import '../entities/bookmark.dart';

/// واجهة مستودع إدارة العلامات المرجعية والمفضلة (BookmarksRepository Interface).
abstract interface class BookmarksRepository {
  /// جلب جميع العلامات المرجعية المحفوظة مرتبة من الأحدث إلى الأقدم مع تفاصيل الآية والسورة
  Future<List<Bookmark>> getBookmarks();

  /// جلب علامة مرجعية لآية معينة إن وجدت
  Future<Bookmark?> getBookmarkByAyahId(int ayahId);

  /// إضافة آية جديدة إلى المفضلة مع ملاحظة اختيارية
  Future<int> addBookmark({
    required int ayahId,
    String? note,
  });

  /// تحديث ملاحظة أو تدبر علامة مرجعية موجودة
  Future<bool> updateBookmarkNote({
    required int bookmarkId,
    required String note,
  });

  /// إزالة علامة مرجعية عبر المعرف
  Future<bool> removeBookmark(int bookmarkId);

  /// إزالة علامة مرجعية عبر معرف الآية
  Future<bool> removeBookmarkByAyahId(int ayahId);

  /// التحقق مما إذا كانت الآية مضافة إلى المفضلة
  Future<bool> isBookmarked(int ayahId);
}
