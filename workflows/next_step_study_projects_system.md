# خطة العمل للمرحلة القادمة: نظام مشاريع الدراسة القرآنية المتكامل (Study Projects System)

## اسم التدفق
`next_step_study_projects_system`

---

## 🎯 الهدف العام (Objective)
إنشاء نظام إدارة وبحث متقدم يتيح للباحثين والدارسين فتح مشاريع دراسة قرآنية مستقلة ومنهجية داخل التطبيق، مصنفة إلى ثلاثة أنماط رئيسية تلبي كافة الأسئلة المعجمية والتفسيرية والمفاهيمية وفق معايير TRD وClean Architecture.

---

## 📊 أنواع مشاريع الدراسة ومحاورها التحليلية (Project Types)

### 1. مشروع دراسة الجذر اللغوي (Root Study Project)
- **نوع الجذر**: ثنائي، ثلاثي، رباعي، خماسي (مع ميزة الاكتشاف والاحتساب الآلي).
- **أحرف العلة**: هل يحتوي على حروف علة؟ كم عددها؟ وما هي؟ (استنتاج وتحليل آلي).
- **التطابقات في اللغات السامية والأجنبية**: سريانية، آرامية، عبرية، حبشية، إنجليزية... إلخ.
- **أقدم استخدام مرصود للجذر**: هل ورد في النقوش واللغة العربية قبل القرآن، أم هو نتاج وإثراء قرآني؟
- **الاستخدام المعاصر**: هل ما زال الجذر متداولاً في الاستعمال المعاصر اليوم؟
- **الدلالة اللغوية**: مادية، معنوية، تجريدية، مشتركة.
- **المعنى المرادف والمعنى المضاد**.
- **رأي الباحث وملاحظاته وخلاصاته**.
- **قائمة الاشتقاقات والمفردات القرآنية** (ربط تفاعلي مباشر بجدول `words`).

### 2. مشروع دراسة الآيات القرآنية (Ayah Study Project)
- **موضوع الآية**: المحور العام وعن ماذا تتحدث.
- **التفسير من الموروث**: خلاصة أمهات كتب التفسير المعتمدة.
- **زمن ومناسبات وسبب النزول**: مكي/مدني، ترتيب النزول، وأسباب النزول الموثقة.
- **التقاطعات والآيات المفسرة**: علاقتها بآيات أخرى، الآيات التي تفسرها أو تخصصها.
- **التشابهات في الكتب المقدسة السابقة**: دراسة مقارنة للقصص والنصوص.
- **المفهوم الظاهر من الآية**: الدلالة المباشرة للنص القرآني.
- **طبيعة الدلالة**: دليل على حكم شرعي (فقهي)، أم عقدي، أم أخلاقي، أم سُنني كوني.
- **رأي الباحث وملاحظاته**.
- **قائمة الآيات ذات الصلة** (ربط مباشر وتفاعلي بجدول `ayahs`).

### 3. مشروع دراسة المفاهيم والمواضيع القرآنية (Concepts & Topics Study Project)
- **المفهوم أو المصطلح**: العنوان الأساسي (مثال: الحق، العدل، التربية، التجارة، السعي...).
- **نوع الدلالة**:
  - *معنوي*: يرصد أثره بالمشاعر والوجدان (مثل: الحب، الرحمة، الخوف).
  - *قياسي*: يستخدم للموازنة والقياس (مثل: كبير، صغير، قليل، كثير).
  - *تجريدي*: لا يخضع لقيود الزمكان (مثل: الحق، العلم، الحكمة).
  - *مادي*: يرتبط بالأعيان والمحسوسات (مثل: جبل، شجر، ماء).
  - *فكري*: يرصده العقل والاستنباط (مثل: الأخلاق، العدل، البرهان).
- **المعنى القرآني والمعنى المعاصر**: الفوارق والتطور الدلالي للمفهوم.
- **المفهوم المغاير أو المضاد**: المفهوم المقابل (مثل: الحق / الباطل، العدل / الظلم).
- **العلاقة بالمفاهيم الأخرى**: خريطة المفاهيم القرآنية المترابطة.
- **المعالجة القرآنية والسياق العام**: كيف ناقش القرآن هذا المفهوم من خلال تقاطع الآيات.
- **قائمة الآيات التي تناولته** (ربط تفاعلي مع المصحف).
- **قائمة الجذور والمفردات المعبرة عنه** (ربط مع شبكة المعجم الصرفي).
- **رأي الباحث وملاحظاته وتوصياته**.

---

## 🏗️ التصميم المعماري وقاعدة البيانات (Architecture & Database Schema)

