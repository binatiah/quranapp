#!/usr/bin/env python3
# -*- coding: utf-8 -*-
"""
أداة بناء وتوليد قاعدة بيانات المصحف الشريف والدراسة القرآنية (quran.db).
تستخرج البيانات من Ayahsquran.xlsx و wordquran.xlsx وتنشئ جداول SQLite مع الفهارس المعتمدة في TRD.
"""

import os
import sys
import re
import sqlite3
import zipfile
import xml.etree.ElementTree as ET

# بيانات السور الـ 114 المعتمدة في مصاحف المدينة المنورة ورواية حفص عن عاصم
# (الاسم العربي، الاسم الإنجليزي، نوع التنزيل، عدد الآيات، ترتيب النزول، صفحة البداية)
SURAHS_DATA = [
    (1, "الفاتحة", "Al-Fatihah", "مكية", 7, 5, 1),
    (2, "البقرة", "Al-Baqarah", "مدنية", 286, 87, 2),
    (3, "آل عمران", "Ali 'Imran", "مدنية", 200, 89, 50),
    (4, "النساء", "An-Nisa", "مدنية", 176, 92, 77),
    (5, "المائدة", "Al-Ma'idah", "مدنية", 120, 112, 106),
    (6, "الأنعام", "Al-An'am", "مكية", 165, 55, 128),
    (7, "الأعراف", "Al-A'raf", "مكية", 206, 39, 151),
    (8, "الأنفال", "Al-Anfal", "مدنية", 75, 88, 177),
    (9, "التوبة", "At-Tawbah", "مدنية", 129, 113, 187),
    (10, "يونس", "Yunus", "مكية", 109, 51, 208),
    (11, "هود", "Hud", "مكية", 123, 52, 221),
    (12, "يوسف", "Yusuf", "مكية", 111, 53, 235),
    (13, "الرعد", "Ar-Ra'd", "مدنية", 43, 96, 249),
    (14, "إبراهيم", "Ibrahim", "مكية", 52, 72, 255),
    (15, "الحجر", "Al-Hijr", "مكية", 99, 54, 262),
    (16, "النحل", "An-Nahl", "مكية", 128, 70, 267),
    (17, "الإسراء", "Al-Isra", "مكية", 111, 50, 282),
    (18, "الكهف", "Al-Kahf", "مكية", 110, 69, 293),
    (19, "مريم", "Maryam", "مكية", 98, 44, 305),
    (20, "طه", "Taha", "مكية", 135, 45, 312),
    (21, "الأنبياء", "Al-Anbiya", "مكية", 112, 73, 322),
    (22, "الحج", "Al-Hajj", "مدنية", 78, 103, 332),
    (23, "المؤمنون", "Al-Mu'minun", "مكية", 118, 74, 342),
    (24, "النور", "An-Nur", "مدنية", 64, 102, 350),
    (25, "الفرقان", "Al-Furqan", "مكية", 77, 42, 359),
    (26, "الشعراء", "Ash-Shu'ara", "مكية", 227, 47, 367),
    (27, "النمل", "An-Naml", "مكية", 93, 48, 377),
    (28, "القصص", "Al-Qasas", "مكية", 88, 49, 385),
    (29, "العنكبوت", "Al-'Ankabut", "مكية", 69, 85, 396),
    (30, "الروم", "Ar-Rum", "مكية", 60, 84, 404),
    (31, "لقمان", "Luqman", "مكية", 34, 57, 411),
    (32, "السجدة", "As-Sajdah", "مكية", 30, 75, 415),
    (33, "الأحزاب", "Al-Ahzab", "مدنية", 73, 90, 418),
    (34, "سبأ", "Saba", "مكية", 54, 58, 428),
    (35, "فاطر", "Fatir", "مكية", 45, 43, 434),
    (36, "يس", "Ya-Sin", "مكية", 83, 41, 440),
    (37, "الصافات", "As-Saffat", "مكية", 182, 56, 446),
    (38, "ص", "Sad", "مكية", 88, 38, 453),
    (39, "الزمر", "Az-Zumar", "مكية", 75, 59, 458),
    (40, "غافر", "Ghafir", "مكية", 85, 60, 467),
    (41, "فصلت", "Fussilat", "مكية", 54, 61, 477),
    (42, "الشورى", "Ash-Shura", "مكية", 53, 62, 483),
    (43, "الزخرف", "Az-Zukhruf", "مكية", 89, 63, 489),
    (44, "الدخان", "Ad-Dukhan", "مكية", 59, 64, 496),
    (45, "الجاثية", "Al-Jathiyah", "مكية", 37, 65, 499),
    (46, "الأحقاف", "Al-Ahqaf", "مكية", 35, 66, 502),
    (47, "محمد", "Muhammad", "مدنية", 38, 95, 507),
    (48, "الفتح", "Al-Fath", "مدنية", 29, 111, 511),
    (49, "الحجرات", "Al-Hujurat", "مدنية", 18, 106, 515),
    (50, "ق", "Qaf", "مكية", 45, 34, 518),
    (51, "الذاريات", "Adh-Dhariyat", "مكية", 60, 67, 520),
    (52, "الطور", "At-Tur", "مكية", 49, 76, 523),
    (53, "النجم", "An-Najm", "مكية", 62, 23, 526),
    (54, "القمر", "Al-Qamar", "مكية", 55, 37, 528),
    (55, "الرحمن", "Ar-Rahman", "مدنية", 78, 97, 531),
    (56, "الواقعة", "Al-Waqi'ah", "مكية", 96, 46, 534),
    (57, "الحديد", "Al-Hadid", "مدنية", 29, 94, 537),
    (58, "المجادلة", "Al-Mujadilah", "مدنية", 22, 105, 542),
    (59, "الحشر", "Al-Hashr", "مدنية", 24, 101, 545),
    (60, "الممتحنة", "Al-Mumtahanah", "مدنية", 13, 91, 549),
    (61, "الصف", "As-Saff", "مدنية", 14, 109, 551),
    (62, "الجمعة", "Al-Jumu'ah", "مدنية", 11, 110, 553),
    (63, "المنافقون", "Al-Munafiqun", "مدنية", 11, 104, 554),
    (64, "التغابن", "At-Taghabun", "مدنية", 18, 108, 556),
    (65, "الطلاق", "At-Talaq", "مدنية", 12, 99, 558),
    (66, "التحريم", "At-Tahrim", "مدنية", 12, 107, 560),
    (67, "الملك", "Al-Mulk", "مكية", 30, 77, 562),
    (68, "القلم", "Al-Qalam", "مكية", 52, 2, 564),
    (69, "الحاقة", "Al-Haqqah", "مكية", 52, 78, 566),
    (70, "المعارج", "Al-Ma'arij", "مكية", 44, 79, 568),
    (71, "نوح", "Nuh", "مكية", 28, 71, 570),
    (72, "الجن", "Al-Jinn", "مكية", 28, 40, 572),
    (73, "المزمل", "Al-Muzzammil", "مكية", 20, 3, 574),
    (74, "المدثر", "Al-Muddaththir", "مكية", 56, 4, 575),
    (75, "القيامة", "Al-Qiyamah", "مكية", 40, 31, 577),
    (76, "الإنسان", "Al-Insan", "مدنية", 31, 98, 578),
    (77, "المرسلات", "Al-Mursalat", "مكية", 50, 33, 580),
    (78, "النبأ", "An-Naba", "مكية", 40, 80, 582),
    (79, "النازعات", "An-Nazi'at", "مكية", 46, 81, 583),
    (80, "عبس", "'Abasa", "مكية", 42, 24, 585),
    (81, "التكوير", "At-Takwir", "مكية", 29, 7, 586),
    (82, "الانفطار", "Al-Infitar", "مكية", 19, 82, 587),
    (83, "المطففين", "Al-Mutaffifin", "مكية", 36, 86, 587),
    (84, "الانشقاق", "Al-Inshiqaq", "مكية", 25, 83, 589),
    (85, "البروج", "Al-Buruj", "مكية", 22, 27, 590),
    (86, "الطارق", "At-Tariq", "مكية", 17, 36, 591),
    (87, "الأعلى", "Al-A'la", "مكية", 19, 8, 591),
    (88, "الغاشية", "Al-Ghashiyah", "مكية", 26, 68, 592),
    (89, "الفجر", "Al-Fajr", "مكية", 30, 10, 593),
    (90, "البلد", "Al-Balad", "مكية", 20, 35, 594),
    (91, "الشمس", "Ash-Shams", "مكية", 15, 26, 595),
    (92, "الليل", "Al-Layl", "مكية", 21, 9, 595),
    (93, "الضحى", "Ad-Duha", "مكية", 11, 11, 596),
    (94, "الشرح", "Ash-Sharh", "مكية", 8, 12, 596),
    (95, "التين", "At-Tin", "مكية", 8, 28, 597),
    (96, "العلق", "Al-'Alaq", "مكية", 19, 1, 597),
    (97, "القدر", "Al-Qadr", "مكية", 5, 25, 598),
    (98, "البينة", "Al-Bayyinah", "مدنية", 8, 100, 598),
    (99, "الزلزلة", "Az-Zalzalah", "مدنية", 8, 93, 599),
    (100, "العاديات", "Al-'Adiyat", "مكية", 11, 14, 599),
    (101, "القارعة", "Al-Qari'ah", "مكية", 11, 30, 600),
    (102, "التكاثر", "At-Takathur", "مكية", 8, 16, 600),
    (103, "العصر", "Al-'Asr", "مكية", 3, 13, 601),
    (104, "الهمزة", "Al-Humazah", "مكية", 9, 32, 601),
    (105, "الفيل", "Al-Fil", "مكية", 5, 19, 601),
    (106, "قريش", "Quraysh", "مكية", 4, 29, 602),
    (107, "الماعون", "Al-Ma'un", "مكية", 7, 17, 602),
    (108, "الكوثر", "Al-Kawthar", "مكية", 3, 15, 602),
    (109, "الكافرون", "Al-Kafirun", "مكية", 6, 18, 603),
    (110, "النصر", "An-Nasr", "مدنية", 3, 114, 603),
    (111, "المسد", "Al-Masad", "مكية", 5, 6, 603),
    (112, "الإخلاص", "Al-Ikhlas", "مكية", 4, 22, 604),
    (113, "الفلق", "Al-Falaq", "مكية", 5, 20, 604),
    (114, "الناس", "An-Nas", "مكية", 6, 21, 604),
]

