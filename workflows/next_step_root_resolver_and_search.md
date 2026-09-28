# خطة العمل للمرحلة القادمة: محرك استخراج الجذور ودراسة الجذر (Root Resolver & Study)

## اسم التدفق
`next_step_root_resolver_and_search`

## أهداف المرحلة القادمة (المرحلة 5)
1. **بناء محرك تحديد الجذور المتقدم [RootResolver](file:///c:/Users/Atiah/myworks/quranapp/lib/features/quran_search/domain/services/root_resolver.dart)**:
   - تطبيق المستويات الستة الصارمة المحددة في TRD:
     1. البحث المباشر في `word_normalized`.
     2. البحث في أصل الكلمة `lemma_normalized`.
     3. مطابقة `root_normalized` المباشرة إذا أدخل المستخدم جذرًا.
     4. البحث في قاموس الكلمات المحلي.
     5. التخمين الصرفي المنهجي.
     6. البحث بالحروف المرتبة كخيار احتياطي أخير وتصنيفه صراحة كاقتراح غير مؤكد.
   - تصنيف مصادر النتائج:
     - `verifiedRoot` (جذر موثق صرفيًا)
     - `dictionaryRoot` (جذر معجمي)
     - `inferredRoot` (جذر مستنبط)
     - `orderedCharactersSuggestion` (اقتراح حروف مرتبة غير مؤكد)
   - دعم عرض مربعات الاختيار في حال تعدد الجذور المحتملة لاختيار الجذر المقصود.
2. **تطوير شاشة دراسة الجذر [RootStudyScreen](file:///c:/Users/Atiah/myworks/quranapp/lib/features/root_study/presentation/screens/root_study_screen.dart)**:
   - عرض الجذر وبياناته ومعناه اللغوي.
   - عرض جميع الكلمات القرآنية المشتقة من الجذر مع تكرار كل كلمة.
   - إحصاءات توزيع الكلمات على سور القرآن الكريم.
   - الانتقال المباشر لأي كلمة أو موضع في المصحف.
3. **الاختبارات الآلية والتحقق**:
   - اختبارات وحدة لمستويات `RootResolver` الستة وتصنيف النتائج.
   - اختبارات استعلامات دراسة الجذر وإحصاءات المشتقات.
   - تشغيل `flutter analyze` و `flutter test`.
