import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:share_plus/share_plus.dart';

import '../../../../app/theme/app_theme.dart';
import '../../domain/entities/concept_study_details.dart';
import '../../domain/entities/study_project.dart';
import '../controllers/study_projects_providers.dart';
import '../widgets/add_ayah_link_dialog.dart';
import '../widgets/add_root_link_dialog.dart';

/// شاشة محرر مشروع دراسة المفاهيم والمواضيع القرآنية
class ConceptStudyProjectScreen extends ConsumerStatefulWidget {
  /// معرف المشروع
  final int projectId;

  /// المنشئ
  const ConceptStudyProjectScreen({super.key, required this.projectId});

  @override
  ConsumerState<ConceptStudyProjectScreen> createState() => _ConceptStudyProjectScreenState();
}

class _ConceptStudyProjectScreenState extends ConsumerState<ConceptStudyProjectScreen> {
  bool _isInitialized = false;

  final _termController = TextEditingController();
  ConceptDenotationType? _denotationType;
  final _quranicVsContemporaryController = TextEditingController();
  final _oppositeConceptController = TextEditingController();
  final _relatedConceptsController = TextEditingController();
  final _quranicDiscourseController = TextEditingController();
  final _notesController = TextEditingController();

  bool _isSaving = false;

  @override
  void dispose() {
    _termController.dispose();
    _quranicVsContemporaryController.dispose();
    _oppositeConceptController.dispose();
    _relatedConceptsController.dispose();
    _quranicDiscourseController.dispose();
    _notesController.dispose();
    super.dispose();
  }

  void _initFields(ConceptStudyDetails details) {
    if (_isInitialized) return;
    _termController.text = details.term;
    _denotationType = ConceptDenotationType.fromString(details.denotationType) ?? ConceptDenotationType.abstractType;
    _quranicVsContemporaryController.text = details.quranicVsContemporaryMeaning ?? '';
    _oppositeConceptController.text = details.oppositeConcept ?? '';
    _relatedConceptsController.text = details.relatedConcepts ?? '';
    _quranicDiscourseController.text = details.quranicDiscourse ?? '';
    _notesController.text = details.researcherNotes ?? '';
    _isInitialized = true;
  }

