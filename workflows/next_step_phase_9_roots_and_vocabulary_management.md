# خطة وتدفق المرحلة 9: دليل وإدارة الجذور ومعجم الكلمات القرآنية (Phase 9: Roots Directory & Vocabulary Management)

## اسم التدفق
`next_step_phase_9_roots_and_vocabulary_management`

## أهداف المرحلة 9
1. **دليل وإدارة الجذور اللغوية (Roots Management)**:
   - مستودع بيانات [RootManagementRepository](file:///c:/Users/Atiah/myworks/quranapp/lib/features/root_study/domain/repositories/root_management_repository.dart) وتطبيقه العملي [RootManagementRepositoryImpl](file:///c:/Users/Atiah/myworks/quranapp/lib/features/root_study/data/repositories/root_management_repository_impl.dart).
   - واجهة [RootsDirectoryScreen](file:///c:/Users/Atiah/myworks/quranapp/lib/features/root_study/presentation/screens/roots_directory_screen.dart) مع دعم البحث الفوري، الفرز بالأكثر تكراراً أو الأكثر مشتقات أو الأبجدي أو بدون وصف.
   - عمليات الإضافة والتعديل والحذف الآمن مع نافذة [AddEditRootDialog](file:///c:/Users/Atiah/myworks/quranapp/lib/features/root_study/presentation/widgets/add_edit_root_dialog.dart).
2. **معجم وإدارة وتصحيح الكلمات القرآنية (Vocabulary Management)**:
   - مستودع [WordManagementRepository](file:///c:/Users/Atiah/myworks/quranapp/lib/features/vocabulary/domain/repositories/word_management_repository.dart) وتطبيقه [WordManagementRepositoryImpl](file:///c:/Users/Atiah/myworks/quranapp/lib/features/vocabulary/data/repositories/word_management_repository_impl.dart).
   - واجهة [WordsManagementScreen](file:///c:/Users/Atiah/myworks/quranapp/lib/features/vocabulary/presentation/screens/words_management_screen.dart) مع تصفية الكلمات بالسورة وبحالة الارتباط بالجذر.
   - نافذة تفاعلية لإعادة ربط الكلمة بالجذر [RelinkWordDialog](file:///c:/Users/Atiah/myworks/quranapp/lib/features/vocabulary/presentation/widgets/relink_word_dialog.dart) مدعومة باقتراحات [RootResolver](file:///c:/Users/Atiah/myworks/quranapp/lib/features/quran_search/data/services/root_resolver_impl.dart) الذكية وخيار التطبيق الجماعي.
   - نافذة تعديل بيانات وتفاصيل الكلمة الصرفية [EditWordDialog](file:///c:/Users/Atiah/myworks/quranapp/lib/features/vocabulary/presentation/widgets/edit_word_dialog.dart).
3. **الهوية البصرية وتكوين النظام الأساسي (App Branding & Identity)**:
   - تحديث معرف التطبيق (`applicationId` و `namespace`) إلى المعرف المعتمد `com.binatiah.quranapp` في [build.gradle.kts](file:///c:/Users/Atiah/myworks/quranapp/android/app/build.gradle.kts).
   - نقل وتحديث حزمة Kotlin إلى `com.binatiah.quranapp` في [MainActivity.kt](file:///c:/Users/Atiah/myworks/quranapp/android/app/src/main/kotlin/com/binatiah/quranapp/MainActivity.kt).
   - تصميم وتوليد أيقونة التطبيق الإسلامية الفاخرة (`ic_launcher.png`) بكافة كثافات الشاشة (mdpi, hdpi, xhdpi, xxhdpi, xxxhdpi).
