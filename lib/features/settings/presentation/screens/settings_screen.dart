import 'package:flutter/material.dart';
import '../../../../app/theme/app_theme.dart';

/// شاشة الإعدادات العامة للتطبيق (SettingsScreen).
class SettingsScreen extends StatefulWidget {
  const SettingsScreen({super.key});

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  bool _isDarkMode = false;
  double _fontSize = 18.0;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('الإعدادات'),
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          // إعدادات المظهر
          const Text(
            'المظهر والقراءة',
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.bold,
              color: AppTheme.primaryEmerald,
            ),
          ),
          const SizedBox(height: 12),
          Card(
            child: Column(
              children: [
                SwitchListTile(
                  secondary: const Icon(Icons.dark_mode_outlined),
                  title: const Text('الوضع الليلي'),
                  subtitle: const Text('مظهر داكن مريح للقراءة الليلية'),
                  value: _isDarkMode,
                  activeTrackColor: AppTheme.primaryEmerald,
                  onChanged: (val) {
                    setState(() {
                      _isDarkMode = val;
                    });
                  },
                ),
                const Divider(height: 1),
                ListTile(
                  leading: const Icon(Icons.format_size),
                  title: const Text('حجم خط الآيات'),
                  subtitle: Slider(
                    value: _fontSize,
                    min: 14.0,
                    max: 32.0,
                    divisions: 9,
                    label: '${_fontSize.toInt()}',
                    activeColor: AppTheme.primaryEmerald,
                    onChanged: (val) {
                      setState(() {
                        _fontSize = val;
                      });
                    },
                  ),
                  trailing: Text(
                    '${_fontSize.toInt()}',
                    style: const TextStyle(fontWeight: FontWeight.bold),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 24),

          // معلومات المصدر والترخيص
          const Text(
            'المصدر والبيانات',
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.bold,
              color: AppTheme.primaryEmerald,
            ),
          ),
          const SizedBox(height: 12),
          Card(
            child: Column(
              children: [
                ListTile(
                  leading: const Icon(Icons.verified_outlined, color: AppTheme.secondaryGold),
                  title: const Text('مصدر البيانات الصرفية'),
                  subtitle: const Text('بيانات الكلمات والجذور مستندة للتحليل الصرفي القرآني الموثق (Quranic Arabic Corpus).'),
                ),
                const Divider(height: 1),
                ListTile(
                  leading: const Icon(Icons.info_outline),
                  title: const Text('حول التطبيق'),
                  subtitle: const Text('تطبيق مصحف ودراسة القرآن الكريم - إصدار 1.0.0'),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
