import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:share_plus/share_plus.dart';

import '../../../../app/theme/app_theme.dart';
import '../../domain/entities/root_study_details.dart';
import '../../domain/entities/study_project.dart';
import '../controllers/study_projects_providers.dart';
import '../widgets/add_ayah_link_dialog.dart';

/// شاشة محرر مشروع دراسة الجذر اللغوي القرآني
class RootStudyProjectScreen extends ConsumerStatefulWidget {
  /// معرف المشروع
  final int projectId;

  /// المنشئ
  const RootStudyProjectScreen({super.key, required this.projectId});

  @override
  ConsumerState<RootStudyProjectScreen> createState() => _RootStudyProjectScreenState();
}

class _RootStudyProjectScreenState extends ConsumerState<RootStudyProjectScreen> {
  bool _isInitialized = false;

  // Controllers for editable fields
  final _rootTypeController = TextEditingController();
  bool _hasVowels = false;
  final _vowelsCountController = TextEditingController();
  final _vowelsListController = TextEditingController();
  final _cognatesController = TextEditingController();
  final _oldestUsageController = TextEditingController();
  bool _isUsedToday = true;
  String? _usageNature;
  final _synonymsController = TextEditingController();
  final _antonymsController = TextEditingController();
  final _notesController = TextEditingController();

  bool _isSaving = false;

  @override
  void dispose() {
    _rootTypeController.dispose();
    _vowelsCountController.dispose();
    _vowelsListController.dispose();
    _cognatesController.dispose();
    _oldestUsageController.dispose();
    _synonymsController.dispose();
    _antonymsController.dispose();
    _notesController.dispose();
    super.dispose();
  }

  void _initFields(RootStudyDetails details) {
    if (_isInitialized) return;
    _rootTypeController.text = details.rootType ?? '';
    _hasVowels = details.hasVowels;
    _vowelsCountController.text = details.vowelsCount.toString();
    _vowelsListController.text = details.vowelsList ?? '';
    _cognatesController.text = details.cognatesOtherLanguages ?? '';
    _oldestUsageController.text = details.oldestUsage ?? '';
    _isUsedToday = details.isUsedToday;
    _usageNature = details.usageNature ?? 'معنوية';
    _synonymsController.text = details.synonyms ?? '';
    _antonymsController.text = details.antonyms ?? '';
    _notesController.text = details.researcherNotes ?? '';
    _isInitialized = true;
  }

