import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:quranapp/app/theme/app_theme.dart';
import 'package:quranapp/features/quran_reader/presentation/controllers/quran_providers.dart';
import 'package:quranapp/features/vocabulary/domain/entities/morphology_audit_stats.dart';
import 'package:quranapp/features/vocabulary/presentation/controllers/morphology_audit_providers.dart';

/// شاشة التدقيق الصرفي والمعجمي الجماعي (Batch Morphology Auditing Dashboard).
/// توفر لوحة إحصائية لرصد الكلمات غير المحللة أو غير المربوطة وتتيح تحديدها وربطها بالجذور دفعة واحدة.
class MorphologyAuditScreen extends ConsumerStatefulWidget {
  const MorphologyAuditScreen({super.key});

  @override
  ConsumerState<MorphologyAuditScreen> createState() => _MorphologyAuditScreenState();
}

class _MorphologyAuditScreenState extends ConsumerState<MorphologyAuditScreen> {
  final TextEditingController _searchController = TextEditingController();
  final ScrollController _scrollController = ScrollController();

  @override
  void initState() {
    super.initState();
    _scrollController.addListener(_onScroll);
  }

  @override
  void dispose() {
    _searchController.dispose();
    _scrollController.removeListener(_onScroll);
    _scrollController.dispose();
    super.dispose();
  }

  void _onScroll() {
    if (_scrollController.position.pixels >= _scrollController.position.maxScrollExtent - 200) {
      ref.read(morphologyAuditNotifierProvider.notifier).loadMore();
    }
  }

