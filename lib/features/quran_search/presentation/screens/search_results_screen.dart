import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../../../app/theme/app_theme.dart';
import '../../domain/entities/search_match_type.dart';

/// شاشة نتائج البحث (SearchResultsScreen) تعرض بطاقات الآيات المطابقة مع إمكانية عرض السياق.
class SearchResultsScreen extends StatelessWidget {
  final String query;
  final bool isRoot;

  const SearchResultsScreen({
    super.key,
    required this.query,
    this.isRoot = false,
  });

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('نتائج البحث: $query'),
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          // شريط معلومات البحث
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: AppTheme.primaryEmerald.withValues(alpha: 0.08),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Row(
              children: [
                const Icon(Icons.info_outline, color: AppTheme.primaryEmerald, size: 20),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    isRoot
                        ? 'بحث بالجذر: $query (سيتم ربطه بمحرك الاستعلام الصرفي في المرحلة 5)'
                        : 'بحث مباشر: $query (سيتم ربطه بالمطبع والبحث المباشر في المرحلة 4)',
                    style: const TextStyle(fontSize: 13),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),

          // نموذج تجريبي لبطاقة نتيجة البحث (البطاقة القياسية المحددة في TRD)
          _buildSampleResultCard(context),
        ],
      ),
    );
  }

  /// بناء بطاقة نتيجة البحث القياسية وفق مواصفات TRD
  Widget _buildSampleResultCard(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
          // رأس البطاقة: اسم السورة ورقم الآية ونوع المطابقة
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text(
                'سورة البقرة - الآية 20',
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 15,
                  color: AppTheme.primaryEmerald,
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: AppTheme.secondaryGold.withValues(alpha: 0.15),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  SearchMatchType.verifiedRoot.labelArabic,
                  style: const TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.bold,
                    color: AppTheme.secondaryGold,
                  ),
                ),
              ),
            ],
          ),
          const Divider(height: 20),

          // النص القرآني العثماني
          const Text(
            'يَكَادُ الْبَرْقُ يَخْطَفُ أَبْصَارَهُمْ ۖ كُلَّمَا أَضَاءَ لَهُم مَّشَوْا فِيهِ...',
            style: TextStyle(
              fontSize: 18,
              height: 1.8,
              fontWeight: FontWeight.w500,
            ),
            textAlign: TextAlign.right,
          ),
          const SizedBox(height: 12),

          // الكلمات المطابقة والجذر
          Row(
            children: [
              const Text(
                'الكلمات المطابقة: ',
                style: TextStyle(fontSize: 13, fontWeight: FontWeight.bold),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                decoration: BoxDecoration(
                  color: AppTheme.primaryEmerald.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(4),
                ),
                child: const Text('أَبْصَارَهُمْ', style: TextStyle(fontSize: 12)),
              ),
              const SizedBox(width: 12),
              const Text(
                'الجذر: ',
                style: TextStyle(fontSize: 13, fontWeight: FontWeight.bold),
              ),
              const Text('بصر', style: TextStyle(fontSize: 13, color: AppTheme.primaryEmerald)),
            ],
          ),
          const SizedBox(height: 16),

          // شريط أزرار الإجراءات السريعة
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              OutlinedButton.icon(
                icon: const Icon(Icons.import_contacts, size: 16),
                label: const Text('فتح في المصحف'),
                onPressed: () => context.push('/reader/2?ayah=20'),
              ),
              OutlinedButton.icon(
                icon: const Icon(Icons.layers_outlined, size: 16),
                label: const Text('عرض السياق'),
                onPressed: () => context.push('/context'),
              ),
              IconButton(
                icon: const Icon(Icons.star_border),
                tooltip: 'إضافة للمفضلة',
                onPressed: () {},
              ),
              IconButton(
                icon: const Icon(Icons.copy_outlined),
                tooltip: 'نسخ الآية',
                onPressed: () {},
              ),
              IconButton(
                icon: const Icon(Icons.share_outlined),
                tooltip: 'مشاركة الآية',
                onPressed: () {},
              ),
            ],
          ),
        ],
      ),
    ),
  );
  }
}
