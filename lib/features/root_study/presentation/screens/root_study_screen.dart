import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:share_plus/share_plus.dart';

import 'package:quranapp/app/theme/app_theme.dart';
import 'package:quranapp/core/database/quran_database.dart';
import 'package:quranapp/core/text/quran_text_utils.dart';
import 'package:quranapp/features/quran_search/domain/entities/ayah_search_result.dart';
import 'package:quranapp/features/root_study/domain/entities/derived_word.dart';
import 'package:quranapp/features/root_study/domain/entities/root_study_data.dart';
import 'package:quranapp/features/root_study/domain/entities/surah_occurrence.dart';
import 'package:quranapp/features/root_study/presentation/controllers/root_study_providers.dart';

/// شاشة دراسة الجذر القرآني (RootStudyScreen) الشاملة وفق متطلبات TRD.
/// تعرض بيانات الجذر، إحصاءات الورود، الكلمات المشتقة، توزيع السور، وجميع مواضع الآيات.
class RootStudyScreen extends ConsumerWidget {
  /// الجذر اللغوي المراد دراسته
  final String root;

  const RootStudyScreen({
    super.key,
    required this.root,
  });

  /// نسخ نص الآية إلى الحافظة
  void _copyAyah(BuildContext context, AyahSearchResult result) {
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
            content: Text('تمت إضافة آية (${result.ayahNumber}) سورة ${result.surahName} للمفضلة'),
            backgroundColor: AppTheme.secondaryGold,
            duration: const Duration(seconds: 2),
          ),
        );
      }
    } catch (_) {}
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(rootStudyNotifierProvider(root));
    final uiState = state.uiState;

    return Scaffold(
      appBar: AppBar(
        title: Text('دراسة الجذر: $root'),
      ),
      body: Builder(
        builder: (context) {
          if (uiState.isLoading) {
            return const Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  CircularProgressIndicator(color: AppTheme.primaryEmerald),
                  SizedBox(height: 16),
                  Text('جاري استخراج بيانات الجذر ومشتقاته...'),
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
                    Text(uiState.errorMessage ?? 'حدث خطأ أثناء تحميل بيانات الجذر'),
                    const SizedBox(height: 16),
                    ElevatedButton(
                      onPressed: () {
                        ref.read(rootStudyNotifierProvider(root).notifier).loadRootData();
                      },
                      child: const Text('إعادة المحاولة'),
                    ),
                  ],
                ),
              ),
            );
          }

          if (uiState.isEmpty || uiState.data == null) {
            return Center(
              child: Padding(
                padding: const EdgeInsets.all(24),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Icon(Icons.search_off, size: 56, color: Colors.grey),
                    const SizedBox(height: 16),
                    Text(
                      'لم يتم العثور على كلمات قرآنية مرتبطة بالجذر "$root"',
                      style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                      textAlign: TextAlign.center,
                    ),
                  ],
                ),
              ),
            );
          }

          final data = uiState.data!;
          return _buildContent(context, ref, state, data);
        },
      ),
    );
  }

  /// بناء المحتوى التفاعلي الرئيسي لشاشة دراسة الجذر
  Widget _buildContent(
    BuildContext context,
    WidgetRef ref,
    RootStudyState state,
    RootStudyData data,
  ) {
    return DefaultTabController(
      length: 3,
      child: Column(
        children: [
          // بطاقة معلومات الجذر الأساسية والإحصاءات
          _buildHeaderCard(context, data),

          // شريط الفلاتر النشطة (إن وُجد فلتر سورة أو كلمة مشتقة)
          if (state.selectedWordNormalized != null || state.selectedSurahId != null)
            _buildActiveFiltersBar(context, ref, state),

          // شريط التبويبات الثلاثة
          Container(
            color: Theme.of(context).cardColor,
            child: TabBar(
              indicatorColor: AppTheme.primaryEmerald,
              labelColor: AppTheme.primaryEmerald,
              unselectedLabelColor: Colors.grey,
              labelStyle: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13),
              tabs: [
                Tab(
                  icon: const Icon(Icons.format_list_numbered, size: 20),
                  text: 'الآيات والمواضع (${data.verses.length})',
                ),
                Tab(
                  icon: const Icon(Icons.category_outlined, size: 20),
                  text: 'الكلمات المشتقة (${data.derivedWords.length})',
                ),
                Tab(
                  icon: const Icon(Icons.pie_chart_outline, size: 20),
                  text: 'توزيع السور (${data.surahOccurrences.length})',
                ),
              ],
            ),
          ),

          // محتوى التبويبات
          Expanded(
            child: TabBarView(
              children: [
                // التبويب 1: قائمة الآيات
                _buildVersesList(context, ref, data.verses),

                // التبويب 2: قائمة الكلمات المشتقة وتكرارها
                _buildDerivedWordsTab(context, ref, state, data.derivedWords),

                // التبويب 3: توزيع السور وتكرارها
                _buildSurahDistributionTab(context, ref, state, data.surahOccurrences),
              ],
            ),
          ),
        ],
      ),
    );
  }

  /// بطاقة رأس دراسة الجذر مع الإحصاءات الثلاثية
  Widget _buildHeaderCard(BuildContext context, RootStudyData data) {
    return Container(
      padding: const EdgeInsets.all(16),
      margin: const EdgeInsets.fromLTRB(16, 12, 16, 8),
      decoration: BoxDecoration(
        color: AppTheme.primaryEmerald.withValues(alpha: 0.07),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppTheme.primaryEmerald.withValues(alpha: 0.2)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: AppTheme.primaryEmerald,
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: const Icon(Icons.account_tree, color: Colors.white, size: 24),
                  ),
                  const SizedBox(width: 12),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'الجذر القرآني: ${data.root.root}',
                        style: const TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                          color: AppTheme.primaryEmerald,
                        ),
                      ),
                      if (data.root.descriptionAr != null && data.root.descriptionAr!.isNotEmpty)
                        Text(
                          data.root.descriptionAr!,
                          style: const TextStyle(fontSize: 12, color: Colors.grey),
                        ),
                    ],
                  ),
                ],
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  color: AppTheme.secondaryGold.withValues(alpha: 0.15),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: AppTheme.secondaryGold.withValues(alpha: 0.4)),
                ),
                child: const Text(
                  'جذر صرفي موثق',
                  style: TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.bold,
                    color: AppTheme.secondaryGold,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),

          // صف الإحصاءات الثلاثية
          Row(
            children: [
              _buildStatBox(
                context,
                title: 'إجمالي الورود',
                value: '${data.totalOccurrences}',
                subtitle: 'مرة في القرآن',
                icon: Icons.repeat,
              ),
              const SizedBox(width: 8),
              _buildStatBox(
                context,
                title: 'الكلمات المشتقة',
                value: '${data.uniqueWordsCount}',
                subtitle: 'صيغة وكلمة',
                icon: Icons.auto_stories,
              ),
              const SizedBox(width: 8),
              _buildStatBox(
                context,
                title: 'السور القرآنية',
                value: '${data.surahsCount}',
                subtitle: 'سورة مختلفة',
                icon: Icons.menu_book,
              ),
            ],
          ),
        ],
      ),
    );
  }

  /// مربع إحصائي فردي
  Widget _buildStatBox(
    BuildContext context, {
    required String title,
    required String value,
    required String subtitle,
    required IconData icon,
  }) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 8),
        decoration: BoxDecoration(
          color: Theme.of(context).cardColor,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: Theme.of(context).dividerColor.withValues(alpha: 0.3)),
        ),
        child: Column(
          children: [
            Icon(icon, size: 18, color: AppTheme.primaryEmerald),
            const SizedBox(height: 4),
            Text(
              value,
              style: const TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: AppTheme.primaryEmerald,
              ),
            ),
            Text(
              title,
              style: const TextStyle(fontSize: 11, fontWeight: FontWeight.bold),
              textAlign: TextAlign.center,
            ),
            Text(
              subtitle,
              style: const TextStyle(fontSize: 10, color: Colors.grey),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }

  /// شريط الفلاتر النشطة مع زر الإلغاء
  Widget _buildActiveFiltersBar(BuildContext context, WidgetRef ref, RootStudyState state) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
      color: AppTheme.secondaryGold.withValues(alpha: 0.12),
      child: Row(
        children: [
          const Icon(Icons.filter_alt, size: 16, color: AppTheme.secondaryGold),
          const SizedBox(width: 6),
          const Text(
            'تصفية مفعلة:',
            style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold),
          ),
          const SizedBox(width: 8),
          if (state.selectedWordUthmani != null)
            Padding(
              padding: const EdgeInsets.only(left: 4),
              child: Chip(
                label: Text('الكلمة: ${state.selectedWordUthmani}', style: const TextStyle(fontSize: 11)),
                onDeleted: () {
                  ref.read(rootStudyNotifierProvider(root).notifier).filterByWord(
                        wordNormalized: state.selectedWordNormalized!,
                        wordUthmani: state.selectedWordUthmani!,
                      );
                },
              ),
            ),
          if (state.selectedSurahName != null)
            Padding(
              padding: const EdgeInsets.only(left: 4),
              child: Chip(
                label: Text('سورة ${state.selectedSurahName}', style: const TextStyle(fontSize: 11)),
                onDeleted: () {
                  ref.read(rootStudyNotifierProvider(root).notifier).filterBySurah(
                        surahId: state.selectedSurahId!,
                        surahName: state.selectedSurahName!,
                      );
                },
              ),
            ),
          const Spacer(),
          TextButton(
            onPressed: () {
              ref.read(rootStudyNotifierProvider(root).notifier).clearFilters();
            },
            child: const Text('مسح الكل', style: TextStyle(fontSize: 12)),
          ),
        ],
      ),
    );
  }

  /// قائمة الآيات ومواضع الورود
  Widget _buildVersesList(BuildContext context, WidgetRef ref, List<AyahSearchResult> verses) {
    if (verses.isEmpty) {
      return const Center(
        child: Padding(
          padding: EdgeInsets.all(24),
          child: Text('لا توجد آيات تطابق الفلتر المحدد'),
        ),
      );
    }

    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: verses.length,
      itemBuilder: (context, index) {
        final item = verses[index];
        return _buildAyahCard(context, item);
      },
    );
  }

  /// بطاقة الآية القرآنية المعروضة
  Widget _buildAyahCard(BuildContext context, AyahSearchResult item) {
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(14),
        side: BorderSide(color: Theme.of(context).dividerColor.withValues(alpha: 0.3)),
      ),
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // اسم السورة ورقم الآية
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'سورة ${item.surahName} - الآية ${item.ayahNumber}',
                  style: const TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 14,
                    color: AppTheme.primaryEmerald,
                  ),
                ),
                Text(
                  'آية ${item.ayahNumber}',
                  style: const TextStyle(fontSize: 12, color: Colors.grey),
                ),
              ],
            ),
            const Divider(height: 16),

            // نص الآية العثماني مع تظليل كلمات الجذر المشتقة
            RichText(
              text: TextSpan(
                children: QuranTextUtils.highlightMatchedWords(
                  textUthmani: item.textUthmani,
                  matchedWords: item.matchedWords,
                  defaultStyle: TextStyle(
                    fontSize: 17,
                    height: 2.0,
                    fontWeight: FontWeight.w500,
                    color: Theme.of(context).textTheme.bodyLarge?.color,
                  ),
                ),
              ),
              textAlign: TextAlign.right,
            ),
            const SizedBox(height: 10),

            // أزرار الإجراءات
            Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                TextButton.icon(
                  icon: const Icon(Icons.import_contacts, size: 16),
                  label: const Text('المصحف', style: TextStyle(fontSize: 12)),
                  onPressed: () {
                    context.push('/reader/${item.surahId}?ayah=${item.ayahNumber}');
                  },
                ),
                TextButton.icon(
                  icon: const Icon(Icons.layers_outlined, size: 16),
                  label: const Text('السياق', style: TextStyle(fontSize: 12)),
                  onPressed: () {
                    context.push('/context?before=2&after=2');
                  },
                ),
                IconButton(
                  icon: const Icon(Icons.star_border, size: 18),
                  tooltip: 'المفضلة',
                  onPressed: () => _bookmarkAyah(context, item),
                ),
                IconButton(
                  icon: const Icon(Icons.copy_outlined, size: 16),
                  tooltip: 'نسخ',
                  onPressed: () => _copyAyah(context, item),
                ),
                IconButton(
                  icon: const Icon(Icons.share_outlined, size: 16),
                  tooltip: 'مشاركة',
                  onPressed: () => _shareAyah(item),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  /// تبويب الكلمات المشتقة وتكراراتها
  Widget _buildDerivedWordsTab(
    BuildContext context,
    WidgetRef ref,
    RootStudyState state,
    List<DerivedWord> derivedWords,
  ) {
    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: derivedWords.length,
      itemBuilder: (context, index) {
        final item = derivedWords[index];
        final isSelected = state.selectedWordNormalized == item.wordNormalized;

        return Card(
          margin: const EdgeInsets.only(bottom: 8),
          color: isSelected ? AppTheme.primaryEmerald.withValues(alpha: 0.1) : null,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
            side: BorderSide(
              color: isSelected
                  ? AppTheme.primaryEmerald
                  : Theme.of(context).dividerColor.withValues(alpha: 0.3),
              width: isSelected ? 1.5 : 1.0,
            ),
          ),
          child: ListTile(
            title: Text(
              item.wordUthmani,
              style: const TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                fontFamily: 'Amiri',
              ),
            ),
            subtitle: Text('الصيغة المطبّعة: ${item.wordNormalized}'),
            trailing: Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
              decoration: BoxDecoration(
                color: isSelected ? AppTheme.primaryEmerald : AppTheme.secondaryGold.withValues(alpha: 0.15),
                borderRadius: BorderRadius.circular(16),
              ),
              child: Text(
                'وردت ${item.occurrenceCount} مرة',
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.bold,
                  color: isSelected ? Colors.white : AppTheme.secondaryGold,
                ),
              ),
            ),
            onTap: () {
              ref.read(rootStudyNotifierProvider(root).notifier).filterByWord(
                    wordNormalized: item.wordNormalized,
                    wordUthmani: item.wordUthmani,
                  );
            },
          ),
        );
      },
    );
  }

  /// تبويب توزيع السور وتكرار الورود في كل سورة
  Widget _buildSurahDistributionTab(
    BuildContext context,
    WidgetRef ref,
    RootStudyState state,
    List<SurahOccurrence> surahOccurrences,
  ) {
    final maxCount = surahOccurrences.isNotEmpty
        ? surahOccurrences.map((s) => s.occurrenceCount).reduce((a, b) => a > b ? a : b)
        : 1;

    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: surahOccurrences.length,
      itemBuilder: (context, index) {
        final item = surahOccurrences[index];
        final isSelected = state.selectedSurahId == item.surahId;
        final fraction = (item.occurrenceCount / maxCount).clamp(0.05, 1.0);

        return Card(
          margin: const EdgeInsets.only(bottom: 8),
          color: isSelected ? AppTheme.primaryEmerald.withValues(alpha: 0.1) : null,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
            side: BorderSide(
              color: isSelected
                  ? AppTheme.primaryEmerald
                  : Theme.of(context).dividerColor.withValues(alpha: 0.3),
              width: isSelected ? 1.5 : 1.0,
            ),
          ),
          child: InkWell(
            borderRadius: BorderRadius.circular(12),
            onTap: () {
              ref.read(rootStudyNotifierProvider(root).notifier).filterBySurah(
                    surahId: item.surahId,
                    surahName: item.surahName,
                  );
            },
            child: Padding(
              padding: const EdgeInsets.all(12),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        'سورة ${item.surahName}',
                        style: const TextStyle(fontSize: 15, fontWeight: FontWeight.bold),
                      ),
                      Text(
                        '${item.occurrenceCount} مواضع',
                        style: const TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.bold,
                          color: AppTheme.primaryEmerald,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  ClipRRect(
                    borderRadius: BorderRadius.circular(4),
                    child: LinearProgressIndicator(
                      value: fraction,
                      minHeight: 6,
                      backgroundColor: Theme.of(context).dividerColor.withValues(alpha: 0.2),
                      valueColor: AlwaysStoppedAnimation<Color>(
                        isSelected ? AppTheme.primaryEmerald : AppTheme.secondaryGold,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }
}
