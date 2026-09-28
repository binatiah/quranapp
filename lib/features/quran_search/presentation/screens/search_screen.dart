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

/// شاشة البحث القرآني المباشر وبالجذر مع Debounce والتصفية والتمييز اللوني.
class SearchScreen extends ConsumerStatefulWidget {
  const SearchScreen({super.key});

  @override
  ConsumerState<SearchScreen> createState() => _SearchScreenState();
}

class _SearchScreenState extends ConsumerState<SearchScreen> {
  final TextEditingController _controller = TextEditingController();

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  /// نسخ نص الآية إلى الحافظة
  void _copyAyah(AyahSearchResult result) {
    final text = '﴿${result.textUthmani}﴾ [سورة ${result.surahName}: ${result.ayahNumber}]';
    Clipboard.setData(ClipboardData(text: text));
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('تم نسخ الآية إلى الحافظة'), duration: Duration(seconds: 2)),
    );
  }

  /// مشاركة الآية عبر التطبيقات
  void _shareAyah(AyahSearchResult result) {
    final text = '﴿${result.textUthmani}﴾\n[سورة ${result.surahName} - الآية ${result.ayahNumber}]';
    SharePlus.instance.share(ShareParams(text: text));
  }

  /// إضافة الآية إلى المفضلة
  Future<void> _bookmarkAyah(AyahSearchResult result) async {
    try {
      await QuranDatabase.instance.insert(
        table: 'bookmarks',
        values: {
          'ayah_id': result.ayahId,
          'note': 'سورة ${result.surahName} آية ${result.ayahNumber}',
          'created_at': DateTime.now().toIso8601String(),
        },
      );
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('تمت إضافة آية (${result.ayahNumber}) سورة ${result.surahName} للمفضلة'),
            backgroundColor: AppTheme.secondaryGold,
            duration: const Duration(seconds: 2),
          ),
        );
      }
    } catch (_) {}
  }

  @override
  Widget build(BuildContext context) {
    final searchState = ref.watch(searchNotifierProvider);
    final uiState = searchState.uiState;

    return Scaffold(
      appBar: AppBar(
        title: const Text('البحث في القرآن الكريم'),
      ),
      body: Column(
        children: [
          // شريط البحث وخيارات التصفية
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Theme.of(context).cardColor,
              border: Border(
                bottom: BorderSide(color: Theme.of(context).dividerColor.withValues(alpha: 0.3)),
              ),
            ),
            child: Column(
              children: [
                TextField(
                  controller: _controller,
                  onChanged: (val) {
                    ref.read(searchNotifierProvider.notifier).onQueryChanged(val);
                  },
                  onSubmitted: (_) {
                    ref.read(searchNotifierProvider.notifier).performSearch();
                  },
                  textInputAction: TextInputAction.search,
                  decoration: InputDecoration(
                    hintText: searchState.isRootSearch
                        ? 'ابحث بالجذر (مثل: علم، حمد، غفر)...'
                        : 'ابحث بالكلمة (مثل: الحمد، يعلمون، الجنة)...',
                    prefixIcon: const Icon(Icons.search, color: AppTheme.primaryEmerald),
                    suffixIcon: _controller.text.isNotEmpty
                        ? IconButton(
                            icon: const Icon(Icons.clear),
                            onPressed: () {
                              _controller.clear();
                              ref.read(searchNotifierProvider.notifier).onQueryChanged('');
                            },
                          )
                        : null,
                  ),
                ),
                const SizedBox(height: 8),

                // خيار التبديل بين البحث بالكلمة والبحث بالجذر
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    FilterChip(
                      selected: searchState.isRootSearch,
                      selectedColor: AppTheme.secondaryGold.withValues(alpha: 0.2),
                      checkmarkColor: AppTheme.secondaryGold,
                      label: const Text('البحث بالجذر اللغوي'),
                      onSelected: (val) {
                        ref.read(searchNotifierProvider.notifier).toggleRootSearch(val);
                      },
                    ),
                    if (searchState.selectedSurahId != null)
                      InputChip(
                        label: Text('سورة رقم ${searchState.selectedSurahId}'),
                        onDeleted: () {
                          ref.read(searchNotifierProvider.notifier).setSurahFilter(null);
                        },
                      ),
                  ],
                ),

                // خيارات الجذور المرشحة وفق TRD مع تمييز المؤكد عن الاقتراح
                if (searchState.isRootSearch && searchState.rootCandidates.isNotEmpty) ...[
                  const SizedBox(height: 10),
                  Row(
                    children: [
                      const Text(
                        'الجذور المحتملة:',
                        style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold),
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: SizedBox(
                          height: 38,
                          child: ListView.separated(
                            scrollDirection: Axis.horizontal,
                            itemCount: searchState.rootCandidates.length,
                            separatorBuilder: (context, index) => const SizedBox(width: 8),
                            itemBuilder: (context, index) {
                              final cand = searchState.rootCandidates[index];
                              final isSelected = searchState.selectedRoot == cand.root;
                              return ChoiceChip(
                                selected: isSelected,
                                selectedColor: cand.isVerified ? AppTheme.primaryEmerald : Colors.amber.shade700,
                                avatar: cand.isVerified
                                    ? null
                                    : Icon(
                                        Icons.help_outline,
                                        size: 16,
                                        color: isSelected ? Colors.white : Colors.amber.shade800,
                                      ),
                                labelStyle: TextStyle(
                                  color: isSelected
                                      ? Colors.white
                                      : (cand.isVerified ? AppTheme.primaryEmerald : Colors.brown),
                                  fontWeight: FontWeight.bold,
                                  fontSize: 12,
                                ),
                                label: Text(
                                  cand.isVerified ? 'جذر: ${cand.root}' : '${cand.root} (اقتراح غير مؤكد)',
                                ),
                                onSelected: (_) {
                                  ref.read(searchNotifierProvider.notifier).selectCandidateRoot(cand.root);
                                },
                              );
                            },
                          ),
                        ),
                      ),
                    ],
                  ),
                  if (searchState.selectedRoot != null) ...[
                    const SizedBox(height: 6),
                    Align(
                      alignment: Alignment.centerLeft,
                      child: TextButton.icon(
                        icon: const Icon(Icons.school_outlined, size: 16, color: AppTheme.secondaryGold),
                        label: Text(
                          'فتح شاشة دراسة الجذر (${searchState.selectedRoot})',
                          style: const TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.bold,
                            color: AppTheme.secondaryGold,
                          ),
                        ),
                        onPressed: () {
                          context.push('/roots/${searchState.selectedRoot}');
                        },
                      ),
                    ),
                  ],
                ],
              ],
            ),
          ),

          // منطقة عرض نتائج البحث
          Expanded(
            child: Builder(
              builder: (context) {
                if (uiState.isInitial) {
                  return _buildInitialView();
                }

                if (uiState.isLoading) {
                  return const Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        CircularProgressIndicator(color: AppTheme.primaryEmerald),
                        SizedBox(height: 16),
                        Text('جاري استعلام آيات القرآن الكريم...'),
                      ],
                    ),
                  );
                }

                if (uiState.isError) {
                  return Center(
                    child: Padding(
                      padding: const EdgeInsets.all(24),
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          const Icon(Icons.error_outline, size: 48, color: Colors.red),
                          const SizedBox(height: 12),
                          Text(uiState.errorMessage ?? 'حدث خطأ أثناء البحث'),
                          const SizedBox(height: 16),
                          ElevatedButton(
                            onPressed: () {
                              ref.read(searchNotifierProvider.notifier).performSearch();
                            },
                            child: const Text('إعادة المحاولة'),
                          ),
                        ],
                      ),
                    ),
                  );
                }

                if (uiState.isEmpty) {
                  return Center(
                    child: Padding(
                      padding: const EdgeInsets.all(24),
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          const Icon(Icons.search_off, size: 56, color: Colors.grey),
                          const SizedBox(height: 16),
                          Text(
                            'لم يتم العثور على آيات تطابق "${searchState.query}"',
                            style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                            textAlign: TextAlign.center,
                          ),
                          const SizedBox(height: 8),
                          const Text(
                            'جرب البحث بكلمة أخرى، أو استخدام الحروف المجردة بدون سوابق ولواحق.',
                            style: TextStyle(fontSize: 13, color: Colors.grey),
                            textAlign: TextAlign.center,
                          ),
                        ],
                      ),
                    ),
                  );
                }

                final results = uiState.data ?? [];
                return ListView.builder(
                  padding: const EdgeInsets.all(16),
                  itemCount: results.length,
                  itemBuilder: (context, index) {
                    final item = results[index];
                    return _buildSearchResultCard(item);
                  },
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  /// واجهة البداية التوجيهية مع نماذج كلمات للبحث السريع
  Widget _buildInitialView() {
    return Center(
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Column(
          children: [
            Icon(
              Icons.manage_search,
              size: 64,
              color: AppTheme.primaryEmerald.withValues(alpha: 0.5),
            ),
            const SizedBox(height: 16),
            const Text(
              'محرك البحث والدراسة القرآنية',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            const Text(
              'اكتب كلمة أو عبارة للبحث المباشر بتشكيل أو دونه، أو فعّل البحث بالجذر للوصول لمشتقات الكلمة وتصريفاتها.',
              textAlign: TextAlign.center,
              style: TextStyle(fontSize: 14, color: Colors.grey, height: 1.5),
            ),
            const SizedBox(height: 24),
            const Text('أمثلة سريعة للبحث:', style: TextStyle(fontWeight: FontWeight.bold)),
            const SizedBox(height: 12),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              alignment: WrapAlignment.center,
              children: ['الحمد', 'يعلمون', 'الجنة', 'الرحمن', 'الصراط', 'غفر'].map((term) {
                return ActionChip(
                  label: Text(term),
                  onPressed: () {
                    _controller.text = term;
                    ref.read(searchNotifierProvider.notifier).onQueryChanged(term);
                    ref.read(searchNotifierProvider.notifier).performSearch();
                  },
                );
              }).toList(),
            ),
          ],
        ),
      ),
    );
  }

  /// بناء بطاقة نتيجة البحث القياسية وفق مواصفات TRD
  Widget _buildSearchResultCard(AyahSearchResult result) {
    return Card(
      margin: const EdgeInsets.only(bottom: 16),
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: BorderSide(
          color: Theme.of(context).dividerColor.withValues(alpha: 0.3),
        ),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // رأس البطاقة: اسم السورة ورقم الآية وشارة المطابقة
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

            // النص القرآني العثماني مع تمييز الكلمات المطابقة لونياً
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

            // الكلمات المطابقة والجذر
            Wrap(
              spacing: 8,
              runSpacing: 4,
              crossAxisAlignment: WrapCrossAlignment.center,
              children: [
                const Text(
                  'الكلمات المطابقة: ',
                  style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold),
                ),
                ...result.matchedWords.map(
                  (w) => Container(
                    padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                    decoration: BoxDecoration(
                      color: AppTheme.secondaryGold.withValues(alpha: 0.15),
                      borderRadius: BorderRadius.circular(4),
                    ),
                    child: Text(
                      w,
                      style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold),
                    ),
                  ),
                ),
                if (result.matchedRoot != null) ...[
                  const SizedBox(width: 8),
                  const Text('الجذر: ', style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold)),
                  InkWell(
                    onTap: () => context.push('/roots/${result.matchedRoot}'),
                    child: Text(
                      result.matchedRoot!,
                      style: const TextStyle(
                        fontSize: 13,
                        color: AppTheme.primaryEmerald,
                        fontWeight: FontWeight.bold,
                        decoration: TextDecoration.underline,
                      ),
                    ),
                  ),
                ],
              ],
            ),
            const SizedBox(height: 16),

            // أزرار الإجراءات السريعة
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
                  onPressed: () => _bookmarkAyah(result),
                ),
                IconButton(
                  icon: const Icon(Icons.copy_outlined, size: 18),
                  tooltip: 'نسخ الآية',
                  onPressed: () => _copyAyah(result),
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
