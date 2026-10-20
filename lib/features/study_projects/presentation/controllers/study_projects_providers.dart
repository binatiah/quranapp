import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../domain/entities/study_project.dart';
import '../../domain/entities/study_project_full.dart';
import '../../domain/entities/root_study_details.dart';
import '../../domain/entities/ayah_study_details.dart';
import '../../domain/entities/concept_study_details.dart';
import '../../domain/repositories/study_projects_repository.dart';
import '../../domain/services/study_project_analyzer_service.dart';
import '../../data/repositories/study_projects_repository_impl.dart';

/// موفر مستودع مشاريع الدراسة القرآنية
final studyProjectsRepositoryProvider = Provider<StudyProjectsRepository>((ref) {
  return StudyProjectsRepositoryImpl();
});

/// موفر خدمة تحليل واستنتاج مشاريع الدراسة
final studyProjectAnalyzerServiceProvider = Provider<StudyProjectAnalyzerService>((ref) {
  return const StudyProjectAnalyzerService();
});

/// حالة تصفية وبحث قائمة المشاريع
class StudyProjectsFilterState {
  /// فلترة بنمط المشروع
  final StudyProjectType? typeFilter;

  /// فلترة بحالة المشروع
  final StudyProjectStatus? statusFilter;

  /// عبارة البحث
  final String searchQuery;

  /// المنشئ الثابت
  const StudyProjectsFilterState({
    this.typeFilter,
    this.statusFilter,
    this.searchQuery = '',
  });

  /// إنشاء نسخة معدلة
  StudyProjectsFilterState copyWith({
    StudyProjectType? typeFilter,
    bool clearTypeFilter = false,
    StudyProjectStatus? statusFilter,
    bool clearStatusFilter = false,
    String? searchQuery,
  }) {
    return StudyProjectsFilterState(
      typeFilter: clearTypeFilter ? null : (typeFilter ?? this.typeFilter),
      statusFilter: clearStatusFilter ? null : (statusFilter ?? this.statusFilter),
      searchQuery: searchQuery ?? this.searchQuery,
    );
  }
}

/// موفر حالة فلترة قائمة المشاريع
final studyProjectsFilterProvider = StateProvider<StudyProjectsFilterState>((ref) {
  return const StudyProjectsFilterState();
});

/// موفر إحصائيات مشاريع الدراسة العامة
final studyProjectsStatsProvider = FutureProvider<Map<String, int>>((ref) async {
  final repo = ref.watch(studyProjectsRepositoryProvider);
  return repo.getProjectsStatistics();
});

/// مدير حالة قائمة مشاريع الدراسة القرآنية
class StudyProjectsListNotifier extends StateNotifier<AsyncValue<List<StudyProject>>> {
  final StudyProjectsRepository _repository;
  final Ref _ref;

  /// المنشئ
  StudyProjectsListNotifier(this._repository, this._ref) : super(const AsyncValue.loading()) {
    loadProjects();
  }

  /// تحميل وتحديث قائمة المشاريع بحسب الفلاتر المحددة
  Future<void> loadProjects() async {
    state = const AsyncValue.loading();
    try {
      final filter = _ref.read(studyProjectsFilterProvider);
      final list = await _repository.getProjects(
        type: filter.typeFilter,
        status: filter.statusFilter,
        query: filter.searchQuery,
      );
      state = AsyncValue.data(list);
    } catch (e, st) {
      state = AsyncValue.error(e, st);
    }
  }

  /// إنشاء مشروع جديد وتحديث القائمة والإحصاءات
  Future<int> createProject(
    StudyProject project, {
    RootStudyDetails? rootDetails,
    AyahStudyDetails? ayahDetails,
    ConceptStudyDetails? conceptDetails,
  }) async {
    final id = await _repository.createProject(
      project,
      rootDetails: rootDetails,
      ayahDetails: ayahDetails,
      conceptDetails: conceptDetails,
    );
    await loadProjects();
    _ref.invalidate(studyProjectsStatsProvider);
    return id;
  }

  /// حذف مشروع وتحديث القائمة
  Future<void> deleteProject(int id) async {
    await _repository.deleteProject(id);
    await loadProjects();
    _ref.invalidate(studyProjectsStatsProvider);
  }
}

/// موفر قائمة مشاريع الدراسة
final studyProjectsListNotifierProvider =
    StateNotifierProvider<StudyProjectsListNotifier, AsyncValue<List<StudyProject>>>((ref) {
  final repo = ref.watch(studyProjectsRepositoryProvider);
  return StudyProjectsListNotifier(repo, ref);
});

