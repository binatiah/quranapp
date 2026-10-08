import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../data/repositories/settings_repository_impl.dart';
import '../../domain/repositories/settings_repository.dart';

/// موفر مستودع الإعدادات
final settingsRepositoryProvider = Provider<SettingsRepository>((ref) {
  return SettingsRepositoryImpl();
});

/// كائن حالة إعدادات التطبيق
class SettingsState {
  final double fontSize;
  final ThemeMode themeMode;
  final bool keepScreenAwake;
  final bool isLoaded;

  const SettingsState({
    this.fontSize = 22.0,
    this.themeMode = ThemeMode.system,
    this.keepScreenAwake = false,
    this.isLoaded = false,
  });

  SettingsState copyWith({
    double? fontSize,
    ThemeMode? themeMode,
    bool? keepScreenAwake,
    bool? isLoaded,
  }) {
    return SettingsState(
      fontSize: fontSize ?? this.fontSize,
      themeMode: themeMode ?? this.themeMode,
      keepScreenAwake: keepScreenAwake ?? this.keepScreenAwake,
      isLoaded: isLoaded ?? this.isLoaded,
    );
  }
}

/// متحكم حالة إعدادات وتفضيلات التطبيق (SettingsNotifier)
class SettingsNotifier extends Notifier<SettingsState> {
  @override
  SettingsState build() {
    Future.microtask(() => loadSettings());
    return const SettingsState();
  }

  SettingsRepository get _repo => ref.read(settingsRepositoryProvider);

  /// تحميل جميع الإعدادات المحفوظة من SharedPreferences
  Future<void> loadSettings({bool force = false}) async {
    if (state.isLoaded && !force) return;
    final size = await _repo.getFontSize();
    final mode = await _repo.getThemeMode();
    final keepAwake = await _repo.getKeepScreenAwake();

    state = state.copyWith(
      fontSize: size,
      themeMode: mode,
      keepScreenAwake: keepAwake,
      isLoaded: true,
    );
  }

  /// تغيير وحفظ حجم خط قراءة الآيات
  Future<void> setFontSize(double size) async {
    state = state.copyWith(fontSize: size, isLoaded: true);
    await _repo.setFontSize(size);
  }

  /// تغيير وحفظ نمط المظهر (فاتح / داكن / نظام)
  Future<void> setThemeMode(ThemeMode mode) async {
    state = state.copyWith(themeMode: mode, isLoaded: true);
    await _repo.setThemeMode(mode);
  }

  /// تبديل إبقاء الشاشة مضاءة
  Future<void> setKeepScreenAwake(bool keep) async {
    state = state.copyWith(keepScreenAwake: keep, isLoaded: true);
    await _repo.setKeepScreenAwake(keep);
  }
}

/// موفر حالة الإعدادات العامة
final settingsNotifierProvider =
    NotifierProvider<SettingsNotifier, SettingsState>(() {
  return SettingsNotifier();
});

/// موفر نمط المظهر الحالي المرتبط مباشرة بـ MaterialApp
final themeModeProvider = Provider<ThemeMode>((ref) {
  return ref.watch(settingsNotifierProvider).themeMode;
});

/// موفر حجم الخط الحالي المرتبط مباشرة بقراءة الآيات
final appFontSizeProvider = Provider<double>((ref) {
  return ref.watch(settingsNotifierProvider).fontSize;
});
