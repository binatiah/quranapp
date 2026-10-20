import 'package:flutter/material.dart';

import '../../../../app/theme/app_theme.dart';
import '../../../../core/database/quran_database.dart';
import '../../../../core/text/arabic_normalizer.dart';

/// نافذة حوار لإسناد وربط جذر لغوي بمشروع دراسة المفهوم مع فحص عدد تكراراته في المصحف
class AddRootLinkDialog extends StatefulWidget {
  /// دالة الاستدعاء عند الحفظ
  final Future<void> Function(String rootNormalized, String? note) onAdd;

  /// المنشئ
  const AddRootLinkDialog({super.key, required this.onAdd});

  @override
  State<AddRootLinkDialog> createState() => _AddRootLinkDialogState();
}

class _AddRootLinkDialogState extends State<AddRootLinkDialog> {
  final _rootController = TextEditingController();
  final _noteController = TextEditingController();
  final _normalizer = const ArabicNormalizerImpl();

  int? _occurrenceCount;
  bool _isChecking = false;
  bool _isSaving = false;

  @override
  void dispose() {
    _rootController.dispose();
    _noteController.dispose();
    super.dispose();
  }

  Future<void> _checkRoot(String value) async {
    final normalized = _normalizer.normalizeForRootSearch(value.trim());
    if (normalized.isEmpty) {
      setState(() => _occurrenceCount = null);
      return;
    }

    setState(() => _isChecking = true);
    try {
      final rows = await QuranDatabase.instance.query(
        sql: 'SELECT COUNT(*) as cnt FROM words WHERE root_normalized = ?;',
        arguments: [normalized],
      );
      if (rows.isNotEmpty) {
        setState(() {
          _occurrenceCount = (rows.first['cnt'] as int?) ?? 0;
        });
      }
    } catch (_) {
      setState(() => _occurrenceCount = null);
    } finally {
      if (mounted) setState(() => _isChecking = false);
    }
  }

  Future<void> _submit() async {
    final root = _normalizer.normalizeForRootSearch(_rootController.text.trim());
    if (root.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('يرجى إدخال الجذر اللغوي')),
      );
      return;
    }

    setState(() => _isSaving = true);
    try {
      await widget.onAdd(
        root,
        _noteController.text.trim().isEmpty ? null : _noteController.text.trim(),
      );
      if (mounted) Navigator.of(context).pop();
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('فشل إضافة الجذر: $e')),
        );
      }
    } finally {
      if (mounted) setState(() => _isSaving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Container(
        width: 440,
        padding: const EdgeInsets.all(20),
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Row(
                children: [
                  const Icon(Icons.account_tree_outlined, color: AppTheme.secondaryGold),
                  const SizedBox(width: 8),
                  const Expanded(
                    child: Text(
                      'ربط جذر لغوي معبر عن المفهوم',
                      style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                    ),
                  ),
                  IconButton(
                    icon: const Icon(Icons.close),
                    onPressed: () => Navigator.of(context).pop(),
                  ),
                ],
              ),
              const Divider(),
              const SizedBox(height: 8),

              // حقل إدخال الجذر
              TextField(
                controller: _rootController,
                decoration: const InputDecoration(
                  labelText: 'الجذر الصرفي',
                  hintText: 'مثال: عدل، قسط، ظلم، علم',
                  border: OutlineInputBorder(),
                  prefixIcon: Icon(Icons.spellcheck),
                ),
                onChanged: _checkRoot,
              ),
              const SizedBox(height: 10),

              // حالة الفحص في المصحف
              if (_isChecking)
                const Center(child: Padding(padding: EdgeInsets.all(8), child: CircularProgressIndicator(strokeWidth: 2)))
              else if (_occurrenceCount != null)
                Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: _occurrenceCount! > 0
                        ? AppTheme.primaryEmerald.withValues(alpha: 0.1)
                        : Colors.orange.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Row(
                    children: [
                      Icon(
                        _occurrenceCount! > 0 ? Icons.check_circle_outline : Icons.info_outline,
                        size: 18,
                        color: _occurrenceCount! > 0 ? AppTheme.primaryEmerald : Colors.orange,
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          _occurrenceCount! > 0
                              ? 'وردت مشتقات هذا الجذر $_occurrenceCount مرة في القرآن الكريم.'
                              : 'لم يُسجل ورود مباشر لهذا الجذر في معجم كلمات القرآن، لكن يمكن إضافته للدراسة الدلالية المقارنة.',
                          style: TextStyle(
                            fontSize: 12,
                            color: _occurrenceCount! > 0 ? AppTheme.primaryEmerald : Colors.orange.shade800,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              const SizedBox(height: 14),

              // ملاحظة الباحث
              TextField(
                controller: _noteController,
                maxLines: 2,
                decoration: const InputDecoration(
                  labelText: 'دلالة الجذر في خدمة المفهوم (اختياري)',
                  border: OutlineInputBorder(),
                ),
              ),
              const SizedBox(height: 20),

              Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  TextButton(
                    onPressed: _isSaving ? null : () => Navigator.of(context).pop(),
                    child: const Text('إلغاء'),
                  ),
                  const SizedBox(width: 8),
                  ElevatedButton.icon(
                    onPressed: _isSaving ? null : _submit,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppTheme.secondaryGold,
                      foregroundColor: Colors.white,
                    ),
                    icon: _isSaving
                        ? const SizedBox(width: 16, height: 16, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                        : const Icon(Icons.check, size: 18),
                    label: const Text('إسناد الجذر'),
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
