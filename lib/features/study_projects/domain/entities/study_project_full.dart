import 'package:equatable/equatable.dart';
import 'study_project.dart';
import 'root_study_details.dart';
import 'ayah_study_details.dart';
import 'concept_study_details.dart';
import 'study_project_ayah_link.dart';
import 'study_project_root_link.dart';

/// يجمع كامل بيانات المشروع وتفاصيله المتخصصة وروابطه في كائن مدمج متكامل
class StudyProjectFull extends Equatable {
  /// بيانات المشروع الأساسية
  final StudyProject project;

  /// تفاصيل دراسة الجذر (إذا كان نوع المشروع root)
  final RootStudyDetails? rootDetails;

  /// تفاصيل دراسة الآية (إذا كان نوع المشروع ayah)
  final AyahStudyDetails? ayahDetails;

  /// تفاصيل دراسة المفهوم (إذا كان نوع المشروع concept)
  final ConceptStudyDetails? conceptDetails;

  /// قائمة الآيات المرتبطة بالمشروع
  final List<StudyProjectAyahLink> linkedAyahs;

  /// قائمة الجذور المرتبطة بالمشروع
  final List<StudyProjectRootLink> linkedRoots;

  /// نص الآية العثماني المستهدفة (إذا كان المشروع دراسة آية)
  final String? targetVerseText;

  /// اسم السورة المستهدفة
  final String? targetSurahName;

  /// إجمالي تكرار الجذر المستهدف في المصحف
  final int? targetRootTotalOccurrences;

  /// عدد الكلمات المشتقة من الجذر المستهدف
  final int? targetRootDerivedWordsCount;

  /// المنشئ الثابت
  const StudyProjectFull({
    required this.project,
    this.rootDetails,
    this.ayahDetails,
    this.conceptDetails,
    this.linkedAyahs = const [],
    this.linkedRoots = const [],
    this.targetVerseText,
    this.targetSurahName,
    this.targetRootTotalOccurrences,
    this.targetRootDerivedWordsCount,
  });

  /// إنشاء نسخة معدلة
  StudyProjectFull copyWith({
    StudyProject? project,
    RootStudyDetails? rootDetails,
    AyahStudyDetails? ayahDetails,
    ConceptStudyDetails? conceptDetails,
    List<StudyProjectAyahLink>? linkedAyahs,
    List<StudyProjectRootLink>? linkedRoots,
    String? targetVerseText,
    String? targetSurahName,
    int? targetRootTotalOccurrences,
    int? targetRootDerivedWordsCount,
  }) {
    return StudyProjectFull(
      project: project ?? this.project,
      rootDetails: rootDetails ?? this.rootDetails,
      ayahDetails: ayahDetails ?? this.ayahDetails,
      conceptDetails: conceptDetails ?? this.conceptDetails,
      linkedAyahs: linkedAyahs ?? this.linkedAyahs,
      linkedRoots: linkedRoots ?? this.linkedRoots,
      targetVerseText: targetVerseText ?? this.targetVerseText,
      targetSurahName: targetSurahName ?? this.targetSurahName,
      targetRootTotalOccurrences:
          targetRootTotalOccurrences ?? this.targetRootTotalOccurrences,
      targetRootDerivedWordsCount:
          targetRootDerivedWordsCount ?? this.targetRootDerivedWordsCount,
    );
  }

  @override
  List<Object?> get props => [
        project,
        rootDetails,
        ayahDetails,
        conceptDetails,
        linkedAyahs,
        linkedRoots,
        targetVerseText,
        targetSurahName,
        targetRootTotalOccurrences,
        targetRootDerivedWordsCount,
      ];
}
