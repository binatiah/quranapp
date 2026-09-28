# خطة العمل للمرحلة القادمة: بناء قاعدة بيانات SQLite وإدارة الأصول (Database & Assets)

## اسم التدفق

`next_step_database_and_assets`

## أهداف المرحلة القادمة (المرحلة 2)

1. **إنشاء مخطط قاعدة البيانات SQLite**:
   - بناء خدمة [QuranDatabase](file:///c:/Users/Atiah/myworks/quranapp/lib/core/database/quran_database.dart).
   - إنشاء الجداول والفهارس المطلوبة:
     - جدول السور `surahs` (114 سورة).
     - جدول الآيات `ayahs` (6236 آية متضمنة البسملة في الفاتحة).
     - جدول الكلمات والتحليل الصرفي `words`.
     - جدول الجذور `roots`.
     - جدول ربط الكلمات بالجذور `word_roots`.
     - جدول المفضلة `bookmarks`.
     - جدول آخر موضع قراءة `reading_positions`.
     - الفهارس الفائقة للبحث المباشر والبحث بالجذور (`root_normalized`, `word_normalized`, `ayah_id`, ...).

2. **استخراج وتحويل بيانات Excel إلى SQLite مسبقة التجهيز (Pre-populated Database)**:
   - تحويل بيانات [Ayahsquran.xlsx](file:///c:/Users/Atiah/myworks/quranapp/Ayahsquran.xlsx) و [wordquran.xlsx](file:///c:/Users/Atiah/myworks/quranapp/wordquran.xlsx) إلى قاعدة بيانات `quran.db` وحفظها داخل مجلد `assets/database/`.
   - استدراك آية البسملة الناقصة في الفاتحة لضمان سلامة المصحف برواية حفص عن عاصم (6236 آية).

3. **آلية استيراد قاعدة البيانات الجاهزة عند أول تشغيل**:
   - نسخ `quran.db` من الأصول (`assets`) إلى مجلد المستندات المحلي عبر `path_provider` و `sqflite`.

4. **نظام الإصدارات والترقية (Versioning & Migrations)**:
   - دعم التحديث التلقائي والترحيل السلس عند ترقية إصدار قاعدة البيانات.

5. **مستودع القرآن الأساسي [QuranRepository](file:///c:/Users/Atiah/myworks/quranapp/lib/features/quran_reader/domain/repositories/quran_repository.dart)**:
   - تنفيذ استعلامات جلب السور، والآيات، ونطاق الآيات، وموضع القراءة.

6. **الاختبارات والتأكد من الصحة**:
   - اختبارات تكاملية على قاعدة البيانات واختبارات سلامة الأعداد (6236 آية، 114 سورة، والفهارس).
   - تشغيل `flutter analyze` و `flutter test`.
