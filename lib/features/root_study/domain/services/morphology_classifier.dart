import '../entities/derived_word.dart';
import '../entities/morphology_tree_node.dart';

/// محرك تصنيف وتوزيع الكلمات القرآنية المشتقة إلى فروع الشجرة الصرفية (Morphology Classifier).
class MorphologyClassifier {
  const MorphologyClassifier();

  /// تصنيف قائمة الكلمات المشتقة التابعة لجذر معين إلى فروع شجرة الاشتقاق
  MorphologyTreeData classify({
    required String root,
    required String rootNormalized,
    required List<DerivedWord> words,
  }) {
    final Map<String, Map<String, List<DerivedWord>>> treeMap = {
      'الأفعال': {
        'أفعال ماضية': [],
        'أفعال مضارعة': [],
        'أفعال أمر': [],
      },
      'الأسماء والمشتقات': {
        'أسماء فاعلين': [],
        'أسماء مفعولين': [],
        'صيغ مبالغة وصفات مشبهة': [],
        'أسماء تفضيل': [],
        'مصادر وأسماء صريحة': [],
      },
      'مشتقات وتراكيب أخرى': {
        'مشتقات لغوية متنوعة': [],
      },
    };

    for (final word in words) {
      final norm = word.wordNormalized;
      final (category, subCategory) = _determineCategory(norm, rootNormalized);
      treeMap[category]![subCategory]!.add(word);
    }

    final branches = <MorphologyBranch>[];
    int totalOccurrences = 0;
    int totalUniqueWords = words.length;

    treeMap.forEach((category, subCategories) {
      subCategories.forEach((subCat, wordList) {
        if (wordList.isNotEmpty) {
          final branchOccurrences = wordList.fold<int>(0, (sum, w) => sum + w.occurrenceCount);
          totalOccurrences += branchOccurrences;

          // ترتيب كلمات الفرع حسب الأكثر تكراراً
          wordList.sort((a, b) => b.occurrenceCount.compareTo(a.occurrenceCount));

          branches.add(MorphologyBranch(
            categoryName: category,
            subCategory: subCat,
            words: List.unmodifiable(wordList),
            totalOccurrences: branchOccurrences,
          ));
        }
      });
    });

    return MorphologyTreeData(
      root: root,
      rootNormalized: rootNormalized,
      branches: List.unmodifiable(branches),
      totalUniqueWords: totalUniqueWords,
      totalOccurrences: totalOccurrences,
    );
  }

  /// تحديد فرع التصنيف بناءً على الوزن واللواحق والصيغة الصرفية
  (String, String) _determineCategory(String norm, String rootNorm) {
    // إزالة السوابق الشائعة للتحليل: ف، و، ل، ب، ك، ال
    var stripped = norm;
    if (stripped.startsWith('وال') || stripped.startsWith('فال') || stripped.startsWith('بال') || stripped.startsWith('كال') || stripped.startsWith('لل')) {
      stripped = stripped.substring(3);
    } else if (stripped.startsWith('ال')) {
      stripped = stripped.substring(2);
    } else if ((stripped.startsWith('و') || stripped.startsWith('ف') || stripped.startsWith('ب') || stripped.startsWith('ل')) && stripped.length > 3) {
      stripped = stripped.substring(1);
    }

    // 1. أفعال الأمر
    if (stripped.startsWith('اع') || stripped.startsWith('استع') || stripped.startsWith('ان') || stripped.startsWith('اق') || stripped.startsWith('اذ')) {
      if (stripped.endsWith('وا') || stripped.endsWith('ي') || stripped.endsWith('ن')) {
        return ('الأفعال', 'أفعال أمر');
      }
    }

    // 2. أفعال مضارعة (تبدأ بحروف أنيت: ي، ت، ن، أ)
    if ((stripped.startsWith('ي') || stripped.startsWith('ت') || stripped.startsWith('ن')) && stripped.length >= 4) {
      if (stripped.endsWith('ون') || stripped.endsWith('ين') || stripped.endsWith('ان') || stripped.endsWith('وا')) {
        return ('الأفعال', 'أفعال مضارعة');
      }
      return ('الأفعال', 'أفعال مضارعة');
    }

    // 3. أسماء الفاعلين (وزن فاعل / فاعلون / فاعلين / مفعل / مستفعل)
    if (stripped.contains('اع') || stripped.startsWith('مستع') || stripped.startsWith('مع')) {
      if (stripped.endsWith('ين') || stripped.endsWith('ون') || stripped.endsWith('ات') || stripped.endsWith('ة') || stripped.length == 4) {
        return ('الأسماء والمشتقات', 'أسماء فاعلين');
      }
    }

    // 4. أسماء المفعولين (وزن مفعول / مفعولين / مفعولات)
    if (stripped.startsWith('م') && (stripped.contains('و') || stripped.endsWith('ة'))) {
      return ('الأسماء والمشتقات', 'أسماء مفعولين');
    }

    // 5. صيغ مبالغة وصفات مشبهة (وزن فعيل / فعال / فعول)
    if ((stripped.contains('ي') || stripped.contains('و')) && stripped.length <= 5) {
      return ('الأسماء والمشتقات', 'صيغ مبالغة وصفات مشبهة');
    }

    // 6. أسماء التفضيل (وزن أفعل)
    if (stripped.startsWith('ا') && stripped.length == 4) {
      return ('الأسماء والمشتقات', 'أسماء تفضيل');
    }

    // 7. أفعال ماضية (تنتهي بضمائر الرفع: نا، تم، توا، ت، وا)
    if (stripped.endsWith('تم') || stripped.endsWith('نا') || stripped.endsWith('وا') || stripped.endsWith('ت') || stripped.endsWith('تما')) {
      return ('الأفعال', 'أفعال ماضية');
    }

    // 8. مصادر وأسماء صريحة
    if (stripped.length <= 4) {
      return ('الأسماء والمشتقات', 'مصادر وأسماء صريحة');
    }

    return ('مشتقات وتراكيب أخرى', 'مشتقات لغوية متنوعة');
  }
}
