import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:share_plus/share_plus.dart';

import 'package:quranapp/app/theme/app_theme.dart';
import 'package:quranapp/core/database/quran_database.dart';
import 'package:quranapp/features/quran_reader/domain/entities/ayah.dart';
import 'package:quranapp/features/quran_search/domain/entities/ayah_context_group.dart';
import 'package:quranapp/features/quran_search/domain/entities/ayah_search_result.dart';
import 'package:quranapp/features/quran_search/presentation/controllers/context_providers.dart';

/// شاشة سياق الآيات القرآنية المتقدمة (AyahContextScreen).
/// تعرض الآيات السابقة واللاحقة مع تطبيق خوارزمية دمج النطاقات المتداخلة وقص حدود السورة.
class AyahContextScreen extends ConsumerStatefulWidget {
  final int initialBeforeCount;
  final int initialAfterCount;
  final int? surahId;
  final int? ayahNumber;
  final List<AyahSearchResult>? results;

  const AyahContextScreen({
    super.key,
    this.initialBeforeCount = 2,
    this.initialAfterCount = 2,
    this.surahId,
    this.ayahNumber,
    this.results,
  });

  @override
  ConsumerState<AyahContextScreen> createState() => _AyahContextScreenState();
}

class _AyahContextScreenState extends ConsumerState<AyahContextScreen> {
  @override
  void initState() {
    super.initState();
    Future.microtask(() {
      final notifier = ref.read(ayahContextNotifierProvider.notifier);
      if (widget.surahId != null && widget.ayahNumber != null) {
        notifier.loadForAyah(
          surahId: widget.surahId!,
          ayahNumber: widget.ayahNumber!,
          before: widget.initialBeforeCount,
          after: widget.initialAfterCount,
        );
      } else if (widget.results != null && widget.results!.isNotEmpty) {
        notifier.loadForResults(
          results: widget.results!,
          before: widget.initialBeforeCount,
          after: widget.initialAfterCount,
        );
      } else {
        // افتراضياً سورة الفاتحة الآية 2 في حال عدم تمرير معطيات
        notifier.loadForAyah(
          surahId: 1,
          ayahNumber: 2,
          before: widget.initialBeforeCount,
          after: widget.initialAfterCount,
        );
      }
    });
  }

