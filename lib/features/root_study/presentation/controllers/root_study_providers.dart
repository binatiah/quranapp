import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:quranapp/core/database/quran_database.dart';
import 'package:quranapp/core/text/arabic_normalizer.dart';
import 'package:quranapp/core/constants/ui_state.dart';
import 'package:quranapp/features/root_study/data/repositories/root_study_repository_impl.dart';
import 'package:quranapp/features/root_study/domain/entities/root_study_data.dart';
import 'package:quranapp/features/root_study/domain/repositories/root_study_repository.dart';

/// مزود مستودع دراسة الجذور
final rootStudyRepositoryProvider = Provider<RootStudyRepository>((ref) {
  return RootStudyRepositoryImpl(
    database: QuranDatabase.instance,
    normalizer: const ArabicNormalizerImpl(),
  );
});

/// حالة شاشة دراسة الجذر القرآني
class RootStudyState {
  /// حالة واجهة المستخدم والبيانات المسترجعة
  final UIState<RootStudyData> uiState;

  /// الجذر قيد الدراسة
  final String root;

  /// مرشح السورة الحالية (إن وجد)
  final int? selectedSurahId;

  /// اسم السورة المختارة للترشيح (إن وجد)
  final String? selectedSurahName;

  /// مرشح الكلمة المشتقة المختارة (إن وجد)
  final String? selectedWordNormalized;

  /// النص العثماني للكلمة المختارة
  final String? selectedWordUthmani;

  const RootStudyState({
    required this.uiState,
    required this.root,
    this.selectedSurahId,
    this.selectedSurahName,
    this.selectedWordNormalized,
    this.selectedWordUthmani,
  });

  /// حالة أولية
  factory RootStudyState.initial(String root) {
    return RootStudyState(
      uiState: UIState.initial(),
      root: root,
    );
  }

  /// إنشاء نسخة جديدة مع تعديل الحقول
  RootStudyState copyWith({
    UIState<RootStudyData>? uiState,
    String? root,
    int? selectedSurahId,
    String? selectedSurahName,
    String? selectedWordNormalized,
    String? selectedWordUthmani,
    bool clearSurahFilter = false,
    bool clearWordFilter = false,
  }) {
    return RootStudyState(
      uiState: uiState ?? this.uiState,
      root: root ?? this.root,
      selectedSurahId: clearSurahFilter ? null : (selectedSurahId ?? this.selectedSurahId),
      selectedSurahName: clearSurahFilter ? null : (selectedSurahName ?? this.selectedSurahName),
      selectedWordNormalized:
          clearWordFilter ? null : (selectedWordNormalized ?? this.selectedWordNormalized),
      selectedWordUthmani: clearWordFilter ? null : (selectedWordUthmani ?? this.selectedWordUthmani),
    );
  }
}

/// متحكم حالة دراسة الجذر القرآني (RootStudyNotifier)
class RootStudyNotifier extends FamilyNotifier<RootStudyState, String> {
  @override
  RootStudyState build(String arg) {
    // جلب البيانات فور بناء المتحكم
    Future.microtask(() => loadRootData());
    return RootStudyState.initial(arg);
  }

  RootStudyRepository get _repository => ref.read(rootStudyRepositoryProvider);

  /// تحميل بيانات الجذر وتطبيق الفلاتر الحالية
  Future<void> loadRootData() async {
    state = state.copyWith(uiState: UIState.loading());
    try {
      final data = await _repository.getRootStudyData(
        state.root,
        surahId: state.selectedSurahId,
        wordNormalizedFilter: state.selectedWordNormalized,
      );

      if (data == null || data.totalOccurrences == 0) {
        state = state.copyWith(
          uiState: UIState.empty(),
        );
      } else {
        state = state.copyWith(
          uiState: UIState.success(data),
        );
      }
    } catch (e) {
      state = state.copyWith(
        uiState: UIState.error('تعذر جلب بيانات دراسة الجذر: ${e.toString()}'),
      );
    }
  }

  /// تصفية الآيات حسب كلمة مشتقة معينة
  void filterByWord({required String wordNormalized, required String wordUthmani}) {
    if (state.selectedWordNormalized == wordNormalized) {
      // إلغاء الفلتر إذا ضغط عليها ثانية
      state = state.copyWith(clearWordFilter: true);
    } else {
      state = state.copyWith(
        selectedWordNormalized: wordNormalized,
        selectedWordUthmani: wordUthmani,
      );
    }
    loadRootData();
  }

  /// تصفية الآيات حسب سورة معينة
  void filterBySurah({required int surahId, required String surahName}) {
    if (state.selectedSurahId == surahId) {
      // إلغاء الفلتر
      state = state.copyWith(clearSurahFilter: true);
    } else {
      state = state.copyWith(
        selectedSurahId: surahId,
        selectedSurahName: surahName,
      );
    }
    loadRootData();
  }

  /// مسح جميع الفلاتر المطبقة
  void clearFilters() {
    state = state.copyWith(
      clearSurahFilter: true,
      clearWordFilter: true,
    );
    loadRootData();
  }
}

/// موفر حالة دراسة الجذر بمعامل الجذر اللغوي
final rootStudyNotifierProvider =
    NotifierProvider.family<RootStudyNotifier, RootStudyState, String>(() {
  return RootStudyNotifier();
});
