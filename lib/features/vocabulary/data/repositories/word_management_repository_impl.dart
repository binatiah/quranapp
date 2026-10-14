import 'package:quranapp/core/database/quran_database.dart';
import 'package:quranapp/core/text/arabic_normalizer.dart';
import 'package:quranapp/features/quran_search/domain/entities/quran_word.dart';
import 'package:quranapp/features/vocabulary/domain/entities/word_filter_criteria.dart';
import 'package:quranapp/features/vocabulary/domain/repositories/word_management_repository.dart';

/// تطبيق مستودع إدارة واستعراض وتصحيح كلمات ومفردات القرآن الكريم عبر SQLite.
class WordManagementRepositoryImpl implements WordManagementRepository {
  final QuranDatabase _db;
  final ArabicNormalizer _normalizer;

  WordManagementRepositoryImpl({
    QuranDatabase? database,
    ArabicNormalizer? normalizer,
  })  : _db = database ?? QuranDatabase.instance,
        _normalizer = normalizer ?? const ArabicNormalizerImpl();

  @override
  Future<List<QuranWord>> getWords({
    required WordFilterCriteria criteria,
    int limit = 50,
    int offset = 0,
  }) async {
    final (whereSql, args) = _buildWhereClause(criteria);

    final sql = '''
      SELECT
          w.id,
          w.ayah_id,
          w.surah_id,
          w.ayah_number,
          w.word_position,
          w.word_uthmani,
          w.word_simple,
          w.word_normalized,
          w.lemma,
          w.lemma_normalized,
          w.root,
          w.root_normalized,
          w.prefix,
          w.stem,
          w.suffix,
          w.part_of_speech,
          w.morphology,
          s.name_arabic AS surah_name
      FROM words AS w
      INNER JOIN surahs AS s ON s.id = w.surah_id
      $whereSql
      ORDER BY w.surah_id ASC, w.ayah_number ASC, w.word_position ASC
      LIMIT ? OFFSET ?;
    ''';

    final queryArgs = [...args, limit, offset];
    final rows = await _db.query(sql: sql, arguments: queryArgs);
    return rows.map(QuranWord.fromMap).toList();
  }

  @override
  Future<int> getWordsCount({required WordFilterCriteria criteria}) async {
    final (whereSql, args) = _buildWhereClause(criteria);

    final sql = '''
      SELECT COUNT(*) AS total
      FROM words AS w
      $whereSql;
    ''';

    final rows = await _db.query(sql: sql, arguments: args);
    if (rows.isEmpty) return 0;
    return (rows.first['total'] as int?) ?? 0;
  }

  @override
  Future<QuranWord?> getWordById(int id) async {
    const sql = '''
      SELECT
          w.id,
          w.ayah_id,
          w.surah_id,
          w.ayah_number,
          w.word_position,
          w.word_uthmani,
          w.word_simple,
          w.word_normalized,
          w.lemma,
          w.lemma_normalized,
          w.root,
          w.root_normalized,
          w.prefix,
          w.stem,
          w.suffix,
          w.part_of_speech,
          w.morphology,
          s.name_arabic AS surah_name
      FROM words AS w
      INNER JOIN surahs AS s ON s.id = w.surah_id
      WHERE w.id = ?
      LIMIT 1;
    ''';

    final rows = await _db.query(sql: sql, arguments: [id]);
    if (rows.isEmpty) return null;
    return QuranWord.fromMap(rows.first);
  }

  @override
  Future<int> getWordOccurrencesCount(String wordNormalized) async {
    final clean = _normalizer.normalizeForSearch(wordNormalized);
    if (clean.isEmpty) return 0;

    const sql = '''
      SELECT COUNT(*) AS total
      FROM words
      WHERE word_normalized = ?;
    ''';

    final rows = await _db.query(sql: sql, arguments: [clean]);
    if (rows.isEmpty) return 0;
    return (rows.first['total'] as int?) ?? 0;
  }

  @override
  Future<int> relinkWordToRoot({
    required int wordId,
    required String newRoot,
    bool applyToAllOccurrences = false,
  }) async {
    final cleanRoot = newRoot.trim();
    if (cleanRoot.isEmpty) {
      throw ArgumentError('الجذر الجديد لا يمكن أن يكون فارغاً');
    }

    final normalized = _normalizer.normalizeForRootSearch(cleanRoot);
    if (normalized.isEmpty) {
      throw ArgumentError('تعذر استخراج حروف الجذر الجديد');
    }

    // 1. التأكد من وجود الجذر في جدول roots أو إنشائه
    final existingRoots = await _db.query(
      sql: 'SELECT id FROM roots WHERE root_normalized = ? LIMIT 1;',
      arguments: [normalized],
    );

    int rootId;
    if (existingRoots.isNotEmpty) {
      rootId = existingRoots.first['id'] as int;
    } else {
      rootId = await _db.insert(
        table: 'roots',
        values: {
          'root': cleanRoot,
          'root_normalized': normalized,
          'description_ar': 'أضيف تلقائياً أثناء ربط الكلمات',
        },
      );
    }

    // 2. جلب بيانات الكلمة الحالية
    final wordRows = await _db.query(
      sql: 'SELECT id, word_normalized FROM words WHERE id = ? LIMIT 1;',
      arguments: [wordId],
    );

    if (wordRows.isEmpty) {
      throw StateError('الكلمة المحددة غير موجودة في قاعدة البيانات');
    }

    final wordNormalized = wordRows.first['word_normalized'] as String;

    if (!applyToAllOccurrences) {
      // تحديث هذه الكلمة المفردة فقط
      await _db.update(
        table: 'words',
        values: {
          'root': cleanRoot,
          'root_normalized': normalized,
        },
        where: 'id = ?',
        whereArgs: [wordId],
      );

      // تحديث أو إدراج في جدول word_roots
      await _db.insert(
        table: 'word_roots',
        values: {
          'word_id': wordId,
          'root_id': rootId,
          'confidence': 1.0,
          'is_primary': 1,
          'source': 'manual_verification',
        },
      );

      return 1;
    } else {
      // تطبيق التعديل على جميع الكلمات المطابقة للمطبع في القرآن
      final updatedCount = await _db.update(
        table: 'words',
        values: {
          'root': cleanRoot,
          'root_normalized': normalized,
        },
        where: 'word_normalized = ?',
        whereArgs: [wordNormalized],
      );

      // ربط جميع الكلمات المطابقة في جدول word_roots
      final rawDb = await _db.database;
      await rawDb.rawInsert('''
        INSERT OR REPLACE INTO word_roots (word_id, root_id, confidence, is_primary, source)
        SELECT id, ?, 1.0, 1, 'manual_batch_verification'
        FROM words
        WHERE word_normalized = ?;
      ''', [rootId, wordNormalized]);

      return updatedCount;
    }
  }

