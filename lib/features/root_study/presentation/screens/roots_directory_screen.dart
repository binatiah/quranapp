import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:quranapp/app/theme/app_theme.dart';
import 'package:quranapp/features/quran_search/domain/entities/quran_root.dart';
import 'package:quranapp/features/root_study/domain/repositories/root_management_repository.dart';
import 'package:quranapp/features/root_study/presentation/controllers/roots_directory_providers.dart';
import 'package:quranapp/features/root_study/presentation/widgets/add_edit_root_dialog.dart';
import 'package:quranapp/features/vocabulary/presentation/widgets/lexicon_export_import_dialog.dart';

/// شاشة دليل وإدارة الجذور القرآنية (Roots Directory & Management Screen).
class RootsDirectoryScreen extends ConsumerStatefulWidget {
  const RootsDirectoryScreen({super.key});

  @override
  ConsumerState<RootsDirectoryScreen> createState() => _RootsDirectoryScreenState();
}

class _RootsDirectoryScreenState extends ConsumerState<RootsDirectoryScreen> {
  final ScrollController _scrollController = ScrollController();
  final TextEditingController _searchController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _scrollController.addListener(_onScroll);
  }

  void _onScroll() {
    if (_scrollController.position.pixels >= _scrollController.position.maxScrollExtent - 200) {
      ref.read(rootsDirectoryNotifierProvider.notifier).loadMore();
    }
  }

  @override
  void dispose() {
    _scrollController.dispose();
    _searchController.dispose();
    super.dispose();
  }

  void _openAddRootDialog() {
    showDialog<bool>(
      context: context,
      builder: (ctx) => AddEditRootDialog(
        onSave: ({required String root, String? descriptionAr}) async {
          await ref.read(rootsDirectoryNotifierProvider.notifier).addRoot(
                root: root,
                descriptionAr: descriptionAr,
              );
        },
      ),
    ).then((result) {
      if (result == true && mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('تمت إضافة الجذر بنجاح'),
            backgroundColor: AppTheme.primaryEmerald,
          ),
        );
      }
    });
  }

  void _openEditRootDialog(QuranRoot targetRoot) {
    showDialog<bool>(
      context: context,
      builder: (ctx) => AddEditRootDialog(
        rootToEdit: targetRoot,
        onSave: ({required String root, String? descriptionAr}) async {
          await ref.read(rootsDirectoryNotifierProvider.notifier).updateRoot(
                id: targetRoot.id,
                root: root,
                descriptionAr: descriptionAr,
              );
        },
      ),
    ).then((result) {
      if (result == true && mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('تم تحديث بيانات الجذر بنجاح'),
            backgroundColor: AppTheme.primaryEmerald,
          ),
        );
      }
    });
  }

  void _confirmDeleteRoot(QuranRoot root) {
    showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: const Row(
          children: [
            Icon(Icons.warning_amber_rounded, color: Colors.red),
            SizedBox(width: 8),
            Text('تأكيد حذف الجذر'),
          ],
        ),
        content: Text(
          'هل أنت متأكد من رغبتك في حذف الجذر "${root.root}"؟\n'
          'سيتم فك ارتباطه بجميع الكلمات القرآنية المسجلة تحته (${root.occurrencesCount} موضع ورود).',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(false),
            child: const Text('إلغاء'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.of(ctx).pop(true),
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            child: const Text('تأكيد الحذف'),
          ),
        ],
      ),
    ).then((confirmed) async {
      if (confirmed == true && mounted) {
        try {
          final success = await ref
              .read(rootsDirectoryNotifierProvider.notifier)
              .deleteRoot(root.id);
          if (success && mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(
                content: Text('تم حذف الجذر بنجاح'),
                backgroundColor: Colors.red,
              ),
            );
          }
        } catch (e) {
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text('فشل الحذف: ${e.toString()}'),
                backgroundColor: Theme.of(context).colorScheme.error,
              ),
            );
          }
        }
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(rootsDirectoryNotifierProvider);
    final notifier = ref.read(rootsDirectoryNotifierProvider.notifier);

    return Scaffold(
      appBar: AppBar(
        title: const Text('دليل وإدارة الجذور القرآنية'),
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
              onImportSuccess: () => notifier.loadRoots(refresh: true),
            ),
          ),
          IconButton(
            icon: const Icon(Icons.refresh),
            tooltip: 'تحديث القائمة',
            onPressed: () => notifier.loadRoots(refresh: true),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: _openAddRootDialog,
        backgroundColor: AppTheme.primaryEmerald,
        foregroundColor: Colors.white,
        icon: const Icon(Icons.add),
        label: const Text('إضافة جذر جديد'),
      ),
      body: Column(
        children: [
          // شريط البحث
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 8),
            child: TextField(
              controller: _searchController,
              decoration: InputDecoration(
                hintText: 'ابحث عن جذر، لفظ، أو معنى لغوي...',
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

          // شرائح خيارات الترتيب والفرز
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
            child: Row(
              children: [
                _buildSortChip(
                  label: 'الأكثر تكراراً',
                  icon: Icons.trending_up,
                  sort: RootSortBy.occurrencesDesc,
                  currentSort: state.sortBy,
                  onSelect: notifier.setSortBy,
                ),
                const SizedBox(width: 8),
                _buildSortChip(
                  label: 'الأكثر مشتقات',
                  icon: Icons.account_tree,
                  sort: RootSortBy.wordsCountDesc,
                  currentSort: state.sortBy,
                  onSelect: notifier.setSortBy,
                ),
                const SizedBox(width: 8),
                _buildSortChip(
                  label: 'أبجدياً (أ - ي)',
                  icon: Icons.sort_by_alpha,
                  sort: RootSortBy.alphabetical,
                  currentSort: state.sortBy,
                  onSelect: notifier.setSortBy,
                ),
                const SizedBox(width: 8),
                _buildSortChip(
                  label: 'بدون بيان لغوي',
                  icon: Icons.edit_note,
                  sort: RootSortBy.withoutDescription,
                  currentSort: state.sortBy,
                  onSelect: notifier.setSortBy,
                ),
              ],
            ),
          ),

          // شريط إحصائي بعدد الجذور
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'إجمالي الجذور المطابقة: ${state.totalCount}',
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

          // المحتوى الرئيسي
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
                      Icon(
                        Icons.search_off,
                        size: 64,
                        color: Colors.grey.withValues(alpha: 0.5),
                      ),
                      const SizedBox(height: 16),
                      const Text(
                        'لم يتم العثور على أي جذر مطابق',
                        style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                      ),
                      const SizedBox(height: 8),
                      const Text(
                        'يمكنك إضافة هذا الجذر فوراً لقاعدة البيانات بالضغط على زر الإضافة أدناه.',
                        textAlign: TextAlign.center,
                        style: TextStyle(fontSize: 14, color: Colors.grey),
                      ),
                      const SizedBox(height: 16),
                      ElevatedButton.icon(
                        onPressed: _openAddRootDialog,
                        icon: const Icon(Icons.add),
                        label: const Text('إضافة الجذر الآن'),
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
                        onPressed: () => notifier.loadRoots(refresh: true),
                        child: const Text('إعادة المحاولة'),
                      ),
                    ],
                  ),
                ),
              ),
              success: (roots) => RefreshIndicator(
                onRefresh: () => notifier.loadRoots(refresh: true),
                child: ListView.separated(
                  controller: _scrollController,
                  padding: const EdgeInsets.fromLTRB(16, 12, 16, 80),
                  itemCount: roots.length + (state.isLoadingMore ? 1 : 0),
                  separatorBuilder: (_, _) => const SizedBox(height: 12),
                  itemBuilder: (context, index) {
                    if (index >= roots.length) {
                      return const Padding(
                        padding: EdgeInsets.symmetric(vertical: 24),
                        child: Center(child: CircularProgressIndicator()),
                      );
                    }
                    final root = roots[index];
                    return _buildRootCard(context, root);
                  },
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSortChip({
    required String label,
    required IconData icon,
    required RootSortBy sort,
    required RootSortBy currentSort,
    required void Function(RootSortBy) onSelect,
  }) {
    final isSelected = sort == currentSort;
    return ChoiceChip(
      selected: isSelected,
      avatar: Icon(
        icon,
        size: 16,
        color: isSelected ? Colors.white : AppTheme.primaryEmerald,
      ),
      label: Text(label),
      selectedColor: AppTheme.primaryEmerald,
      labelStyle: TextStyle(
        color: isSelected ? Colors.white : null,
        fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
        fontSize: 13,
      ),
      onSelected: (_) => onSelect(sort),
    );
  }

  Widget _buildRootCard(BuildContext context, QuranRoot root) {
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
            // ترويسة البطاقة: الجذر مع شارات الإحصاء وقائمة الإجراءات
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                  decoration: BoxDecoration(
                    color: AppTheme.primaryEmerald.withValues(alpha: 0.12),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(
                      color: AppTheme.primaryEmerald.withValues(alpha: 0.3),
                    ),
                  ),
                  child: Text(
                    root.root,
                    style: const TextStyle(
                      fontSize: 22,
                      fontWeight: FontWeight.bold,
                      color: AppTheme.primaryEmerald,
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Wrap(
                    spacing: 8,
                    runSpacing: 4,
                    children: [
                      Chip(
                        materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
                        padding: EdgeInsets.zero,
                        labelPadding: const EdgeInsets.symmetric(horizontal: 8),
                        avatar: const Icon(Icons.repeat, size: 14, color: AppTheme.secondaryGold),
                        label: Text(
                          '${root.occurrencesCount} موضع ورود',
                          style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold),
                        ),
                      ),
                      Chip(
                        materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
                        padding: EdgeInsets.zero,
                        labelPadding: const EdgeInsets.symmetric(horizontal: 8),
                        avatar: const Icon(Icons.style, size: 14, color: AppTheme.primaryEmerald),
                        label: Text(
                          '${root.wordsCount} مشتقات',
                          style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold),
                        ),
                      ),
                    ],
                  ),
                ),
                PopupMenuButton<String>(
                  icon: const Icon(Icons.more_vert),
                  onSelected: (val) {
                    if (val == 'edit') {
                      _openEditRootDialog(root);
                    } else if (val == 'delete') {
                      _confirmDeleteRoot(root);
                    }
                  },
                  itemBuilder: (ctx) => [
                    const PopupMenuItem(
                      value: 'edit',
                      child: Row(
                        children: [
                          Icon(Icons.edit_outlined, size: 18),
                          SizedBox(width: 8),
                          Text('تعديل الجذر'),
                        ],
                      ),
                    ),
                    const PopupMenuItem(
                      value: 'delete',
                      child: Row(
                        children: [
                          Icon(Icons.delete_outline, color: Colors.red, size: 18),
                          SizedBox(width: 8),
                          Text('حذف الجذر', style: TextStyle(color: Colors.red)),
                        ],
                      ),
                    ),
                  ],
                ),
              ],
            ),
            const SizedBox(height: 12),

            // وصف الجذر إن وجد
            if (root.descriptionAr != null && root.descriptionAr!.trim().isNotEmpty) ...[
              Text(
                root.descriptionAr!,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(
                  fontSize: 13,
                  height: 1.5,
                  color: Theme.of(context).textTheme.bodyMedium?.color?.withValues(alpha: 0.85),
                ),
              ),
              const SizedBox(height: 12),
            ] else ...[
              Row(
                children: [
                  Icon(Icons.info_outline, size: 14, color: Colors.grey.withValues(alpha: 0.6)),
                  const SizedBox(width: 6),
                  const Text(
                    'لا يوجد بيان لغوي مسجل لهذا الجذر بعد.',
                    style: TextStyle(fontSize: 12, color: Colors.grey),
                  ),
                ],
              ),
              const SizedBox(height: 12),
            ],

            // أزرار التنقل السريع: دراسة تفصيلية واستعراض الكلمات
            Row(
              children: [
                Expanded(
                  child: ElevatedButton.icon(
                    onPressed: () {
                      context.push('/roots/${root.root}');
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppTheme.primaryEmerald,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(vertical: 8),
                    ),
                    icon: const Icon(Icons.account_tree_outlined, size: 18),
                    label: const Text('دراسة الجذر', style: TextStyle(fontSize: 13)),
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: () {
                      context.push('/words?root=${root.rootNormalized}');
                    },
                    style: OutlinedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(vertical: 8),
                      side: const BorderSide(color: AppTheme.secondaryGold),
                      foregroundColor: AppTheme.secondaryGold,
                    ),
                    icon: const Icon(Icons.list_alt, size: 18),
                    label: const Text('استعراض الكلمات', style: TextStyle(fontSize: 13)),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
