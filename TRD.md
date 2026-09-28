سأحوّل فكرتك إلى وثيقة متطلبات عملية وموجّه شامل يمكن تسليمه مباشرة إلى وكيل ذكاء اصطناعي داخل IDE لبناء التطبيق مرحلة بمرحلة. وسأصحح آلية البحث بحيث تعتمد على بيانات الجذور الصرفية الموثوقة أولًا، مع استخدام مطابقة الحروف المرتبة كخيار احتياطي فقط، لأن الاعتماد عليها وحدها قد ينتج كلمات غير منتمية فعليًا إلى الجذر.

1. ملخص المشروع
اسم مبدئي

Quran Study App

تطبيق مصحف إلكتروني يعمل دون اتصال بالإنترنت باستخدام:

Flutter لبناء تطبيق Android وiOS.
SQLite لتخزين السور والآيات والكلمات والجذور والفهارس.
واجهة عربية RTL.
بنية قابلة لإضافة الإنجليزية والترجمات والتفاسير مستقبلًا.

استخدام SQLite مناسب هنا لأن التطبيق يحتاج إلى تخزين واستعلام كمية منظمة من البيانات محليًا، كما توصي وثائق Flutter بفصل واجهة المستخدم عن طبقة البيانات والمستودعات والخدمات لتسهيل الاختبار والصيانة.

1. أقسام التطبيق الرئيسية

يتكون التطبيق من قسمين أساسيين:

القسم الأول: المصحف التقليدي

يحتوي على:

قائمة السور.
عرض آيات السورة.
الانتقال إلى آية محددة.
عرض اسم السورة ورقمها ومكان نزولها وعدد آياتها.
دعم النص العثماني.
دعم التمرير المستمر.
حفظ آخر موضع قراءة.
إضافة الآيات إلى المفضلة.
نسخ الآية ومشاركتها.
تغيير حجم الخط.
الوضع الليلي.
الانتقال إلى صفحة أو جزء أو حزب مستقبلًا.
القسم الثاني: البحث والدراسة

يحتوي على:

البحث بالكلمة كما كُتبت.
البحث بالكلمة دون تشكيل.
البحث بالجذر.
عرض الكلمات القرآنية المرتبطة بالجذر.
عرض الآيات التي تحتوي تلك الكلمات.
عرض سياق الآية، أي الآيات السابقة واللاحقة.
تصفية النتائج حسب السورة.
إظهار الكلمة المطابقة داخل الآية بلون مميز.
عرض سبب ظهور النتيجة:
مطابقة مباشرة.
مطابقة بعد إزالة التشكيل.
مطابقة بالجذر.
مطابقة تقريبية بالحروف المرتبة.
إمكانية دراسة كل جذر وإظهار:
الجذر.
الكلمات المرتبطة به.
عدد مرات ورود كل كلمة.
السور التي ورد فيها.
جميع مواضع الورود.
3. ملاحظة مهمة حول استخراج الجذر
المشكلة في استخراج الجذر برمجيًا

تحويل كلمات مثل:

يفعلون ← فعل
المفلحين ← فلح
يستغفرون ← غفر

ليس مجرد حذف:

أل التعريف.
حروف الجمع.
حروف المضارعة.
اللواحق والضمائر.

فاللغة العربية تحتوي على:

جذور ثلاثية ورباعية.
حروف علة.
إعلال وإبدال.
همزات.
تضعيف.
كلمات لها الحروف نفسها ولكن جذورها مختلفة.
كلمات قد تحتمل أكثر من تحليل صرفي بحسب السياق.

لذلك يجب ألا تكون دالة حذف السوابق واللواحق هي المصدر النهائي لتحديد الجذر.

الحل الموصى به

استخدم ثلاث طبقات:

المستوى الأول: الجذر المخزن مسبقًا

يجب أن يحتوي جدول كلمات القرآن على الجذر الصحيح لكل كلمة:

surface_word: يَفْعَلُونَ
normalized_word: يفعلون
lemma: فعل
root: فعل

ويكون البحث الأساسي:

SELECT *
FROM words
WHERE root_normalized = ?;

يمكن الاعتماد على مصدر بيانات صرفية متخصص مثل Quranic Arabic Corpus، الذي يوفر تحليلًا صرفيًا ونحويًا لكلمات القرآن. يجب الالتزام بشروط ترخيص المصدر وإظهار نسب البيانات إليه داخل التطبيق.

المستوى الثاني: قاموس الكلمات

إذا لم توجد الكلمة نفسها، يبحث التطبيق في قاموس محلي يحتوي على:

normalized_word → root

مثال:

يفعلون      → فعل
فاعلون      → فعل
المفلحين    → فلح
يستغفرون    → غفر

