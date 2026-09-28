import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:quranapp/core/constants/ui_state.dart';
import 'package:quranapp/core/database/quran_database.dart';
import 'package:quranapp/features/quran_search/data/services/search_context_service_impl.dart';
import 'package:quranapp/features/quran_search/domain/entities/ayah_context_group.dart';
import 'package:quranapp/features/quran_search/domain/entities/ayah_search_result.dart';
import 'package:quranapp/features/quran_search/domain/services/ayah_range_merger.dart';
import 'package:quranapp/features/quran_search/domain/services/search_context_service.dart';

/// موفر خدمة سياق الآيات القرآنية
final searchContextServiceProvider = Provider<SearchContextService>((ref) {
  return SearchContextServiceImpl(
    database: QuranDatabase.instance,
    rangeMerger: const AyahRangeMerger(),
  );
});

/// حالة شاشة سياق الآيات
class AyahContextState {
  /// عدد الآيات السابقة
  final int beforeCount;

  /// عدد الآيات اللاحقة
  final int afterCount;

  /// حالة واجهة المستخدم ومجموعات الآيات المجلوبة
  final UIState<List<AyahContextGroup>> uiState;

  /// رقم السورة المحددة (في حال فتح سياق آية مفردة)
  final int? surahId;

  /// رقم الآية المحددة (في حال فتح سياق آية مفردة)
  final int? ayahNumber;

  /// نتائج البحث الأصلية الممررة (إن وُجدت)
  final List<AyahSearchResult> searchResults;

  const AyahContextState({
    required this.beforeCount,
    required this.afterCount,
    required this.uiState,
    this.surahId,
    this.ayahNumber,
    this.searchResults = const [],
  });

  /// إنشاء نسخة معدلة من الحالة
  AyahContextState copyWith({
    int? beforeCount,
    int? afterCount,
    UIState<List<AyahContextGroup>>? uiState,
    int? surahId,
    int? ayahNumber,
    List<AyahSearchResult>? searchResults,
  }) {
    return AyahContextState(
      beforeCount: beforeCount ?? this.beforeCount,
      afterCount: afterCount ?? this.afterCount,
      uiState: uiState ?? this.uiState,
      surahId: surahId ?? this.surahId,
      ayahNumber: ayahNumber ?? this.ayahNumber,
      searchResults: searchResults ?? this.searchResults,
    );
  }
}

/// متحكم حالة سياق الآيات ودمج النطاقات (AyahContextNotifier)
class AyahContextNotifier extends Notifier<AyahContextState> {
  @override
  AyahContextState build() {
    return AyahContextState(
      beforeCount: 2,
      afterCount: 2,
      uiState: UIState.initial(),
    );
  }

  SearchContextService get _service => ref.read(searchContextServiceProvider);

  /// تحميل سياق آية محددة
  Future<void> loadForAyah({
    required int surahId,
    required int ayahNumber,
    int? before,
    int? after,
  }) async {
    final b = before ?? state.beforeCount;
    final a = after ?? state.afterCount;

    state = state.copyWith(
      surahId: surahId,
      ayahNumber: ayahNumber,
      beforeCount: b,
      afterCount: a,
      uiState: UIState.loading(),
    );

    try {
      final group = await _service.loadSingleAyahContext(
        surahId: surahId,
        ayahNumber: ayahNumber,
        beforeCount: b,
        afterCount: a,
      );

      if (group == null || group.ayahs.isEmpty) {
        state = state.copyWith(uiState: UIState.empty());
      } else {
        state = state.copyWith(uiState: UIState.success([group]));
      }
    } catch (e) {
      state = state.copyWith(
        uiState: UIState.error('تعذر تحميل سياق الآية: ${e.toString()}'),
      );
    }
  }

  /// تحميل سياق مجموعة نتائج بحث مع دمج النطاقات المتداخلة
  Future<void> loadForResults({
    required List<AyahSearchResult> results,
    int? before,
    int? after,
  }) async {
    final b = before ?? state.beforeCount;
    final a = after ?? state.afterCount;

    state = state.copyWith(
      searchResults: results,
      beforeCount: b,
      afterCount: a,
      uiState: UIState.loading(),
    );

    if (results.isEmpty) {
      state = state.copyWith(uiState: UIState.empty());
      return;
    }

    try {
      final groups = await _service.loadContext(
        results: results,
        beforeCount: b,
        afterCount: a,
      );

      if (groups.isEmpty) {
        state = state.copyWith(uiState: UIState.empty());
      } else {
        state = state.copyWith(uiState: UIState.success(groups));
      }
    } catch (e) {
      state = state.copyWith(
        uiState: UIState.error('تعذر تجميع سياقات الآيات: ${e.toString()}'),
      );
    }
  }

  /// تحديث قيم الآيات السابقة واللاحقة وإعادة التحميل فوراً
  Future<void> updateCounts({required int before, required int after}) async {
    final clampedBefore = before.clamp(0, 20);
    final clampedAfter = after.clamp(0, 20);

    state = state.copyWith(
      beforeCount: clampedBefore,
      afterCount: clampedAfter,
    );

    if (state.surahId != null && state.ayahNumber != null) {
      await loadForAyah(
        surahId: state.surahId!,
        ayahNumber: state.ayahNumber!,
        before: clampedBefore,
        after: clampedAfter,
      );
    } else if (state.searchResults.isNotEmpty) {
      await loadForResults(
        results: state.searchResults,
        before: clampedBefore,
        after: clampedAfter,
      );
    }
  }
}

/// موفر حالة سياق الآيات
final ayahContextNotifierProvider =
    NotifierProvider<AyahContextNotifier, AyahContextState>(() {
  return AyahContextNotifier();
});
