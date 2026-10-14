import 'package:quranapp/core/database/quran_database.dart';
import 'package:quranapp/core/text/arabic_normalizer.dart';
import 'package:quranapp/features/quran_search/domain/entities/quran_root.dart';
import 'package:quranapp/features/root_study/domain/repositories/root_management_repository.dart';

/// تطبيق مستودع إدارة واستعراض الجذور اللغوية القرآنية باستخدام SQLite.
class RootManagementRepositoryImpl implements RootManagementRepository {
  final QuranDatabase _db;
  final ArabicNormalizer _normalizer;

  RootManagementRepositoryImpl({
    QuranDatabase? database,
    ArabicNormalizer? normalizer,
  })  : _db = database ?? QuranDatabase.instance,
        _normalizer = normalizer ?? const ArabicNormalizerImpl();

  @override
  Future<List<QuranRoot>> getRoots({
    String? query,
    RootSortBy sortBy = RootSortBy.occurrencesDesc,
    int limit = 50,
    int offset = 0,
  }) async {
    final args = <Object?>[];
    final whereClauses = <String>[];

    if (query != null && query.trim().isNotEmpty) {
      final clean = query.trim();
      final normalized = _normalizer.normalizeForRootSearch(clean);
      whereClauses.add('''
        (r.root LIKE ? OR r.root_normalized LIKE ? OR (r.description_ar IS NOT NULL AND r.description_ar LIKE ?))
      ''');
      args.addAll(['%$clean%', '%$normalized%', '%$clean%']);
    }

    if (sortBy == RootSortBy.withoutDescription) {
      whereClauses.add("(r.description_ar IS NULL OR TRIM(r.description_ar) = '')");
    }

    final whereSql = whereClauses.isNotEmpty ? 'WHERE ${whereClauses.join(' AND ')}' : '';

    final orderBySql = switch (sortBy) {
      RootSortBy.occurrencesDesc => 'occurrences_count DESC, words_count DESC, r.root_normalized ASC',
      RootSortBy.occurrencesAsc => 'occurrences_count ASC, r.root_normalized ASC',
      RootSortBy.alphabetical => 'r.root_normalized ASC',
      RootSortBy.wordsCountDesc => 'words_count DESC, occurrences_count DESC, r.root_normalized ASC',
      RootSortBy.withoutDescription => 'occurrences_count DESC, r.root_normalized ASC',
    };

    final sql = '''
      SELECT
          r.id,
          r.root,
          r.root_normalized,
          r.description_ar,
          COUNT(w.id) AS occurrences_count,
          COUNT(DISTINCT w.word_normalized) AS words_count
      FROM roots AS r
      LEFT JOIN words AS w ON w.root_normalized = r.root_normalized
      $whereSql
      GROUP BY r.id, r.root, r.root_normalized, r.description_ar
      ORDER BY $orderBySql
      LIMIT ? OFFSET ?;
    ''';

    args.addAll([limit, offset]);

    final rows = await _db.query(sql: sql, arguments: args);
    return rows.map(QuranRoot.fromMap).toList();
  }

  @override
  Future<int> getRootsCount({
    String? query,
    RootSortBy sortBy = RootSortBy.occurrencesDesc,
  }) async {
    final args = <Object?>[];
    final whereClauses = <String>[];

    if (query != null && query.trim().isNotEmpty) {
      final clean = query.trim();
      final normalized = _normalizer.normalizeForRootSearch(clean);
      whereClauses.add('''
        (r.root LIKE ? OR r.root_normalized LIKE ? OR (r.description_ar IS NOT NULL AND r.description_ar LIKE ?))
      ''');
      args.addAll(['%$clean%', '%$normalized%', '%$clean%']);
    }

    if (sortBy == RootSortBy.withoutDescription) {
      whereClauses.add("(r.description_ar IS NULL OR TRIM(r.description_ar) = '')");
    }

    final whereSql = whereClauses.isNotEmpty ? 'WHERE ${whereClauses.join(' AND ')}' : '';

    final sql = '''
      SELECT COUNT(*) AS total
      FROM roots AS r
      $whereSql;
    ''';

    final rows = await _db.query(sql: sql, arguments: args);
    if (rows.isEmpty) return 0;
    return (rows.first['total'] as int?) ?? 0;
  }

  @override
  Future<QuranRoot?> getRootById(int id) async {
    const sql = '''
      SELECT
          r.id,
          r.root,
          r.root_normalized,
          r.description_ar,
          COUNT(w.id) AS occurrences_count,
          COUNT(DISTINCT w.word_normalized) AS words_count
      FROM roots AS r
      LEFT JOIN words AS w ON w.root_normalized = r.root_normalized
      WHERE r.id = ?
      GROUP BY r.id, r.root, r.root_normalized, r.description_ar
      LIMIT 1;
    ''';

    final rows = await _db.query(sql: sql, arguments: [id]);
    if (rows.isEmpty) return null;
    return QuranRoot.fromMap(rows.first);
  }

