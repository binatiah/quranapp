import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:quranapp/app/theme/app_theme.dart';
import 'package:quranapp/core/database/quran_database.dart';
import 'package:quranapp/core/text/arabic_normalizer.dart';
import 'package:quranapp/features/quran_search/data/services/root_resolver_impl.dart';
import 'package:quranapp/features/quran_search/domain/entities/quran_word.dart';
import 'package:quranapp/features/quran_search/domain/entities/root_candidate.dart';
import 'package:quranapp/features/vocabulary/presentation/controllers/words_management_providers.dart';

/// نافذة حوار إعادة ربط الكلمة القرآنية بالجذر اللغوي الصحيح مع مقترحات صرفية ذكية.
class RelinkWordDialog extends ConsumerStatefulWidget {
  final QuranWord word;
  final Future<int> Function({required String newRoot, required bool applyToAll}) onRelink;

  const RelinkWordDialog({
    super.key,
    required this.word,
    required this.onRelink,
  });

  @override
  ConsumerState<RelinkWordDialog> createState() => _RelinkWordDialogState();
}

class _RelinkWordDialogState extends ConsumerState<RelinkWordDialog> {
  late final TextEditingController _rootController;
  final _formKey = GlobalKey<FormState>();

  bool _isSaving = false;
  bool _applyToAll = false;
  int _occurrencesCount = 1;
  bool _isLoadingOccurrences = true;

  List<RootCandidate> _candidates = [];
  bool _isLoadingCandidates = true;

  @override
  void initState() {
    super.initState();
    _rootController = TextEditingController(text: widget.word.root ?? '');
    _loadMetadata();
  }

  Future<void> _loadMetadata() async {
    // 1. جلب عدد مرات ورود الكلمة المطابقة
    try {
      final repo = ref.read(wordManagementRepositoryProvider);
      final count = await repo.getWordOccurrencesCount(widget.word.wordNormalized);
      if (mounted) {
        setState(() {
          _occurrencesCount = count;
          _isLoadingOccurrences = false;
        });
      }
    } catch (_) {
      if (mounted) {
        setState(() {
          _isLoadingOccurrences = false;
        });
      }
    }

    // 2. اقتراح الجذور الصرفية المناسبة للكلمة عبر محرك RootResolver
    try {
      final resolver = RootResolverImpl(
        database: QuranDatabase.instance,
        normalizer: const ArabicNormalizerImpl(),
      );
      final list = await resolver.resolve(widget.word.wordNormalized);
      if (mounted) {
        setState(() {
          _candidates = list;
          _isLoadingCandidates = false;
        });
      }
    } catch (_) {
      if (mounted) {
        setState(() {
          _isLoadingCandidates = false;
        });
      }
    }
  }

  @override
  void dispose() {
    _rootController.dispose();
    super.dispose();
  }