  Future<void> _saveDetails() async {
    setState(() => _isSaving = true);
    try {
      final notifier = ref.read(studyProjectDetailsNotifierProvider(widget.projectId).notifier);
      final details = RootStudyDetails(
        projectId: widget.projectId,
        rootType: _rootTypeController.text.trim().isEmpty ? null : _rootTypeController.text.trim(),
        hasVowels: _hasVowels,
        vowelsCount: int.tryParse(_vowelsCountController.text.trim()) ?? 0,
        vowelsList: _vowelsListController.text.trim().isEmpty ? null : _vowelsListController.text.trim(),
        cognatesOtherLanguages: _cognatesController.text.trim().isEmpty ? null : _cognatesController.text.trim(),
        oldestUsage: _oldestUsageController.text.trim().isEmpty ? null : _oldestUsageController.text.trim(),
        isUsedToday: _isUsedToday,
        usageNature: _usageNature,
        synonyms: _synonymsController.text.trim().isEmpty ? null : _synonymsController.text.trim(),
        antonyms: _antonymsController.text.trim().isEmpty ? null : _antonymsController.text.trim(),
        researcherNotes: _notesController.text.trim().isEmpty ? null : _notesController.text.trim(),
      );

      await notifier.updateRootDetails(details);
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('تم حفظ بيانات دراسة الجذر بنجاح وتم تحديث نسبة الإنجاز')),
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('خطأ في الحفظ: $e')),
      );
    } finally {
      if (mounted) setState(() => _isSaving = false);
    }
  }

  void _exportMarkdown() {
    final notifier = ref.read(studyProjectDetailsNotifierProvider(widget.projectId).notifier);
    final md = notifier.exportMarkdown();
    Clipboard.setData(ClipboardData(text: md));
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('تم نسخ تقرير الدراسة بصيغة Markdown إلى الحافظة')),
    );
  }

  void _shareMarkdown() {
    final notifier = ref.read(studyProjectDetailsNotifierProvider(widget.projectId).notifier);
    final md = notifier.exportMarkdown();
    SharePlus.instance.share(
      ShareParams(text: md, subject: 'تقرير مشروع دراسة جذر قرآني'),
    );
  }

  @override
  Widget build(BuildContext context) {
    final projectState = ref.watch(studyProjectDetailsNotifierProvider(widget.projectId));

    return Scaffold(
      appBar: AppBar(
        title: projectState.when(
          data: (full) => Text(full.project.title),
          loading: () => const Text('جارِ التحميل...'),
          error: (_, _) => const Text('خطأ في التحميل'),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.share_outlined),
            tooltip: 'مشاركة تقرير الدراسة',
            onPressed: _shareMarkdown,
          ),
          IconButton(
            icon: const Icon(Icons.copy_all_outlined),
            tooltip: 'نسخ تقرير Markdown',
            onPressed: _exportMarkdown,
          ),
          IconButton(
            icon: _isSaving
                ? const SizedBox(width: 18, height: 18, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                : const Icon(Icons.save_outlined),
            tooltip: 'حفظ التعديلات',
            onPressed: _isSaving ? null : _saveDetails,
          ),
        ],
      ),
      body: projectState.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (err, _) => Center(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text('حدث خطأ: $err'),
              const SizedBox(height: 12),
              ElevatedButton(
                onPressed: () => ref.refresh(studyProjectDetailsNotifierProvider(widget.projectId)),
                child: const Text('إعادة المحاولة'),
              ),
            ],
          ),
        ),
        data: (full) {
          final p = full.project;
          final d = full.rootDetails ?? RootStudyDetails(projectId: widget.projectId);
          _initFields(d);

          return SingleChildScrollView(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                // بطاقة ملخص المشروع والمستهدف ومؤشر التقدم
                Card(
                  elevation: 2,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                  child: Padding(
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      children: [
                        Row(
                          children: [
                            CircleAvatar(
                              backgroundColor: AppTheme.primaryEmerald.withValues(alpha: 0.15),
                              foregroundColor: AppTheme.primaryEmerald,
                              radius: 24,
                              child: Text(
                                p.targetIdentifier,
                                style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                              ),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Row(
                                    children: [
                                      Text(
                                        'الجذر المستهدف: (${p.targetIdentifier})',
                                        style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                                      ),
                                      const Spacer(),
                                      Container(
                                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                                        decoration: BoxDecoration(
                                          color: p.status == StudyProjectStatus.completed
                                              ? Colors.green.withValues(alpha: 0.15)
                                              : (p.status == StudyProjectStatus.inProgress
                                                  ? Colors.orange.withValues(alpha: 0.15)
                                                  : Colors.grey.withValues(alpha: 0.15)),
                                          borderRadius: BorderRadius.circular(8),
                                        ),
                                        child: Text(
                                          p.status.arabicLabel,
                                          style: TextStyle(
                                            fontSize: 12,
                                            fontWeight: FontWeight.bold,
                                            color: p.status == StudyProjectStatus.completed
                                                ? Colors.green.shade800
                                                : (p.status == StudyProjectStatus.inProgress
                                                    ? Colors.orange.shade800
                                                    : Colors.grey.shade800),
                                          ),
                                        ),
                                      ),
                                    ],
                                  ),
                                  const SizedBox(height: 6),
                                  Text(
                                    'ورود الكلمات المشتقة في المصحف: ${full.targetRootTotalOccurrences ?? 0} موضع • مشتقات فريدة: ${full.targetRootDerivedWordsCount ?? 0}',
                                    style: TextStyle(fontSize: 12, color: Colors.grey.shade600),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 14),
                        Row(
                          children: [
                            const Text('نسبة إنجاز محاور الدراسة: ', style: TextStyle(fontSize: 13)),
                            Text(
                              '${(p.progress * 100).toInt()}%',
                              style: const TextStyle(fontWeight: FontWeight.bold, color: AppTheme.primaryEmerald),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: ClipRRect(
                                borderRadius: BorderRadius.circular(6),
                                child: LinearProgressIndicator(
                                  value: p.progress,
                                  minHeight: 8,
                                  backgroundColor: Colors.grey.withValues(alpha: 0.2),
                                  valueColor: const AlwaysStoppedAnimation(AppTheme.primaryEmerald),
                                ),
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 16),

                // المحور 1 و 2: نوع الجذر وأحرف العلة
                Card(
                  child: Padding(
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Row(
                          children: [
                            Icon(Icons.category_outlined, color: AppTheme.primaryEmerald, size: 20),
                            SizedBox(width: 8),
                            Text(
                              '1. نوع الجذر الصرفي وأحرف العلة',
                              style: TextStyle(fontWeight: FontWeight.bold, fontSize: 15),
                            ),
                          ],
                        ),
                        const SizedBox(height: 12),
                        Row(
                          children: [
                            Expanded(
                              child: TextField(
                                controller: _rootTypeController,
                                decoration: const InputDecoration(
                                  labelText: 'نوع الجذر (ثنائي / ثلاثي / رباعي...)',
                                  border: OutlineInputBorder(),
                                ),
                              ),
                            ),
                            const SizedBox(width: 10),
                            OutlinedButton.icon(
                              onPressed: () {
                                final analyzer = ref.read(studyProjectAnalyzerServiceProvider);
                                final res = analyzer.analyzeRoot(p.targetIdentifier);
                                setState(() {
                                  _rootTypeController.text = res.rootType;
                                  _hasVowels = res.hasVowels;
                                  _vowelsCountController.text = res.vowelsCount.toString();
                                  _vowelsListController.text = res.vowelsList;
                                });
                              },
                              icon: const Icon(Icons.auto_awesome, size: 16),
                              label: const Text('استنتاج آلي'),
                            ),
                          ],
                        ),
                        const SizedBox(height: 12),
                        SwitchListTile(
                          contentPadding: EdgeInsets.zero,
                          title: const Text('هل يحتوي الجذر على أحرف علة؟'),
                          value: _hasVowels,
                          onChanged: (val) => setState(() => _hasVowels = val),
                        ),
                        if (_hasVowels) ...[
                          Row(
                            children: [
                              Expanded(
                                flex: 1,
                                child: TextField(
                                  controller: _vowelsCountController,
                                  keyboardType: TextInputType.number,
                                  decoration: const InputDecoration(
                                    labelText: 'عدد أحرف العلة',
                                    border: OutlineInputBorder(),
                                  ),
                                ),
                              ),
                              const SizedBox(width: 10),
                              Expanded(
                                flex: 2,
                                child: TextField(
                                  controller: _vowelsListController,
                                  decoration: const InputDecoration(
                                    labelText: 'أحرف العلة الموجودة (مثل: و، ي)',
                                    border: OutlineInputBorder(),
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ],
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 12),

                // المحور 3: التطابقات في اللغات السامية والأجنبية
                Card(
                  child: Padding(
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Row(
                          children: [
                            Icon(Icons.language_outlined, color: AppTheme.secondaryGold, size: 20),
                            SizedBox(width: 8),
                            Text(
                              '2. التطابقات في لغات أخرى (سريانية/آرامية/عبرية/إنجليزية)',
                              style: TextStyle(fontWeight: FontWeight.bold, fontSize: 15),
                            ),
                          ],
                        ),
                        const SizedBox(height: 12),
                        TextField(
                          controller: _cognatesController,
                          maxLines: 2,
                          decoration: const InputDecoration(
                            labelText: 'التطابقات اللغوية المقارنة والمعاني المشتركة',
                            hintText: 'سجل النظائر المقارنة في السريانية، الآرامية، العبرية، أو اللغات الأخرى...',
                            border: OutlineInputBorder(),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 12),

                // المحور 4 و 5: أقدم استخدام والاستعمال المعاصر
                Card(
                  child: Padding(
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Row(
                          children: [
                            Icon(Icons.history_edu_outlined, color: AppTheme.primaryEmerald, size: 20),
                            SizedBox(width: 8),
                            Text(
                              '3. التاريخية والمعاصرة وطبيعة الدلالة',
                              style: TextStyle(fontWeight: FontWeight.bold, fontSize: 15),
                            ),
                          ],
                        ),
                        const SizedBox(height: 12),
                        TextField(
                          controller: _oldestUsageController,
                          maxLines: 2,
                          decoration: const InputDecoration(
                            labelText: 'أقدم استخدام مرصود للجذر',
                            hintText: 'هل استُخدم في لسان العرب قبل القرآن أم نتاج وإثراء قرآني؟',
                            border: OutlineInputBorder(),
                          ),
                        ),
                        const SizedBox(height: 12),
                        SwitchListTile(
                          contentPadding: EdgeInsets.zero,
                          title: const Text('هل لا زال الجذر مستخدماً ومتداولاً في لغة اليوم؟'),
                          value: _isUsedToday,
                          onChanged: (val) => setState(() => _isUsedToday = val),
                        ),
                        const SizedBox(height: 8),
                        DropdownButtonFormField<String>(
                          initialValue: _usageNature,
                          decoration: const InputDecoration(
                            labelText: 'طبيعة دلالة الجذر',
                            border: OutlineInputBorder(),
                          ),
                          items: const [
                            DropdownMenuItem(value: 'مادية', child: Text('دلالة مادية (حسية/أعيان)')),
                            DropdownMenuItem(value: 'معنوية', child: Text('دلالة معنوية (وجدانية/شعورية)')),
                            DropdownMenuItem(value: 'مجردة', child: Text('دلالة مجردة (عقلية/كلية)')),
                            DropdownMenuItem(value: 'مشتركة', child: Text('مشتركة (تجمع بين المادي والمعنوي)')),
                          ],
                          onChanged: (val) => setState(() => _usageNature = val),
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 12),

                // المحور 6: المترادفات والأضداد
                Card(
                  child: Padding(
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Row(
                          children: [
                            Icon(Icons.compare_arrows_outlined, color: AppTheme.secondaryGold, size: 20),
                            SizedBox(width: 8),
                            Text(
                              '4. المعنى المرادف والمعنى المضاد',
                              style: TextStyle(fontWeight: FontWeight.bold, fontSize: 15),
                            ),
                          ],
                        ),
                        const SizedBox(height: 12),
                        TextField(
                          controller: _synonymsController,
                          decoration: const InputDecoration(
                            labelText: 'المعنى المرادف للجذر',
                            hintText: 'مثال: علم ← درى، عرف، فقه',
                            border: OutlineInputBorder(),
                          ),
                        ),
                        const SizedBox(height: 12),
                        TextField(
                          controller: _antonymsController,
                          decoration: const InputDecoration(
                            labelText: 'المعنى المضاد والمغاير',
                            hintText: 'مثال: علم ← جهل، عمي',
                            border: OutlineInputBorder(),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 12),

                // المحور 7: رأي الباحث وملاحظاته
                Card(
                  child: Padding(
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Row(
                          children: [
                            Icon(Icons.edit_note, color: AppTheme.primaryEmerald, size: 24),
                            SizedBox(width: 8),
                            Text(
                              '5. رأي الباحث وملاحظاته وخلاصاته',
                              style: TextStyle(fontWeight: FontWeight.bold, fontSize: 15),
                            ),
                          ],
                        ),
                        const SizedBox(height: 12),
                        TextField(
                          controller: _notesController,
                          maxLines: 4,
                          decoration: const InputDecoration(
                            hintText: 'سجل هنا تحليلك اللغوي واستنباطاتك التدبرية حول هذا الجذر في النظم القرآني...',
                            border: OutlineInputBorder(),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 16),

                // بطاقة الانتقال التفاعلي لمعجم واشتقاقات الجذر
                Card(
                  color: AppTheme.primaryEmerald.withValues(alpha: 0.08),
                  child: ListTile(
                    leading: const CircleAvatar(
                      backgroundColor: AppTheme.primaryEmerald,
                      foregroundColor: Colors.white,
                      child: Icon(Icons.account_tree),
                    ),
                    title: const Text('قائمة الاشتقاقات وشجرة المعجم الصرفي'),
                    subtitle: Text('استعراض كافة مفردات (${p.targetIdentifier}) وتوزيع السور ومواضع التنزيل'),
                    trailing: const Icon(Icons.arrow_forward_ios, size: 16),
                    onTap: () => context.push('/roots/${p.targetIdentifier}'),
                  ),
                ),
                const SizedBox(height: 16),

                // قائمة الآيات والشواهد المرتبطة
                Row(
                  children: [
                    const Text(
                      'الآيات القرآنية والشواهد المرتبطة:',
                      style: TextStyle(fontWeight: FontWeight.bold, fontSize: 15),
                    ),
                    const Spacer(),
                    ElevatedButton.icon(
                      onPressed: () {
                        showDialog(
                          context: context,
                          builder: (ctx) => AddAyahLinkDialog(
                            onAdd: (ayahId, note, relType) async {
                              final notifier = ref.read(studyProjectDetailsNotifierProvider(widget.projectId).notifier);
                              await notifier.addAyahLink(ayahId, note: note, relationType: relType);
                            },
                          ),
                        );
                      },
                      icon: const Icon(Icons.add, size: 16),
                      label: const Text('إسناد آية'),
                    ),
                  ],
                ),
                const SizedBox(height: 8),

                if (full.linkedAyahs.isEmpty)
                  Container(
                    padding: const EdgeInsets.all(24),
                    alignment: Alignment.center,
                    decoration: BoxDecoration(
                      border: Border.all(color: Colors.grey.withValues(alpha: 0.2)),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: const Text('لم يتم ربط أي آيات مخصصة بعد. اضغط "إسناد آية" لإضافة شواهد.'),
                  )
                else
                  ...full.linkedAyahs.map((link) {
                    return Card(
                      margin: const EdgeInsets.only(bottom: 8),
                      child: ListTile(
                        leading: CircleAvatar(
                          backgroundColor: AppTheme.primaryEmerald.withValues(alpha: 0.1),
                          foregroundColor: AppTheme.primaryEmerald,
                          child: Text('${link.ayahNumber}'),
                        ),
                        title: Text(
                          'سورة ${link.surahName} [آية ${link.ayahNumber}] (${link.relationTypeArabic})',
                          style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13),
                        ),
                        subtitle: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const SizedBox(height: 4),
                            Text(
                              link.textUthmani,
                              style: const TextStyle(fontFamily: 'Amiri', fontSize: 15, height: 1.6),
                            ),
                            if (link.note != null && link.note!.trim().isNotEmpty) ...[
                              const SizedBox(height: 4),
                              Text('ملاحظة: ${link.note}', style: const TextStyle(fontSize: 12, color: Colors.grey)),
                            ],
                          ],
                        ),
                        trailing: IconButton(
                          icon: const Icon(Icons.delete_outline, color: Colors.red, size: 20),
                          tooltip: 'حذف الرابط',
                          onPressed: () async {
                            final notifier = ref.read(studyProjectDetailsNotifierProvider(widget.projectId).notifier);
                            await notifier.removeAyahLink(link.id);
                          },
                        ),
                      ),
                    );
                  }),
                const SizedBox(height: 32),

                // زر الحفظ النهائي العائم في الأسفل
                ElevatedButton.icon(
                  onPressed: _isSaving ? null : _saveDetails,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppTheme.primaryEmerald,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 14),
                  ),
                  icon: const Icon(Icons.save),
                  label: const Text('حفظ دراسة الجذر وتحديث الإنجاز', style: TextStyle(fontSize: 16)),
                ),
              ],
            ),
          );
        },
      ),
    );
  }
}
