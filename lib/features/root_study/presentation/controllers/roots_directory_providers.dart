import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:quranapp/core/constants/ui_state.dart';
import 'package:quranapp/core/database/quran_database.dart';
import 'package:quranapp/core/text/arabic_normalizer.dart';
import 'package:quranapp/features/quran_search/domain/entities/quran_root.dart';
import 'package:quranapp/features/root_study/data/repositories/root_management_repository_impl.dart';
import 'package:quranapp/features/root_study/domain/repositories/root_management_repository.dart';

/// مزود مستودع إدارة الجذور القرآنية
final rootManagementRepositoryProvider = Provider<RootManagementRepository>((ref) {
  return RootManagementRepositoryImpl(
    database: QuranDatabase.instance,
    normalizer: const ArabicNormalizerImpl(),
  );
});

/// حالة شاشة دليل واستعراض الجذور القرآنية
class RootsDirectoryState {
  /// حالة واجهة المستخدم وقائمة الجذور المحملة
  final UIState<List<QuranRoot>> uiState;

  /// عبارة البحث الحالية
  final String query;

  /// معيار الفرز الحالي
  final RootSortBy sortBy;

  /// إجمالي عدد الجذور المطابقة
  final int totalCount;

  /// الصفحة الحالية للتحميل التراكمي
  final int page;

  /// حجم الصفحة الواحدة
  final int pageSize;

  /// هل تتوفر مزيد من السجلات
  final bool hasMore;

  /// هل يجري تحميل صفحة إضافية في الخلفية
  final bool isLoadingMore;

  const RootsDirectoryState({
    required this.uiState,
    this.query = '',
    this.sortBy = RootSortBy.occurrencesDesc,
    this.totalCount = 0,
    this.page = 0,
    this.pageSize = 40,
    this.hasMore = true,
    this.isLoadingMore = false,
  });

  /// إنشاء حالة أولية
  factory RootsDirectoryState.initial() {
    return RootsDirectoryState(
      uiState: UIState.initial(),
    );
  }

  /// إنشاء نسخة جديدة مع تعديل بعض الخصائص
  RootsDirectoryState copyWith({
    UIState<List<QuranRoot>>? uiState,
    String? query,
    RootSortBy? sortBy,
    int? totalCount,
    int? page,
    int? pageSize,
    bool? hasMore,
    bool? isLoadingMore,
  }) {
    return RootsDirectoryState(
      uiState: uiState ?? this.uiState,
      query: query ?? this.query,
      sortBy: sortBy ?? this.sortBy,
      totalCount: totalCount ?? this.totalCount,
      page: page ?? this.page,
      pageSize: pageSize ?? this.pageSize,
      hasMore: hasMore ?? this.hasMore,
      isLoadingMore: isLoadingMore ?? this.isLoadingMore,
    );
  }
}

/// متحكم حالة دليل واستعراض الجذور القرآنية (RootsDirectoryNotifier).
class RootsDirectoryNotifier extends Notifier<RootsDirectoryState> {
  @override
  RootsDirectoryState build() {
    // بدء جلب الجذور تلقائياً عند أول إنشاء
    Future.microtask(() => loadRoots(refresh: true));
    return RootsDirectoryState.initial();
  }

  RootManagementRepository get _repository => ref.read(rootManagementRepositoryProvider);

  /// تحميل الجذور (مع خيار التحديث الكامل)
  Future<void> loadRoots({bool refresh = false}) async {
    final nextPage = refresh ? 0 : state.page;

    if (refresh) {
      state = state.copyWith(
        uiState: UIState.loading(),
        page: 0,
        hasMore: true,
      );
    }

    try {
      final total = await _repository.getRootsCount(
        query: state.query,
        sortBy: state.sortBy,
      );

      final roots = await _repository.getRoots(
        query: state.query,
        sortBy: state.sortBy,
        limit: state.pageSize,
        offset: nextPage * state.pageSize,
      );

      if (roots.isEmpty && refresh) {
        state = state.copyWith(
          uiState: UIState.empty(),
          totalCount: total,
          hasMore: false,
        );
      } else {
        final currentList = refresh ? <QuranRoot>[] : (state.uiState.data ?? <QuranRoot>[]);
        final combined = [...currentList, ...roots];

        state = state.copyWith(
          uiState: UIState.success(combined),
          totalCount: total,
          page: nextPage + 1,
          hasMore: combined.length < total,
          isLoadingMore: false,
        );
      }
    } catch (e) {
      state = state.copyWith(
        uiState: UIState.error('تعذر تحميل قائمة الجذور: ${e.toString()}'),
        isLoadingMore: false,
      );
    }
  }

  /// تحميل الصفحة التالية (Infinite Scrolling)
  Future<void> loadMore() async {
    if (state.isLoadingMore || !state.hasMore || state.uiState.isLoading) return;

    state = state.copyWith(isLoadingMore: true);

    try {
      final roots = await _repository.getRoots(
        query: state.query,
        sortBy: state.sortBy,
        limit: state.pageSize,
        offset: state.page * state.pageSize,
      );

      final currentList = state.uiState.data ?? <QuranRoot>[];
      final combined = [...currentList, ...roots];

      state = state.copyWith(
        uiState: UIState.success(combined),
        page: state.page + 1,
        hasMore: combined.length < state.totalCount,
        isLoadingMore: false,
      );
    } catch (e) {
      state = state.copyWith(isLoadingMore: false);
    }
  }

  /// البحث الفوري في الجذور
  void search(String newQuery) {
    if (state.query == newQuery) return;
    state = state.copyWith(query: newQuery);
    loadRoots(refresh: true);
  }

  /// تغيير طريقة الترتيب والفرز
  void setSortBy(RootSortBy sort) {
    if (state.sortBy == sort) return;
    state = state.copyWith(sortBy: sort);
    loadRoots(refresh: true);
  }

  /// إضافة جذر جديد إلى قاعدة البيانات
  Future<bool> addRoot({required String root, String? descriptionAr}) async {
    try {
      await _repository.addRoot(root: root, descriptionAr: descriptionAr);
      await loadRoots(refresh: true);
      return true;
    } catch (e) {
      rethrow;
    }
  }

  /// تعديل بيانات جذر موجود مسبقاً
  Future<bool> updateRoot({
    required int id,
    required String root,
    String? descriptionAr,
  }) async {
    try {
      await _repository.updateRoot(
        id: id,
        root: root,
        descriptionAr: descriptionAr,
      );
      await loadRoots(refresh: true);
      return true;
    } catch (e) {
      rethrow;
    }
  }

  /// حذف جذر من قاعدة البيانات
  Future<bool> deleteRoot(int id) async {
    try {
      final success = await _repository.deleteRoot(id);
      if (success) {
        await loadRoots(refresh: true);
      }
      return success;
    } catch (e) {
      rethrow;
    }
  }
}

/// موفر حالة دليل الجذور القرآنية
final rootsDirectoryNotifierProvider =
    NotifierProvider<RootsDirectoryNotifier, RootsDirectoryState>(() {
  return RootsDirectoryNotifier();
});
