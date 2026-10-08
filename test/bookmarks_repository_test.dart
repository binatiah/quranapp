import 'dart:io';
import 'package:flutter_test/flutter_test.dart';
import 'package:path/path.dart' as p;
import 'package:quranapp/core/database/quran_database.dart';
import 'package:quranapp/features/bookmarks/data/repositories/bookmarks_repository_impl.dart';
import 'package:quranapp/features/bookmarks/domain/repositories/bookmarks_repository.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';

void main() {
  setUpAll(() {
    sqfliteFfiInit();
  });

  group('BookmarksRepository SQLite Tests', () {
    late Directory tempDir;
    late String tempDbPath;
    late QuranDatabase quranDb;
    late BookmarksRepository bookmarksRepo;

    setUp(() async {
      QuranDatabase.resetForTesting();

      // إنشاء مجلد مؤقت ونسخ قاعدة البيانات لعزل عمليات الكتابة
      tempDir = Directory.systemTemp.createTempSync('quran_bookmarks_test_');
      final assetDbFile = File(p.join(Directory.current.path, 'assets', 'database', 'quran.db'));
      tempDbPath = p.join(tempDir.path, 'quran_test.db');
      await assetDbFile.copy(tempDbPath);

      quranDb = QuranDatabase.forTesting(
        customFactory: databaseFactoryFfi,
        customPath: tempDbPath,
      );

      bookmarksRepo = BookmarksRepositoryImpl(database: quranDb);
    });

    tearDown(() async {
      await quranDb.close();
      QuranDatabase.resetForTesting();
      try {
        if (tempDir.existsSync()) {
          tempDir.deleteSync(recursive: true);
        }
      } catch (_) {}
    });

    test('getBookmarks returns empty list initially', () async {
      // إفراغ أي بيانات سابقة
      final rawDb = await quranDb.database;
      await rawDb.delete('bookmarks');

      final bookmarks = await bookmarksRepo.getBookmarks();
      expect(bookmarks, isEmpty);
    });

    test('addBookmark successfully inserts and retrieves bookmark with Surah details', () async {
      final rawDb = await quranDb.database;
      await rawDb.delete('bookmarks');

      // إضافة الآية 1 من سورة الفاتحة
      final id = await bookmarksRepo.addBookmark(
        ayahId: 1,
        note: 'تدبر في البسملة وفضائلها',
      );
      expect(id, greaterThan(0));

      final isSaved = await bookmarksRepo.isBookmarked(1);
      expect(isSaved, isTrue);

      final bookmarks = await bookmarksRepo.getBookmarks();
      expect(bookmarks.length, 1);

      final first = bookmarks.first;
      expect(first.id, id);
      expect(first.ayahId, 1);
      expect(first.surahName, 'الفاتحة');
      expect(first.ayahNumber, 1);
      expect(first.ayahText, contains('بِسْمِ اللَّهِ'));
      expect(first.note, 'تدبر في البسملة وفضائلها');
    });

    test('addBookmark on existing ayah updates note instead of duplicating', () async {
      final rawDb = await quranDb.database;
      await rawDb.delete('bookmarks');

      // الإضافة الأولى
      final id1 = await bookmarksRepo.addBookmark(
        ayahId: 2,
        note: 'ملاحظة أولى',
      );

      // الإضافة الثانية لنفس الآية
      final id2 = await bookmarksRepo.addBookmark(
        ayahId: 2,
        note: 'ملاحظة ثانية محدثة',
      );

      expect(id2, id1);

      final list = await bookmarksRepo.getBookmarks();
      expect(list.length, 1);
      expect(list.first.note, 'ملاحظة ثانية محدثة');
    });

    test('updateBookmarkNote updates note text successfully', () async {
      final rawDb = await quranDb.database;
      await rawDb.delete('bookmarks');

      final id = await bookmarksRepo.addBookmark(ayahId: 7, note: 'ملاحظة قبل التعديل');
      final updated = await bookmarksRepo.updateBookmarkNote(
        bookmarkId: id,
        note: 'ملاحظة بعد التعديل',
      );
      expect(updated, isTrue);

      final bookmark = await bookmarksRepo.getBookmarkByAyahId(7);
      expect(bookmark, isNotNull);
      expect(bookmark!.note, 'ملاحظة بعد التعديل');
    });

    test('removeBookmark deletes the bookmark correctly', () async {
      final rawDb = await quranDb.database;
      await rawDb.delete('bookmarks');

      final id = await bookmarksRepo.addBookmark(ayahId: 3);
      expect(await bookmarksRepo.isBookmarked(3), isTrue);

      final deleted = await bookmarksRepo.removeBookmark(id);
      expect(deleted, isTrue);

      expect(await bookmarksRepo.isBookmarked(3), isFalse);
      final list = await bookmarksRepo.getBookmarks();
      expect(list, isEmpty);
    });

    test('removeBookmarkByAyahId deletes correctly using ayahId', () async {
      final rawDb = await quranDb.database;
      await rawDb.delete('bookmarks');

      await bookmarksRepo.addBookmark(ayahId: 5);
      expect(await bookmarksRepo.isBookmarked(5), isTrue);

      final deleted = await bookmarksRepo.removeBookmarkByAyahId(5);
      expect(deleted, isTrue);

      expect(await bookmarksRepo.isBookmarked(5), isFalse);
    });
  });
}