/// مدير حالة تفاصيل المشروع الفردي الكامل
class StudyProjectDetailsNotifier extends StateNotifier<AsyncValue<StudyProjectFull>> {
  final StudyProjectsRepository _repository;
  final StudyProjectAnalyzerService _analyzer;
  final Ref _ref;
  final int projectId;

  /// المنشئ
  StudyProjectDetailsNotifier(
    this._repository,
    this._analyzer,
    this._ref,
    this.projectId,
  ) : super(const AsyncValue.loading()) {
    loadDetails();
  }

  /// تحميل التفاصيل الكاملة
  Future<void> loadDetails() async {
    state = const AsyncValue.loading();
    try {
      final projectFull = await _repository.getProjectById(projectId);
      if (projectFull == null) {
        state = AsyncValue.error('لم يتم العثور على المشروع المحدد', StackTrace.current);
      } else {
        state = AsyncValue.data(projectFull);
      }
    } catch (e, st) {
      state = AsyncValue.error(e, st);
    }
  }

  /// تحديث بيانات المشروع الأساسية
  Future<void> updateProject(StudyProject updatedProject) async {
    await _repository.updateProject(updatedProject);
    await recalculateAndSaveProgress();
    _ref.read(studyProjectsListNotifierProvider.notifier).loadProjects();
    _ref.invalidate(studyProjectsStatsProvider);
  }

  /// تحديث تفاصيل دراسة الجذر
  Future<void> updateRootDetails(RootStudyDetails details) async {
    await _repository.updateRootDetails(details);
    await recalculateAndSaveProgress();
    _ref.read(studyProjectsListNotifierProvider.notifier).loadProjects();
  }

  /// تحديث تفاصيل دراسة الآية
  Future<void> updateAyahDetails(AyahStudyDetails details) async {
    await _repository.updateAyahDetails(details);
    await recalculateAndSaveProgress();
    _ref.read(studyProjectsListNotifierProvider.notifier).loadProjects();
  }

  /// تحديث تفاصيل دراسة المفهوم
  Future<void> updateConceptDetails(ConceptStudyDetails details) async {
    await _repository.updateConceptDetails(details);
    await recalculateAndSaveProgress();
    _ref.read(studyProjectsListNotifierProvider.notifier).loadProjects();
  }

  /// إضافة رابط آية
  Future<void> addAyahLink(int ayahId, {String? note, String relationType = 'related'}) async {
    await _repository.addAyahLink(
      projectId: projectId,
      ayahId: ayahId,
      note: note,
      relationType: relationType,
    );
    await recalculateAndSaveProgress();
  }

  /// حذف رابط آية
  Future<void> removeAyahLink(int linkId) async {
    await _repository.removeAyahLink(linkId);
    await recalculateAndSaveProgress();
  }

  /// إضافة رابط جذر
  Future<void> addRootLink(String rootNormalized, {String? note}) async {
    await _repository.addRootLink(
      projectId: projectId,
      rootNormalized: rootNormalized,
      note: note,
    );
    await recalculateAndSaveProgress();
  }

  /// حذف رابط جذر
  Future<void> removeRootLink(int linkId) async {
    await _repository.removeRootLink(linkId);
    await recalculateAndSaveProgress();
  }

  /// إعادة احتساب نسبة التقدم وحفظها وتحديث الواجهة
  Future<void> recalculateAndSaveProgress() async {
    final currentFull = await _repository.getProjectById(projectId);
    if (currentFull != null) {
      final progress = _analyzer.calculateProgress(currentFull);
      final updatedProject = currentFull.project.copyWith(
        progress: progress,
        status: progress >= 0.95
            ? StudyProjectStatus.completed
            : (progress > 0.1 ? StudyProjectStatus.inProgress : StudyProjectStatus.draft),
      );
      await _repository.updateProject(updatedProject);
      state = AsyncValue.data(currentFull.copyWith(project: updatedProject));
    }
  }

  /// تصدير التقرير كـ Markdown
  String exportMarkdown() {
    final current = state.value;
    if (current == null) return '';
    return _analyzer.exportToMarkdown(current);
  }

  /// تصدير التقرير كـ JSON
  String exportJson() {
    final current = state.value;
    if (current == null) return '';
    return _analyzer.exportToJson(current);
  }
}

/// موفر تفاصيل المشروع الفردي
final studyProjectDetailsNotifierProvider = StateNotifierProvider.family<
    StudyProjectDetailsNotifier, AsyncValue<StudyProjectFull>, int>((ref, projectId) {
  final repo = ref.watch(studyProjectsRepositoryProvider);
  final analyzer = ref.watch(studyProjectAnalyzerServiceProvider);
  return StudyProjectDetailsNotifier(repo, analyzer, ref, projectId);
});
