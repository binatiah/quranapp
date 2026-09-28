import 'package:equatable/equatable.dart';

/// يمثل إحصائية تكرار الجذر أو الكلمات المشتقة منه في سورة معينة.
class SurahOccurrence extends Equatable {
  /// معرف السورة (1 إلى 114)
  final int surahId;

  /// اسم السورة بالعربية
  final String surahName;

  /// عدد مرات ورود الجذر في هذه السورة
  final int occurrenceCount;

  /// المنشئ الثابت لإحصائية تكرار السورة
  const SurahOccurrence({
    required this.surahId,
    required this.surahName,
    required this.occurrenceCount,
  });

  /// تحويل من صف قاعدة البيانات
  factory SurahOccurrence.fromMap(Map<String, Object?> map) {
    return SurahOccurrence(
      surahId: (map['surah_id'] as num?)?.toInt() ?? 0,
      surahName: (map['surah_name'] ?? '') as String,
      occurrenceCount: (map['occurrence_count'] as num?)?.toInt() ?? 0,
    );
  }

  @override
  List<Object?> get props => [surahId, surahName, occurrenceCount];
}
