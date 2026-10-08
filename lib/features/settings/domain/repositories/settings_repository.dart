import 'package:flutter/material.dart';

/// واجهة مستودع إعدادات وتفضيلات التطبيق (SettingsRepository Interface).
abstract interface class SettingsRepository {
  /// جلب حجم خط قراءة الآيات المحفوظ محلياً
  Future<double> getFontSize();

  /// حفظ حجم خط قراءة الآيات
  Future<void> setFontSize(double size);

  /// جلب نمط المظهر المحفوظ (فاتح / داكن / يتبع النظام)
  Future<ThemeMode> getThemeMode();

  /// حفظ نمط المظهر
  Future<void> setThemeMode(ThemeMode mode);

  /// جلب خيار إبقاء الشاشة نشطة أثناء التلاوة
  Future<bool> getKeepScreenAwake();

  /// حفظ خيار إبقاء الشاشة نشطة أثناء التلاوة
  Future<void> setKeepScreenAwake(bool keep);
}
