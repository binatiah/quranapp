import 'dart:io';
import 'package:flutter_test/flutter_test.dart';
import 'package:path/path.dart' as p;
import 'package:quranapp/core/database/database_migrations.dart';
import 'package:quranapp/core/database/quran_database.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';

void main() {
  setUpAll(() {
    // تهيئة محرك sqflite_common_ffi لاختبارات سطح المكتب والـ Unit Tests
    sqfliteFfiInit();
  });

  group('Quran Database Integrity & Query Tests', () {
    late QuranDatabase quranDb;
    late Database rawDb;

    setUp(() async {
      QuranDatabase.resetForTesting();
      // مسار قاعدة البيانات الحقيقية المنشأة في الأصول
      final assetDbPath = p.join(Directory.current.path, 'assets', 'database', 'quran.db');

      quranDb = QuranDatabase.forTesting(
        customFactory: databaseFactoryFfi,
        customPath: assetDbPath,
      );
      rawDb = await quranDb.database;
    });

    tearDown(() async {
      await quranDb.close();
      QuranDatabase.resetForTesting();
    });

    test('Verify all required tables exist in database', () async {
      final isValid = await DatabaseMigrations.verifyIntegrity(rawDb);
      expect(isValid, isTrue);
    });

    test('Verify surahs table contains exactly 114 surahs', () async {
      final result = await quranDb.query(sql: 'SELECT COUNT(*) as count FROM surahs;');
      expect(result.first['count'], 114);

      // التأكد من سورة الفاتحة
      final fatihah = await quranDb.query(
        sql: 'SELECT * FROM surahs WHERE id = ?;',
        arguments: [1],
      );
      expect(fatihah.first['name_arabic'], 'الفاتحة');
      expect(fatihah.first['ayah_count'], 7);

      // التأكد من سورة البقرة
      final baqarah = await quranDb.query(
        sql: 'SELECT * FROM surahs WHERE id = ?;',
        arguments: [2],
      );
      expect(baqarah.first['name_arabic'], 'البقرة');
      expect(baqarah.first['ayah_count'], 286);
    });

    test('Verify ayahs table contains exactly 6236 verses according to Hafs standard', () async {
      final result = await quranDb.query(sql: 'SELECT COUNT(*) as count FROM ayahs;');
      expect(result.first['count'], 6236);

      // التأكد من استدراك الآية 1 في الفاتحة (البسملة)
      final bismillah = await quranDb.query(
        sql: 'SELECT * FROM ayahs WHERE surah_id = ? AND ayah_number = ?;',
        arguments: [1, 1],
      );
      expect(bismillah.isNotEmpty, isTrue);
      expect(bismillah.first['text_uthmani'], contains('بِسْمِ اللَّهِ الرَّحْمَٰنِ الرَّحِيمِ'));
      expect(bismillah.first['global_ayah_number'], 1);
    });

    test('Verify words and roots tables contain data and links', () async {
      final wordsCount = await quranDb.query(sql: 'SELECT COUNT(*) as count FROM words;');
      expect((wordsCount.first['count'] as int) > 70000, isTrue);

      final rootsCount = await quranDb.query(sql: 'SELECT COUNT(*) as count FROM roots;');
      expect((rootsCount.first['count'] as int) > 2000, isTrue);

      final linksCount = await quranDb.query(sql: 'SELECT COUNT(*) as count FROM word_roots;');
      expect((linksCount.first['count'] as int) > 50000, isTrue);
    });

    test('Verify required performance indexes exist in database', () async {
      final indexResults = await quranDb.query(
        sql: "SELECT name FROM sqlite_master WHERE type='index';",
      );
      final indexNames = indexResults.map((r) => r['name'] as String).toSet();

      final expectedIndexes = [
        'idx_ayahs_surah_number',
        'idx_ayahs_global',
        'idx_words_ayah',
        'idx_words_normalized',
        'idx_words_lemma',
        'idx_words_root',
        'idx_words_surah_ayah',
        'idx_words_root_ayah',
      ];

      for (final idx in expectedIndexes) {
        expect(indexNames.contains(idx), isTrue, reason: 'Index $idx should exist');
      }
    });

    test('Execute primary root JOIN query from TRD specifications', () async {
      // الاستعلام الأساسي المعتمد في TRD لجلب الآيات المرتبطة بجذر معين
      const sql = '''
      SELECT DISTINCT
          a.id,
          a.surah_id,
          a.ayah_number,
          a.global_ayah_number,
          a.text_uthmani,
          a.text_normalized,
          s.name_arabic
      FROM ayahs AS a
      INNER JOIN surahs AS s
          ON s.id = a.surah_id
      INNER JOIN words AS w
          ON w.ayah_id = a.id
      WHERE w.root_normalized = ?
      ORDER BY a.global_ayah_number;
      ''';

      // اختبار مع جذر 'حمد'
      final results = await quranDb.query(
        sql: sql,
        arguments: ['حمد'],
      );

      expect(results.isNotEmpty, isTrue);
      // التحقق من أن سورة الفاتحة ضمن نتائج جذر 'حمد' (الحمد لله رب العالمين)
      expect(results.any((r) => r['surah_id'] == 1), isTrue);
    });

    test('Test bookmarks CRUD operations with parameterized queries', () async {
      // إدخال علامة مرجعية
      final bookmarkId = await quranDb.insert(
        table: 'bookmarks',
        values: {
          'ayah_id': 1,
          'note': 'ملاحظة اختبارية في سورة الفاتحة',
          'created_at': DateTime.now().toIso8601String(),
        },
      );
      expect(bookmarkId, greaterThan(0));

      // استعلام العلامة المرجعية
      final bookmarks = await quranDb.query(
        sql: 'SELECT * FROM bookmarks WHERE id = ?;',
        arguments: [bookmarkId],
      );
      expect(bookmarks.first['note'], 'ملاحظة اختبارية في سورة الفاتحة');

      // حذف العلامة
      final deletedCount = await quranDb.delete(
        table: 'bookmarks',
        where: 'id = ?',
        whereArgs: [bookmarkId],
      );
      expect(deletedCount, 1);
    });

    test('Test reading_positions single record update and read', () async {
      // تحديث آخر موضع قراءة إلى سورة البقرة الآية 255
      await quranDb.update(
        table: 'reading_positions',
        values: {
          'surah_id': 2,
          'ayah_number': 255,
          'updated_at': DateTime.now().toIso8601String(),
        },
        where: 'id = ?',
        whereArgs: [1],
      );

      final position = await quranDb.query(
        sql: 'SELECT * FROM reading_positions WHERE id = 1;',
      );
      expect(position.first['surah_id'], 2);
      expect(position.first['ayah_number'], 255);
    });
  });
}
