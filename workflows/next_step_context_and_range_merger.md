# خطة العمل للمرحلة القادمة: سياق الآيات ودمج النطاقات المتداخلة (Ayah Context & Range Merger)

## اسم التدفق

`next_step_context_and_range_merger`

## أهداف المرحلة القادمة (المرحلة 6)

1. **بناء خدمة دمج النطاقات [AyahRangeMerger](file:///c:/Users/Atiah/myworks/quranapp/lib/features/quran_search/domain/services/ayah_range_merger.dart)**:
   - استقبال نتائج الآيات البحثية وحساب النطاقات بناءً على `beforeCount` و `afterCount`.
   - قص بداية النطاق عند الآية 1 من السورة.
   - قص نهاية النطاق عند أقصى عدد آيات في السورة (`ayah_count`).
   - عدم انتقال السياق بين السور في الوضع الافتراضي.
   - ترتيب النطاقات ودمج النطاقات المتداخلة والمتجاورة داخل السورة الواحدة دون تكرار للآيات.
   - الاحتفاظ الدقيق بقائمة أرقام الآيات المطابقة الأصلية (`matchedAyahNumbers`) لتمييزها بصرياً.

2. **بناء خدمة جلب سياق الآيات [SearchContextService](file:///c:/Users/Atiah/myworks/quranapp/lib/features/quran_search/domain/services/search_context_service.dart)**:
   - جلب الآيات المرتبطة بكل نطاق مدمج من قاعدة البيانات دفعة واحدة.
   - تجميع النتائج في مجموعات سياقية [AyahContextGroup](file:///c:/Users/Atiah/myworks/quranapp/lib/features/quran_search/domain/entities/ayah_context_group.dart).

3. **تطوير شاشة سياق الآيات [AyahContextScreen](file:///c:/Users/Atiah/myworks/quranapp/lib/features/quran_search/presentation/screens/ayah_context_screen.dart)**:
   - التحكم التفاعلي بعدد الآيات السابقة واللاحقة (0 إلى 20).
   - عرض الآيات السابقة واللاحقة بتنسيق انسيابي مع تمييز الآية المطابقة بلون واضح وهوية بصرية مميزة.
   - أزرار فتح السورة في المصحف، النسخ، المشاركة، والمفضلة.

4. **الاختبارات الآلية الشاملة**:
   - اختبارات وحدة لحساب النطاقات وقص الحدود عند أول السورة وآخرها.
   - اختبارات دمج النطاقات المتداخلة (مثال: 15-24 + 17-26 + 18-27 = 15-27).
   - اختبارات عدم دمج نطاقات سور مختلفة.
   - تشغيل `flutter analyze` و `flutter test`.
