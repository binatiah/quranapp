import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:quranapp/core/constants/ui_state.dart';
import '../../data/repositories/bookmarks_repository_impl.dart';
import '../../domain/entities/bookmark.dart';
import '../../domain/repositories/bookmarks_repository.dart';

/// موفر مستودع المفضلة (BookmarksRepository Provider)
final bookmarksRepositoryProvider = Provider<BookmarksRepository>((ref) {
  return BookmarksRepositoryImpl();
});

/// متحكم حالة قائمة المفضلة وإدارتها (BookmarksNotifier)
class BookmarksNotifier extends Notifier<UIState<List<Bookmark>>> {
  @override
  UIState<List<Bookmark>> build() {
    Future.microtask(() => loadBookmarks());
    return UIState.initial();
  }

  BookmarksRepository get _repo => ref.read(bookmarksRepositoryProvider);

  /// تحميل جميع العلامات المرجعية المحفوظة
  Future<void> loadBookmarks() async {
    state = UIState.loading();
    try {
      final bookmarks = await _repo.getBookmarks();
      if (bookmarks.isEmpty) {
        state = UIState.empty();
      } else {
        state = UIState.success(bookmarks);
      }
    } catch (e) {
      state = UIState.error('تعذر جلب الآيات المفضلة: ${e.toString()}');
    }
  }

  /// إضافة آية جديدة إلى المفضلة
  Future<void> addBookmark({required int ayahId, String? note}) async {
    try {
      await _repo.addBookmark(ayahId: ayahId, note: note);
      await loadBookmarks();
    } catch (_) {}
  }

  /// تحديث ملاحظة أو تدبر علامة مرجعية
  Future<void> updateNote({required int bookmarkId, required String note}) async {
    try {
      await _repo.updateBookmarkNote(bookmarkId: bookmarkId, note: note);
      await loadBookmarks();
    } catch (_) {}
  }

  /// حذف علامة مرجعية عبر المعرف
  Future<void> removeBookmark(int bookmarkId) async {
    try {
      await _repo.removeBookmark(bookmarkId);
      await loadBookmarks();
    } catch (_) {}
  }

  /// تبديل حالة التفضيل لآية (إضافة أو حذف)
  Future<bool> toggleBookmark({required int ayahId, String? note}) async {
    final isAlreadyBookmarked = await _repo.isBookmarked(ayahId);
    if (isAlreadyBookmarked) {
      await _repo.removeBookmarkByAyahId(ayahId);
      await loadBookmarks();
      return false;
    } else {
      await _repo.addBookmark(ayahId: ayahId, note: note);
      await loadBookmarks();
      return true;
    }
  }
}

/// موفر قائمة المفضلة العام للتطبيق
final bookmarksNotifierProvider =
    NotifierProvider<BookmarksNotifier, UIState<List<Bookmark>>>(() {
  return BookmarksNotifier();
});

/// موفر التحقق مما إذا كانت آية معينة مضافة للمفضلة
final isAyahBookmarkedProvider = FutureProvider.family<bool, int>((ref, ayahId) async {
  // نعيد الاستماع لموفر المفضلة ليحدث تلقائياً عند أي إضافة أو حذف
  ref.watch(bookmarksNotifierProvider);
  final repo = ref.read(bookmarksRepositoryProvider);
  return repo.isBookmarked(ayahId);
});
