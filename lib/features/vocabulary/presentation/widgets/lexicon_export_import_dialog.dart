import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:share_plus/share_plus.dart';

import 'package:quranapp/app/theme/app_theme.dart';
import 'package:quranapp/features/vocabulary/domain/entities/lexicon_export_data.dart';
import 'package:quranapp/features/vocabulary/presentation/controllers/lexicon_io_providers.dart';

/// نافذة حوار تصدير واستيراد تصحيحات المعجم القرآني
class LexiconExportImportDialog extends ConsumerStatefulWidget {
  /// رد نداء اختياري يُنفّذ عند اكتمال عملية استيراد لتحديث القوائم في الشاشات الأبوية
  final VoidCallback? onImportSuccess;

  const LexiconExportImportDialog({
    super.key,
    this.onImportSuccess,
  });

  /// دالة مساعدة لفتح نافذة الحوار
  static Future<void> show(BuildContext context, {VoidCallback? onImportSuccess}) {
    return showDialog<void>(
      context: context,
      builder: (context) => LexiconExportImportDialog(onImportSuccess: onImportSuccess),
    );
  }

  @override
  ConsumerState<LexiconExportImportDialog> createState() => _LexiconExportImportDialogState();
}

class _LexiconExportImportDialogState extends ConsumerState<LexiconExportImportDialog>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  final TextEditingController _importTextController = TextEditingController();
  bool _exportCustomOnly = true;
  String? _exportedJsonCache;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    _importTextController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(lexiconIONotifierProvider);

    return Dialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 540, maxHeight: 680),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 20),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // العنوان والإغلاق
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: AppTheme.primaryEmerald.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: const Icon(Icons.sync_alt, color: AppTheme.primaryEmerald),
                  ),
                  const SizedBox(width: 12),
                  const Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'تصدير واستيراد تصحيحات المعجم',
                          style: TextStyle(fontSize: 17, fontWeight: FontWeight.bold),
                        ),
                        Text(
                          'مزامنة وحفظ التعديلات اللغوية بصيغة JSON الموحدة',
                          style: TextStyle(fontSize: 12, color: Colors.grey),
                        ),
                      ],
                    ),
                  ),
                  IconButton(
                    icon: const Icon(Icons.close),
                    onPressed: () => Navigator.of(context).pop(),
                  ),
                ],
              ),
              const SizedBox(height: 16),

              // شريط التبويبات
              Container(
                decoration: BoxDecoration(
                  color: Theme.of(context).cardColor,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: Theme.of(context).dividerColor.withValues(alpha: 0.2)),
                ),
                child: TabBar(
                  controller: _tabController,
                  indicatorColor: AppTheme.primaryEmerald,
                  labelColor: AppTheme.primaryEmerald,
                  unselectedLabelColor: Colors.grey,
                  indicatorWeight: 3,
                  tabs: const [
                    Tab(
                      icon: Icon(Icons.upload_file, size: 20),
                      text: 'تصدير التصحيحات',
                    ),
                    Tab(
                      icon: Icon(Icons.download_for_offline_outlined, size: 20),
                      text: 'استيراد ودمج',
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 16),

              // محتوى التبويبات
              Expanded(
                child: TabBarView(
                  controller: _tabController,
                  children: [
                    _buildExportTab(context, state),
                    _buildImportTab(context, state),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  /// تبويب تصدير المعجم
  Widget _buildExportTab(BuildContext context, LexiconIOState state) {
    return SingleChildScrollView(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: AppTheme.secondaryGold.withValues(alpha: 0.08),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: AppTheme.secondaryGold.withValues(alpha: 0.2)),
            ),
            child: const Row(
              children: [
                Icon(Icons.info_outline, color: AppTheme.secondaryGold, size: 20),
                SizedBox(width: 8),
                Expanded(
                  child: Text(
                    'يتيح التصدير حفظ الجذور المضافة حديثاً والتصحيحات التي قمت بها على الكلمات، لمشاركتها أو استعادتها لاحقاً.',
                    style: TextStyle(fontSize: 12),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),

          // خيار نوع التصدير
          SwitchListTile(
            title: const Text(
              'تصدير التصحيحات المخصصة فقط',
              style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
            ),
            subtitle: const Text(
              'تصدير الكلمات والجذور المعدلة والمراجعة يدوياً (حجم أصغر وأسرع)',
              style: TextStyle(fontSize: 12),
            ),
            value: _exportCustomOnly,
            activeThumbColor: AppTheme.primaryEmerald,
            onChanged: (val) {
              setState(() {
                _exportCustomOnly = val;
                _exportedJsonCache = null;
              });
            },
          ),
          const SizedBox(height: 16),

          if (state.isLoading)
            const Center(
              child: Padding(
                padding: EdgeInsets.all(24),
                child: Column(
                  children: [
                    CircularProgressIndicator(color: AppTheme.primaryEmerald),
                    SizedBox(height: 12),
                    Text('جاري استخراج وتجهيز حزمة بيانات المعجم...'),
                  ],
                ),
              ),
            )
          else ...[
            if (state.errorMessage != null)
              Container(
                margin: const EdgeInsets.only(bottom: 12),
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: Colors.red.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  state.errorMessage!,
                  style: const TextStyle(color: Colors.red, fontSize: 12),
                ),
              ),

            // أزرار التصدير والمشاركة
            ElevatedButton.icon(
              icon: const Icon(Icons.copy, size: 18),
              label: const Text('نسخ كود JSON إلى الحافظة'),
              style: ElevatedButton.styleFrom(
                backgroundColor: AppTheme.primaryEmerald,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(vertical: 12),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
              ),
              onPressed: () async {
                final messenger = ScaffoldMessenger.of(context);
                final jsonStr = _exportedJsonCache ??
                    await ref
                        .read(lexiconIONotifierProvider.notifier)
                        .exportJson(customOnly: _exportCustomOnly);
                if (jsonStr != null && mounted) {
                  _exportedJsonCache = jsonStr;
                  await Clipboard.setData(ClipboardData(text: jsonStr));
                  if (mounted) {
                    messenger.showSnackBar(
                      const SnackBar(
                        content: Text('تم نسخ بيانات المعجم بنجاح إلى الحافظة'),
                        backgroundColor: AppTheme.primaryEmerald,
                        duration: Duration(seconds: 2),
                      ),
                    );
                  }
                }
              },
            ),
            const SizedBox(height: 10),
            OutlinedButton.icon(
              icon: const Icon(Icons.share, size: 18),
              label: const Text('مشاركة أو حفظ كملف JSON'),
              style: OutlinedButton.styleFrom(
                padding: const EdgeInsets.symmetric(vertical: 12),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
              ),
              onPressed: () async {
                final jsonStr = _exportedJsonCache ??
                    await ref
                        .read(lexiconIONotifierProvider.notifier)
                        .exportJson(customOnly: _exportCustomOnly);
                if (jsonStr != null) {
                  _exportedJsonCache = jsonStr;
                  await SharePlus.instance.share(
                    ShareParams(
                      text: jsonStr,
                      subject: 'quran_lexicon_backup.json',
                    ),
                  );
                }
              },
            ),
          ],
        ],
      ),
    );
  }

  /// تبويب استيراد المعجم
  Widget _buildImportTab(BuildContext context, LexiconIOState state) {
    final result = state.importResult;

    return SingleChildScrollView(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: Colors.blue.withValues(alpha: 0.08),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: Colors.blue.withValues(alpha: 0.2)),
            ),
            child: const Row(
              children: [
                Icon(Icons.info_outline, color: Colors.blue, size: 20),
                SizedBox(width: 8),
                Expanded(
                  child: Text(
                    'الصق حزمة التعديلات بصيغة JSON. سيتم دمج الجذور وتحديث روابط الكلمات بأمان داخل معاملة قاعدة البيانات (Transaction).',
                    style: TextStyle(fontSize: 12),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 12),

          // حقل إدخال JSON
          TextField(
            controller: _importTextController,
            maxLines: 7,
            style: const TextStyle(fontSize: 12, fontFamily: 'monospace'),
            decoration: InputDecoration(
              hintText: 'ألصق نص JSON هنا...\n{\n  "version": 1,\n  "roots": [...],\n  "word_links": [...]\n}',
              border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
              filled: true,
              suffixIcon: IconButton(
                icon: const Icon(Icons.paste, size: 20),
                tooltip: 'لصق من الحافظة',
                onPressed: () async {
                  final data = await Clipboard.getData('text/plain');
                  if (data?.text != null && mounted) {
                    setState(() {
                      _importTextController.text = data!.text!;
                    });
                  }
                },
              ),
            ),
          ),
          const SizedBox(height: 12),

          if (state.isLoading)
            const Center(
              child: Padding(
                padding: EdgeInsets.all(16),
                child: Column(
                  children: [
                    CircularProgressIndicator(color: AppTheme.primaryEmerald),
                    SizedBox(height: 8),
                    Text('جاري تدقيق واستيراد البيانات إلى المعجم...'),
                  ],
                ),
              ),
            )
          else ...[
            if (state.errorMessage != null)
              Container(
                margin: const EdgeInsets.only(bottom: 12),
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: Colors.red.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  state.errorMessage!,
                  style: const TextStyle(color: Colors.red, fontSize: 12),
                ),
              ),

            // عرض نتيجة الاستيراد الناجح
            if (result != null)
              _buildImportResultCard(context, result),

            const SizedBox(height: 8),
            ElevatedButton.icon(
              icon: const Icon(Icons.system_update_alt, size: 18),
              label: const Text('بدء استيراد ودمج المعجم'),
              style: ElevatedButton.styleFrom(
                backgroundColor: AppTheme.primaryEmerald,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(vertical: 12),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
              ),
              onPressed: () async {
                final text = _importTextController.text.trim();
                if (text.isEmpty) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text('الرجاء إدخال أو لصق نص JSON أولاً'),
                      backgroundColor: Colors.orange,
                    ),
                  );
                  return;
                }

                final res = await ref.read(lexiconIONotifierProvider.notifier).importJson(text);
                if (res != null && mounted) {
                  widget.onImportSuccess?.call();
                }
              },
            ),
          ],
        ],
      ),
    );
  }

  /// بطاقة عرض تفاصيل نجاح عملية الاستيراد
  Widget _buildImportResultCard(BuildContext context, LexiconImportResult result) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.green.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.green.withValues(alpha: 0.3)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Row(
            children: [
              Icon(Icons.check_circle, color: Colors.green, size: 20),
              SizedBox(width: 8),
              Text(
                'اكتمل الاستيراد بنجاح!',
                style: TextStyle(fontWeight: FontWeight.bold, color: Colors.green),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            '• عدد الجذور المعالجة: ${result.importedRootsCount}',
            style: const TextStyle(fontSize: 12),
          ),
          Text(
            '• عدد روابط الكلمات المحدثة: ${result.updatedWordsCount}',
            style: const TextStyle(fontSize: 12),
          ),
          if (result.warnings.isNotEmpty) ...[
            const SizedBox(height: 6),
            Text(
              '• تنبيهات (${result.warnings.length}): ${result.warnings.take(2).join(", ")}',
              style: const TextStyle(fontSize: 11, color: Colors.orange),
            ),
          ],
        ],
      ),
    );
  }
}
