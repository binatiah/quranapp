import 'package:equatable/equatable.dart';

/// يمثل كيان السورة القرآنية في طبقة النطاق (Domain Layer).
class Surah extends Equatable {
  /// الرقم التسلسلي للسورة من 1 إلى 114
  final int id;

  /// اسم السورة باللغة العربية
  final String nameArabic;

  /// اسم السورة بالحروف الإنجليزية أو الترجمة الصوتية
  final String nameEnglish;

  /// نوع التنزيل (مكية / مدنية)
  final String revelationType;

  /// عدد آيات السورة
  final int ayahCount;

  /// ترتيب نزول السورة
  final int? revelationOrder;

  /// رقم الصفحة الأولى التي تبدأ عندها السورة في المصحف
  final int? startPage;

  /// المنشئ الثابت لتهيئة كائن السورة بقيم غير قابلة للتعديل
  const Surah({
    required this.id,
    required this.nameArabic,
    required this.nameEnglish,
    required this.revelationType,
    required this.ayahCount,
    this.revelationOrder,
    this.startPage,
  });

  /// إنشاء نسخة جديدة مع تعديل بعض الخصائص
  Surah copyWith({
    int? id,
    String? nameArabic,
    String? nameEnglish,
    String? revelationType,
    int? ayahCount,
    int? revelationOrder,
    int? startPage,
  }) {
    return Surah(
      id: id ?? this.id,
      nameArabic: nameArabic ?? this.nameArabic,
      nameEnglish: nameEnglish ?? this.nameEnglish,
      revelationType: revelationType ?? this.revelationType,
      ayahCount: ayahCount ?? this.ayahCount,
      revelationOrder: revelationOrder ?? this.revelationOrder,
      startPage: startPage ?? this.startPage,
    );
  }

  /// تحويل كائن السورة إلى Map لتخزينه في قاعدة البيانات
  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'name_arabic': nameArabic,
      'name_english': nameEnglish,
      'revelation_type': revelationType,
      'ayah_count': ayahCount,
      'revelation_order': revelationOrder,
      'start_page': startPage,
    };
  }

  /// إنشاء كائن سورة من بيانات قادمة من قاعدة بيانات SQLite
  factory Surah.fromMap(Map<String, dynamic> map) {
    return Surah(
      id: map['id'] as int,
      nameArabic: map['name_arabic'] as String,
      nameEnglish: (map['name_english'] ?? '') as String,
      revelationType: (map['revelation_type'] ?? '') as String,
      ayahCount: map['ayah_count'] as int,
      revelationOrder: map['revelation_order'] as int?,
      startPage: map['start_page'] as int?,
    );
  }

  @override
  List<Object?> get props => [
        id,
        nameArabic,
        nameEnglish,
        revelationType,
        ayahCount,
        revelationOrder,
        startPage,
      ];
}
