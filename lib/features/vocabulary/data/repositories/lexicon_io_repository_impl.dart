import 'package:quranapp/core/database/quran_database.dart';
import 'package:quranapp/core/text/arabic_normalizer.dart';
import 'package:quranapp/features/vocabulary/domain/entities/lexicon_export_data.dart';
import 'package:quranapp/features/vocabulary/domain/repositories/lexicon_io_repository.dart';

/// تطبيق مستودع تصدير واستيراد تصحيحات المعجم القرآني عبر معاملات SQLite الموحدة.
class LexiconIORepositoryImpl implements LexiconIORepository {
  final QuranDatabase _db;
  final ArabicNormalizer _normalizer;

  LexiconIORepositoryImpl({
    QuranDatabase? database,
    ArabicNormalizer? normalizer,
  })  : _db = database ?? QuranDatabase.instance,
        _normalizer = normalizer ?? const ArabicNormalizerImpl();

  @override
  Future<LexiconExportData> exportLexiconData({bool customOnly = true}) async {
    final List<ExportedRootEntry> exportedRoots = [];
    final List<ExportedWordRootLink> exportedLinks = [];

    if (customOnly) {
      // 1. جلب الروابط التي تمت مراجعتها يدوياً أو إدراجها بواسطة المستخدم
      final customLinks = await _db.query(
        sql: '''
          SELECT
              w.id AS word_id,
              w.word_uthmani,
              w.root,
              w.root_normalized,
              wr.source
          FROM words AS w
          INNER JOIN word_roots AS wr ON wr.word_id = w.id
          WHERE wr.source LIKE 'manual%'
          ORDER BY w.id ASC;
        ''',
      );

      for (final row in customLinks) {
        exportedLinks.add(ExportedWordRootLink(
          wordId: row['word_id'] as int,
          root: (row['root'] ?? '') as String,
          rootNormalized: (row['root_normalized'] ?? '') as String,
          wordUthmani: row['word_uthmani'] as String?,
          source: row['source'] as String?,
        ));
      }

      // 2. جلب الجذور المرتبطة أو المضافة حديثاً
      final rootRows = await _db.query(
        sql: '''
          SELECT DISTINCT r.root, r.root_normalized, r.description_ar
          FROM roots AS r
          WHERE r.description_ar LIKE '%أضيف%' OR r.description_ar LIKE '%مضاف%'
             OR r.root_normalized IN (
                SELECT DISTINCT w.root_normalized
                FROM words AS w
                INNER JOIN word_roots AS wr ON wr.word_id = w.id
                WHERE wr.source LIKE 'manual%'
             )
          ORDER BY r.root_normalized ASC;
        ''',
      );

      for (final row in rootRows) {
        exportedRoots.add(ExportedRootEntry(
          root: row['root'] as String,
          rootNormalized: row['root_normalized'] as String,
          descriptionAr: row['description_ar'] as String?,
        ));
      }
    } else {
      // تصدير شامل لكافة الجذور والكلمات
      final allRoots = await _db.query(
        sql: 'SELECT root, root_normalized, description_ar FROM roots ORDER BY root_normalized ASC;',
      );
      for (final row in allRoots) {
        exportedRoots.add(ExportedRootEntry(
          root: row['root'] as String,
          rootNormalized: row['root_normalized'] as String,
          descriptionAr: row['description_ar'] as String?,
        ));
      }

      final allLinks = await _db.query(
        sql: '''
          SELECT w.id AS word_id, w.word_uthmani, w.root, w.root_normalized
          FROM words AS w
          WHERE w.root_normalized IS NOT NULL AND w.root_normalized != ''
          ORDER BY w.id ASC
          LIMIT 1000;
        ''',
      );
      for (final row in allLinks) {
        exportedLinks.add(ExportedWordRootLink(
          wordId: row['word_id'] as int,
          root: (row['root'] ?? '') as String,
          rootNormalized: (row['root_normalized'] ?? '') as String,
          wordUthmani: row['word_uthmani'] as String?,
          source: 'database_export',
        ));
      }
    }

    return LexiconExportData(
      version: '1.0',
      exportedAt: DateTime.now().toIso8601String(),
      notes: customOnly
          ? 'حزمة تصحيحات المعجم اليدوية الصادرة من مصحف البحث والدراسة'
          : 'نسخة تصدير المعجم القرآني الشامل',
      roots: exportedRoots,
      wordLinks: exportedLinks,
    );
  }