  Future<void> _saveDetails() async {
    setState(() => _isSaving = true);
    try {
      final notifier = ref.read(studyProjectDetailsNotifierProvider(widget.projectId).notifier);
      final details = ConceptStudyDetails(
        projectId: widget.projectId,
        term: _termController.text.trim().isEmpty ? 'المفهوم' : _termController.text.trim(),
        denotationType: _denotationType?.toDbValue(),
        quranicVsContemporaryMeaning: _quranicVsContemporaryController.text.trim().isEmpty ? null : _quranicVsContemporaryController.text.trim(),
        oppositeConcept: _oppositeConceptController.text.trim().isEmpty ? null : _oppositeConceptController.text.trim(),
        relatedConcepts: _relatedConceptsController.text.trim().isEmpty ? null : _relatedConceptsController.text.trim(),
        quranicDiscourse: _quranicDiscourseController.text.trim().isEmpty ? null : _quranicDiscourseController.text.trim(),
        researcherNotes: _notesController.text.trim().isEmpty ? null : _notesController.text.trim(),
      );

      await notifier.updateConceptDetails(details);
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('تم حفظ بيانات دراسة المفهوم بنجاح وتحديث نسبة الإنجاز')),
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
      const SnackBar(content: Text('تم نسخ تقرير دراسة المفهوم بصيغة Markdown إلى الحافظة')),
    );
  }

  void _shareMarkdown() {
    final notifier = ref.read(studyProjectDetailsNotifierProvider(widget.projectId).notifier);
    final md = notifier.exportMarkdown();
    SharePlus.instance.share(
      ShareParams(text: md, subject: 'تقرير مشروع دراسة مفهوم قرآني'),
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
            tooltip: 'مشاركة التقرير',
            onPressed: _shareMarkdown,
          ),
          IconButton(
            icon: const Icon(Icons.copy_all_outlined),
            tooltip: 'نسخ Markdown',
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
        error: (err, _) => Center(child: Text('حدث خطأ: $err')),
        data: (full) {
          final p = full.project;
          final d = full.conceptDetails ?? ConceptStudyDetails(projectId: widget.projectId, term: p.targetIdentifier);
          _initFields(d);

          return SingleChildScrollView(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                // بطاقة ملخص المفهوم ونسبة الإنجاز
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
                              backgroundColor: AppTheme.secondaryGold.withValues(alpha: 0.15),
                              foregroundColor: AppTheme.secondaryGold,
                              radius: 24,
                              child: const Icon(Icons.lightbulb_outline),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Row(
                                    children: [
                                      Text(
                                        'المفهوم: ${_termController.text}',
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
                                    'الآيات المستندة: ${full.linkedAyahs.length} • الجذور المرتبطة: ${full.linkedRoots.length}',
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
                            const Text('نسبة إنجاز دراسة المفهوم: ', style: TextStyle(fontSize: 13)),
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

                // 1. المفهوم أو المصطلح
                Card(
                  child: Padding(
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Row(
                          children: [
                            Icon(Icons.label_outline, color: AppTheme.primaryEmerald, size: 20),
                            SizedBox(width: 8),
                            Text('1. المفهوم أو المصطلح (العنوان)', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 15)),
                          ],
                        ),
                        const SizedBox(height: 10),
                        TextField(
                          controller: _termController,
                          decoration: const InputDecoration(
                            labelText: 'عنوان المفهوم المدروس',
                            border: OutlineInputBorder(),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 12),

                // 2. نوعه والدلالة (معنوي، قياسي، تجريدي، مادي، فكري)
                Card(
                  child: Padding(
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Row(
                          children: [
                            Icon(Icons.psychology_outlined, color: AppTheme.secondaryGold, size: 20),
                            SizedBox(width: 8),
                            Text('2. نوع الدلالة الفكرية والمعنوية للمفهوم', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 15)),
                          ],
                        ),
                        const SizedBox(height: 12),
                        DropdownButtonFormField<ConceptDenotationType>(
                          initialValue: _denotationType,
                          decoration: const InputDecoration(
                            labelText: 'صنف الدلالة',
                            border: OutlineInputBorder(),
                          ),
                          items: ConceptDenotationType.values.map((type) {
                            return DropdownMenuItem(
                              value: type,
                              child: Text(type.arabicLabel),
                            );
                          }).toList(),
                          onChanged: (val) {
                            if (val != null) setState(() => _denotationType = val);
                          },
                        ),
                        if (_denotationType != null) ...[
                          const SizedBox(height: 10),
                          Container(
                            padding: const EdgeInsets.all(12),
                            decoration: BoxDecoration(
                              color: AppTheme.secondaryGold.withValues(alpha: 0.1),
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: Row(
                              children: [
                                const Icon(Icons.info_outline, size: 18, color: AppTheme.secondaryGold),
                                const SizedBox(width: 8),
                                Expanded(
                                  child: Text(
                                    _denotationType!.explanation,
                                    style: TextStyle(fontSize: 12, color: Colors.brown.shade800),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 12),

                // 3. المعنى القرآني والمعنى المعاصر
                Card(
                  child: Padding(
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Row(
                          children: [
                            Icon(Icons.compare, color: AppTheme.primaryEmerald, size: 20),
                            SizedBox(width: 8),
                            Text('3. المعنى القرآني والمعنى المعاصر', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 15)),
                          ],
                        ),
                        const SizedBox(height: 10),
                        TextField(
                          controller: _quranicVsContemporaryController,
                          maxLines: 3,
                          decoration: const InputDecoration(
                            hintText: 'قارن بين حمولة المصطلح في لسان التنزيل القرآني وبين الاستعمالات الفلسفية أو اليومية المعاصرة...',
                            border: OutlineInputBorder(),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 12),

                // 4 و 5. المفهوم المغاير وعلاقته بمفاهيم أخرى
                Card(
                  child: Padding(
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Row(
                          children: [
                            Icon(Icons.hub_outlined, color: AppTheme.secondaryGold, size: 20),
                            SizedBox(width: 8),
                            Text('4. المفهوم المغاير (المضاد) والشبكة المفهومية', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 15)),
                          ],
                        ),
                        const SizedBox(height: 10),
                        TextField(
                          controller: _oppositeConceptController,
                          decoration: const InputDecoration(
                            labelText: 'المفهوم المغاير أو المضاد (مثل: الحق / الباطل، العدل / الظلم)',
                            border: OutlineInputBorder(),
                          ),
                        ),
                        const SizedBox(height: 12),
                        TextField(
                          controller: _relatedConceptsController,
                          maxLines: 2,
                          decoration: const InputDecoration(
                            labelText: 'علاقته بمفاهيم قرآنية أخرى (الحقل الدلالي)',
                            hintText: 'سجل المفاهيم المقترنة به مثل: اقتران الحق بالميزان، أو العدل بالقسط...',
                            border: OutlineInputBorder(),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 12),

                // 6. كيف ناقش القرآن هذا المفهوم (السياق العام عبر تقاطع الآيات)
                Card(
                  child: Padding(
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Row(
                          children: [
                            Icon(Icons.forum_outlined, color: AppTheme.primaryEmerald, size: 20),
                            SizedBox(width: 8),
                            Text('5. كيف ناقش القرآن هذا المفهوم؟ (السياق العام وتقاطع الآيات)', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 15)),
                          ],
                        ),
                        const SizedBox(height: 10),
                        TextField(
                          controller: _quranicDiscourseController,
                          maxLines: 5,
                          decoration: const InputDecoration(
                            hintText: 'بناء السياق الكلي: كيف عالج القرآن هذا المفهوم في السور المكية والمدنية، وما هي الأبعاد العقدية والتشريعية والكونية؟',
                            border: OutlineInputBorder(),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 12),

                // 7. رأي الباحث وملاحظاته
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
                            Text('6. رأي الباحث وملاحظاته واستنباطاته', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 15)),
                          ],
                        ),
                        const SizedBox(height: 10),
                        TextField(
                          controller: _notesController,
                          maxLines: 4,
                          decoration: const InputDecoration(
                            hintText: 'سجل الخلاصات المنهجية، التوصيات، والنتائج التحليلية التي توصلت إليها في هذه الدراسة...',
                            border: OutlineInputBorder(),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 16),

                // 8. قائمة الآيات التي تحدثت عن المفهوم
                Row(
                  children: [
                    const Text('قائمة الآيات التي تحدثت عن المفهوم:', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 15)),
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
                    child: const Text('لم يتم إسناد آيات بعد. اضغط "إسناد آية" لإضافة شواهد المفهوم.'),
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
                            Text(link.textUthmani, style: const TextStyle(fontFamily: 'Amiri', fontSize: 15, height: 1.6)),
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
                const SizedBox(height: 20),

                // 9. قائمة الجذور والمفردات التي تعبر عنه
                Row(
                  children: [
                    const Text('قائمة الجذور والمفردات المعبرة عنه:', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 15)),
                    const Spacer(),
                    ElevatedButton.icon(
                      onPressed: () {
                        showDialog(
                          context: context,
                          builder: (ctx) => AddRootLinkDialog(
                            onAdd: (root, note) async {
                              final notifier = ref.read(studyProjectDetailsNotifierProvider(widget.projectId).notifier);
                              await notifier.addRootLink(root, note: note);
                            },
                          ),
                        );
                      },
                      style: ElevatedButton.styleFrom(backgroundColor: AppTheme.secondaryGold, foregroundColor: Colors.white),
                      icon: const Icon(Icons.account_tree, size: 16),
                      label: const Text('إسناد جذر'),
                    ),
                  ],
                ),
                const SizedBox(height: 8),

                if (full.linkedRoots.isEmpty)
                  Container(
                    padding: const EdgeInsets.all(24),
                    alignment: Alignment.center,
                    decoration: BoxDecoration(
                      border: Border.all(color: Colors.grey.withValues(alpha: 0.2)),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: const Text('لم يتم إسناد جذور لغوية للمفهوم بعد. اضغط "إسناد جذر" لربط شبكة المعجم.'),
                  )
                else
                  ...full.linkedRoots.map((root) {
                    return Card(
                      margin: const EdgeInsets.only(bottom: 8),
                      child: ListTile(
                        leading: CircleAvatar(
                          backgroundColor: AppTheme.secondaryGold.withValues(alpha: 0.15),
                          foregroundColor: AppTheme.secondaryGold,
                          child: const Icon(Icons.account_tree_outlined),
                        ),
                        title: Text('جذر (${root.rootNormalized}) • تكرار مشتقاته في المصحف: ${root.occurrenceCount} مرة'),
                        subtitle: root.note != null && root.note!.trim().isNotEmpty
                            ? Text('دلالة الجذر: ${root.note}')
                            : null,
                        trailing: IconButton(
                          icon: const Icon(Icons.delete_outline, color: Colors.red, size: 20),
                          tooltip: 'حذف الرابط',
                          onPressed: () async {
                            final notifier = ref.read(studyProjectDetailsNotifierProvider(widget.projectId).notifier);
                            await notifier.removeRootLink(root.id);
                          },
                        ),
                      ),
                    );
                  }),
                const SizedBox(height: 32),

                // زر الحفظ النهائي
                ElevatedButton.icon(
                  onPressed: _isSaving ? null : _saveDetails,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppTheme.primaryEmerald,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 14),
                  ),
                  icon: const Icon(Icons.save),
                  label: const Text('حفظ دراسة المفهوم وتحديث الإنجاز', style: TextStyle(fontSize: 16)),
                ),
              ],
            ),
          );
        },
      ),
    );
  }
}
