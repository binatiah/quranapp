import 'package:quranapp/core/database/quran_database.dart';
import 'package:quranapp/core/text/arabic_normalizer.dart';
import 'package:quranapp/features/quran_search/domain/entities/ayah_search_result.dart';
import 'package:quranapp/features/quran_search/domain/entities/quran_root.dart';
import 'package:quranapp/features/quran_search/domain/entities/search_match_type.dart';
import 'package:quranapp/features/root_study/domain/entities/derived_word.dart';
import 'package:quranapp/features/root_study/domain/entities/root_study_data.dart';
import 'package:quranapp/features/root_study/domain/entities/surah_occurrence.dart';
import 'package:quranapp/features/root_study/domain/repositories/root_study_repository.dart';

/// تطبيق مستودع دراسة الجذور القرآنية المعتمد على استعلامات SQLite ذات الأداء العالي.
class RootStudyRepositoryImpl implements RootStudyRepository {
  final QuranDatabase _db;
  final ArabicNormalizer _normalizer;

  RootStudyRepositoryImpl({
    QuranDatabase? database,
    ArabicNormalizer? normalizer,
  })  : _db = database ?? QuranDatabase.instance,
        _normalizer = normalizer ?? const ArabicNormalizerImpl();

  @override
  Future<List<DerivedWord>> getDerivedWords(String root) async {
    final normalized = _normalizer.normalizeForRootSearch(root);
    if (normalized.isEmpty) return const [];

    const sql = '''
      SELECT
          word_normalized,
          MIN(word_uthmani) AS display_word,
          COUNT(*) AS occurrence_count
      FROM words
      WHERE root_normalized = ?
      GROUP BY word_normalized
      ORDER BY occurrence_count DESC, word_normalized ASC;
    ''';

    final rows = await _db.query(sql: sql, arguments: [normalized]);
    return rows.map(DerivedWord.fromMap).toList();
  }

  @override
  Future<List<SurahOccurrence>> getSurahOccurrences(String root) async {
    final normalized = _normalizer.normalizeForRootSearch(root);
    if (normalized.isEmpty) return const [];

    const sql = '''
      SELECT
          s.id AS surah_id,
          s.name_arabic AS surah_name,
          COUNT(w.id) AS occurrence_count
      FROM words AS w
      INNER JOIN surahs AS s ON s.id = w.surah_id
      WHERE w.root_normalized = ?
      GROUP BY s.id, s.name_arabic
      ORDER BY occurrence_count DESC, s.id ASC;
    ''';

    final rows = await _db.query(sql: sql, arguments: [normalized]);
    return rows.map(SurahOccurrence.fromMap).toList();
  }

  @override
  Future<List<AyahSearchResult>> getVersesForRoot(
    String root, {
    int? surahId,
    String? wordNormalizedFilter,
  }) async {
    final normalized = _normalizer.normalizeForRootSearch(root);
    if (normalized.isEmpty) return const [];

    final buffer = StringBuffer('''
      SELECT
          a.id AS ayah_id,
          a.surah_id,
          a.ayah_number,
          a.global_ayah_number,
          a.text_uthmani,
          s.name_arabic AS surah_name,
          GROUP_CONCAT(DISTINCT w.word_uthmani) AS matched_words
      FROM ayahs AS a
      INNER JOIN surahs AS s ON s.id = a.surah_id
      INNER JOIN words AS w ON w.ayah_id = a.id
      WHERE w.root_normalized = ?
    ''');

    final args = <Object?>[normalized];

    if (surahId != null) {
      buffer.write(' AND a.surah_id = ?');
      args.add(surahId);
    }

    if (wordNormalizedFilter != null && wordNormalizedFilter.isNotEmpty) {
      final cleanWordFilter = _normalizer.normalizeForSearch(wordNormalizedFilter);
      buffer.write(' AND w.word_normalized = ?');
      args.add(cleanWordFilter);
    }

    buffer.write('''
      GROUP BY
          a.id, a.surah_id, a.ayah_number, a.global_ayah_number,
          a.text_uthmani, s.name_arabic
      ORDER BY a.global_ayah_number ASC
      LIMIT 250;
    ''');

    final rows = await _db.query(sql: buffer.toString(), arguments: args);

    return rows.map((row) {
      final wordsRaw = (row['matched_words'] ?? '') as String;
      final matchedList = wordsRaw.split(',').map((w) => w.trim()).toList();

      return AyahSearchResult(
        ayahId: row['ayah_id'] as int,
        surahId: row['surah_id'] as int,
        surahName: row['surah_name'] as String,
        ayahNumber: row['ayah_number'] as int,
        globalAyahNumber: row['global_ayah_number'] as int,
        textUthmani: row['text_uthmani'] as String,
        matchedWords: matchedList,
        matchedRoot: normalized,
        matchType: SearchMatchType.verifiedRoot,
      );
    }).toList();
  }

  @override
  Future<RootStudyData?> getRootStudyData(
    String root, {
    int? surahId,
    String? wordNormalizedFilter,
  }) async {
    final normalized = _normalizer.normalizeForRootSearch(root);
    if (normalized.isEmpty) return null;

    // 1. جلب بيانات الجذر من جدول roots
    final rootRows = await _db.query(
      sql: '''
        SELECT id, root, root_normalized, description_ar
        FROM roots
        WHERE root_normalized = ?
        LIMIT 1;
      ''',
      arguments: [normalized],
    );

    final QuranRoot rootEntity;
    if (rootRows.isNotEmpty) {
      rootEntity = QuranRoot.fromMap(rootRows.first);
    } else {
      // إذا لم يكن موجوداً بجدول roots ننشئ كائناً افتراضياً
      rootEntity = QuranRoot(
        id: 0,
        root: normalized,
        rootNormalized: normalized,
        descriptionAr: 'جذر لغوي مستخرج من مفردات القرآن الكريم',
      );
    }

    // 2. جلب الكلمات المشتقة وتوزيع السور والآيات بالتوازي
    final derivedWords = await getDerivedWords(normalized);
    final surahOccurrences = await getSurahOccurrences(normalized);
    final verses = await getVersesForRoot(
      normalized,
      surahId: surahId,
      wordNormalizedFilter: wordNormalizedFilter,
    );

    final totalOccurrences = derivedWords.fold<int>(0, (sum, w) => sum + w.occurrenceCount);

    return RootStudyData(
      root: rootEntity.copyWith(
        occurrencesCount: totalOccurrences,
        wordsCount: derivedWords.length,
      ),
      derivedWords: derivedWords,
      surahOccurrences: surahOccurrences,
      verses: verses,
      totalOccurrences: totalOccurrences,
      uniqueWordsCount: derivedWords.length,
      surahsCount: surahOccurrences.length,
    );
  }
}
