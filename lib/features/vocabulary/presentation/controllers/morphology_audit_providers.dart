import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:quranapp/core/constants/ui_state.dart';
import 'package:quranapp/core/database/quran_database.dart';
import 'package:quranapp/core/text/arabic_normalizer.dart';
import 'package:quranapp/features/vocabulary/data/repositories/morphology_audit_repository_impl.dart';
import 'package:quranapp/features/vocabulary/domain/entities/morphology_audit_item.dart';
import 'package:quranapp/features/vocabulary/domain/entities/morphology_audit_stats.dart';
import 'package:quranapp/features/vocabulary/domain/repositories/morphology_audit_repository.dart';

/// موفر مستودع التدقيق الصرفي والمعجمي
final morphologyAuditRepositoryProvider = Provider<MorphologyAuditRepository>((ref) {
  return MorphologyAuditRepositoryImpl(
    database: QuranDatabase.instance,
    normalizer: const ArabicNormalizerImpl(),
  );
});

/// حالة شاشة التدقيق الصرفي والمعجمي الجماعي
class MorphologyAuditState {
  final UIState<List<MorphologyAuditItem>> uiState;
  final MorphologyAuditStats? stats;
  final Set<int> selectedWordIds;
  final bool withoutRootOnly;
  final String searchQuery;
  final int? selectedSurahId;
  final String? selectedSurahName;
  final int totalCount;
  final int page;
  final int pageSize;
  final bool hasMore;
  final bool isLoadingMore;

  const MorphologyAuditState({
    required this.uiState,
    this.stats,
    this.selectedWordIds = const {},
    this.withoutRootOnly = true,
    this.searchQuery = '',
    this.selectedSurahId,
    this.selectedSurahName,
    this.totalCount = 0,
    this.page = 0,
    this.pageSize = 40,
    this.hasMore = true,
    this.isLoadingMore = false,
  });

  factory MorphologyAuditState.initial() {
    return MorphologyAuditState(
      uiState: UIState.initial(),
    );
  }

  MorphologyAuditState copyWith({
    UIState<List<MorphologyAuditItem>>? uiState,
    MorphologyAuditStats? stats,
    Set<int>? selectedWordIds,
    bool? withoutRootOnly,
    String? searchQuery,
    int? selectedSurahId,
    String? selectedSurahName,
    bool clearSurah = false,
    int? totalCount,
    int? page,
    int? pageSize,
    bool? hasMore,
    bool? isLoadingMore,
  }) {
    return MorphologyAuditState(
      uiState: uiState ?? this.uiState,
      stats: stats ?? this.stats,
      selectedWordIds: selectedWordIds ?? this.selectedWordIds,
      withoutRootOnly: withoutRootOnly ?? this.withoutRootOnly,
      searchQuery: searchQuery ?? this.searchQuery,
      selectedSurahId: clearSurah ? null : (selectedSurahId ?? this.selectedSurahId),
      selectedSurahName: clearSurah ? null : (selectedSurahName ?? this.selectedSurahName),
      totalCount: totalCount ?? this.totalCount,
      page: page ?? this.page,
      pageSize: pageSize ?? this.pageSize,
      hasMore: hasMore ?? this.hasMore,
      isLoadingMore: isLoadingMore ?? this.isLoadingMore,
    );
  }
}

/// متحكم التدقيق الصرفي والمعجمي الجماعي
class MorphologyAuditNotifier extends Notifier<MorphologyAuditState> {
  @override
  MorphologyAuditState build() {
    Future.microtask(() {
      loadStats();
      loadItems(refresh: true);
    });
    return MorphologyAuditState.initial();
  }

  /// تحميل الإحصاءات العامة
  Future<void> loadStats() async {
    try {
      final repo = ref.read(morphologyAuditRepositoryProvider);
      final stats = await repo.getAuditStats();
      state = state.copyWith(stats: stats);
    } catch (_) {}
  }

