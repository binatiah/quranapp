import 'package:flutter/material.dart';
import 'package:quranapp/app/theme/app_theme.dart';
import 'package:quranapp/features/quran_search/domain/entities/quran_word.dart';

/// نافذة حوار لتعديل البيانات الصرفية والتفصيلية للكلمة القرآنية (Edit Word Dialog).
class EditWordDialog extends StatefulWidget {
  final QuranWord word;
  final Future<void> Function({
    required int wordId,
    required String wordUthmani,
    String? lemma,
    String? prefix,
    String? stem,
    String? suffix,
    String? partOfSpeech,
    String? morphology,
  }) onSave;

  const EditWordDialog({
    super.key,
    required this.word,
    required this.onSave,
  });

  @override
  State<EditWordDialog> createState() => _EditWordDialogState();
}

class _EditWordDialogState extends State<EditWordDialog> {
  final _formKey = GlobalKey<FormState>();

  late final TextEditingController _uthmaniController;
  late final TextEditingController _lemmaController;
  late final TextEditingController _prefixController;
  late final TextEditingController _stemController;
  late final TextEditingController _suffixController;
  late final TextEditingController _posController;
  late final TextEditingController _morphologyController;

  bool _isSaving = false;

  @override
  void initState() {
    super.initState();
    _uthmaniController = TextEditingController(text: widget.word.wordUthmani);
    _lemmaController = TextEditingController(text: widget.word.lemma ?? '');
    _prefixController = TextEditingController(text: widget.word.prefix ?? '');
    _stemController = TextEditingController(text: widget.word.stem ?? '');
    _suffixController = TextEditingController(text: widget.word.suffix ?? '');
    _posController = TextEditingController(text: widget.word.partOfSpeech ?? '');
    _morphologyController = TextEditingController(text: widget.word.morphology ?? '');
  }

  @override
  void dispose() {
    _uthmaniController.dispose();
    _lemmaController.dispose();
    _prefixController.dispose();
    _stemController.dispose();
    _suffixController.dispose();
    _posController.dispose();
    _morphologyController.dispose();
    super.dispose();
  }

  Future<void> _handleSave() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() {
      _isSaving = true;
    });

    try {
      await widget.onSave(
        wordId: widget.word.id,
        wordUthmani: _uthmaniController.text.trim(),
        lemma: _lemmaController.text.trim().isEmpty ? null : _lemmaController.text.trim(),
        prefix: _prefixController.text.trim().isEmpty ? null : _prefixController.text.trim(),
        stem: _stemController.text.trim().isEmpty ? null : _stemController.text.trim(),
        suffix: _suffixController.text.trim().isEmpty ? null : _suffixController.text.trim(),
        partOfSpeech: _posController.text.trim().isEmpty ? null : _posController.text.trim(),
        morphology: _morphologyController.text.trim().isEmpty ? null : _morphologyController.text.trim(),
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
            content: Text(e.toString().replaceAll('Exception: ', '')),
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
          Icon(Icons.edit_note, color: AppTheme.primaryEmerald),
          SizedBox(width: 8),
          Text('تعديل بيانات الكلمة القرآنية'),
        ],
      ),
      content: SingleChildScrollView(
        child: Form(
          key: _formKey,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextFormField(
                controller: _uthmaniController,
                decoration: InputDecoration(
                  labelText: 'الرسم العثماني للكلمة*',
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                ),
                textDirection: TextDirection.rtl,
                validator: (val) {
                  if (val == null || val.trim().isEmpty) {
                    return 'يرجى إدخال الرسم العثماني';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 12),
              TextFormField(
                controller: _lemmaController,
                decoration: InputDecoration(
                  labelText: 'اللفظ المجرد / أصل الكلمة (Lemma)',
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                ),
                textDirection: TextDirection.rtl,
              ),
              const SizedBox(height: 12),
              TextFormField(
                controller: _posController,
                decoration: InputDecoration(
                  labelText: 'نوع الكلمة الصرفي (Part of Speech)',
                  hintText: 'مثال: اسم فاعل، فعل ماض، حرف جر...',
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                ),
                textDirection: TextDirection.rtl,
              ),
              const SizedBox(height: 12),
              Row(
                children: [
                  Expanded(
                    child: TextFormField(
                      controller: _prefixController,
                      decoration: InputDecoration(
                        labelText: 'السابقة (Prefix)',
                        border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                      ),
                      textDirection: TextDirection.rtl,
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: TextFormField(
                      controller: _stemController,
                      decoration: InputDecoration(
                        labelText: 'الجذع (Stem)',
                        border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                      ),
                      textDirection: TextDirection.rtl,
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: TextFormField(
                      controller: _suffixController,
                      decoration: InputDecoration(
                        labelText: 'اللاحقة (Suffix)',
                        border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                      ),
                      textDirection: TextDirection.rtl,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              TextFormField(
                controller: _morphologyController,
                decoration: InputDecoration(
                  labelText: 'الوصف الصرفي والإعرابي',
                  hintText: 'تحليل دقيق لأصل الاشتقاق وعلامة الإعراب...',
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                  alignLabelWithHint: true,
                ),
                maxLines: 3,
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
              : const Text('حفظ التعديلات'),
        ),
      ],
    );
  }
}