  Future<void> _handleConfirm() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() {
      _isSaving = true;
    });

    try {
      final updatedCount = await widget.onRelink(
        newRoot: _rootController.text.trim(),
        applyToAll: _applyToAll,
      );

      if (mounted) {
        Navigator.of(context).pop(updatedCount);
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _isSaving = false;
        });
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(e.toString().replaceAll('Exception: ', '').replaceAll('ArgumentError: ', '')),
            backgroundColor: Theme.of(context).colorScheme.error,
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      title: const Row(
        children: [
          Icon(Icons.alt_route, color: AppTheme.primaryEmerald),
          SizedBox(width: 8),
          Text('إعادة ربط الكلمة بالجذر'),
        ],
      ),
      content: SingleChildScrollView(
        child: Form(
          key: _formKey,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // بطاقة سياق الكلمة
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(
                  color: AppTheme.primaryEmerald.withValues(alpha: 0.08),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(
                    color: AppTheme.primaryEmerald.withValues(alpha: 0.2),
                  ),
                ),
                child: Column(
                  children: [
                    Text(
                      widget.word.wordUthmani,
                      style: const TextStyle(
                        fontSize: 26,
                        fontWeight: FontWeight.bold,
                        color: AppTheme.primaryEmerald,
                      ),
                    ),
                    const SizedBox(height: 6),
                    Text(
                      '${widget.word.surahName ?? 'سورة ${widget.word.surahId}'} - الآية ${widget.word.ayahNumber} (الموضع ${widget.word.wordPosition})',
                      style: TextStyle(
                        fontSize: 12,
                        color: Theme.of(context).textTheme.bodySmall?.color,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      'الجذر الحالي: ${widget.word.root ?? 'غير مرتبط بجذر'}',
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.bold,
                        color: widget.word.root != null ? AppTheme.secondaryGold : Colors.red,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 16),

              // مقترحات الجذور الذكية
              if (_isLoadingCandidates)
                const Padding(
                  padding: EdgeInsets.symmetric(vertical: 8),
                  child: Row(
                    children: [
                      SizedBox(width: 16, height: 16, child: CircularProgressIndicator(strokeWidth: 2)),
                      SizedBox(width: 8),
                      Text('جاري تحليل واقتراح الجذور الصرفية...', style: TextStyle(fontSize: 12)),
                    ],
                  ),
                )
              else if (_candidates.isNotEmpty) ...[
                const Text(
                  'مقترحات الجذور الصرفية (انقر للاختيار):',
                  style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 6),
                Wrap(
                  spacing: 6,
                  runSpacing: 6,
                  children: _candidates.take(5).map((candidate) {
                    final percentage = (candidate.confidence * 100).toInt();
                    final isSelected = _rootController.text.trim() == candidate.root;

                    return ActionChip(
                      avatar: isSelected
                          ? const Icon(Icons.check, size: 14, color: Colors.white)
                          : null,
                      backgroundColor: isSelected
                          ? AppTheme.primaryEmerald
                          : AppTheme.primaryEmerald.withValues(alpha: 0.08),
                      label: Text(
                        '${candidate.root} ($percentage%)',
                        style: TextStyle(
                          fontSize: 12,
                          color: isSelected ? Colors.white : AppTheme.primaryEmerald,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      onPressed: () {
                        setState(() {
                          _rootController.text = candidate.root;
                        });
                      },
                    );
                  }).toList(),
                ),
                const SizedBox(height: 14),
              ],

              // حقل إدخال الجذر الجديد
              TextFormField(
                controller: _rootController,
                decoration: InputDecoration(
                  labelText: 'الجذر الصرفي الجديد*',
                  hintText: 'مثال: رحم أو كتب',
                  prefixIcon: const Icon(Icons.edit),
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                ),
                textDirection: TextDirection.rtl,
                validator: (val) {
                  if (val == null || val.trim().isEmpty) {
                    return 'يرجى إدخال الجذر الصحيح';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 14),

              // خيار التطبيق على جميع المواضع
              if (_isLoadingOccurrences)
                const SizedBox.shrink()
              else if (_occurrencesCount > 1) ...[
                Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: Theme.of(context).cardColor,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: Theme.of(context).dividerColor),
                  ),
                  child: CheckboxListTile(
                    contentPadding: EdgeInsets.zero,
                    dense: true,
                    value: _applyToAll,
                    activeColor: AppTheme.primaryEmerald,
                    title: Text(
                      'تطبيق على جميع مواضع الكلمة المطابقة في المصحف ($_occurrencesCount موضعاً)',
                      style: const TextStyle(fontSize: 13, fontWeight: FontWeight.bold),
                    ),
                    subtitle: const Text(
                      'سيوفر عليك الوقت بربط كافة الكلمات المشابهة لنفس الجذر بضغطة واحدة.',
                      style: TextStyle(fontSize: 11),
                    ),
                    onChanged: (val) {
                      setState(() {
                        _applyToAll = val ?? false;
                      });
                    },
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
      actions: [
        TextButton(
          onPressed: _isSaving ? null : () => Navigator.of(context).pop(),
          child: const Text('إلغاء'),
        ),
        ElevatedButton(
          onPressed: _isSaving ? null : _handleConfirm,
          style: ElevatedButton.styleFrom(
            backgroundColor: AppTheme.primaryEmerald,
            foregroundColor: Colors.white,
          ),
          child: _isSaving
              ? const SizedBox(
                  width: 20,
                  height: 20,
                  child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                )
              : const Text('تأكيد الربط'),
        ),
      ],
    );
  }
}
