import 'dart:convert';
import 'dart:io';
import 'package:flutter_test/flutter_test.dart';
import 'package:path/path.dart' as p;
import 'package:quranapp/core/database/quran_database.dart';
import 'package:quranapp/core/text/arabic_normalizer.dart';
import 'package:quranapp/features/root_study/data/repositories/root_study_repository_impl.dart';
import 'package:quranapp/features/root_study/domain/entities/derived_word.dart';
import 'package:quranapp/features/root_study/domain/services/morphology_classifier.dart';
import 'package:quranapp/features/vocabulary/data/repositories/lexicon_io_repository_impl.dart';
import 'package:quranapp/features/vocabulary/data/repositories/morphology_audit_repository_impl.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';

void main() {
  setUpAll(() {
    sqfliteFfiInit();
  });

  group('MorphologyClassifier Unit Tests', () {
    test('classifies past, present verbs, active participles and verbal nouns', () {
      const classifier = MorphologyClassifier();
      final words = [
        const DerivedWord(wordUthmani: 'عَلِمَ', wordNormalized: 'علم', occurrenceCount: 5),
        const DerivedWord(wordUthmani: 'يَعْلَمُونَ', wordNormalized: 'يعلمون', occurrenceCount: 20),
        const DerivedWord(wordUthmani: 'عَالِمُ', wordNormalized: 'عالم', occurrenceCount: 10),
        const DerivedWord(wordUthmani: 'عِلْمًا', wordNormalized: 'علما', occurrenceCount: 15),
      ];

      final tree = classifier.classify(
        root: 'علم',
        rootNormalized: 'علم',
        words: words,
      );

      expect(tree.root, 'علم');
      expect(tree.branches, isNotEmpty);
      expect(tree.totalOccurrences, 50);

      final subCats = tree.branches.map((b) => b.subCategory).toList();
      expect(subCats.any((c) => c.contains('ماضية') || c.contains('مضارعة')), isTrue);
    });
  });

  group('Lexicon and Morphology Repository Integration Tests', () {
    late QuranDatabase testDb;
    late String testDbPath;
    late RootStudyRepositoryImpl rootStudyRepo;
    late LexiconIORepositoryImpl lexiconIoRepo;
    late MorphologyAuditRepositoryImpl auditRepo;

    setUpAll(() async {
      final assetDbPath = p.join(Directory.current.path, 'assets', 'database', 'quran.db');
      final tempDir = Directory.systemTemp.createTempSync('morph_lex_test');
      testDbPath = p.join(tempDir.path, 'quran_test.db');
      File(assetDbPath).copySync(testDbPath);

      testDb = QuranDatabase.forTesting(
        customFactory: databaseFactoryFfi,
        customPath: testDbPath,
        readOnly: false,
      );

      const normalizer = ArabicNormalizerImpl();
      rootStudyRepo = RootStudyRepositoryImpl(database: testDb, normalizer: normalizer);
      lexiconIoRepo = LexiconIORepositoryImpl(database: testDb, normalizer: normalizer);
      auditRepo = MorphologyAuditRepositoryImpl(database: testDb, normalizer: normalizer);
    });

    tearDownAll(() async {
      await testDb.close();
      QuranDatabase.resetForTesting();
      try {
        final f = File(testDbPath);
        if (f.existsSync()) f.deleteSync();
      } catch (_) {}
    });

    test('getMorphologyTree constructs derivation branches for root "علم"', () async {
      final tree = await rootStudyRepo.getMorphologyTree('علم');
      expect(tree.root, 'علم');
      expect(tree.branches, isNotEmpty);
      expect(tree.totalOccurrences, greaterThan(0));

      final branchTitles = tree.branches.map((b) => b.subCategory).toList();
      expect(
        branchTitles.any((t) =>
            t.contains('ماضية') ||
            t.contains('مضارعة') ||
            t.contains('أسماء') ||
            t.contains('مصادر')),
        isTrue,
      );
    });

    test('exportLexiconJson generates valid JSON and importLexiconJson merges correctly', () async {
      final jsonStr = await lexiconIoRepo.exportLexiconJson(customOnly: false, pretty: false);
      expect(jsonStr, isNotEmpty);
      final decoded = jsonDecode(jsonStr) as Map<String, dynamic>;
      expect(decoded.containsKey('roots'), isTrue);
      expect(decoded.containsKey('word_links'), isTrue);

      // اختبار الاستيراد الآمن لحزمة مخصصة
      final customJson = jsonEncode({
        'version': '1.0',
        'exported_at': DateTime.now().toIso8601String(),
        'roots': [
          {
            'root': 'جذر_تجريبي',
            'meaning': 'معنى تجريبي لاختبار الاستيراد',
          }
        ],
        'word_links': [
          {
            'word_id': 1,
            'root': 'جذر_تجريبي',
            'word_uthmani': 'بِسْمِ',
          }
        ]
      });

      final result = await lexiconIoRepo.importLexiconJson(customJson);
      expect(result.isSuccess, isTrue);
      expect(result.importedRootsCount, 1);
      expect(result.updatedWordsCount, 1);

      // التحقق من أن الكلمة رقم 1 تم ربطها بالفعل
      final rows = await testDb.query(
        sql: 'SELECT root FROM words WHERE id = 1;',
      );
      expect(rows.first['root'], 'جذر_تجريبي');
    });

    test('MorphologyAuditRepository statistics and batch relink functionality', () async {
      final stats = await auditRepo.getAuditStats();
      expect(stats.totalWords, greaterThan(70000));
      expect(stats.wordsWithRoot, greaterThan(60000));
      expect(stats.totalUniqueRoots, greaterThan(1500));
      expect(stats.rootCoveragePercentage, greaterThan(80.0));

      // جلب كلمات بدون جذر للتدقيق
      final items = await auditRepo.getAuditItems(
        withoutRootOnly: true,
        limit: 5,
        offset: 0,
      );

      if (items.isNotEmpty) {
        final targetIds = items.take(2).map((e) => e.wordId).toList();
        final count = await auditRepo.batchRelinkWords(
          wordIds: targetIds,
          newRoot: 'علم',
          applyToAllOccurrences: false,
        );

        expect(count, targetIds.length);

        // التحقق من قاعدة البيانات
        for (final id in targetIds) {
          final res = await testDb.query(
            sql: 'SELECT root FROM words WHERE id = ?;',
            arguments: [id],
          );
          expect(res.first['root'], 'علم');
        }
      }
    });
  });
}
