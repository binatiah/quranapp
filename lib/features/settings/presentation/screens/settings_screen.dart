import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../app/theme/app_theme.dart';
import '../controllers/settings_providers.dart';

/// شاشة الإعدادات العامة والتفضيلات (SettingsScreen).
class SettingsScreen extends ConsumerWidget {
  const SettingsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final settings = ref.watch(settingsNotifierProvider);
    final settingsNotifier = ref.read(settingsNotifierProvider.notifier);

    return Scaffold(
      appBar: AppBar(
        title: const Text('الإعدادات والتفضيلات'),
      ),
      body: ListView(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 20),
        children: [
          // 1. قسم المظهر والسمة
          _buildSectionTitle(
            context,
            title: 'المظهر والسمة',
            icon: Icons.palette_outlined,
          ),
          const SizedBox(height: 10),
          Card(
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
            elevation: 1,
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'نمط العرض المفضل',
                    style: TextStyle(fontSize: 15, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 4),
                  const Text(
                    'اختر السمة التي تفضلها أثناء قراءة وتصفح التطبيق:',
                    style: TextStyle(fontSize: 13, color: Colors.grey),
                  ),
                  const SizedBox(height: 14),
                  // اختيار السمة (فاتح، داكن، النظام)
                  Row(
                    children: [
                      _buildThemeOption(
                        context,
                        title: 'تلقائي',
                        subtitle: 'النظام',
                        icon: Icons.brightness_auto,
                        isSelected: settings.themeMode == ThemeMode.system,
                        onTap: () => settingsNotifier.setThemeMode(ThemeMode.system),
                      ),
                      const SizedBox(width: 10),
                      _buildThemeOption(
                        context,
                        title: 'فاتح',
                        subtitle: 'نهاري',
                        icon: Icons.light_mode,
                        isSelected: settings.themeMode == ThemeMode.light,
                        onTap: () => settingsNotifier.setThemeMode(ThemeMode.light),
                      ),
                      const SizedBox(width: 10),
                      _buildThemeOption(
                        context,
                        title: 'داكن',
                        subtitle: 'ليلي',
                        icon: Icons.dark_mode,
                        isSelected: settings.themeMode == ThemeMode.dark,
                        onTap: () => settingsNotifier.setThemeMode(ThemeMode.dark),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 24),

          // 2. قسم حجم الخط والمعاينة الحية
          _buildSectionTitle(
            context,
            title: 'حجم خط المصحف والمعاينة',
            icon: Icons.format_size,
          ),
          const SizedBox(height: 10),
          Card(
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
            elevation: 1,
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text(
                        'حجم خط الآيات',
                        style: TextStyle(fontSize: 15, fontWeight: FontWeight.bold),
                      ),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                        decoration: BoxDecoration(
                          color: AppTheme.primaryEmerald.withValues(alpha: 0.1),
                          borderRadius: BorderRadius.circular(8),
                          border: Border.all(
                            color: AppTheme.primaryEmerald.withValues(alpha: 0.3),
                          ),
                        ),
                        child: Text(
                          '${settings.fontSize.toInt()} نقطة',
                          style: const TextStyle(
                            fontSize: 13,
                            fontWeight: FontWeight.bold,
                            color: AppTheme.primaryEmerald,
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  Slider(
                    value: settings.fontSize,
                    min: 16.0,
                    max: 36.0,
                    divisions: 10,
                    activeColor: AppTheme.primaryEmerald,
                    label: '${settings.fontSize.toInt()}',
                    onChanged: (val) {
                      settingsNotifier.setFontSize(val);
                    },
                  ),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text('أصغر (16)', style: TextStyle(fontSize: 12, color: Colors.grey)),
                      TextButton.icon(
                        style: TextButton.styleFrom(visualDensity: VisualDensity.compact),
                        onPressed: () => settingsNotifier.setFontSize(22.0),
                        icon: const Icon(Icons.restore, size: 16, color: AppTheme.secondaryGold),
                        label: const Text(
                          'إعادة للوضع الافتراضي (22)',
                          style: TextStyle(fontSize: 12, color: AppTheme.secondaryGold),
                        ),
                      ),
                      const Text('أكبر (36)', style: TextStyle(fontSize: 12, color: Colors.grey)),
                    ],
                  ),
                  const SizedBox(height: 14),
                  const Divider(height: 1),
                  const SizedBox(height: 14),
                  const Text(
                    'معاينة حية للنص العثماني:',
                    style: TextStyle(fontSize: 13, fontWeight: FontWeight.bold, color: Colors.grey),
                  ),
                  const SizedBox(height: 10),
                  // حاوية المعاينة الحية للخط
                  Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: AppTheme.primaryEmerald.withValues(alpha: 0.05),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(
                        color: AppTheme.secondaryGold.withValues(alpha: 0.3),
                      ),
                    ),
                    child: Column(
                      children: [
                        Text(
                          'بِسْمِ اللَّهِ الرَّحْمَٰنِ الرَّحِيمِ',
                          style: TextStyle(
                            fontSize: settings.fontSize * 0.9,
                            fontWeight: FontWeight.bold,
                            color: AppTheme.primaryEmerald,
                          ),
                          textAlign: TextAlign.center,
                        ),
                        const SizedBox(height: 8),
                        Text(
                          '﴿إِنَّ هَٰذَا الْقُرْآنَ يَهْدِي لِلَّتِي هِيَ أَقْوَمُ وَيُبَشِّرُ الْمُؤْمِنِينَ الَّذِينَ يَعْمَلُونَ الصَّالِحَاتِ أَنَّ لَهُمْ أَجْرًا كَبِيرًا﴾',
                          style: TextStyle(
                            fontSize: settings.fontSize,
                            height: 2.1,
                            fontWeight: FontWeight.w500,
                          ),
                          textAlign: TextAlign.center,
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 24),

          // 3. قسم تفضيلات القراءة
          _buildSectionTitle(
            context,
            title: 'تفضيلات القراءة',
            icon: Icons.menu_book,
          ),
          const SizedBox(height: 10),
          Card(
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
            elevation: 1,
            child: Column(
              children: [
                SwitchListTile(
                  secondary: const Icon(Icons.phone_android, color: AppTheme.primaryEmerald),
                  title: const Text('إبقاء الشاشة مضاءة'),
                  subtitle: const Text('منع إغلاق الشاشة تلقائياً أثناء تلاوة القرآن وتدبره'),
                  value: settings.keepScreenAwake,
                  activeTrackColor: AppTheme.primaryEmerald,
                  onChanged: (val) => settingsNotifier.setKeepScreenAwake(val),
                ),
              ],
            ),
          ),
          const SizedBox(height: 24),

          // 4. قسم المصادر والبيانات
          _buildSectionTitle(
            context,
            title: 'المصادر والتوثيق',
            icon: Icons.info_outline,
          ),
          const SizedBox(height: 10),
          Card(
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
            elevation: 1,
            child: Column(
              children: [
                const ListTile(
                  leading: Icon(Icons.verified, color: AppTheme.secondaryGold),
                  title: Text('المصحف بالرسم العثماني'),
                  subtitle: Text(
                    'النص القرآني المعتمد برواية حفص عن عاصم، مدقق ومشكول بالكامل (مجمع الملك فهد).',
                    style: TextStyle(fontSize: 13),
                  ),
                ),
                const Divider(height: 1),
                const ListTile(
                  leading: Icon(Icons.account_tree_outlined, color: AppTheme.primaryEmerald),
                  title: Text('التحليل الصرفي والجذور'),
                  subtitle: Text(
                    'قاعدة بيانات صرفية دقيقة لـ 77,794 كلمة و 2,194 جذراً لغوياً (Quranic Arabic Corpus).',
                    style: TextStyle(fontSize: 13),
                  ),
                ),
                const Divider(height: 1),
                ListTile(
                  leading: const Icon(Icons.layers_outlined, color: Colors.blueGrey),
                  title: const Text('هندسة التطبيق وقاعدة البيانات'),
                  subtitle: Text(
                    'تطبيق يعمل كلياً بدون إنترنت (Offline-First) بهندسة نظيفة Clean Architecture وتخزين محلي فائق السرعة عبر SQLite.',
                    style: TextStyle(
                      fontSize: 13,
                      color: Theme.of(context).textTheme.bodySmall?.color,
                    ),
                  ),
                ),
                const Divider(height: 1),
                const ListTile(
                  leading: Icon(Icons.info_outline),
                  title: Text('إصدار التطبيق'),
                  trailing: Text(
                    '1.0.0 (المرحلة 7)',
                    style: TextStyle(fontWeight: FontWeight.bold),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 32),
        ],
      ),
    );
  }

  /// عنوان القسم
  Widget _buildSectionTitle(
    BuildContext context, {
    required String title,
    required IconData icon,
  }) {
    return Row(
      children: [
        Icon(icon, size: 20, color: AppTheme.primaryEmerald),
        const SizedBox(width: 8),
        Text(
          title,
          style: const TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.bold,
            color: AppTheme.primaryEmerald,
          ),
        ),
      ],
    );
  }

  /// بناء زر خيار السمة
  Widget _buildThemeOption(
    BuildContext context, {
    required String title,
    required String subtitle,
    required IconData icon,
    required bool isSelected,
    required VoidCallback onTap,
  }) {
    return Expanded(
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 8),
          decoration: BoxDecoration(
            color: isSelected
                ? AppTheme.primaryEmerald.withValues(alpha: 0.12)
                : Theme.of(context).cardColor,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: isSelected
                  ? AppTheme.primaryEmerald
                  : Colors.grey.withValues(alpha: 0.25),
              width: isSelected ? 2 : 1,
            ),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                icon,
                color: isSelected ? AppTheme.primaryEmerald : Colors.grey,
                size: 26,
              ),
              const SizedBox(height: 6),
              Text(
                title,
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                  color: isSelected ? AppTheme.primaryEmerald : null,
                ),
              ),
              const SizedBox(height: 2),
              Text(
                subtitle,
                style: const TextStyle(fontSize: 11, color: Colors.grey),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
