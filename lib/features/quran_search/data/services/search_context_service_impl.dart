import 'package:quranapp/core/database/quran_database.dart';
import 'package:quranapp/features/quran_reader/domain/entities/ayah.dart';
import 'package:quranapp/features/quran_search/domain/entities/ayah_context_group.dart';
import 'package:quranapp/features/quran_search/domain/entities/ayah_search_result.dart';
import 'package:quranapp/features/quran_search/domain/services/ayah_range_merger.dart';
import 'package:quranapp/features/quran_search/domain/services/search_context_service.dart';

/// تطبيق خدمة جلب سياق الآيات القرآنية بالاعتماد على SQLite وخوارزمية دمج النطاقات.
class SearchContextServiceImpl implements SearchContextService {
  final QuranDatabase _db;
  final AyahRangeMerger _rangeMerger;

  SearchContextServiceImpl({
    QuranDatabase? database,
    AyahRangeMerger? rangeMerger,
  })  : _db = database ?? QuranDatabase.instance,
        _rangeMerger = rangeMerger ?? const AyahRangeMerger();

  @override
  Future<AyahContextGroup?> loadSingleAyahContext({
    required int surahId,
    required int ayahNumber,
    required int beforeCount,
    required int afterCount,
  }) async {
    // 1. جلب بيانات السورة (الاسم وإجمالي عدد الآيات للقص عند الحدود)
    final surahRows = await _db.query(
      sql: 'SELECT id, name_arabic, ayah_count FROM surahs WHERE id = ? LIMIT 1;',
      arguments: [surahId],
    );

    if (surahRows.isEmpty) return null;
    final surahName = surahRows.first['name_arabic'] as String;
    final totalAyahs = (surahRows.first['ayah_count'] as num).toInt();

    // 2. حساب النطاق بعد القص الآمن عند الآية 1 وآخر آية
    final range = _rangeMerger.calculateRange(
      surahId: surahId,
      ayahNumber: ayahNumber,
      surahAyahCount: totalAyahs,
      beforeCount: beforeCount,
      afterCount: afterCount,
    );

    // 3. جلب نصوص آيات النطاق دفعة واحدة
    final ayahRows = await _db.query(
      sql: '''
        SELECT id, surah_id, ayah_number, global_ayah_number,
               page_number, juz_number, hizb_number,
               text_uthmani, text_simple, text_normalized
        FROM ayahs
        WHERE surah_id = ?
          AND ayah_number BETWEEN ? AND ?
        ORDER BY ayah_number ASC;
      ''',
      arguments: [surahId, range.startAyah, range.endAyah],
    );

    final ayahs = ayahRows.map(Ayah.fromMap).toList();

    return AyahContextGroup(
      surahId: surahId,
      surahName: surahName,
      range: range,
      ayahs: ayahs,
      matchedAyahNumbers: range.targetAyahNumbers,
    );
  }

  @override
  Future<List<AyahContextGroup>> loadContext({
    required List<AyahSearchResult> results,
    required int beforeCount,
    required int afterCount,
  }) async {
    if (results.isEmpty) return const [];

    // 1. استخراج السور الفريدة وجلب بياناتها من قاعدة البيانات
    final surahIds = results.map((r) => r.surahId).toSet().toList();
    final placeholders = List.filled(surahIds.length, '?').join(',');

    final surahRows = await _db.query(
      sql: '''
        SELECT id, name_arabic, ayah_count
        FROM surahs
        WHERE id IN ($placeholders);
      ''',
      arguments: surahIds,
    );

    final surahAyahCounts = <int, int>{};
    final surahNames = <int, String>{};

    for (final row in surahRows) {
      final sId = (row['id'] as num).toInt();
      surahAyahCounts[sId] = (row['ayah_count'] as num).toInt();
      surahNames[sId] = row['name_arabic'] as String;
    }

    // 2. دمج النطاقات المتداخلة والمتجاورة داخل السور
    final mergedRanges = _rangeMerger.mergeSearchResults(
      results: results,
      surahAyahCounts: surahAyahCounts,
      beforeCount: beforeCount,
      afterCount: afterCount,
    );

    // 3. جلب الآيات لكل نطاق مدمج وتكوين مجموعات السياق
    final contextGroups = <AyahContextGroup>[];

    for (final range in mergedRanges) {
      final ayahRows = await _db.query(
        sql: '''
          SELECT id, surah_id, ayah_number, global_ayah_number,
                 page_number, juz_number, hizb_number,
                 text_uthmani, text_simple, text_normalized
          FROM ayahs
          WHERE surah_id = ?
            AND ayah_number BETWEEN ? AND ?
          ORDER BY ayah_number ASC;
        ''',
        arguments: [range.surahId, range.startAyah, range.endAyah],
      );

      final ayahs = ayahRows.map(Ayah.fromMap).toList();
      final surahName = surahNames[range.surahId] ?? 'سورة ${range.surahId}';

      contextGroups.add(
        AyahContextGroup(
          surahId: range.surahId,
          surahName: surahName,
          range: range,
          ayahs: ayahs,
          matchedAyahNumbers: range.targetAyahNumbers,
        ),
      );
    }

    return contextGroups;
  }
}
