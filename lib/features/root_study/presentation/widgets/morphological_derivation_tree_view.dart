import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:quranapp/app/theme/app_theme.dart';
import 'package:quranapp/features/root_study/domain/entities/derived_word.dart';
import 'package:quranapp/features/root_study/domain/entities/morphology_tree_node.dart';

/// ويدجت عرض شجرة الاشتقاق الصرفي التفاعلية للجذر القرآني (Morphological Derivation Tree View).
class MorphologicalDerivationTreeView extends StatelessWidget {
  final MorphologyTreeData treeData;
  final void Function(DerivedWord word)? onWordSelected;

  const MorphologicalDerivationTreeView({
    super.key,
    required this.treeData,
    this.onWordSelected,
  });

  @override
  Widget build(BuildContext context) {
    if (treeData.branches.isEmpty) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Icons.account_tree_outlined, size: 56, color: Colors.grey.withValues(alpha: 0.5)),
              const SizedBox(height: 12),
              const Text(
                'لا توجد فروع اشتقاقية مسجلة لهذا الجذر',
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
              ),
            ],
          ),
        ),
      );
    }

    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        // ترويسة الشجرة مع إحصاءات الجذع
        Card(
          elevation: 0,
          color: Theme.of(context).brightness == Brightness.light
              ? AppTheme.primaryEmerald.withValues(alpha: 0.08)
              : AppTheme.darkCard,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
            side: BorderSide(
              color: AppTheme.primaryEmerald.withValues(alpha: 0.2),
            ),
          ),
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                  decoration: BoxDecoration(
                    color: AppTheme.primaryEmerald,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Text(
                    treeData.root,
                    style: const TextStyle(
                      fontSize: 24,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                    ),
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'أصل الجذر والشجرة الصرفية',
                        style: TextStyle(fontWeight: FontWeight.bold, fontSize: 15),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        '${treeData.branches.length} فئات اشتقاقية • ${treeData.totalUniqueWords} كلمة مختلفة • ${treeData.totalOccurrences} موضعاً',
                        style: TextStyle(
                          fontSize: 12,
                          color: Theme.of(context).textTheme.bodySmall?.color,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
        const SizedBox(height: 16),

        // عرض فروع وأوزان الشجرة
        ...treeData.branches.map((branch) => _buildBranchCard(context, branch)),
      ],
    );
  }

  Widget _buildBranchCard(BuildContext context, MorphologyBranch branch) {
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(14),
        side: BorderSide(
          color: Theme.of(context).dividerColor.withValues(alpha: 0.15),
        ),
      ),
      child: Theme(
        data: Theme.of(context).copyWith(dividerColor: Colors.transparent),
        child: ExpansionTile(
          initiallyExpanded: true,
          leading: CircleAvatar(
            backgroundColor: _getCategoryColor(branch.categoryName).withValues(alpha: 0.12),
            foregroundColor: _getCategoryColor(branch.categoryName),
            child: Icon(_getCategoryIcon(branch.categoryName), size: 20),
          ),
          title: Row(
            children: [
              Text(
                branch.subCategory,
                style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15),
              ),
              const SizedBox(width: 8),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                decoration: BoxDecoration(
                  color: AppTheme.secondaryGold.withValues(alpha: 0.15),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  '${branch.totalOccurrences} تكرار',
                  style: const TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.bold,
                    color: AppTheme.secondaryGold,
                  ),
                ),
              ),
            ],
          ),
          subtitle: Text(
            branch.categoryName,
            style: TextStyle(
              fontSize: 12,
              color: Theme.of(context).textTheme.bodySmall?.color,
            ),
          ),
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
              child: Wrap(
                spacing: 8,
                runSpacing: 8,
                children: branch.words.map((word) {
                  return InkWell(
                    borderRadius: BorderRadius.circular(10),
                    onTap: () {
                      if (onWordSelected != null) {
                        onWordSelected!(word);
                      } else {
                        context.push('/words?root=${treeData.rootNormalized}');
                      }
                    },
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                      decoration: BoxDecoration(
                        color: Theme.of(context).cardColor,
                        borderRadius: BorderRadius.circular(10),
                        border: Border.all(
                          color: Theme.of(context).dividerColor.withValues(alpha: 0.3),
                        ),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Text(
                            word.wordUthmani,
                            style: const TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                              color: AppTheme.primaryEmerald,
                            ),
                          ),
                          const SizedBox(width: 6),
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                            decoration: BoxDecoration(
                              color: AppTheme.primaryEmerald.withValues(alpha: 0.1),
                              borderRadius: BorderRadius.circular(6),
                            ),
                            child: Text(
                              '${word.occurrenceCount}',
                              style: const TextStyle(fontSize: 11, fontWeight: FontWeight.bold),
                            ),
                          ),
                        ],
                      ),
                    ),
                  );
                }).toList(),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Color _getCategoryColor(String category) {
    if (category.contains('الأفعال')) return AppTheme.primaryEmerald;
    if (category.contains('الأسماء')) return AppTheme.secondaryGold;
    return Colors.blueGrey;
  }

  IconData _getCategoryIcon(String category) {
    if (category.contains('الأفعال')) return Icons.play_arrow_outlined;
    if (category.contains('الأسماء')) return Icons.style_outlined;
    return Icons.widgets_outlined;
  }
}