المستوى الثالث: التخمين بالحروف المرتبة

يستخدم فقط عندما لا توجد نتيجة مباشرة أو جذر معروف.

يجب تسمية نتائجه داخل الواجهة:

نتائج مقترحة تحتاج إلى مراجعة

ولا تُعرض باعتبارها نتائج صرفية مؤكدة.

1. قاعدة البيانات المقترحة
4.1 جدول السور surahs
CREATE TABLE surahs (
    id INTEGER PRIMARY KEY,
    name_arabic TEXT NOT NULL,
    name_english TEXT,
    revelation_type TEXT,
    ayah_count INTEGER NOT NULL,
    revelation_order INTEGER,
    start_page INTEGER
);

4.2 جدول الآيات ayahs
CREATE TABLE ayahs (
    id INTEGER PRIMARY KEY,
    surah_id INTEGER NOT NULL,
    ayah_number INTEGER NOT NULL,
    global_ayah_number INTEGER NOT NULL,
    page_number INTEGER,
    juz_number INTEGER,
    hizb_number INTEGER,
    text_uthmani TEXT NOT NULL,
    text_simple TEXT NOT NULL,
    text_normalized TEXT NOT NULL,
    FOREIGN KEY (surah_id) REFERENCES surahs(id),
    UNIQUE (surah_id, ayah_number)
);

الفرق بين الحقول:

text_uthmani: النص المعروض للمستخدم.
text_simple: نص مبسط عند الحاجة.
text_normalized: نص منزوع التشكيل ومهيأ للبحث.
4.3 جدول كلمات القرآن words
CREATE TABLE words (
    id INTEGER PRIMARY KEY,
    ayah_id INTEGER NOT NULL,
    surah_id INTEGER NOT NULL,
    ayah_number INTEGER NOT NULL,
    word_position INTEGER NOT NULL,
    word_uthmani TEXT NOT NULL,
    word_simple TEXT NOT NULL,
    word_normalized TEXT NOT NULL,
    lemma TEXT,
    lemma_normalized TEXT,
    root TEXT,
    root_normalized TEXT,
    prefix TEXT,
    stem TEXT,
    suffix TEXT,
    part_of_speech TEXT,
    morphology TEXT,
    FOREIGN KEY (ayah_id) REFERENCES ayahs(id)
);

4.4 جدول الجذور roots
CREATE TABLE roots (
    id INTEGER PRIMARY KEY,
    root TEXT NOT NULL,
    root_normalized TEXT NOT NULL UNIQUE,
    description_ar TEXT
);

4.5 جدول ربط الكلمات بالجذور

إذا كانت بعض الكلمات تحتمل أكثر من تحليل:

CREATE TABLE word_roots (
    word_id INTEGER NOT NULL,
    root_id INTEGER NOT NULL,
    confidence REAL DEFAULT 1.0,
    is_primary INTEGER DEFAULT 1,
    source TEXT,
    PRIMARY KEY (word_id, root_id),
    FOREIGN KEY (word_id) REFERENCES words(id),
    FOREIGN KEY (root_id) REFERENCES roots(id)
);

4.6 جدول المفضلة
CREATE TABLE bookmarks (
    id INTEGER PRIMARY KEY AUTOINCREMENT,
    ayah_id INTEGER NOT NULL,
    note TEXT,
    created_at TEXT NOT NULL,
    FOREIGN KEY (ayah_id) REFERENCES ayahs(id)
);

4.7 جدول آخر موضع قراءة
CREATE TABLE reading_positions (
    id INTEGER PRIMARY KEY CHECK (id = 1),
    surah_id INTEGER NOT NULL,
    ayah_number INTEGER NOT NULL,
    updated_at TEXT NOT NULL
);

1. الفهارس المطلوبة
CREATE INDEX idx_ayahs_surah_number
ON ayahs(surah_id, ayah_number);

CREATE INDEX idx_ayahs_global
ON ayahs(global_ayah_number);

CREATE INDEX idx_words_ayah
ON words(ayah_id);

CREATE INDEX idx_words_normalized
ON words(word_normalized);

CREATE INDEX idx_words_root
ON words(root_normalized);

CREATE INDEX idx_words_lemma
ON words(lemma_normalized);

CREATE INDEX idx_words_surah_ayah
ON words(surah_id, ayah_number);

CREATE INDEX idx_words_root_ayah
ON words(root_normalized, ayah_id);

وجود فهرس مباشر على root_normalized سيجعل البحث أدق وأسرع بكثير من تنفيذ عدة شروط LIKE '%حرف%'.

1. تطبيع النص العربي

يجب إنشاء خدمة مستقلة باسم:

ArabicNormalizer

