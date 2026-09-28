import 'dart:io';
import 'package:flutter_test/flutter_test.dart';
import 'package:path/path.dart' as p;
import 'package:quranapp/core/database/quran_database.dart';
import 'package:quranapp/core/text/arabic_normalizer.dart';
import 'package:quranapp/features/quran_search/data/services/root_resolver_impl.dart';
import 'package:quranapp/features/quran_search/domain/entities/search_match_type.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';

void main() {
  setUpAll(() {
    sqfliteFfiInit();
  });

  group('RootResolver 6-Layers Unit & Integration Tests', () {
    late QuranDatabase testDb;
    late RootResolverImpl rootResolver;

    setUpAll(() async {
      final assetDbPath = p.join(Directory.current.path, 'assets', 'database', 'quran.db');

      testDb = QuranDatabase.forTesting(
        customFactory: databaseFactoryFfi,
        customPath: assetDbPath,
        readOnly: true,
      );
      rootResolver = RootResolverImpl(
        database: testDb,
        normalizer: const ArabicNormalizerImpl(),
      );
    });

    tearDownAll(() async {
      await testDb.close();
      QuranDatabase.resetForTesting();
    });

    test('Level 1: resolves root from word_normalized direct match', () async {
      final candidates = await rootResolver.resolve('يعلمون');
      expect(candidates.isNotEmpty, isTrue);

      final match = candidates.firstWhere((c) => c.root == 'علم');
      expect(match.confidence, greaterThanOrEqualTo(0.95));
      expect(match.isVerified, isTrue);
      expect(match.matchType, anyOf(equals(SearchMatchType.verifiedRoot), equals(SearchMatchType.lemma)));
    });

    test('Level 2: resolves root from lemma_normalized', () async {
      // كلمة 'عالمين' أصلها 'عالم' والجذر 'علم'
      final candidates = await rootResolver.resolve('عالمين');
      expect(candidates.isNotEmpty, isTrue);
      expect(candidates.any((c) => c.root == 'علم'), isTrue);
    });

    test('Level 3: resolves root when user directly enters a root_normalized', () async {
      // إدخال جذر مباشر مثل 'حمد'
      final candidates = await rootResolver.resolve('حمد');
      expect(candidates.isNotEmpty, isTrue);

      final direct = candidates.firstWhere((c) => c.root == 'حمد');
      expect(direct.isVerified, isTrue);
      expect(direct.confidence, greaterThanOrEqualTo(0.90));
    });

    test('Level 4: resolves root from local dictionary lexicon', () async {
      // كلمة 'الرحمن' ترتبط بالجذر 'رحم'
      final candidates = await rootResolver.resolve('الرحمن');
      expect(candidates.isNotEmpty, isTrue);
      expect(candidates.any((c) => c.root == 'رحم'), isTrue);
    });

    test('Level 5: infers root systematically from complex affixes and patterns', () async {
      // كلمة 'مستغفرين' تستأصل السوابق واللواحق لتصل للجذر 'غفر'
      final candidates = await rootResolver.resolve('مستغفرين');
      expect(candidates.isNotEmpty, isTrue);
      expect(candidates.any((c) => c.root == 'غفر'), isTrue);
    });

    test('Level 6: fallback suggestion by ordered characters is explicitly flagged as unverified', () async {
      // كلمة أو جذر تجريبي غير موجود بالقرآن مباشرة
      final candidates = await rootResolver.resolve('سلك');
      expect(candidates.isNotEmpty, isTrue);

      // التأكد من تصنيف أي نتيجة غير مؤكدة صراحة وفق TRD
      final unverified = candidates.where((c) => !c.isVerified);
      for (final cand in unverified) {
        expect(cand.matchType, equals(SearchMatchType.orderedCharactersSuggestion));
        expect(cand.confidence, lessThan(0.7));
        expect(cand.source, contains('تحتاج إلى مراجعة'));
      }
    });

    test('Results are deduplicated and sorted by confidence descending', () async {
      final candidates = await rootResolver.resolve('المفلحون');
      expect(candidates.isNotEmpty, isTrue);

      // التأكد من عدم وجود تكرار للجذور
      final rootsList = candidates.map((c) => c.root).toList();
      final rootsSet = rootsList.toSet();
      expect(rootsList.length, equals(rootsSet.length));

      // التأكد من الترتيب التنازلي لدرجة الثقة
      for (var i = 0; i < candidates.length - 1; i++) {
        expect(candidates[i].confidence, greaterThanOrEqualTo(candidates[i + 1].confidence));
      }
    });
  });
}
