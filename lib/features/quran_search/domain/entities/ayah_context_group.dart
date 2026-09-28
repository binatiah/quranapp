import 'package:equatable/equatable.dart';
import '../../../quran_reader/domain/entities/ayah.dart';
import 'ayah_range.dart';

/// يمثل مجموعة سياق قرآني متصل لسورة معينة، يضم الآيات ونطاقها والآيات الأصلية المطابقة للبحث.
class AyahContextGroup extends Equatable {
  /// رقم السورة
  final int surahId;

  /// اسم السورة بالعربية
  final String surahName;

  /// نطاق الآيات المشمول في هذه المجموعة
  final AyahRange range;

  /// قائمة كائنات الآيات المجلوبة لهذا السياق (مرتبة تسلسليًا)
  final List<Ayah> ayahs;

  /// أرقام الآيات الأصلية المستهدفة بالبحث لتمييزها بصريًا في السياق
  final Set<int> matchedAyahNumbers;

  /// المنشئ الثابت لتهيئة مجموعة سياق الآيات
  const AyahContextGroup({
    required this.surahId,
    required this.surahName,
    required this.range,
    required this.ayahs,
    required this.matchedAyahNumbers,
  });

  /// إنشاء نسخة جديدة مع تعديل بعض الخصائص
  AyahContextGroup copyWith({
    int? surahId,
    String? surahName,
    AyahRange? range,
    List<Ayah>? ayahs,
    Set<int>? matchedAyahNumbers,
  }) {
    return AyahContextGroup(
      surahId: surahId ?? this.surahId,
      surahName: surahName ?? this.surahName,
      range: range ?? this.range,
      ayahs: ayahs ?? this.ayahs,
      matchedAyahNumbers: matchedAyahNumbers ?? this.matchedAyahNumbers,
    );
  }

  @override
  List<Object?> get props => [
        surahId,
        surahName,
        range,
        ayahs,
        matchedAyahNumbers,
      ];
}
