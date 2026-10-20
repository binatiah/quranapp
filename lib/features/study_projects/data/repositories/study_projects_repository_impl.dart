import 'package:sqflite/sqflite.dart';
import 'package:quranapp/core/database/quran_database.dart';
import '../../domain/entities/study_project.dart';
import '../../domain/entities/study_project_full.dart';
import '../../domain/entities/root_study_details.dart';
import '../../domain/entities/ayah_study_details.dart';
import '../../domain/entities/concept_study_details.dart';
import '../../domain/entities/study_project_ayah_link.dart';
import '../../domain/entities/study_project_root_link.dart';
import '../../domain/repositories/study_projects_repository.dart';

/// تطبيق مستودع إدارة مشاريع الدراسة القرآنية المعتمد على SQLite
class StudyProjectsRepositoryImpl implements StudyProjectsRepository {
  final QuranDatabase _db;

  /// منشئ المستودع
  StudyProjectsRepositoryImpl({QuranDatabase? database})
      : _db = database ?? QuranDatabase.instance;

  @override
  Future<List<StudyProject>> getProjects({
    StudyProjectType? type,
    StudyProjectStatus? status,
    String? query,
  }) async {
    final whereClauses = <String>[];
    final whereArgs = <dynamic>[];

    if (type != null) {
      whereClauses.add('project_type = ?');
      whereArgs.add(type.toDbValue());
    }

    if (status != null) {
      whereClauses.add('status = ?');
      whereArgs.add(status.toDbValue());
    }

    if (query != null && query.trim().isNotEmpty) {
      whereClauses.add('(title LIKE ? OR target_identifier LIKE ? OR description LIKE ?)');
      final term = '%${query.trim()}%';
      whereArgs.addAll([term, term, term]);
    }

    final whereSql = whereClauses.isNotEmpty ? 'WHERE ${whereClauses.join(' AND ')}' : '';
    final sql = 'SELECT * FROM study_projects $whereSql ORDER BY updated_at DESC;';

    final rows = await _db.query(sql: sql, arguments: whereArgs);
    return rows.map((row) => StudyProject.fromMap(row)).toList();
  }

  @override
  Future<StudyProjectFull?> getProjectById(int id) async {
    final projectRows = await _db.query(
      sql: 'SELECT * FROM study_projects WHERE id = ? LIMIT 1;',
      arguments: [id],
    );

    if (projectRows.isEmpty) return null;
    final project = StudyProject.fromMap(projectRows.first);

    RootStudyDetails? rootDetails;
    AyahStudyDetails? ayahDetails;
    ConceptStudyDetails? conceptDetails;
    String? targetVerseText;
    String? targetSurahName;
    int? targetRootTotalOccurrences;
    int? targetRootDerivedWordsCount;

    // استعلام تفاصيل دراسة الجذر
    if (project.projectType == StudyProjectType.root) {
      final rootRows = await _db.query(
        sql: 'SELECT * FROM root_study_projects WHERE project_id = ? LIMIT 1;',
        arguments: [id],
      );
      if (rootRows.isNotEmpty) {
        rootDetails = RootStudyDetails.fromMap(rootRows.first);
      }

      // جلب إحصاءات الجذر من جدول الكلمات القرآنية
      final statsRows = await _db.query(
        sql: '''
          SELECT COUNT(*) as total_occurrences,
                 COUNT(DISTINCT word_normalized) as unique_words
          FROM words
          WHERE root_normalized = ?;
        ''',
        arguments: [project.targetIdentifier],
      );
      if (statsRows.isNotEmpty) {
        targetRootTotalOccurrences = (statsRows.first['total_occurrences'] as int?) ?? 0;
        targetRootDerivedWordsCount = (statsRows.first['unique_words'] as int?) ?? 0;
      }
    }

    // استعلام تفاصيل دراسة الآية
    if (project.projectType == StudyProjectType.ayah) {
      final ayahRows = await _db.query(
        sql: 'SELECT * FROM ayah_study_projects WHERE project_id = ? LIMIT 1;',
        arguments: [id],
      );
      if (ayahRows.isNotEmpty) {
        ayahDetails = AyahStudyDetails.fromMap(ayahRows.first);

        // جلب نص الآية واسم السورة
        final verseRows = await _db.query(
          sql: '''
            SELECT a.text_uthmani, s.name_arabic as surah_name
            FROM ayahs a
            INNER JOIN surahs s ON s.id = a.surah_id
            WHERE a.surah_id = ? AND a.ayah_number = ?
            LIMIT 1;
          ''',
          arguments: [ayahDetails.surahId, ayahDetails.ayahNumber],
        );
        if (verseRows.isNotEmpty) {
          targetVerseText = verseRows.first['text_uthmani'] as String?;
          targetSurahName = verseRows.first['surah_name'] as String?;
        }
      }
    }

    // استعلام تفاصيل دراسة المفهوم
    if (project.projectType == StudyProjectType.concept) {
      final conceptRows = await _db.query(
        sql: 'SELECT * FROM concept_study_projects WHERE project_id = ? LIMIT 1;',
        arguments: [id],
      );
      if (conceptRows.isNotEmpty) {
        conceptDetails = ConceptStudyDetails.fromMap(conceptRows.first);
      }
    }

    // جلب الآيات المرتبطة
    final linkedAyahsRows = await _db.query(
      sql: '''
        SELECT l.id, l.project_id, l.ayah_id, l.note, l.relation_type,
               a.ayah_number, a.text_uthmani, s.id as surah_id, s.name_arabic as surah_name
        FROM study_project_ayahs l
        INNER JOIN ayahs a ON a.id = l.ayah_id
        INNER JOIN surahs s ON s.id = a.surah_id
        WHERE l.project_id = ?
        ORDER BY a.global_ayah_number;
      ''',
      arguments: [id],
    );
    final linkedAyahs = linkedAyahsRows.map((r) => StudyProjectAyahLink.fromMap(r)).toList();

    // جلب الجذور المرتبطة (لمشاريع المفاهيم)
    final linkedRootsRows = await _db.query(
      sql: '''
        SELECT l.id, l.project_id, l.root_normalized, l.note,
               (SELECT COUNT(*) FROM words w WHERE w.root_normalized = l.root_normalized) AS occurrence_count
        FROM study_project_roots l
        WHERE l.project_id = ?
        ORDER BY occurrence_count DESC;
      ''',
      arguments: [id],
    );
    final linkedRoots = linkedRootsRows.map((r) => StudyProjectRootLink.fromMap(r)).toList();

    return StudyProjectFull(
      project: project,
      rootDetails: rootDetails,
      ayahDetails: ayahDetails,
      conceptDetails: conceptDetails,
      linkedAyahs: linkedAyahs,
      linkedRoots: linkedRoots,
      targetVerseText: targetVerseText,
      targetSurahName: targetSurahName,
      targetRootTotalOccurrences: targetRootTotalOccurrences,
      targetRootDerivedWordsCount: targetRootDerivedWordsCount,
    );
  }

