import 'package:quranapp/core/database/quran_database.dart';
import '../../domain/entities/bookmark.dart';
import '../../domain/repositories/bookmarks_repository.dart';

/// تطبيق مستودع إدارة العلامات المرجعية والمفضلة باستخدام SQLite.
class BookmarksRepositoryImpl implements BookmarksRepository {
  final QuranDatabase _db;

  BookmarksRepositoryImpl({QuranDatabase? database})
      : _db = database ?? QuranDatabase.instance;

  @override
  Future<List<Bookmark>> getBookmarks() async {
    const sql = '''
      SELECT
          b.id,
          b.ayah_id,
          b.note,
          b.created_at,
          a.ayah_number,
          a.text_uthmani,
          s.id AS surah_id,
          s.name_arabic AS surah_name
      FROM bookmarks AS b
      INNER JOIN ayahs AS a ON a.id = b.ayah_id
      INNER JOIN surahs AS s ON s.id = a.surah_id
      ORDER BY b.id DESC;
    ''';

    final rows = await _db.query(sql: sql);
    return rows.map((row) => Bookmark.fromMap(row)).toList();
  }

  @override
  Future<Bookmark?> getBookmarkByAyahId(int ayahId) async {
    const sql = '''
      SELECT
          b.id,
          b.ayah_id,
          b.note,
          b.created_at,
          a.ayah_number,
          a.text_uthmani,
          s.id AS surah_id,
          s.name_arabic AS surah_name
      FROM bookmarks AS b
      INNER JOIN ayahs AS a ON a.id = b.ayah_id
      INNER JOIN surahs AS s ON s.id = a.surah_id
      WHERE b.ayah_id = ?
      LIMIT 1;
    ''';

    final rows = await _db.query(sql: sql, arguments: [ayahId]);
    if (rows.isEmpty) return null;
    return Bookmark.fromMap(rows.first);
  }

  @override
  Future<int> addBookmark({
    required int ayahId,
    String? note,
  }) async {
    final now = DateTime.now().toIso8601String();

    // التحقق أولاً مما إذا كانت الآية مضافة مسبقاً
    final existing = await getBookmarkByAyahId(ayahId);
    if (existing != null) {
      if (note != null && note.isNotEmpty) {
        await updateBookmarkNote(bookmarkId: existing.id!, note: note);
      }
      return existing.id!;
    }

    final id = await _db.insert(
      table: 'bookmarks',
      values: {
        'ayah_id': ayahId,
        'note': note,
        'created_at': now,
      },
    );
    return id;
  }

  @override
  Future<bool> updateBookmarkNote({
    required int bookmarkId,
    required String note,
  }) async {
    final count = await _db.update(
      table: 'bookmarks',
      values: {'note': note},
      where: 'id = ?',
      whereArgs: [bookmarkId],
    );
    return count > 0;
  }

  @override
  Future<bool> removeBookmark(int bookmarkId) async {
    final count = await _db.delete(
      table: 'bookmarks',
      where: 'id = ?',
      whereArgs: [bookmarkId],
    );
    return count > 0;
  }

  @override
  Future<bool> removeBookmarkByAyahId(int ayahId) async {
    final count = await _db.delete(
      table: 'bookmarks',
      where: 'ayah_id = ?',
      whereArgs: [ayahId],
    );
    return count > 0;
  }

  @override
  Future<bool> isBookmarked(int ayahId) async {
    final rows = await _db.query(
      sql: 'SELECT 1 FROM bookmarks WHERE ayah_id = ? LIMIT 1;',
      arguments: [ayahId],
    );
    return rows.isNotEmpty;
  }
}
