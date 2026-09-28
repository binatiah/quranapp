# خطة العمل للمرحلة القادمة: قائمة السور وتلاوة الآيات (Surahs List & Quran Reader)

## اسم التدفق
`next_step_surahs_and_reader`

## أهداف المرحلة القادمة (المرحلة 3)
1. **واجهة ومستودع السور والآيات (Data & Domain Repositories)**:
   - بناء الواجهة المعمارية `QuranRepository` في `lib/features/quran_reader/domain/repositories/quran_repository.dart`.
   - تنفيذ المستودع الفعلي `QuranRepositoryImpl` في `lib/features/quran_reader/data/repositories/quran_repository_impl.dart`.
   - كتابة الدوال:
     - `getSurahs()`: جلب قائمة السور الـ 114 مرتبة.
     - `getSurahAyahs(int surahId)`: جلب جميع آيات السورة بالنص العثماني.
     - `getAyah(int surahId, int ayahNumber)`: جلب آية محددة.
     - `getAyahRange(...)`: جلب نطاق محدد من الآيات.
     - `getLastReadingPosition()` و `saveReadingPosition(...)`: إدارة حفظ واسترجاع موضع القراءة.
2. **إدارة الحالة (Riverpod State Notifiers)**:
   - إنشاء `SurahListNotifier` و `SurahListState` لإدارة حالة قائمة السور والبحث فيها.
   - إنشاء `ReaderNotifier` و `ReaderState` لإدارة تلاوة السورة والتمرير السلس وحجم الخط وموضع القراءة.
3. **تطوير شاشات العرض والتفاعل (Presentation Layer)**:
   - تحديث [SurahListScreen](file:///c:/Users/Atiah/myworks/quranapp/lib/features/quran_reader/presentation/screens/surah_list_screen.dart) لعرض السور الـ 114 مع معلوماتها التنزيلية وعدد الآيات مع شريط بحث سريع.
   - تحديث [QuranReaderScreen](file:///c:/Users/Atiah/myworks/quranapp/lib/features/quran_reader/presentation/screens/quran_reader_screen.dart) لعرض الآيات بالنص العثماني الأصلي المشكول، والتمرير المستمر، ونسخ ومشاركة الآيات، والتحكم بحجم الخط، وحفظ آخر موضع قراءة تلقائياً.
4. **الاختبارات الآلية والتحقق**:
   - اختبارات مستودع `QuranRepository` مع قاعدة SQLite.
   - اختبارات وحدات التحكم (Notifiers).
   - تشغيل `flutter analyze` و `flutter test`.
