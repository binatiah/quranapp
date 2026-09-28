import 'package:equatable/equatable.dart';

/// يمثل كيان الآية القرآنية في طبقة النطاق (Domain Layer).
class Ayah extends Equatable {
  /// المعرف الفريد للآية في قاعدة البيانات
  final int id;

  /// رقم السورة التي تنتمي إليها الآية
  final int surahId;

  /// رقم الآية داخل السورة (يبدأ من 1)
  final int ayahNumber;

  /// رقم الآية التراكمي في المصحف كاملاً (1 إلى 6236)
  final int globalAyahNumber;

  /// رقم الصفحة في المصحف
  final int? pageNumber;

  /// رقم الجزء (1 إلى 30)
  final int? juzNumber;

  /// رقم الحزب (1 إلى 60)
  final int? hizbNumber;

  /// النص العثماني الأصلي للآية بالرسم القرآني والتشكيل
  final String textUthmani;

  /// النص المبسط للآية لتسهيل القراءة عند الحاجة
  final String textSimple;

  /// النص المطبع المجرّد من التشكيل لعمليات البحث
  final String textNormalized;

  /// المنشئ الثابت لتهيئة كائن الآية غير القابل للتعديل
  const Ayah({
    required this.id,
    required this.surahId,
    required this.ayahNumber,
    required this.globalAyahNumber,
    required this.textUthmani,
    required this.textSimple,
    required this.textNormalized,
    this.pageNumber,
    this.juzNumber,
    this.hizbNumber,
  });

  /// إنشاء نسخة جديدة مع تعديل بعض الخصائص
  Ayah copyWith({
    int? id,
    int? surahId,
    int? ayahNumber,
    int? globalAyahNumber,
    int? pageNumber,
    int? juzNumber,
    int? hizbNumber,
    String? textUthmani,
    String? textSimple,
    String? textNormalized,
  }) {
    return Ayah(
      id: id ?? this.id,
      surahId: surahId ?? this.surahId,
      ayahNumber: ayahNumber ?? this.ayahNumber,
      globalAyahNumber: globalAyahNumber ?? this.globalAyahNumber,
      pageNumber: pageNumber ?? this.pageNumber,
      juzNumber: juzNumber ?? this.juzNumber,
      hizbNumber: hizbNumber ?? this.hizbNumber,
      textUthmani: textUthmani ?? this.textUthmani,
      textSimple: textSimple ?? this.textSimple,
      textNormalized: textNormalized ?? this.textNormalized,
    );
  }

  /// تحويل كائن الآية إلى Map لتخزينه في قاعدة البيانات
  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'surah_id': surahId,
      'ayah_number': ayahNumber,
      'global_ayah_number': globalAyahNumber,
      'page_number': pageNumber,
      'juz_number': juzNumber,
      'hizb_number': hizbNumber,
      'text_uthmani': textUthmani,
      'text_simple': textSimple,
      'text_normalized': textNormalized,
    };
  }

  /// إنشاء كائن آية من بيانات قادمة من قاعدة بيانات SQLite
  factory Ayah.fromMap(Map<String, dynamic> map) {
    return Ayah(
      id: map['id'] as int,
      surahId: map['surah_id'] as int,
      ayahNumber: map['ayah_number'] as int,
      globalAyahNumber: map['global_ayah_number'] as int,
      pageNumber: map['page_number'] as int?,
      juzNumber: map['juz_number'] as int?,
      hizbNumber: map['hizb_number'] as int?,
      textUthmani: map['text_uthmani'] as String,
      textSimple: (map['text_simple'] ?? '') as String,
      textNormalized: (map['text_normalized'] ?? '') as String,
    );
  }

  @override
  List<Object?> get props => [
        id,
        surahId,
        ayahNumber,
        globalAyahNumber,
        pageNumber,
        juzNumber,
        hizbNumber,
        textUthmani,
        textSimple,
        textNormalized,
      ];
}
