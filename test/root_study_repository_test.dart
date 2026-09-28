import 'dart:io';
import 'package:flutter_test/flutter_test.dart';
import 'package:path/path.dart' as p;
import 'package:quranapp/core/database/quran_database.dart';
import 'package:quranapp/core/text/arabic_normalizer.dart';
import 'package:quranapp/features/root_study/data/repositories/root_study_repository_impl.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';

void main() {
  setUpAll(() {
    sqfliteFfiInit();
  });

  group('RootStudyRepository Unit & Integration Tests', () {
    late QuranDatabase testDb;
    late RootStudyRepositoryImpl repository;

    setUpAll(() async {
      final assetDbPath = p.join(Directory.current.path, 'assets', 'database', 'quran.db');

      testDb = QuranDatabase.forTesting(
        customFactory: databaseFactoryFfi,
        customPath: assetDbPath,
        readOnly: true,
      );
      repository = RootStudyRepositoryImpl(
        database: testDb,
        normalizer: const ArabicNormalizerImpl(),
      );
    });

    tearDownAll(() async {
      await testDb.close();
      QuranDatabase.resetForTesting();
    });

    test('getDerivedWords returns distinct words with occurrence count in descending order', () async {
      final words = await repository.getDerivedWords('علم');
      expect(words.isNotEmpty, isTrue);

      // التأكد من الترتيب التنازلي للتكرار
      for (var i = 0; i < words.length - 1; i++) {
        expect(words[i].occurrenceCount, greaterThanOrEqualTo(words[i + 1].occurrenceCount));
      }

      // التأكد من أن الكلمات المشتقة تتضمن أشكالاً معروفة مثل 'يعلمون' أو 'علم'
      final normalizedForms = words.map((w) => w.wordNormalized).toList();
      expect(normalizedForms.any((form) => form.contains('علم')), isTrue);
    });

    test('getSurahOccurrences returns occurrence counts per surah', () async {
      final surahs = await repository.getSurahOccurrences('حمد');
      expect(surahs.isNotEmpty, isTrue);

      // سورة الفاتحة يجب أن تكون ضمن السور التي ورد فيها جذر 'حمد'
      expect(surahs.any((s) => s.surahId == 1), isTrue);

      // التأكد من أن كل سجل يحتوي على اسم سورة وعدد تكرار موجب
      for (final item in surahs) {
        expect(item.surahName.isNotEmpty, isTrue);
        expect(item.occurrenceCount, greaterThan(0));
      }
    });

    test('getVersesForRoot returns verses matching root using single JOIN query', () async {
      final verses = await repository.getVersesForRoot('حمد');
      expect(verses.isNotEmpty, isTrue);

      // الفاتحة الآية 2 (الحمد لله رب العالمين)
      final fatihahVerse = verses.firstWhere((v) => v.surahId == 1 && v.ayahNumber == 2);
      expect(fatihahVerse.textUthmani.isNotEmpty, isTrue);
      expect(fatihahVerse.matchedWords.isNotEmpty, isTrue);
    });

    test('getVersesForRoot with surahId filter restricts verses to specified surah', () async {
      final verses = await repository.getVersesForRoot('علم', surahId: 2);
      expect(verses.isNotEmpty, isTrue);
      expect(verses.every((v) => v.surahId == 2), isTrue);
    });

    test('getVersesForRoot with wordNormalizedFilter restricts verses to specified derived word', () async {
      final verses = await repository.getVersesForRoot('علم', wordNormalizedFilter: 'يعلمون');
      expect(verses.isNotEmpty, isTrue);
      for (final v in verses) {
        expect(v.matchedWords.any((w) => w.contains('يَعْلَمُونَ') || w.contains('يعلمون')), isTrue);
      }
    });

    test('getRootStudyData aggregates all metrics correctly into RootStudyData', () async {
      final data = await repository.getRootStudyData('حمد');
      expect(data, isNotNull);
      expect(data!.root.rootNormalized, equals('حمد'));
      expect(data.totalOccurrences, greaterThan(0));
      expect(data.uniqueWordsCount, equals(data.derivedWords.length));
      expect(data.surahsCount, equals(data.surahOccurrences.length));
      expect(data.verses.isNotEmpty, isTrue);
    });
  });
}
