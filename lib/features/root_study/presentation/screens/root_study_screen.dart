import 'package:flutter/material.dart';
import '../../../../app/theme/app_theme.dart';

/// شاشة دراسة الجذر القرآني (RootStudyScreen) لعرض تفاصيل الجذر ومشتقاته وإحصاءاته.
class RootStudyScreen extends StatelessWidget {
  /// الجذر اللغوي المراد دراسته
  final String root;

  const RootStudyScreen({
    super.key,
    required this.root,
  });

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('دراسة الجذر: $root'),
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          // بطاقة معلومات الجذر الأساسية
          Card(
            color: AppTheme.primaryEmerald.withValues(alpha: 0.08),
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      const Icon(Icons.account_tree, color: AppTheme.primaryEmerald, size: 28),
                      const SizedBox(width: 8),
                      Text(
                        'الجذر اللغوي: $root',
                        style: const TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                          color: AppTheme.primaryEmerald,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  const Text(
                    'سيتم جلب الكلمات القرآنية المرتبطة بهذا الجذر، وعدد مرات ورود كل كلمة، وتوزيعها على السور القرآنية من قاعدة البيانات في المرحلة 5.',
                    style: TextStyle(fontSize: 14, height: 1.5),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 20),

          const Text(
            'الكلمات المشتقة من الجذر',
            style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 12),

          // قائمة تمثيلية للكلمات المشتقة
          ...['عَلِمَ', 'يَعْلَمُونَ', 'عَالِمُ', 'عَلِيمٌ', 'مَعْلُومٍ'].map(
            (word) => Card(
              margin: const EdgeInsets.only(bottom: 8),
              child: ListTile(
                title: Text(word, style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                subtitle: const Text('كلمة قرآنية مشتقة'),
                trailing: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                  decoration: BoxDecoration(
                    color: AppTheme.secondaryGold.withValues(alpha: 0.15),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: const Text('تكرار الكلمة', style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold)),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