def normalize_text(text: str) -> str:
    """إزالة التشكيل وتوحيد الألف وعلامات الترقيم لأغراض البحث السريع"""
    if not text:
        return ""
    # إزالة التشكيل القرآني والعربي
    text = re.sub(r'[\u0610-\u061A\u064B-\u065F\u0670\u06D6-\u06ED]', '', text)
    # إزالة التطويل
    text = text.replace('ـ', '')
    # توحيد الألف
    text = re.sub(r'[إأآٱ]', 'ا', text)
    # توحيد التاء المربوطة
    text = text.replace('ة', 'ه')
    # توحيد الياء والألف المقصورة للبحث
    text = text.replace('ى', 'ي')
    # إزالة علامات الوقف والترقيم
    text = re.sub(r'[^\w\s]', '', text)
    # تنظيف المسافات الزائدة
    text = re.sub(r'\s+', ' ', text).strip()
    return text

def remove_diacritics_only(text: str) -> str:
    """إزالة التشكيل فقط دون تعديل الحروف (النص المبسط text_simple)"""
    if not text:
        return ""
    text = re.sub(r'[\u0610-\u061A\u064B-\u065F\u0670\u06D6-\u06ED]', '', text)
    text = text.replace('ـ', '')
    text = re.sub(r'\s+', ' ', text).strip()
    return text

