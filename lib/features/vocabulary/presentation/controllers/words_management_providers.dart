import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:quranapp/core/constants/ui_state.dart';
import 'package:quranapp/core/database/quran_database.dart';
import 'package:quranapp/core/text/arabic_normalizer.dart';
import 'package:quranapp/features/quran_search/domain/entities/quran_word.dart';
import 'package:quranapp/features/vocabulary/data/repositories/word_management_repository_impl.dart';
import 'package:quranapp/features/vocabulary/domain/entities/word_filter_criteria.dart';
import 'package:quranapp/features/vocabulary/domain/repositories/word_management_repository.dart';

/// مزود مستودع إدارة الكلمات القرآنية
final wordManagementRepositoryProvider = Provider<WordManagementRepository>((ref) {
  return WordManagementRepositoryImpl(
    database: QuranDatabase.instance,
    normalizer: const ArabicNormalizerImpl(),
  );
});

/// حالة شاشة معجم وإدارة الكلمات القرآنية
class WordsManagementState {
  /// حالة واجهة المستخدم وقائمة الكلمات المعروضة
  final UIState<List<QuranWord>> uiState;

  /// معايير الفرز والتصفية الحالية
  final WordFilterCriteria criteria;

  /// إجمالي عدد الكلمات المطابقة
  final int totalCount;

  /// الصفحة الحالية للتحميل
  final int page;

  /// حجم الصفحة الواحدة
  final int pageSize;

  /// هل تتوفر مزيد من الكلمات في الصفحات التالية
  final bool hasMore;

  /// هل يجري تحميل صفحة إضافية
  final bool isLoadingMore;

  /// اسم السورة المختارة (للعرض في الواجهة)
  final String? selectedSurahName;

  const WordsManagementState({
    required this.uiState,
    this.criteria = const WordFilterCriteria(),
    this.totalCount = 0,
    this.page = 0,
    this.pageSize = 40,
    this.hasMore = true,
    this.isLoadingMore = false,
    this.selectedSurahName,
  });

  /// إنشاء حالة أولية
  factory WordsManagementState.initial({String? initialRoot}) {
    return WordsManagementState(
      uiState: UIState.initial(),
      criteria: WordFilterCriteria(
        rootStatus: initialRoot != null ? WordRootStatus.specificRoot : WordRootStatus.all,
        specificRoot: initialRoot,
      ),
    );
  }

  /// إنشاء نسخة جديدة مع تعديل الحقول
  WordsManagementState copyWith({
    UIState<List<QuranWord>>? uiState,
    WordFilterCriteria? criteria,
    int? totalCount,
    int? page,
    int? pageSize,
    bool? hasMore,
    bool? isLoadingMore,
    String? selectedSurahName,
    bool clearSurahName = false,
  }) {
    return WordsManagementState(
      uiState: uiState ?? this.uiState,
      criteria: criteria ?? this.criteria,
      totalCount: totalCount ?? this.totalCount,
      page: page ?? this.page,
      pageSize: pageSize ?? this.pageSize,
      hasMore: hasMore ?? this.hasMore,
      isLoadingMore: isLoadingMore ?? this.isLoadingMore,
      selectedSurahName: clearSurahName ? null : (selectedSurahName ?? this.selectedSurahName),
    );
  }
}

/// متحكم حالة معجم واستعراض الكلمات القرآنية (WordsManagementNotifier).
class WordsManagementNotifier extends FamilyNotifier<WordsManagementState, String?> {
  @override
  WordsManagementState build(String? initialRoot) {
    Future.microtask(() => loadWords(refresh: true));
    return WordsManagementState.initial(initialRoot: initialRoot);
  }

  WordManagementRepository get _repository => ref.read(wordManagementRepositoryProvider);

