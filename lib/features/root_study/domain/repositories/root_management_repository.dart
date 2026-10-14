import 'package:quranapp/features/quran_search/domain/entities/quran_root.dart';

/// خيارات ترتيب وفرز قائمة الجذور اللغوية
enum RootSortBy {
  /// الأكثر وروداً وتكراراً في القرآن الكريم (تنازلي)
  occurrencesDesc,

  /// الأقل وروداً وتكراراً (تصاعدي)
  occurrencesAsc,

  /// الترتيب الأبجدي الهجائي العربي (أ - ي)
  alphabetical,

  /// الأكثر اشتقاقاً لكلمات قرآنية مختلفة
  wordsCountDesc,

  /// الجذور التي لا تمتلك وصفاً لغوياً (لتسهيل التدقيق والإثراء)
  withoutDescription,
}

/// واجهة مستودع إدارة واستعراض الجذور القرآنية (RootManagementRepository Interface).
/// توفر عمليات استرجاع، بحث، فرز، إضافة، تعديل، وحذف الجذور بأمان في قاعدة البيانات المحلية.
abstract interface class RootManagementRepository {
  /// استرجاع قائمة الجذور القرآنية مع دعم البحث والفرز والترقيم (Pagination)
  Future<List<QuranRoot>> getRoots({
    String? query,
    RootSortBy sortBy = RootSortBy.occurrencesDesc,
    int limit = 50,
    int offset = 0,
  });

  /// حساب العدد الإجمالي للجذور المطابقة لمعايير البحث
  Future<int> getRootsCount({
    String? query,
    RootSortBy sortBy = RootSortBy.occurrencesDesc,
  });

  /// جلب تفاصيل جذر محدد بمعرفه
  Future<QuranRoot?> getRootById(int id);

  /// إضافة جذر لغوي جديد إلى قاعدة البيانات
  Future<QuranRoot> addRoot({
    required String root,
    String? descriptionAr,
  });

  /// تعديل بيانات جذر موجود مسبقاً
  Future<void> updateRoot({
    required int id,
    required String root,
    String? descriptionAr,
  });

  /// فحص عدد الكلمات القرآنية المرتبطة بالجذر قبل اتخاذ قرار الحذف
  Future<int> getRootWordCount(int id);

  /// حذف جذر من قاعدة البيانات (مع تنظيف جدول الروابط)
  Future<bool> deleteRoot(int id);
}
