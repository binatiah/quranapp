# خطة العمل للمرحلة القادمة: المفضلة والملاحظات وإعدادات التطبيق (Bookmarks & Settings)

## اسم التدفق

`next_step_bookmarks_and_settings`

## أهداف المرحلة القادمة (المرحلة 7)

1. **إدارة المفضلة والملاحظات [BookmarksRepository](file:///c:/Users/Atiah/myworks/quranapp/lib/features/bookmarks/domain/repositories/bookmarks_repository.dart)**:
   - بناء مستودع المفضلة للتعامل مع جدول `bookmarks` في SQLite.
   - إضافة آية للمفضلة مع إمكانية تدوين ملاحظة نصية.
   - تعديل وحذف الملاحظات وإلغاء التفضيل.
   - جلب قائمة الآيات المفضلة مع نصوصها العثمانية وأسماء سورها وأرقام آياتها.
   - تطوير شاشة المفضلة [BookmarksScreen](file:///c:/Users/Atiah/myworks/quranapp/lib/features/bookmarks/presentation/screens/bookmarks_screen.dart) مع دعم الانتقال المباشر للمصحف ومشاركة الآية.

2. **إعدادات التطبيق والتخصيص [SettingsRepository](file:///c:/Users/Atiah/myworks/quranapp/lib/features/settings/domain/repositories/settings_repository.dart)**:
   - حفظ واسترجاع حجم خط القراءة (Font Size) بشكل دائم عبر `shared_preferences`.
   - إدارة وحفظ سمة المظهر (ThemeMode: فاتح / داكن / يتبع النظام).
   - تطوير شاشة الإعدادات [SettingsScreen](file:///c:/Users/Atiah/myworks/quranapp/lib/features/settings/presentation/screens/settings_screen.dart) بواجهة عصرية متناسقة مع الهوية البصرية للتطبيق.
   - ربط إعدادات الخط والمظهر فورياً مع `AppTheme` و `QuranReaderScreen`.

3. **الاختبارات الآلية الشاملة**:
   - اختبارات وحدة لعمليات إضافة وحذف وجلب المفضلة.
   - اختبارات حفظ واسترجاع تفضيلات الخط والمظهر.
   - تشغيل `flutter analyze` و `flutter test`.
