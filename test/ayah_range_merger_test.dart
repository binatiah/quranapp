import 'package:flutter_test/flutter_test.dart';
import 'package:quranapp/features/quran_search/domain/entities/ayah_range.dart';
import 'package:quranapp/features/quran_search/domain/entities/ayah_search_result.dart';
import 'package:quranapp/features/quran_search/domain/entities/search_match_type.dart';
import 'package:quranapp/features/quran_search/domain/services/ayah_range_merger.dart';

void main() {
  group('AyahRangeMerger Unit Tests', () {
    const merger = AyahRangeMerger();

    test('calculateRange clips properly at start of surah (ayah 1)', () {
      // آية 2 مع 5 آيات سابقة في سورة الفاتحة (7 آيات)
      final range = merger.calculateRange(
        surahId: 1,
        ayahNumber: 2,
        surahAyahCount: 7,
        beforeCount: 5,
        afterCount: 3,
      );

      expect(range.surahId, equals(1));
      expect(range.startAyah, equals(1)); // تم القص عند الآية 1
      expect(range.endAyah, equals(5)); // 2 + 3 = 5
      expect(range.targetAyahNumbers, contains(2));
    });

    test('calculateRange clips properly at end of surah', () {
      // آية 6 مع 10 آيات لاحقة في سورة الفاتحة (7 آيات)
      final range = merger.calculateRange(
        surahId: 1,
        ayahNumber: 6,
        surahAyahCount: 7,
        beforeCount: 2,
        afterCount: 10,
      );

      expect(range.surahId, equals(1));
      expect(range.startAyah, equals(4)); // 6 - 2 = 4
      expect(range.endAyah, equals(7)); // تم القص عند آخر آية (7)
      expect(range.targetAyahNumbers, contains(6));
    });

    test('mergeRanges merges overlapping ranges into a single unified range', () {
      // مثال TRD المعتمد: نطاقات 15-24 و 17-26 و 18-27 في سورة واحدة تدمج في 15-27
      final ranges = [
        const AyahRange(surahId: 2, startAyah: 15, endAyah: 24, targetAyahNumbers: {20}),
        const AyahRange(surahId: 2, startAyah: 17, endAyah: 26, targetAyahNumbers: {22}),
        const AyahRange(surahId: 2, startAyah: 18, endAyah: 27, targetAyahNumbers: {23}),
      ];

      final merged = merger.mergeRanges(ranges);

      expect(merged.length, equals(1));
      expect(merged.first.surahId, equals(2));
      expect(merged.first.startAyah, equals(15));
      expect(merged.first.endAyah, equals(27));
      expect(merged.first.targetAyahNumbers, equals({20, 22, 23}));
    });

    test('mergeRanges merges adjacent ranges into a single continuous range', () {
      // نطاقين متجاورين: 1-5 و 6-10
      final ranges = [
        const AyahRange(surahId: 1, startAyah: 1, endAyah: 5, targetAyahNumbers: {3}),
        const AyahRange(surahId: 1, startAyah: 6, endAyah: 7, targetAyahNumbers: {6}),
      ];

      final merged = merger.mergeRanges(ranges);

      expect(merged.length, equals(1));
      expect(merged.first.startAyah, equals(1));
      expect(merged.first.endAyah, equals(7));
      expect(merged.first.targetAyahNumbers, equals({3, 6}));
    });

    test('mergeRanges preserves separate disjoint ranges when not overlapping or adjacent', () {
      // نطاقات منفصلة متباعدة
      final ranges = [
        const AyahRange(surahId: 2, startAyah: 5, endAyah: 10, targetAyahNumbers: {7}),
        const AyahRange(surahId: 2, startAyah: 40, endAyah: 45, targetAyahNumbers: {42}),
      ];

      final merged = merger.mergeRanges(ranges);

      expect(merged.length, equals(2));
      expect(merged[0].startAyah, equals(5));
      expect(merged[0].endAyah, equals(10));
      expect(merged[1].startAyah, equals(40));
      expect(merged[1].endAyah, equals(45));
    });

    test('mergeRanges never merges ranges across different surahs', () {
      // نطاق في سورة 1 ونطاق في سورة 2
      final ranges = [
        const AyahRange(surahId: 1, startAyah: 5, endAyah: 7, targetAyahNumbers: {6}),
        const AyahRange(surahId: 2, startAyah: 1, endAyah: 5, targetAyahNumbers: {3}),
      ];

      final merged = merger.mergeRanges(ranges);

      expect(merged.length, equals(2));
      expect(merged[0].surahId, equals(1));
      expect(merged[1].surahId, equals(2));
    });

    test('mergeSearchResults calculates and merges directly from AyahSearchResults', () {
      final results = [
        const AyahSearchResult(
          ayahId: 20,
          surahId: 2,
          surahName: 'البقرة',
          ayahNumber: 20,
          globalAyahNumber: 27,
          textUthmani: 'نص الآية 20',
          matchedWords: ['يكاد'],
          matchType: SearchMatchType.exact,
        ),
        const AyahSearchResult(
          ayahId: 22,
          surahId: 2,
          surahName: 'البقرة',
          ayahNumber: 22,
          globalAyahNumber: 29,
          textUthmani: 'نص الآية 22',
          matchedWords: ['الذي'],
          matchType: SearchMatchType.exact,
        ),
      ];

      final merged = merger.mergeSearchResults(
        results: results,
        surahAyahCounts: {2: 286},
        beforeCount: 3,
        afterCount: 3,
      );

      // 20 - 3 = 17 إلى 23
      // 22 - 3 = 19 إلى 25
      // تدمج في نطاق واحد: 17 إلى 25
      expect(merged.length, equals(1));
      expect(merged.first.startAyah, equals(17));
      expect(merged.first.endAyah, equals(25));
      expect(merged.first.targetAyahNumbers, equals({20, 22}));
    });
  });
}