  @override
  Future<int> createProject(
    StudyProject project, {
    RootStudyDetails? rootDetails,
    AyahStudyDetails? ayahDetails,
    ConceptStudyDetails? conceptDetails,
  }) async {
    final dbClient = await _db.database;

    return await dbClient.transaction<int>((txn) async {
      final projectId = await txn.insert('study_projects', project.toMap());

      if (project.projectType == StudyProjectType.root) {
        final details = rootDetails ?? RootStudyDetails(projectId: projectId);
        await txn.insert('root_study_projects', details.copyWith(projectId: projectId).toMap());
      } else if (project.projectType == StudyProjectType.ayah && ayahDetails != null) {
        await txn.insert('ayah_study_projects', ayahDetails.copyWith(projectId: projectId).toMap());
      } else if (project.projectType == StudyProjectType.concept) {
        final details = conceptDetails ?? ConceptStudyDetails(projectId: projectId, term: project.targetIdentifier);
        await txn.insert('concept_study_projects', details.copyWith(projectId: projectId).toMap());
      }

      return projectId;
    });
  }

  @override
  Future<void> updateProject(StudyProject project) async {
    final nowIso = DateTime.now().toIso8601String();
    await _db.update(
      table: 'study_projects',
      values: {
        'title': project.title,
        'description': project.description,
        'status': project.status.toDbValue(),
        'progress': project.progress,
        'updated_at': nowIso,
      },
      where: 'id = ?',
      whereArgs: [project.id],
    );
  }

  @override
  Future<void> updateRootDetails(RootStudyDetails details) async {
    final dbClient = await _db.database;
    await dbClient.transaction((txn) async {
      await txn.insert(
        'root_study_projects',
        details.toMap(),
        conflictAlgorithm: ConflictAlgorithm.replace,
      );
      await txn.update(
        'study_projects',
        {'updated_at': DateTime.now().toIso8601String()},
        where: 'id = ?',
        whereArgs: [details.projectId],
      );
    });
  }

