import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:quranapp/features/settings/data/repositories/settings_repository_impl.dart';
import 'package:quranapp/features/settings/presentation/controllers/settings_providers.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('SettingsRepository SharedPreferences Tests', () {
    setUp(() {
      SharedPreferences.setMockInitialValues({});
    });

    test('getFontSize returns default 22.0 when not set', () async {
      final repo = SettingsRepositoryImpl();
      final size = await repo.getFontSize();
      expect(size, 22.0);
    });

    test('setFontSize persists and retrieves customized font size', () async {
      final repo = SettingsRepositoryImpl();
      await repo.setFontSize(28.0);
      final size = await repo.getFontSize();
      expect(size, 28.0);
    });

    test('getThemeMode returns system by default', () async {
      final repo = SettingsRepositoryImpl();
      final mode = await repo.getThemeMode();
      expect(mode, ThemeMode.system);
    });

    test('setThemeMode persists dark, light, and system modes correctly', () async {
      final repo = SettingsRepositoryImpl();

      await repo.setThemeMode(ThemeMode.dark);
      expect(await repo.getThemeMode(), ThemeMode.dark);

      await repo.setThemeMode(ThemeMode.light);
      expect(await repo.getThemeMode(), ThemeMode.light);

      await repo.setThemeMode(ThemeMode.system);
      expect(await repo.getThemeMode(), ThemeMode.system);
    });

    test('keepScreenAwake defaults to false and persists true', () async {
      final repo = SettingsRepositoryImpl();
      expect(await repo.getKeepScreenAwake(), isFalse);

      await repo.setKeepScreenAwake(true);
      expect(await repo.getKeepScreenAwake(), isTrue);
    });
  });

  group('SettingsNotifier & Providers Integration Tests', () {
    setUp(() {
      SharedPreferences.setMockInitialValues({
        'quran_font_size': 24.0,
        'quran_theme_mode': 'dark',
        'quran_keep_screen_awake': true,
      });
    });

    test('SettingsNotifier loads persisted values on initialization', () async {
      final container = ProviderContainer();
      addTearDown(container.dispose);

      // انتظر تحميل الإعدادات غير المتزامن
      final notifier = container.read(settingsNotifierProvider.notifier);
      await notifier.loadSettings();

      final state = container.read(settingsNotifierProvider);
      expect(state.fontSize, 24.0);
      expect(state.themeMode, ThemeMode.dark);
      expect(state.keepScreenAwake, isTrue);

      expect(container.read(themeModeProvider), ThemeMode.dark);
      expect(container.read(appFontSizeProvider), 24.0);
    });

    test('SettingsNotifier updates propagate to themeModeProvider and appFontSizeProvider', () async {
      final container = ProviderContainer();
      addTearDown(container.dispose);

      final notifier = container.read(settingsNotifierProvider.notifier);
      await notifier.loadSettings();

      await notifier.setFontSize(30.0);
      expect(container.read(appFontSizeProvider), 30.0);

      await notifier.setThemeMode(ThemeMode.light);
      expect(container.read(themeModeProvider), ThemeMode.light);
    });
  });
}
