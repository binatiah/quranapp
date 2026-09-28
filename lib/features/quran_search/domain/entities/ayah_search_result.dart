import 'package:equatable/equatable.dart';
import 'search_match_type.dart';

/// يمثل نتيجة بحث للآية القرآنية في نتائج البحث والدراسة.
class AyahSearchResult extends Equatable {
  /// معرف الآية في قاعدة البيانات
  final int ayahId;

  /// رقم السورة
  final int surahId;

  /// اسم السورة بالعربية (مثل: سورة البقرة)
  final String surahName;

  /// رقم الآية داخل السورة
  final int ayahNumber;

  /// رقم الآية التراكمي في المصحف
  final int globalAyahNumber;

  /// النص العثماني الأصلي للآية
  final String textUthmani;

  /// قائمة الكلمات المطابقة داخل هذه الآية
  final List<String> matchedWords;

  /// الجذر المطابق إن وُجد
  final String? matchedRoot;

  /// نوع المطابقة الذي أنتج هذه النتيجة
  final SearchMatchType matchType;

  /// المنشئ الثابت لتهيئة نتيجة بحث الآية
  const AyahSearchResult({
    required this.ayahId,
    required this.surahId,
    required this.surahName,
    required this.ayahNumber,
    required this.globalAyahNumber,
    required this.textUthmani,
    required this.matchedWords,
    required this.matchType,
    this.matchedRoot,
  });

  /// إنشاء نسخة جديدة مع تعديل بعض الخصائص
  AyahSearchResult copyWith({
    int? ayahId,
    int? surahId,
    String? surahName,
    int? ayahNumber,
    int? globalAyahNumber,
    String? textUthmani,
    List<String>? matchedWords,
    String? matchedRoot,
    SearchMatchType? matchType,
  }) {
    return AyahSearchResult(
      ayahId: ayahId ?? this.ayahId,
      surahId: surahId ?? this.surahId,
      surahName: surahName ?? this.surahName,
      ayahNumber: ayahNumber ?? this.ayahNumber,
      globalAyahNumber: globalAyahNumber ?? this.globalAyahNumber,
      textUthmani: textUthmani ?? this.textUthmani,
      matchedWords: matchedWords ?? this.matchedWords,
      matchedRoot: matchedRoot ?? this.matchedRoot,
      matchType: matchType ?? this.matchType,
    );
  }

  @override
  List<Object?> get props => [
        ayahId,
        surahId,
        surahName,
        ayahNumber,
        globalAyahNumber,
        textUthmani,
        matchedWords,
        matchedRoot,
        matchType,
      ];
}