def read_xlsx_rows(filename):
    """قراءة أسطر ملف إكسل بسرعة وخفة دون الحاجة لمكتبات خارجية ثقيلة"""
    with zipfile.ZipFile(filename, 'r') as z:
        shared_strings = []
        if 'xl/sharedStrings.xml' in z.namelist():
            tree = ET.fromstring(z.read('xl/sharedStrings.xml'))
            for si in tree.findall('{http://schemas.openxmlformats.org/spreadsheetml/2006/main}si'):
                text = ''.join(t.text for t in si.findall('.//{http://schemas.openxmlformats.org/spreadsheetml/2006/main}t') if t.text)
                shared_strings.append(text)
        
        tree = ET.fromstring(z.read('xl/worksheets/sheet1.xml'))
        rows = tree.findall('.//{http://schemas.openxmlformats.org/spreadsheetml/2006/main}row')
        for r in rows:
            cells = []
            for c in r.findall('{http://schemas.openxmlformats.org/spreadsheetml/2006/main}c'):
                t = c.get('t')
                v = c.find('{http://schemas.openxmlformats.org/spreadsheetml/2006/main}v')
                val = v.text if v is not None else ''
                if t == 's' and val.isdigit():
                    val = shared_strings[int(val)]
                cells.append(val.strip())
            yield cells