  @override
  Future<QuranRoot> addRoot({
    required String root,
    String? descriptionAr,
  }) async {
    final trimmedRoot = root.trim();
    if (trimmedRoot.isEmpty) {
      throw ArgumentError('نص الجذر لا يمكن أن يكون فارغاً');
    }

    final normalized = _normalizer.normalizeForRootSearch(trimmedRoot);
    if (normalized.isEmpty) {
      throw ArgumentError('تعذر استخراج حروف الجذر الصرفية');
    }

    // التحقق من عدم وجود الجذر مسبقاً
    final existing = await _db.query(
      sql: 'SELECT id, root FROM roots WHERE root_normalized = ? LIMIT 1;',
      arguments: [normalized],
    );

    if (existing.isNotEmpty) {
      throw StateError('الجذر "$trimmedRoot" موجود مسبقاً في قاعدة البيانات');
    }

    final newId = await _db.insert(
      table: 'roots',
      values: {
        'root': trimmedRoot,
        'root_normalized': normalized,
        'description_ar': descriptionAr?.trim().isEmpty == true ? null : descriptionAr?.trim(),
      },
    );

    return QuranRoot(
      id: newId,
      root: trimmedRoot,
      rootNormalized: normalized,
      descriptionAr: descriptionAr?.trim().isEmpty == true ? null : descriptionAr?.trim(),
      wordsCount: 0,
      occurrencesCount: 0,
    );
  }

  @override
  Future<void> updateRoot({
    required int id,
    required String root,
    String? descriptionAr,
  }) async {
    final trimmedRoot = root.trim();
    if (trimmedRoot.isEmpty) {
      throw ArgumentError('نص الجذر لا يمكن أن يكون فارغاً');
    }

    final normalized = _normalizer.normalizeForRootSearch(trimmedRoot);
    if (normalized.isEmpty) {
      throw ArgumentError('تعذر استخراج حروف الجذر الصرفية');
    }

    // جلب الجذر القديم للتحقق
    final oldRecord = await _db.query(
      sql: 'SELECT id, root_normalized FROM roots WHERE id = ? LIMIT 1;',
      arguments: [id],
    );

    if (oldRecord.isEmpty) {
      throw StateError('الجذر المطلوب تعديله غير موجود في قاعدة البيانات');
    }

    final oldNormalized = oldRecord.first['root_normalized'] as String;

    // إذا تغير الجذر المطبّع، نتأكد أنه لا يتعارض مع جذر آخر
    if (normalized != oldNormalized) {
      final conflict = await _db.query(
        sql: 'SELECT id FROM roots WHERE root_normalized = ? AND id != ? LIMIT 1;',
        arguments: [normalized, id],
      );
      if (conflict.isNotEmpty) {
        throw StateError('الجذر الجديد "$trimmedRoot" مسجل بالفعل تحت معرف آخر');
      }

      // تحديث جدول roots
      await _db.update(
        table: 'roots',
        values: {
          'root': trimmedRoot,
          'root_normalized': normalized,
          'description_ar': descriptionAr?.trim().isEmpty == true ? null : descriptionAr?.trim(),
        },
        where: 'id = ?',
        whereArgs: [id],
      );

      // تحديث الكلمات المرتبطة بالجذر القديم
      await _db.update(
        table: 'words',
        values: {
          'root': trimmedRoot,
          'root_normalized': normalized,
        },
        where: 'root_normalized = ?',
        whereArgs: [oldNormalized],
      );
    } else {
      // فقط تحديث الاسم المعروض أو الوصف
      await _db.update(
        table: 'roots',
        values: {
          'root': trimmedRoot,
          'description_ar': descriptionAr?.trim().isEmpty == true ? null : descriptionAr?.trim(),
        },
        where: 'id = ?',
        whereArgs: [id],
      );
    }
  }

  @override
  Future<int> getRootWordCount(int id) async {
    const sql = '''
      SELECT COUNT(w.id) AS count
      FROM words AS w
      INNER JOIN roots AS r ON r.root_normalized = w.root_normalized
      WHERE r.id = ?;
    ''';
    final rows = await _db.query(sql: sql, arguments: [id]);
    if (rows.isEmpty) return 0;
    return (rows.first['count'] as int?) ?? 0;
  }

  @override
  Future<bool> deleteRoot(int id) async {
    final rootRecord = await _db.query(
      sql: 'SELECT id, root_normalized FROM roots WHERE id = ? LIMIT 1;',
      arguments: [id],
    );
    if (rootRecord.isEmpty) return false;

    final rootNormalized = rootRecord.first['root_normalized'] as String;

    // 1. حذف الروابط من جدول word_roots
    await _db.delete(
      table: 'word_roots',
      where: 'root_id = ?',
      whereArgs: [id],
    );

    // 2. فك ارتباط الكلمات في جدول words
    await _db.update(
      table: 'words',
      values: {
        'root': null,
        'root_normalized': null,
      },
      where: 'root_normalized = ?',
      whereArgs: [rootNormalized],
    );

    // 3. حذف السجل من جدول roots
    final deletedCount = await _db.delete(
      table: 'roots',
      where: 'id = ?',
      whereArgs: [id],
    );

    return deletedCount > 0;
  }
}
