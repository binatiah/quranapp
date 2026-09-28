import 'package:equatable/equatable.dart';

/// يمثل كيان آخر موضع قراءة للمستخدم في المصحف.
class ReadingPosition extends Equatable {
  /// المعرف الثابت (1 دائمًا لموضع القراءة الحالي)
  final int id;

  /// رقم السورة التي توقف عندها القارئ
  final int surahId;

  /// رقم الآية التي توقف عندها القارئ
  final int ayahNumber;

  /// وقت آخر تحديث لموضع القراءة بصيغة ISO 8601
  final String updatedAt;

  /// المنشئ الثابت لتهيئة كائن موضع القراءة
  const ReadingPosition({
    this.id = 1,
    required this.surahId,
    required this.ayahNumber,
    required this.updatedAt,
  });

  /// إنشاء نسخة جديدة مع تعديل بعض الخصائص
  ReadingPosition copyWith({
    int? id,
    int? surahId,
    int? ayahNumber,
    String? updatedAt,
  }) {
    return ReadingPosition(
      id: id ?? this.id,
      surahId: surahId ?? this.surahId,
      ayahNumber: ayahNumber ?? this.ayahNumber,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }

  /// تحويل كائن موضع القراءة إلى Map لقاعدة البيانات
  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'surah_id': surahId,
      'ayah_number': ayahNumber,
      'updated_at': updatedAt,
    };
  }

  /// إنشاء كائن موضع القراءة من Map
  factory ReadingPosition.fromMap(Map<String, dynamic> map) {
    return ReadingPosition(
      id: (map['id'] ?? 1) as int,
      surahId: map['surah_id'] as int,
      ayahNumber: map['ayah_number'] as int,
      updatedAt: map['updated_at'] as String,
    );
  }

  @override
  List<Object?> get props => [id, surahId, ayahNumber, updatedAt];
}
