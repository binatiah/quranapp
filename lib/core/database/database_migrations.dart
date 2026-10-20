import 'package:sqflite/sqflite.dart';

/// يدير ترقيات وإصدارات قاعدة البيانات (Database Versioning and Migrations).
class DatabaseMigrations {
  /// رقم الإصدار الحالي لقاعدة البيانات
  static const int currentVersion = 2;

  /// تنفيذ الترحيلات والترقيات عند تغير إصدار قاعدة البيانات
  static Future<void> onUpgrade(Database db, int oldVersion, int newVersion) async {
    for (var version = oldVersion + 1; version <= newVersion; version++) {
      await _migrateToVersion(db, version);
    }
  }

  /// تنفيذ الترحيل الخاص بكل إصدار محدد
  static Future<void> _migrateToVersion(Database db, int version) async {
    switch (version) {
      case 1:
        // الإصدار الأساسي 1 تم إنشاؤه مسبقاً في ملف الأصول
        break;
      case 2:
        // إنشاء جداول وفهارس نظام مشاريع الدراسة القرآنية المنهجية
        await createStudyProjectsTables(db);
        break;
      default:
        break;
    }
  }

  /// إنشاء جداول وفهارس مشاريع الدراسة بأمان (Idempotent DDL)
  static Future<void> createStudyProjectsTables(Database db) async {
    await db.execute('''
      CREATE TABLE IF NOT EXISTS study_projects (
          id INTEGER PRIMARY KEY AUTOINCREMENT,
          title TEXT NOT NULL,
          project_type TEXT NOT NULL,
          target_identifier TEXT NOT NULL,
          description TEXT,
          created_at TEXT NOT NULL,
          updated_at TEXT NOT NULL,
          status TEXT NOT NULL DEFAULT 'draft',
          progress REAL NOT NULL DEFAULT 0.0
      );
    ''');

    await db.execute('''
      CREATE TABLE IF NOT EXISTS root_study_projects (
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
    ''');

    await db.execute('''
      CREATE TABLE IF NOT EXISTS ayah_study_projects (
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
    ''');

    await db.execute('''
      CREATE TABLE IF NOT EXISTS concept_study_projects (
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
    ''');

    await db.execute('''
      CREATE TABLE IF NOT EXISTS study_project_ayahs (
          id INTEGER PRIMARY KEY AUTOINCREMENT,
          project_id INTEGER NOT NULL,
          ayah_id INTEGER NOT NULL,
          note TEXT,
          relation_type TEXT DEFAULT 'related',
          FOREIGN KEY (project_id) REFERENCES study_projects(id) ON DELETE CASCADE,
          FOREIGN KEY (ayah_id) REFERENCES ayahs(id) ON DELETE CASCADE
      );
    ''');

    await db.execute('''
      CREATE TABLE IF NOT EXISTS study_project_roots (
          id INTEGER PRIMARY KEY AUTOINCREMENT,
          project_id INTEGER NOT NULL,
          root_normalized TEXT NOT NULL,
          note TEXT,
          FOREIGN KEY (project_id) REFERENCES study_projects(id) ON DELETE CASCADE
      );
    ''');

    await db.execute('CREATE INDEX IF NOT EXISTS idx_study_projects_type ON study_projects(project_type);');
    await db.execute('CREATE INDEX IF NOT EXISTS idx_study_projects_updated ON study_projects(updated_at);');
    await db.execute('CREATE INDEX IF NOT EXISTS idx_study_project_ayahs_pid ON study_project_ayahs(project_id);');
    await db.execute('CREATE INDEX IF NOT EXISTS idx_study_project_roots_pid ON study_project_roots(project_id);');
  }

  /// التحقق من سلامة وصلاحية الجداول الأساسية والفهارس
  static Future<bool> verifyIntegrity(Database db) async {
    try {
      final tables = await db.rawQuery(
        "SELECT name FROM sqlite_master WHERE type='table';",
      );
      final tableNames = tables.map((row) => row['name'] as String).toSet();

      final requiredTables = {
        'surahs',
        'ayahs',
        'words',
        'roots',
        'word_roots',
        'bookmarks',
        'reading_positions',
        'study_projects',
        'root_study_projects',
        'ayah_study_projects',
        'concept_study_projects',
        'study_project_ayahs',
        'study_project_roots',
      };

      return requiredTables.every(tableNames.contains);
    } catch (_) {
      return false;
    }
  }
}
