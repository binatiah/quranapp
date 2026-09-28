/// يحدد نوع المطابقة التي أدت إلى ظهور الآية أو الكلمة في نتائج البحث.
enum SearchMatchType {
  /// مطابقة حرفية تامة مع التشكيل والرسم العثماني
  exact,

  /// مطابقة نصية بعد إزالة التشكيل وتوحيد الألف
  normalized,

  /// مطابقة صرفية من خلال أصل الكلمة (Lemma)
  lemma,

  /// مطابقة من خلال جذر قرآني صرفي موثق
  verifiedRoot,

  /// مطابقة من خلال قاموس المفردات القرآني
  dictionaryRoot,

  /// مطابقة مستنبطة صرفيًا
  inferredRoot,

  /// اقتراح غير مؤكد ناتج عن توافق الحروف بالترتيب (خيار احتياطي)
  orderedCharactersSuggestion;

  /// النص الوصفي باللغة العربية لعرضه في واجهة المستخدم
  String get labelArabic {
    switch (this) {
      case SearchMatchType.exact:
        return 'مطابقة مباشرة تامة';
      case SearchMatchType.normalized:
        return 'مطابقة بعد إزالة التشكيل';
      case SearchMatchType.lemma:
        return 'مطابقة بأصل الكلمة';
      case SearchMatchType.verifiedRoot:
        return 'مطابقة صرفية موثقة';
      case SearchMatchType.dictionaryRoot:
        return 'مطابقة معجمية';
      case SearchMatchType.inferredRoot:
        return 'مطابقة صرفية مستنبطة';
      case SearchMatchType.orderedCharactersSuggestion:
        return 'اقتراح بحروف مرتبة (غير مؤكد)';
    }
  }

  /// هل النتيجة مؤكدة صرفياً أم أنها مجرد اقتراح بالحروف المرتبة؟
  bool get isVerified {
    return this != SearchMatchType.orderedCharactersSuggestion;
  }
}
