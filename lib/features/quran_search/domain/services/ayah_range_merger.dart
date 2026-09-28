import 'package:quranapp/features/quran_search/domain/entities/ayah_range.dart';
import 'package:quranapp/features/quran_search/domain/entities/ayah_search_result.dart';

/// خدمة حساب ودمج نطاقات سياق الآيات القرآنية (AyahRangeMerger).
/// مسؤولة عن:
/// 1. حساب النطاق لكل آية بناءً على عدد الآيات السابقة (beforeCount) واللاحقة (afterCount).
/// 2. قص النطاق عند الآية 1 (بداية السورة) وعند إجمالي آيات السورة (نهاية السورة).
/// 3. فرز وترتيب النطاقات.
/// 4. دمج النطاقات المتداخلة والمتجاورة داخل السورة الواحدة دون تكرار للآيات.
/// 5. عدم دمج نطاقات سور مختلفة (فصل حدود السور افتراضياً وفق TRD).
/// 6. الحفاظ على أرقام الآيات الأصلية المستهدفة لتمييزها بصرياً.
class AyahRangeMerger {
  const AyahRangeMerger();

  /// حساب نطاق آية مفردة مع مراعاة حدود السورة
  AyahRange calculateRange({
    required int surahId,
    required int ayahNumber,
    required int surahAyahCount,
    required int beforeCount,
    required int afterCount,
  }) {
    assert(beforeCount >= 0, 'beforeCount must be non-negative');
    assert(afterCount >= 0, 'afterCount must be non-negative');
    assert(surahAyahCount >= 1, 'surahAyahCount must be at least 1');

    // قص البداية عند الآية 1
    final start = (ayahNumber - beforeCount).clamp(1, surahAyahCount);
    // قص النهاية عند آخر آية في السورة
    final end = (ayahNumber + afterCount).clamp(1, surahAyahCount);

    return AyahRange(
      surahId: surahId,
      startAyah: start,
      endAyah: end,
      targetAyahNumbers: {ayahNumber},
    );
  }

  /// تحويل قائمة نتائج البحث إلى نطاقات أولية قبل الدمج
  List<AyahRange> buildRawRanges({
    required List<AyahSearchResult> results,
    required Map<int, int> surahAyahCounts,
    required int beforeCount,
    required int afterCount,
  }) {
    final rawRanges = <AyahRange>[];

    for (final res in results) {
      final totalAyahs = surahAyahCounts[res.surahId] ?? 286;
      rawRanges.add(
        calculateRange(
          surahId: res.surahId,
          ayahNumber: res.ayahNumber,
          surahAyahCount: totalAyahs,
          beforeCount: beforeCount,
          afterCount: afterCount,
        ),
      );
    }

    return rawRanges;
  }

  /// دمج النطاقات المتداخلة أو المتجاورة داخل نفس السورة
  List<AyahRange> mergeRanges(List<AyahRange> ranges) {
    if (ranges.isEmpty) return const [];
    if (ranges.length == 1) return ranges;

    // 1. تجميع النطاقات حسب السورة
    final rangesBySurah = <int, List<AyahRange>>{};
    for (final range in ranges) {
      rangesBySurah.putIfAbsent(range.surahId, () => []).add(range);
    }

    final mergedResult = <AyahRange>[];

    // ترتيب السور تصاعدياً (1 إلى 114)
    final sortedSurahIds = rangesBySurah.keys.toList()..sort();

    for (final surahId in sortedSurahIds) {
      final surahRanges = rangesBySurah[surahId]!;

      // 2. ترتيب نطاقات السورة تصاعدياً حسب بداية النطاق startAyah
      surahRanges.sort((a, b) {
        final cmp = a.startAyah.compareTo(b.startAyah);
        if (cmp != 0) return cmp;
        return a.endAyah.compareTo(b.endAyah);
      });

      var current = surahRanges.first;

      for (var i = 1; i < surahRanges.length; i++) {
        final next = surahRanges[i];

        if (current.overlapsOrAdjacent(next)) {
          // دمج النطاقين المتداخلين أو المتجاورين
          current = current.mergeWith(next);
        } else {
          mergedResult.add(current);
          current = next;
        }
      }

      mergedResult.add(current);
    }

    return mergedResult;
  }

  /// بناء ودمج النطاقات بخطوة واحدة مباشرة من نتائج البحث
  List<AyahRange> mergeSearchResults({
    required List<AyahSearchResult> results,
    required Map<int, int> surahAyahCounts,
    required int beforeCount,
    required int afterCount,
  }) {
    final raw = buildRawRanges(
      results: results,
      surahAyahCounts: surahAyahCounts,
      beforeCount: beforeCount,
      afterCount: afterCount,
    );

    return mergeRanges(raw);
  }
}