  /// تحميل قائمة الكلمات للتدقيق
  Future<void> loadItems({bool refresh = false}) async {
    if (refresh) {
      state = state.copyWith(
        uiState: UIState.loading(),
        page: 0,
        selectedWordIds: {},
      );
    }

    try {
      final repo = ref.read(morphologyAuditRepositoryProvider);
      final count = await repo.getAuditItemsCount(
        withoutRootOnly: state.withoutRootOnly,
        query: state.searchQuery,
        surahId: state.selectedSurahId,
      );

      final items = await repo.getAuditItems(
        withoutRootOnly: state.withoutRootOnly,
        query: state.searchQuery,
        surahId: state.selectedSurahId,
        limit: state.pageSize,
        offset: 0,
      );

      state = state.copyWith(
        uiState: items.isEmpty ? UIState.empty() : UIState.success(items),
        totalCount: count,
        page: 0,
        hasMore: items.length < count,
        isLoadingMore: false,
      );
    } catch (e) {
      state = state.copyWith(
        uiState: UIState.error('فشل تحميل الكلمات: ${e.toString()}'),
      );
    }
  }

  /// تحميل المزيد من الصفحات
  Future<void> loadMore() async {
    if (!state.hasMore || state.isLoadingMore || state.uiState.isLoading) return;

    state = state.copyWith(isLoadingMore: true);

    try {
      final nextPage = state.page + 1;
      final repo = ref.read(morphologyAuditRepositoryProvider);

      final nextItems = await repo.getAuditItems(
        withoutRootOnly: state.withoutRootOnly,
        query: state.searchQuery,
        surahId: state.selectedSurahId,
        limit: state.pageSize,
        offset: nextPage * state.pageSize,
      );

      final current = state.uiState.data ?? [];
      final updatedList = [...current, ...nextItems];

      state = state.copyWith(
        uiState: UIState.success(updatedList),
        page: nextPage,
        hasMore: updatedList.length < state.totalCount,
        isLoadingMore: false,
      );
    } catch (_) {
      state = state.copyWith(isLoadingMore: false);
    }
  }

  /// تبديل تحديد كلمة معينة
  void toggleWordSelection(int wordId) {
    final current = Set<int>.from(state.selectedWordIds);
    if (current.contains(wordId)) {
      current.remove(wordId);
    } else {
      current.add(wordId);
    }
    state = state.copyWith(selectedWordIds: current);
  }

  /// تحديد جميع الكلمات الظاهرة في الصفحة
  void selectAll() {
    final items = state.uiState.data ?? [];
    final allIds = items.map((e) => e.wordId).toSet();
    state = state.copyWith(selectedWordIds: allIds);
  }

  /// إلغاء تحديد الكل
  void clearSelection() {
    state = state.copyWith(selectedWordIds: {});
  }

  /// تبديل نوع التدقيق
  void setWithoutRootOnly(bool val) {
    if (state.withoutRootOnly == val) return;
    state = state.copyWith(withoutRootOnly: val);
    loadItems(refresh: true);
  }

  /// البحث بنص الكلمة
  void search(String query) {
    state = state.copyWith(searchQuery: query);
    loadItems(refresh: true);
  }

  /// التصفية حسب السورة
  void filterBySurah(int? surahId, String? surahName) {
    state = state.copyWith(
      selectedSurahId: surahId,
      selectedSurahName: surahName,
      clearSurah: surahId == null,
    );
    loadItems(refresh: true);
  }

  /// تنفيذ الربط الجماعي للكلمات المحددة بجذر لغوي
  Future<int> batchRelink({
    required String newRoot,
    bool applyToAll = false,
  }) async {
    final selectedIds = state.selectedWordIds.toList();
    if (selectedIds.isEmpty) return 0;

    final repo = ref.read(morphologyAuditRepositoryProvider);
    final count = await repo.batchRelinkWords(
      wordIds: selectedIds,
      newRoot: newRoot,
      applyToAllOccurrences: applyToAll,
    );

    // تحديث البيانات والإحصاءات والقائمة
    await loadStats();
    await loadItems(refresh: true);
    return count;
  }
}

/// موفر حالة متحكم التدقيق الصرفي والمعجمي
final morphologyAuditNotifierProvider =
    NotifierProvider<MorphologyAuditNotifier, MorphologyAuditState>(() {
  return MorphologyAuditNotifier();
});