وتكون مسؤولة عن:

إزالة التشكيل.
إزالة علامة التطويل ـ.
توحيد صور الألف عند البحث:
أ
إ
آ
ٱ
ا
التعامل مع الألف المقصورة والياء بحسب سياسة واضحة.
التعامل مع الهمزة على الواو والياء عند البحث التقريبي فقط.
إزالة المسافات الزائدة.
إزالة علامات الوقف القرآنية من نسخة البحث.
عدم تعديل النص العثماني الأصلي.
حفظ نسخة normalized مستقلة بدل تعديل النص المعروض.

مثال دالة:

abstract interface class ArabicNormalizer {
  String normalizeForExactSearch(String input);

  String normalizeForRootSearch(String input);

  String removeDiacritics(String input);

  List<String> tokenize(String input);
}

سياسة التطبيع المقترحة
ٱلْحَمْدُ ← الحمد
إِنَّا     ← انا
يَفْعَلُونَ ← يفعلون

لكن يجب عدم استخدام نسخة التطبيع لعرض الآيات، بل للبحث فقط.

1. مسار البحث المقترح
المرحلة الأولى: تجهيز عبارة البحث

مدخل المستخدم:

يَفْعَلُونَ

بعد التطبيع:

يفعلون

الخطوات:

تنظيف المدخل.
إزالة التشكيل.
تقسيم العبارة إلى كلمات.
منع البحث إذا كان المدخل فارغًا.
التحقق من طول الكلمة.
البحث عن الكلمة مباشرة.
استخراج الجذور المحتملة من قاعدة البيانات.
عرض الجذر للمستخدم مع إمكانية تغييره.
المرحلة الثانية: تحديد الجذر

الترتيب:

1. مطابقة word_normalized
2. مطابقة lemma_normalized
3. مطابقة root_normalized إذا أدخل المستخدم جذرًا
4. قاموس محلي
5. محلل صرفي مبسط
6. تخمين بالحروف المرتبة

مثال:

SELECT DISTINCT
    root_normalized,
    lemma_normalized
FROM words
WHERE word_normalized = ?
   OR lemma_normalized = ?;

إذا ظهرت عدة جذور، يعرض التطبيق مربع اختيار:

اختر الجذر المقصود:
○ فعل
○ فوع

المرحلة الثالثة: استخراج الكلمات المفتاحية
SELECT
    word_normalized,
    MIN(word_uthmani) AS display_word,
    COUNT(*) AS occurrence_count
FROM words
WHERE root_normalized = ?
GROUP BY word_normalized
ORDER BY occurrence_count DESC, word_normalized;

مثال النتيجة:

فعل
يفعلون
فاعلون
المفعلين

يجب ألا تعتمد هذه المرحلة على تنفيذ استعلام مستقل لكل كلمة.

المرحلة الرابعة: جلب الآيات

الأفضل تنفيذ JOIN واحد:

SELECT DISTINCT
    a.id,
    a.surah_id,
    a.ayah_number,
    a.global_ayah_number,
    a.text_uthmani,
    a.text_normalized,
    s.name_arabic
FROM ayahs AS a
INNER JOIN surahs AS s
    ON s.id = a.surah_id
INNER JOIN words AS w
    ON w.ayah_id = a.id
WHERE w.root_normalized = ?
ORDER BY a.global_ayah_number;

ولعرض الكلمات المطابقة في كل آية:

SELECT
    a.id AS ayah_id,
    a.surah_id,
    a.ayah_number,
    a.global_ayah_number,
    a.text_uthmani,
    s.name_arabic,
    GROUP_CONCAT(DISTINCT w.word_uthmani) AS matched_words
FROM ayahs AS a
INNER JOIN surahs AS s
    ON s.id = a.surah_id
INNER JOIN words AS w
    ON w.ayah_id = a.id
WHERE w.root_normalized = ?
GROUP BY
    a.id,
    a.surah_id,
    a.ayah_number,
    a.global_ayah_number,
    a.text_uthmani,
    s.name_arabic
ORDER BY a.global_ayah_number;

1. تصحيح البحث بالحروف المرتبة

الاستعلام المقترح في فكرتك يواجه مشكلتين:

instr يعيد أول موضع للحرف فقط.
قد يعطي نتائج غير صحيحة عند تكرار الحرف.
قد يجد كلمة تحتوي الحروف بالترتيب لكنها لا تنتمي إلى الجذر.
شروط %حرف% لا تستفيد بكفاءة من الفهارس التقليدية.
بناء SQL ديناميكي من إدخال المستخدم قد يفتح مجالًا للأخطاء إذا لم تستخدم معاملات parameterized queries.
حل لحروف جذر ثلاثي
SELECT DISTINCT
    word_normalized,
    word_uthmani
