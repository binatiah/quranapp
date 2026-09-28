import '../entities/ayah_search_result.dart';
import '../entities/quran_root.dart';
import '../entities/quran_word.dart';
import '../entities/root_candidate.dart';

/// واجهة مستودع البحث والدراسة القرآنية (QuranSearchRepository Interface).
abstract interface class QuranSearchRepository {
  /// البحث المباشر المطابق للكلمة بالتشكيل أو الرسم العثماني
  Future<List<AyahSearchResult>> searchExactWord(String word, {int? surahId});

  /// البحث النصي المرن في آيات القرآن دون تشكيل مع إمكانية التصفية حسب السورة
  Future<List<AyahSearchResult>> searchText(String query, {int? surahId});

  /// تحديد الجذور المحتملة لكلمة مدخلة مع درجات الثقة
  Future<List<RootCandidate>> resolveRoots(String query);

  /// جلب جميع الكلمات القرآنية المرتبطة بجذر محدد وتكراراتها
  Future<List<QuranWord>> getWordsByRoot(String root);

  /// جلب الآيات المرتبطة بجذر محدد باستخدام استعلام JOIN الموحد المعتمد في TRD
  Future<List<AyahSearchResult>> searchAyahsByRoot(String root, {int? surahId});

  /// جلب تفاصيل الجذر الصرفي وإحصاءاته
  Future<QuranRoot?> getRootDetails(String root);
}
