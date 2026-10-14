import 'package:equatable/equatable.dart';
import 'derived_word.dart';

/// فرع اشتقاقي صرفي ضمن شجرة اشتقاقات الجذر (Morphology Branch).
class MorphologyBranch extends Equatable {
  /// اسم الفرع الرئيسي (مثل: الأفعال، المشتقات الاسمية، المصادر، أخرى)
  final String categoryName;

  /// اسم الوزن أو الفئة الفرعية (مثل: فعل مضارع، اسم فاعل، صيغة مبالغة)
  final String subCategory;

  /// الكلمات المشتقة الواردة تحت هذا الفرع
  final List<DerivedWord> words;

  /// إجمالي عدد مرات الورود لكلمات هذا الفرع
  final int totalOccurrences;

  const MorphologyBranch({
    required this.categoryName,
    required this.subCategory,
    required this.words,
    required this.totalOccurrences,
  });

  @override
  List<Object?> get props => [categoryName, subCategory, words, totalOccurrences];
}

/// شجرة الاشتقاق الصرفي الكاملة للجذر القرآني (MorphologyTreeData).
class MorphologyTreeData extends Equatable {
  /// الجذر اللغوي
  final String root;

  /// الجذر المطبّع
  final String rootNormalized;

  /// الفروع والأوزان الاشتقاقية
  final List<MorphologyBranch> branches;

  /// إجمالي عدد الكلمات المشتقة المختلفة
  final int totalUniqueWords;

  /// إجمالي مرات الورود في القرآن الكريم
  final int totalOccurrences;

  const MorphologyTreeData({
    required this.root,
    required this.rootNormalized,
    required this.branches,
    required this.totalUniqueWords,
    required this.totalOccurrences,
  });

  @override
  List<Object?> get props => [
        root,
        rootNormalized,
        branches,
        totalUniqueWords,
        totalOccurrences,
      ];
}