FROM words
WHERE instr(word_normalized, ?) > 0
  AND instr(
        substr(
            word_normalized,
            instr(word_normalized, ?) + 1
        ),
        ?
      ) > 0
  AND instr(
        substr(
            word_normalized,
            instr(word_normalized, ?) +
            instr(
                substr(
                    word_normalized,
                    instr(word_normalized, ?) + 1
                ),
                ?
            ) + 1
        ),
        ?
      ) > 0;

لكن هذا الاستعلام معقد، لذلك الأفضل إنشاء دالة Dart:

bool containsCharactersInOrder({
  required String word,
  required String root,
}) {
  var searchFrom = 0;

  for (final character in root.runes) {
    final char = String.fromCharCode(character);
    final position = word.indexOf(char, searchFrom);

    if (position == -1) {
      return false;
    }

    searchFrom = position + char.length;
  }

  return true;
}

الاستخدام الصحيح
جلب قائمة مرشحين محدودة من SQLite.
فحص ترتيب الحروف في Dart.
تصنيفها كاقتراحات.
عدم خلطها بنتائج الجذر الموثقة.
9. البحث النصي باستخدام FTS5

يمكن إنشاء فهرس بحث نصي للآيات:

CREATE VIRTUAL TABLE ayahs_fts USING fts5(
    text_normalized,
    content='ayahs',
    content_rowid='id'
);

ثم:

SELECT
    a.*
FROM ayahs_fts AS f
INNER JOIN ayahs AS a
    ON a.id = f.rowid
WHERE ayahs_fts MATCH ?;

FTS5 هو محرك بحث نصي داخل SQLite ويدعم البحث في مجموعات نصية، والعبارات، والبادئات، والعوامل المنطقية، ودوال مثل تمييز أجزاء النتائج.

توجد أيضًا إضافة Flutter مخصصة لتطبيع التشكيل العربي داخل FTS5، لكنها ينبغي تقييمها جيدًا من حيث الاعتمادية ودعم المنصات قبل جعلها جزءًا أساسيًا من التطبيق.

ملاحظة

FTS5 مناسب من أجل:

البحث النصي المباشر.
البحث عن عبارة.
البحث دون تشكيل.
إيجاد الآيات التي تحتوي عدة كلمات.

لكنه لا يستبدل جدول الجذور والتحليل الصرفي.

 1. البحث المتقدم بسياق الآية
متطلبات الواجهة

أضف حقلين رقميين:

عدد الآيات السابقة: 5
عدد الآيات اللاحقة: 4

مع القيم الافتراضية:

السابق: 0
اللاحق: 0

والحد الأقصى المقترح:

20 آية سابقة
20 آية لاحقة

الاستعلام داخل السورة نفسها

إذا كانت النتيجة سورة معينة وآية رقم 20، والسابق 5 واللاحق 4:

البداية = 15
النهاية = 24

الاستعلام:

SELECT *
FROM ayahs
WHERE surah_id = ?
  AND ayah_number BETWEEN
      MAX(1, ? - ?)
      AND
      MIN(
          (SELECT ayah_count FROM surahs WHERE id = ?),
          ? + ?
      )
ORDER BY ayah_number;

المعاملات:

surahId
ayahNumber
beforeCount
surahId
ayahNumber
afterCount

السلوك الافتراضي الموصى به

لا ينتقل السياق من نهاية سورة إلى بداية سورة أخرى.

مثال:

نتيجة البحث في الآية 2.
السابق = 5.
يبدأ السياق من الآية 1.
لا يجلب آيات من السورة السابقة.
وضع اختياري

يمكن إضافة خيار:

☐ السماح بامتداد السياق بين السور

عند تفعيله يستخدم التطبيق global_ayah_number.

SELECT *
FROM ayahs
WHERE global_ayah_number BETWEEN ? AND ?
ORDER BY global_ayah_number;

 1. تجميع السياقات المتداخلة

إذا ظهرت نتائج في الآيات:

20، 22، 23

وكان السياق:

5 قبل، 4 بعد

ستكون النطاقات:

15 إلى 24
17 إلى 26
18 إلى 27

لا ينبغي عرض الآيات ثلاث مرات.

يجب دمجها في نطاق واحد:

15 إلى 27

أنشئ كلاس:

class AyahRange {
  final int surahId;
  final int startAyah;
  final int endAyah;

  const AyahRange({
    required this.surahId,
    required this.startAyah,
    required this.endAyah,
  });
}

ثم أنشئ خدمة:

AyahRangeMerger

مسؤوليتها:

