import 'package:flutter_test/flutter_test.dart';
import 'package:quranapp/core/constants/ui_state.dart';
import 'package:quranapp/features/bookmarks/domain/entities/bookmark.dart';
import 'package:quranapp/features/quran_reader/domain/entities/ayah.dart';
import 'package:quranapp/features/quran_reader/domain/entities/reading_position.dart';
import 'package:quranapp/features/quran_reader/domain/entities/surah.dart';
import 'package:quranapp/features/quran_search/domain/entities/ayah_context_group.dart';
import 'package:quranapp/features/quran_search/domain/entities/ayah_range.dart';
import 'package:quranapp/features/quran_search/domain/entities/ayah_search_result.dart';
import 'package:quranapp/features/quran_search/domain/entities/quran_root.dart';
import 'package:quranapp/features/quran_search/domain/entities/quran_word.dart';
import 'package:quranapp/features/quran_search/domain/entities/root_candidate.dart';
import 'package:quranapp/features/quran_search/domain/entities/search_match_type.dart';

void main() {
  group('Domain Entities Tests', () {
    test('Surah entity serialization and copyWith', () {
      const surah = Surah(
        id: 1,
        nameArabic: 'الفاتحة',
        nameEnglish: 'Al-Fatiha',
        revelationType: 'مكية',
        ayahCount: 7,
        revelationOrder: 5,
        startPage: 1,
      );

      final map = surah.toMap();
      expect(map['id'], 1);
      expect(map['name_arabic'], 'الفاتحة');
      expect(map['ayah_count'], 7);

      final fromMap = Surah.fromMap(map);
      expect(fromMap, equals(surah));

      final modified = surah.copyWith(ayahCount: 8);
      expect(modified.ayahCount, 8);
      expect(modified.id, surah.id);
    });

    test('Ayah entity serialization and integrity', () {
      const ayah = Ayah(
        id: 1,
        surahId: 1,
        ayahNumber: 1,
        globalAyahNumber: 1,
        pageNumber: 1,
        juzNumber: 1,
        hizbNumber: 1,
        textUthmani: 'بِسْمِ اللَّهِ الرَّحْمَٰنِ الرَّحِيمِ',
        textSimple: 'بسم الله الرحمن الرحيم',
        textNormalized: 'بسم الله الرحمن الرحيم',
      );

      final map = ayah.toMap();
      expect(map['surah_id'], 1);
      expect(map['ayah_number'], 1);

      final fromMap = Ayah.fromMap(map);
      expect(fromMap, equals(ayah));
    });

    test('ReadingPosition entity serialization', () {
      const pos = ReadingPosition(
        surahId: 2,
        ayahNumber: 255,
        updatedAt: '2026-09-28T12:00:00Z',
      );

      final map = pos.toMap();
      expect(map['surah_id'], 2);
      expect(map['ayah_number'], 255);

      final fromMap = ReadingPosition.fromMap(map);
      expect(fromMap, equals(pos));
    });

    test('AyahRange overlapsOrAdjacent and mergeWith logic', () {
      const range1 = AyahRange(
        surahId: 2,
        startAyah: 15,
        endAyah: 20,
        targetAyahNumbers: {18},
      );

      const range2 = AyahRange(
        surahId: 2,
        startAyah: 19,
        endAyah: 25,
        targetAyahNumbers: {22},
      );

      // متداخلان
      expect(range1.overlapsOrAdjacent(range2), isTrue);

      final merged = range1.mergeWith(range2);
      expect(merged.surahId, 2);
      expect(merged.startAyah, 15);
      expect(merged.endAyah, 25);
      expect(merged.targetAyahNumbers, equals({18, 22}));

      // نطاق غير متداخل
      const rangeFar = AyahRange(
        surahId: 2,
        startAyah: 35,
        endAyah: 40,
      );
      expect(range1.overlapsOrAdjacent(rangeFar), isFalse);

      // نطاق في سورة أخرى
      const rangeOtherSurah = AyahRange(
        surahId: 3,
        startAyah: 15,
        endAyah: 20,
      );
      expect(range1.overlapsOrAdjacent(rangeOtherSurah), isFalse);
    });

    test('AyahContextGroup entity copyWith and integrity', () {
      const group = AyahContextGroup(
        surahId: 2,
        surahName: 'البقرة',
        range: AyahRange(surahId: 2, startAyah: 18, endAyah: 22),
        ayahs: [],
        matchedAyahNumbers: {20},
      );

      expect(group.surahName, 'البقرة');
      expect(group.matchedAyahNumbers.contains(20), isTrue);
      final copied = group.copyWith(surahName: 'سورة البقرة');
      expect(copied.surahName, 'سورة البقرة');
    });

    test('AyahSearchResult and SearchMatchType verification status', () {
      const result = AyahSearchResult(
        ayahId: 10,
        surahId: 2,
        surahName: 'البقرة',
        ayahNumber: 20,
        globalAyahNumber: 27,
        textUthmani: 'يَكَادُ الْبَرْقُ يَخْطَفُ أَبْصَارَهُمْ',
        matchedWords: ['أَبْصَارَهُمْ'],
        matchType: SearchMatchType.verifiedRoot,
        matchedRoot: 'بصر',
      );

      expect(result.matchType.isVerified, isTrue);
      expect(SearchMatchType.orderedCharactersSuggestion.isVerified, isFalse);
      expect(result.surahName, 'البقرة');
    });

    test('QuranWord entity serialization', () {
      const word = QuranWord(
        id: 1,
        ayahId: 1,
        surahId: 1,
        ayahNumber: 1,
        wordPosition: 1,
        wordUthmani: 'بِسْمِ',
        wordSimple: 'بسم',
        wordNormalized: 'بسم',
        root: 'س-م-و',
        rootNormalized: 'سمو',
      );

      final map = word.toMap();
      expect(map['word_uthmani'], 'بِسْمِ');
      expect(map['root_normalized'], 'سمو');

      final fromMap = QuranWord.fromMap(map);
      expect(fromMap, equals(word));
    });

    test('QuranRoot entity serialization', () {
      const root = QuranRoot(
        id: 1,
        root: 'عَلِمَ',
        rootNormalized: 'علم',
        descriptionAr: 'العلم والمعرفة',
        wordsCount: 15,
        occurrencesCount: 854,
      );

      final map = root.toMap();
      expect(map['root_normalized'], 'علم');
      expect(QuranRoot.fromMap(map).rootNormalized, 'علم');
    });

    test('RootCandidate properties and copyWith', () {
      const candidate = RootCandidate(
        root: 'علم',
        confidence: 0.95,
        source: 'Quranic Arabic Corpus',
        isVerified: true,
        matchType: SearchMatchType.verifiedRoot,
      );

      expect(candidate.isVerified, isTrue);
      expect(candidate.confidence, 0.95);
      final copied = candidate.copyWith(confidence: 1.0);
      expect(copied.confidence, 1.0);
    });

    test('Bookmark serialization and copyWith', () {
      const bookmark = Bookmark(
        id: 1,
        ayahId: 5,
        surahId: 1,
        surahName: 'الفاتحة',
        ayahNumber: 5,
        ayahText: 'إِيَّاكَ نَعْبُدُ وَإِيَّاكَ نَسْتَعِينُ',
        note: 'آية الإخلاص والاستعانة',
        createdAt: '2026-09-28T12:00:00Z',
      );

      final map = bookmark.toMap();
      expect(map['ayah_id'], 5);
      expect(map['note'], 'آية الإخلاص والاستعانة');

      final fromMap = Bookmark.fromMap(map);
      expect(fromMap.ayahId, 5);
      expect(fromMap.note, 'آية الإخلاص والاستعانة');
    });

    test('UIState transitions and helper getters', () {
      final initial = UIState<String>.initial();
      expect(initial.isInitial, isTrue);
      expect(initial.isLoading, isFalse);

      final loading = UIState<String>.loading();
      expect(loading.isLoading, isTrue);

      final success = UIState<String>.success('تم التحميل');
      expect(success.isSuccess, isTrue);
      expect(success.data, 'تم التحميل');

      final empty = UIState<String>.empty();
      expect(empty.isEmpty, isTrue);

      final error = UIState<String>.error('حدث خطأ ما');
      expect(error.isError, isTrue);
      expect(error.errorMessage, 'حدث خطأ ما');
    });
  });
}
