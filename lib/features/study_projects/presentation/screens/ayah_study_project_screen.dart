import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:share_plus/share_plus.dart';

import '../../../../app/theme/app_theme.dart';
import '../../domain/entities/ayah_study_details.dart';
import '../controllers/study_projects_providers.dart';
import '../widgets/add_ayah_link_dialog.dart';

/// شاشة محرر مشروع دراسة الآيات القرآنية
class AyahStudyProjectScreen extends ConsumerStatefulWidget {
  /// معرف المشروع
  final int projectId;

  /// المنشئ
  const AyahStudyProjectScreen({super.key, required this.projectId});

  @override
  ConsumerState<AyahStudyProjectScreen> createState() => _AyahStudyProjectScreenState();
}

class _AyahStudyProjectScreenState extends ConsumerState<AyahStudyProjectScreen> {
  bool _isInitialized = false;

  final _topicController = TextEditingController();
  final _traditionalTafseerController = TextEditingController();
  final _revelationContextController = TextEditingController();
  final _crossReferencesController = TextEditingController();
  final _otherScripturesController = TextEditingController();
  final _apparentConceptController = TextEditingController();
  String? _rulingOrStatus;
  final _notesController = TextEditingController();

  bool _isSaving = false;

  @override
  void dispose() {
    _topicController.dispose();
    _traditionalTafseerController.dispose();
    _revelationContextController.dispose();
    _crossReferencesController.dispose();
    _otherScripturesController.dispose();
    _apparentConceptController.dispose();
    _notesController.dispose();
    super.dispose();
  }

  void _initFields(AyahStudyDetails details) {
    if (_isInitialized) return;
    _topicController.text = details.topic ?? '';
    _traditionalTafseerController.text = details.traditionalTafseer ?? '';
    _revelationContextController.text = details.revelationContext ?? '';
    _crossReferencesController.text = details.crossReferences ?? '';
    _otherScripturesController.text = details.otherScripturesParallels ?? '';
    _apparentConceptController.text = details.apparentConcept ?? '';
    _rulingOrStatus = details.rulingOrStatus ?? 'حكم شرعي';
    _notesController.text = details.researcherNotes ?? '';
    _isInitialized = true;
  }

