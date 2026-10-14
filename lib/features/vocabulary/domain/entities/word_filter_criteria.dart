import 'package:equatable/equatable.dart';

/// حالة ارتباط الكلمة القرآنية بالجذر الصرفي لأغراض الفلترة
enum WordRootStatus {
  /// جميع الكلمات القرآنية
  all,

  /// الكلمات المرتبطة بجذر موثق
  withRoot,

  /// الكلمات غير المرتبطة بأي جذر (لأغراض المراجعة والتصحيح)
  withoutRoot,

  /// تصفية الكلمات التابعة لجذر محدد
  specificRoot,
}

/// معايير تصفية وبحث مفردات وكلمات القرآن الكريم (WordFilterCriteria).
class WordFilterCriteria extends Equatable {
  /// عبارة البحث النصي (رسم عثماني، إملائي، أو مطبع)
  final String? query;

  /// رقم السورة لتحديد النطاق (1 - 114)
  final int? surahId;

  /// حالة ارتباط الكلمة بالجذور
  final WordRootStatus rootStatus;

  /// الجذر المحدد عند اختيار [WordRootStatus.specificRoot]
  final String? specificRoot;

  const WordFilterCriteria({
    this.query,
    this.surahId,
    this.rootStatus = WordRootStatus.all,
    this.specificRoot,
  });

  /// إنشاء نسخة جديدة مع تعديل بعض المعايير
  WordFilterCriteria copyWith({
    String? query,
    int? surahId,
    WordRootStatus? rootStatus,
    String? specificRoot,
    bool clearQuery = false,
    bool clearSurahId = false,
    bool clearSpecificRoot = false,
  }) {
    return WordFilterCriteria(
      query: clearQuery ? null : (query ?? this.query),
      surahId: clearSurahId ? null : (surahId ?? this.surahId),
      rootStatus: rootStatus ?? this.rootStatus,
      specificRoot: clearSpecificRoot ? null : (specificRoot ?? this.specificRoot),
    );
  }

  @override
  List<Object?> get props => [query, surahId, rootStatus, specificRoot];
}