  void _openSurahFilterModal() {
    final surahs = ref.read(surahListNotifierProvider).uiState.data ?? [];
    final currentSurahId = ref.read(morphologyAuditNotifierProvider).selectedSurahId;

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
                        'تصفية حسب السورة',
                        style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                      ),
                      if (currentSurahId != null)
                        TextButton(
                          onPressed: () {
                            ref
                                .read(morphologyAuditNotifierProvider.notifier)
                                .filterBySurah(null, null);
                            Navigator.of(ctx).pop();
                          },
                          child: const Text('إلغاء التصفية'),
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
                        trailing: isSelected
                            ? const Icon(Icons.check, color: AppTheme.primaryEmerald)
                            : null,
                        onTap: () {
                          ref
                              .read(morphologyAuditNotifierProvider.notifier)
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

  void _openBatchRelinkDialog(int selectedCount) {
    final rootController = TextEditingController();
    bool applyToAll = true;

    showDialog<bool>(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (context, setDialogState) {
          return AlertDialog(
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
            title: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: AppTheme.primaryEmerald.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: const Icon(Icons.link, color: AppTheme.primaryEmerald),
                ),
                const SizedBox(width: 10),
                const Expanded(
                  child: Text(
                    'ربط جماعي بالجذر',
                    style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                  ),
                ),
              ],
            ),
            content: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'سيتم ربط عدد ($selectedCount) كلمة مختارة بالجذر المحدد.',
                  style: const TextStyle(fontSize: 13, color: Colors.grey),
                ),
                const SizedBox(height: 16),
                TextField(
                  controller: rootController,
                  autofocus: true,
                  decoration: InputDecoration(
                    labelText: 'الجذر اللغوي المستهدف',
                    hintText: 'مثال: علم، كتب، نزل...',
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                    prefixIcon: const Icon(Icons.spa_outlined),
                  ),
                ),
                const SizedBox(height: 12),
                CheckboxListTile(
                  contentPadding: EdgeInsets.zero,
                  title: const Text(
                    'تطبيق على جميع مواضع هذه الكلمات في المصحف',
                    style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600),
                  ),
                  subtitle: const Text(
                    'تحديث كل تكرارات الكلمة المطابقة في عموم القرآن',
                    style: TextStyle(fontSize: 11),
                  ),
                  value: applyToAll,
                  activeColor: AppTheme.primaryEmerald,
                  onChanged: (val) {
                    setDialogState(() {
                      applyToAll = val ?? true;
                    });
                  },
                ),
              ],
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.of(ctx).pop(false),
                child: const Text('إلغاء'),
              ),
              ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppTheme.primaryEmerald,
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                ),
                onPressed: () async {
                  final text = rootController.text.trim();
                  if (text.isEmpty) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                        content: Text('الرجاء إدخال الجذر اللغوي'),
                        backgroundColor: Colors.orange,
                      ),
                    );
                    return;
                  }
                  final messenger = ScaffoldMessenger.of(context);
                  Navigator.of(ctx).pop(true);

                  final affected = await ref
                      .read(morphologyAuditNotifierProvider.notifier)
                      .batchRelink(newRoot: text, applyToAll: applyToAll);

                  if (mounted) {
                    messenger.showSnackBar(
                      SnackBar(
                        content: Text('تم ربط $affected موضعاً بالجذر "$text" بنجاح'),
                        backgroundColor: AppTheme.primaryEmerald,
                        duration: const Duration(seconds: 3),
                      ),
                    );
                  }
                },
                child: const Text('تأكيد وربط الكلمات'),
              ),
            ],
          );
        },
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(morphologyAuditNotifierProvider);
    final notifier = ref.read(morphologyAuditNotifierProvider.notifier);
    final selectedCount = state.selectedWordIds.length;

    return Scaffold(
      appBar: AppBar(
        title: const Text('التدقيق الصرفي الجماعي'),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            tooltip: 'تحديث البيانات',
            onPressed: () {
              notifier.loadStats();
              notifier.loadItems(refresh: true);
            },
          ),
        ],
      ),
      bottomNavigationBar: selectedCount > 0
          ? _buildBatchActionBar(context, selectedCount, notifier)
          : null,
      body: Column(
        children: [
          // لوحة إحصاءات التدقيق الصرفي والمعجمي
          if (state.stats != null) _buildStatsCard(context, state.stats!),

          // شريط التبديل والفلترة والبحث
          _buildFilterBar(context, state, notifier),

          // شريط تحديد الكل ومعلومات النتائج
          _buildSelectionSummaryBar(context, state, notifier),

          // قائمة الكلمات قيد التدقيق
          Expanded(
            child: _buildItemsList(context, state, notifier),
          ),
        ],
      ),
    );
  }

  /// بطاقة الإحصاءات العامة والمؤشرات الرئيسية
  Widget _buildStatsCard(BuildContext context, MorphologyAuditStats stats) {
    return Container(
      margin: const EdgeInsets.fromLTRB(16, 12, 16, 8),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            AppTheme.primaryEmerald,
            AppTheme.primaryEmerald.withValues(alpha: 0.85),
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: AppTheme.primaryEmerald.withValues(alpha: 0.25),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'لوحة التدقيق والربط المعجمي',
                    style: TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.bold),
                  ),
                  Text(
                    'رصد وتصنيف مفردات القرآن الكريم الشريف',
                    style: TextStyle(color: Colors.white70, fontSize: 11),
                  ),
                ],
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                decoration: BoxDecoration(
                  color: AppTheme.secondaryGold,
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Text(
                  'تغطية الجذور: ${stats.rootCoveragePercentage.toStringAsFixed(1)}%',
                  style: const TextStyle(
                    color: Colors.black87,
                    fontWeight: FontWeight.bold,
                    fontSize: 12,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),
          Row(
            children: [
              Expanded(
                child: _buildMiniStat(
                  title: 'إجمالي الكلمات',
                  value: '${stats.totalWords}',
                  icon: Icons.auto_stories,
                ),
              ),
              Expanded(
                child: _buildMiniStat(
                  title: 'مرتبطة بجذر',
                  value: '${stats.wordsWithRoot}',
                  icon: Icons.check_circle_outline,
                ),
              ),
              Expanded(
                child: _buildMiniStat(
                  title: 'تحتاج ربطاً',
                  value: '${stats.wordsWithoutRoot}',
                  icon: Icons.help_outline,
                  highlight: true,
                ),
              ),
              Expanded(
                child: _buildMiniStat(
                  title: 'الجذور المسجلة',
                  value: '${stats.totalUniqueRoots}',
                  icon: Icons.spa_outlined,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildMiniStat({
    required String title,
    required String value,
    required IconData icon,
    bool highlight = false,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 6),
      decoration: BoxDecoration(
        color: highlight
            ? Colors.amber.withValues(alpha: 0.25)
            : Colors.white.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(8),
      ),
      margin: const EdgeInsets.symmetric(horizontal: 2),
      child: Column(
        children: [
          Icon(icon, color: Colors.white, size: 16),
          const SizedBox(height: 4),
          Text(
            value,
            style: const TextStyle(
              color: Colors.white,
              fontWeight: FontWeight.bold,
              fontSize: 13,
            ),
          ),
          Text(
            title,
            style: const TextStyle(color: Colors.white70, fontSize: 10),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  /// شريط الفلاتر والبحث
  Widget _buildFilterBar(
    BuildContext context,
    MorphologyAuditState state,
    MorphologyAuditNotifier notifier,
  ) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
      child: Column(
        children: [
          Row(
            children: [
              Expanded(
                child: SegmentedButton<bool>(
                  segments: const [
                    ButtonSegment<bool>(
                      value: true,
                      label: Text('غير مربوطة بجذر', style: TextStyle(fontSize: 12)),
                      icon: Icon(Icons.link_off, size: 16),
                    ),
                    ButtonSegment<bool>(
                      value: false,
                      label: Text('بدون صرف', style: TextStyle(fontSize: 12)),
                      icon: Icon(Icons.spellcheck, size: 16),
                    ),
                  ],
                  selected: {state.withoutRootOnly},
                  onSelectionChanged: (set) {
                    if (set.isNotEmpty) {
                      notifier.setWithoutRootOnly(set.first);
                    }
                  },
                ),
              ),
              const SizedBox(width: 8),
              OutlinedButton.icon(
                icon: const Icon(Icons.filter_list, size: 18),
                label: Text(
                  state.selectedSurahName ?? 'كل السور',
                  style: const TextStyle(fontSize: 12),
                ),
                style: OutlinedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                ),
                onPressed: _openSurahFilterModal,
              ),
            ],
          ),
          const SizedBox(height: 8),
          TextField(
            controller: _searchController,
            decoration: InputDecoration(
              hintText: 'ابحث عن كلمة معينة للتدقيق...',
              prefixIcon: const Icon(Icons.search, size: 20),
              isDense: true,
              border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
              suffixIcon: _searchController.text.isNotEmpty
                  ? IconButton(
                      icon: const Icon(Icons.clear, size: 18),
                      onPressed: () {
                        _searchController.clear();
                        notifier.search('');
                      },
                    )
                  : null,
            ),
            onSubmitted: (q) => notifier.search(q),
          ),
        ],
      ),
    );
  }

  /// شريط التحديد والملخص
  Widget _buildSelectionSummaryBar(
    BuildContext context,
    MorphologyAuditState state,
    MorphologyAuditNotifier notifier,
  ) {
    final items = state.uiState.data ?? [];
    final allSelected = items.isNotEmpty && state.selectedWordIds.length == items.length;

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            'عدد النتائج: ${state.totalCount} موضعاً',
            style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: Colors.grey),
          ),
          Row(
            children: [
              TextButton.icon(
                icon: Icon(
                  allSelected ? Icons.check_box : Icons.check_box_outline_blank,
                  size: 18,
                  color: AppTheme.primaryEmerald,
                ),
                label: Text(
                  allSelected ? 'إلغاء تحديد الكل' : 'تحديد الصفحة',
                  style: const TextStyle(fontSize: 12, color: AppTheme.primaryEmerald),
                ),
                onPressed: () {
                  if (allSelected) {
                    notifier.clearSelection();
                  } else {
                    notifier.selectAll();
                  }
                },
              ),
            ],
          ),
        ],
      ),
    );
  }

  /// بناء قائمة الكلمات
  Widget _buildItemsList(
    BuildContext context,
    MorphologyAuditState state,
    MorphologyAuditNotifier notifier,
  ) {
    if (state.uiState.isLoading) {
      return const Center(
        child: CircularProgressIndicator(color: AppTheme.primaryEmerald),
      );
    }

    if (state.uiState.isError) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.error_outline, size: 48, color: Colors.red),
            const SizedBox(height: 12),
            Text(state.uiState.errorMessage ?? 'حدث خطأ'),
            const SizedBox(height: 12),
            ElevatedButton(
              onPressed: () => notifier.loadItems(refresh: true),
              child: const Text('إعادة المحاولة'),
            ),
          ],
        ),
      );
    }

    final items = state.uiState.data ?? [];
    if (items.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.verified, size: 56, color: Colors.green),
            const SizedBox(height: 12),
            const Text(
              'ممتاز! لا توجد كلمات مطابقة لمعايير التدقيق',
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 4),
            Text(
              state.withoutRootOnly
                  ? 'جميع الكلمات في هذا النطاق مربوطة بالجذور'
                  : 'جميع الكلمات في هذا النطاق مصنفة صرفياً',
              style: const TextStyle(fontSize: 12, color: Colors.grey),
            ),
          ],
        ),
      );
    }

    return ListView.builder(
      controller: _scrollController,
      padding: const EdgeInsets.fromLTRB(16, 4, 16, 80),
      itemCount: items.length + (state.isLoadingMore ? 1 : 0),
      itemBuilder: (context, index) {
        if (index == items.length) {
          return const Center(
            child: Padding(
              padding: EdgeInsets.all(16),
              child: CircularProgressIndicator(color: AppTheme.primaryEmerald),
            ),
          );
        }

        final item = items[index];
        final isSelected = state.selectedWordIds.contains(item.wordId);

        return Card(
          margin: const EdgeInsets.symmetric(vertical: 4),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
            side: BorderSide(
              color: isSelected
                  ? AppTheme.primaryEmerald
                  : Theme.of(context).dividerColor.withValues(alpha: 0.15),
              width: isSelected ? 1.5 : 1,
            ),
          ),
          child: InkWell(
            borderRadius: BorderRadius.circular(12),
            onTap: () => notifier.toggleWordSelection(item.wordId),
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              child: Row(
                children: [
                  Checkbox(
                    value: isSelected,
                    activeColor: AppTheme.primaryEmerald,
                    onChanged: (_) => notifier.toggleWordSelection(item.wordId),
                  ),
                  const SizedBox(width: 6),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Text(
                              item.wordUthmani,
                              style: const TextStyle(
                                fontSize: 18,
                                fontWeight: FontWeight.bold,
                                color: AppTheme.primaryEmerald,
                              ),
                            ),
                            const SizedBox(width: 8),
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                              decoration: BoxDecoration(
                                color: AppTheme.secondaryGold.withValues(alpha: 0.15),
                                borderRadius: BorderRadius.circular(6),
                              ),
                              child: Text(
                                'تتكرر ${item.occurrences} مرات',
                                style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w600),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 4),
                        Text(
                          'سورة ${item.surahName} • الآية ${item.ayahNumber} • الموضع ${item.wordPosition}',
                          style: const TextStyle(fontSize: 12, color: Colors.grey),
                        ),
                      ],
                    ),
                  ),
                  IconButton(
                    icon: const Icon(Icons.link, color: AppTheme.primaryEmerald),
                    tooltip: 'ربط مفرد بالجذر',
                    onPressed: () {
                      notifier.clearSelection();
                      notifier.toggleWordSelection(item.wordId);
                      _openBatchRelinkDialog(1);
                    },
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  /// شريط الإجراءات الجماعي العائم في الأسفل
  Widget _buildBatchActionBar(
    BuildContext context,
    int selectedCount,
    MorphologyAuditNotifier notifier,
  ) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        color: Theme.of(context).cardColor,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.12),
            blurRadius: 10,
            offset: const Offset(0, -3),
          ),
        ],
        borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
      ),
      child: SafeArea(
        child: Row(
          children: [
            Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'تم تحديد $selectedCount كلمة',
                  style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
                ),
                InkWell(
                  onTap: () => notifier.clearSelection(),
                  child: const Text(
                    'إلغاء التحديد',
                    style: TextStyle(fontSize: 11, color: Colors.red),
                  ),
                ),
              ],
            ),
            const Spacer(),
            ElevatedButton.icon(
              icon: const Icon(Icons.auto_fix_high, size: 18),
              label: const Text('ربط جماعي بالجذر'),
              style: ElevatedButton.styleFrom(
                backgroundColor: AppTheme.primaryEmerald,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              ),
              onPressed: () => _openBatchRelinkDialog(selectedCount),
            ),
          ],
        ),
      ),
    );
  }
}
