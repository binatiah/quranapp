import 'package:equatable/equatable.dart';

/// يمثل كيان الجذر اللغوي القرآني (Quranic Root Entity).
class QuranRoot extends Equatable {
  /// المعرف الفريد للجذر في قاعدة البيانات
  final int id;

  /// الجذر بالحروف الأصلية (مثل: عَلِمَ أو علم)
  final String root;

  /// الجذر المطبّع منزوع التشكيل لأغراض الفهرسة والبحث
  final String rootNormalized;

  /// الوصف أو المعنى اللغوي للجذر بالعربية
  final String? descriptionAr;

  /// عدد الكلمات المشتقة المختلفة من هذا الجذر (إحصاء مفيد لشاشة دراسة الجذر)
  final int wordsCount;

  /// إجمالي عدد مرات ورود هذا الجذر في القرآن الكريم
  final int occurrencesCount;

  /// المنشئ الثابت لتهيئة كائن الجذر القرآني
  const QuranRoot({
    required this.id,
    required this.root,
    required this.rootNormalized,
    this.descriptionAr,
    this.wordsCount = 0,
    this.occurrencesCount = 0,
  });

  /// إنشاء نسخة جديدة مع تعديل بعض الخصائص
  QuranRoot copyWith({
    int? id,
    String? root,
    String? rootNormalized,
    String? descriptionAr,
    int? wordsCount,
    int? occurrencesCount,
  }) {
    return QuranRoot(
      id: id ?? this.id,
      root: root ?? this.root,
      rootNormalized: rootNormalized ?? this.rootNormalized,
      descriptionAr: descriptionAr ?? this.descriptionAr,
      wordsCount: wordsCount ?? this.wordsCount,
      occurrencesCount: occurrencesCount ?? this.occurrencesCount,
    );
  }

  /// تحويل كائن الجذر إلى Map لقاعدة البيانات
  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'root': root,
      'root_normalized': rootNormalized,
      'description_ar': descriptionAr,
    };
  }

  /// إنشاء كائن الجذر القرآني من Map
  factory QuranRoot.fromMap(Map<String, dynamic> map) {
    return QuranRoot(
      id: map['id'] as int,
      root: map['root'] as String,
      rootNormalized: map['root_normalized'] as String,
      descriptionAr: map['description_ar'] as String?,
      wordsCount: (map['words_count'] ?? 0) as int,
      occurrencesCount: (map['occurrences_count'] ?? 0) as int,
    );
  }

  @override
  List<Object?> get props => [
        id,
        root,
        rootNormalized,
        descriptionAr,
        wordsCount,
        occurrencesCount,
      ];
}
