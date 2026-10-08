import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../domain/repositories/settings_repository.dart';

/// تطبيق مستودع الإعدادات والتفضيلات بالاعتماد على SharedPreferences.
class SettingsRepositoryImpl implements SettingsRepository {
  static const String _keyFontSize = 'quran_font_size';
  static const String _keyThemeMode = 'quran_theme_mode';
  static const String _keyKeepScreenAwake = 'quran_keep_screen_awake';

  final SharedPreferences? _prefs;

  SettingsRepositoryImpl({SharedPreferences? preferences}) : _prefs = preferences;

  Future<SharedPreferences> _getPrefs() async {
    return _prefs ?? await SharedPreferences.getInstance();
  }

  @override
  Future<double> getFontSize() async {
    final prefs = await _getPrefs();
    return prefs.getDouble(_keyFontSize) ?? 22.0;
  }

  @override
  Future<void> setFontSize(double size) async {
    final prefs = await _getPrefs();
    await prefs.setDouble(_keyFontSize, size);
  }

  @override
  Future<ThemeMode> getThemeMode() async {
    final prefs = await _getPrefs();
    final modeStr = prefs.getString(_keyThemeMode);
    switch (modeStr) {
      case 'light':
        return ThemeMode.light;
      case 'dark':
        return ThemeMode.dark;
      case 'system':
      default:
        return ThemeMode.system;
    }
  }

  @override
  Future<void> setThemeMode(ThemeMode mode) async {
    final prefs = await _getPrefs();
    final String modeStr;
    switch (mode) {
      case ThemeMode.light:
        modeStr = 'light';
        break;
      case ThemeMode.dark:
        modeStr = 'dark';
        break;
      case ThemeMode.system:
        modeStr = 'system';
        break;
    }
    await prefs.setString(_keyThemeMode, modeStr);
  }

  @override
  Future<bool> getKeepScreenAwake() async {
    final prefs = await _getPrefs();
    return prefs.getBool(_keyKeepScreenAwake) ?? false;
  }

  @override
  Future<void> setKeepScreenAwake(bool keep) async {
    final prefs = await _getPrefs();
    await prefs.setBool(_keyKeepScreenAwake, keep);
  }
}