ترتيب النطاقات.
دمج النطاقات المتداخلة.
دمج النطاقات المتجاورة.
عدم دمج نطاقات سور مختلفة.
الاحتفاظ بأرقام الآيات التي كانت نتائج بحث أصلية لتمييزها.
12. تصميم بطاقة نتيجة البحث

كل بطاقة تعرض:

سورة البقرة، الآية 20

نص الآية العثماني...

الكلمات المطابقة:
يفعلون، فاعلون

الجذر:
فعل

نوع المطابقة:
مطابقة صرفية موثقة

الأزرار:

عرض السياق.
فتح في المصحف.
نسخ.
مشاركة.
إضافة إلى المفضلة.
إضافة ملاحظة.
عرض كلمات الجذر.

عند فتح السياق:

الآية السابقة
الآية السابقة
الآية المطابقة بلون مميز
الآية اللاحقة
الآية اللاحقة

 1. البنية المعمارية المقترحة

استخدم بنية Feature-first مع فصل الطبقات:

lib/
├── app/
│   ├── app.dart
│   ├── router.dart
│   └── theme/
├── core/
│   ├── database/
│   ├── errors/
│   ├── extensions/
│   ├── localization/
│   ├── text/
│   └── widgets/
├── features/
│   ├── quran_reader/
│   │   ├── data/
│   │   ├── domain/
│   │   └── presentation/
│   ├── quran_search/
│   │   ├── data/
│   │   ├── domain/
│   │   └── presentation/
│   ├── root_study/
│   │   ├── data/
│   │   ├── domain/
│   │   └── presentation/
│   ├── bookmarks/
│   └── settings/
└── main.dart

وتكون المسؤوليات:

Presentation → ViewModel/Notifier → Use Case → Repository → SQLite

هذا يتوافق مع المبادئ المعمارية الموصى بها في Flutter، والتي تفصل Views وViewModels عن Repositories وServices، مع إضافة Domain Layer عندما توجد قواعد عمل معقدة.

 1. الخدمات الأساسية

أنشئ الواجهات التالية:

abstract interface class QuranRepository {
  Future<List<Surah>> getSurahs();

  Future<List<Ayah>> getSurahAyahs(int surahId);

  Future<Ayah?> getAyah(int surahId, int ayahNumber);

  Future<List<Ayah>> getAyahRange({
    required int surahId,
    required int startAyah,
    required int endAyah,
  });
}

abstract interface class QuranSearchRepository {
  Future<List<RootCandidate>> resolveRoots(String query);

  Future<List<QuranWord>> getWordsByRoot(String root);

  Future<List<AyahSearchResult>> searchAyahsByRoot(String root);

  Future<List<AyahSearchResult>> searchExactWord(String word);

  Future<List<AyahSearchResult>> searchText(String query);
}

abstract interface class RootResolver {
  Future<List<RootCandidate>> resolve(String normalizedWord);
}

abstract interface class SearchContextService {
  Future<List<AyahContextGroup>> loadContext({
    required List<AyahSearchResult> results,
    required int beforeCount,
    required int afterCount,
  });
}

 1. نماذج البيانات
class AyahSearchResult {
  final int ayahId;
  final int surahId;
  final String surahName;
  final int ayahNumber;
  final int globalAyahNumber;
  final String textUthmani;
  final List<String> matchedWords;
  final String? matchedRoot;
  final SearchMatchType matchType;

  const AyahSearchResult({
    required this.ayahId,
    required this.surahId,
    required this.surahName,
    required this.ayahNumber,
    required this.globalAyahNumber,
    required this.textUthmani,
    required this.matchedWords,
    required this.matchType,
    this.matchedRoot,
  });
}

enum SearchMatchType {
  exact,
  normalized,
  lemma,
  verifiedRoot,
  orderedCharactersSuggestion,
}

class RootCandidate {
  final String root;
  final double confidence;
  final String source;
  final bool isVerified;

  const RootCandidate({
    required this.root,
    required this.confidence,
    required this.source,
    required this.isVerified,
  });
}

 1. الحزم المقترحة

اختر الإصدارات المستقرة المتوافقة وقت التنفيذ، ولا تثبت أرقام نسخ عشوائية في البداية:

dependencies:
  flutter:
    sdk: flutter

  flutter_riverpod:
  go_router:
  sqlite3:
  path_provider:
  path:
  equatable:
  freezed_annotation:
  json_annotation:
  intl:
  shared_preferences:

dev_dependencies:
  flutter_test:
    sdk: flutter

  build_runner:
  freezed:
  json_serializable:
  very_good_analysis:

لماذا sqlite3 بدل sqflite؟

