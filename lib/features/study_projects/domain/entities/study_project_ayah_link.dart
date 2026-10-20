import 'package:equatable/equatable.dart';

/// يمثل رابط آية قرآنية مع مشروع الدراسة (للتقاطعات والآيات المفسرة أو الشواهد)
class StudyProjectAyahLink extends Equatable {
  /// المعرف الفريد للرابط
  final int id;

  /// معرف المشروع التابع له
  final int projectId;

  /// معرف الآية في جدول ayahs
  final int ayahId;

  /// رقم السورة
  final int surahId;

  /// اسم السورة بالعربية
  final String surahName;

  /// رقم الآية في السورة
  final int ayahNumber;

  /// النص العثماني للآية
  final String textUthmani;

  /// ملاحظة أو توجيه الباحث حول وجه الارتباط
  final String? note;

  /// نوع الارتباط (related: صلة عامة، crossReference: تقاطع، explaining: مفسرة، ruling: حكم)
  final String relationType;

  /// المنشئ الثابت
  const StudyProjectAyahLink({
    required this.id,
    required this.projectId,
    required this.ayahId,
    required this.surahId,
    required this.surahName,
    required this.ayahNumber,
    required this.textUthmani,
    this.note,
    this.relationType = 'related',
  });

  /// إنشاء كائن من استعلام SQL
  factory StudyProjectAyahLink.fromMap(Map<String, dynamic> map) {
    return StudyProjectAyahLink(
      id: map['id'] as int,
      projectId: map['project_id'] as int,
      ayahId: map['ayah_id'] as int,
      surahId: (map['surah_id'] as int?) ?? 1,
      surahName: (map['surah_name'] as String?) ?? '',
      ayahNumber: (map['ayah_number'] as int?) ?? 1,
      textUthmani: (map['text_uthmani'] as String?) ?? '',
      note: map['note'] as String?,
      relationType: (map['relation_type'] as String?) ?? 'related',
    );
  }

  /// الاسم العربي لنوع الارتباط
  String get relationTypeArabic {
    switch (relationType) {
      case 'explaining':
        return 'آية مفسرة';
      case 'crossReference':
        return 'تقاطع موضوعي';
      case 'ruling':
        return 'شاهد حكم';
      default:
        return 'آية ذات صلة';
    }
  }

  @override
  List<Object?> get props => [
        id,
        projectId,
        ayahId,
        surahId,
        surahName,
        ayahNumber,
        textUthmani,
        note,
        relationType,
      ];
}
