import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:quranapp/app/theme/app_theme.dart';
import 'package:quranapp/features/quran_reader/presentation/controllers/quran_providers.dart';
import 'package:quranapp/features/quran_search/domain/entities/quran_word.dart';
import 'package:quranapp/features/vocabulary/domain/entities/word_filter_criteria.dart';
import 'package:quranapp/features/vocabulary/presentation/controllers/words_management_providers.dart';
import 'package:quranapp/features/vocabulary/presentation/widgets/edit_word_dialog.dart';
import 'package:quranapp/features/vocabulary/presentation/widgets/relink_word_dialog.dart';
import 'package:quranapp/features/vocabulary/presentation/widgets/lexicon_export_import_dialog.dart';

/// شاشة معجم وإدارة وتصحيح الكلمات والمفردات القرآنية (Words Management Screen).
class WordsManagementScreen extends ConsumerStatefulWidget {
  /// جذر اختياري لبدء الشاشة بفلترة كلماته مباشرة
  final String? initialRoot;

  const WordsManagementScreen({
    super.key,
    this.initialRoot,
  });

  @override
  ConsumerState<WordsManagementScreen> createState() => _WordsManagementScreenState();
}

class _WordsManagementScreenState extends ConsumerState<WordsManagementScreen> {
  final ScrollController _scrollController = ScrollController();
  final TextEditingController _searchController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _scrollController.addListener(_onScroll);
  }

  void _onScroll() {
    if (_scrollController.position.pixels >= _scrollController.position.maxScrollExtent - 200) {
      ref.read(wordsManagementNotifierProvider(widget.initialRoot).notifier).loadMore();
    }
  }

  @override
  void dispose() {
    _scrollController.dispose();
    _searchController.dispose();
    super.dispose();
  }

  void _openSurahFilterModal() {
    final surahs = ref.read(surahListNotifierProvider).uiState.data ?? [];
    final currentSurahId = ref.read(wordsManagementNotifierProvider(widget.initialRoot)).criteria.surahId;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (ctx) {
        return DraggableScrollableSheet(
          initialChildSize: 0.7,
          minChildSize: 0.4,
          maxChildSize: 0.9,
          expand: false,
          builder: (context, scrollController) {
            return Column(
              children: [
                Padding(
                  padding: const EdgeInsets.all(16),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text(
                        'اختر سورة للتصفية',
                        style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                      ),
                      if (currentSurahId != null)
                        TextButton(
                          onPressed: () {
                            ref
                                .read(wordsManagementNotifierProvider(widget.initialRoot).notifier)
                                .filterBySurah(null, null);
                            Navigator.of(ctx).pop();
                          },
                          child: const Text('إلغاء الفلترة'),
                        ),
                    ],
                  ),
                ),
                const Divider(height: 1),
                Expanded(
                  child: ListView.builder(
                    controller: scrollController,
                    itemCount: surahs.length,
                    itemBuilder: (context, index) {
                      final surah = surahs[index];
                      final isSelected = surah.id == currentSurahId;

                      return ListTile(
                        leading: CircleAvatar(
                          backgroundColor: isSelected
                              ? AppTheme.primaryEmerald
                              : AppTheme.primaryEmerald.withValues(alpha: 0.1),
                          foregroundColor: isSelected ? Colors.white : AppTheme.primaryEmerald,
                          child: Text('${surah.id}', style: const TextStyle(fontSize: 12)),
                        ),
                        title: Text(
                          surah.nameArabic,
                          style: TextStyle(
                            fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                          ),
                        ),
                        subtitle: Text('عدد آياتها: ${surah.ayahCount}'),
                        trailing: isSelected
                            ? const Icon(Icons.check, color: AppTheme.primaryEmerald)
                            : null,
                        onTap: () {
                          ref
                              .read(wordsManagementNotifierProvider(widget.initialRoot).notifier)
                              .filterBySurah(surah.id, surah.nameArabic);
                          Navigator.of(ctx).pop();
                        },
                      );
                    },
                  ),
                ),
              ],
            );
          },
        );
      },
    );
  }

  void _openRelinkDialog(QuranWord word) {
    showDialog<int>(
      context: context,
      builder: (ctx) => RelinkWordDialog(
        word: word,
        onRelink: ({required String newRoot, required bool applyToAll}) {
          return ref
              .read(wordsManagementNotifierProvider(widget.initialRoot).notifier)
              .relinkWord(
                wordId: word.id,
                newRoot: newRoot,
                applyToAll: applyToAll,
              );
        },
      ),
    ).then((updatedCount) {
      if (updatedCount != null && mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              updatedCount > 1
                  ? 'تم تحديث وربط $updatedCount موضعاً في القرآن الكريم بنجاح'
                  : 'تم إعادة ربط الكلمة بالجذر بنجاح',
            ),
            backgroundColor: AppTheme.primaryEmerald,
          ),
        );
      }
    });
  }

  void _openEditDialog(QuranWord word) {
    showDialog<bool>(
      context: context,
      builder: (ctx) => EditWordDialog(
        word: word,
        onSave: ({
          required int wordId,
          required String wordUthmani,
          String? lemma,
          String? prefix,
          String? stem,
          String? suffix,
          String? partOfSpeech,
          String? morphology,
        }) {
          return ref
              .read(wordsManagementNotifierProvider(widget.initialRoot).notifier)
              .updateWordDetails(
                wordId: wordId,
                wordUthmani: wordUthmani,
                lemma: lemma,
                prefix: prefix,
                stem: stem,
                suffix: suffix,
                partOfSpeech: partOfSpeech,
                morphology: morphology,
              );
        },
      ),
    ).then((result) {
      if (result == true && mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('تم حفظ وتحديث تفاصيل الكلمة بنجاح'),
            backgroundColor: AppTheme.primaryEmerald,
          ),
        );
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(wordsManagementNotifierProvider(widget.initialRoot));
    final notifier = ref.read(wordsManagementNotifierProvider(widget.initialRoot).notifier);

    return Scaffold(
      appBar: AppBar(
        title: const Text('معجم وإدارة الكلمات القرآنية'),
        actions: [
          IconButton(
            icon: const Icon(Icons.rule_folder_outlined),
            tooltip: 'لوحة التدقيق الصرفي الجماعي',
            onPressed: () => context.push('/morphology-audit'),
          ),
          IconButton(
            icon: const Icon(Icons.sync_alt),
            tooltip: 'تصدير واستيراد تصحيحات المعجم',
            onPressed: () => LexiconExportImportDialog.show(
              context,
              onImportSuccess: () => notifier.loadWords(refresh: true),
            ),
          ),
          IconButton(
            icon: const Icon(Icons.refresh),
            tooltip: 'تحديث الكلمات',
            onPressed: () => notifier.loadWords(refresh: true),
          ),
        ],
      ),
      body: Column(
        children: [
          // شريط البحث
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 8),
            child: TextField(
              controller: _searchController,
              decoration: InputDecoration(
                hintText: 'ابحث بالكلمة القرآنية أو أصلها...',
                prefixIcon: const Icon(Icons.search),
                suffixIcon: _searchController.text.isNotEmpty
                    ? IconButton(
                        icon: const Icon(Icons.clear),
                        onPressed: () {
                          _searchController.clear();
                          notifier.search('');
                        },
                      )
                    : null,
                filled: true,
                fillColor: Theme.of(context).brightness == Brightness.light
                    ? AppTheme.lightCard
                    : AppTheme.darkCard,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(16),
                  borderSide: BorderSide.none,
                ),
                contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
              ),
              onChanged: notifier.search,
            ),
          ),

          // شرائح الفلاتر (السورة، حالة الجذر)
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
            child: Row(
              children: [
                // فلتر السورة
                FilterChip(
                  avatar: const Icon(Icons.menu_book, size: 16),
                  label: Text(state.selectedSurahName != null
                      ? 'سورة: ${state.selectedSurahName}'
                      : 'تصفية بالسورة'),
                  selected: state.criteria.surahId != null,
                  onSelected: (_) => _openSurahFilterModal(),
                ),
                const SizedBox(width: 8),

                // فلتر الجذر المحدد (إن وجد)
                if (state.criteria.specificRoot != null) ...[
                  InputChip(
                    avatar: const Icon(Icons.account_tree, size: 16),
                    label: Text('الجذر: ${state.criteria.specificRoot}'),
                    selected: true,
                    onDeleted: () {
                      notifier.filterByRootStatus(WordRootStatus.all);
                    },
                  ),
                  const SizedBox(width: 8),
                ],

                // فلتر الكلمات غير المربوطة بجذر
                ChoiceChip(
                  avatar: const Icon(Icons.link_off, size: 16),
                  label: const Text('غير مربوطة بجذر'),
                  selected: state.criteria.rootStatus == WordRootStatus.withoutRoot,
                  onSelected: (val) {
                    notifier.filterByRootStatus(
                      val ? WordRootStatus.withoutRoot : WordRootStatus.all,
                    );
                  },
                ),
                const SizedBox(width: 8),

                // فلتر الكلمات المرتبطة بجذر
                ChoiceChip(
                  avatar: const Icon(Icons.link, size: 16),
                  label: const Text('مرتبطة بجذر'),
                  selected: state.criteria.rootStatus == WordRootStatus.withRoot,
                  onSelected: (val) {
                    notifier.filterByRootStatus(
                      val ? WordRootStatus.withRoot : WordRootStatus.all,
                    );
                  },
                ),
              ],
            ),
          ),

          // شريط الإحصائيات
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'إجمالي الكلمات المطابقة: ${state.totalCount}',
                  style: TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.bold,
                    color: Theme.of(context).colorScheme.primary,
                  ),
                ),
                if (state.uiState.data != null)
                  Text(
                    'معروض: ${state.uiState.data!.length}',
                    style: TextStyle(
                      fontSize: 12,
                      color: Theme.of(context).textTheme.bodySmall?.color,
                    ),
                  ),
              ],
            ),
          ),
          const Divider(height: 1),

          // قائمة الكلمات
          Expanded(
            child: state.uiState.when(
              initial: () => const Center(child: CircularProgressIndicator()),
              loading: () => const Center(child: CircularProgressIndicator()),
              empty: () => Center(
                child: Padding(
                  padding: const EdgeInsets.all(24),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.search_off, size: 64, color: Colors.grey.withValues(alpha: 0.5)),
                      const SizedBox(height: 16),
                      const Text(
                        'لا توجد كلمات مطابقة لمعايير البحث',
                        style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                      ),
                      const SizedBox(height: 8),
                      const Text(
                        'جرب تعديل عبارة البحث أو تغيير فلتر السورة أو حالة الجذر.',
                        textAlign: TextAlign.center,
                        style: TextStyle(fontSize: 14, color: Colors.grey),
                      ),
                    ],
                  ),
                ),
              ),
              error: (msg) => Center(
                child: Padding(
                  padding: const EdgeInsets.all(24),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Icon(Icons.error_outline, size: 48, color: Colors.red),
                      const SizedBox(height: 12),
                      Text(msg, textAlign: TextAlign.center),
                      const SizedBox(height: 16),
                      ElevatedButton(
                        onPressed: () => notifier.loadWords(refresh: true),
                        child: const Text('إعادة المحاولة'),
                      ),
                    ],
                  ),
                ),
              ),
              success: (words) => RefreshIndicator(
                onRefresh: () => notifier.loadWords(refresh: true),
                child: ListView.separated(
                  controller: _scrollController,
                  padding: const EdgeInsets.fromLTRB(16, 12, 16, 40),
                  itemCount: words.length + (state.isLoadingMore ? 1 : 0),
                  separatorBuilder: (_, _) => const SizedBox(height: 12),
                  itemBuilder: (context, index) {
                    if (index >= words.length) {
                      return const Padding(
                        padding: EdgeInsets.symmetric(vertical: 24),
                        child: Center(child: CircularProgressIndicator()),
                      );
                    }
                    final word = words[index];
                    return _buildWordCard(context, word);
                  },
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildWordCard(BuildContext context, QuranWord word) {
    final hasRoot = word.root != null && word.root!.trim().isNotEmpty;

    return Card(
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: BorderSide(
          color: Theme.of(context).dividerColor.withValues(alpha: 0.15),
          width: 1,
        ),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // السورة والآية وموضع الكلمة
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Row(
                  children: [
                    const Icon(Icons.auto_stories, size: 16, color: AppTheme.secondaryGold),
                    const SizedBox(width: 6),
                    Text(
                      '${word.surahName ?? 'سورة ${word.surahId}'} - آية ${word.ayahNumber}',
                      style: const TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.bold,
                        color: AppTheme.secondaryGold,
                      ),
                    ),
                  ],
                ),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                  decoration: BoxDecoration(
                    color: Theme.of(context).dividerColor.withValues(alpha: 0.2),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Text(
                    'الكلمة ${word.wordPosition}',
                    style: const TextStyle(fontSize: 11, fontWeight: FontWeight.bold),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),

            // الكلمة بالرسم العثماني وشارة الجذر
            Row(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                Expanded(
                  child: Text(
                    word.wordUthmani,
                    style: const TextStyle(
                      fontSize: 26,
                      fontWeight: FontWeight.bold,
                      color: AppTheme.primaryEmerald,
                    ),
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                  decoration: BoxDecoration(
                    color: hasRoot
                        ? AppTheme.primaryEmerald.withValues(alpha: 0.1)
                        : Colors.red.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(
                      color: hasRoot
                          ? AppTheme.primaryEmerald.withValues(alpha: 0.3)
                          : Colors.red.withValues(alpha: 0.3),
                    ),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(
                        hasRoot ? Icons.account_tree : Icons.link_off,
                        size: 14,
                        color: hasRoot ? AppTheme.primaryEmerald : Colors.red,
                      ),
                      const SizedBox(width: 6),
                      Text(
                        hasRoot ? 'الجذر: ${word.root}' : 'غير مربوط بجذر',
                        style: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.bold,
                          color: hasRoot ? AppTheme.primaryEmerald : Colors.red,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),

            // اللفظ المجرد ونوع الكلمة والتحليل
            Wrap(
              spacing: 8,
              runSpacing: 4,
              children: [
                if (word.lemma != null && word.lemma!.isNotEmpty)
                  _buildMetaTag(context, 'الأصل', word.lemma!),
                if (word.partOfSpeech != null && word.partOfSpeech!.isNotEmpty)
                  _buildMetaTag(context, 'النوع', word.partOfSpeech!),
                if (word.stem != null && word.stem!.isNotEmpty)
                  _buildMetaTag(context, 'الجذع', word.stem!),
              ],
            ),
            if (word.morphology != null && word.morphology!.isNotEmpty) ...[
              const SizedBox(height: 8),
              Text(
                'التحليل: ${word.morphology}',
                style: TextStyle(
                  fontSize: 12,
                  color: Theme.of(context).textTheme.bodySmall?.color,
                ),
              ),
            ],
            const SizedBox(height: 14),

            // أزرار العمليات
            Row(
              children: [
                // زر إعادة ربط الكلمة بالجذر
                Expanded(
                  child: ElevatedButton.icon(
                    onPressed: () => _openRelinkDialog(word),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppTheme.primaryEmerald,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(vertical: 8),
                    ),
                    icon: const Icon(Icons.alt_route, size: 16),
                    label: const Text('إعادة ربط بالجذر', style: TextStyle(fontSize: 12)),
                  ),
                ),
                const SizedBox(width: 8),

                // زر تعديل بيانات الكلمة
                OutlinedButton.icon(
                  onPressed: () => _openEditDialog(word),
                  style: OutlinedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 12),
                  ),
                  icon: const Icon(Icons.edit_note, size: 16),
                  label: const Text('تعديل', style: TextStyle(fontSize: 12)),
                ),
                const SizedBox(width: 8),

                // زر الانتقال للمصحف
                IconButton(
                  tooltip: 'عرض الآية في المصحف',
                  icon: const Icon(Icons.menu_book_outlined, size: 20),
                  onPressed: () {
                    context.push('/reader/${word.surahId}?ayah=${word.ayahNumber}');
                  },
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildMetaTag(BuildContext context, String label, String value) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color: Theme.of(context).dividerColor.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(6),
      ),
      child: Text(
        '$label: $value',
        style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w600),
      ),
    );
  }
}
