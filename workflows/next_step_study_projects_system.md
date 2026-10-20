# نظام مشاريع الدراسة القرآنية المتكامل (Study Projects System)

## اسم التدفق
`next_step_study_projects_system`

## ملخص ما تم إنجازه بالكامل في هذا التدفق (Completed Steps)

1. **ترقية قاعدة البيانات (Database Migration v2)**:
   - ترقية إصدار قاعدة البيانات إلى 2 في [database_migrations.dart](file:///c:/Users/Atiah/myworks/quranapp/lib/core/database/database_migrations.dart).
   - إنشاء 6 جداول أساسية متصلة مع قيود التكامل والحذف المتتالي (`ON DELETE CASCADE`):
     - `study_projects`: جدول المشاريع الرئيسي وحالة التقدم والنمط.
     - `root_study_projects`: تفاصيل دراسة الجذور اللغوية.
     - `ayah_study_projects`: تفاصيل دراسة الآيات القرآنية.
     - `concept_study_projects`: تفاصيل دراسة المفاهيم والمواضيع.
     - `study_project_ayahs`: روابط الآيات والشواهد المفسرة والنظائر.
     - `study_project_roots`: روابط الجذور المعبرة عن المفاهيم.
   - إنشاء 4 فهارس لتسريع البحث والتصفية بحسب النمط وتاريخ التحديث والروابط.

2. **طبقة الكيانات ونماذج النطاق (Domain Entities)**:
   - إنشاء [StudyProject](file:///c:/Users/Atiah/myworks/quranapp/lib/features/study_projects/domain/entities/study_project.dart) بأنماطه الثلاثة (`root`، `ayah`، `concept`) وحالاته الثلاث (`draft`، `inProgress`، `completed`).
   - إنشاء [RootStudyDetails](file:///c:/Users/Atiah/myworks/quranapp/lib/features/study_projects/domain/entities/root_study_details.dart) للإجابة المنهجية على أسئلة الجذر (نوع الجذر، أحرف العلة وعددها، اللغات الأخرى، أقدم استخدام، المعاصرة، الدلالة، المترادفات، الأضداد، رأي الباحث).
   - إنشاء [AyahStudyDetails](file:///c:/Users/Atiah/myworks/quranapp/lib/features/study_projects/domain/entities/ayah_study_details.dart) للإجابة على محاور الآية (الموضوع، التفسير الموروث، زمن وسبب النزول، التقاطعات والآيات المفسرة، الكتب المقدسة، المفهوم الظاهر، الحكم الشرعي، رأي الباحث).
   - إنشاء [ConceptStudyDetails](file:///c:/Users/Atiah/myworks/quranapp/lib/features/study_projects/domain/entities/concept_study_details.dart) لتصنيف الدلالة الخمسية (معنوي، قياسي، تجريدي، مادي، فكري) والمقارنة المعاصرة، الأضداد، السياق العام، ورأي الباحث.
   - إنشاء كيانات الروابط المرجعية [StudyProjectAyahLink](file:///c:/Users/Atiah/myworks/quranapp/lib/features/study_projects/domain/entities/study_project_ayah_link.dart) و [StudyProjectRootLink](file:///c:/Users/Atiah/myworks/quranapp/lib/features/study_projects/domain/entities/study_project_root_link.dart) والكيان الشامل [StudyProjectFull](file:///c:/Users/Atiah/myworks/quranapp/lib/features/study_projects/domain/entities/study_project_full.dart).

3. **خدمة التحليل والاستنتاج الآلي (StudyProjectAnalyzerService)**:
   - إنشاء [StudyProjectAnalyzerService](file:///c:/Users/Atiah/myworks/quranapp/lib/features/study_projects/domain/services/study_project_analyzer_service.dart) لاكتشاف نوع الجذر آلياً (ثنائي/ثلاثي/رباعي/خماسي)، وحصر أحرف العلة وتحديدها.
   - احتساب نسبة اكتمال محاور الدراسة آلياً (`progress` من 0.0 إلى 1.0) وتحديث حالة المشروع تلقائياً.
   - تصدير التقرير النهائي بصيغة **Markdown** منسقة بدقة واحترافية وبصيغة **JSON**.

4. **مستودع البيانات والتطبيق العملي (Repository & Implementation)**:
   - إنشاء واجهة المستودع [StudyProjectsRepository](file:///c:/Users/Atiah/myworks/quranapp/lib/features/study_projects/domain/repositories/study_projects_repository.dart).
   - تطبيق المستودع [StudyProjectsRepositoryImpl](file:///c:/Users/Atiah/myworks/quranapp/lib/features/study_projects/data/repositories/study_projects_repository_impl.dart) بمعاملات SQLite الآمنة و parameterized queries لجلب الإحصاءات وربط الآيات والجذور.

5. **إدارة الحالة وموفرو Riverpod**:
   - إنشاء [study_projects_providers.dart](file:///c:/Users/Atiah/myworks/quranapp/lib/features/study_projects/presentation/controllers/study_projects_providers.dart) مع موفرات القائمة، الفلترة المتعددة، إحصاءات KPI، وتفاصيل المشروع الفردي.

6. **شاشات الواجهة والتجربة التفاعلية (UI/UX)**:
   - إنشاء شاشة مركز المشاريع [StudyProjectsHubScreen](file:///c:/Users/Atiah/myworks/quranapp/lib/features/study_projects/presentation/screens/study_projects_hub_screen.dart) مع مؤشرات KPI، الفرز والتصفية والبحث.
   - حوار إنشاء المشروع الذكي [CreateStudyProjectDialog](file:///c:/Users/Atiah/myworks/quranapp/lib/features/study_projects/presentation/widgets/create_study_project_dialog.dart) بالاستنتاج التلقائي.
   - شاشة محرر مشروع دراسة الجذر [RootStudyProjectScreen](file:///c:/Users/Atiah/myworks/quranapp/lib/features/study_projects/presentation/screens/root_study_project_screen.dart).
   - شاشة محرر مشروع دراسة الآية [AyahStudyProjectScreen](file:///c:/Users/Atiah/myworks/quranapp/lib/features/study_projects/presentation/screens/ayah_study_project_screen.dart) مع عرض الآية بالرسم العثماني.
   - شاشة محرر مشروع دراسة المفهوم [ConceptStudyProjectScreen](file:///c:/Users/Atiah/myworks/quranapp/lib/features/study_projects/presentation/screens/concept_study_project_screen.dart) مع محدد الدلالة الخمسية التفاعلي.
   - حوارات إسناد الآيات والجذور [AddAyahLinkDialog](file:///c:/Users/Atiah/myworks/quranapp/lib/features/study_projects/presentation/widgets/add_ayah_link_dialog.dart) و [AddRootLinkDialog](file:///c:/Users/Atiah/myworks/quranapp/lib/features/study_projects/presentation/widgets/add_root_link_dialog.dart).

7. **نقاط التكامل عبر أرجاء التطبيق**:
   - إضافة بطاقة مركز المشاريع في الشاشة الرئيسية [HomeScreen](file:///c:/Users/Atiah/myworks/quranapp/lib/features/home/presentation/screens/home_screen.dart).
   - إضافة زر "فتح مشروع دراسة لهذا الجذر" في [RootStudyScreen](file:///c:/Users/Atiah/myworks/quranapp/lib/features/root_study/presentation/screens/root_study_screen.dart).
   - إضافة زر "فتح مشروع دراسة لهذه الآية" في كل بطاقة آية في [QuranReaderScreen](file:///c:/Users/Atiah/myworks/quranapp/lib/features/quran_reader/presentation/screens/quran_reader_screen.dart).
   - تسجيل المسارات الأربعة في [appRouter](file:///c:/Users/Atiah/myworks/quranapp/lib/app/router.dart).

8. **الاختبارات الآلية الشاملة**:
   - إنشاء [study_projects_system_test.dart](file:///c:/Users/Atiah/myworks/quranapp/test/study_projects_system_test.dart) وفحص التحليل، الحفظ، الربط، والتصفيات، والحذف المتتالي.
   - اجتياز جميع اختبارات المشروع (116 اختباراً آلياً بنسبة 100%) و 0 أخطاء في `dart analyze`.

---

## الخطوات المستقبلية المقترحة للمرحلة القادمة (Next Workflow: `next_step_audio_recitations_and_tafseer`)
1. **نظام التلاوات الصوتية دون إنترنت والتحميل المسبق (Audio Recitations & Offline Audio)**:
   - دعم الاستماع للآيات مع التظليل المتزامن (Word-by-word / Ayah synchronization) وإدارة الملفات محلياً.
2. **المعجم التفسيري المدمج (Integrated Quranic Tafseer & Dictionaries)**:
   - ربط تفاسير موثوقة (الميسر، ابن كثير، السعدي) وإتاحة الاستفادة منها مباشرة داخل مشاريع الدراسة.