  /// نسخ نص الآية إلى الحافظة
  void _copyAyah(Ayah ayah, String surahName) {
    final text = '﴿${ayah.textUthmani}﴾ [سورة $surahName: ${ayah.ayahNumber}]';
    Clipboard.setData(ClipboardData(text: text));
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('تم نسخ الآية إلى الحافظة'), duration: Duration(seconds: 2)),
    );
  }

  /// مشاركة نص الآية
  void _shareAyah(Ayah ayah, String surahName) {
    final text = '﴿${ayah.textUthmani}﴾\n[سورة $surahName - الآية ${ayah.ayahNumber}]';
    SharePlus.instance.share(ShareParams(text: text));
  }

  /// إضافة الآية إلى المفضلة
  Future<void> _bookmarkAyah(Ayah ayah, String surahName) async {
    try {
      await QuranDatabase.instance.insert(
        table: 'bookmarks',
        values: {
          'ayah_id': ayah.id,
          'note': 'سياق سورة $surahName آية ${ayah.ayahNumber}',
          'created_at': DateTime.now().toIso8601String(),
        },
      );
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('تمت إضافة آية (${ayah.ayahNumber}) سورة $surahName للمفضلة'),
            backgroundColor: AppTheme.secondaryGold,
            duration: const Duration(seconds: 2),
          ),
        );
      }
    } catch (_) {}
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(ayahContextNotifierProvider);
    final uiState = state.uiState;

    return Scaffold(
      appBar: AppBar(
        title: const Text('سياق الآيات القرآنية'),
        actions: [
          IconButton(
            icon: const Icon(Icons.tune),
            tooltip: 'تعديل نطاق السياق',
            onPressed: () => _showSettingsDialog(state),
          ),
        ],
      ),
      body: Column(
        children: [
          // شريط معلومات وإعدادات نطاق السياق
          _buildContextControlBar(state),

          // منطقة عرض مجموعات سياق الآيات
          Expanded(
            child: Builder(
              builder: (context) {
                if (uiState.isLoading) {
                  return const Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        CircularProgressIndicator(color: AppTheme.primaryEmerald),
                        SizedBox(height: 16),
                        Text('جاري تجميع سياقات الآيات ودمج النطاقات...'),
                      ],
                    ),
                  );
                }

                if (uiState.isError) {
                  return Center(
                    child: Padding(
                      padding: const EdgeInsets.all(24),
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          const Icon(Icons.error_outline, size: 48, color: Colors.red),
                          const SizedBox(height: 12),
                          Text(uiState.errorMessage ?? 'حدث خطأ أثناء تحميل السياق'),
                          const SizedBox(height: 16),
                          ElevatedButton(
                            onPressed: () {
                              ref.read(ayahContextNotifierProvider.notifier).updateCounts(
                                    before: state.beforeCount,
                                    after: state.afterCount,
                                  );
                            },
                            child: const Text('إعادة المحاولة'),
                          ),
                        ],
                      ),
                    ),
                  );
                }

                if (uiState.isEmpty || uiState.data == null || uiState.data!.isEmpty) {
                  return const Center(
                    child: Padding(
                      padding: EdgeInsets.all(24),
                      child: Text('لا توجد آيات لعرض سياقها'),
                    ),
                  );
                }

                final groups = uiState.data!;
                return ListView.builder(
                  padding: const EdgeInsets.all(16),
                  itemCount: groups.length,
                  itemBuilder: (context, index) {
                    final group = groups[index];
                    return _buildContextGroupCard(group);
                  },
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  /// شريط التحكم بنطاق السياق السريع
  Widget _buildContextControlBar(AyahContextState state) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        color: Theme.of(context).cardColor,
        border: Border(
          bottom: BorderSide(color: Theme.of(context).dividerColor.withValues(alpha: 0.3)),
        ),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: AppTheme.primaryEmerald.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: const Icon(Icons.layers_outlined, color: AppTheme.primaryEmerald, size: 20),
              ),
              const SizedBox(width: 12),
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'السابق: ${state.beforeCount} آيات | اللاحق: ${state.afterCount} آيات',
                    style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
                  ),
                  const Text(
                    'تم دمج النطاقات المتداخلة تلقائياً وفق حدود السورة',
                    style: TextStyle(fontSize: 11, color: Colors.grey),
                  ),
                ],
              ),
            ],
          ),
          OutlinedButton.icon(
            icon: const Icon(Icons.tune, size: 16),
            label: const Text('تغيير', style: TextStyle(fontSize: 12)),
            onPressed: () => _showSettingsDialog(state),
          ),
        ],
      ),
    );
  }

  /// بناء بطاقة مجموعة السياق المتصلة لسورة محددة
  Widget _buildContextGroupCard(AyahContextGroup group) {
    return Card(
      margin: const EdgeInsets.only(bottom: 20),
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: BorderSide(color: Theme.of(context).dividerColor.withValues(alpha: 0.3)),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // ترويسة المجموعة: اسم السورة ونطاق الآيات المدمجة
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Row(
                  children: [
                    const Icon(Icons.menu_book, color: AppTheme.primaryEmerald, size: 20),
                    const SizedBox(width: 8),
                    Text(
                      'سورة ${group.surahName}',
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        color: AppTheme.primaryEmerald,
                      ),
                    ),
                  ],
                ),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                  decoration: BoxDecoration(
                    color: AppTheme.primaryEmerald.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Text(
                    'النطاق: الآيات [${group.range.startAyah} إلى ${group.range.endAyah}]',
                    style: const TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.bold,
                      color: AppTheme.primaryEmerald,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 4),
            Text(
              'الآيات المستهدفة بالبحث: ${group.matchedAyahNumbers.join('، ')}',
              style: const TextStyle(fontSize: 11, color: Colors.grey),
            ),
            const Divider(height: 24),

            // قائمة أسطر الآيات المتسلسلة
            ...group.ayahs.map((ayah) {
              final isTarget = group.matchedAyahNumbers.contains(ayah.ayahNumber);
              return _buildAyahRow(ayah, group.surahName, isTarget);
            }),
          ],
        ),
      ),
    );
  }

  /// بناء سطر الآية مع التمييز البصري للآية المستهدفة
  Widget _buildAyahRow(Ayah ayah, String surahName, bool isTarget) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: isTarget
            ? AppTheme.secondaryGold.withValues(alpha: 0.14)
            : Theme.of(context).cardColor,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: isTarget
              ? AppTheme.secondaryGold.withValues(alpha: 0.6)
              : Theme.of(context).dividerColor.withValues(alpha: 0.2),
          width: isTarget ? 1.5 : 1.0,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // شريط بيانات الآية والوسم
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                children: [
                  Container(
                    width: 28,
                    height: 28,
                    alignment: Alignment.center,
                    decoration: BoxDecoration(
                      color: isTarget ? AppTheme.secondaryGold : AppTheme.primaryEmerald,
                      shape: BoxShape.circle,
                    ),
                    child: Text(
                      '${ayah.ayahNumber}',
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 12,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Text(
                    'الآية (${ayah.ayahNumber})',
                    style: TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.bold,
                      color: isTarget ? AppTheme.secondaryGold : AppTheme.primaryEmerald,
                    ),
                  ),
                ],
              ),
              if (isTarget)
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                  decoration: BoxDecoration(
                    color: AppTheme.secondaryGold,
                    borderRadius: BorderRadius.circular(6),
                  ),
                  child: const Text(
                    'آية البحث المطابقة',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 10,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
            ],
          ),
          const SizedBox(height: 10),

          // نص الآية العثماني المشكول
          Text(
            ayah.textUthmani,
            style: TextStyle(
              fontSize: 18,
              height: 2.1,
              fontFamily: 'Amiri',
              fontWeight: isTarget ? FontWeight.bold : FontWeight.w500,
              color: Theme.of(context).textTheme.bodyLarge?.color,
            ),
            textAlign: TextAlign.right,
          ),
          const SizedBox(height: 8),

          // أزرار التفاعل السريع للآية
          Row(
            mainAxisAlignment: MainAxisAlignment.end,
            children: [
              TextButton.icon(
                icon: const Icon(Icons.import_contacts, size: 15),
                label: const Text('المصحف', style: TextStyle(fontSize: 11)),
                onPressed: () {
                  context.push('/reader/${ayah.surahId}?ayah=${ayah.ayahNumber}');
                },
              ),
              IconButton(
                icon: const Icon(Icons.star_border, size: 18),
                tooltip: 'المفضلة',
                onPressed: () => _bookmarkAyah(ayah, surahName),
              ),
              IconButton(
                icon: const Icon(Icons.copy_outlined, size: 16),
                tooltip: 'نسخ',
                onPressed: () => _copyAyah(ayah, surahName),
              ),
              IconButton(
                icon: const Icon(Icons.share_outlined, size: 16),
                tooltip: 'مشاركة',
                onPressed: () => _shareAyah(ayah, surahName),
              ),
            ],
          ),
        ],
      ),
    );
  }

  /// مربع حوار لتعديل نطاق السياق السابق واللاحق
  void _showSettingsDialog(AyahContextState state) {
    int selectedBefore = state.beforeCount;
    int selectedAfter = state.afterCount;

    showDialog<void>(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (context, setDialogState) => AlertDialog(
          title: const Row(
            children: [
              Icon(Icons.tune, color: AppTheme.primaryEmerald),
              SizedBox(width: 8),
              Text('تعديل نطاق السياق'),
            ],
          ),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const Text(
                'اختر عدد الآيات السابقة واللاحقة المطلوب إدراجها ضمن السياق (بحد أقصى 20 آية):',
                style: TextStyle(fontSize: 13, height: 1.4),
              ),
              const SizedBox(height: 16),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text('الآيات السابقة:'),
                  DropdownButton<int>(
                    value: selectedBefore,
                    items: List.generate(21, (i) => DropdownMenuItem(value: i, child: Text('$i'))),
                    onChanged: (val) {
                      if (val != null) {
                        setDialogState(() => selectedBefore = val);
                      }
                    },
                  ),
                ],
              ),
              const SizedBox(height: 8),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text('الآيات اللاحقة:'),
                  DropdownButton<int>(
                    value: selectedAfter,
                    items: List.generate(21, (i) => DropdownMenuItem(value: i, child: Text('$i'))),
                    onChanged: (val) {
                      if (val != null) {
                        setDialogState(() => selectedAfter = val);
                      }
                    },
                  ),
                ],
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(ctx),
              child: const Text('إلغاء'),
            ),
            ElevatedButton(
              onPressed: () {
                Navigator.pop(ctx);
                ref.read(ayahContextNotifierProvider.notifier).updateCounts(
                      before: selectedBefore,
                      after: selectedAfter,
                    );
              },
              child: const Text('تطبيق'),
            ),
          ],
        ),
      ),
    );
  }
}
