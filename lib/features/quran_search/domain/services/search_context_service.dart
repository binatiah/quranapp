import 'package:quranapp/features/quran_search/domain/entities/ayah_context_group.dart';
import 'package:quranapp/features/quran_search/domain/entities/ayah_search_result.dart';

/// واجهة خدمة جلب سياق الآيات القرآنية ومجموعاتها المتصلة (SearchContextService Interface).
abstract interface class SearchContextService {
  /// جلب سياق الآيات لمجموعة نتائج بحث مع دمج النطاقات المتداخلة والمتجاورة
  Future<List<AyahContextGroup>> loadContext({
    required List<AyahSearchResult> results,
    required int beforeCount,
    required int afterCount,
  });

  /// جلب سياق آية مفردة داخل سورتها مع قص الحدود
  Future<AyahContextGroup?> loadSingleAyahContext({
    required int surahId,
    required int ayahNumber,
    required int beforeCount,
    required int afterCount,
  });
}
