import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../app/theme/app_theme.dart';
import '../../../../core/text/arabic_normalizer.dart';
import '../../../quran_reader/presentation/controllers/quran_providers.dart';
import '../../domain/entities/study_project.dart';
import '../../domain/entities/root_study_details.dart';
import '../../domain/entities/ayah_study_details.dart';
import '../../domain/entities/concept_study_details.dart';
import '../../domain/services/study_project_analyzer_service.dart';
import '../controllers/study_projects_providers.dart';

/// نافذة حوار ذكية لإنشاء مشروع دراسة قرآني جديد مع الاستنتاج الآلي
class CreateStudyProjectDialog extends ConsumerStatefulWidget {
  /// النمط الأولي المقترح
  final StudyProjectType? initialType;

  /// الهدف الأولي المقترح (اسم جذر أو معرف آية)
  final String? initialTarget;

  /// رقم السورة الأولي (في حال إنشاء مشروع من عارض الآيات)
  final int? initialSurahId;

  /// رقم الآية الأولي
  final int? initialAyahNumber;

  /// المنشئ
  const CreateStudyProjectDialog({
    super.key,
    this.initialType,
    this.initialTarget,
    this.initialSurahId,
    this.initialAyahNumber,
  });

  @override
  ConsumerState<CreateStudyProjectDialog> createState() => _CreateStudyProjectDialogState();
}

class _CreateStudyProjectDialogState extends ConsumerState<CreateStudyProjectDialog> {
  late StudyProjectType _selectedType;
  final _titleController = TextEditingController();
  final _targetController = TextEditingController();
  final _descController = TextEditingController();
  final _analyzer = const StudyProjectAnalyzerService();
  final _normalizer = const ArabicNormalizerImpl();

  int _selectedSurahId = 1;
  int _selectedAyahNumber = 1;
  bool _isSaving = false;
  String? _rootAnalysisInfo;

  @override
  void initState() {
    super.initState();
    _selectedType = widget.initialType ?? StudyProjectType.root;

    if (widget.initialTarget != null) {
      _targetController.text = widget.initialTarget!;
    }

    if (widget.initialSurahId != null) {
      _selectedSurahId = widget.initialSurahId!;
    }
    if (widget.initialAyahNumber != null) {
      _selectedAyahNumber = widget.initialAyahNumber!;
    }

    _generateDefaultValues();
  }

  @override
  void dispose() {
    _titleController.dispose();
    _targetController.dispose();
    _descController.dispose();
    super.dispose();
  }

  void _generateDefaultValues() {
    if (_selectedType == StudyProjectType.root) {
      final root = _targetController.text.trim().isEmpty ? 'علم' : _targetController.text.trim();
      _titleController.text = 'دراسة جذر ($root) في القرآن';
      _updateRootAnalysis(root);
    } else if (_selectedType == StudyProjectType.ayah) {
      _targetController.text = '$_selectedSurahId:$_selectedAyahNumber';
      _titleController.text = 'دراسة الآية [$_selectedAyahNumber] من السورة $_selectedSurahId';
      _rootAnalysisInfo = null;
    } else {
      final term = _targetController.text.trim().isEmpty ? 'الحق' : _targetController.text.trim();
      _titleController.text = 'مفهوم ($term) في الخطاب القرآني';
      _rootAnalysisInfo = null;
    }
  }

  void _updateRootAnalysis(String root) {
    if (root.trim().isEmpty) {
      setState(() => _rootAnalysisInfo = null);
      return;
    }
    final normalized = _normalizer.normalizeForRootSearch(root);
    final analysis = _analyzer.analyzeRoot(normalized);
    setState(() {
      _rootAnalysisInfo =
          'النوع المستنتج: جذر ${analysis.rootType} • أحرف العلة: ${analysis.hasVowels ? analysis.vowelsList : "لا يوجد"}';
    });
  }

