import 'dart:io';
import 'package:flutter_test/flutter_test.dart';
import 'package:path/path.dart' as p;
import 'package:quranapp/core/database/quran_database.dart';
import 'package:quranapp/features/quran_search/data/repositories/quran_search_repository_impl.dart';
import 'package:quranapp/features/quran_search/domain/entities/search_match_type.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';

void main() {
  setUpAll(() {
    sqfliteFfiInit();
  });

  group('QuranSearchRepository Unit & Integration Tests', () {
    late QuranDatabase testDb;
    late QuranSearchRepositoryImpl searchRepository;

    setUp(() async {
      QuranDatabase.resetForTesting();
      final assetDbPath = p.join(Directory.current.path, 'assets', 'database', 'quran.db');

      testDb = QuranDatabase.forTesting(
        customFactory: databaseFactoryFfi,
        customPath: assetDbPath,
      );
      searchRepository = QuranSearchRepositoryImpl(database: testDb);
    });

    tearDown(() async {
      await testDb.close();
      QuranDatabase.resetForTesting();
    });

    test('searchExactWord finds verses by exact word uthmani', () async {
      final results = await searchRepository.searchExactWord('الْحَمْدُ');
      expect(results.isNotEmpty, isTrue);
      expect(results.first.matchType, equals(SearchMatchType.exact));
      // الفاتحة يجب أن تكون ضمن النتائج
      expect(results.any((r) => r.surahId == 1 && r.ayahNumber == 2), isTrue);
    });

    test('searchText finds verses by normalized word without diacritics', () async {
      // بحث دون تشكيل وبدون ألف وصل
      final results = await searchRepository.searchText('الحمد');
      expect(results.isNotEmpty, isTrue);
      expect(results.first.matchType, equals(SearchMatchType.normalized));
      expect(results.any((r) => r.surahId == 1), isTrue);
    });

    test('searchText with surahId filter scopes results to target surah only', () async {
      final results = await searchRepository.searchText('الرحمن', surahId: 1);
      expect(results.isNotEmpty, isTrue);
      expect(results.every((r) => r.surahId == 1), isTrue);
    });

    test('resolveRoots detects root candidate from normalized word and lexicon', () async {
      // كلمة 'يعلمون' يجب أن ترجع الجذر 'علم'
      final candidates = await searchRepository.resolveRoots('يعلمون');
      expect(candidates.isNotEmpty, isTrue);
      expect(candidates.any((c) => c.root == 'علم'), isTrue);
      expect(candidates.first.isVerified, isTrue);
    });

    test('searchAyahsByRoot executes single JOIN query returning verses for root', () async {
      final results = await searchRepository.searchAyahsByRoot('حمد');
      expect(results.isNotEmpty, isTrue);
      expect(results.first.matchType, equals(SearchMatchType.verifiedRoot));
      expect(results.first.matchedRoot, 'حمد');
      // الفاتحة الآية 2 (الحمد لله رب العالمين)
      expect(results.any((r) => r.surahId == 1 && r.ayahNumber == 2), isTrue);
    });

    test('getWordsByRoot returns derived vocabulary for given root', () async {
      final words = await searchRepository.getWordsByRoot('علم');
      expect(words.isNotEmpty, isTrue);
      expect(words.every((w) => w.rootNormalized == 'علم'), isTrue);
    });

    test('getRootDetails returns root statistics', () async {
      final details = await searchRepository.getRootDetails('علم');
      expect(details, isNotNull);
      expect(details!.rootNormalized, 'علم');
      expect(details.occurrencesCount, greaterThan(0));
    });
  });
}
