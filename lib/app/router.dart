import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../features/bookmarks/presentation/screens/bookmarks_screen.dart';
import '../features/home/presentation/screens/home_screen.dart';
import '../features/quran_reader/presentation/screens/quran_reader_screen.dart';
import '../features/quran_reader/presentation/screens/surah_list_screen.dart';
import '../features/quran_search/presentation/screens/ayah_context_screen.dart';
import '../features/quran_search/presentation/screens/search_results_screen.dart';
import '../features/quran_search/presentation/screens/search_screen.dart';
import '../features/root_study/presentation/screens/root_study_screen.dart';
import '../features/settings/presentation/screens/settings_screen.dart';

/// تكوين نظام التوجيه والتنقل الشامل (GoRouter) للتطبيق.
final GoRouter appRouter = GoRouter(
  initialLocation: '/',
  routes: <RouteBase>[
    // الشاشة الرئيسية
    GoRoute(
      path: '/',
      builder: (BuildContext context, GoRouterState state) {
        return const HomeScreen();
      },
    ),

    // شاشة قائمة السور
    GoRoute(
      path: '/surahs',
      builder: (BuildContext context, GoRouterState state) {
        return const SurahListScreen();
      },
    ),

    // شاشة عارض السورة والآيات في المصحف
    GoRoute(
      path: '/reader/:surahId',
      builder: (BuildContext context, GoRouterState state) {
        final surahIdStr = state.pathParameters['surahId'] ?? '1';
        final surahId = int.tryParse(surahIdStr) ?? 1;
        final ayahStr = state.uri.queryParameters['ayah'];
        final targetAyah = ayahStr != null ? int.tryParse(ayahStr) : null;

        return QuranReaderScreen(
          surahId: surahId,
          targetAyahNumber: targetAyah,
        );
      },
    ),

    // شاشة البحث
    GoRoute(
      path: '/search',
      builder: (BuildContext context, GoRouterState state) {
        return const SearchScreen();
      },
      routes: [
        // شاشة نتائج البحث
        GoRoute(
          path: 'results',
          builder: (BuildContext context, GoRouterState state) {
            final extra = state.extra as Map<String, dynamic>?;
            final query = extra?['query'] as String? ?? '';
            final isRoot = extra?['isRoot'] as bool? ?? false;

            return SearchResultsScreen(
              query: query,
              isRoot: isRoot,
            );
          },
        ),
      ],
    ),

    // شاشة دراسة الجذر القرآني
    GoRoute(
      path: '/roots/:root',
      builder: (BuildContext context, GoRouterState state) {
        final root = state.pathParameters['root'] ?? '';
        return RootStudyScreen(root: root);
      },
    ),

    // شاشة سياق الآيات
    GoRoute(
      path: '/context',
      builder: (BuildContext context, GoRouterState state) {
        final beforeStr = state.uri.queryParameters['before'];
        final afterStr = state.uri.queryParameters['after'];
        final before = beforeStr != null ? int.tryParse(beforeStr) ?? 2 : 2;
        final after = afterStr != null ? int.tryParse(afterStr) ?? 2 : 2;

        return AyahContextScreen(
          initialBeforeCount: before,
          initialAfterCount: after,
        );
      },
    ),

    // شاشة المفضلة
    GoRoute(
      path: '/bookmarks',
      builder: (BuildContext context, GoRouterState state) {
        return const BookmarksScreen();
      },
    ),

    // شاشة الإعدادات
    GoRoute(
      path: '/settings',
      builder: (BuildContext context, GoRouterState state) {
        return const SettingsScreen();
      },
    ),
  ],
);