  @override
  Future<int> unlinkWordFromRoot({
    required int wordId,
    bool applyToAllOccurrences = false,
  }) async {
    final wordRows = await _db.query(
      sql: 'SELECT id, word_normalized FROM words WHERE id = ? LIMIT 1;',
      arguments: [wordId],
    );

    if (wordRows.isEmpty) return 0;
    final wordNormalized = wordRows.first['word_normalized'] as String;

    if (!applyToAllOccurrences) {
      await _db.update(
        table: 'words',
        values: {
          'root': null,
          'root_normalized': null,
        },
        where: 'id = ?',
        whereArgs: [wordId],
      );

      await _db.delete(
        table: 'word_roots',
        where: 'word_id = ?',
        whereArgs: [wordId],
      );

      return 1;
    } else {
      final affectedCount = await _db.update(
        table: 'words',
        values: {
          'root': null,
          'root_normalized': null,
        },
        where: 'word_normalized = ?',
        whereArgs: [wordNormalized],
      );

      final rawDb = await _db.database;
      await rawDb.rawDelete('''
        DELETE FROM word_roots
        WHERE word_id IN (SELECT id FROM words WHERE word_normalized = ?);
      ''', [wordNormalized]);

      return affectedCount;
    }
  }

  @override
  Future<void> updateWordDetails({
    required int wordId,
    required String wordUthmani,
    String? lemma,
    String? prefix,
    String? stem,
    String? suffix,
    String? partOfSpeech,
    String? morphology,
  }) async {
    final cleanUthmani = wordUthmani.trim();
    if (cleanUthmani.isEmpty) {
      throw ArgumentError('الرسم العثماني للكلمة لا يمكن أن يكون فارغاً');
    }

    final lemmaNormalized = (lemma != null && lemma.trim().isNotEmpty)
        ? _normalizer.normalizeForSearch(lemma.trim())
        : null;

    await _db.update(
      table: 'words',
      values: {
        'word_uthmani': cleanUthmani,
        'lemma': lemma?.trim().isEmpty == true ? null : lemma?.trim(),
        'lemma_normalized': lemmaNormalized,
        'prefix': prefix?.trim().isEmpty == true ? null : prefix?.trim(),
        'stem': stem?.trim().isEmpty == true ? null : stem?.trim(),
        'suffix': suffix?.trim().isEmpty == true ? null : suffix?.trim(),
        'part_of_speech': partOfSpeech?.trim().isEmpty == true ? null : partOfSpeech?.trim(),
        'morphology': morphology?.trim().isEmpty == true ? null : morphology?.trim(),
      },
      where: 'id = ?',
      whereArgs: [wordId],
    );
  }

  /// بناء جملة WHERE والمتغيرات المرتبطة بمعايير الفلترة
  (String, List<Object?>) _buildWhereClause(WordFilterCriteria criteria) {
    final whereClauses = <String>[];
    final args = <Object?>[];

    // 1. فلتر البحث النصي
    if (criteria.query != null && criteria.query!.trim().isNotEmpty) {
      final queryText = criteria.query!.trim();
      final normalizedQuery = _normalizer.normalizeForSearch(queryText);
      whereClauses.add('''
        (w.word_uthmani LIKE ? OR w.word_normalized LIKE ? OR (w.lemma_normalized IS NOT NULL AND w.lemma_normalized LIKE ?))
      ''');
      args.addAll(['%$queryText%', '%$normalizedQuery%', '%$normalizedQuery%']);
    }

    // 2. فلتر السورة
    if (criteria.surahId != null) {
      whereClauses.add('w.surah_id = ?');
      args.add(criteria.surahId);
    }

    // 3. فلتر حالة الجذر
    switch (criteria.rootStatus) {
      case WordRootStatus.all:
        break;
      case WordRootStatus.withRoot:
        whereClauses.add("(w.root_normalized IS NOT NULL AND TRIM(w.root_normalized) != '')");
        break;
      case WordRootStatus.withoutRoot:
        whereClauses.add("(w.root_normalized IS NULL OR TRIM(w.root_normalized) = '')");
        break;
      case WordRootStatus.specificRoot:
        if (criteria.specificRoot != null && criteria.specificRoot!.trim().isNotEmpty) {
          final normalizedRoot = _normalizer.normalizeForRootSearch(criteria.specificRoot!.trim());
          whereClauses.add('w.root_normalized = ?');
          args.add(normalizedRoot);
        }
        break;
    }

    final whereSql = whereClauses.isNotEmpty ? 'WHERE ${whereClauses.join(' AND ')}' : '';
    return (whereSql, args);
  }
}
