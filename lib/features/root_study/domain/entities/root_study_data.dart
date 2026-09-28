import 'package:equatable/equatable.dart';
import 'package:quranapp/features/quran_search/domain/entities/ayah_search_result.dart';
import 'package:quranapp/features/quran_search/domain/entities/quran_root.dart';
import 'derived_word.dart';
import 'surah_occurrence.dart';

/// يحتوي على كافة البيانات والإحصائيات الشاملة لدراسة الجذر القرآني وفق متطلبات TRD.
class RootStudyData extends Equatable {
  /// بيانات الجذر الصرفي ومعناه
  final QuranRoot root;

  /// قائمة بجميع الكلمات القرآنية المشتقة من الجذر مع تكرار كل كلمة
  final List<DerivedWord> derivedWords;

  /// إحصاءات توزيع الجذر على السور القرآنية
  final List<SurahOccurrence> surahOccurrences;

  /// قائمة الآيات القرآنية التي وردت فيها كلمات الجذر
  final List<AyahSearchResult> verses;

  /// إجمالي عدد مرات الورود في القرآن الكريم
  final int totalOccurrences;

  /// عدد الكلمات المشتقة المختلفة
  final int uniqueWordsCount;

  /// عدد السور التي ورد فيها الجذر
  final int surahsCount;

  /// المنشئ الثابت لكائن دراسة الجذر
  const RootStudyData({
    required this.root,
    required this.derivedWords,
    required this.surahOccurrences,
    required this.verses,
    required this.totalOccurrences,
    required this.uniqueWordsCount,
    required this.surahsCount,
  });

  /// إنشاء نسخة معدلة
  RootStudyData copyWith({
    QuranRoot? root,
    List<DerivedWord>? derivedWords,
    List<SurahOccurrence>? surahOccurrences,
    List<AyahSearchResult>? verses,
    int? totalOccurrences,
    int? uniqueWordsCount,
    int? surahsCount,
  }) {
    return RootStudyData(
      root: root ?? this.root,
      derivedWords: derivedWords ?? this.derivedWords,
      surahOccurrences: surahOccurrences ?? this.surahOccurrences,
      verses: verses ?? this.verses,
      totalOccurrences: totalOccurrences ?? this.totalOccurrences,
      uniqueWordsCount: uniqueWordsCount ?? this.uniqueWordsCount,
      surahsCount: surahsCount ?? this.surahsCount,
    );
  }

  @override
  List<Object?> get props => [
        root,
        derivedWords,
        surahOccurrences,
        verses,
        totalOccurrences,
        uniqueWordsCount,
        surahsCount,
      ];
}
