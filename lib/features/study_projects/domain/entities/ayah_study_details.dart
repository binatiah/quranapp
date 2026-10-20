import 'package:equatable/equatable.dart';

/// يحتوي على تفاصيل وأسئلة مشروع دراسة الآيات القرآنية وفق متطلبات TRD
class AyahStudyDetails extends Equatable {
  /// المعرف المرجعي لمشروع الدراسة
  final int projectId;

  /// رقم السورة في المصحف الشريف (1 - 114)
  final int surahId;

  /// رقم الآية داخل السورة
  final int ayahNumber;

  /// الرقم التراكمي للآية في المصحف (1 - 6236)
  final int? globalAyahNumber;

  /// موضوع الآية ومحورها الأساسي (عن ماذا تتحدث؟)
  final String? topic;

  /// تفسير الآية من الموروث والتفاسير المعتمدة
  final String? traditionalTafseer;

  /// زمن وسبب النزول ومناسباته (مكي/مدني، أسباب النزول)
  final String? revelationContext;

  /// علاقتها بآيات أخرى وتقاطعاتها وهل هناك آيات تفسرها أو تخصصها
  final String? crossReferences;

  /// التشابهات والتقاطعات في الكتب والشرائع المقدسة السابقة
  final String? otherScripturesParallels;

  /// المفهوم الظاهر والمباشر من نص الآية
  final String? apparentConcept;

  /// هل الآية دليل على حكم شرعي فقهي أم دلالة عقدية أو أخلاقية أو غيره؟
  final String? rulingOrStatus;

  /// رأي الباحث وملاحظاته التدبرية واستنباطاته
  final String? researcherNotes;

  /// المنشئ الثابت لتفاصيل دراسة الآية
  const AyahStudyDetails({
    required this.projectId,
    required this.surahId,
    required this.ayahNumber,
    this.globalAyahNumber,
    this.topic,
    this.traditionalTafseer,
    this.revelationContext,
    this.crossReferences,
    this.otherScripturesParallels,
    this.apparentConcept,
    this.rulingOrStatus,
    this.researcherNotes,
  });

  /// إنشاء نسخة معدلة
  AyahStudyDetails copyWith({
    int? projectId,
    int? surahId,
    int? ayahNumber,
    int? globalAyahNumber,
    String? topic,
    String? traditionalTafseer,
    String? revelationContext,
    String? crossReferences,
    String? otherScripturesParallels,
    String? apparentConcept,
    String? rulingOrStatus,
    String? researcherNotes,
  }) {
    return AyahStudyDetails(
      projectId: projectId ?? this.projectId,
      surahId: surahId ?? this.surahId,
      ayahNumber: ayahNumber ?? this.ayahNumber,
      globalAyahNumber: globalAyahNumber ?? this.globalAyahNumber,
      topic: topic ?? this.topic,
      traditionalTafseer: traditionalTafseer ?? this.traditionalTafseer,
      revelationContext: revelationContext ?? this.revelationContext,
      crossReferences: crossReferences ?? this.crossReferences,
      otherScripturesParallels: otherScripturesParallels ?? this.otherScripturesParallels,
      apparentConcept: apparentConcept ?? this.apparentConcept,
      rulingOrStatus: rulingOrStatus ?? this.rulingOrStatus,
      researcherNotes: researcherNotes ?? this.researcherNotes,
    );
  }

  /// تحويل الكائن إلى خريطة بيانات SQLite
  Map<String, dynamic> toMap() {
    return {
      'project_id': projectId,
      'surah_id': surahId,
      'ayah_number': ayahNumber,
      'global_ayah_number': globalAyahNumber,
      'topic': topic,
      'traditional_tafseer': traditionalTafseer,
      'revelation_context': revelationContext,
      'cross_references': crossReferences,
      'other_scriptures_parallels': otherScripturesParallels,
      'apparent_concept': apparentConcept,
      'ruling_or_status': rulingOrStatus,
      'researcher_notes': researcherNotes,
    };
  }

  /// إنشاء كائن تفاصيل الآية من صف في قاعدة البيانات
  factory AyahStudyDetails.fromMap(Map<String, dynamic> map) {
    return AyahStudyDetails(
      projectId: map['project_id'] as int,
      surahId: map['surah_id'] as int,
      ayahNumber: map['ayah_number'] as int,
      globalAyahNumber: map['global_ayah_number'] as int?,
      topic: map['topic'] as String?,
      traditionalTafseer: map['traditional_tafseer'] as String?,
      revelationContext: map['revelation_context'] as String?,
      crossReferences: map['cross_references'] as String?,
      otherScripturesParallels: map['other_scriptures_parallels'] as String?,
      apparentConcept: map['apparent_concept'] as String?,
      rulingOrStatus: map['ruling_or_status'] as String?,
      researcherNotes: map['researcher_notes'] as String?,
    );
  }

  @override
  List<Object?> get props => [
        projectId,
        surahId,
        ayahNumber,
        globalAyahNumber,
        topic,
        traditionalTafseer,
        revelationContext,
        crossReferences,
        otherScripturesParallels,
        apparentConcept,
        rulingOrStatus,
        researcherNotes,
      ];
}
