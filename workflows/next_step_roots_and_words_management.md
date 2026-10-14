# خطة العمل للمرحلة القادمة: إدارة الجذور ومعجم الكلمات المتقدم (Roots Directory & Vocabulary Management)

## اسم التدفق
`next_step_roots_and_words_management`

## ملخص ما تم إنجازه في هذه المرحلة
1. **دليل وإدارة الجذور القرآنية (Roots Directory & Management)**:
   - إنشاء [RootManagementRepository](file:///c:/Users/Atiah/myworks/quranapp/lib/features/root_study/domain/repositories/root_management_repository.dart) وتطبيقه العملي [RootManagementRepositoryImpl](file:///c:/Users/Atiah/myworks/quranapp/lib/features/root_study/data/repositories/root_management_repository_impl.dart).
   - توفير عمليات CRUD كاملة للجذور (بحث فوري، فرز متعدد، إضافة جذر، تعديل البيانات والوصف، وحذف مع سلامة الروابط).
   - بناء شاشة دليل الجذور [RootsDirectoryScreen](file:///c:/Users/Atiah/myworks/quranapp/lib/features/root_study/presentation/screens/roots_directory_screen.dart) مع حوار تفاعلي [AddEditRootDialog](file:///c:/Users/Atiah/myworks/quranapp/lib/features/root_study/presentation/widgets/add_edit_root_dialog.dart).
2. **معجم وإدارة الكلمات القرآنية (Words & Vocabulary Management)**:
   - إنشاء [WordManagementRepository](file:///c:/Users/Atiah/myworks/quranapp/lib/features/vocabulary/domain/repositories/word_management_repository.dart) وتطبيقه الفعلي [WordManagementRepositoryImpl](file:///c:/Users/Atiah/myworks/quranapp/lib/features/vocabulary/data/repositories/word_management_repository_impl.dart).
   - توفير فلترة الكلمات (بالبحث النصي، بالسورة من الـ 114 سورة، وبحالة الارتباط بالجذر: مرتبطة/غير مرتبطة/جذر محدد).
   - بناء شاشة معجم الكلمات [WordsManagementScreen](file:///c:/Users/Atiah/myworks/quranapp/lib/features/vocabulary/presentation/screens/words_management_screen.dart).
   - نافذة تفاعلية لإعادة ربط الكلمة بالجذر [RelinkWordDialog](file:///c:/Users/Atiah/myworks/quranapp/lib/features/vocabulary/presentation/widgets/relink_word_dialog.dart) مدعومة باقتراحات ذكية من `RootResolver` وخيار التطبيق الجماعي على كامل مواضع الكلمة في المصحف.
   - نافذة تعديل بيانات وتفاصيل الكلمة الصرفية [EditWordDialog](file:///c:/Users/Atiah/myworks/quranapp/lib/features/vocabulary/presentation/widgets/edit_word_dialog.dart).
3. **التكامل والتوجيه والتحقق**:
   - تسجيل المسارين `/roots` و `/words` في [appRouter](file:///c:/Users/Atiah/myworks/quranapp/lib/app/router.dart).
   - إضافة بطاقات الوصول السريع في الشاشة الرئيسية [HomeScreen](file:///c:/Users/Atiah/myworks/quranapp/lib/features/home/presentation/screens/home_screen.dart).
   - كتابة 10 اختبارات تكامل جديدة واجتياز 103 اختبارات بنسبة 100%.

## الخطوات المستقبلية المقترحة للمرحلة القادمة
1. **تصدير واستيراد تصحيحات المعجم (Lexicon Export & Import)**:
   - تصدير التعديلات والتصحيحات التي يجريها المستخدم على الجذور والكلمات إلى ملفات JSON / CSV لتبادلها أو حفظ نسخة احتياطية منها.
2. **شجرة الاشتقاق البصرية (Morphological Derivation Tree)**:
   - رسم بياني تفاعلي يوضح تفرع الكلمات القرآنية من الجذر (الماضي، المضارع، اسم الفاعل، اسم المفعول، المصادر).
3. **التدقيق الصرفي الجماعي (Batch Morphology Auditing)**:
   - لوحة إحصائية ترصد الكلمات غير المحللة صرفياً وتتيح مراجعتها وتصنيفها دفعة واحدة.