### 1. ترقية قاعدة البيانات (Database Migration v2)
إضافة الجداول التالية داخل SQLite:
```sql
-- 1. جدول المشاريع الأساسي
CREATE TABLE study_projects (
    id INTEGER PRIMARY KEY AUTOINCREMENT,
    title TEXT NOT NULL,
    project_type TEXT NOT NULL CHECK(project_type IN ('root', 'ayah', 'concept')),
    target_identifier TEXT NOT NULL,
    description TEXT,
    created_at TEXT NOT NULL,
    updated_at TEXT NOT NULL,
    status TEXT NOT NULL DEFAULT 'draft' CHECK(status IN ('draft', 'in_progress', 'completed')),
    progress REAL NOT NULL DEFAULT 0.0
);

-- 2. جدول تفاصيل دراسة الجذر
CREATE TABLE root_study_projects (
    project_id INTEGER PRIMARY KEY,
    root_type TEXT,
    has_vowels INTEGER DEFAULT 0,
    vowels_count INTEGER DEFAULT 0,
    vowels_list TEXT,
    cognates_other_languages TEXT,
    oldest_usage TEXT,
    is_used_today INTEGER DEFAULT 1,
    usage_nature TEXT,
    synonyms TEXT,
    antonyms TEXT,
    researcher_notes TEXT,
    FOREIGN KEY (project_id) REFERENCES study_projects(id) ON DELETE CASCADE
);

-- 3. جدول تفاصيل دراسة الآيات
CREATE TABLE ayah_study_projects (
    project_id INTEGER PRIMARY KEY,
    surah_id INTEGER NOT NULL,
    ayah_number INTEGER NOT NULL,
    global_ayah_number INTEGER,
    topic TEXT,
    traditional_tafseer TEXT,
    revelation_context TEXT,
    cross_references TEXT,
    other_scriptures_parallels TEXT,
    apparent_concept TEXT,
    ruling_or_status TEXT,
    researcher_notes TEXT,
    FOREIGN KEY (project_id) REFERENCES study_projects(id) ON DELETE CASCADE
);

-- 4. جدول تفاصيل دراسة المفاهيم
CREATE TABLE concept_study_projects (
    project_id INTEGER PRIMARY KEY,
    term TEXT NOT NULL,
    denotation_type TEXT,
    quranic_vs_contemporary_meaning TEXT,
    opposite_concept TEXT,
    related_concepts TEXT,
    quranic_discourse TEXT,
    researcher_notes TEXT,
    FOREIGN KEY (project_id) REFERENCES study_projects(id) ON DELETE CASCADE
);

-- 5. جدول ربط الآيات التفاعلية بالمشروع
CREATE TABLE study_project_ayahs (
    id INTEGER PRIMARY KEY AUTOINCREMENT,
    project_id INTEGER NOT NULL,
    ayah_id INTEGER NOT NULL,
    note TEXT,
    relation_type TEXT DEFAULT 'related',
    FOREIGN KEY (project_id) REFERENCES study_projects(id) ON DELETE CASCADE,
    FOREIGN KEY (ayah_id) REFERENCES ayahs(id) ON DELETE CASCADE
);

-- 6. جدول ربط الجذور التفاعلية بالمشروع
CREATE TABLE study_project_roots (
    id INTEGER PRIMARY KEY AUTOINCREMENT,
    project_id INTEGER NOT NULL,
    root_normalized TEXT NOT NULL,
    note TEXT,
    FOREIGN KEY (project_id) REFERENCES study_projects(id) ON DELETE CASCADE
);
```

---

## 📱 الواجهات والتجربة التفاعلية (UI/UX)
1. **شاشة مركز مشاريع الدراسة (`StudyProjectsHubScreen`)**:
   - بطاقات إحصائية للمشاريع المفتوحة والمكتملة والمصنفة حسب النوع.
   - زر إجراء عائم `+` لبدء مشروع جديد مع معالج خطوات مرن (Wizard).
   - مرشحات تصفية (الكل، جذور، آيات، مفاهيم) وبحث فوري.
2. **محرر مشروع دراسة الجذر (`RootStudyProjectEditorScreen`)**:
   - حقول إدخال منظمة حسب المحاور مع استنتاج آلي فوري لحروف العلة ونوع الجذر.
   - قائمة تفاعلية للاشتقاقات من جدول `words`.
3. **محرر مشروع دراسة الآية (`AyahStudyProjectEditorScreen`)**:
   - عرض فوري للنص العثماني للآية المختارة ومعلومات السورة.
   - حقول محاور النزول والتفسير والمقارنة مع منتقي الآيات ذات الصلة (`AyahPickerSheet`).
4. **محرر مشروع دراسة المفهوم (`ConceptStudyProjectEditorScreen`)**:
   - اختيار نوع الدلالة مع بطاقات إرشادية وتوضيحية للأثر الدلالي.
   - شبكة إسناد الآيات والجذور المعبرة عن المفهوم.
5. **نقاط الدخول السريعة في أرجاء التطبيق**:
   - زر "فتح مشروع دراسة" من قائمة خيارات أي آية في المصحف.
   - زر "بدء مشروع دراسة" من شاشة دراسة الجذر أو دليل الجذور.
   - إمكانية تصدير الدراسة كتقرير متكامل (Markdown / JSON).

---

## 🧪 خطة الاختبار والتحقق (Testing Plan)
- اختبارات وحدة لترقية قاعدة البيانات والتأكد من القيود والعلاقات `CASCADE`.
- اختبارات مستودعات البيانات `StudyProjectsRepository`.
- اختبارات محرك الاستنتاج الآلي للجذور وأحرف العلة.
- اختبارات واجهات المحررات وحفظ المسودات وحساب نسبة الإنجاز `progress`.
