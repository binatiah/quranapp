import 'package:quranapp/core/database/quran_database.dart';
import 'package:quranapp/core/text/arabic_normalizer.dart';
import 'package:quranapp/features/vocabulary/domain/entities/morphology_audit_item.dart';
import 'package:quranapp/features/vocabulary/domain/entities/morphology_audit_stats.dart';
import 'package:quranapp/features/vocabulary/domain/repositories/morphology_audit_repository.dart';

/// تطبيق مستودع التدقيق الصرفي والمعجمي الجماعي
class MorphologyAuditRepositoryImpl implements MorphologyAuditRepository {
  final QuranDatabase _db;
  final ArabicNormalizer _normalizer;

  MorphologyAuditRepositoryImpl({
    QuranDatabase? database,
    ArabicNormalizer? normalizer,
  })  : _db = database ?? QuranDatabase.instance,
        _normalizer = normalizer ?? const ArabicNormalizerImpl();

  @override
  Future<MorphologyAuditStats> getAuditStats() async {
    const statsSql = '''
      SELECT
        COUNT(*) AS total_words,
        COUNT(CASE WHEN root_normalized IS NOT NULL AND TRIM(root_normalized) != '' AND TRIM(root_normalized) != 'غير محدد' THEN 1 END) AS words_with_root,
        COUNT(CASE WHEN part_of_speech IS NOT NULL AND TRIM(part_of_speech) != '' THEN 1 END) AS words_with_morphology
      FROM words;
    ''';

    final statsRows = await _db.query(sql: statsSql);
    final totalWords = (statsRows.first['total_words'] as num?)?.toInt() ?? 0;
    final wordsWithRoot = (statsRows.first['words_with_root'] as num?)?.toInt() ?? 0;
    final wordsWithMorph = (statsRows.first['words_with_morphology'] as num?)?.toInt() ?? 0;

    const rootsSql = 'SELECT COUNT(*) AS total_roots FROM roots;';
    final rootsRows = await _db.query(sql: rootsSql);
    final totalRoots = (rootsRows.first['total_roots'] as num?)?.toInt() ?? 0;

    return MorphologyAuditStats(
      totalWords: totalWords,
      wordsWithRoot: wordsWithRoot,
      wordsWithoutRoot: totalWords - wordsWithRoot,
      wordsWithoutMorphology: totalWords - wordsWithMorph,
      totalUniqueRoots: totalRoots,
    );
  }

  @override
  Future<List<MorphologyAuditItem>> getAuditItems({
    bool withoutRootOnly = true,
    String? query,
    int? surahId,
    int limit = 40,
    int offset = 0,
  }) async {
    final whereClauses = <String>[];
    final args = <Object?>[];

    if (withoutRootOnly) {
      whereClauses.add("(w.root_normalized IS NULL OR TRIM(w.root_normalized) = '' OR w.root_normalized = 'غير محدد')");
    } else {
      whereClauses.add("(w.part_of_speech IS NULL OR TRIM(w.part_of_speech) = '')");
    }

    if (surahId != null) {
      whereClauses.add('w.surah_id = ?');
      args.add(surahId);
    }

    if (query != null && query.trim().isNotEmpty) {
      final clean = query.trim();
      final normalized = _normalizer.normalizeForSearch(clean);
      whereClauses.add('(w.word_uthmani LIKE ? OR w.word_normalized LIKE ?)');
      args.addAll(['%$clean%', '%$normalized%']);
    }

    final whereSql = 'WHERE ${whereClauses.join(' AND ')}';

    final sql = '''
      SELECT
        w.id,
        w.surah_id,
        w.ayah_number,
        w.word_position,
        w.word_uthmani,
        w.word_normalized,
        w.part_of_speech,
        w.root,
        s.name_arabic AS surah_name,
        (SELECT COUNT(*) FROM words WHERE word_normalized = w.word_normalized) AS occurrences
      FROM words AS w
      INNER JOIN surahs AS s ON s.id = w.surah_id
      $whereSql
      ORDER BY occurrences DESC, w.surah_id ASC, w.ayah_number ASC
      LIMIT ? OFFSET ?;
    ''';

    final queryArgs = [...args, limit, offset];
    final rows = await _db.query(sql: sql, arguments: queryArgs);
    return rows.map(MorphologyAuditItem.fromMap).toList();
  }