  Future<void> _handleSave() async {
    final title = _titleController.text.trim();
    final target = _targetController.text.trim();

    if (title.isEmpty || target.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('يرجى ملء عنوان المشروع والمستهدف')),
      );
      return;
    }

    setState(() => _isSaving = true);

    try {
      final now = DateTime.now();
      final project = StudyProject(
        title: title,
        projectType: _selectedType,
        targetIdentifier: target,
        description: _descController.text.trim().isEmpty ? null : _descController.text.trim(),
        createdAt: now,
        updatedAt: now,
        status: StudyProjectStatus.draft,
        progress: 0.05,
      );

      RootStudyDetails? rootDetails;
      AyahStudyDetails? ayahDetails;
      ConceptStudyDetails? conceptDetails;

      if (_selectedType == StudyProjectType.root) {
        final analysis = _analyzer.analyzeRoot(target);
        rootDetails = RootStudyDetails(
          projectId: 0,
          rootType: analysis.rootType,
          hasVowels: analysis.hasVowels,
          vowelsCount: analysis.vowelsCount,
          vowelsList: analysis.vowelsList,
          isUsedToday: true,
        );
      } else if (_selectedType == StudyProjectType.ayah) {
        ayahDetails = AyahStudyDetails(
          projectId: 0,
          surahId: _selectedSurahId,
          ayahNumber: _selectedAyahNumber,
        );
      } else {
        conceptDetails = ConceptStudyDetails(
          projectId: 0,
          term: target,
        );
      }

      final projectId = await ref
          .read(studyProjectsListNotifierProvider.notifier)
          .createProject(
            project,
            rootDetails: rootDetails,
            ayahDetails: ayahDetails,
            conceptDetails: conceptDetails,
          );

      if (!mounted) return;
      Navigator.of(context).pop();

      // التوجيه إلى شاشة محرر المشروع المتخصص
      switch (_selectedType) {
        case StudyProjectType.root:
          context.push('/study-projects/root/$projectId');
          break;
        case StudyProjectType.ayah:
          context.push('/study-projects/ayah/$projectId');
          break;
        case StudyProjectType.concept:
          context.push('/study-projects/concept/$projectId');
          break;
      }
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('فشل إنشاء المشروع: $e')),
      );
    } finally {
      if (mounted) setState(() => _isSaving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final surahsAsync = ref.watch(surahListNotifierProvider);
    final surahs = surahsAsync.uiState.data ?? [];

    return Dialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      child: Container(
        width: MediaQuery.of(context).size.width > 600 ? 540 : double.infinity,
        padding: const EdgeInsets.all(24),
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // ترويسة النافذة
              Row(
                children: [
                  CircleAvatar(
                    backgroundColor: AppTheme.primaryEmerald.withValues(alpha: 0.15),
                    foregroundColor: AppTheme.primaryEmerald,
                    child: const Icon(Icons.create_new_folder_outlined),
                  ),
                  const SizedBox(width: 12),
                  const Expanded(
                    child: Text(
                      'فتح مشروع دراسة جديد',
                      style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                    ),
                  ),
                  IconButton(
                    icon: const Icon(Icons.close),
                    onPressed: () => Navigator.of(context).pop(),
                  ),
                ],
              ),
              const Divider(height: 24),

              // اختيار نمط المشروع
              const Text(
                'اختر نمط ومسار الدراسة:',
                style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
              ),
              const SizedBox(height: 10),
              SegmentedButton<StudyProjectType>(
                segments: const [
                  ButtonSegment(
                    value: StudyProjectType.root,
                    label: Text('جذر لغوي'),
                    icon: Icon(Icons.account_tree_outlined),
                  ),
                  ButtonSegment(
                    value: StudyProjectType.ayah,
                    label: Text('آية قرآنية'),
                    icon: Icon(Icons.menu_book_outlined),
                  ),
                  ButtonSegment(
                    value: StudyProjectType.concept,
                    label: Text('مفهوم موضوعي'),
                    icon: Icon(Icons.lightbulb_outline),
                  ),
                ],
                selected: {_selectedType},
                onSelectionChanged: (newSelection) {
                  setState(() {
                    _selectedType = newSelection.first;
                    _generateDefaultValues();
                  });
                },
              ),
              const SizedBox(height: 18),

              // حقول الإدخال المتغيرة حسب النمط
              if (_selectedType == StudyProjectType.root) ...[
                TextField(
                  controller: _targetController,
                  decoration: const InputDecoration(
                    labelText: 'الجذر اللغوي المستهدف',
                    hintText: 'مثال: علم، ضرب، رحم، وعد',
                    prefixIcon: Icon(Icons.spellcheck),
                    border: OutlineInputBorder(),
                  ),
                  onChanged: (val) {
                    _titleController.text = 'دراسة جذر (${val.trim()}) في القرآن';
                    _updateRootAnalysis(val);
                  },
                ),
                if (_rootAnalysisInfo != null) ...[
                  const SizedBox(height: 8),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                    decoration: BoxDecoration(
                      color: AppTheme.primaryEmerald.withValues(alpha: 0.08),
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(color: AppTheme.primaryEmerald.withValues(alpha: 0.2)),
                    ),
                    child: Row(
                      children: [
                        const Icon(Icons.auto_awesome, size: 18, color: AppTheme.primaryEmerald),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            _rootAnalysisInfo!,
                            style: const TextStyle(fontSize: 12, color: AppTheme.primaryEmerald),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ] else if (_selectedType == StudyProjectType.ayah) ...[
                Row(
                  children: [
                    Expanded(
                      flex: 2,
                      child: DropdownButtonFormField<int>(
                        initialValue: _selectedSurahId,
                        decoration: const InputDecoration(
                          labelText: 'السورة',
                          border: OutlineInputBorder(),
                        ),
                        items: surahs.map((s) {
                          return DropdownMenuItem(
                            value: s.id,
                            child: Text('${s.id}. ${s.nameArabic}'),
                          );
                        }).toList(),
                        onChanged: (val) {
                          if (val != null) {
                            setState(() {
                              _selectedSurahId = val;
                              _selectedAyahNumber = 1;
                              final surahObj = surahs.firstWhere((s) => s.id == val);
                              _targetController.text = '$_selectedSurahId:$_selectedAyahNumber';
                              _titleController.text =
                                  'دراسة الآية [$_selectedAyahNumber] من سورة ${surahObj.nameArabic}';
                            });
                          }
                        },
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      flex: 1,
                      child: TextFormField(
                        initialValue: '$_selectedAyahNumber',
                        keyboardType: TextInputType.number,
                        decoration: const InputDecoration(
                          labelText: 'رقم الآية',
                          border: OutlineInputBorder(),
                        ),
                        onChanged: (val) {
                          final num = int.tryParse(val) ?? 1;
                          _selectedAyahNumber = num;
                          _targetController.text = '$_selectedSurahId:$_selectedAyahNumber';
                          final surahObj = surahs.where((s) => s.id == _selectedSurahId);
                          final surahName = surahObj.isNotEmpty ? surahObj.first.nameArabic : '$_selectedSurahId';
                          _titleController.text = 'دراسة الآية [$_selectedAyahNumber] من سورة $surahName';
                        },
                      ),
                    ),
                  ],
                ),
              ] else ...[
                TextField(
                  controller: _targetController,
                  decoration: const InputDecoration(
                    labelText: 'اسم المفهوم أو المصطلح',
                    hintText: 'مثال: الحق، العدل، التربية، التجارة، السعي',
                    prefixIcon: Icon(Icons.label_outline),
                    border: OutlineInputBorder(),
                  ),
                  onChanged: (val) {
                    _titleController.text = 'مفهوم (${val.trim()}) في الخطاب القرآني';
                  },
                ),
              ],
              const SizedBox(height: 16),

              // عنوان المشروع
              TextField(
                controller: _titleController,
                decoration: const InputDecoration(
                  labelText: 'عنوان المشروع',
                  border: OutlineInputBorder(),
                  prefixIcon: Icon(Icons.title),
                ),
              ),
              const SizedBox(height: 16),

              // الوصف أو التمهيد
              TextField(
                controller: _descController,
                maxLines: 2,
                decoration: const InputDecoration(
                  labelText: 'وصف أو تمهيد للمشروع (اختياري)',
                  border: OutlineInputBorder(),
                  prefixIcon: Icon(Icons.description_outlined),
                ),
              ),
              const SizedBox(height: 24),

              // أزرار الإجراء
              Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  TextButton(
                    onPressed: _isSaving ? null : () => Navigator.of(context).pop(),
                    child: const Text('إلغاء'),
                  ),
                  const SizedBox(width: 12),
                  ElevatedButton.icon(
                    onPressed: _isSaving ? null : _handleSave,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppTheme.primaryEmerald,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                    ),
                    icon: _isSaving
                        ? const SizedBox(
                            width: 16,
                            height: 16,
                            child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                          )
                        : const Icon(Icons.rocket_launch_outlined, size: 18),
                    label: Text(_isSaving ? 'جارِ الفتح...' : 'بدء المشروع الآن'),
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
