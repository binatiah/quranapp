import 'package:flutter/material.dart';
import '../../../../app/theme/app_theme.dart';

/// شاشة عارض القرآن الكريم (QuranReaderScreen) لعرض آيات السورة بالنص العثماني.
class QuranReaderScreen extends StatelessWidget {
  /// رقم السورة المعروضة
  final int surahId;

  /// رقم الآية المستهدفة للانتقال المباشر إليها إن وُجدت
  final int? targetAyahNumber;

  const QuranReaderScreen({
    super.key,
    required this.surahId,
    this.targetAyahNumber,
  });

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('سورة رقم $surahId'),
        actions: [
          IconButton(
            icon: const Icon(Icons.format_size),
            tooltip: 'تغيير حجم الخط',
            onPressed: () {},
          ),
          IconButton(
            icon: const Icon(Icons.bookmark_border),
            tooltip: 'حفظ موضع القراءة',
            onPressed: () {
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('تم حفظ موضع القراءة')),
              );
            },
          ),
        ],
      ),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              padding: const EdgeInsets.all(24),
              margin: const EdgeInsets.symmetric(horizontal: 24),
              decoration: BoxDecoration(
                color: Theme.of(context).cardColor,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(
                  color: AppTheme.secondaryGold.withValues(alpha: 0.4),
                  width: 1.5,
                ),
              ),
              child: Column(
                children: [
                  const Text(
                    'بِسْمِ اللَّهِ الرَّحْمَٰنِ الرَّحِيمِ',
                    style: TextStyle(
                      fontSize: 22,
                      fontWeight: FontWeight.bold,
                      color: AppTheme.primaryEmerald,
                    ),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 16),
                  Text(
                    'عرض آيات السورة رقم ($surahId)\nسيتم جلب الآيات كاملة بالنص العثماني من قاعدة بيانات SQLite في المرحلة المخصصة (المرحلة 3).',
                    textAlign: TextAlign.center,
                    style: const TextStyle(fontSize: 15, height: 1.6),
                  ),
                  if (targetAyahNumber != null) ...[
                    const SizedBox(height: 12),
                    Text(
                      'الانتقال للآية: $targetAyahNumber',
                      style: const TextStyle(
                        color: AppTheme.secondaryGold,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
