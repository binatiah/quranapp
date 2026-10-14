import 'package:equatable/equatable.dart';

/// يمثل عنصراً أو كلمة في قائمة التدقيق الصرفي والمعجمي
class MorphologyAuditItem extends Equatable {
  /// معرف الكلمة في جدول words
  final int wordId;

  /// الكلمة بالرسم العثماني
  final String wordUthmani;

  /// الكلمة المطبّعة منزوعة التشكيل
  final String wordNormalized;

  /// اسم السورة
  final String surahName;

  /// رقم السورة
  final int surahId;

  /// رقم الآية
  final int ayahNumber;

  /// موضع الكلمة في الآية
  final int wordPosition;

  /// التصنيف الصرفي الحالي (مثل N, V, P, PRON) إن وجد
  final String? partOfSpeech;

  /// الجذر اللغوي الحالي (إن وجد)
  final String? root;

  /// عدد مرات تكرار هذه الكلمة المطبّعة في المصحف
  final int occurrences;

  const MorphologyAuditItem({
    required this.wordId,
    required this.wordUthmani,
    required this.wordNormalized,
    required this.surahName,
    required this.surahId,
    required this.ayahNumber,
    required this.wordPosition,
    this.partOfSpeech,
    this.root,
    required this.occurrences,
  });

  /// تحويل من صف قاعدة البيانات
  factory MorphologyAuditItem.fromMap(Map<String, Object?> map) {
    return MorphologyAuditItem(
      wordId: (map['id'] as num).toInt(),
      wordUthmani: (map['word_uthmani'] ?? '') as String,
      wordNormalized: (map['word_normalized'] ?? '') as String,
      surahName: (map['surah_name'] ?? '') as String,
      surahId: (map['surah_id'] as num?)?.toInt() ?? 1,
      ayahNumber: (map['ayah_number'] as num?)?.toInt() ?? 1,
      wordPosition: (map['word_position'] as num?)?.toInt() ?? 1,
      partOfSpeech: map['part_of_speech'] as String?,
      root: map['root'] as String?,
      occurrences: (map['occurrences'] as num?)?.toInt() ?? 1,
    );
  }

  @override
  List<Object?> get props => [
        wordId,
        wordUthmani,
        wordNormalized,
        surahName,
        surahId,
        ayahNumber,
        wordPosition,
        partOfSpeech,
        root,
        occurrences,
      ];
}
