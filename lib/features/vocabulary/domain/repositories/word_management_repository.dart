import 'package:quranapp/features/quran_search/domain/entities/quran_word.dart';
import '../entities/word_filter_criteria.dart';

/// واجهة مستودع إدارة واستعراض وتصحيح كلمات ومفردات القرآن الكريم (WordManagementRepository Interface).
abstract interface class WordManagementRepository {
  /// استرجاع قائمة الكلمات القرآنية مع دعم الفلاتر والبحث والترقيم السريع
  Future<List<QuranWord>> getWords({
    required WordFilterCriteria criteria,
    int limit = 50,
    int offset = 0,
  });

  /// حساب إجمالي عدد الكلمات المطابقة لمعايير البحث والتصفية
  Future<int> getWordsCount({
    required WordFilterCriteria criteria,
  });

  /// جلب تفاصيل كلمة مفردة بالمعرف
  Future<QuranWord?> getWordById(int id);

  /// حساب عدد مرات ورود الكلمة المطبّعة في القرآن الكريم
  Future<int> getWordOccurrencesCount(String wordNormalized);

  /// إعادة ربط الكلمة بالجذر الصحيح (مع إمكانية التطبيق على هذا الموضع فقط أو جميع مواضع الكلمة في المصحف)
  Future<int> relinkWordToRoot({
    required int wordId,
    required String newRoot,
    bool applyToAllOccurrences = false,
  });

  /// فك ارتباط الكلمة بالجذر الحالي
  Future<int> unlinkWordFromRoot({
    required int wordId,
    bool applyToAllOccurrences = false,
  });

  /// تعديل وتدقيق البيانات الصرفية والتفصيلية للكلمة القرآنية
  Future<void> updateWordDetails({
    required int wordId,
    required String wordUthmani,
    String? lemma,
    String? prefix,
    String? stem,
    String? suffix,
    String? partOfSpeech,
    String? morphology,
  });
}
