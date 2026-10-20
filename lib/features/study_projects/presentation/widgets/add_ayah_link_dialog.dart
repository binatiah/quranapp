import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../app/theme/app_theme.dart';
import '../../../../core/database/quran_database.dart';
import '../../../quran_reader/presentation/controllers/quran_providers.dart';

/// نافذة حوار لإسناد وربط آية قرآنية بمشروع الدراسة مع المعاينة الحية
class AddAyahLinkDialog extends ConsumerStatefulWidget {
  /// دالة الاستدعاء عند الحفظ
  final Future<void> Function(int ayahId, String? note, String relationType) onAdd;

  /// المنشئ
  const AddAyahLinkDialog({super.key, required this.onAdd});

  @override
  ConsumerState<AddAyahLinkDialog> createState() => _AddAyahLinkDialogState();
}

class _AddAyahLinkDialogState extends ConsumerState<AddAyahLinkDialog> {
  int _selectedSurahId = 1;
  int _selectedAyahNumber = 1;
  String _relationType = 'related';
  final _noteController = TextEditingController();

  String? _previewText;
  int? _matchedAyahId;
  bool _isLoadingPreview = false;
  bool _isSaving = false;

  @override
  void initState() {
    super.initState();
    _fetchPreview();
  }

  @override
  void dispose() {
    _noteController.dispose();
    super.dispose();
  }

  Future<void> _fetchPreview() async {
    setState(() => _isLoadingPreview = true);
    try {
      final rows = await QuranDatabase.instance.query(
        sql: 'SELECT id, text_uthmani FROM ayahs WHERE surah_id = ? AND ayah_number = ? LIMIT 1;',
        arguments: [_selectedSurahId, _selectedAyahNumber],
      );
      if (rows.isNotEmpty) {
        setState(() {
          _matchedAyahId = rows.first['id'] as int;
          _previewText = rows.first['text_uthmani'] as String;
        });
      } else {
        setState(() {
          _matchedAyahId = null;
          _previewText = 'رقم الآية غير موجود في هذه السورة';
        });
      }
    } catch (_) {
      setState(() {
        _matchedAyahId = null;
        _previewText = null;
      });
    } finally {
      if (mounted) setState(() => _isLoadingPreview = false);
    }
  }

  Future<void> _submit() async {
    if (_matchedAyahId == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('يرجى اختيار آية صالحة من المصحف')),
      );
      return;
    }

    setState(() => _isSaving = true);
    try {
      await widget.onAdd(
        _matchedAyahId!,
        _noteController.text.trim().isEmpty ? null : _noteController.text.trim(),
        _relationType,
      );
      if (mounted) Navigator.of(context).pop();
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('فشل إضافة الآية: $e')),
        );
      }
    } finally {
      if (mounted) setState(() => _isSaving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final surahsAsync = ref.watch(surahListNotifierProvider);
    final surahs = surahsAsync.uiState.data ?? [];

    return Dialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Container(
        width: 480,
        padding: const EdgeInsets.all(20),
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Row(
                children: [
                  const Icon(Icons.add_link, color: AppTheme.primaryEmerald),
                  const SizedBox(width: 8),
                  const Expanded(
                    child: Text(
                      'ربط آية قرآنية بالمشروع',
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

              // اختيار السورة والآية
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
                          });
                          _fetchPreview();
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
                        setState(() => _selectedAyahNumber = num);
                        _fetchPreview();
                      },
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),

              // معاينة نص الآية
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: AppTheme.primaryEmerald.withValues(alpha: 0.05),
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: AppTheme.primaryEmerald.withValues(alpha: 0.2)),
                ),
                child: _isLoadingPreview
                    ? const Center(child: CircularProgressIndicator(strokeWidth: 2))
                    : Text(
                        _previewText ?? 'اختر آية لعرض نصها',
                        textAlign: TextAlign.center,
                        style: const TextStyle(
                          fontFamily: 'Amiri',
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                          height: 1.6,
                        ),
                      ),
              ),
              const SizedBox(height: 16),

              // نوع الارتباط
              DropdownButtonFormField<String>(
                initialValue: _relationType,
                decoration: const InputDecoration(
                  labelText: 'نوع وجه الارتباط بالمشروع',
                  border: OutlineInputBorder(),
                ),
                items: const [
                  DropdownMenuItem(value: 'related', child: Text('صلة موضوعية عامة')),
                  DropdownMenuItem(value: 'explaining', child: Text('آية مفسرة أو مخصصة')),
                  DropdownMenuItem(value: 'crossReference', child: Text('تقاطع دلالي نظير')),
                  DropdownMenuItem(value: 'ruling', child: Text('شاهد استنباط حكم')),
                ],
                onChanged: (val) {
                  if (val != null) setState(() => _relationType = val);
                },
              ),
              const SizedBox(height: 16),

              // ملاحظة الباحث
              TextField(
                controller: _noteController,
                maxLines: 2,
                decoration: const InputDecoration(
                  labelText: 'ملاحظة الباحث على الآية (اختياري)',
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
                    onPressed: _isSaving || _matchedAyahId == null ? null : _submit,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppTheme.primaryEmerald,
                      foregroundColor: Colors.white,
                    ),
                    icon: _isSaving
                        ? const SizedBox(width: 16, height: 16, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                        : const Icon(Icons.check, size: 18),
                    label: const Text('ربط الآية'),
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
