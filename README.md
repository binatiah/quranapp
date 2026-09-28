# تطبيق مصحف البحث والدراسة (Quran Study App)

تطبيق مصحف إلكتروني احترافي يعمل بالكامل دون اتصال بالإنترنت (Offline-First) مبني باستخدام **Flutter** و **SQLite** ومصمم وفق مبادئ المعمارية النظيفة الموجهة بالخصائص (**Clean Feature-First Architecture**).

---

## 🌟 مميزات التطبيق وأقسامه

### 1. قسم المصحف الشريف (Quran Reader)
- عرض سور القرآن الكريم الـ 114 سورة.
- تلاوة الآيات بالرسم والنص العثماني الأصلي المشكول دون تعديل.
- الانتقال المباشر إلى آية محددة.
- حفظ آخر موضع قراءة للمستخدم واسترجاعه بنقرة واحدة.
- قائمة المفضلة مع إمكانية تدوين الملاحظات والتدبرات.
- نسخ ومشاركة نصوص الآيات.
- التحكم في حجم الخط والتبديل السلس بين الوضع النهاري والوضع الليلي المريح للعين.

### 2. قسم البحث والدراسة المعجمية والصرفية (Quran Search & Study)
- **البحث المباشر**: بحث مطابق للنص بالتشكيل أو بدونه.
- **البحث بالجذر اللغوي**: تحديد الجذور اللغوية الموثقة صرفياً للكلمات.
- **عرض الكلمات المشتقة**: استخراج جميع تصريفات ومشتقات الجذر وتكرار كل كلمة.
- **جلب الآيات بـ JOIN واحد**: استعلام موحد فائق الأداء يربط الكلمات والآيات والسور.
- **ميزة سياق الآية (Context Engine)**:
  - جلب عدد مخصص من الآيات السابقة واللاحقة.
  - قص النطاق عند حدود السورة افتراضياً مع خيار امتداد عالمي.
  - دمج النطاقات المتداخلة أو المتجاورة تلقائياً بدون تكرار الآيات.
  - تمييز الآيات الأصلية المستهدفة والكلمات المطابقة بصرياً.
- **شاشة دراسة الجذر**: تحليل إحصائي للكلمات ومواضع الورود في سور المصحف.

---

## 🏛️ البنية المعمارية المعتمدة (Architecture)

التطبيق يعتمد نمط **Feature-First Clean Architecture**:

```text
Presentation (Widgets & Screens)
        ↓
ViewModel / StateNotifier (Riverpod)
        ↓
Domain Layer (Use Cases & Pure Entities)
        ↓
Data Layer (Repositories & SQLite Pre-populated Database)
```

### 📂 شجرة المجلدات الأساسية

```text
lib/
├── app/
│   ├── app.dart                   # الويدجت الجذر للتطبيق مع التوطين والثيم
│   ├── router.dart                # نظام التوجيه والتنقل الشامل (GoRouter)
│   └── theme/
│       └── app_theme.dart         # الهوية البصرية الإسلامية والألوان الفاتحة والداكنة
├── core/
│   ├── constants/
│   │   └── ui_state.dart          # غلاف حالات الواجهة (Initial, Loading, Success, Empty, Error)
│   ├── database/                  # خدمات SQLite وإدارة الهجرة والأصول
│   └── text/                      # معالج النصوص والمطبع العربي ArabicNormalizer
└── features/
    ├── home/                      # الشاشة الرئيسية وأقسام التبديل
    ├── quran_reader/              # عارض المصحف وقائمة السور
    ├── quran_search/              # محرك البحث المباشر والصرفي وسياق الآيات
    ├── root_study/                # شاشة دراسة الجذر وإحصاءات المشتقات
    ├── bookmarks/                 # إدارة المفضلة والتدبرات
    └── settings/                  # إعدادات المظهر وحجم الخط والترخيص
```

---

## 📊 الكيانات البرمجية الأساسية (Domain Entities)

- [Surah](file:///c:/Users/Atiah/myworks/quranapp/lib/features/quran_reader/domain/entities/surah.dart): تمثيل السورة وبياناتها التنزيلية.
- [Ayah](file:///c:/Users/Atiah/myworks/quranapp/lib/features/quran_reader/domain/entities/ayah.dart): تمثيل الآية القرآنية بنصوصها (عثماني، مبسط، مطبّع).
- [QuranWord](file:///c:/Users/Atiah/myworks/quranapp/lib/features/quran_search/domain/entities/quran_word.dart): الكلمة وموقعها وبياناتها الصرفية (Lemma, Root, Part of Speech).
- [QuranRoot](file:///c:/Users/Atiah/myworks/quranapp/lib/features/quran_search/domain/entities/quran_root.dart): الجذر اللغوي وإحصاءات وروده ومشتقاته.
- [RootCandidate](file:///c:/Users/Atiah/myworks/quranapp/lib/features/quran_search/domain/entities/root_candidate.dart): ترشيح الجذر ودرجة الثقة ومصدر الاستخراج.
- [AyahSearchResult](file:///c:/Users/Atiah/myworks/quranapp/lib/features/quran_search/domain/entities/ayah_search_result.dart): بطاقة نتيجة البحث الشاملة ومواضع الكلمات المطابقة.
- [AyahRange](file:///c:/Users/Atiah/myworks/quranapp/lib/features/quran_search/domain/entities/ayah_range.dart): نطاق الآيات وخوارزمية دمج النطاقات المتداخلة.
- [AyahContextGroup](file:///c:/Users/Atiah/myworks/quranapp/lib/features/quran_search/domain/entities/ayah_context_group.dart): تجميعة سياق الآيات مع تمييز الآيات الهدف.
- [Bookmark](file:///c:/Users/Atiah/myworks/quranapp/lib/features/bookmarks/domain/entities/bookmark.dart): العلامات المرجعية والملاحظات.
- [ReadingPosition](file:///c:/Users/Atiah/myworks/quranapp/lib/features/quran_reader/domain/entities/reading_position.dart): حفظ آخر موضع قراءة.

---

## 🚀 ما تم إنجازه في المرحلة 1 (Phase 1 Status)

- [x] تهيئة البنية المعمارية وتثبيت كافة الحزم المتوافقة مع Flutter 3.41 و Dart 3.11.
- [x] إعداد نظام التوجيه [appRouter](file:///c:/Users/Atiah/myworks/quranapp/lib/app/router.dart) لربط كافة الشاشات الـ 9.
- [x] إعداد نظام الهوية البصرية والثيم [AppTheme](file:///c:/Users/Atiah/myworks/quranapp/lib/app/theme/app_theme.dart) للوضعين الفاتح والداكن.
- [x] دعم اللغة العربية افتراضياً مع نمط الكتابة من اليمين لليسار (RTL) والتجهيز للتعدد اللغوي.
- [x] بناء وتوثيق كافة كيانات النطاق الأساسية (Domain Entities) ونظام حالات الواجهة الموحد [UIState](file:///c:/Users/Atiah/myworks/quranapp/lib/core/constants/ui_state.dart).
- [x] اجتياز التحليل البرمجي `flutter analyze` بنتيجة **0 issues**.
- [x] اجتياز كافة الاختبارات `flutter test` بنجاح (12 اختبار وحدة وتكامل).

---

## 🛠️ أوامر التشغيل والاختبار

```bash
# تثبيت الحزم
flutter pub get

# فحص سلامة وجودة الكود
flutter analyze

# تشغيل الاختبارات الآلية
flutter test

# تشغيل التطبيق
flutter run
```