def build_database(db_path: str):
    """بناء قاعدة بيانات SQLite الشاملة"""
    os.makedirs(os.path.dirname(db_path), exist_ok=True)
    if os.path.exists(db_path):
        os.remove(db_path)
    
    print(f"إنشاء قاعدة البيانات في: {db_path}...")
    conn = sqlite3.connect(db_path)
    cursor = conn.cursor()

    # تحسين أداء SQLite
    cursor.execute("PRAGMA journal_mode = WAL;")
    cursor.execute("PRAGMA synchronous = NORMAL;")

    # 1. إنشاء جدول السور
    cursor.execute("""
    CREATE TABLE surahs (
        id INTEGER PRIMARY KEY,
        name_arabic TEXT NOT NULL,
        name_english TEXT,
        revelation_type TEXT,
        ayah_count INTEGER NOT NULL,
        revelation_order INTEGER,
        start_page INTEGER
    );
    """)

    # 2. إنشاء جدول الآيات
    cursor.execute("""
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
    """)

    # 3. إنشاء جدول الكلمات
    cursor.execute("""
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
    """)

    # 4. إنشاء جدول الجذور
    cursor.execute("""
    CREATE TABLE roots (
        id INTEGER PRIMARY KEY,
        root TEXT NOT NULL,
        root_normalized TEXT NOT NULL UNIQUE,
        description_ar TEXT
    );
    """)

    # 5. إنشاء جدول ربط الكلمات بالجذور
    cursor.execute("""
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
    """)

    # 6. إنشاء جدول المفضلة
    cursor.execute("""
    CREATE TABLE bookmarks (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        ayah_id INTEGER NOT NULL,
        note TEXT,
        created_at TEXT NOT NULL,
        FOREIGN KEY (ayah_id) REFERENCES ayahs(id)
    );
    """)

    # 7. إنشاء جدول آخر موضع قراءة
    cursor.execute("""
    CREATE TABLE reading_positions (
        id INTEGER PRIMARY KEY CHECK (id = 1),
        surah_id INTEGER NOT NULL,
        ayah_number INTEGER NOT NULL,
        updated_at TEXT NOT NULL
    );
    """)

    # إدخال السور الـ 114
    print("إدخال بيانات السور الـ 114...")
    cursor.executemany("""
    INSERT INTO surahs (id, name_arabic, name_english, revelation_type, ayah_count, revelation_order, start_page)
    VALUES (?, ?, ?, ?, ?, ?, ?);
    """, SURAHS_DATA)

    # وضع موضع القراءة الافتراضي (سورة الفاتحة الآية 1)
    cursor.execute("""
    INSERT INTO reading_positions (id, surah_id, ayah_number, updated_at)
    VALUES (1, 1, 1, datetime('now'));
    """)

    # قراءة قاموس الكلمات والجذور من wordquran.xlsx
    print("قراءة معجم الكلمات والجذور من wordquran.xlsx...")
    # Map: word_simple -> (root_raw, lemma_raw, typew, case1)
    word_dict = {}
    roots_set = set() # (root_clean, root_norm)

    word_gen = read_xlsx_rows("wordquran.xlsx")
    _ = next(word_gen) # تخطي سطر العناوين
    for row in word_gen:
        if len(row) > 7:
            w_simple = row[1].strip()
            typew = row[6].strip() if len(row) > 6 else ""
            sr_word = row[7].strip() if len(row) > 7 else ""
            txtnot = row[8].strip() if len(row) > 8 else ""

            # الجذر مثل 'ح.م.د' -> تنظيفه إلى 'حمد'
            if sr_word and '.' in sr_word and not sr_word.startswith('#'):
                clean_root = sr_word.replace('.', '').strip()
            elif txtnot and not txtnot.startswith('#') and len(txtnot) in [3, 4]:
                clean_root = txtnot.strip()
            else:
                clean_root = None

            norm_root = normalize_text(clean_root) if clean_root else None
            clean_lemma = txtnot if (txtnot and not txtnot.startswith('#')) else None
            norm_lemma = normalize_text(clean_lemma) if clean_lemma else None

            if clean_root and norm_root:
                roots_set.add((clean_root, norm_root))

            word_dict[w_simple] = (clean_root, norm_root, clean_lemma, norm_lemma, typew)

    print(f"تم تحميل {len(word_dict)} مفردة و {len(roots_set)} جذر فريد من المعجم.")

    # إدخال الجذور في جدول roots
    root_id_map = {}
    root_counter = 1
    # ترتيب الجذور أبجدياً
    sorted_roots = sorted(list(roots_set), key=lambda x: x[1])
    for r_raw, r_norm in sorted_roots:
        if r_norm not in root_id_map:
            cursor.execute("""
            INSERT INTO roots (id, root, root_normalized, description_ar)
            VALUES (?, ?, ?, ?);
            """, (root_counter, r_raw, r_norm, f"جذر قرآني: {r_raw}"))
            root_id_map[r_norm] = root_counter
            root_counter += 1

    # قراءة الآيات من Ayahsquran.xlsx
    print("قراءة الآيات من Ayahsquran.xlsx...")
    ayahs_gen = read_xlsx_rows("Ayahsquran.xlsx")
    _ = next(ayahs_gen) # تخطي العنوان

    ayah_records = []
    # استدراك الآية 1 في الفاتحة (البسملة)
    bismillah_uthmani = "بِسْمِ اللَّهِ الرَّحْمَٰنِ الرَّحِيمِ"
    ayah_records.append((
        1,  # id
        1,  # surah_id (الفاتحة)
        1,  # ayah_number
        1,  # global_ayah_number
        1,  # page_number
        1,  # juz_number
        1,  # hizb_number
        bismillah_uthmani,
        remove_diacritics_only(bismillah_uthmani),
        normalize_text(bismillah_uthmani),
    ))

    global_counter = 2
    raw_ayahs = []
    for row in ayahs_gen:
        if len(row) >= 6:
            surah_id = int(row[2])
            ayah_num = int(row[5])
            raw_text = row[4].strip()
            # إزالة رقم الآية الموضوع بين قوسين في نهاية النص مثل (2)
            clean_text = re.sub(r'\s*\(\d+\)\s*$', '', raw_text)
            raw_ayahs.append((surah_id, ayah_num, clean_text))

    # ترتيب الآيات تسلسلياً حسب السورة ورقم الآية
    raw_ayahs.sort(key=lambda x: (x[0], x[1]))

    for s_id, a_num, uthmani in raw_ayahs:
        # حساب رقم الصفحة التقديري بناء على صفحة بداية السورة
        start_pg = SURAHS_DATA[s_id - 1][6]
        ayah_id = global_counter
        ayah_records.append((
            ayah_id,
            s_id,
            a_num,
            global_counter,
            start_pg,
            1, # juz
            1, # hizb
            uthmani,
            remove_diacritics_only(uthmani),
            normalize_text(uthmani),
        ))
        global_counter += 1

    print(f"إدخال {len(ayah_records)} آية في جدول ayahs...")
    cursor.executemany("""
    INSERT INTO ayahs (id, surah_id, ayah_number, global_ayah_number, page_number, juz_number, hizb_number, text_uthmani, text_simple, text_normalized)
    VALUES (?, ?, ?, ?, ?, ?, ?, ?, ?, ?);
    """, ayah_records)

    # تقسيم الآيات إلى كلمات وتخزينها في words و word_roots
    print("تفكيك الآيات إلى كلمات وبناء جدول words والصرف القرآني...")
    word_records = []
    word_root_records = []
    word_id_counter = 1

    for ayah in ayah_records:
        ayah_id = ayah[0]
        surah_id = ayah[1]
        ayah_num = ayah[2]
        text_uthmani = ayah[7]

        words_list = text_uthmani.split()
        for pos, w_uthmani in enumerate(words_list, start=1):
            w_simple = remove_diacritics_only(w_uthmani)
            w_norm = normalize_text(w_uthmani)

            # البحث في المعجم
            dict_match = word_dict.get(w_simple) or word_dict.get(w_norm)
            if dict_match:
                c_root, n_root, c_lemma, n_lemma, part_of_sp = dict_match
            else:
                c_root, n_root, c_lemma, n_lemma, part_of_sp = None, None, None, None, None

            word_records.append((
                word_id_counter,
                ayah_id,
                surah_id,
                ayah_num,
                pos,
                w_uthmani,
                w_simple,
                w_norm,
                c_lemma,
                n_lemma,
                c_root,
                n_root,
                "", # prefix
                w_simple, # stem
                "", # suffix
                part_of_sp or "كلمة قرآنية",
                ""  # morphology
            ))

            if n_root and n_root in root_id_map:
                r_id = root_id_map[n_root]
                word_root_records.append((
                    word_id_counter,
                    r_id,
                    1.0,
                    1,
                    "Quranic Arabic Corpus / Lexicon"
                ))

            word_id_counter += 1

    print(f"إدخال {len(word_records)} كلمة في جدول words...")
    cursor.executemany("""
    INSERT INTO words (
        id, ayah_id, surah_id, ayah_number, word_position,
        word_uthmani, word_simple, word_normalized,
        lemma, lemma_normalized, root, root_normalized,
        prefix, stem, suffix, part_of_speech, morphology
    ) VALUES (?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?);
    """, word_records)

    print(f"إدخال {len(word_root_records)} رابط في جدول word_roots...")
    cursor.executemany("""
    INSERT INTO word_roots (word_id, root_id, confidence, is_primary, source)
    VALUES (?, ?, ?, ?, ?);
    """, word_root_records)

    # إنشاء الفهارس المطلوبة في TRD
    print("إنشاء الفهارس الفائقة...")
    indexes = [
        "CREATE INDEX idx_ayahs_surah_number ON ayahs(surah_id, ayah_number);",
        "CREATE INDEX idx_ayahs_global ON ayahs(global_ayah_number);",
        "CREATE INDEX idx_words_ayah ON words(ayah_id);",
        "CREATE INDEX idx_words_normalized ON words(word_normalized);",
        "CREATE INDEX idx_words_lemma ON words(lemma_normalized);",
        "CREATE INDEX idx_words_root ON words(root_normalized);",
        "CREATE INDEX idx_words_surah_ayah ON words(surah_id, ayah_number);",
        "CREATE INDEX idx_words_root_ayah ON words(root_normalized, ayah_id);",
    ]
    for idx_sql in indexes:
        cursor.execute(idx_sql)

    conn.commit()

    # تقرير التحقق النهائي
    cursor.execute("SELECT COUNT(*) FROM surahs;")
    surahs_cnt = cursor.fetchone()[0]
    cursor.execute("SELECT COUNT(*) FROM ayahs;")
    ayahs_cnt = cursor.fetchone()[0]
    cursor.execute("SELECT COUNT(*) FROM words;")
    words_cnt = cursor.fetchone()[0]
    cursor.execute("SELECT COUNT(*) FROM roots;")
    roots_cnt = cursor.fetchone()[0]
    cursor.execute("SELECT COUNT(*) FROM word_roots;")
    word_roots_cnt = cursor.fetchone()[0]

    conn.close()

    print("========================================")
    print("تم بناء قاعدة البيانات بنجاح تام!")
    print(f"- عدد السور: {surahs_cnt} سورة (المطلوب: 114)")
    print(f"- عدد الآيات: {ayahs_cnt} آية (المطلوب: 6236 آية برواية حفص)")
    print(f"- عدد الكلمات: {words_cnt} كلمة قرآنية")
    print(f"- عدد الجذور: {roots_cnt} جذر لغوي")
    print(f"- روابط الكلمات بالجذور: {word_roots_cnt} رابط صرفي")
    print(f"- حجم الملف: {os.path.getsize(db_path) / (1024 * 1024):.2f} ميغابايت")
    print("========================================")

if __name__ == "__main__":
    target_db = os.path.join("assets", "database", "quran.db")
    build_database(target_db)
