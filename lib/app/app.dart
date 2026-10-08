import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../features/settings/presentation/controllers/settings_providers.dart';
import 'router.dart';
import 'theme/app_theme.dart';

/// ويدجت الجذر الأساسي للتطبيق (QuranStudyApp) مهيأ للتوطين والتوجيه وإدارة الحالة.
class QuranStudyApp extends ConsumerWidget {
  const QuranStudyApp({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final themeMode = ref.watch(themeModeProvider);

    return MaterialApp.router(
      title: 'مصحف البحث والدراسة',
      debugShowCheckedModeBanner: false,

      // إعدادات التوجيه باستخدام GoRouter
      routerConfig: appRouter,

      // إعدادات الهوية البصرية والثيم
      theme: AppTheme.lightTheme,
      darkTheme: AppTheme.darkTheme,
      themeMode: themeMode,

      // إعدادات اللغة والتوطين (العربية افتراضيًا مع اتجاه RTL)
      locale: const Locale('ar'),
      supportedLocales: const [
        Locale('ar'),
        Locale('en'),
      ],
      localizationsDelegates: const [
        GlobalMaterialLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
      ],
    );
  }
}
