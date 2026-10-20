import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../app/theme/app_theme.dart';
import '../../domain/entities/study_project.dart';
import '../controllers/study_projects_providers.dart';
import '../widgets/create_study_project_dialog.dart';

/// الشاشة الرئيسية لمركز مشاريع الدراسة القرآنية (StudyProjectsHubScreen)
class StudyProjectsHubScreen extends ConsumerStatefulWidget {
  /// المنشئ
  const StudyProjectsHubScreen({super.key});

  @override
  ConsumerState<StudyProjectsHubScreen> createState() => _StudyProjectsHubScreenState();
}

class _StudyProjectsHubScreenState extends ConsumerState<StudyProjectsHubScreen> {
  final _searchController = TextEditingController();

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  void _openCreateDialog([StudyProjectType? type]) {
    showDialog(
      context: context,
      builder: (ctx) => CreateStudyProjectDialog(initialType: type),
    );
  }

  void _confirmDelete(BuildContext context, StudyProject project) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('تأكيد حذف المشروع'),
        content: Text('هل أنت متأكد من حذف مشروع "${project.title}" وكافة بياناته وروابطه نهائياً؟'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(),
            child: const Text('إلغاء'),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red, foregroundColor: Colors.white),
            onPressed: () async {
              Navigator.of(ctx).pop();
              if (project.id != null) {
                await ref.read(studyProjectsListNotifierProvider.notifier).deleteProject(project.id!);
                if (context.mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('تم حذف المشروع بنجاح')),
                  );
                }
              }
            },
            child: const Text('حذف نهائي'),
          ),
        ],
      ),
    );
  }

  void _navigateToProject(BuildContext context, StudyProject project) {
    if (project.id == null) return;
    switch (project.projectType) {
      case StudyProjectType.root:
        context.push('/study-projects/root/${project.id}');
        break;
      case StudyProjectType.ayah:
        context.push('/study-projects/ayah/${project.id}');
        break;
      case StudyProjectType.concept:
        context.push('/study-projects/concept/${project.id}');
        break;
    }
  }

  @override
  Widget build(BuildContext context) {
    final projectsAsync = ref.watch(studyProjectsListNotifierProvider);
    final statsAsync = ref.watch(studyProjectsStatsProvider);
    final filter = ref.watch(studyProjectsFilterProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('مشاريع الدراسة القرآنية'),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            tooltip: 'تحديث القائمة',
            onPressed: () {
              ref.read(studyProjectsListNotifierProvider.notifier).loadProjects();
              ref.invalidate(studyProjectsStatsProvider);
            },
          ),
          IconButton(
            icon: const Icon(Icons.add),
            tooltip: 'مشروع دراسة جديد',
            onPressed: () => _openCreateDialog(),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => _openCreateDialog(),
        backgroundColor: AppTheme.primaryEmerald,
        foregroundColor: Colors.white,
        icon: const Icon(Icons.add),
        label: const Text('مشروع دراسة جديد'),
      ),
      body: RefreshIndicator(
        onRefresh: () async {
          await ref.read(studyProjectsListNotifierProvider.notifier).loadProjects();
          ref.invalidate(studyProjectsStatsProvider);
        },
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            // بطاقة مؤشرات KPI والإحصاءات
            statsAsync.when(
              loading: () => const SizedBox.shrink(),
              error: (_, _) => const SizedBox.shrink(),
              data: (stats) {
                final total = stats['total'] ?? 0;
                final rootCount = stats['root'] ?? 0;
                final ayahCount = stats['ayah'] ?? 0;
                final conceptCount = stats['concept'] ?? 0;
                final completed = stats['completed'] ?? 0;

                return Card(
                  margin: const EdgeInsets.only(bottom: 16),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                  child: Padding(
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            const Icon(Icons.analytics_outlined, color: AppTheme.primaryEmerald),
                            const SizedBox(width: 8),
                            const Text('لوحة مؤشرات مشاريع الدراسة', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                            const Spacer(),
                            Text('إجمالي المشاريع: $total', style: const TextStyle(fontWeight: FontWeight.bold, color: AppTheme.primaryEmerald)),
                          ],
                        ),
                        const SizedBox(height: 14),
                        Row(
                          children: [
                            Expanded(
                              child: _buildStatItem(
                                title: 'دراسة الجذور',
                                count: rootCount,
                                icon: Icons.account_tree_outlined,
                                color: AppTheme.primaryEmerald,
                              ),
                            ),
                            Expanded(
                              child: _buildStatItem(
                                title: 'دراسة الآيات',
                                count: ayahCount,
                                icon: Icons.menu_book_outlined,
                                color: Colors.blue.shade700,
                              ),
                            ),
                            Expanded(
                              child: _buildStatItem(
                                title: 'دراسة المفاهيم',
                                count: conceptCount,
                                icon: Icons.lightbulb_outline,
                                color: AppTheme.secondaryGold,
                              ),
                            ),
                            Expanded(
                              child: _buildStatItem(
                                title: 'مكتملة وموثقة',
                                count: completed,
                                icon: Icons.verified_outlined,
                                color: Colors.green.shade700,
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                );
              },
            ),

            // حقل البحث الفوري
            TextField(
              controller: _searchController,
              decoration: InputDecoration(
                hintText: 'ابحث في عناوين ومستهدفات مشاريع الدراسة...',
                prefixIcon: const Icon(Icons.search),
                suffixIcon: _searchController.text.isNotEmpty
                    ? IconButton(
                        icon: const Icon(Icons.clear),
                        onPressed: () {
                          _searchController.clear();
                          ref.read(studyProjectsFilterProvider.notifier).state =
                              filter.copyWith(searchQuery: '');
                          ref.read(studyProjectsListNotifierProvider.notifier).loadProjects();
                        },
                      )
                    : null,
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                filled: true,
              ),
              onChanged: (val) {
                ref.read(studyProjectsFilterProvider.notifier).state =
                    filter.copyWith(searchQuery: val);
                ref.read(studyProjectsListNotifierProvider.notifier).loadProjects();
              },
            ),
            const SizedBox(height: 12),

            // مرشحات التصفية حسب نمط المشروع
            SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: Row(
                children: [
                  FilterChip(
                    label: const Text('الكل'),
                    selected: filter.typeFilter == null,
                    onSelected: (_) {
                      ref.read(studyProjectsFilterProvider.notifier).state =
                          filter.copyWith(clearTypeFilter: true);
                      ref.read(studyProjectsListNotifierProvider.notifier).loadProjects();
                    },
                  ),
                  const SizedBox(width: 8),
                  FilterChip(
                    label: const Text('دراسة جذر'),
                    avatar: const Icon(Icons.account_tree_outlined, size: 16),
                    selected: filter.typeFilter == StudyProjectType.root,
                    onSelected: (selected) {
                      ref.read(studyProjectsFilterProvider.notifier).state =
                          filter.copyWith(typeFilter: selected ? StudyProjectType.root : null, clearTypeFilter: !selected);
                      ref.read(studyProjectsListNotifierProvider.notifier).loadProjects();
                    },
                  ),
                  const SizedBox(width: 8),
                  FilterChip(
                    label: const Text('دراسة آية'),
                    avatar: const Icon(Icons.menu_book_outlined, size: 16),
                    selected: filter.typeFilter == StudyProjectType.ayah,
                    onSelected: (selected) {
                      ref.read(studyProjectsFilterProvider.notifier).state =
                          filter.copyWith(typeFilter: selected ? StudyProjectType.ayah : null, clearTypeFilter: !selected);
                      ref.read(studyProjectsListNotifierProvider.notifier).loadProjects();
                    },
                  ),
                  const SizedBox(width: 8),
                  FilterChip(
                    label: const Text('دراسة مفهوم'),
                    avatar: const Icon(Icons.lightbulb_outline, size: 16),
                    selected: filter.typeFilter == StudyProjectType.concept,
                    onSelected: (selected) {
                      ref.read(studyProjectsFilterProvider.notifier).state =
                          filter.copyWith(typeFilter: selected ? StudyProjectType.concept : null, clearTypeFilter: !selected);
                      ref.read(studyProjectsListNotifierProvider.notifier).loadProjects();
                    },
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),

            // قائمة مشاريع الدراسة
            projectsAsync.when(
              loading: () => const Center(
                child: Padding(
                  padding: EdgeInsets.all(40),
                  child: CircularProgressIndicator(),
                ),
              ),
              error: (err, _) => Center(
                child: Padding(
                  padding: const EdgeInsets.all(32),
                  child: Column(
                    children: [
                      const Icon(Icons.error_outline, color: Colors.red, size: 48),
                      const SizedBox(height: 12),
                      Text('حدث خطأ في تحميل المشاريع: $err'),
                      const SizedBox(height: 12),
                      ElevatedButton(
                        onPressed: () => ref.read(studyProjectsListNotifierProvider.notifier).loadProjects(),
                        child: const Text('إعادة المحاولة'),
                      ),
                    ],
                  ),
                ),
              ),
              data: (projects) {
                if (projects.isEmpty) {
                  return Container(
                    padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 48),
                    alignment: Alignment.center,
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        CircleAvatar(
                          radius: 40,
                          backgroundColor: AppTheme.primaryEmerald.withValues(alpha: 0.1),
                          foregroundColor: AppTheme.primaryEmerald,
                          child: const Icon(Icons.folder_open, size: 42),
                        ),
                        const SizedBox(height: 16),
                        const Text(
                          'لا توجد مشاريع دراسة مطابقة',
                          style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18),
                        ),
                        const SizedBox(height: 8),
                        const Text(
                          'ابدأ مسارك البحثي والتدبري بإنشاء مشروع دراسة لجذر لغوي، أو آية قرآنية، أو مفهوم كلي.',
                          textAlign: TextAlign.center,
                          style: TextStyle(color: Colors.grey, height: 1.5),
                        ),
                        const SizedBox(height: 20),
                        ElevatedButton.icon(
                          onPressed: () => _openCreateDialog(),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: AppTheme.primaryEmerald,
                            foregroundColor: Colors.white,
                            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                          ),
                          icon: const Icon(Icons.add),
                          label: const Text('فتح أول مشروع دراسة'),
                        ),
                      ],
                    ),
                  );
                }

                return ListView.builder(
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  itemCount: projects.length,
                  itemBuilder: (context, index) {
                    final project = projects[index];
                    return _buildProjectCard(context, project);
                  },
                );
              },
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStatItem({
    required String title,
    required int count,
    required IconData icon,
    required Color color,
  }) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 4),
      padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 8),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: color.withValues(alpha: 0.15)),
      ),
      child: Column(
        children: [
          Icon(icon, size: 20, color: color),
          const SizedBox(height: 6),
          Text(
            '$count',
            style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16, color: color),
          ),
          const SizedBox(height: 2),
          Text(
            title,
            textAlign: TextAlign.center,
            style: const TextStyle(fontSize: 10, color: Colors.grey),
          ),
        ],
      ),
    );
  }

  Widget _buildProjectCard(BuildContext context, StudyProject project) {
    Color typeColor;
    IconData typeIcon;

    switch (project.projectType) {
      case StudyProjectType.root:
        typeColor = AppTheme.primaryEmerald;
        typeIcon = Icons.account_tree_outlined;
        break;
      case StudyProjectType.ayah:
        typeColor = Colors.blue.shade700;
        typeIcon = Icons.menu_book_outlined;
        break;
      case StudyProjectType.concept:
        typeColor = AppTheme.secondaryGold;
        typeIcon = Icons.lightbulb_outline;
        break;
    }

    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
      elevation: 1.5,
      child: InkWell(
        borderRadius: BorderRadius.circular(14),
        onTap: () => _navigateToProject(context, project),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  CircleAvatar(
                    backgroundColor: typeColor.withValues(alpha: 0.15),
                    foregroundColor: typeColor,
                    radius: 22,
                    child: Icon(typeIcon, size: 22),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          project.title,
                          style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                        ),
                        const SizedBox(height: 4),
                        Row(
                          children: [
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                              decoration: BoxDecoration(
                                color: typeColor.withValues(alpha: 0.12),
                                borderRadius: BorderRadius.circular(6),
                              ),
                              child: Text(
                                project.projectType.arabicLabel,
                                style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: typeColor),
                              ),
                            ),
                            const SizedBox(width: 8),
                            Text(
                              'المستهدف: ${project.targetIdentifier}',
                              style: TextStyle(fontSize: 12, color: Colors.grey.shade600),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                  PopupMenuButton<String>(
                    onSelected: (val) async {
                      if (val == 'open') {
                        _navigateToProject(context, project);
                      } else if (val == 'delete') {
                        _confirmDelete(context, project);
                      }
                    },
                    itemBuilder: (ctx) => [
                      const PopupMenuItem(value: 'open', child: Row(children: [Icon(Icons.edit_outlined, size: 18), SizedBox(width: 8), Text('فتح المحرر')])),
                      const PopupMenuItem(value: 'delete', child: Row(children: [Icon(Icons.delete_outline, color: Colors.red, size: 18), SizedBox(width: 8), Text('حذف', style: TextStyle(color: Colors.red))])),
                    ],
                  ),
                ],
              ),
              if (project.description != null && project.description!.trim().isNotEmpty) ...[
                const SizedBox(height: 10),
                Text(
                  project.description!,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(fontSize: 13, color: Colors.grey.shade700, height: 1.4),
                ),
              ],
              const SizedBox(height: 12),
              const Divider(height: 1),
              const SizedBox(height: 10),
              Row(
                children: [
                  Text(
                    'نسبة الإنجاز: ${(project.progress * 100).toInt()}%',
                    style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(4),
                      child: LinearProgressIndicator(
                        value: project.progress,
                        minHeight: 6,
                        backgroundColor: Colors.grey.withValues(alpha: 0.2),
                        valueColor: AlwaysStoppedAnimation(typeColor),
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                    decoration: BoxDecoration(
                      color: project.status == StudyProjectStatus.completed
                          ? Colors.green.withValues(alpha: 0.15)
                          : (project.status == StudyProjectStatus.inProgress
                              ? Colors.orange.withValues(alpha: 0.15)
                              : Colors.grey.withValues(alpha: 0.15)),
                      borderRadius: BorderRadius.circular(6),
                    ),
                    child: Text(
                      project.status.arabicLabel,
                      style: TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.bold,
                        color: project.status == StudyProjectStatus.completed
                            ? Colors.green.shade800
                            : (project.status == StudyProjectStatus.inProgress
                                ? Colors.orange.shade800
                                : Colors.grey.shade800),
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}
