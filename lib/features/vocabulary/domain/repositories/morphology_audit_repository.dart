import '../entities/morphology_audit_item.dart';
import '../entities/morphology_audit_stats.dart';

/// واجهة مستودع التدقيق الصرفي والمعجمي الجماعي
abstract interface class MorphologyAuditRepository {
  /// جلب الإحصاءات العامة لنسب اكتمال الربط الصرفي والمعجمي
  Future<MorphologyAuditStats> getAuditStats();

  /// جلب الكلمات التي تحتاج تدقيقاً (بدون جذر أو بدون تصنيف صرفي) مع دعم الفرز والبحث والترقيم
  Future<List<MorphologyAuditItem>> getAuditItems({
    bool withoutRootOnly = true,
    String? query,
    int? surahId,
    int limit = 40,
    int offset = 0,
  });

  /// حساب إجمالي الكلمات التي تطابق شرط التدقيق
  Future<int> getAuditItemsCount({
    bool withoutRootOnly = true,
    String? query,
    int? surahId,
  });

  /// تنفيذ ربط جماعي لمجموعة من الكلمات بجذر لغوي محدد
  Future<int> batchRelinkWords({
    required List<int> wordIds,
    required String newRoot,
    bool applyToAllOccurrences = false,
  });
}
