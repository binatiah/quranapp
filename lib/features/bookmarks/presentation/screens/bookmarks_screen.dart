import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:share_plus/share_plus.dart';

import '../../../../app/theme/app_theme.dart';
import '../../domain/entities/bookmark.dart';
import '../controllers/bookmarks_providers.dart';

/// شاشة عرض وإدارة الآيات المفضلة والملاحظات والتدبرات (BookmarksScreen).
class BookmarksScreen extends ConsumerStatefulWidget {
  const BookmarksScreen({super.key});

  @override
  ConsumerState<BookmarksScreen> createState() => _BookmarksScreenState();
}

class _BookmarksScreenState extends ConsumerState<BookmarksScreen> {
  final TextEditingController _searchController = TextEditingController();
  String _filterQuery = '';

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  /// فتح حوار تعديل أو إضافة ملاحظة/تدبر لآية محفوظة
  Future<void> _showEditNoteDialog(BuildContext context, Bookmark bookmark) async {
    final noteController = TextEditingController(text: bookmark.note ?? '');

    final saved = await showDialog<bool>(
      context: context,
      builder: (dialogCtx) {
        return AlertDialog(
          title: Row(
            children: [
              const Icon(Icons.edit_note, color: AppTheme.secondaryGold),
              const SizedBox(width: 8),
              Text(
                'تدبر: ${bookmark.surahName ?? ""} [${bookmark.ayahNumber ?? ""}]',
                style: const TextStyle(fontSize: 16),
              ),
            ],
          ),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const Text(
                'اكتب ملاحظتك الشخصية أو تدبرك حول هذه الآية:',
                style: TextStyle(fontSize: 13, color: Colors.grey),
              ),
              const SizedBox(height: 12),
              TextField(
                controller: noteController,
                maxLines: 4,
                autofocus: true,
                decoration: InputDecoration(
                  hintText: 'اكتب تدبرك هنا...',
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(10),
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(10),
                    borderSide: const BorderSide(color: AppTheme.primaryEmerald, width: 2),
                  ),
                ),
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(dialogCtx, false),
              child: const Text('إلغاء'),
            ),
            ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: AppTheme.primaryEmerald,
                foregroundColor: Colors.white,
              ),
              onPressed: () => Navigator.pop(dialogCtx, true),
              child: const Text('حفظ'),
            ),
          ],
        );
      },
    );

    if (saved == true && bookmark.id != null) {
      final newNote = noteController.text.trim();
      await ref
          .read(bookmarksNotifierProvider.notifier)
          .updateNote(bookmarkId: bookmark.id!, note: newNote);

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('تم حفظ الملاحظة بنجاح'),
            backgroundColor: AppTheme.primaryEmerald,
            duration: Duration(seconds: 2),
          ),
        );
      }
    }
  }

  /// نسخ نص الآية المفضلة مع بيانات السورة للحافظة
  void _copyBookmark(Bookmark bookmark) {
    final text = '﴿${bookmark.ayahText ?? ""}﴾\n[سورة ${bookmark.surahName ?? ""} - الآية ${bookmark.ayahNumber ?? ""}]';
    Clipboard.setData(ClipboardData(text: text));
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('تم نسخ الآية إلى الحافظة'),
        duration: Duration(seconds: 2),
      ),
    );
  }

  /// مشاركة نص الآية والتدبر الخارجي
  void _shareBookmark(Bookmark bookmark) {
    var text = '﴿${bookmark.ayahText ?? ""}﴾\n[سورة ${bookmark.surahName ?? ""} - الآية ${bookmark.ayahNumber ?? ""}]';
    if (bookmark.note != null && bookmark.note!.isNotEmpty) {
      text += '\n\nالتدبر / الملاحظة:\n${bookmark.note}';
    }
    SharePlus.instance.share(ShareParams(text: text));
  }

  /// حذف الآية من المفضلة بعد تأكيد المستخدم
  Future<void> _confirmDeleteBookmark(BuildContext context, Bookmark bookmark) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogCtx) => AlertDialog(
        title: const Text('حذف من المفضلة'),
        content: Text(
          'هل تريد حذف الآية ${bookmark.ayahNumber ?? ""} من سورة ${bookmark.surahName ?? ""} من المفضلة؟',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogCtx, false),
            child: const Text('إلغاء'),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.red.shade700,
              foregroundColor: Colors.white,
            ),
            onPressed: () => Navigator.pop(dialogCtx, true),
            child: const Text('حذف'),
          ),
        ],
      ),
    );

    if (confirmed == true && bookmark.id != null) {
      await ref.read(bookmarksNotifierProvider.notifier).removeBookmark(bookmark.id!);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('تم حذف الآية ${bookmark.ayahNumber ?? ""} من المفضلة'),
            backgroundColor: Colors.grey.shade800,
            duration: const Duration(seconds: 2),
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final bookmarksState = ref.watch(bookmarksNotifierProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('المفضلة والملاحظات'),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            tooltip: 'تحديث',
            onPressed: () => ref.read(bookmarksNotifierProvider.notifier).loadBookmarks(),
          ),
        ],
      ),
      body: bookmarksState.when(
        initial: () => const Center(
          child: CircularProgressIndicator(color: AppTheme.primaryEmerald),
        ),
        loading: () => const Center(
          child: CircularProgressIndicator(color: AppTheme.primaryEmerald),
        ),
        empty: () => _buildEmptyState(context),
        error: (errorMessage) => _buildErrorState(errorMessage),
        success: (allBookmarks) {
          final filtered = _filterQuery.isEmpty
              ? allBookmarks
              : allBookmarks.where((b) {
                  final sName = b.surahName ?? '';
                  final note = b.note ?? '';
                  final text = b.ayahText ?? '';
                  return sName.contains(_filterQuery) ||
                      note.contains(_filterQuery) ||
                      text.contains(_filterQuery);
                }).toList();

          if (filtered.isEmpty && _filterQuery.isNotEmpty) {
            return Column(
              children: [
                _buildSearchHeader(allBookmarks.length),
                Expanded(
                  child: Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const Icon(Icons.search_off, size: 56, color: Colors.grey),
                        const SizedBox(height: 12),
                        Text(
                          'لا توجد نتائج تطابق "$_filterQuery"',
                          style: const TextStyle(fontSize: 16, color: Colors.grey),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            );
          }

          return RefreshIndicator(
            color: AppTheme.primaryEmerald,
            onRefresh: () => ref.read(bookmarksNotifierProvider.notifier).loadBookmarks(),
            child: Column(
              children: [
                _buildSearchHeader(allBookmarks.length),
                Expanded(
                  child: ListView.separated(
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                    itemCount: filtered.length,
                    separatorBuilder: (_, __) => const SizedBox(height: 12),
                    itemBuilder: (context, index) {
                      final bookmark = filtered[index];
                      return _buildBookmarkCard(context, bookmark);
                    },
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }

  /// شريط تصفية وبحث في المفضلة
  Widget _buildSearchHeader(int totalCount) {
    return Container(
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 8),
      child: TextField(
        controller: _searchController,
        decoration: InputDecoration(
          hintText: 'البحث في المفضلة والملاحظات ($totalCount آيات)...',
          prefixIcon: const Icon(Icons.search, color: AppTheme.primaryEmerald),
          suffixIcon: _filterQuery.isNotEmpty
              ? IconButton(
                  icon: const Icon(Icons.clear),
                  onPressed: () {
                    _searchController.clear();
                    setState(() {
                      _filterQuery = '';
                    });
                  },
                )
              : null,
          filled: true,
          fillColor: Theme.of(context).cardColor,
          contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: BorderSide(color: Colors.grey.withValues(alpha: 0.3)),
          ),
          enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: BorderSide(color: Colors.grey.withValues(alpha: 0.2)),
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: const BorderSide(color: AppTheme.primaryEmerald, width: 1.5),
          ),
        ),
        onChanged: (val) {
          setState(() {
            _filterQuery = val.trim();
          });
        },
      ),
    );
  }

  /// بناء بطاقة الآية المفضلة مع الملاحظة والإجراءات
  Widget _buildBookmarkCard(BuildContext context, Bookmark bookmark) {
    final hasNote = bookmark.note != null && bookmark.note!.trim().isNotEmpty;

    return Card(
      elevation: 1.5,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(14),
        side: BorderSide(
          color: Theme.of(context).dividerColor.withValues(alpha: 0.2),
        ),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // السطر العلوي: اسم السورة ورقم الآية والأزرار السريعة
            Row(
              children: [
                // بادج اسم السورة ورقم الآية
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                  decoration: BoxDecoration(
                    color: AppTheme.primaryEmerald.withValues(alpha: 0.12),
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(
                      color: AppTheme.primaryEmerald.withValues(alpha: 0.3),
                    ),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Icon(Icons.menu_book, size: 14, color: AppTheme.primaryEmerald),
                      const SizedBox(width: 6),
                      Text(
                        'سورة ${bookmark.surahName ?? ""} - الآية ${bookmark.ayahNumber ?? ""}',
                        style: const TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.bold,
                          color: AppTheme.primaryEmerald,
                        ),
                      ),
                    ],
                  ),
                ),
                const Spacer(),
                // زر التعديل
                IconButton(
                  icon: const Icon(Icons.edit_note, size: 22, color: AppTheme.secondaryGold),
                  tooltip: hasNote ? 'تعديل التدبر' : 'إضافة تدبر',
                  onPressed: () => _showEditNoteDialog(context, bookmark),
                ),
                // زر النسخ
                IconButton(
                  icon: const Icon(Icons.copy_outlined, size: 18),
                  tooltip: 'نسخ الآية',
                  onPressed: () => _copyBookmark(bookmark),
                ),
                // زر المشاركة
                IconButton(
                  icon: const Icon(Icons.share_outlined, size: 18),
                  tooltip: 'مشاركة',
                  onPressed: () => _shareBookmark(bookmark),
                ),
                // زر الحذف
                IconButton(
                  icon: Icon(Icons.delete_outline, size: 20, color: Colors.red.shade400),
                  tooltip: 'حذف من المفضلة',
                  onPressed: () => _confirmDeleteBookmark(context, bookmark),
                ),
              ],
            ),
            const SizedBox(height: 12),

            // النص العثماني للآية
            Text(
              bookmark.ayahText ?? '',
              style: const TextStyle(
                fontFamily: 'UthmanicHafs',
                fontSize: 19,
                height: 2.0,
                fontWeight: FontWeight.w500,
              ),
              textAlign: TextAlign.right,
            ),

            // قسم الملاحظة / التدبر الشخصي إن وجد
            if (hasNote) ...[
              const SizedBox(height: 12),
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: AppTheme.secondaryGold.withValues(alpha: 0.08),
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(
                    color: AppTheme.secondaryGold.withValues(alpha: 0.35),
                  ),
                ),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Icon(
                      Icons.format_quote,
                      size: 20,
                      color: AppTheme.secondaryGold,
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                            'ملاحظتي / تدبري:',
                            style: TextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.bold,
                              color: AppTheme.secondaryGold,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            bookmark.note!,
                            style: const TextStyle(fontSize: 14, height: 1.5),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ] else ...[
              const SizedBox(height: 8),
              Align(
                alignment: Alignment.centerRight,
                child: TextButton.icon(
                  onPressed: () => _showEditNoteDialog(context, bookmark),
                  icon: const Icon(Icons.add, size: 16, color: AppTheme.secondaryGold),
                  label: const Text(
                    'إضافة تدبر أو ملاحظة',
                    style: TextStyle(fontSize: 12, color: AppTheme.secondaryGold),
                  ),
                ),
              ),
            ],

            const SizedBox(height: 8),
            const Divider(height: 1),
            const SizedBox(height: 8),

            // زر الانتقال للمصحف
            Align(
              alignment: Alignment.centerLeft,
              child: TextButton.icon(
                onPressed: () {
                  if (bookmark.surahId != null && bookmark.ayahNumber != null) {
                    context.push('/reader/${bookmark.surahId}?ayah=${bookmark.ayahNumber}');
                  }
                },
                icon: const Icon(Icons.arrow_back, size: 16, color: AppTheme.primaryEmerald),
                label: const Text(
                  'قراءة في المصحف',
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    color: AppTheme.primaryEmerald,
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  /// الحالة الفارغة عند عدم وجود أي آيات مفضلة
  Widget _buildEmptyState(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(
                color: AppTheme.secondaryGold.withValues(alpha: 0.1),
                shape: BoxShape.circle,
              ),
              child: const Icon(
                Icons.star_outline,
                size: 72,
                color: AppTheme.secondaryGold,
              ),
            ),
            const SizedBox(height: 24),
            const Text(
              'لا توجد آيات محفوظة في المفضلة',
              style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 10),
            const Text(
              'يمكنك حفظ الآيات أثناء القراءة بالنقر على رمز النجمة، وتدوين تدبراتك وملاحظاتك الشخصية للرجوع إليها لاحقاً.',
              textAlign: TextAlign.center,
              style: TextStyle(fontSize: 14, color: Colors.grey, height: 1.6),
            ),
            const SizedBox(height: 24),
            ElevatedButton.icon(
              style: ElevatedButton.styleFrom(
                backgroundColor: AppTheme.primaryEmerald,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
              ),
              onPressed: () => context.push('/surahs'),
              icon: const Icon(Icons.menu_book),
              label: const Text('تصفح المصحف الشريف'),
            ),
          ],
        ),
      ),
    );
  }

  /// حالة الخطأ مع إمكانية إعادة المحاولة
  Widget _buildErrorState(String errorMessage) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.error_outline, size: 60, color: Colors.red),
            const SizedBox(height: 16),
            Text(
              errorMessage,
              textAlign: TextAlign.center,
              style: const TextStyle(fontSize: 15, color: Colors.red),
            ),
            const SizedBox(height: 16),
            ElevatedButton.icon(
              onPressed: () => ref.read(bookmarksNotifierProvider.notifier).loadBookmarks(),
              icon: const Icon(Icons.refresh),
              label: const Text('إعادة المحاولة'),
            ),
          ],
        ),
      ),
    );
  }
}