  Future<void> _saveDetails(AyahStudyDetails baseDetails) async {
    setState(() => _isSaving = true);
    try {
      final notifier = ref.read(studyProjectDetailsNotifierProvider(widget.projectId).notifier);
      final details = baseDetails.copyWith(
        topic: _topicController.text.trim().isEmpty ? null : _topicController.text.trim(),
        traditionalTafseer: _traditionalTafseerController.text.trim().isEmpty ? null : _traditionalTafseerController.text.trim(),
        revelationContext: _revelationContextController.text.trim().isEmpty ? null : _revelationContextController.text.trim(),
        crossReferences: _crossReferencesController.text.trim().isEmpty ? null : _crossReferencesController.text.trim(),
        otherScripturesParallels: _otherScripturesController.text.trim().isEmpty ? null : _otherScripturesController.text.trim(),
        apparentConcept: _apparentConceptController.text.trim().isEmpty ? null : _apparentConceptController.text.trim(),
        rulingOrStatus: _rulingOrStatus,
        researcherNotes: _notesController.text.trim().isEmpty ? null : _notesController.text.trim(),
      );

      await notifier.updateAyahDetails(details);
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('تم حفظ بيانات دراسة الآية بنجاح وتحديث نسبة الإنجاز')),
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
      ShareParams(text: md, subject: 'تقرير مشروع دراسة آية قرآنية'),
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
            onPressed: _isSaving ? null : () {
              final d = projectState.value?.ayahDetails;
              if (d != null) _saveDetails(d);
            },
          ),
        ],
      ),
      body: projectState.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (err, _) => Center(child: Text('حدث خطأ: $err')),
        data: (full) {
          final p = full.project;
          final d = full.ayahDetails ??
              AyahStudyDetails(
                projectId: widget.projectId,
                surahId: 1,
                ayahNumber: 1,
              );
          _initFields(d);

          return SingleChildScrollView(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                // بطاقة الآية المستهدفة والنص العثماني
                Card(
                  elevation: 3,
                  color: Theme.of(context).brightness == Brightness.light
                      ? AppTheme.primaryEmerald
                      : AppTheme.darkCard,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                  child: Padding(
                    padding: const EdgeInsets.all(20),
                    child: Column(
                      children: [
                        Row(
                          children: [
                            const Icon(Icons.auto_stories, color: AppTheme.goldAccent, size: 24),
                            const SizedBox(width: 8),
                            Text(
                              'سورة ${full.targetSurahName ?? "السورة ${d.surahId}"} [الآية ${d.ayahNumber}]',
                              style: const TextStyle(
                                color: Colors.white,
                                fontWeight: FontWeight.bold,
                                fontSize: 16,
                              ),
                            ),
                            const Spacer(),
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                              decoration: BoxDecoration(
                                color: Colors.black.withValues(alpha: 0.25),
                                borderRadius: BorderRadius.circular(12),
                              ),
                              child: Text(
                                p.status.arabicLabel,
                                style: const TextStyle(color: Colors.white, fontSize: 12),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 14),
                        Text(
                          full.targetVerseText ?? 'جارِ قراءة النص العثماني...',
                          textAlign: TextAlign.center,
                          style: const TextStyle(
                            fontFamily: 'Amiri',
                            fontSize: 20,
                            fontWeight: FontWeight.bold,
                            height: 1.8,
                            color: Colors.white,
                          ),
                        ),
                        const SizedBox(height: 16),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            OutlinedButton.icon(
                              onPressed: () {
                                context.push('/reader/${d.surahId}?ayah=${d.ayahNumber}');
                              },
                              style: OutlinedButton.styleFrom(
                                foregroundColor: Colors.white,
                                side: const BorderSide(color: Colors.white70),
                              ),
                              icon: const Icon(Icons.menu_book, size: 16),
                              label: const Text('فتح في المصحف'),
                            ),
                            const SizedBox(width: 12),
                            OutlinedButton.icon(
                              onPressed: () {
                                context.push('/ayah-context', extra: {
                                  'surahId': d.surahId,
                                  'surahName': full.targetSurahName ?? '',
                                  'ayahNumber': d.ayahNumber,
                                  'globalAyahNumber': d.globalAyahNumber ?? 1,
                                  'textUthmani': full.targetVerseText ?? '',
                                  'matchedWords': <String>[],
                                });
                              },
                              style: OutlinedButton.styleFrom(
                                foregroundColor: Colors.white,
                                side: const BorderSide(color: Colors.white70),
                              ),
                              icon: const Icon(Icons.compare_arrows, size: 16),
                              label: const Text('عرض السياق'),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 12),

                // شريط التقدم
                Card(
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                    child: Row(
                      children: [
                        const Text('نسبة إنجاز دراسة الآية: ', style: TextStyle(fontSize: 13)),
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
                  ),
                ),
                const SizedBox(height: 16),

                // 1. موضوع الآية وعن ماذا تتحدث
                Card(
                  child: Padding(
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Row(
                          children: [
                            Icon(Icons.topic_outlined, color: AppTheme.primaryEmerald, size: 20),
                            SizedBox(width: 8),
                            Text('1. موضوع الآية وعن ماذا تتحدث؟', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 15)),
                          ],
                        ),
                        const SizedBox(height: 10),
                        TextField(
                          controller: _topicController,
                          maxLines: 2,
                          decoration: const InputDecoration(
                            hintText: 'حدد المحور الموضوعي العام للآية الكريمة وسياقها في السورة...',
                            border: OutlineInputBorder(),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 12),

                // 2. تفسير الآية من الموروث
                Card(
                  child: Padding(
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Row(
                          children: [
                            Icon(Icons.menu_book, color: AppTheme.secondaryGold, size: 20),
                            SizedBox(width: 8),
                            Text('2. تفسير الآية من الموروث المعتمد', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 15)),
                          ],
                        ),
                        const SizedBox(height: 10),
                        TextField(
                          controller: _traditionalTafseerController,
                          maxLines: 4,
                          decoration: const InputDecoration(
                            hintText: 'لخّص أقوال أئمة التفسير (الطبري، القرطبي، ابن كثير، السعدي، الرازي)...',
                            border: OutlineInputBorder(),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 12),

                // 3. زمن وسبب النزول
                Card(
                  child: Padding(
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Row(
                          children: [
                            Icon(Icons.history, color: AppTheme.primaryEmerald, size: 20),
                            SizedBox(width: 8),
                            Text('3. زمن ومناسبات وسبب النزول', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 15)),
                          ],
                        ),
                        const SizedBox(height: 10),
                        TextField(
                          controller: _revelationContextController,
                          maxLines: 3,
                          decoration: const InputDecoration(
                            hintText: 'بيّن مكان وزمن التنزيل (مكي/مدني)، والوقائع والمناسبات المسببة لنزول الآية...',
                            border: OutlineInputBorder(),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 12),

                // 4. علاقتها بآيات أخرى وتقاطعاتها
                Card(
                  child: Padding(
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Row(
                          children: [
                            Icon(Icons.alt_route_outlined, color: AppTheme.secondaryGold, size: 20),
                            SizedBox(width: 8),
                            Text('4. علاقتها بآيات أخرى والآيات المفسرة لها', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 15)),
                          ],
                        ),
                        const SizedBox(height: 10),
                        TextField(
                          controller: _crossReferencesController,
                          maxLines: 3,
                          decoration: const InputDecoration(
                            hintText: 'كيف تفسر الآيات الأخرى هذه الآية؟ وما هي تقاطعاتها في سور القرآن الأخرى؟',
                            border: OutlineInputBorder(),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 12),

                // 5. هل لها تشابهات في كتب مقدسة أخرى؟
                Card(
                  child: Padding(
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Row(
                          children: [
                            Icon(Icons.library_books_outlined, color: AppTheme.primaryEmerald, size: 20),
                            SizedBox(width: 8),
                            Text('5. التشابهات في كتب وشرائع مقدسة سابقة', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 15)),
                          ],
                        ),
                        const SizedBox(height: 10),
                        TextField(
                          controller: _otherScripturesController,
                          maxLines: 2,
                          decoration: const InputDecoration(
                            hintText: 'سجل المقارنات والتقاطعات التاريخية أو التشريعية مع النصوص الدينية السابقة...',
                            border: OutlineInputBorder(),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 12),

                // 6 و 7. المفهوم الظاهر وطبيعة الدلالة (حكم شرعي أم غيره)
                Card(
                  child: Padding(
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Row(
                          children: [
                            Icon(Icons.gavel_outlined, color: AppTheme.secondaryGold, size: 20),
                            SizedBox(width: 8),
                            Text('6. المفهوم الظاهر وطبيعة الدلالة التشريعية', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 15)),
                          ],
                        ),
                        const SizedBox(height: 10),
                        TextField(
                          controller: _apparentConceptController,
                          maxLines: 2,
                          decoration: const InputDecoration(
                            labelText: 'المفهوم الظاهر والمتبادر من الآية',
                            border: OutlineInputBorder(),
                          ),
                        ),
                        const SizedBox(height: 12),
                        DropdownButtonFormField<String>(
                          initialValue: _rulingOrStatus,
                          decoration: const InputDecoration(
                            labelText: 'هل هي دليل على حكم شرعي أم غيره؟',
                            border: OutlineInputBorder(),
                          ),
                          items: const [
                            DropdownMenuItem(value: 'حكم شرعي تكليفي', child: Text('حكم شرعي تكليفي (وجوب، تحريم، ندب...)')),
                            DropdownMenuItem(value: 'حكم وضعي', child: Text('حكم وضعي (شرط، سبب، مانع)')),
                            DropdownMenuItem(value: 'دلالة عقدية إيمانية', child: Text('دلالة عقدية إيمانية (توحيد، صفات، غيبيات)')),
                            DropdownMenuItem(value: 'قيمة أخلاقية وسلوكية', child: Text('قيمة أخلاقية وسلوكية')),
                            DropdownMenuItem(value: 'سنة كونية وتاريخية', child: Text('سُنّة كونية وتاريخية في الأمم')),
                          ],
                          onChanged: (val) => setState(() => _rulingOrStatus = val),
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 12),

                // 8. رأي الباحث وملاحظاته
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
                            Text('7. رأي الباحث وملاحظاته وخلاصاته التدبرية', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 15)),
                          ],
                        ),
                        const SizedBox(height: 10),
                        TextField(
                          controller: _notesController,
                          maxLines: 4,
                          decoration: const InputDecoration(
                            hintText: 'دوّن هنا استنباطاتك الخاصة، وإشارات التدبر، واللطائف البلاغية والتربوية المستفادة...',
                            border: OutlineInputBorder(),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 16),

                // 9. قائمة الآيات ذات الصلة
                Row(
                  children: [
                    const Text('قائمة الآيات القرآنية ذات الصلة:', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 15)),
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
                    child: const Text('لم يتم ربط آيات ذات صلة بعد. اضغط "إسناد آية" لإضافة التقاطعات.'),
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
                const SizedBox(height: 32),

                // زر الحفظ النهائي
                ElevatedButton.icon(
                  onPressed: _isSaving ? null : () => _saveDetails(d),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppTheme.primaryEmerald,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 14),
                  ),
                  icon: const Icon(Icons.save),
                  label: const Text('حفظ دراسة الآية وتحديث الإنجاز', style: TextStyle(fontSize: 16)),
                ),
              ],
            ),
          );
        },
      ),
    );
  }
}
