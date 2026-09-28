import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:share_plus/share_plus.dart';

import '../../../../app/theme/app_theme.dart';
import '../../../../core/database/quran_database.dart';
import '../../domain/entities/ayah.dart';
import '../../domain/entities/surah.dart';
import '../controllers/quran_providers.dart';

/// شاشة عارض القرآن الكريم التفاعلية (QuranReaderScreen) لعرض آيات السورة بالنص العثماني.
class QuranReaderScreen extends ConsumerStatefulWidget {
  /// رقم السورة المعروضة (1 إلى 114)
  final int surahId;

  /// رقم الآية المستهدفة للانتقال المباشر إليها إن وُجدت
  final int? targetAyahNumber;

  const QuranReaderScreen({
    super.key,
    required this.surahId,
    this.targetAyahNumber,
  });

  @override
  ConsumerState<QuranReaderScreen> createState() => _QuranReaderScreenState();
}

class _QuranReaderScreenState extends ConsumerState<QuranReaderScreen> {
  final ScrollController _scrollController = ScrollController();
  final Map<int, GlobalKey> _ayahKeys = {};
  bool _hasScrolledToTarget = false;

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  /// التمرير التلقائي إلى الآية المستهدفة عند اكتمال تحميل الواجهة
  void _scrollToTargetAyah(List<Ayah> ayahs) {
    if (_hasScrolledToTarget || widget.targetAyahNumber == null) return;
    final targetNum = widget.targetAyahNumber!;
    final key = _ayahKeys[targetNum];

    if (key != null && key.currentContext != null) {
      _hasScrolledToTarget = true;
      WidgetsBinding.instance.addPostFrameCallback((_) {
        Scrollable.ensureVisible(
          key.currentContext!,
          duration: const Duration(milliseconds: 600),
          curve: Curves.easeInOut,
          alignment: 0.1,
        );
      });
    }
  }

