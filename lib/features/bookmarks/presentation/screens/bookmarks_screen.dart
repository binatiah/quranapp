import 'package:flutter/material.dart';
import '../../../../app/theme/app_theme.dart';

/// شاشة المفضلة والآيات المحفوظة (BookmarksScreen).
class BookmarksScreen extends StatelessWidget {
  const BookmarksScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('المفضلة والملاحظات'),
      ),
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                Icons.star_outline,
                size: 64,
                color: AppTheme.secondaryGold.withValues(alpha: 0.6),
              ),
              const SizedBox(height: 16),
              const Text(
                'قائمة المفضلة خالية حالياً',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 8),
              const Text(
                'يمكنك حفظ الآيات وإضافة تدبراتك وملاحظاتك الشخصية عليها، وسيتم تفعيل الحفظ الدائم في SQLite في المرحلة 7.',
                textAlign: TextAlign.center,
                style: TextStyle(fontSize: 14, color: Colors.grey),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
