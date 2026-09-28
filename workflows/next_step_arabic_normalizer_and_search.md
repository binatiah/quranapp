# خطة العمل للمرحلة القادمة: مطبع النصوص العربي والبحث المباشر (Arabic Normalizer & Search)

## اسم التدفق
`next_step_arabic_normalizer_and_search`

## أهداف المرحلة القادمة (المرحلة 4)
1. **بناء مطبع النصوص العربي المستقل [ArabicNormalizer](file:///c:/Users/Atiah/myworks/quranapp/lib/core/text/arabic_normalizer.dart)**:
   - إنشاء واجهة `ArabicNormalizer` والخدمة التنفيذية `ArabicNormalizerImpl`.
   - إزالة التشكيل (الحركات والتنوين وعلامات الضبط).
   - إزالة علامة التطويل (الكشيدة `ـ`).
   - إزالة علامات الوقف والرموز القرآنية من نسخة البحث.
   - توحيد صور الألف لأغراض البحث: `[أ، إ، آ، ٱ]` إلى `ا`.
   - توحيد التاء المربوطة والهاء والياء والألف المقصورة بحسب السياسة المعتمدة في TRD.
   - تنظيف المسافات الزائدة وتقسيم العبارات إلى كلمات (Tokenization).
   - الالتزام الصارم بعدم تعديل النص العثماني الأصلي المخصص للعرض.
2. **تنفيذ مستودع البحث القرآني [QuranSearchRepository](file:///c:/Users/Atiah/myworks/quranapp/lib/features/quran_search/domain/repositories/quran_search_repository.dart)**:
   - البحث بالكلمة المباشرة التامة (`searchExactWord`).
   - البحث بدون تشكيل والبحث النصي العام في الآيات (`searchText`).
   - استعلامات parameterized queries سريعة مستفيدة من الفهرس `idx_words_normalized` و `idx_ayahs_surah_number`.
3. **إدارة الحالة وميزة الـ Debounce**:
   - بناء `SearchNotifier` مع إضافة Debounce (300-500ms) لمنع إطلاق استعلامات متزامنة مع كل ضغطة حرف.
   - معالجة حالات البحث (Initial, Loading, Success, Empty, Error).
4. **تطوير شاشات البحث والنتائج**:
   - ترقية [SearchScreen](file:///c:/Users/Atiah/myworks/quranapp/lib/features/quran_search/presentation/screens/search_screen.dart) لعرض البحث المباشر واقتراحات الكلمات وسجل البحث الأخير.
   - ترقية [SearchResultsScreen](file:///c:/Users/Atiah/myworks/quranapp/lib/features/quran_search/presentation/screens/search_results_screen.dart) لعرض بطاقات نتائج البحث المتطابقة مع تمييز الكلمات المطابقة بالألوان الإسلامية وربط الانتقال إلى المصحف وسياق الآية.
5. **الاختبارات الآلية والتحقق**:
   - اختبارات وحدة لـ `ArabicNormalizer` (إزالة التشكيل، توحيد الألف، التطويل، تنظيف الوقف).
   - اختبارات مستودع البحث `QuranSearchRepository`.
   - تشغيل `flutter analyze` و `flutter test`.
