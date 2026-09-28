import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:share_plus/share_plus.dart';

import 'package:quranapp/app/theme/app_theme.dart';
import 'package:quranapp/core/database/quran_database.dart';
import 'package:quranapp/core/text/quran_text_utils.dart';
import 'package:quranapp/features/quran_search/domain/entities/ayah_search_result.dart';
import 'package:quranapp/features/quran_search/domain/entities/search_match_type.dart';
import 'package:quranapp/features/quran_search/presentation/controllers/search_providers.dart';

/// شاشة مخصصة لعرض نتائج البحث المفصلة ومشاركتها (SearchResultsScreen).
class SearchResultsScreen extends ConsumerWidget {
  final String query;
  final bool isRoot;

  const SearchResultsScreen({
    super.key,
    required this.query,
    this.isRoot = false,
  });

  void _copyAyah(BuildContext context, AyahSearchResult result) {
    final text = '﴿${result.textUthmani}﴾ [سورة ${result.surahName}: ${result.ayahNumber}]';
    Clipboard.setData(ClipboardData(text: text));
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('تم نسخ الآية إلى الحافظة'), duration: Duration(seconds: 2)),
    );
  }

  void _shareAyah(AyahSearchResult result) {
    final text = '﴿${result.textUthmani}﴾\n[سورة ${result.surahName} - الآية ${result.ayahNumber}]';
    SharePlus.instance.share(ShareParams(text: text));
  }

  Future<void> _bookmarkAyah(BuildContext context, AyahSearchResult result) async {
    try {
      await QuranDatabase.instance.insert(
        table: 'bookmarks',
        values: {
          'ayah_id': result.ayahId,
          'note': 'سورة ${result.surahName} آية ${result.ayahNumber}',
          'created_at': DateTime.now().toIso8601String(),
        },
      );
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('تمت إضافة آية (${result.ayahNumber}) للمفضلة'),
            backgroundColor: AppTheme.secondaryGold,
            duration: const Duration(seconds: 2),
          ),
        );
      }
    } catch (_) {}
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final searchState = ref.watch(searchNotifierProvider);
    final uiState = searchState.uiState;
    final results = uiState.data ?? [];

    return Scaffold(
      appBar: AppBar(
        title: Text('نتائج: $query'),
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
                        ? 'نتائج البحث بالجذر الصرفي: ($query) • ${results.length} آيات مطابقة'
                        : 'نتائج البحث النصي المباشر: ($query) • ${results.length} آيات مطابقة',
                    style: const TextStyle(fontSize: 13, fontWeight: FontWeight.bold),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),

          if (results.isEmpty)
            const Center(
              child: Padding(
                padding: EdgeInsets.all(32),
                child: Text('لا توجد نتائج مطابقة لعرضها'),
              ),
            )
          else
            ...results.map((item) => _buildCard(context, item)),
        ],
      ),
    );
  }

  Widget _buildCard(BuildContext context, AyahSearchResult result) {
    return Card(
      margin: const EdgeInsets.only(bottom: 16),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'سورة ${result.surahName} - الآية ${result.ayahNumber}',
                  style: const TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 15,
                    color: AppTheme.primaryEmerald,
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: result.matchType == SearchMatchType.verifiedRoot
                        ? AppTheme.secondaryGold.withValues(alpha: 0.15)
                        : AppTheme.primaryEmerald.withValues(alpha: 0.12),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Text(
                    result.matchType.labelArabic,
                    style: TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.bold,
                      color: result.matchType == SearchMatchType.verifiedRoot
                          ? AppTheme.secondaryGold
                          : AppTheme.primaryEmerald,
                    ),
                  ),
                ),
              ],
            ),
            const Divider(height: 20),
            RichText(
              text: TextSpan(
                children: QuranTextUtils.highlightMatchedWords(
                  textUthmani: result.textUthmani,
                  matchedWords: result.matchedWords,
                  defaultStyle: TextStyle(
                    fontSize: 18,
                    height: 2.0,
                    fontWeight: FontWeight.w500,
                    color: Theme.of(context).textTheme.bodyLarge?.color,
                  ),
                ),
              ),
              textAlign: TextAlign.right,
            ),
            const SizedBox(height: 12),
            Wrap(
              spacing: 8,
              runSpacing: 4,
              children: [
                const Text('الكلمات المطابقة: ', style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold)),
                ...result.matchedWords.map(
                  (w) => Container(
                    padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                    decoration: BoxDecoration(
                      color: AppTheme.secondaryGold.withValues(alpha: 0.15),
                      borderRadius: BorderRadius.circular(4),
                    ),
                    child: Text(w, style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold)),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                OutlinedButton.icon(
                  icon: const Icon(Icons.import_contacts, size: 16),
                  label: const Text('فتح في المصحف'),
                  onPressed: () {
                    context.push('/reader/${result.surahId}?ayah=${result.ayahNumber}');
                  },
                ),
                OutlinedButton.icon(
                  icon: const Icon(Icons.layers_outlined, size: 16),
                  label: const Text('عرض السياق'),
                  onPressed: () {
                    context.push('/context?surahId=${result.surahId}&ayah=${result.ayahNumber}&before=2&after=2');
                  },
                ),
                if (result.matchedRoot != null)
                  OutlinedButton.icon(
                    icon: const Icon(Icons.account_tree_outlined, size: 16, color: AppTheme.secondaryGold),
                    label: Text(
                      'دراسة الجذر (${result.matchedRoot})',
                      style: const TextStyle(color: AppTheme.secondaryGold, fontWeight: FontWeight.bold),
                    ),
                    onPressed: () {
                      context.push('/roots/${result.matchedRoot}');
                    },
                  ),
                IconButton(
                  icon: const Icon(Icons.star_border, size: 20),
                  tooltip: 'إضافة للمفضلة',
                  onPressed: () => _bookmarkAyah(context, result),
                ),
                IconButton(
                  icon: const Icon(Icons.copy_outlined, size: 18),
                  tooltip: 'نسخ الآية',
                  onPressed: () => _copyAyah(context, result),
                ),
                IconButton(
                  icon: const Icon(Icons.share_outlined, size: 18),
                  tooltip: 'مشاركة الآية',
                  onPressed: () => _shareAyah(result),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
