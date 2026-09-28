import 'package:flutter/material.dart';
import '../../app/theme/app_theme.dart';
import 'arabic_normalizer.dart';

/// أدوات مساعدة لمعالجة وتمييز النصوص القرآنية في واجهة المستخدم (Text Highlighting Utils).
class QuranTextUtils {
  static const ArabicNormalizer _normalizer = ArabicNormalizerImpl();

  /// بناء قائمة TextSpan للآية مع تمييز الكلمات المطابقة بلون واضح دون تعديل النص العثماني الأصلي
  static List<TextSpan> highlightMatchedWords({
    required String textUthmani,
    required List<String> matchedWords,
    required TextStyle defaultStyle,
    Color highlightColor = AppTheme.secondaryGold,
  }) {
    if (matchedWords.isEmpty) {
      return [TextSpan(text: textUthmani, style: defaultStyle)];
    }

    final spans = <TextSpan>[];
    final words = textUthmani.split(' ');

    // تجهيز قائمة الكلمات المطابقة بعد التطبيع للمقارنة السريعة
    final normalizedTargets = matchedWords
        .map(_normalizer.normalizeForSearch)
        .where((w) => w.isNotEmpty)
        .toSet();

    for (var i = 0; i < words.length; i++) {
      final word = words[i];
      final normWord = _normalizer.normalizeForSearch(word);

      final isMatch = normalizedTargets.any((target) {
        return normWord == target || normWord.contains(target) || target.contains(normWord);
      });

      if (isMatch) {
        spans.add(
          TextSpan(
            text: word,
            style: defaultStyle.copyWith(
              color: highlightColor,
              fontWeight: FontWeight.bold,
              backgroundColor: highlightColor.withValues(alpha: 0.15),
            ),
          ),
        );
      } else {
        spans.add(TextSpan(text: word, style: defaultStyle));
      }

      if (i < words.length - 1) {
        spans.add(TextSpan(text: ' ', style: defaultStyle));
      }
    }

    return spans;
  }
}
