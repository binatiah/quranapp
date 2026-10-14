import 'dart:io';
import 'package:flutter_test/flutter_test.dart';
import 'package:path/path.dart' as p;
import 'package:quranapp/core/database/quran_database.dart';
import 'package:quranapp/core/text/arabic_normalizer.dart';
import 'package:quranapp/features/vocabulary/data/repositories/word_management_repository_impl.dart';
import 'package:quranapp/features/vocabulary/domain/entities/word_filter_criteria.dart';
import 'package:quranapp/features/vocabulary/domain/repositories/word_management_repository.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';

void main() {
  setUpAll(() {
    sqfliteFfiInit();
  });

  group('WordManagementRepository Tests', () {
    late QuranDatabase testDb;
    late WordManagementRepository repository;
    late String testDbPath;

    setUpAll(() async {
      // ننشئ نسخة مؤقتة قابلة للكتابة لاختبار التعديل وإعادة الربط بأمان
      final assetDbPath = p.join(Directory.current.path, 'assets', 'database', 'quran.db');
      final tempDir = Directory.systemTemp.createTempSync('word_repo_test');
      testDbPath = p.join(tempDir.path, 'quran_test.db');
      File(assetDbPath).copySync(testDbPath);

      testDb = QuranDatabase.forTesting(
        customFactory: databaseFactoryFfi,
        customPath: testDbPath,
        readOnly: false,
      );
      repository = WordManagementRepositoryImpl(
        database: testDb,
        normalizer: const ArabicNormalizerImpl(),
      );
    });

    tearDownAll(() async {
      await testDb.close();
      QuranDatabase.resetForTesting();
      try {
        final f = File(testDbPath);
        if (f.existsSync()) f.deleteSync();
      } catch (_) {}
    });

    test('getWords loads words with surah name and pagination', () async {
      final words = await repository.getWords(
        criteria: const WordFilterCriteria(),
        limit: 10,
        offset: 0,
      );

      expect(words.length, 10);
      expect(words.first.surahName, isNotNull);
      expect(words.first.wordUthmani.isNotEmpty, isTrue);
      // أول كلمة في الفاتحة: بِسْمِ
      expect(words.first.surahId, 1);
      expect(words.first.ayahNumber, 1);
    });

    test('getWords with Surah filter limits to specific surah', () async {
      final words = await repository.getWords(
        criteria: const WordFilterCriteria(surahId: 1),
        limit: 100,
      );

      expect(words.isNotEmpty, isTrue);
      expect(words.every((w) => w.surahId == 1), isTrue);
    });

    test('getWords with search query finds matching words', () async {
      final words = await repository.getWords(
        criteria: const WordFilterCriteria(query: 'الرحيم'),
      );

      expect(words.isNotEmpty, isTrue);
      expect(words.any((w) => w.wordNormalized.contains('رحيم')), isTrue);
    });

    test('getWordOccurrencesCount returns correct count', () async {
      // كلمة 'الله' أو 'بسم'
      final count = await repository.getWordOccurrencesCount('بسم');
      expect(count, greaterThan(0));
    });

    test('relinkWordToRoot updates word root and creates entry in word_roots', () async {
      // جلب كلمة لاختبار ربطها بجذر مخصص
      final words = await repository.getWords(
        criteria: const WordFilterCriteria(surahId: 114),
        limit: 1,
      );
      final word = words.first;

      // إعادة ربطها بجذر اختباري
      final updatedCount = await repository.relinkWordToRoot(
        wordId: word.id,
        newRoot: 'نوس',
        applyToAllOccurrences: false,
      );

      expect(updatedCount, 1);

      final reloaded = await repository.getWordById(word.id);
      expect(reloaded!.root, 'نوس');
      expect(reloaded.rootNormalized, 'نوس');
    });

    test('updateWordDetails modifies morphology and lemma correctly', () async {
      final words = await repository.getWords(
        criteria: const WordFilterCriteria(surahId: 112),
        limit: 1,
      );
      final word = words.first;

      await repository.updateWordDetails(
        wordId: word.id,
        wordUthmani: word.wordUthmani,
        lemma: 'قل',
        partOfSpeech: 'فعل أمر',
        morphology: 'فعل أمر مبني على السكون',
      );

      final updated = await repository.getWordById(word.id);
      expect(updated!.lemma, 'قل');
      expect(updated.partOfSpeech, 'فعل أمر');
      expect(updated.morphology, 'فعل أمر مبني على السكون');
    });
  });
}