إذا كان الهدف Android وiOS فقط، يمكن استخدام sqflite بسهولة، وهو الخيار المستخدم في دليل Flutter الأساسي. أما إذا كنت تحتاج تحكمًا أكبر في SQLite أو دعم سطح المكتب وFTS5 وإضافات tokenizer، فقيّم sqlite3 بعناية قبل اعتماد طبقة البيانات. دليل Flutter يشير أيضًا إلى استخدام sqflite_common_ffi مع تطبيقات سطح المكتب.

 1. الاختبارات المطلوبة
اختبارات التطبيع
يَفْعَلُونَ → يفعلون
ٱلْحَمْدُ → الحمد
إِنَّا → انا

اختبارات تحديد الجذر
يفعلون → فعل
فاعلون → فعل
المفلحين → فلح
يستغفرون → غفر

اختبارات الحروف المرتبة
word = المتفاعلون
root = فعل
expected = true

word = لف
root = فعل
expected = false

اختبارات حدود السورة
آية 2 مع 5 آيات سابقة تبدأ من 1.
آخر آية مع 10 آيات لاحقة تنتهي عند آخر السورة.
السياق لا يعبر إلى سورة أخرى في الوضع الافتراضي.
اختبارات دمج النطاقات
15-24 + 17-26 + 18-27 = 15-27

اختبارات قاعدة البيانات
كل سورة تحتوي العدد الصحيح من الآيات.
كل كلمة مرتبطة بآية موجودة.
لا توجد آيات مكررة.
surah_id + ayah_number فريد.
كل نتيجة جذر تشير إلى كلمة موجودة.
النص العثماني لا يتم تعديله أثناء التطبيع.
18. مراحل التنفيذ
المرحلة الأولى: MVP
إنشاء مشروع Flutter.
تجهيز قاعدة البيانات.
عرض قائمة السور.
عرض آيات السورة.
حفظ آخر موضع قراءة.
البحث المباشر دون تشكيل.
البحث بالجذر المخزن.
عرض نتائج الآيات.
عرض السياق السابق واللاحق.
المرحلة الثانية
شاشة دراسة الجذر.
عدد مرات ورود الكلمات.
تصفية النتائج بالسورة.
دمج السياقات المتداخلة.
المفضلة والملاحظات.
تمييز الكلمة داخل الآية.
المرحلة الثالثة
FTS5.
البحث بعبارات متعددة.
البحث المنطقي AND وOR.
التفسير والترجمة.
الصوت.
البحث الدلالي.
مزامنة المفضلة اختياريًا.
19. معايير القبول

يعتبر إصدار MVP ناجحًا عندما:

يعمل التطبيق دون اتصال بالإنترنت.
يعرض السور والآيات دون تعديل النص الأصلي.
يستطيع المستخدم البحث بكلمة مشكلة أو غير مشكلة.
يستطيع النظام تحديد الجذر من البيانات الصرفية المخزنة.
يعرض جميع الكلمات المرتبطة بالجذر.
يعرض الآيات دون تكرار.
يميز الكلمات المطابقة.
يجلب عددًا اختياريًا من الآيات السابقة واللاحقة.
لا يتجاوز سياق الآية حدود السورة افتراضيًا.
يدمج نطاقات السياق المتداخلة.
يعرض النتائج المقترحة غير الموثقة بصورة مختلفة.
يحتوي على اختبارات Unit وRepository وWidget.
لا ينفذ استعلامًا منفصلًا لكل كلمة إذا كان يمكن استخدام JOIN.
يستخدم parameterized queries.
يحافظ على استجابة الواجهة أثناء البحث.
20. الموجّه الجاهز لوكيل الذكاء الاصطناعي

انسخ النص التالي وأعطه لمساعدك البرمجي:

أنت مهندس Flutter خبير في Clean Architecture وSQLite ومعالجة النصوص العربية.

أريد منك بناء تطبيق مصحف إلكتروني احترافي يعمل دون اتصال بالإنترنت باستخدام Flutter وSQLite. نفذ العمل تدريجيًا، وحافظ على المشروع في حالة قابلة للتشغيل بعد كل مرحلة.

اسم المشروع المبدئي:
quran_study_app

المنصات المستهدفة في MVP:
Android وiOS.

لغة الواجهة:
العربية RTL، مع تهيئة المشروع لدعم الإنجليزية مستقبلًا.

التطبيق يتكون من قسمين:

1. قسم المصحف التقليدي:

- قائمة السور.
- عرض آيات كل سورة بالنص العثماني.
- الانتقال إلى آية محددة.
- حفظ آخر موضع قراءة.
- المفضلة.
- نسخ ومشاركة الآية.
- التحكم في حجم الخط.
- الوضع الليلي.

1. قسم البحث والدراسة:

