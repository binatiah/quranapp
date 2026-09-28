import 'package:quranapp/core/database/quran_database.dart';
import 'package:quranapp/core/text/arabic_normalizer.dart';
import 'package:quranapp/features/quran_search/domain/entities/ayah_search_result.dart';
import 'package:quranapp/features/quran_search/domain/entities/quran_root.dart';
import 'package:quranapp/features/quran_search/domain/entities/quran_word.dart';
import 'package:quranapp/features/quran_search/domain/entities/root_candidate.dart';
import 'package:quranapp/features/quran_search/domain/entities/search_match_type.dart';
import 'package:quranapp/features/quran_search/domain/repositories/quran_search_repository.dart';

/// تطبيق مستودع البحث والدراسة القرآنية باستخدام SQLite ومطبع النصوص العربي.
class QuranSearchRepositoryImpl implements QuranSearchRepository {
  final QuranDatabase _db;
  final ArabicNormalizer _normalizer;

  QuranSearchRepositoryImpl({
    QuranDatabase? database,
    ArabicNormalizer? normalizer,
  })  : _db = database ?? QuranDatabase.instance,
        _normalizer = normalizer ?? const ArabicNormalizerImpl();

  @override
  Future<List<AyahSearchResult>> searchExactWord(String word, {int? surahId}) async {
    final cleanWord = word.trim();
    if (cleanWord.isEmpty) return const [];

    final buffer = StringBuffer('''
      SELECT DISTINCT
          a.id AS ayah_id,
          a.surah_id,
          a.ayah_number,
          a.global_ayah_number,
          a.text_uthmani,
          s.name_arabic AS surah_name,
          w.word_uthmani AS matched_word,
          w.root_normalized AS matched_root
      FROM ayahs AS a
      INNER JOIN surahs AS s ON s.id = a.surah_id
      INNER JOIN words AS w ON w.ayah_id = a.id
      WHERE w.word_uthmani = ?
    ''');

    final args = <Object?>[cleanWord];

    if (surahId != null) {
      buffer.write(' AND a.surah_id = ?');
      args.add(surahId);
    }

    buffer.write(' ORDER BY a.global_ayah_number ASC LIMIT 100;');

    final rows = await _db.query(sql: buffer.toString(), arguments: args);

    // تجميع الكلمات المطابقة لكل آية بدون تكرار
    final resultMap = <int, AyahSearchResult>{};
    for (final row in rows) {
      final ayahId = row['ayah_id'] as int;
      final matchedWord = (row['matched_word'] ?? cleanWord) as String;

      if (!resultMap.containsKey(ayahId)) {
        resultMap[ayahId] = AyahSearchResult(
          ayahId: ayahId,
          surahId: row['surah_id'] as int,
          surahName: row['surah_name'] as String,
          ayahNumber: row['ayah_number'] as int,
          globalAyahNumber: row['global_ayah_number'] as int,
          textUthmani: row['text_uthmani'] as String,
          matchedWords: [matchedWord],
          matchedRoot: row['matched_root'] as String?,
          matchType: SearchMatchType.exact,
        );
      } else {
        final existing = resultMap[ayahId]!;
        if (!existing.matchedWords.contains(matchedWord)) {
          resultMap[ayahId] = existing.copyWith(
            matchedWords: [...existing.matchedWords, matchedWord],
          );
        }
      }
    }

    return resultMap.values.toList();
  }

  @override
  Future<List<AyahSearchResult>> searchText(String query, {int? surahId}) async {
    final normalized = _normalizer.normalizeForSearch(query);
    if (normalized.isEmpty) return const [];

    final buffer = StringBuffer('''
      SELECT
          a.id AS ayah_id,
          a.surah_id,
          a.ayah_number,
          a.global_ayah_number,
          a.text_uthmani,
          s.name_arabic AS surah_name
      FROM ayahs AS a
      INNER JOIN surahs AS s ON s.id = a.surah_id
      WHERE a.text_normalized LIKE ?
    ''');

    final args = <Object?>['%$normalized%'];

    if (surahId != null) {
      buffer.write(' AND a.surah_id = ?');
      args.add(surahId);
    }

    buffer.write(' ORDER BY a.global_ayah_number ASC LIMIT 150;');

    final rows = await _db.query(sql: buffer.toString(), arguments: args);

    final results = <AyahSearchResult>[];
    for (final row in rows) {
      final ayahId = row['ayah_id'] as int;
      final textUthmani = row['text_uthmani'] as String;

      // استخراج الكلمات المطابقة من نص الآية الفعلي
      final tokens = textUthmani.split(' ');
      final matched = <String>[];
      for (final t in tokens) {
        if (_normalizer.normalizeForSearch(t).contains(normalized)) {
          matched.add(t);
        }
      }

      results.add(
        AyahSearchResult(
          ayahId: ayahId,
          surahId: row['surah_id'] as int,
          surahName: row['surah_name'] as String,
          ayahNumber: row['ayah_number'] as int,
          globalAyahNumber: row['global_ayah_number'] as int,
          textUthmani: textUthmani,
          matchedWords: matched.isNotEmpty ? matched : [query],
          matchType: SearchMatchType.normalized,
        ),
      );
    }

    return results;
  }

