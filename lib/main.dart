import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';

import 'app/app.dart';

/// نقطة الدخول الرئيسية للتطبيق
void main() {
  WidgetsFlutterBinding.ensureInitialized();

  // تهيئة محرك SQLite عبر FFI لمنصات سطح المكتب (Windows / Linux / macOS)
  if (!kIsWeb && (Platform.isWindows || Platform.isLinux || Platform.isMacOS)) {
    sqfliteFfiInit();
    databaseFactory = databaseFactoryFfi;
  }

  runApp(const ProviderScope(child: QuranStudyApp()));
}