- البحث المباشر بالكلمة.
- البحث دون تشكيل.
- البحث بحسب الجذر.
- عرض الكلمات القرآنية المرتبطة بالجذر.
- عرض جميع الآيات التي تحتوي كلمات الجذر.
- تمييز الكلمات المطابقة.
- عرض عدد اختياري من الآيات السابقة واللاحقة.
- دمج نطاقات السياق المتداخلة.
- تصفية النتائج حسب السورة.
- شاشة مخصصة لدراسة الجذر.

استخدم Feature-first Architecture مع فصل واضح بين:

- Presentation
- Application/ViewModel
- Domain
- Data

التدفق المعماري:
Presentation → ViewModel/Notifier → Use Case → Repository → SQLite

استخدم Riverpod لإدارة الحالة وgo_router للتنقل.

أنشئ قاعدة بيانات SQLite تحتوي على الجداول التالية:

surahs:

- id
- name_arabic
- name_english
- revelation_type
- ayah_count
- revelation_order
- start_page

ayahs:

- id
- surah_id
- ayah_number
- global_ayah_number
- page_number
- juz_number
- hizb_number
- text_uthmani
- text_simple
- text_normalized

words:

- id
- ayah_id
- surah_id
- ayah_number
- word_position
- word_uthmani
- word_simple
- word_normalized
- lemma
- lemma_normalized
- root
- root_normalized
- prefix
- stem
- suffix
- part_of_speech
- morphology

roots:

- id
- root
- root_normalized
- description_ar

word_roots:

- word_id
- root_id
- confidence
- is_primary
- source

bookmarks:

- id
- ayah_id
- note
- created_at

reading_positions:

- id
- surah_id
- ayah_number
- updated_at

أضف الفهارس اللازمة على:

- ayahs(surah_id, ayah_number)
- ayahs(global_ayah_number)
- words(ayah_id)
- words(word_normalized)
- words(lemma_normalized)
- words(root_normalized)
- words(root_normalized, ayah_id)

أنشئ ArabicNormalizer مستقلًا يقوم بـ:

- إزالة التشكيل.
- إزالة التطويل.
- إزالة علامات الوقف من نسخة البحث.
- توحيد صور الألف لأغراض البحث.
- تنظيف المسافات.
- عدم تعديل النص العثماني الأصلي.

لا تعتمد على حذف السوابق واللواحق وحده لتحديد الجذر.

ترتيب تحديد الجذر:

1. البحث في word_normalized.
2. البحث في lemma_normalized.
3. مطابقة root_normalized.
4. البحث في قاموس الكلمات المحلي.
5. التخمين الصرفي.
6. البحث بالحروف المرتبة كخيار احتياطي فقط.

إذا ظهرت عدة جذور محتملة، اعرضها للمستخدم ليختار أحدها.

صنف نتائج الجذور إلى:

- verifiedRoot
- dictionaryRoot
- inferredRoot
- orderedCharactersSuggestion

أي نتيجة ناتجة عن مطابقة الحروف المرتبة يجب أن تظهر على أنها اقتراح غير مؤكد، ولا يجوز خلطها بالنتائج الصرفية الموثقة.

لا تنفذ loop يقوم باستعلام منفصل لكل كلمة. استخدم JOIN واحدًا بين words وayahs للحصول على الآيات المرتبطة بالجذر.

الاستعلام الأساسي:

SELECT DISTINCT
    a.id,
    a.surah_id,
    a.ayah_number,
    a.global_ayah_number,
    a.text_uthmani,
    a.text_normalized,
    s.name_arabic
FROM ayahs AS a
INNER JOIN surahs AS s
    ON s.id = a.surah_id
INNER JOIN words AS w
    ON w.ayah_id = a.id
WHERE w.root_normalized = ?
ORDER BY a.global_ayah_number;

استخدم parameterized queries فقط.

ميزة سياق الآية:

- يأخذ المستخدم beforeCount وafterCount.
- إذا كانت النتيجة الآية 20 والسابق 5 واللاحق 4، اجلب الآيات 15 إلى 24.
- قص البداية عند الآية 1.
- قص النهاية عند آخر آية في السورة.
- لا تنتقل إلى سورة أخرى في الوضع الافتراضي.
- أضف خيارًا مستقبليًا للامتداد باستخدام global_ayah_number.
- ادمج النطاقات المتداخلة أو المتجاورة في السورة نفسها.
- لا تعرض الآية نفسها أكثر من مرة.
- احتفظ بمعلومة تحدد الآيات الأصلية المطابقة للبحث.

أنشئ الكيانات التالية:

- Surah
- Ayah
- QuranWord
- QuranRoot
- RootCandidate
- AyahSearchResult
- AyahRange
- AyahContextGroup
- Bookmark

