import 'dart:io';
import 'package:flutter_test/flutter_test.dart';
import 'package:path/path.dart' as p;
import 'package:quranapp/core/database/quran_database.dart';
import 'package:quranapp/core/text/arabic_normalizer.dart';
import 'package:quranapp/features/bookmarks/data/repositories/bookmarks_repository_impl.dart';
import 'package:quranapp/features/quran_reader/data/repositories/quran_repository_impl.dart';
import 'package:quranapp/features/quran_search/data/repositories/quran_search_repository_impl.dart';
import 'package:quranapp/features/quran_search/domain/entities/ayah_range.dart';
import 'package:quranapp/features/quran_search/domain/services/ayah_range_merger.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';

void main() {
  setUpAll(() {
    sqfliteFfiInit();
  });

  group('Phase 8: Security & Parameterized Query Tests', () {
    late Directory tempDir;
    late String tempDbPath;
    late QuranDatabase quranDb;
    late QuranSearchRepositoryImpl searchRepo;
    late BookmarksRepositoryImpl bookmarksRepo;

    setUp(() async {
      QuranDatabase.resetForTesting();
      tempDir = Directory.systemTemp.createTempSync('quran_security_test_');
      final assetDb = File(p.join(Directory.current.path, 'assets', 'database', 'quran.db'));
      tempDbPath = p.join(tempDir.path, 'quran_security.db');
      await assetDb.copy(tempDbPath);

      quranDb = QuranDatabase.forTesting(
        customFactory: databaseFactoryFfi,
        customPath: tempDbPath,
      );

      searchRepo = QuranSearchRepositoryImpl(database: quranDb);
      bookmarksRepo = BookmarksRepositoryImpl(database: quranDb);
    });

    tearDown(() async {
      await quranDb.close();
      QuranDatabase.resetForTesting();
      try {
        if (tempDir.existsSync()) {
          tempDir.deleteSync(recursive: true);
        }
      } catch (_) {}
    });

    test('SQL Injection payloads in searchExactWord are safely handled as literals', () async {
      const payloads = [
        "' OR '1'='1",
        "'; DROP TABLE ayahs; --",
        "admin'--",
        "' UNION SELECT * FROM surahs --",
        "\" OR 1=1 --",
        "1; DELETE FROM words;",
      ];

      for (final payload in payloads) {
        final results = await searchRepo.searchExactWord(payload);
        // يجب ألا يتسبب في خطأ برمجي أو استرجاع كافة السجلات
        expect(results, isEmpty);
      }

      // التأكد من بقاء الجداول سليمة بعد محاولات الحقن
      final count = await quranDb.query(sql: 'SELECT COUNT(*) as count FROM ayahs;');
      expect(count.first['count'], 6236);
    });

    test('SQL Injection payloads in searchText normalized query are safe', () async {
      const payloads = [
        "' OR '1'='1",
        "'; DROP TABLE words; --",
        "%'; SELECT * FROM surahs; --",
      ];

      for (final payload in payloads) {
        final results = await searchRepo.searchText(payload);
        expect(results, isNotNull);
      }

      // التحقق من سلامة جدول الكلمات
      final wordsCount = await quranDb.query(sql: 'SELECT COUNT(*) as count FROM words;');
      expect(wordsCount.first['count'], greaterThan(70000));
    });

    test('SQL Injection in Bookmark notes is safely sanitized via parameterized query', () async {
      const maliciousNote = "تدبر'; DROP TABLE bookmarks; -- ' OR 1=1";

      final bookmarkId = await bookmarksRepo.addBookmark(
        ayahId: 1,
        note: maliciousNote,
      );
      expect(bookmarkId, greaterThan(0));

      final saved = await bookmarksRepo.getBookmarkByAyahId(1);
      expect(saved, isNotNull);
      expect(saved!.note, maliciousNote);

      // التأكد من بقاء جدول المفضلة سليمًا
      final checkTable = await quranDb.query(sql: 'SELECT COUNT(*) as count FROM bookmarks;');
      expect(checkTable.first['count'], 1);
    });
  });

  group('Phase 8: Boundary & Special Ayah Tests', () {
    late QuranDatabase quranDb;
    late QuranRepositoryImpl quranRepo;

    setUp(() {
      QuranDatabase.resetForTesting();
      final assetDbPath = p.join(Directory.current.path, 'assets', 'database', 'quran.db');
      quranDb = QuranDatabase.forTesting(
        customFactory: databaseFactoryFfi,
        customPath: assetDbPath,
        readOnly: true,
      );
      quranRepo = QuranRepositoryImpl(database: quranDb);
    });

    tearDown(() async {
      await quranDb.close();
      QuranDatabase.resetForTesting();
    });

    test('First Ayah (Al-Fatihah, Ayah 1) integrity', () async {
      final ayah = await quranRepo.getAyah(1, 1);
      expect(ayah, isNotNull);
      expect(ayah!.ayahNumber, 1);
      expect(ayah.globalAyahNumber, 1);
      expect(ayah.textUthmani, contains('بِسْمِ اللَّهِ الرَّحْمَٰنِ الرَّحِيمِ'));
    });

    test('Last Ayah (An-Nas, Ayah 6) integrity', () async {
      final ayah = await quranRepo.getAyah(114, 6);
      expect(ayah, isNotNull);
      expect(ayah!.ayahNumber, 6);
      expect(ayah.globalAyahNumber, 6236);
      expect(ayah.textUthmani, contains('مِنَ الْجِنَّةِ وَالنَّاسِ'));
    });

    test('Longest Ayah (Al-Baqarah, Ayah 282 - Ayat Al-Dayn) loads without truncation', () async {
      final ayah = await quranRepo.getAyah(2, 282);
      expect(ayah, isNotNull);
      expect(ayah!.textUthmani.length, greaterThan(500));
      expect(ayah.textUthmani, contains('يَا أَيُّهَا الَّذِينَ آمَنُوا إِذَا تَدَايَنْتُمْ'));
      expect(ayah.textUthmani, contains('وَاتَّقُوا اللَّهَ وَيُعَلِّمُكُمُ اللَّهُ'));
    });

    test('Short Surah boundary handling (Al-Kawthar, 3 Ayahs)', () async {
      final ayahs = await quranRepo.getSurahAyahs(108);
      expect(ayahs.length, 3);
      expect(ayahs.first.ayahNumber, 1);
      expect(ayahs.last.ayahNumber, 3);
    });

    test('All 114 Surahs have valid non-empty names and correct verse counts', () async {
      final surahs = await quranRepo.getSurahs();
      expect(surahs.length, 114);

      int totalVerses = 0;
      for (final s in surahs) {
        expect(s.id, greaterThan(0));
        expect(s.nameArabic.trim().isNotEmpty, isTrue);
        expect(s.ayahCount, greaterThan(0));
        totalVerses += s.ayahCount;
      }
      expect(totalVerses, 6236);
    });
  });

  group('Phase 8: ArabicNormalizer Edge Cases', () {
    const normalizer = ArabicNormalizerImpl();

    test('Handles emojis, symbols, and non-Arabic text gracefully', () async {
      expect(normalizer.removeDiacritics('📖 🕋 ✨ Quran'), '📖 🕋 ✨ Quran');
      expect(normalizer.normalizeForSearch('📖 🕋 ✨'), '');
      expect(normalizer.normalizeForSearch(''), '');
      expect(normalizer.normalizeForSearch('   '), '');
    });

    test('Strips complex Quranic signs and punctuation', () async {
      // علامات الوقف القرآني: ۖ ۗ ۘ ۙ ۚ ۛ ۜ ۞ ۟ ۠ ۡ ۢ ۣ
      const quranicText = 'الْحَمْدُ لِلَّهِ رَبِّ الْعَالَمِينَ ۝١ ۘ ۚ ۖ';
      final normalized = normalizer.normalizeForSearch(quranicText);
      expect(normalized, 'الحمد لله رب العالمين');
    });

    test('Tokenize handles edge cases with multiple spaces and punctuation', () async {
      final tokens = normalizer.tokenize('   قُلْ   هُوَ   اللَّهُ   أَحَدٌ   ');
      expect(tokens, ['قل', 'هو', 'الله', 'احد']);
    });
  });

  group('Phase 8: AyahRangeMerger Extreme Edge Cases', () {
    const merger = AyahRangeMerger();

    test('Single verse range with 0 before and 0 after', () {
      final range = merger.calculateRange(
        surahId: 1,
        ayahNumber: 1,
        beforeCount: 0,
        afterCount: 0,
        surahAyahCount: 7,
      );
      expect(range.startAyah, 1);
      expect(range.endAyah, 1);
    });

    test('Massive before and after count on a short Surah clamps safely', () {
      final range = merger.calculateRange(
        surahId: 112,
        ayahNumber: 2,
        beforeCount: 100,
        afterCount: 100,
        surahAyahCount: 4,
      );
      expect(range.startAyah, 1);
      expect(range.endAyah, 4);
    });

    test('Merging complete Surah range with internal sub-ranges', () {
      final merged = merger.mergeRanges([
        const AyahRange(surahId: 1, startAyah: 1, endAyah: 7),
        const AyahRange(surahId: 1, startAyah: 2, endAyah: 4),
        const AyahRange(surahId: 1, startAyah: 6, endAyah: 7),
      ]);
      expect(merged.length, 1);
      expect(merged.first.startAyah, 1);
      expect(merged.first.endAyah, 7);
    });

    test('Empty ranges list returns empty list', () {
      final merged = merger.mergeRanges([]);
      expect(merged, isEmpty);
    });
  });
}
