# خطة العمل للمرحلة القادمة: إدارة الجذور ومعجم الكلمات المتقدم (Roots Directory & Vocabulary Management)

## اسم التدفق
`next_step_roots_and_words_management`

## ملخص ما تم إنجازه بالكامل في هذا التدفق (Completed Steps)
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

3. **تصدير واستيراد تصحيحات المعجم (Lexicon Export & Import)**:
   - إنشاء نماذج البيانات [LexiconExportData](file:///c:/Users/Atiah/myworks/quranapp/lib/features/vocabulary/domain/entities/lexicon_export_data.dart) ومستودع التصدير والاستيراد [LexiconIORepository](file:///c:/Users/Atiah/myworks/quranapp/lib/features/vocabulary/domain/repositories/lexicon_io_repository.dart) وتطبيقه [LexiconIORepositoryImpl](file:///c:/Users/Atiah/myworks/quranapp/lib/features/vocabulary/data/repositories/lexicon_io_repository_impl.dart).
   - تنفيذ نافذة الحوار المتكاملة [LexiconExportImportDialog](file:///c:/Users/Atiah/myworks/quranapp/lib/features/vocabulary/presentation/widgets/lexicon_export_import_dialog.dart) لدعم تصدير التصحيحات أو كامل المعجم بصيغة JSON، ونسخها أو مشاركتها واستيرادها ودمجها بأمان تام عبر معاملات SQLite.
   - إضافة أزرار الوصول في شاشات الجذور والكلمات والإعدادات.

4. **شجرة الاشتقاق البصرية (Morphological Derivation Tree)**:
   - إنشاء الكيان [MorphologyTreeData](file:///c:/Users/Atiah/myworks/quranapp/lib/features/root_study/domain/entities/morphology_tree_node.dart) ومحرك التصنيف الصرفي الذكي [MorphologyClassifier](file:///c:/Users/Atiah/myworks/quranapp/lib/features/root_study/domain/services/morphology_classifier.dart).
   - بناء الواجهة التفاعلية [MorphologicalDerivationTreeView](file:///c:/Users/Atiah/myworks/quranapp/lib/features/root_study/presentation/widgets/morphological_derivation_tree_view.dart) ودمجها كتبويب رابع في [RootStudyScreen](file:///c:/Users/Atiah/myworks/quranapp/lib/features/root_study/presentation/screens/root_study_screen.dart) لفرز مشتقات الأفعال والأسماء والمصادر مع فلترة الآيات باللمس.

5. **التدقيق الصرفي والمعجمي الجماعي (Batch Morphology Auditing)**:
   - بناء لوحة التدقيق الإحصائية [MorphologyAuditScreen](file:///c:/Users/Atiah/myworks/quranapp/lib/features/vocabulary/presentation/screens/morphology_audit_screen.dart) ومستودعها [MorphologyAuditRepositoryImpl](file:///c:/Users/Atiah/myworks/quranapp/lib/features/vocabulary/data/repositories/morphology_audit_repository_impl.dart).
   - توفير مؤشرات KPI لنسب تغطية الجذور والصرف على مستوى 77,794 كلمة، ونظام تحديد متعدد (Multi-Select) وشريط إجراءات عائم لتنفيذ **الربط الجماعي (Batch Relink)** لكافة الكلمات المحددة بجذر موحد دفعة واحدة.
   - تسجيل المسار `/morphology-audit` في [appRouter](file:///c:/Users/Atiah/myworks/quranapp/lib/app/router.dart).

6. **سلامة الجودة والاختبارات**:
   - كتابة اختبارات تكامل ووحدة شاملة في [lexicon_and_morphology_features_test.dart](file:///c:/Users/Atiah/myworks/quranapp/test/lexicon_and_morphology_features_test.dart).
   - اجتياز 107 اختبارات آلية بنسبة 100% بدون أي أخطاء أو تحذيرات (`dart analyze: 0 issues`).

---

## الخطوات المستقبلية المقترحة للمرحلة القادمة (Next Workflow: `next_step_audio_recitations_and_tafseer`)
1. **نظام التلاوات الصوتية دون إنترنت والتحميل المسبق (Audio Recitations & Offline Audio)**:
   - دعم الاستماع للآيات مع التظليل المتزامن (Word-by-word / Ayah synchronization) وإدارة الملفات الصوتية محلياً.
2. **المعجم التفسيري المدمج (Integrated Quranic Tafseer & Dictionaries)**:
   - ربط تفاسير موثوقة (الميسر، ابن كثير، السعدي) وغريب القرآن مع إمكانية استعراضها أثناء القراءة والبحث والدراسة.
3. **الحفظ والمراجعة التكرارية الذكية (Spaced Repetition Memorization Mode)**:
   - وضع مخصص للحفظ والمراجعة مع إخفاء الكلمات تدريجياً وإحصاءات الإتقان اليومي.
