import '../../../../core/database/quran_database.dart';
import '../../domain/entities/ayah.dart';
import '../../domain/entities/reading_position.dart';
import '../../domain/entities/surah.dart';
import '../../domain/repositories/quran_repository.dart';

/// تطبيق مستودع القرآن الكريم باستخدام قاعدة بيانات SQLite المحلية.
class QuranRepositoryImpl implements QuranRepository {
  final QuranDatabase _db;

  /// المنشئ مع إمكانية تمرير كائن قاعدة البيانات (يدعم الحقن والاختبارات)
  QuranRepositoryImpl({QuranDatabase? database})
      : _db = database ?? QuranDatabase.instance;

  @override
  Future<List<Surah>> getSurahs() async {
    const sql = '''
      SELECT id, name_arabic, name_english, revelation_type, ayah_count, revelation_order, start_page
      FROM surahs
      ORDER BY id ASC;
    ''';
    final rows = await _db.query(sql: sql);
    return rows.map(Surah.fromMap).toList();
  }

  @override
  Future<Surah?> getSurahById(int surahId) async {
    const sql = '''
      SELECT id, name_arabic, name_english, revelation_type, ayah_count, revelation_order, start_page
      FROM surahs
      WHERE id = ?
      LIMIT 1;
    ''';
    final rows = await _db.query(sql: sql, arguments: [surahId]);
    if (rows.isEmpty) return null;
    return Surah.fromMap(rows.first);
  }

  @override
  Future<List<Ayah>> getSurahAyahs(int surahId) async {
    const sql = '''
      SELECT id, surah_id, ayah_number, global_ayah_number, page_number, juz_number, hizb_number, text_uthmani, text_simple, text_normalized
      FROM ayahs
      WHERE surah_id = ?
      ORDER BY ayah_number ASC;
    ''';
    final rows = await _db.query(sql: sql, arguments: [surahId]);
    return rows.map(Ayah.fromMap).toList();
  }

  @override
  Future<Ayah?> getAyah(int surahId, int ayahNumber) async {
    const sql = '''
      SELECT id, surah_id, ayah_number, global_ayah_number, page_number, juz_number, hizb_number, text_uthmani, text_simple, text_normalized
      FROM ayahs
      WHERE surah_id = ? AND ayah_number = ?
      LIMIT 1;
    ''';
    final rows = await _db.query(sql: sql, arguments: [surahId, ayahNumber]);
    if (rows.isEmpty) return null;
    return Ayah.fromMap(rows.first);
  }

  @override
  Future<List<Ayah>> getAyahRange({
    required int surahId,
    required int startAyah,
    required int endAyah,
  }) async {
    const sql = '''
      SELECT id, surah_id, ayah_number, global_ayah_number, page_number, juz_number, hizb_number, text_uthmani, text_simple, text_normalized
      FROM ayahs
      WHERE surah_id = ?
        AND ayah_number BETWEEN ? AND ?
      ORDER BY ayah_number ASC;
    ''';
    final rows = await _db.query(
      sql: sql,
      arguments: [surahId, startAyah, endAyah],
    );
    return rows.map(Ayah.fromMap).toList();
  }

  @override
  Future<ReadingPosition?> getLastReadingPosition() async {
    const sql = '''
      SELECT id, surah_id, ayah_number, updated_at
      FROM reading_positions
      WHERE id = 1
      LIMIT 1;
    ''';
    final rows = await _db.query(sql: sql);
    if (rows.isEmpty) return null;
    return ReadingPosition.fromMap(rows.first);
  }

  @override
  Future<void> saveReadingPosition({
    required int surahId,
    required int ayahNumber,
  }) async {
    final now = DateTime.now().toIso8601String();
    await _db.insert(
      table: 'reading_positions',
      values: {
        'id': 1,
        'surah_id': surahId,
        'ayah_number': ayahNumber,
        'updated_at': now,
      },
    );
  }
}