  @override
  Future<void> updateAyahDetails(AyahStudyDetails details) async {
    final dbClient = await _db.database;
    await dbClient.transaction((txn) async {
      await txn.insert(
        'ayah_study_projects',
        details.toMap(),
        conflictAlgorithm: ConflictAlgorithm.replace,
      );
      await txn.update(
        'study_projects',
        {'updated_at': DateTime.now().toIso8601String()},
        where: 'id = ?',
        whereArgs: [details.projectId],
      );
    });
  }

  @override
  Future<void> updateConceptDetails(ConceptStudyDetails details) async {
    final dbClient = await _db.database;
    await dbClient.transaction((txn) async {
      await txn.insert(
        'concept_study_projects',
        details.toMap(),
        conflictAlgorithm: ConflictAlgorithm.replace,
      );
      await txn.update(
        'study_projects',
        {'updated_at': DateTime.now().toIso8601String()},
        where: 'id = ?',
        whereArgs: [details.projectId],
      );
    });
  }

  @override
  Future<void> deleteProject(int projectId) async {
    final dbClient = await _db.database;
    await dbClient.transaction((txn) async {
      await txn.delete('study_projects', where: 'id = ?', whereArgs: [projectId]);
      await txn.delete('root_study_projects', where: 'project_id = ?', whereArgs: [projectId]);
      await txn.delete('ayah_study_projects', where: 'project_id = ?', whereArgs: [projectId]);
      await txn.delete('concept_study_projects', where: 'project_id = ?', whereArgs: [projectId]);
      await txn.delete('study_project_ayahs', where: 'project_id = ?', whereArgs: [projectId]);
      await txn.delete('study_project_roots', where: 'project_id = ?', whereArgs: [projectId]);
    });
  }

  @override
  Future<int> addAyahLink({
    required int projectId,
    required int ayahId,
    String? note,
    String relationType = 'related',
  }) async {
    final dbClient = await _db.database;
    final linkId = await dbClient.insert('study_project_ayahs', {
      'project_id': projectId,
      'ayah_id': ayahId,
      'note': note,
      'relation_type': relationType,
    });

    await _db.update(
      table: 'study_projects',
      values: {'updated_at': DateTime.now().toIso8601String()},
      where: 'id = ?',
      whereArgs: [projectId],
    );

    return linkId;
  }

  @override
  Future<void> removeAyahLink(int linkId) async {
    final dbClient = await _db.database;
    await dbClient.delete('study_project_ayahs', where: 'id = ?', whereArgs: [linkId]);
  }

  @override
  Future<int> addRootLink({
    required int projectId,
    required String rootNormalized,
    String? note,
  }) async {
    final dbClient = await _db.database;
    final linkId = await dbClient.insert('study_project_roots', {
      'project_id': projectId,
      'root_normalized': rootNormalized.trim(),
      'note': note,
    });

    await _db.update(
      table: 'study_projects',
      values: {'updated_at': DateTime.now().toIso8601String()},
      where: 'id = ?',
      whereArgs: [projectId],
    );

    return linkId;
  }

  @override
  Future<void> removeRootLink(int linkId) async {
    final dbClient = await _db.database;
    await dbClient.delete('study_project_roots', where: 'id = ?', whereArgs: [linkId]);
  }

  @override
  Future<Map<String, int>> getProjectsStatistics() async {
    const sql = '''
      SELECT
        COUNT(*) as total,
        SUM(CASE WHEN status = 'draft' THEN 1 ELSE 0 END) as draft_count,
        SUM(CASE WHEN status = 'in_progress' THEN 1 ELSE 0 END) as in_progress_count,
        SUM(CASE WHEN status = 'completed' THEN 1 ELSE 0 END) as completed_count,
        SUM(CASE WHEN project_type = 'root' THEN 1 ELSE 0 END) as root_count,
        SUM(CASE WHEN project_type = 'ayah' THEN 1 ELSE 0 END) as ayah_count,
        SUM(CASE WHEN project_type = 'concept' THEN 1 ELSE 0 END) as concept_count
      FROM study_projects;
    ''';

    final rows = await _db.query(sql: sql);
    if (rows.isEmpty) {
      return {
        'total': 0,
        'draft': 0,
        'in_progress': 0,
        'completed': 0,
        'root': 0,
        'ayah': 0,
        'concept': 0,
      };
    }

    final row = rows.first;
    return {
      'total': (row['total'] as int?) ?? 0,
      'draft': (row['draft_count'] as int?) ?? 0,
      'in_progress': (row['in_progress_count'] as int?) ?? 0,
      'completed': (row['completed_count'] as int?) ?? 0,
      'root': (row['root_count'] as int?) ?? 0,
      'ayah': (row['ayah_count'] as int?) ?? 0,
      'concept': (row['concept_count'] as int?) ?? 0,
    };
  }
}
