import 'package:equatable/equatable.dart';

/// يمثل كيان العلامة المرجعية (المفضلة) لآية محددة مع إمكانية إضافة ملاحظة.
class Bookmark extends Equatable {
  /// المعرف الفريد للعلامة في قاعدة البيانات
  final int? id;

  /// معرف الآية المرتبطة
  final int ayahId;

  /// رقم السورة (لتسهيل العرض في الواجهة)
  final int? surahId;

  /// اسم السورة بالعربية (لتسهيل العرض)
  final String? surahName;

  /// رقم الآية داخل السورة
  final int? ayahNumber;

  /// جزء من نص الآية للعرض السريع في بطاقة المفضلة
  final String? ayahText;

  /// ملاحظة أو تدبر كتبه المستخدم حول الآية
  final String? note;

  /// تاريخ ووقت إنشاء المفضلة بصيغة ISO 8601
  final String createdAt;

  /// المنشئ الثابت لتهيئة كائن المفضلة
  const Bookmark({
    this.id,
    required this.ayahId,
    this.surahId,
    this.surahName,
    this.ayahNumber,
    this.ayahText,
    this.note,
    required this.createdAt,
  });

  /// إنشاء نسخة جديدة مع تعديل بعض الخصائص
  Bookmark copyWith({
    int? id,
    int? ayahId,
    int? surahId,
    String? surahName,
    int? ayahNumber,
    String? ayahText,
    String? note,
    String? createdAt,
  }) {
    return Bookmark(
      id: id ?? this.id,
      ayahId: ayahId ?? this.ayahId,
      surahId: surahId ?? this.surahId,
      surahName: surahName ?? this.surahName,
      ayahNumber: ayahNumber ?? this.ayahNumber,
      ayahText: ayahText ?? this.ayahText,
      note: note ?? this.note,
      createdAt: createdAt ?? this.createdAt,
    );
  }

  /// تحويل كائن المفضلة إلى Map لقاعدة البيانات
  Map<String, dynamic> toMap() {
    final map = <String, dynamic>{
      'ayah_id': ayahId,
      'note': note,
      'created_at': createdAt,
    };
    if (id != null) {
      map['id'] = id;
    }
    return map;
  }

  /// إنشاء كائن المفضلة من Map قادم من استعلام SQLite
  factory Bookmark.fromMap(Map<String, dynamic> map) {
    return Bookmark(
      id: map['id'] as int?,
      ayahId: map['ayah_id'] as int,
      surahId: map['surah_id'] as int?,
      surahName: map['surah_name'] as String?,
      ayahNumber: map['ayah_number'] as int?,
      ayahText: map['text_uthmani'] as String? ?? map['ayah_text'] as String?,
      note: map['note'] as String?,
      createdAt: map['created_at'] as String,
    );
  }

  @override
  List<Object?> get props => [
        id,
        ayahId,
        surahId,
        surahName,
        ayahNumber,
        ayahText,
        note,
        createdAt,
      ];
}
