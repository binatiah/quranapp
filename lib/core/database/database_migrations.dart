import 'package:sqflite/sqflite.dart';

/// يدير ترقيات وإصدارات قاعدة البيانات (Database Versioning and Migrations).
class DatabaseMigrations {
  /// رقم الإصدار الحالي لقاعدة البيانات
  static const int currentVersion = 1;

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
      // مستقبلاً: دعم إضافة جداول التفاسير والترجمات الصوتية في إصدارات تالية
      case 2:
        // مثال: await db.execute("CREATE TABLE IF NOT EXISTS translations (...)");
        break;
      default:
        break;
    }
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
      };

      return requiredTables.every(tableNames.contains);
    } catch (_) {
      return false;
    }
  }
}
