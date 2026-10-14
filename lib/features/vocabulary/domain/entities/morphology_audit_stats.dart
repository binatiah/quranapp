import 'package:equatable/equatable.dart';

/// يمثل إحصاءات التدقيق الصرفي والمعجمي لكلمات القرآن الكريم
class MorphologyAuditStats extends Equatable {
  /// إجمالي عدد الكلمات في المصحف الشريف (عادة 77,794 أو 77,430)
  final int totalWords;

  /// عدد الكلمات المرتبطة بجذر لغوي
  final int wordsWithRoot;

  /// عدد الكلمات غير المرتبطة بأي جذر لغوي
  final int wordsWithoutRoot;

  /// عدد الكلمات التي تفتقر لتصنيف صرفي
  final int wordsWithoutMorphology;

  /// إجمالي عدد الجذور اللغوية الفريدة في المعجم
  final int totalUniqueRoots;

  const MorphologyAuditStats({
    required this.totalWords,
    required this.wordsWithRoot,
    required this.wordsWithoutRoot,
    required this.wordsWithoutMorphology,
    required this.totalUniqueRoots,
  });

  /// نسبة الربط اللغوي المئوية
  double get rootCoveragePercentage {
    if (totalWords == 0) return 0.0;
    return (wordsWithRoot / totalWords) * 100.0;
  }

  /// نسبة الاكتمال الصرفي المئوية
  double get morphologyCoveragePercentage {
    if (totalWords == 0) return 0.0;
    return ((totalWords - wordsWithoutMorphology) / totalWords) * 100.0;
  }

  @override
  List<Object?> get props => [
        totalWords,
        wordsWithRoot,
        wordsWithoutRoot,
        wordsWithoutMorphology,
        totalUniqueRoots,
      ];
}