أنشئ الخدمات التالية:

- QuranDatabase
- QuranRepository
- QuranSearchRepository
- ArabicNormalizer
- RootResolver
- SearchContextService
- AyahRangeMerger

أنشئ الشاشات التالية:

- HomeScreen
- SurahListScreen
- QuranReaderScreen
- SearchScreen
- SearchResultsScreen
- RootStudyScreen
- AyahContextScreen
- BookmarksScreen
- SettingsScreen

بطاقة نتيجة البحث تعرض:

- اسم السورة.
- رقم الآية.
- النص العثماني.
- الكلمات المطابقة.
- الجذر.
- نوع المطابقة.
- زر عرض السياق.
- زر فتح الآية في المصحف.
- زر المفضلة.
- زر النسخ والمشاركة.

أضف حالات UI التالية:

- Initial
- Loading
- Success
- Empty
- Error

أضف debounce لحقل البحث، ولا تنفذ البحث عند كل حرف فورًا.

أنشئ اختبارات Unit لـ:

- إزالة التشكيل.
- تطبيع الألف.
- مطابقة الحروف المرتبة.
- تحديد الجذر من قاعدة البيانات.
- حساب نطاق السياق.
- قص النطاق عند بداية ونهاية السورة.
- دمج النطاقات المتداخلة.
- إزالة النتائج المكررة.

أنشئ اختبارات Repository باستخدام قاعدة SQLite اختبارية.

قواعد مهمة:

- لا تغير النص العثماني الأصلي.
- لا تستخدم بيانات قرآن تجريبية في الإصدار النهائي.
- تحقق من مصدر النص وترخيصه وسلامته.
- لا تعتبر خوارزمية الحروف المرتبة محللًا صرفيًا.
- لا تضع منطق SQL داخل Widgets.
- لا تضع منطق التطبيع داخل واجهة المستخدم.
- لا تستخدم dynamic دون حاجة.
- استخدم immutable models.
- عالج الأخطاء برسائل عربية واضحة.
- اجعل كل ملف ذا مسؤولية واحدة.
- وثق الأجزاء المعقدة فقط.
- شغل flutter analyze والاختبارات بعد كل مرحلة.

طريقة التنفيذ المطلوبة:

المرحلة 1:

- أنشئ هيكل المشروع.
- أضف الحزم.
- أنشئ الثيم والتوجيه.
- أنشئ نماذج domain الأساسية.
- لا تنفذ جميع الميزات دفعة واحدة.

المرحلة 2:

- أنشئ قاعدة البيانات والجداول والفهارس.
- أنشئ آلية نسخ قاعدة البيانات الجاهزة من assets إلى مساحة التطبيق عند أول تشغيل.
- أضف versioning وmigrations.

المرحلة 3:

- نفذ قائمة السور وعارض الآيات.

المرحلة 4:

- نفذ ArabicNormalizer والبحث المباشر.

المرحلة 5:

- نفذ RootResolver والبحث بالجذر.

المرحلة 6:

- نفذ سياق الآيات ودمج النطاقات.

المرحلة 7:

- نفذ المفضلة والإعدادات.

المرحلة 8:

- أضف الاختبارات والتحسينات وقياس الأداء.

قبل كتابة أي كود:

1. اعرض شجرة الملفات المقترحة.
2. اعرض الحزم المقترحة وسبب استخدام كل حزمة.
3. اعرض مخطط قاعدة البيانات النهائي.
4. اعرض خطة التنفيذ.
5. حدد أي افتراضات اتخذتها.
6. بعدها ابدأ بالمرحلة الأولى مباشرة.

بعد كل مرحلة:

- اعرض الملفات المنشأة أو المعدلة.
- اعرض الكود الكامل لكل ملف جديد.
- وضح أوامر التشغيل.
- شغل flutter analyze.
- شغل flutter test.
- أصلح الأخطاء قبل الانتقال للمرحلة التالية.
- لا تحذف ميزات أو ملفات سابقة دون توضيح السبب.

أهم تحسين معماري في الفكرة

التحسين الأهم هو تغيير المسار من:

استخراج جذر تخميني
→ البحث عن كلمات تحتوي حروف الجذر
→ loop لتنفيذ استعلام لكل كلمة

إلى:

تطبيع المدخل
→ تحديد الجذر من بيانات صرفية موثقة
→ استعلام words حسب root_normalized
→ JOIN واحد لجلب الآيات
→ تجميع النتائج
→ جلب ودمج سياقات الآيات

بهذا يكون البحث:

أكثر دقة.
أسرع.
أسهل للاختبار.
أقل في النتائج الخاطئة.
قابلًا للتوسع إلى دراسة الجذور والاشتقاقات لاحقًا.