  @override
  Future<List<RootCandidate>> resolveRoots(String query) async {
    final normalized = _normalizer.normalizeForSearch(query);
    if (normalized.isEmpty) return const [];

    final candidates = <RootCandidate>[];
    final seenRoots = <String>{};

    // 1. البحث المباشر في root_normalized
    final directRoots = await _db.query(
      sql: 'SELECT root, root_normalized FROM roots WHERE root_normalized = ? LIMIT 5;',
      arguments: [normalized],
    );
    for (final r in directRoots) {
      final rootNorm = r['root_normalized'] as String;
      if (seenRoots.add(rootNorm)) {
        candidates.add(
          RootCandidate(
            root: rootNorm,
            confidence: 1.0,
            source: 'قاعدة بيانات الجذور الصرفية الموثقة',
            isVerified: true,
            matchType: SearchMatchType.verifiedRoot,
          ),
        );
      }
    }

    // 2. البحث في word_normalized و lemma_normalized
    final wordRoots = await _db.query(
      sql: '''
        SELECT DISTINCT root_normalized
        FROM words
        WHERE (word_normalized = ? OR lemma_normalized = ?)
          AND root_normalized IS NOT NULL
        LIMIT 5;
      ''',
      arguments: [normalized, normalized],
    );

    for (final wr in wordRoots) {
      final rootNorm = wr['root_normalized'] as String;
      if (seenRoots.add(rootNorm)) {
        candidates.add(
          RootCandidate(
            root: rootNorm,
            confidence: 0.95,
            source: 'معجم الكلمات الصرفي الموثق',
            isVerified: true,
            matchType: SearchMatchType.verifiedRoot,
          ),
        );
      }
    }

    return candidates;
  }

  @override
  Future<List<QuranWord>> getWordsByRoot(String root) async {
    final normalized = _normalizer.normalizeForSearch(root);
    if (normalized.isEmpty) return const [];

    const sql = '''
      SELECT
          id, ayah_id, surah_id, ayah_number, word_position,
          word_uthmani, word_simple, word_normalized,
          lemma, lemma_normalized, root, root_normalized,
          prefix, stem, suffix, part_of_speech, morphology
      FROM words
      WHERE root_normalized = ?
      ORDER BY surah_id ASC, ayah_number ASC, word_position ASC;
    ''';

    final rows = await _db.query(sql: sql, arguments: [normalized]);
    return rows.map(QuranWord.fromMap).toList();
  }

  @override
  Future<List<AyahSearchResult>> searchAyahsByRoot(String root, {int? surahId}) async {
    final normalized = _normalizer.normalizeForSearch(root);
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

    buffer.write('''
      GROUP BY
          a.id, a.surah_id, a.ayah_number, a.global_ayah_number,
          a.text_uthmani, s.name_arabic
      ORDER BY a.global_ayah_number ASC
      LIMIT 200;
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
  Future<QuranRoot?> getRootDetails(String root) async {
    final normalized = _normalizer.normalizeForSearch(root);
    if (normalized.isEmpty) return null;

    final rootRows = await _db.query(
      sql: '''
        SELECT
            r.id, r.root, r.root_normalized, r.description_ar,
            COUNT(DISTINCT w.id) AS occurrences_count,
            COUNT(DISTINCT w.word_normalized) AS words_count
        FROM roots AS r
        LEFT JOIN words AS w ON w.root_normalized = r.root_normalized
        WHERE r.root_normalized = ?
        GROUP BY r.id, r.root, r.root_normalized, r.description_ar
        LIMIT 1;
      ''',
      arguments: [normalized],
    );

    if (rootRows.isEmpty) return null;
    return QuranRoot.fromMap(rootRows.first);
  }
}
