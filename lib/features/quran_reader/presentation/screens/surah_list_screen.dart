import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../../../app/theme/app_theme.dart';

/// شاشة قائمة السور (SurahListScreen) لعرض الـ 114 سورة والانتقال لسورة محددة.
class SurahListScreen extends StatelessWidget {
  const SurahListScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('سور القرآن الكريم'),
      ),
      body: ListView.separated(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        itemCount: 114,
        separatorBuilder: (context, index) => const SizedBox(height: 8),
        itemBuilder: (context, index) {
          final surahId = index + 1;
          return Card(
            child: ListTile(
              leading: Container(
                width: 38,
                height: 38,
                decoration: BoxDecoration(
                  color: AppTheme.primaryEmerald.withValues(alpha: 0.1),
                  shape: BoxShape.circle,
                  border: Border.all(color: AppTheme.primaryEmerald.withValues(alpha: 0.3)),
                ),
                alignment: Alignment.center,
                child: Text(
                  '$surahId',
                  style: const TextStyle(
                    fontWeight: FontWeight.bold,
                    color: AppTheme.primaryEmerald,
                  ),
                ),
              ),
              title: Text(
                'سورة رقم $surahId',
                style: const TextStyle(fontWeight: FontWeight.bold),
              ),
              subtitle: const Text('جاري تحميل التفاصيل في المرحلة القادمة'),
              trailing: const Icon(Icons.arrow_forward_ios, size: 14),
              onTap: () => context.push('/reader/$surahId'),
            ),
          );
        },
      ),
    );
  }
}
