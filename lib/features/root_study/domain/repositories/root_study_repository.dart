import 'package:quranapp/features/quran_search/domain/entities/ayah_search_result.dart';
import '../entities/derived_word.dart';
import '../entities/root_study_data.dart';
import '../entities/surah_occurrence.dart';

/// واجهة مستودع دراسة الجذور القرآنية (RootStudyRepository Interface).
abstract interface class RootStudyRepository {
  /// جلب البيانات الإحصائية والتحليلية الكاملة للجذر
  Future<RootStudyData?> getRootStudyData(
    String root, {
    int? surahId,
    String? wordNormalizedFilter,
  });

  /// جلب قائمة الكلمات المشتقة من الجذر مع تكرار كل كلمة
  Future<List<DerivedWord>> getDerivedWords(String root);

  /// جلب توزيع ورود الجذر على السور
  Future<List<SurahOccurrence>> getSurahOccurrences(String root);

  /// جلب الآيات التي وردت فيها كلمات الجذر باستخدام استعلام JOIN الموحد المعتمد في TRD
  Future<List<AyahSearchResult>> getVersesForRoot(
    String root, {
    int? surahId,
    String? wordNormalizedFilter,
  });
}