  /// تحميل الكلمات وفق المعايير الراهنة
  Future<void> loadWords({bool refresh = false}) async {
    final nextPage = refresh ? 0 : state.page;

    if (refresh) {
      state = state.copyWith(
        uiState: UIState.loading(),
        page: 0,
        hasMore: true,
      );
    }

    try {
      final total = await _repository.getWordsCount(criteria: state.criteria);

      final words = await _repository.getWords(
        criteria: state.criteria,
        limit: state.pageSize,
        offset: nextPage * state.pageSize,
      );

      if (words.isEmpty && refresh) {
        state = state.copyWith(
          uiState: UIState.empty(),
          totalCount: total,
          hasMore: false,
        );
      } else {
        final currentList = refresh ? <QuranWord>[] : (state.uiState.data ?? <QuranWord>[]);
        final combined = [...currentList, ...words];

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
        uiState: UIState.error('تعذر جلب كلمات القرآن: ${e.toString()}'),
        isLoadingMore: false,
      );
    }
  }

  /// تحميل دفعة إضافية من الكلمات
  Future<void> loadMore() async {
    if (state.isLoadingMore || !state.hasMore || state.uiState.isLoading) return;

    state = state.copyWith(isLoadingMore: true);

    try {
      final words = await _repository.getWords(
        criteria: state.criteria,
        limit: state.pageSize,
        offset: state.page * state.pageSize,
      );

      final currentList = state.uiState.data ?? <QuranWord>[];
      final combined = [...currentList, ...words];

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

  /// البحث النصي في الكلمات
  void search(String query) {
    if (state.criteria.query == query) return;
    state = state.copyWith(
      criteria: state.criteria.copyWith(
        query: query,
        clearQuery: query.trim().isEmpty,
      ),
    );
    loadWords(refresh: true);
  }

  /// التصفية حسب السورة
  void filterBySurah(int? surahId, String? surahName) {
    if (state.criteria.surahId == surahId) {
      // إلغاء الفلتر
      state = state.copyWith(
        criteria: state.criteria.copyWith(clearSurahId: true),
        clearSurahName: true,
      );
    } else {
      state = state.copyWith(
        criteria: state.criteria.copyWith(surahId: surahId),
        selectedSurahName: surahName,
      );
    }
    loadWords(refresh: true);
  }

  /// التصفية حسب حالة الجذر (الكل / مع جذر / بدون جذر / جذر محدد)
  void filterByRootStatus(WordRootStatus status, {String? specificRoot}) {
    state = state.copyWith(
      criteria: state.criteria.copyWith(
        rootStatus: status,
        specificRoot: specificRoot,
        clearSpecificRoot: specificRoot == null || specificRoot.isEmpty,
      ),
    );
    loadWords(refresh: true);
  }

  /// إعادة ربط الكلمة بجذر جديد
  Future<int> relinkWord({
    required int wordId,
    required String newRoot,
    bool applyToAll = false,
  }) async {
    try {
      final updatedCount = await _repository.relinkWordToRoot(
        wordId: wordId,
        newRoot: newRoot,
        applyToAllOccurrences: applyToAll,
      );
      await loadWords(refresh: true);
      return updatedCount;
    } catch (e) {
      rethrow;
    }
  }

  /// فك ارتباط الكلمة بالجذر
  Future<int> unlinkWord({
    required int wordId,
    bool applyToAll = false,
  }) async {
    try {
      final affected = await _repository.unlinkWordFromRoot(
        wordId: wordId,
        applyToAllOccurrences: applyToAll,
      );
      await loadWords(refresh: true);
      return affected;
    } catch (e) {
      rethrow;
    }
  }

  /// تعديل بيانات الكلمة
  Future<void> updateWordDetails({
    required int wordId,
    required String wordUthmani,
    String? lemma,
    String? prefix,
    String? stem,
    String? suffix,
    String? partOfSpeech,
    String? morphology,
  }) async {
    try {
      await _repository.updateWordDetails(
        wordId: wordId,
        wordUthmani: wordUthmani,
        lemma: lemma,
        prefix: prefix,
        stem: stem,
        suffix: suffix,
        partOfSpeech: partOfSpeech,
        morphology: morphology,
      );
      await loadWords(refresh: true);
    } catch (e) {
      rethrow;
    }
  }
}

/// موفر حالة معجم الكلمات بمعامل اختياري للجذر الابتدائي
final wordsManagementNotifierProvider = NotifierProvider.family<
    WordsManagementNotifier,
    WordsManagementState,
    String?>(() {
  return WordsManagementNotifier();
});
