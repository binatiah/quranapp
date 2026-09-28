/// واجهة معالجة وتطبيع النصوص العربية للقرآن الكريم لأغراض البحث (Arabic Normalizer Interface).
/// تلتزم بعدم المساس بالنص العثماني الأصلي المخصص للعرض، وتوفر نسخاً مطبّعة موحدة للبحث السريع.
abstract interface class ArabicNormalizer {
  /// تطبيع النص للبحث المباشر الدقيق (إزالة التطويل والمسافات وعلامات الترقيم وتوحيد الألف)
  String normalizeForExactSearch(String input);

  /// تطبيع شامل للنص القرآني لعمليات البحث دون تشكيل (إزالة التشكيل، توحيد الألف، والتاء، والياء)
  String normalizeForSearch(String input);

  /// تطبيع مخصص للجذور الصرفية والبحث المعجمي
  String normalizeForRootSearch(String input);

  /// إزالة التشكيل والحركات والتنوين وعلامات الضبط فقط دون تعديل صور الحروف
  String removeDiacritics(String input);

  /// إزالة علامات الوقف والرموز الاصطلاحية القرآنية (مثل: ۖ ۗ ۚ ۛ ۜ ۞ وغيرها)
  String removeQuranicStopSigns(String input);

  /// تقسيم النص إلى قائمة كلمات منفصلة مطهرة
  List<String> tokenize(String input);

  /// التحقق من احتواء الكلمة على حروف الجذر بنفس الترتيب (خيار استنباط احتياطي)
  bool containsCharactersInOrder({
    required String word,
    required String root,
  });
}

/// تطبيق محرك تطبيع النصوص العربية الخاص بالبحث القرآني.
class ArabicNormalizerImpl implements ArabicNormalizer {
  const ArabicNormalizerImpl();

  // تعبير نمطي لجميع الحركات وعلامات التشكيل والتنوين وعلامات الضبط المصحفي
  static final RegExp _diacriticsRegex = RegExp(
    r'[\u0610-\u061A\u064B-\u065F\u0670\u06D6-\u06ED]',
  );

  // تعبير نمطي لعلامات الوقف القرآنية والرموز
  static final RegExp _quranicStopsRegex = RegExp(
    r'[\u06D6-\u06E4\u06E9\u06EA\u06EB\u06EC\u06ED\u06DD\u06DE\u06DF]',
  );

  // تعبير نمطي للرموز وعلامات الترقيم غير الأبجدية
  static final RegExp _punctuationRegex = RegExp(
    r'[^\w\s\u0621-\u064A]',
  );

  @override
  String removeDiacritics(String input) {
    if (input.isEmpty) return '';
    return input.replaceAll(_diacriticsRegex, '').replaceAll('ـ', '').trim();
  }

  @override
  String removeQuranicStopSigns(String input) {
    if (input.isEmpty) return '';
    return input.replaceAll(_quranicStopsRegex, '').trim();
  }

  @override
  String normalizeForExactSearch(String input) {
    if (input.isEmpty) return '';
    var text = removeQuranicStopSigns(input);
    text = text.replaceAll('ـ', '');
    // توحيد صور الهمزة والألف للبحث
    text = text.replaceAll(RegExp(r'[إأآٱ]'), 'ا');
    // تنظيف المسافات الزائدة
    text = text.replaceAll(RegExp(r'\s+'), ' ').trim();
    return text;
  }

  @override
  String normalizeForSearch(String input) {
    if (input.isEmpty) return '';
    // 1. إزالة علامات الوقف والرموز القرآنية
    var text = removeQuranicStopSigns(input);
    // 2. إزالة كافة علامات التشكيل والتنوين
    text = text.replaceAll(_diacriticsRegex, '');
    // 3. إزالة علامة التطويل (الكشيدة)
    text = text.replaceAll('ـ', '');
    // 4. توحيد صور الألف: [أ، إ، آ، ٱ] إلى [ا]
    text = text.replaceAll(RegExp(r'[إأآٱ]'), 'ا');
    // 5. توحيد التاء المربوطة مع الهاء لأغراض البحث المرن
    text = text.replaceAll('ة', 'ه');
    // 6. توحيد الألف المقصورة مع الياء
    text = text.replaceAll('ى', 'ي');
    // 7. إزالة علامات الترقيم والأقواس
    text = text.replaceAll(_punctuationRegex, ' ');
    // 8. تنظيف المسافات
    text = text.replaceAll(RegExp(r'\s+'), ' ').trim();
    return text;
  }

  @override
  String normalizeForRootSearch(String input) {
    if (input.isEmpty) return '';
    var text = normalizeForSearch(input);
    // إزالة الهمزات المتطرفة أو المتوسطة لتقريب الجذر
    text = text.replaceAll(RegExp(r'[ؤئء]'), 'ء');
    return text.replaceAll(' ', '');
  }

  @override
  List<String> tokenize(String input) {
    if (input.isEmpty) return const [];
    final normalized = normalizeForSearch(input);
    return normalized
        .split(RegExp(r'\s+'))
        .where((token) => token.isNotEmpty)
        .toList();
  }

  @override
  bool containsCharactersInOrder({
    required String word,
    required String root,
  }) {
    if (word.isEmpty || root.isEmpty) return false;
    final normalizedWord = normalizeForSearch(word);
    final normalizedRoot = normalizeForRootSearch(root);

    var searchFrom = 0;
    for (final charCode in normalizedRoot.runes) {
      final char = String.fromCharCode(charCode);
      final position = normalizedWord.indexOf(char, searchFrom);
      if (position == -1) {
        return false;
      }
      searchFrom = position + char.length;
    }
    return true;
  }
}
