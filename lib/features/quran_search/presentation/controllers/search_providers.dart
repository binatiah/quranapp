import 'dart:async';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:quranapp/core/constants/ui_state.dart';
import 'package:quranapp/features/quran_search/data/repositories/quran_search_repository_impl.dart';
import 'package:quranapp/features/quran_search/domain/entities/ayah_search_result.dart';
import 'package:quranapp/features/quran_search/domain/entities/root_candidate.dart';
import 'package:quranapp/features/quran_search/domain/repositories/quran_search_repository.dart';

/// مزوّد مستودع البحث القرآني
final quranSearchRepositoryProvider = Provider<QuranSearchRepository>((ref) {
  return QuranSearchRepositoryImpl();
});

/// حالة شاشة البحث والنتائج
class SearchState {
  final String query;
  final bool isRootSearch;
  final int? selectedSurahId;
  final UIState<List<AyahSearchResult>> uiState;
  final List<RootCandidate> rootCandidates;
  final String? selectedRoot;

  const SearchState({
    this.query = '',
    this.isRootSearch = false,
    this.selectedSurahId,
    required this.uiState,
    this.rootCandidates = const [],
    this.selectedRoot,
  });

  SearchState copyWith({
    String? query,
    bool? isRootSearch,
    int? selectedSurahId,
    bool clearSurahId = false,
    UIState<List<AyahSearchResult>>? uiState,
    List<RootCandidate>? rootCandidates,
    String? selectedRoot,
  }) {
    return SearchState(
      query: query ?? this.query,
      isRootSearch: isRootSearch ?? this.isRootSearch,
      selectedSurahId: clearSurahId ? null : (selectedSurahId ?? this.selectedSurahId),
      uiState: uiState ?? this.uiState,
      rootCandidates: rootCandidates ?? this.rootCandidates,
      selectedRoot: selectedRoot ?? this.selectedRoot,
    );
  }
}

/// متحكم عمليات البحث القرآني المباشر وبالجذر مع خاصية Debounce
class SearchNotifier extends StateNotifier<SearchState> {
  final QuranSearchRepository _repository;
  Timer? _debounceTimer;

  SearchNotifier(this._repository)
      : super(SearchState(uiState: UIState.initial()));

  @override
  void dispose() {
    _debounceTimer?.cancel();
    super.dispose();
  }

  /// إدخال نص البحث مع تفعيل Debounce لمنع الاستعلام عند كل حرف فوراً
  void onQueryChanged(String newQuery) {
    state = state.copyWith(query: newQuery);
    _debounceTimer?.cancel();

    if (newQuery.trim().isEmpty) {
      state = state.copyWith(
        uiState: UIState.initial(),
        rootCandidates: const [],
      );
      return;
    }

    // تأخير البحث بمقدار 350ms لضمان انتهاء المستخدم من كتابة الكلمة
    _debounceTimer = Timer(const Duration(milliseconds: 350), () {
      performSearch();
    });
  }

  /// التبديل بين البحث المباشر والبحث بالجذر
  void toggleRootSearch(bool isRoot) {
    state = state.copyWith(isRootSearch: isRoot);
    if (state.query.trim().isNotEmpty) {
      performSearch();
    }
  }

  /// تعيين سورة محددة لتصفية نتائج البحث داخلها
  void setSurahFilter(int? surahId) {
    if (surahId == null) {
      state = state.copyWith(clearSurahId: true);
    } else {
      state = state.copyWith(selectedSurahId: surahId);
    }
    if (state.query.trim().isNotEmpty) {
      performSearch();
    }
  }

  /// تنفيذ البحث الفعلي بحسب الوضع المحدد (مباشر أو بالجذر)
  Future<void> performSearch() async {
    final query = state.query.trim();
    if (query.isEmpty) return;

    _debounceTimer?.cancel();
    state = state.copyWith(uiState: UIState.loading());

    try {
      if (state.isRootSearch) {
        // 1. تحديد الجذور المحتملة أولاً
        final candidates = await _repository.resolveRoots(query);
        final targetRoot = candidates.isNotEmpty ? candidates.first.root : query;

        final results = await _repository.searchAyahsByRoot(
          targetRoot,
          surahId: state.selectedSurahId,
        );

        if (results.isEmpty) {
          state = state.copyWith(
            uiState: UIState.empty(),
            rootCandidates: candidates,
            selectedRoot: targetRoot,
          );
        } else {
          state = state.copyWith(
            uiState: UIState.success(results),
            rootCandidates: candidates,
            selectedRoot: targetRoot,
          );
        }
      } else {
        // 2. البحث النصي المباشر
        final results = await _repository.searchText(
          query,
          surahId: state.selectedSurahId,
        );

        if (results.isEmpty) {
          state = state.copyWith(uiState: UIState.empty());
        } else {
          state = state.copyWith(uiState: UIState.success(results));
        }
      }
    } catch (e) {
      state = state.copyWith(
        uiState: UIState.error('حدث خطأ أثناء إجراء البحث: $e'),
      );
    }
  }

  /// تغيير الجذر المختار يدويًا عند ظهور عدة جذور مقترحة
  Future<void> selectCandidateRoot(String root) async {
    state = state.copyWith(
      selectedRoot: root,
      uiState: UIState.loading(),
    );

    try {
      final results = await _repository.searchAyahsByRoot(
        root,
        surahId: state.selectedSurahId,
      );
      state = state.copyWith(
        uiState: results.isEmpty ? UIState.empty() : UIState.success(results),
      );
    } catch (e) {
      state = state.copyWith(
        uiState: UIState.error('تعذر جلب الآيات المرتبطة بهذا الجذر: $e'),
      );
    }
  }
}

/// مزوّد متحكم البحث الرئيسي
final searchNotifierProvider =
    StateNotifierProvider<SearchNotifier, SearchState>((ref) {
  final repo = ref.watch(quranSearchRepositoryProvider);
  return SearchNotifier(repo);
});