  @override
  Future<String> exportLexiconJson({bool customOnly = true, bool pretty = true}) async {
    final data = await exportLexiconData(customOnly: customOnly);
    return data.toJsonString(pretty: pretty);
  }

  @override
  Future<LexiconImportResult> importLexiconJson(String jsonString) async {
    final LexiconExportData data;
    try {
      data = LexiconExportData.fromJsonString(jsonString);
    } catch (e) {
      return LexiconImportResult(
        isSuccess: false,
        errorMessage: 'فشل تحليل ملف JSON: تأكد من صحة تنسيق الملف وهيكله (${e.toString()})',
      );
    }

    final warnings = <String>[];
    int importedRoots = 0;
    int updatedWords = 0;

    final rawDb = await _db.database;

    try {
      await rawDb.transaction((txn) async {
        // 1. معالجة واستيراد الجذور
        for (final entry in data.roots) {
          final normalized = _normalizer.normalizeForRootSearch(entry.root);
          if (normalized.isEmpty) continue;

          final existing = await txn.rawQuery(
            'SELECT id FROM roots WHERE root_normalized = ? LIMIT 1;',
            [normalized],
          );

          if (existing.isEmpty) {
            await txn.rawInsert(
              'INSERT INTO roots (root, root_normalized, description_ar) VALUES (?, ?, ?);',
              [entry.root.trim(), normalized, entry.descriptionAr],
            );
            importedRoots++;
          } else if (entry.descriptionAr != null && entry.descriptionAr!.trim().isNotEmpty) {
            await txn.rawUpdate(
              'UPDATE roots SET description_ar = ? WHERE id = ?;',
              [entry.descriptionAr, existing.first['id']],
            );
          }
        }

        // 2. معالجة وتطبيق روابط الكلمات
        for (final link in data.wordLinks) {
          final normalized = _normalizer.normalizeForRootSearch(link.root);
          if (normalized.isEmpty) continue;

          // التأكد من وجود الجذر أو إضافته
          final rootRows = await txn.rawQuery(
            'SELECT id FROM roots WHERE root_normalized = ? LIMIT 1;',
            [normalized],
          );

          final int rootId;
          if (rootRows.isNotEmpty) {
            rootId = rootRows.first['id'] as int;
          } else {
            rootId = await txn.rawInsert(
              'INSERT INTO roots (root, root_normalized, description_ar) VALUES (?, ?, ?);',
              [link.root.trim(), normalized, 'أضيف تلقائياً أثناء استيراد المعجم'],
            );
            importedRoots++;
          }

          // التحقق من وجود الكلمة المستهدفة
          final wordExists = await txn.rawQuery(
            'SELECT id FROM words WHERE id = ? LIMIT 1;',
            [link.wordId],
          );

          if (wordExists.isNotEmpty) {
            await txn.rawUpdate(
              'UPDATE words SET root = ?, root_normalized = ? WHERE id = ?;',
              [link.root.trim(), normalized, link.wordId],
            );

            await txn.rawInsert(
              '''
                INSERT OR REPLACE INTO word_roots (word_id, root_id, confidence, is_primary, source)
                VALUES (?, ?, 1.0, 1, ?);
              ''',
              [link.wordId, rootId, link.source ?? 'imported_correction'],
            );

            updatedWords++;
          } else {
            warnings.add('الكلمة بالمعرف ${link.wordId} غير موجودة في قاعدة البيانات المحلية.');
          }
        }
      });

      return LexiconImportResult(
        isSuccess: true,
        importedRootsCount: importedRoots,
        updatedWordsCount: updatedWords,
        warnings: warnings,
      );
    } catch (e) {
      return LexiconImportResult(
        isSuccess: false,
        errorMessage: 'حدث خطأ أثناء تنفيذ عملية الاستيراد: ${e.toString()}',
      );
    }
  }
}
