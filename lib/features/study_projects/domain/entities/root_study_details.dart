import 'package:equatable/equatable.dart';

/// يحتوي على كافة تفاصيل وأسئلة مشروع دراسة الجذر اللغوي القرآني
class RootStudyDetails extends Equatable {
  /// المعرف المرجعي للمشروع الأساسي
  final int projectId;

  /// نوع الجذر الصرفي (ثنائي، ثلاثي، رباعي، خماسي)
  final String? rootType;

  /// هل يحتوي الجذر على أحرف علة؟
  final bool hasVowels;

  /// عدد أحرف العلة في الجذر
  final int vowelsCount;

  /// قائمة أحرف العلة الموجودة مفصولة بفواصل (مثل: و، ي)
  final String? vowelsList;

  /// التطابقات في اللغات الأخرى (سريانية، آرامية، عبرية، إنجليزية، إلخ)
  final String? cognatesOtherLanguages;

  /// أقدم استخدام مرصود للجذر وهل استخدم في لسان العرب قبل القرآن أم نتاج وإثراء قرآني
  final String? oldestUsage;

  /// هل لا يزال الجذر مستخدماً ومتداولاً في اللغة المعاصرة اليوم؟
  final bool isUsedToday;

  /// طبيعة الدلالة (مادية، معنوية، مجردة، مركبة)
  final String? usageNature;

  /// المعنى المرادف للجذر
  final String? synonyms;

  /// المعنى المضاد والمغاير للجذر
  final String? antonyms;

  /// رأي الباحث وملاحظاته التحليلية وخلاصاته
  final String? researcherNotes;

  /// المنشئ الثابت لتفاصيل دراسة الجذر
  const RootStudyDetails({
    required this.projectId,
    this.rootType,
    this.hasVowels = false,
    this.vowelsCount = 0,
    this.vowelsList,
    this.cognatesOtherLanguages,
    this.oldestUsage,
    this.isUsedToday = true,
    this.usageNature,
    this.synonyms,
    this.antonyms,
    this.researcherNotes,
  });

  /// إنشاء نسخة معدلة
  RootStudyDetails copyWith({
    int? projectId,
    String? rootType,
    bool? hasVowels,
    int? vowelsCount,
    String? vowelsList,
    String? cognatesOtherLanguages,
    String? oldestUsage,
    bool? isUsedToday,
    String? usageNature,
    String? synonyms,
    String? antonyms,
    String? researcherNotes,
  }) {
    return RootStudyDetails(
      projectId: projectId ?? this.projectId,
      rootType: rootType ?? this.rootType,
      hasVowels: hasVowels ?? this.hasVowels,
      vowelsCount: vowelsCount ?? this.vowelsCount,
      vowelsList: vowelsList ?? this.vowelsList,
      cognatesOtherLanguages: cognatesOtherLanguages ?? this.cognatesOtherLanguages,
      oldestUsage: oldestUsage ?? this.oldestUsage,
      isUsedToday: isUsedToday ?? this.isUsedToday,
      usageNature: usageNature ?? this.usageNature,
      synonyms: synonyms ?? this.synonyms,
      antonyms: antonyms ?? this.antonyms,
      researcherNotes: researcherNotes ?? this.researcherNotes,
    );
  }

  /// تحويل الكائن إلى خريطة بيانات لـ SQLite
  Map<String, dynamic> toMap() {
    return {
      'project_id': projectId,
      'root_type': rootType,
      'has_vowels': hasVowels ? 1 : 0,
      'vowels_count': vowelsCount,
      'vowels_list': vowelsList,
      'cognates_other_languages': cognatesOtherLanguages,
      'oldest_usage': oldestUsage,
      'is_used_today': isUsedToday ? 1 : 0,
      'usage_nature': usageNature,
      'synonyms': synonyms,
      'antonyms': antonyms,
      'researcher_notes': researcherNotes,
    };
  }

  /// إنشاء كائن تفاصيل الجذر من صف في قاعدة البيانات
  factory RootStudyDetails.fromMap(Map<String, dynamic> map) {
    return RootStudyDetails(
      projectId: map['project_id'] as int,
      rootType: map['root_type'] as String?,
      hasVowels: (map['has_vowels'] as int?) == 1,
      vowelsCount: (map['vowels_count'] as int?) ?? 0,
      vowelsList: map['vowels_list'] as String?,
      cognatesOtherLanguages: map['cognates_other_languages'] as String?,
      oldestUsage: map['oldest_usage'] as String?,
      isUsedToday: (map['is_used_today'] as int?) != 0,
      usageNature: map['usage_nature'] as String?,
      synonyms: map['synonyms'] as String?,
      antonyms: map['antonyms'] as String?,
      researcherNotes: map['researcher_notes'] as String?,
    );
  }

  @override
  List<Object?> get props => [
        projectId,
        rootType,
        hasVowels,
        vowelsCount,
        vowelsList,
        cognatesOtherLanguages,
        oldestUsage,
        isUsedToday,
        usageNature,
        synonyms,
        antonyms,
        researcherNotes,
      ];
}
