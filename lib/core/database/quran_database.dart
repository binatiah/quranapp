import 'dart:io';
import 'package:flutter/services.dart';
import 'package:path/path.dart' as p;
import 'package:sqflite/sqflite.dart';

import 'database_migrations.dart';

/// الفئة المسؤولة عن إدارة وتهيئة قاعدة بيانات القرآن الكريم SQLite.
/// تتولى نسخ قاعدة البيانات الجاهزة من assets عند أول تشغيل، وإدارة الاتصال، والترقيات.
class QuranDatabase {
  static const String databaseFileName = 'quran.db';
  static const String assetDatabasePath = 'assets/database/quran.db';

  static QuranDatabase? _instance;
  static Database? _database;

  /// مصنع قواعد البيانات المخصص (يُستخدم بشكل أساسي في اختبارات الوحدة عبر FFI)
  final DatabaseFactory? _customFactory;

  /// المسار المخصص لملف قاعدة البيانات (يُستخدم في بيئات الاختبار)
  final String? _customPath;

  /// المنشئ الداخلي الخاص
  QuranDatabase._({DatabaseFactory? customFactory, String? customPath})
      : _customFactory = customFactory,
        _customPath = customPath;

  /// الحصول على النسخة المشتركة الفردية (Singleton)
  static QuranDatabase get instance {
    _instance ??= QuranDatabase._();
    return _instance!;
  }

  /// إنشاء نسخة مخصصة لأغراض الاختبارات البرمجية
  factory QuranDatabase.forTesting({
    required DatabaseFactory customFactory,
    required String customPath,
  }) {
    return QuranDatabase._(
      customFactory: customFactory,
      customPath: customPath,
    );
  }

  /// الحصول على كائن اتصال قاعدة البيانات المفتوح
  Future<Database> get database async {
    if (_database != null && _database!.isOpen) {
      return _database!;
    }
    _database = await _initDatabase();
    return _database!;
  }

  /// تهيئة وتجهيز ملف قاعدة البيانات وفتحه
  Future<Database> _initDatabase() async {
    final factory = _customFactory ?? databaseFactory;
    final String path;

    if (_customPath != null) {
      path = _customPath;
    } else {
      final databasesPath = await factory.getDatabasesPath();
      path = p.join(databasesPath, databaseFileName);
    }

    // التحقق مما إذا كانت قاعدة البيانات منسوخة مسبقًا في مجلد التطبيق
    final exists = await factory.databaseExists(path);

    if (!exists && _customPath == null) {
      // نسخ قاعدة البيانات الجاهزة المسبقة من حزمة assets
      await _copyDatabaseFromAssets(path);
    }

    // فتح قاعدة البيانات مع تفعيل إدارة الترحيلات
    return await factory.openDatabase(
      path,
      options: OpenDatabaseOptions(
        version: DatabaseMigrations.currentVersion,
        onUpgrade: DatabaseMigrations.onUpgrade,
      ),
    );
  }

  /// نسخ ملف قاعدة البيانات الجاهزة من assets إلى مساحة التخزين المحلية للتطبيق
  Future<void> _copyDatabaseFromAssets(String targetPath) async {
    try {
      // التأكد من وجود المجلد الهدف
      final targetDir = Directory(p.dirname(targetPath));
      if (!await targetDir.exists()) {
        await targetDir.create(recursive: true);
      }

      // قراءة بايتات قاعدة البيانات من أصول التطبيق
      final ByteData data = await rootBundle.load(assetDatabasePath);
      final List<int> bytes = data.buffer.asUint8List(
        data.offsetInBytes,
        data.lengthInBytes,
      );

      // كتابة الملف في مسار البيانات الدائم للتطبيق
      final file = File(targetPath);
      await file.writeAsBytes(bytes, flush: true);
    } catch (e) {
      throw Exception('فشل في نسخ قاعدة بيانات المصحف من الأصول: $e');
    }
  }

  /// تنفيذ استعلام استرجاع بيانات آمن باستخدام Parameterized Query
  Future<List<Map<String, dynamic>>> query({
    required String sql,
    List<Object?> arguments = const [],
  }) async {
    final db = await database;
    return await db.rawQuery(sql, arguments);
  }

  /// إدخال سجل جديد في جدول محدد بأمان
  Future<int> insert({
    required String table,
    required Map<String, dynamic> values,
    ConflictAlgorithm conflictAlgorithm = ConflictAlgorithm.replace,
  }) async {
    final db = await database;
    return await db.insert(table, values, conflictAlgorithm: conflictAlgorithm);
  }

  /// تحديث سجلات جدول محدد بأمان باستخدام Parameterized Query
  Future<int> update({
    required String table,
    required Map<String, dynamic> values,
    String? where,
    List<Object?>? whereArgs,
  }) async {
    final db = await database;
    return await db.update(table, values, where: where, whereArgs: whereArgs);
  }

  /// حذف سجلات من جدول محدد بأمان
  Future<int> delete({
    required String table,
    String? where,
    List<Object?>? whereArgs,
  }) async {
    final db = await database;
    return await db.delete(table, where: where, whereArgs: whereArgs);
  }

  /// إغلاق اتصال قاعدة البيانات
  Future<void> close() async {
    if (_database != null && _database!.isOpen) {
      await _database!.close();
      _database = null;
    }
  }

  /// إعادة تعيين قاعدة البيانات للاختبارات
  static void resetForTesting() {
    _database = null;
    _instance = null;
  }
}
