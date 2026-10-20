import 'package:equatable/equatable.dart';

/// يمثل رابط جذر لغوي بمشروع دراسة (خاصة في مشاريع المفاهيم لجمع شبكة الجذور المعبرة)
class StudyProjectRootLink extends Equatable {
  /// المعرف الفريد للرابط
  final int id;

  /// معرف المشروع
  final int projectId;

  /// الجذر الصرفي المطبع
  final String rootNormalized;

  /// ملاحظة الباحث حول دلالة هذا الجذر في خدمة المفهوم
  final String? note;

  /// عدد مرات ورود مشتقات الجذر في القرآن الكريم
  final int occurrenceCount;

  /// المنشئ الثابت
  const StudyProjectRootLink({
    required this.id,
    required this.projectId,
    required this.rootNormalized,
    this.note,
    this.occurrenceCount = 0,
  });

  /// إنشاء كائن من خريطة بيانات SQLite
  factory StudyProjectRootLink.fromMap(Map<String, dynamic> map) {
    return StudyProjectRootLink(
      id: map['id'] as int,
      projectId: map['project_id'] as int,
      rootNormalized: map['root_normalized'] as String,
      note: map['note'] as String?,
      occurrenceCount: (map['occurrence_count'] as int?) ?? 0,
    );
  }

  @override
  List<Object?> get props => [
        id,
        projectId,
        rootNormalized,
        note,
        occurrenceCount,
      ];
}
