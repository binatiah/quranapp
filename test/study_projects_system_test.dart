import 'dart:io';
import 'package:flutter_test/flutter_test.dart';
import 'package:path/path.dart' as p;
import 'package:sqflite_common_ffi/sqflite_ffi.dart';

import 'package:quranapp/core/database/quran_database.dart';
import 'package:quranapp/features/study_projects/domain/entities/study_project.dart';
import 'package:quranapp/features/study_projects/domain/entities/study_project_full.dart';
import 'package:quranapp/features/study_projects/domain/entities/root_study_details.dart';
import 'package:quranapp/features/study_projects/domain/entities/ayah_study_details.dart';
import 'package:quranapp/features/study_projects/domain/entities/concept_study_details.dart';
import 'package:quranapp/features/study_projects/domain/services/study_project_analyzer_service.dart';
import 'package:quranapp/features/study_projects/data/repositories/study_projects_repository_impl.dart';

void main() {
  setUpAll(() {
    sqfliteFfiInit();
  });

  group('StudyProjectAnalyzerService Unit Tests', () {
    const analyzer = StudyProjectAnalyzerService();

    test('analyzes sound triliteral root correctly', () {
      final res = analyzer.analyzeRoot('علم');
      expect(res.rootType, 'ثلاثي');
      expect(res.hasVowels, isFalse);
      expect(res.vowelsCount, 0);
      expect(res.vowelsList, 'لا يوجد');
    });

    test('analyzes defective root with vowels correctly', () {
      final res = analyzer.analyzeRoot('وعد');
      expect(res.rootType, 'ثلاثي');
      expect(res.hasVowels, isTrue);
      expect(res.vowelsCount, 1);
      expect(res.vowelsList, contains('و'));
    });

    test('analyzes root with multiple vowels correctly', () {
      final res = analyzer.analyzeRoot('وحي');
      expect(res.rootType, 'ثلاثي');
      expect(res.hasVowels, isTrue);
      expect(res.vowelsCount, 2);
      expect(res.vowelsList, contains('و'));
      expect(res.vowelsList, contains('ي'));
    });

    test('analyzes quadriliteral root correctly', () {
      final res = analyzer.analyzeRoot('زلزل');
      expect(res.rootType, 'رباعي');
      expect(res.hasVowels, isFalse);
      expect(res.vowelsCount, 0);
    });

    test('calculates project progress and exports to Markdown and JSON', () {
      final now = DateTime.now();
      final project = StudyProject(
        id: 1,
        title: 'دراسة جذر علم',
        projectType: StudyProjectType.root,
        targetIdentifier: 'علم',
        createdAt: now,
        updatedAt: now,
      );

      const rootDetails = RootStudyDetails(
        projectId: 1,
        rootType: 'ثلاثي',
        hasVowels: false,
        vowelsCount: 0,
        cognatesOtherLanguages: 'Aramaic: alema',
        oldestUsage: 'استخدم في النقوش القديمة',
        isUsedToday: true,
        usageNature: 'معنوية',
        synonyms: 'عرف، فقه',
        antonyms: 'جهل',
        researcherNotes: 'الجذر يدور حول إدراك الشيء بحقيقته',
      );

      final full = project.copyWith(progress: 0.9);
      final projectFull = full.toFull(
        rootDetails: rootDetails,
        targetRootDerivedWordsCount: 15,
      );

      final progress = analyzer.calculateProgress(projectFull);
      expect(progress, greaterThanOrEqualTo(0.8));

      final md = analyzer.exportToMarkdown(projectFull);
      expect(md, contains('# مشروع دراسة قرآنية: دراسة جذر علم'));
      expect(md, contains('ثلاثي'));
      expect(md, contains('عرف، فقه'));

      final json = analyzer.exportToJson(projectFull);
      expect(json, contains('"title": "دراسة جذر علم"'));
      expect(json, contains('"root_type": "ثلاثي"'));
    });
  });

  group('StudyProjectsRepository SQLite Integration Tests', () {
    late QuranDatabase testDb;
    late String testDbPath;
    late StudyProjectsRepositoryImpl repository;

    setUpAll(() async {
      final assetDbPath = p.join(Directory.current.path, 'assets', 'database', 'quran.db');
      final tempDir = Directory.systemTemp.createTempSync('study_projects_test');
      testDbPath = p.join(tempDir.path, 'quran_test.db');
      File(assetDbPath).copySync(testDbPath);

      testDb = QuranDatabase.forTesting(
        customFactory: databaseFactoryFfi,
        customPath: testDbPath,
        readOnly: false,
      );

      repository = StudyProjectsRepositoryImpl(database: testDb);
    });

    tearDownAll(() async {
      try {
        final db = await testDb.database;
        await db.close();
        final file = File(testDbPath);
        if (file.existsSync()) file.deleteSync();
      } catch (_) {}
    });

    test('creates and retrieves a root study project with stats', () async {
      final now = DateTime.now();
      final project = StudyProject(
        title: 'مشروع دراسة جذر علم',
        projectType: StudyProjectType.root,
        targetIdentifier: 'علم',
        description: 'تحليل دلالة العلم في القرآن',
        createdAt: now,
        updatedAt: now,
      );

      const rootDetails = RootStudyDetails(
        projectId: 0,
        rootType: 'ثلاثي',
        hasVowels: false,
        vowelsCount: 0,
        vowelsList: 'لا يوجد',
        cognatesOtherLanguages: 'سريانية: عليم',
        oldestUsage: 'ورد قبل القرآن بكثرة',
        isUsedToday: true,
        usageNature: 'معنوية',
        synonyms: 'معرفة، دراية',
        antonyms: 'جهل',
        researcherNotes: 'دراسة استقرائية متكاملة',
      );

      final projectId = await repository.createProject(
        project,
        rootDetails: rootDetails,
      );

      expect(projectId, greaterThan(0));

      final retrieved = await repository.getProjectById(projectId);
      expect(retrieved, isNotNull);
      expect(retrieved!.project.title, 'مشروع دراسة جذر علم');
      expect(retrieved.rootDetails, isNotNull);
      expect(retrieved.rootDetails!.rootType, 'ثلاثي');
      expect(retrieved.rootDetails!.synonyms, 'معرفة، دراية');
      expect(retrieved.targetRootTotalOccurrences, greaterThan(0));
      expect(retrieved.targetRootDerivedWordsCount, greaterThan(0));
    });

    test('creates and retrieves an ayah study project with Quranic verse text', () async {
      final now = DateTime.now();
      final project = StudyProject(
        title: 'دراسة آية الكرسي',
        projectType: StudyProjectType.ayah,
        targetIdentifier: '2:255',
        description: 'أعظم آية في كتاب الله',
        createdAt: now,
        updatedAt: now,
      );

      const ayahDetails = AyahStudyDetails(
        projectId: 0,
        surahId: 2,
        ayahNumber: 255,
        topic: 'التوحيد والصفات الإلهية العظمى',
        traditionalTafseer: 'تفسير ابن كثير والطبري',
        revelationContext: 'مدنية',
        apparentConcept: 'عظمة الله وقيوميته المطلقة',
        rulingOrStatus: 'دلالة عقدية إيمانية',
      );

      final projectId = await repository.createProject(
        project,
        ayahDetails: ayahDetails,
      );

      expect(projectId, greaterThan(0));

      final retrieved = await repository.getProjectById(projectId);
      expect(retrieved, isNotNull);
      expect(retrieved!.project.targetIdentifier, '2:255');
      expect(retrieved.targetSurahName, 'البقرة');
      expect(retrieved.targetVerseText, contains('اللَّهُ لَا إِلَهَ إِلَّا هُوَ الْحَيُّ الْقَيُّومُ'));
    });

    test('creates and retrieves a concept study project and links roots and ayahs', () async {
      final now = DateTime.now();
      final project = StudyProject(
        title: 'مفهوم العدل في القرآن',
        projectType: StudyProjectType.concept,
        targetIdentifier: 'العدل',
        createdAt: now,
        updatedAt: now,
      );

      const conceptDetails = ConceptStudyDetails(
        projectId: 0,
        term: 'العدل',
        denotationType: 'فكري',
        quranicVsContemporaryMeaning: 'في القرآن يتجاوز العدالة القانونية ليشمل التوحيد والميزان',
        oppositeConcept: 'الظلم',
        relatedConcepts: 'القسط، الميزان، الحق',
        quranicDiscourse: 'عرض القرآن مفهوم العدل كقانون كوني وتشريع مجتمعي',
      );

      final projectId = await repository.createProject(
        project,
        conceptDetails: conceptDetails,
      );

      expect(projectId, greaterThan(0));

      // إضافة روابط آيات
      final linkAyahId = await repository.addAyahLink(
        projectId: projectId,
        ayahId: 1, // آية الفاتحة 1
        note: 'فاتحة الكتاب والميزان',
        relationType: 'related',
      );
      expect(linkAyahId, greaterThan(0));

      // إضافة روابط جذور
      final linkRootId = await repository.addRootLink(
        projectId: projectId,
        rootNormalized: 'عدل',
        note: 'الجذر المركزي للمفهوم',
      );
      expect(linkRootId, greaterThan(0));

      final retrieved = await repository.getProjectById(projectId);
      expect(retrieved, isNotNull);
      expect(retrieved!.conceptDetails, isNotNull);
      expect(retrieved.conceptDetails!.oppositeConcept, 'الظلم');
      expect(retrieved.linkedAyahs.length, 1);
      expect(retrieved.linkedRoots.length, 1);
      expect(retrieved.linkedRoots.first.rootNormalized, 'عدل');
      expect(retrieved.linkedRoots.first.occurrenceCount, greaterThan(0));

      // حذف رابط وتحقق
      await repository.removeAyahLink(linkAyahId);
      await repository.removeRootLink(linkRootId);

      final afterDeleteLinks = await repository.getProjectById(projectId);
      expect(afterDeleteLinks!.linkedAyahs, isEmpty);
      expect(afterDeleteLinks.linkedRoots, isEmpty);
    });

    test('updates project details and checks statistics and cascade deletion', () async {
      final statsBefore = await repository.getProjectsStatistics();
      expect(statsBefore['total'], greaterThanOrEqualTo(3));

      // جلب المشاريع المصفاة بنمط الجذر
      final rootProjects = await repository.getProjects(type: StudyProjectType.root);
      expect(rootProjects, isNotEmpty);
      final targetProjectId = rootProjects.first.id!;

      // حذف المشروع
      await repository.deleteProject(targetProjectId);

      final afterDelete = await repository.getProjectById(targetProjectId);
      expect(afterDelete, isNull);

      // التأكد من الحذف المتتالي في جداول التفاصيل
      final db = await testDb.database;
      final childRows = await db.query(
        'root_study_projects',
        where: 'project_id = ?',
        whereArgs: [targetProjectId],
      );
      expect(childRows, isEmpty);

      final statsAfter = await repository.getProjectsStatistics();
      expect(statsAfter['total']!, statsBefore['total']! - 1);
    });
  });
}

extension StudyProjectTestX on StudyProject {
  StudyProjectFull toFull({
    RootStudyDetails? rootDetails,
    AyahStudyDetails? ayahDetails,
    ConceptStudyDetails? conceptDetails,
    int? targetRootDerivedWordsCount,
  }) {
    return StudyProjectFull(
      project: this,
      rootDetails: rootDetails,
      ayahDetails: ayahDetails,
      conceptDetails: conceptDetails,
      targetRootDerivedWordsCount: targetRootDerivedWordsCount,
    );
  }
}
