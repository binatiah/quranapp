import 'dart:io';
import 'package:flutter_test/flutter_test.dart';
import 'package:path/path.dart' as p;
import 'package:quranapp/core/database/quran_database.dart';
import 'package:quranapp/features/quran_search/data/services/search_context_service_impl.dart';
import 'package:quranapp/features/quran_search/domain/entities/ayah_search_result.dart';
import 'package:quranapp/features/quran_search/domain/entities/search_match_type.dart';
import 'package:quranapp/features/quran_search/domain/services/ayah_range_merger.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';

void main() {
  setUpAll(() {
    sqfliteFfiInit();
  });

  group('SearchContextService Integration Tests', () {
    late QuranDatabase testDb;
    late SearchContextServiceImpl contextService;

    setUpAll(() async {
      final assetDbPath = p.join(Directory.current.path, 'assets', 'database', 'quran.db');

      testDb = QuranDatabase.forTesting(
        customFactory: databaseFactoryFfi,
        customPath: assetDbPath,
        readOnly: true,
      );
      contextService = SearchContextServiceImpl(
        database: testDb,
        rangeMerger: const AyahRangeMerger(),
      );
    });

    tearDownAll(() async {
      await testDb.close();
      QuranDatabase.resetForTesting();
    });

    test('loadSingleAyahContext loads verses slice with safe clipping', () async {
      // سورة الفاتحة الآية 2 مع سابق 1 ولاحق 2
      final group = await contextService.loadSingleAyahContext(
        surahId: 1,
        ayahNumber: 2,
        beforeCount: 1,
        afterCount: 2,
      );

      expect(group, isNotNull);
      expect(group!.surahId, equals(1));
      expect(group.surahName, equals('الفاتحة'));
      expect(group.range.startAyah, equals(1)); // 2 - 1 = 1
      expect(group.range.endAyah, equals(4)); // 2 + 2 = 4
      expect(group.ayahs.length, equals(4));
      expect(group.matchedAyahNumbers, contains(2));

      // التأكد من تسلسل أرقام الآيات
      expect(group.ayahs[0].ayahNumber, equals(1));
      expect(group.ayahs[1].ayahNumber, equals(2));
      expect(group.ayahs[2].ayahNumber, equals(3));
      expect(group.ayahs[3].ayahNumber, equals(4));
    });

    test('loadSingleAyahContext clips at the end of the surah', () async {
      // سورة الفاتحة الآية 6 مع لاحق 10
      final group = await contextService.loadSingleAyahContext(
        surahId: 1,
        ayahNumber: 6,
        beforeCount: 1,
        afterCount: 10,
      );

      expect(group, isNotNull);
      expect(group!.range.startAyah, equals(5));
      expect(group.range.endAyah, equals(7)); // مقصوص عند آية 7
      expect(group.ayahs.length, equals(3)); // آيات 5، 6، 7
    });

    test('loadContext merges overlapping results into a single context group', () async {
      // نتائج في سورة البقرة الآيات 20 و 22 و 23
      final searchResults = [
        const AyahSearchResult(
          ayahId: 27,
          surahId: 2,
          surahName: 'البقرة',
          ayahNumber: 20,
          globalAyahNumber: 27,
          textUthmani: 'يَكَادُ الْبَرْقُ...',
          matchedWords: ['البرق'],
          matchType: SearchMatchType.exact,
        ),
        const AyahSearchResult(
          ayahId: 29,
          surahId: 2,
          surahName: 'البقرة',
          ayahNumber: 22,
          globalAyahNumber: 29,
          textUthmani: 'الَّذِي جَعَلَ لَكُمُ...',
          matchedWords: ['جعل'],
          matchType: SearchMatchType.exact,
        ),
        const AyahSearchResult(
          ayahId: 30,
          surahId: 2,
          surahName: 'البقرة',
          ayahNumber: 23,
          globalAyahNumber: 30,
          textUthmani: 'وَإِن كُنتُمْ فِي رَيْبٍ...',
          matchedWords: ['ريب'],
          matchType: SearchMatchType.exact,
        ),
      ];

      // مع سابق 5 ولاحق 4:
      // 20 -> 15 إلى 24
      // 22 -> 17 إلى 26
      // 23 -> 18 إلى 27
      // النطاق المدمج يجب أن يكون 15 إلى 27 (13 آية) دون أي تكرار
      final groups = await contextService.loadContext(
        results: searchResults,
        beforeCount: 5,
        afterCount: 4,
      );

      expect(groups.length, equals(1));
      final group = groups.first;
      expect(group.surahId, equals(2));
      expect(group.surahName, equals('البقرة'));
      expect(group.range.startAyah, equals(15));
      expect(group.range.endAyah, equals(27));
      expect(group.ayahs.length, equals(13));
      expect(group.matchedAyahNumbers, equals({20, 22, 23}));

      // التأكد من أن جميع الآيات فريدة ومرتبة تصاعدياً
      final ayahNumbers = group.ayahs.map((a) => a.ayahNumber).toList();
      for (var i = 0; i < ayahNumbers.length; i++) {
        expect(ayahNumbers[i], equals(15 + i));
      }
    });

    test('loadContext keeps different surahs in separate groups without bleeding', () async {
      final searchResults = [
        const AyahSearchResult(
          ayahId: 2,
          surahId: 1,
          surahName: 'الفاتحة',
          ayahNumber: 2,
          globalAyahNumber: 2,
          textUthmani: 'الْحَمْدُ لِلَّهِ...',
          matchedWords: ['الحمد'],
          matchType: SearchMatchType.exact,
        ),
        const AyahSearchResult(
          ayahId: 8,
          surahId: 2,
          surahName: 'البقرة',
          ayahNumber: 1,
          globalAyahNumber: 8,
          textUthmani: 'الم',
          matchedWords: ['الم'],
          matchType: SearchMatchType.exact,
        ),
      ];

      final groups = await contextService.loadContext(
        results: searchResults,
        beforeCount: 2,
        afterCount: 2,
      );

      expect(groups.length, equals(2));
      expect(groups[0].surahId, equals(1));
      expect(groups[1].surahId, equals(2));
    });
  });
}