  @override
  Future<int> getAuditItemsCount({
    bool withoutRootOnly = true,
    String? query,
    int? surahId,
  }) async {
    final whereClauses = <String>[];
    final args = <Object?>[];

    if (withoutRootOnly) {
      whereClauses.add("(w.root_normalized IS NULL OR TRIM(w.root_normalized) = '' OR w.root_normalized = 'غير محدد')");
    } else {
      whereClauses.add("(w.part_of_speech IS NULL OR TRIM(w.part_of_speech) = '')");
    }

    if (surahId != null) {
      whereClauses.add('w.surah_id = ?');
      args.add(surahId);
    }

    if (query != null && query.trim().isNotEmpty) {
      final clean = query.trim();
      final normalized = _normalizer.normalizeForSearch(clean);
      whereClauses.add('(w.word_uthmani LIKE ? OR w.word_normalized LIKE ?)');
      args.addAll(['%$clean%', '%$normalized%']);
    }

    final whereSql = 'WHERE ${whereClauses.join(' AND ')}';
    final sql = 'SELECT COUNT(*) AS total FROM words AS w $whereSql;';

    final rows = await _db.query(sql: sql, arguments: args);
    if (rows.isEmpty) return 0;
    return (rows.first['total'] as num?)?.toInt() ?? 0;
  }

  @override
  Future<int> batchRelinkWords({
    required List<int> wordIds,
    required String newRoot,
    bool applyToAllOccurrences = false,
  }) async {
    if (wordIds.isEmpty) return 0;

    final cleanRoot = newRoot.trim();
    if (cleanRoot.isEmpty) {
      throw ArgumentError('الجذر الجديد لا يمكن أن يكون فارغاً');
    }

    final normalizedRoot = _normalizer.normalizeForRootSearch(cleanRoot);
    if (normalizedRoot.isEmpty) {
      throw ArgumentError('تعذر استخراج حروف الجذر الجديد');
    }

    final rawDb = await _db.database;
    int totalAffected = 0;

    await rawDb.transaction((txn) async {
      // 1. التأكد من وجود الجذر في جدول roots
      final existingRoots = await txn.query(
        'roots',
        columns: ['id'],
        where: 'root_normalized = ?',
        whereArgs: [normalizedRoot],
        limit: 1,
      );

      int rootId;
      if (existingRoots.isNotEmpty) {
        rootId = existingRoots.first['id'] as int;
      } else {
        rootId = await txn.insert('roots', {
          'root': cleanRoot,
          'root_normalized': normalizedRoot,
        });
      }

      if (applyToAllOccurrences) {
        // جلب النصوص المطبّعة للكلمات المحددة
        final placeholders = List.filled(wordIds.length, '?').join(',');
        final wordRows = await txn.rawQuery(
          'SELECT DISTINCT word_normalized FROM words WHERE id IN ($placeholders);',
          wordIds,
        );

        final normalizedList = wordRows
            .map((r) => r['word_normalized'] as String?)
            .where((w) => w != null && w.isNotEmpty)
            .cast<String>()
            .toList();

        if (normalizedList.isNotEmpty) {
          final normPlaceholders = List.filled(normalizedList.length, '?').join(',');
          totalAffected = await txn.update(
            'words',
            {
              'root': cleanRoot,
              'root_normalized': normalizedRoot,
            },
            where: 'word_normalized IN ($normPlaceholders)',
            whereArgs: normalizedList,
          );

          // إدراج سجلات الربط في word_roots
          final affectedWords = await txn.rawQuery(
            'SELECT id FROM words WHERE word_normalized IN ($normPlaceholders);',
            normalizedList,
          );
          for (final row in affectedWords) {
            final wId = row['id'] as int;
            await txn.delete('word_roots', where: 'word_id = ?', whereArgs: [wId]);
            await txn.insert('word_roots', {
              'word_id': wId,
              'root_id': rootId,
              'source': 'manual_batch_audit',
            });
          }
        }
      } else {
        // تحديث الكلمات المحددة بالمعرفات فقط
        final placeholders = List.filled(wordIds.length, '?').join(',');
        totalAffected = await txn.update(
          'words',
          {
            'root': cleanRoot,
            'root_normalized': normalizedRoot,
          },
          where: 'id IN ($placeholders)',
          whereArgs: wordIds,
        );

        for (final wId in wordIds) {
          await txn.delete('word_roots', where: 'word_id = ?', whereArgs: [wId]);
          await txn.insert('word_roots', {
            'word_id': wId,
            'root_id': rootId,
            'source': 'manual_batch_audit',
          });
        }
      }
    });

    return totalAffected;
  }
}
