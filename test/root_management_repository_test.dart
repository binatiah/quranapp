import 'dart:io';
import 'package:flutter_test/flutter_test.dart';
import 'package:path/path.dart' as p;
import 'package:quranapp/core/database/quran_database.dart';
import 'package:quranapp/core/text/arabic_normalizer.dart';
import 'package:quranapp/features/root_study/data/repositories/root_management_repository_impl.dart';
import 'package:quranapp/features/root_study/domain/repositories/root_management_repository.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';

void main() {
  setUpAll(() {
    sqfliteFfiInit();
  });

  group('RootManagementRepository Tests', () {
    late QuranDatabase testDb;
    late RootManagementRepository repository;
    late String testDbPath;

    setUpAll(() async {
      // ننشئ نسخة مؤقتة قابلة للكتابة من قاعدة البيانات لاختبار التعديل والإضافة والحذف بأمان
      final assetDbPath = p.join(Directory.current.path, 'assets', 'database', 'quran.db');
      final tempDir = Directory.systemTemp.createTempSync('root_repo_test');
      testDbPath = p.join(tempDir.path, 'quran_test.db');
      File(assetDbPath).copySync(testDbPath);

      testDb = QuranDatabase.forTesting(
        customFactory: databaseFactoryFfi,
        customPath: testDbPath,
        readOnly: false,
      );
      repository = RootManagementRepositoryImpl(
        database: testDb,
        normalizer: const ArabicNormalizerImpl(),
      );
    });

    tearDownAll(() async {
      await testDb.close();
      QuranDatabase.resetForTesting();
      try {
        final f = File(testDbPath);
        if (f.existsSync()) f.deleteSync();
      } catch (_) {}
    });

    test('getRoots returns paginated roots with occurrence and words count', () async {
      final roots = await repository.getRoots(
        sortBy: RootSortBy.occurrencesDesc,
        limit: 10,
        offset: 0,
      );

      expect(roots.length, 10);
      expect(roots.first.occurrencesCount, greaterThan(0));
      expect(roots.first.wordsCount, greaterThan(0));
      // الترتيب التنازلي
      for (var i = 0; i < roots.length - 1; i++) {
        expect(roots[i].occurrencesCount, greaterThanOrEqualTo(roots[i + 1].occurrencesCount));
      }
    });

    test('getRoots with search query filters roots correctly', () async {
      final roots = await repository.getRoots(query: 'علم');
      expect(roots.isNotEmpty, isTrue);
      expect(roots.any((r) => r.rootNormalized == 'علم'), isTrue);
    });

    test('getRootsCount returns accurate total count', () async {
      final total = await repository.getRootsCount();
      expect(total, greaterThan(1500));

      final filteredTotal = await repository.getRootsCount(query: 'حمد');
      expect(filteredTotal, greaterThan(0));
      expect(filteredTotal, lessThan(total));
    });

    test('addRoot, updateRoot, and deleteRoot lifecycle works seamlessly', () async {
      const testRoot = 'برمج';
      final newRoot = await repository.addRoot(
        root: testRoot,
        descriptionAr: 'جذر اختباري للبرمجة',
      );

      expect(newRoot.id, greaterThan(0));
      expect(newRoot.root, testRoot);
      expect(newRoot.rootNormalized, 'برمج');

      // جلب الجذر بالمعرف
      final fetched = await repository.getRootById(newRoot.id);
      expect(fetched, isNotNull);
      expect(fetched!.descriptionAr, 'جذر اختباري للبرمجة');

      // تعديل الجذر
      await repository.updateRoot(
        id: newRoot.id,
        root: 'برمج',
        descriptionAr: 'وصف محدث للجذر الاختباري',
      );
      final updated = await repository.getRootById(newRoot.id);
      expect(updated!.descriptionAr, 'وصف محدث للجذر الاختباري');

      // حذف الجذر
      final deleted = await repository.deleteRoot(newRoot.id);
      expect(deleted, isTrue);

      final afterDelete = await repository.getRootById(newRoot.id);
      expect(afterDelete, isNull);
    });
  });
}
