import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/constants/ui_state.dart';
import '../../data/repositories/quran_repository_impl.dart';
import '../../domain/entities/ayah.dart';
import '../../domain/entities/reading_position.dart';
import '../../domain/entities/surah.dart';
import '../../domain/repositories/quran_repository.dart';

/// مزوّد مستودع القرآن الكريم (QuranRepository Provider)
final quranRepositoryProvider = Provider<QuranRepository>((ref) {
  return QuranRepositoryImpl();
});

/// مزوّد إدارة وتخزين حجم خط الآيات في المصحف
final fontSizeProvider = StateProvider<double>((ref) => 22.0);

/// حالة قائمة السور المفلترة والمعروضة للمستخدم
class SurahListState {
  final UIState<List<Surah>> uiState;
  final String searchQuery;

  const SurahListState({
    required this.uiState,
    this.searchQuery = '',
  });

  SurahListState copyWith({
    UIState<List<Surah>>? uiState,
    String? searchQuery,
  }) {
    return SurahListState(
      uiState: uiState ?? this.uiState,
      searchQuery: searchQuery ?? this.searchQuery,
    );
  }
}

/// متحكم قائمة السور وإدارة البحث الفوري والتصفية
class SurahListNotifier extends StateNotifier<SurahListState> {
  final QuranRepository _repository;
  List<Surah> _allSurahs = [];

  SurahListNotifier(this._repository)
      : super(SurahListState(uiState: UIState.initial())) {
    loadSurahs();
  }

  /// تحميل السور الـ 114 من قاعدة البيانات
  Future<void> loadSurahs() async {
    state = state.copyWith(uiState: UIState.loading());
    try {
      _allSurahs = await _repository.getSurahs();
      if (_allSurahs.isEmpty) {
        state = state.copyWith(uiState: UIState.empty());
      } else {
        state = state.copyWith(uiState: UIState.success(_allSurahs));
      }
    } catch (e) {
      state = state.copyWith(
        uiState: UIState.error('فشل في تحميل فهرس السور: $e'),
      );
    }
  }

  /// تصفية السور حسب نص البحث (الاسم العربي أو الإنجليزي أو رقم السورة)
  void search(String query) {
    final trimmed = query.trim().toLowerCase();
    if (trimmed.isEmpty) {
      state = SurahListState(
        uiState: UIState.success(_allSurahs),
        searchQuery: '',
      );
      return;
    }

    final filtered = _allSurahs.where((s) {
      final nameAr = s.nameArabic.toLowerCase();
      final nameEn = s.nameEnglish.toLowerCase();
      final idStr = s.id.toString();
      return nameAr.contains(trimmed) ||
          nameEn.contains(trimmed) ||
          idStr == trimmed;
    }).toList();

    state = SurahListState(
      uiState: filtered.isEmpty ? UIState.empty() : UIState.success(filtered),
      searchQuery: query,
    );
  }
}

/// مزوّد قائمة السور
final surahListNotifierProvider =
    StateNotifierProvider<SurahListNotifier, SurahListState>((ref) {
  final repo = ref.watch(quranRepositoryProvider);
  return SurahListNotifier(repo);
});

/// حالة عارض السورة والآيات
class ReaderState {
  final UIState<List<Ayah>> uiState;
  final Surah? surah;
  final int? targetAyahNumber;

  const ReaderState({
    required this.uiState,
    this.surah,
    this.targetAyahNumber,
  });

  ReaderState copyWith({
    UIState<List<Ayah>>? uiState,
    Surah? surah,
    int? targetAyahNumber,
  }) {
    return ReaderState(
      uiState: uiState ?? this.uiState,
      surah: surah ?? this.surah,
      targetAyahNumber: targetAyahNumber ?? this.targetAyahNumber,
    );
  }
}

/// متحكم عارض القرآن الكريم لسورة محددة
class ReaderNotifier extends StateNotifier<ReaderState> {
  final QuranRepository _repository;
  final int surahId;

  ReaderNotifier(this._repository, this.surahId)
      : super(ReaderState(uiState: UIState.initial())) {
    loadSurahDetails();
  }

  /// تحميل السورة وآياتها بالنص العثماني
  Future<void> loadSurahDetails() async {
    state = state.copyWith(uiState: UIState.loading());
    try {
      final surah = await _repository.getSurahById(surahId);
      final ayahs = await _repository.getSurahAyahs(surahId);

      if (ayahs.isEmpty) {
        state = state.copyWith(uiState: UIState.empty(), surah: surah);
      } else {
        state = state.copyWith(
          uiState: UIState.success(ayahs),
          surah: surah,
        );
      }
    } catch (e) {
      state = state.copyWith(
        uiState: UIState.error('تعذر جلب آيات السورة: $e'),
      );
    }
  }

  /// حفظ موضع القراءة الحالي عند آية معينة
  Future<void> saveCurrentPosition(int ayahNumber) async {
    try {
      await _repository.saveReadingPosition(
        surahId: surahId,
        ayahNumber: ayahNumber,
      );
    } catch (_) {}
  }
}

/// مزوّد عارض القرآن الكريم للسورة (مزوّد بمعامل surahId)
final readerNotifierProvider =
    StateNotifierProvider.family<ReaderNotifier, ReaderState, int>(
        (ref, surahId) {
  final repo = ref.watch(quranRepositoryProvider);
  return ReaderNotifier(repo, surahId);
});

/// متحكم إدارة آخر موضع قراءة
class ReadingPositionNotifier extends StateNotifier<UIState<ReadingPosition>> {
  final QuranRepository _repository;

  ReadingPositionNotifier(this._repository) : super(UIState.initial()) {
    loadLastPosition();
  }

  /// جلب آخر موضع قراءة محفوظ
  Future<void> loadLastPosition() async {
    state = UIState.loading();
    try {
      final position = await _repository.getLastReadingPosition();
      if (position == null) {
        state = UIState.empty();
      } else {
        state = UIState.success(position);
      }
    } catch (e) {
      state = UIState.error('تعذر تحميل موضع القراءة: $e');
    }
  }

  /// حفظ وتحديث موضع القراءة
  Future<void> updatePosition(int surahId, int ayahNumber) async {
    try {
      await _repository.saveReadingPosition(
        surahId: surahId,
        ayahNumber: ayahNumber,
      );
      await loadLastPosition();
    } catch (_) {}
  }
}

/// مزوّد آخر موضع قراءة
final readingPositionNotifierProvider =
    StateNotifierProvider<ReadingPositionNotifier, UIState<ReadingPosition>>((ref) {
  final repo = ref.watch(quranRepositoryProvider);
  return ReadingPositionNotifier(repo);
});