  /// حفظ موضع القراءة الحالي وإظهار إشعار للمستخدم
  Future<void> _saveReadingPosition(int ayahNumber, String surahName) async {
    await ref.read(readerNotifierProvider(widget.surahId).notifier).saveCurrentPosition(ayahNumber);
    await ref.read(readingPositionNotifierProvider.notifier).loadLastPosition();

    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('تم حفظ موضع القراءة: سورة $surahName - الآية $ayahNumber'),
          backgroundColor: AppTheme.primaryEmerald,
          duration: const Duration(seconds: 2),
        ),
      );
    }
  }

  /// إضافة الآية إلى المفضلة في SQLite
  Future<void> _addToBookmarks(Ayah ayah, String surahName) async {
    try {
      await QuranDatabase.instance.insert(
        table: 'bookmarks',
        values: {
          'ayah_id': ayah.id,
          'note': 'سورة $surahName آية ${ayah.ayahNumber}',
          'created_at': DateTime.now().toIso8601String(),
        },
      );
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('تمت إضافة الآية ${ayah.ayahNumber} من سورة $surahName إلى المفضلة'),
            backgroundColor: AppTheme.secondaryGold,
            duration: const Duration(seconds: 2),
          ),
        );
      }
    } catch (_) {}
  }

  /// نسخ نص الآية إلى الحافظة
  void _copyAyah(Ayah ayah, String surahName) {
    final text = '${ayah.textUthmani} [سورة $surahName: ${ayah.ayahNumber}]';
    Clipboard.setData(ClipboardData(text: text));
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('تم نسخ الآية إلى الحافظة'),
        duration: Duration(seconds: 2),
      ),
    );
  }

  /// مشاركة نص الآية
  void _shareAyah(Ayah ayah, String surahName) {
    final text = '﴿${ayah.textUthmani}﴾\n[سورة $surahName - الآية ${ayah.ayahNumber}]';
    SharePlus.instance.share(ShareParams(text: text));
  }

  /// عرض حوار التحكم بحجم الخط
  void _showFontSizeDialog() {
    showDialog<void>(
      context: context,
      builder: (ctx) => Consumer(
        builder: (context, ref, _) {
          final currentSize = ref.watch(fontSizeProvider);
          return AlertDialog(
            title: const Text('حجم خط الآيات'),
            content: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  'بِسْمِ اللَّهِ الرَّحْمَٰنِ الرَّحِيمِ',
                  style: TextStyle(
                    fontSize: currentSize,
                    fontWeight: FontWeight.bold,
                    color: AppTheme.primaryEmerald,
                  ),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 20),
                Slider(
                  value: currentSize,
                  min: 16.0,
                  max: 36.0,
                  divisions: 10,
                  activeColor: AppTheme.primaryEmerald,
                  label: '${currentSize.toInt()}',
                  onChanged: (val) {
                    ref.read(fontSizeProvider.notifier).state = val;
                  },
                ),
              ],
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(ctx),
                child: const Text('إغلاق'),
              ),
            ],
          );
        },
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final readerState = ref.watch(readerNotifierProvider(widget.surahId));
    final uiState = readerState.uiState;
    final surah = readerState.surah;
    final fontSize = ref.watch(fontSizeProvider);

    return Scaffold(
      appBar: AppBar(
        title: Text(surah != null ? 'سورة ${surah.nameArabic}' : 'المصحف الشريف'),
        actions: [
          IconButton(
            icon: const Icon(Icons.format_size),
            tooltip: 'تغيير حجم الخط',
            onPressed: _showFontSizeDialog,
          ),
          if (surah != null)
            IconButton(
              icon: const Icon(Icons.bookmark_border),
              tooltip: 'حفظ موضع القراءة هنا',
              onPressed: () => _saveReadingPosition(widget.targetAyahNumber ?? 1, surah.nameArabic),
            ),
        ],
      ),
      body: Builder(
        builder: (context) {
          if (uiState.isLoading) {
            return const Center(
              child: CircularProgressIndicator(color: AppTheme.primaryEmerald),
            );
          }

          if (uiState.isError) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(Icons.error_outline, size: 48, color: Colors.red),
                  const SizedBox(height: 12),
                  Text(
                    uiState.errorMessage ?? 'تعذر عرض الآيات',
                    style: const TextStyle(fontSize: 16),
                  ),
                  const SizedBox(height: 16),
                  ElevatedButton(
                    onPressed: () {
                      ref.read(readerNotifierProvider(widget.surahId).notifier).loadSurahDetails();
                    },
                    child: const Text('إعادة المحاولة'),
                  ),
                ],
              ),
            );
          }

          final ayahs = uiState.data ?? [];
          if (ayahs.isEmpty) {
            return const Center(child: Text('لا توجد آيات لهذه السورة'));
          }

          // التمرير التلقائي للآية المستهدفة
          WidgetsBinding.instance.addPostFrameCallback((_) {
            _scrollToTargetAyah(ayahs);
          });

          return ListView.builder(
            controller: _scrollController,
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            itemCount: ayahs.length + 1, // +1 لترويسة السورة والبسملة
            itemBuilder: (context, index) {
              if (index == 0) {
                return _buildSurahHeader(surah);
              }

              final ayah = ayahs[index - 1];
              final key = _ayahKeys.putIfAbsent(ayah.ayahNumber, GlobalKey.new);
              final isTarget = widget.targetAyahNumber == ayah.ayahNumber;

              return _buildAyahCard(
                key: key,
                ayah: ayah,
                surah: surah,
                fontSize: fontSize,
                isTarget: isTarget,
              );
            },
          );
        },
      ),
    );
  }

  /// بناء ترويسة السورة والبسملة
  Widget _buildSurahHeader(Surah? surah) {
    if (surah == null) return const SizedBox.shrink();

    // سورة التوبة (رقم 9) لا تبدأ بالبسملة
    final showBismillah = surah.id != 9 && surah.id != 1;

    return Container(
      margin: const EdgeInsets.only(bottom: 20),
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: AppTheme.primaryEmerald.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: AppTheme.secondaryGold.withValues(alpha: 0.4),
          width: 1.5,
        ),
      ),
      child: Column(
        children: [
          Text(
            'سورة ${surah.nameArabic}',
            style: const TextStyle(
              fontSize: 24,
              fontWeight: FontWeight.bold,
              color: AppTheme.primaryEmerald,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            '${surah.revelationType} • آياتها ${surah.ayahCount} • ترتيب النزول ${surah.revelationOrder ?? "-"}',
            style: TextStyle(
              fontSize: 13,
              color: Theme.of(context).textTheme.bodySmall?.color,
            ),
          ),
          if (showBismillah) ...[
            const Divider(height: 24),
            const Text(
              'بِسْمِ اللَّهِ الرَّحْمَٰنِ الرَّحِيمِ',
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
                color: AppTheme.primaryEmerald,
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ],
      ),
    );
  }

  /// بناء بطاقة الآية القرآنية المفردة بالنص العثماني وعناصر التفاعل
  Widget _buildAyahCard({
    required Key key,
    required Ayah ayah,
    required Surah? surah,
    required double fontSize,
    required bool isTarget,
  }) {
    final surahName = surah?.nameArabic ?? '';

    return Container(
      key: key,
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: isTarget
            ? AppTheme.secondaryGold.withValues(alpha: 0.12)
            : Theme.of(context).cardColor,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(
          color: isTarget
              ? AppTheme.secondaryGold
              : Theme.of(context).dividerColor.withValues(alpha: 0.3),
          width: isTarget ? 1.8 : 1.0,
        ),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // سطر رقم الآية والمؤشرات
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                // رقم الآية القرآني
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                  decoration: BoxDecoration(
                    color: AppTheme.primaryEmerald.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(
                      color: AppTheme.primaryEmerald.withValues(alpha: 0.3),
                    ),
                  ),
                  child: Text(
                    'الآية ${ayah.ayahNumber}',
                    style: const TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.bold,
                      color: AppTheme.primaryEmerald,
                    ),
                  ),
                ),
                // أزرار الإجراءات السريعة (حفظ الموضع، المفضلة، نسخ، مشاركة)
                Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    IconButton(
                      icon: const Icon(Icons.bookmark_add_outlined, size: 20),
                      tooltip: 'تعيين كموضع قراءة',
                      onPressed: () => _saveReadingPosition(ayah.ayahNumber, surahName),
                    ),
                    IconButton(
                      icon: const Icon(Icons.star_border, size: 20),
                      tooltip: 'إضافة للمفضلة',
                      onPressed: () => _addToBookmarks(ayah, surahName),
                    ),
                    IconButton(
                      icon: const Icon(Icons.copy_outlined, size: 18),
                      tooltip: 'نسخ الآية',
                      onPressed: () => _copyAyah(ayah, surahName),
                    ),
                    IconButton(
                      icon: const Icon(Icons.share_outlined, size: 18),
                      tooltip: 'مشاركة الآية',
                      onPressed: () => _shareAyah(ayah, surahName),
                    ),
                  ],
                ),
              ],
            ),
            const SizedBox(height: 12),

            // النص العثماني الأصلي المشكول
            Text(
              ayah.textUthmani,
              style: TextStyle(
                fontSize: fontSize,
                height: 2.1,
                fontWeight: FontWeight.w500,
                color: Theme.of(context).textTheme.bodyLarge?.color,
              ),
              textAlign: TextAlign.right,
            ),
          ],
        ),
      ),
    );
  }
}
