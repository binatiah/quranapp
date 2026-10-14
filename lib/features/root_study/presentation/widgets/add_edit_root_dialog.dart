import 'package:flutter/material.dart';
import 'package:quranapp/app/theme/app_theme.dart';
import 'package:quranapp/core/text/arabic_normalizer.dart';
import 'package:quranapp/features/quran_search/domain/entities/quran_root.dart';

/// نافذة حوار لإضافة جذر جديد أو تعديل بيانات جذر موجود (Add/Edit Root Dialog).
class AddEditRootDialog extends StatefulWidget {
  /// الجذر الحالي في حالة التعديل، أو null في حالة إضافة جذر جديد
  final QuranRoot? rootToEdit;

  /// دالة الحفظ عند التأكيد
  final Future<void> Function({required String root, String? descriptionAr}) onSave;

  const AddEditRootDialog({
    super.key,
    this.rootToEdit,
    required this.onSave,
  });

  @override
  State<AddEditRootDialog> createState() => _AddEditRootDialogState();
}

class _AddEditRootDialogState extends State<AddEditRootDialog> {
  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _rootController;
  late final TextEditingController _descController;
  final ArabicNormalizer _normalizer = const ArabicNormalizerImpl();

  bool _isSaving = false;
  String _normalizedPreview = '';

  @override
  void initState() {
    super.initState();
    _rootController = TextEditingController(text: widget.rootToEdit?.root ?? '');
    _descController = TextEditingController(text: widget.rootToEdit?.descriptionAr ?? '');
    _updatePreview(_rootController.text);

    _rootController.addListener(() {
      _updatePreview(_rootController.text);
    });
  }

  void _updatePreview(String text) {
    final norm = _normalizer.normalizeForRootSearch(text);
    if (_normalizedPreview != norm) {
      setState(() {
        _normalizedPreview = norm;
      });
    }
  }

  @override
  void dispose() {
    _rootController.dispose();
    _descController.dispose();
    super.dispose();
  }

  Future<void> _handleSave() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() {
      _isSaving = true;
    });

    try {
      await widget.onSave(
        root: _rootController.text.trim(),
        descriptionAr: _descController.text.trim().isEmpty ? null : _descController.text.trim(),
      );
      if (mounted) {
        Navigator.of(context).pop(true);
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _isSaving = false;
        });
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(e.toString().replaceAll('Exception: ', '').replaceAll('StateError: ', '')),
            backgroundColor: Theme.of(context).colorScheme.error,
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final isEditing = widget.rootToEdit != null;

    return AlertDialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      title: Row(
        children: [
          Icon(
            isEditing ? Icons.edit_note : Icons.add_circle_outline,
            color: AppTheme.primaryEmerald,
          ),
          const SizedBox(width: 8),
          Text(isEditing ? 'تعديل الجذر اللغوي' : 'إضافة جذر قرآني جديد'),
        ],
      ),
      content: SingleChildScrollView(
        child: Form(
          key: _formKey,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // حقل الجذر
              TextFormField(
                controller: _rootController,
                decoration: InputDecoration(
                  labelText: 'الجذر (الحروف الأصلية)*',
                  hintText: 'مثال: علم أو ف-ع-ل',
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                  prefixIcon: const Icon(Icons.account_tree_outlined),
                ),
                textDirection: TextDirection.rtl,
                validator: (val) {
                  if (val == null || val.trim().isEmpty) {
                    return 'يرجى إدخال حروف الجذر';
                  }
                  if (_normalizedPreview.isEmpty) {
                    return 'تعذر استخراج حروف عربية صالحة';
                  }
                  return null;
                },
              ),
              if (_normalizedPreview.isNotEmpty) ...[
                const SizedBox(height: 8),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                  decoration: BoxDecoration(
                    color: AppTheme.primaryEmerald.withValues(alpha: 0.08),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Row(
                    children: [
                      const Icon(Icons.check_circle_outline, size: 16, color: AppTheme.primaryEmerald),
                      const SizedBox(width: 6),
                      Text(
                        'صيغة البحث المعجمي: $_normalizedPreview',
                        style: const TextStyle(
                          fontSize: 12,
                          color: AppTheme.primaryEmerald,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
              const SizedBox(height: 16),

              // حقل الوصف والمعنى
              TextFormField(
                controller: _descController,
                decoration: InputDecoration(
                  labelText: 'المعنى والبيان اللغوي (اختياري)',
                  hintText: 'أصل المعنى ودلالته في لسان العرب واستعماله القرآني...',
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                  alignLabelWithHint: true,
                ),
                maxLines: 4,
                textDirection: TextDirection.rtl,
              ),
            ],
          ),
        ),
      ),
      actions: [
        TextButton(
          onPressed: _isSaving ? null : () => Navigator.of(context).pop(false),
          child: const Text('إلغاء'),
        ),
        ElevatedButton(
          onPressed: _isSaving ? null : _handleSave,
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
              : Text(isEditing ? 'حفظ التعديلات' : 'إضافة الجذر'),
        ),
      ],
    );
  }
}
