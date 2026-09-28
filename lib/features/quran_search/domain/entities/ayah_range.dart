import 'package:equatable/equatable.dart';

/// يمثل نطاقًا من الآيات المتصلة داخل نفس السورة، مع حفظ أرقام الآيات المطابقة الأصلية.
class AyahRange extends Equatable {
  /// رقم السورة التي ينتمي إليها النطاق
  final int surahId;

  /// رقم بداية النطاق داخل السورة (شامل)
  final int startAyah;

  /// رقم نهاية النطاق داخل السورة (شامل)
  final int endAyah;

  /// مجموعة أرقام الآيات التي كانت نتائج بحث أصلية (لتسليط الضوء عليها)
  final Set<int> targetAyahNumbers;

  /// المنشئ الثابت لتهيئة نطاق الآيات
  const AyahRange({
    required this.surahId,
    required this.startAyah,
    required this.endAyah,
    this.targetAyahNumbers = const {},
  }) : assert(startAyah <= endAyah, 'startAyah must be less than or equal to endAyah');

  /// إنشاء نسخة جديدة مع تعديل بعض الخصائص
  AyahRange copyWith({
    int? surahId,
    int? startAyah,
    int? endAyah,
    Set<int>? targetAyahNumbers,
  }) {
    return AyahRange(
      surahId: surahId ?? this.surahId,
      startAyah: startAyah ?? this.startAyah,
      endAyah: endAyah ?? this.endAyah,
      targetAyahNumbers: targetAyahNumbers ?? this.targetAyahNumbers,
    );
  }

  /// يتحقق مما إذا كان النطاق الحالي يتداخل أو يجاور نطاقًا آخر في نفس السورة
  bool overlapsOrAdjacent(AyahRange other) {
    if (surahId != other.surahId) return false;
    return !(endAyah + 1 < other.startAyah || other.endAyah + 1 < startAyah);
  }

  /// دمج نطاقين متداخلين أو متجاورين في نطاق واحد ممتد
  AyahRange mergeWith(AyahRange other) {
    assert(surahId == other.surahId, 'Cannot merge ranges from different surahs');
    final newStart = startAyah < other.startAyah ? startAyah : other.startAyah;
    final newEnd = endAyah > other.endAyah ? endAyah : other.endAyah;
    final combinedTargets = {...targetAyahNumbers, ...other.targetAyahNumbers};

    return AyahRange(
      surahId: surahId,
      startAyah: newStart,
      endAyah: newEnd,
      targetAyahNumbers: combinedTargets,
    );
  }

  @override
  List<Object?> get props => [surahId, startAyah, endAyah, targetAyahNumbers];
}
