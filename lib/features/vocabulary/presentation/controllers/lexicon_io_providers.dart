import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:quranapp/core/database/quran_database.dart';
import 'package:quranapp/core/text/arabic_normalizer.dart';
import 'package:quranapp/features/vocabulary/data/repositories/lexicon_io_repository_impl.dart';
import 'package:quranapp/features/vocabulary/domain/entities/lexicon_export_data.dart';
import 'package:quranapp/features/vocabulary/domain/repositories/lexicon_io_repository.dart';

/// موفر واجهة مستودع تصدير واستيراد تصحيحات المعجم
final lexiconIORepositoryProvider = Provider<LexiconIORepository>((ref) {
  return LexiconIORepositoryImpl(
    database: QuranDatabase.instance,
    normalizer: const ArabicNormalizerImpl(),
  );
});

/// حالة عملية الاستيراد أو التصدير للمعجم
class LexiconIOState {
  final bool isLoading;
  final String? errorMessage;
  final LexiconImportResult? importResult;
  final LexiconExportData? exportData;

  const LexiconIOState({
    this.isLoading = false,
    this.errorMessage,
    this.importResult,
    this.exportData,
  });

  LexiconIOState copyWith({
    bool? isLoading,
    String? errorMessage,
    bool clearError = false,
    LexiconImportResult? importResult,
    LexiconExportData? exportData,
  }) {
    return LexiconIOState(
      isLoading: isLoading ?? this.isLoading,
      errorMessage: clearError ? null : (errorMessage ?? this.errorMessage),
      importResult: importResult ?? this.importResult,
      exportData: exportData ?? this.exportData,
    );
  }
}

/// متحكم عمليات تصدير واستيراد المعجم والتصحيحات
class LexiconIONotifier extends Notifier<LexiconIOState> {
  @override
  LexiconIOState build() {
    return const LexiconIOState();
  }

  /// تصدير بيانات المعجم كنص JSON
  Future<String?> exportJson({bool customOnly = true}) async {
    state = state.copyWith(isLoading: true, clearError: true);
    try {
      final repo = ref.read(lexiconIORepositoryProvider);
      final jsonStr = await repo.exportLexiconJson(customOnly: customOnly);
      final data = await repo.exportLexiconData(customOnly: customOnly);
      state = state.copyWith(isLoading: false, exportData: data);
      return jsonStr;
    } catch (e) {
      state = state.copyWith(
        isLoading: false,
        errorMessage: 'حدث خطأ أثناء تصدير المعجم: $e',
      );
      return null;
    }
  }

  /// استيراد بيانات وتصحيحات المعجم من نص JSON
  Future<LexiconImportResult?> importJson(String jsonString) async {
    state = state.copyWith(isLoading: true, clearError: true);
    try {
      final repo = ref.read(lexiconIORepositoryProvider);
      final result = await repo.importLexiconJson(jsonString);
      state = state.copyWith(isLoading: false, importResult: result);
      return result;
    } catch (e) {
      state = state.copyWith(
        isLoading: false,
        errorMessage: 'فشل استيراد المعجم: $e',
      );
      return null;
    }
  }

  /// مسح نتائج الحالة الحالية
  void resetState() {
    state = const LexiconIOState();
  }
}

/// موفر حالة عمليات الاستيراد والتصدير للمعجم
final lexiconIONotifierProvider =
    NotifierProvider<LexiconIONotifier, LexiconIOState>(() {
  return LexiconIONotifier();
});
