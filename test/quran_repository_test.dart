import 'dart:io';
import 'package:flutter_test/flutter_test.dart';
import 'package:path/path.dart' as p;
import 'package:quranapp/core/database/quran_database.dart';
import 'package:quranapp/features/quran_reader/data/repositories/quran_repository_impl.dart';
import 'package:quranapp/features/quran_reader/presentation/controllers/quran_providers.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';

void main() {
  setUpAll(() {
    sqfliteFfiInit();
  });

  group('QuranRepository & Presentation Controllers Tests', () {
    late QuranDatabase testDb;
    late QuranRepositoryImpl repository;

    setUp(() async {
      QuranDatabase.resetForTesting();
      final assetDbPath = p.join(Directory.current.path, 'assets', 'database', 'quran.db');

      testDb = QuranDatabase.forTesting(
        customFactory: databaseFactoryFfi,
        customPath: assetDbPath,
      );
      repository = QuranRepositoryImpl(database: testDb);
    });

    tearDown(() async {
      await testDb.close();
      QuranDatabase.resetForTesting();
    });

    test('getSurahs returns all 114 surahs in ascending order', () async {
      final surahs = await repository.getSurahs();
      expect(surahs.length, 114);
      expect(surahs.first.id, 1);
      expect(surahs.first.nameArabic, 'الفاتحة');
      expect(surahs.last.id, 114);
      expect(surahs.last.nameArabic, 'الناس');
    });

    test('getSurahById returns correct surah data', () async {
      final fatihah = await repository.getSurahById(1);
      expect(fatihah, isNotNull);
      expect(fatihah!.nameArabic, 'الفاتحة');
      expect(fatihah.ayahCount, 7);

      final baqarah = await repository.getSurahById(2);
      expect(baqarah, isNotNull);
      expect(baqarah!.nameArabic, 'البقرة');
      expect(baqarah.ayahCount, 286);
      expect(baqarah.revelationType, 'مدنية');

      final nonExistent = await repository.getSurahById(999);
      expect(nonExistent, isNull);
    });

    test('getSurahAyahs returns complete Uthmani text with correct count', () async {
      // الفاتحة 7 آيات
      final fatihahAyahs = await repository.getSurahAyahs(1);
      expect(fatihahAyahs.length, 7);
      expect(fatihahAyahs.first.ayahNumber, 1);
      expect(fatihahAyahs.first.textUthmani, contains('بِسْمِ اللَّهِ الرَّحْمَٰنِ الرَّحِيمِ'));
      expect(fatihahAyahs.last.ayahNumber, 7);
      expect(fatihahAyahs.last.textUthmani, contains('الضَّالِّينَ'));

      // الناس 6 آيات
      final nasAyahs = await repository.getSurahAyahs(114);
      expect(nasAyahs.length, 6);
      expect(nasAyahs.first.ayahNumber, 1);
      expect(nasAyahs.last.ayahNumber, 6);
    });

    test('getAyah returns a specific verse accurately', () async {
      // آية الكرسي: سورة البقرة (2) الآية 255
      final kursi = await repository.getAyah(2, 255);
      expect(kursi, isNotNull);
      expect(kursi!.surahId, 2);
      expect(kursi.ayahNumber, 255);
      expect(kursi.textUthmani, contains('اللَّهُ لَا إِلَهَ إِلَّا هُوَ الْحَيُّ الْقَيُّومُ'));
    });

    test('getAyahRange retrieves precise verse slices without bleed', () async {
      // جلب الآيات 1 إلى 5 من سورة البقرة
      final range = await repository.getAyahRange(
        surahId: 2,
        startAyah: 1,
        endAyah: 5,
      );

      expect(range.length, 5);
      expect(range.first.ayahNumber, 1);
      expect(range.first.textUthmani, 'الم');
      expect(range.last.ayahNumber, 5);
    });

    test('saveReadingPosition and getLastReadingPosition persistence', () async {
      // حفظ موضع عند سورة يوسف الآية 1
      await repository.saveReadingPosition(surahId: 12, ayahNumber: 1);

      final saved = await repository.getLastReadingPosition();
      expect(saved, isNotNull);
      expect(saved!.surahId, 12);
      expect(saved.ayahNumber, 1);

      // تحديث الموضع إلى سورة الكهف الآية 10
      await repository.saveReadingPosition(surahId: 18, ayahNumber: 10);
      final updated = await repository.getLastReadingPosition();
      expect(updated, isNotNull);
      expect(updated!.surahId, 18);
      expect(updated.ayahNumber, 10);
    });

    test('SurahListNotifier loads and filters surahs accurately', () async {
      final notifier = SurahListNotifier(repository);
      await notifier.loadSurahs();

      // التحقق من نجاح التحميل الأولي
      expect(notifier.state.uiState.isSuccess, isTrue);
      expect(notifier.state.uiState.data!.length, 114);

      // البحث بالاسم العربي
      notifier.search('البقرة');
      expect(notifier.state.uiState.data!.length, 1);
      expect(notifier.state.uiState.data!.first.nameArabic, 'البقرة');

      // البحث برقم السورة
      notifier.search('36');
      expect(notifier.state.uiState.data!.length, 1);
      expect(notifier.state.uiState.data!.first.nameArabic, 'يس');

      // البحث بنص غير موجود
      notifier.search('سورة_غير_موجودة');
      expect(notifier.state.uiState.isEmpty, isTrue);

      // مسح البحث
      notifier.search('');
      expect(notifier.state.uiState.data!.length, 114);
    });
  });
}
