import '../entities/ayah.dart';
import '../entities/reading_position.dart';
import '../entities/surah.dart';

/// واجهة مستودع بيانات القرآن الكريم (QuranRepository Interface).
/// تفصل طبقة النطاق (Domain) عن تفاصيل تطبيق طبقة البيانات (SQLite).
abstract interface class QuranRepository {
  /// جلب جميع سور القرآن الكريم الـ 114 مرتبة تسلسليًا
  Future<List<Surah>> getSurahs();

  /// جلب تفاصيل سورة محددة برقمها
  Future<Surah?> getSurahById(int surahId);

  /// جلب جميع آيات سورة محددة بالنص العثماني مرتبة تسلسليًا
  Future<List<Ayah>> getSurahAyahs(int surahId);

  /// جلب آية مفردة بدلالة رقم السورة ورقم الآية داخلها
  Future<Ayah?> getAyah(int surahId, int ayahNumber);

  /// جلب نطاق محدد من الآيات داخل سورة معينة (من الآية startAyah إلى endAyah)
  Future<List<Ayah>> getAyahRange({
    required int surahId,
    required int startAyah,
    required int endAyah,
  });

  /// جلب آخر موضع قراءة محفوظ للمستخدم
  Future<ReadingPosition?> getLastReadingPosition();

  /// حفظ أو تحديث آخر موضع قراءة للمستخدم
  Future<void> saveReadingPosition({
    required int surahId,
    required int ayahNumber,
  });
}
