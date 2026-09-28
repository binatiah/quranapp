import 'package:quranapp/core/database/quran_database.dart';
import 'package:quranapp/core/text/arabic_normalizer.dart';
import 'package:quranapp/features/quran_search/domain/entities/root_candidate.dart';
import 'package:quranapp/features/quran_search/domain/entities/search_match_type.dart';
import 'package:quranapp/features/quran_search/domain/services/root_resolver.dart';

/// تطبيق محرك استخراج الجذور وتحديدها وفق المستويات الستة الصارمة المعتمدة في TRD.
class RootResolverImpl implements RootResolver {
  final QuranDatabase _db;
  final ArabicNormalizer _normalizer;

  /// معجم محلي للمفردات والمصطلحات القرآنية الشائعة لتسريع التحديد (Level 4: Local Dictionary)
  static const Map<String, String> _localDictionary = {
    'الله': 'اله',
    'الرحمن': 'رحم',
    'الرحيم': 'رحم',
    'الصراط': 'صرط',
    'المستقيم': 'قوم',
    'مستقيم': 'قوم',
    'استقام': 'قوم',
    'الجنة': 'جنن',
    'جهنم': 'جهنم',
    'الانسان': 'انس',
    'الناس': 'نوس',
    'ناس': 'نوس',
    'الصلاة': 'صلو',
    'صلاة': 'صلو',
    'الصلوة': 'صلو',
    'الزكاة': 'زكو',
    'زكاة': 'زكو',
    'الحياة': 'حيي',
    'حياة': 'حيي',
    'التقوى': 'وقي',
    'اتقى': 'وقي',
    'يتقون': 'وقي',
    'متقين': 'وقي',
    'المتقين': 'وقي',
    'المؤمنين': 'امن',
    'مؤمنون': 'امن',
    'ايمان': 'امن',
    'يؤمنون': 'امن',
    'الكتاب': 'كتب',
    'رسول': 'رسل',
    'الرسول': 'رسل',
    'انبياء': 'نبا',
    'النبي': 'نبا',
    'السماء': 'سمو',
    'السموات': 'سمو',
    'سماء': 'سمو',
    'سموات': 'سمو',
    'الارض': 'ارض',
    'ارض': 'ارض',
    'ابناء': 'بني',
    'بنين': 'بني',
    'امهات': 'امم',
    'ماء': 'موه',
    'مياه': 'موه',
    'هدى': 'هدي',
    'هداية': 'هدي',
    'يهدي': 'هدي',
    'يضل': 'ضلل',
    'الضالين': 'ضلل',
    'المفلحون': 'فلح',
    'المفلحين': 'فلح',
    'يستغفرون': 'غفر',
    'مستغفرين': 'غفر',
  };

  /// المنشئ لخدمة تحديد الجذور مع حقن قاعدة البيانات ومطبع النصوص
  RootResolverImpl({
    QuranDatabase? database,
    ArabicNormalizer? normalizer,
  })  : _db = database ?? QuranDatabase.instance,
        _normalizer = normalizer ?? const ArabicNormalizerImpl();

  @override
  Future<List<RootCandidate>> resolve(String query) async {
    final normalized = _normalizer.normalizeForSearch(query);
    if (normalized.isEmpty) return const [];

    final candidates = <RootCandidate>[];
    final seenRoots = <String>{};

    // =========================================================================
    // المستوى 1: البحث المباشر في الكلمات منزوعة التشكيل (word_normalized)
    // =========================================================================
    final wordMatches = await _db.query(
      sql: '''
        SELECT DISTINCT root_normalized
        FROM words
        WHERE word_normalized = ?
          AND root_normalized IS NOT NULL
          AND TRIM(root_normalized) != ''
        LIMIT 5;
      ''',
      arguments: [normalized],
    );

    for (final row in wordMatches) {
      final root = row['root_normalized'] as String;
      if (seenRoots.add(root)) {
        candidates.add(
          RootCandidate(
            root: root,
            confidence: 1.0,
            source: 'مطابقة موثقة في جدول كلمات القرآن (word_normalized)',
            isVerified: true,
            matchType: SearchMatchType.verifiedRoot,
          ),
        );
      }
    }

    // =========================================================================
    // المستوى 2: البحث في أصل الكلمة الصرفي (lemma_normalized)
    // =========================================================================
    final lemmaMatches = await _db.query(
      sql: '''
        SELECT DISTINCT root_normalized
        FROM words
        WHERE lemma_normalized = ?
          AND root_normalized IS NOT NULL
          AND TRIM(root_normalized) != ''
        LIMIT 5;
      ''',
      arguments: [normalized],
    );

    for (final row in lemmaMatches) {
      final root = row['root_normalized'] as String;
      if (seenRoots.add(root)) {
        candidates.add(
          RootCandidate(
            root: root,
            confidence: 0.95,
            source: 'مطابقة أصل الكلمة الصرفي الموثق (lemma_normalized)',
            isVerified: true,
            matchType: SearchMatchType.lemma,
          ),
        );
      }
    }

    // =========================================================================
    // المستوى 3: مطابقة الجذر المباشر إذا أدخل المستخدم جذرًا (root_normalized)
    // =========================================================================
    final rootNormalizedInput = _normalizer.normalizeForRootSearch(query);
    if (rootNormalizedInput.isNotEmpty) {
      final directRoots = await _db.query(
        sql: '''
          SELECT root, root_normalized, description_ar
          FROM roots
          WHERE root_normalized = ?
          LIMIT 1;
        ''',
        arguments: [rootNormalizedInput],
      );

      for (final row in directRoots) {
        final root = row['root_normalized'] as String;
        if (seenRoots.add(root)) {
          candidates.add(
            RootCandidate(
              root: root,
              confidence: 0.92,
              source: 'مطابقة مباشرة في معجم الجذور القرآنية الموثقة',
              isVerified: true,
              matchType: SearchMatchType.verifiedRoot,
            ),
          );
        }
      }
    }

    // =========================================================================
    // المستوى 4: البحث في القاموس المعجمي المحلي (Local Dictionary)
    // =========================================================================
    if (_localDictionary.containsKey(normalized)) {
      final dictRoot = _localDictionary[normalized]!;
      if (seenRoots.add(dictRoot)) {
        candidates.add(
          RootCandidate(
            root: dictRoot,
            confidence: 0.85,
            source: 'معجم الكلمات القرآني المحلي',
            isVerified: true,
            matchType: SearchMatchType.dictionaryRoot,
          ),
        );
      }
    }

    // =========================================================================
    // المستوى 5: التخمين الصرفي المنهجي (Morphological Inference)
    // استئصال السوابق واللواحق والأوزان والتحقق من وجود الجذر المستخرج في جدول roots
    // =========================================================================
    final inferredCandidates = await _inferRootsMorphologically(normalized);
    for (final infRoot in inferredCandidates) {
      if (seenRoots.add(infRoot)) {
        candidates.add(
          RootCandidate(
            root: infRoot,
            confidence: 0.70,
            source: 'استنباط صرفي منهجي مطابق لمعجم الجذور',
            isVerified: true,
            matchType: SearchMatchType.inferredRoot,
          ),
        );
      }
    }

    // =========================================================================
    // المستوى 6: التخمين بالحروف المرتبة كخيار احتياطي أخير (Ordered Characters)
    // تنص TRD صراحة: يجب تصنيفه كاقتراح غير مؤكد يحتاج مراجعة وعدم خلطه بالموثق
    // =========================================================================
    if (candidates.isEmpty || (candidates.length < 3 && normalized.length >= 3)) {
      final fallbackSuggestions = await _suggestRootsByOrderedCharacters(normalized);
      for (final sugRoot in fallbackSuggestions) {
        if (seenRoots.add(sugRoot)) {
          candidates.add(
            RootCandidate(
              root: sugRoot,
              confidence: 0.40,
              source: 'نتائج مقترحة بالحروف المرتبة (تحتاج إلى مراجعة)',
              isVerified: false,
              matchType: SearchMatchType.orderedCharactersSuggestion,
            ),
          );
        }
      }
    }

    // ترتيب المرشحين حسب درجة الثقة تنازلياً
    candidates.sort((a, b) => b.confidence.compareTo(a.confidence));
    return candidates;
  }

  /// التخمين الصرفي المنهجي عبر استئصال السوابق واللواحق والأنماط الشائعة
  Future<List<String>> _inferRootsMorphologically(String text) async {
    final validRoots = <String>[];
    final potentialStems = <String>{};

    var current = text;
    // 1. استئصال أل التعريف
    if (current.startsWith('ال') && current.length > 4) {
      current = current.substring(2);
      potentialStems.add(current);
    }

    // 2. استئصال سوابق العطف والجر والسين (و، ف، ب، ل، ك، س)
    final prefixes = ['و', 'ف', 'ب', 'ل', 'ك', 'س', 'ي', 'ت', 'ن', 'ا'];
    for (final p in prefixes) {
      if (current.startsWith(p) && current.length > 4) {
        final stripped = current.substring(p.length);
        potentialStems.add(stripped);
        if (stripped.startsWith('ال') && stripped.length > 4) {
          potentialStems.add(stripped.substring(2));
        }
      }
    }

    // 3. استئصال اللواحق (الضمائر وعلامات الجمع: ون، ين، ات، وا، هم، ها، كم، نا، ه، ك، ة)
    final suffixes = [
      'ون', 'ين', 'ات', 'ان', 'وا', 'هم', 'هن', 'كم', 'كن', 'نا', 'ها', 'تما', 'تم', 'ه', 'ك', 'ي', 'ة'
    ];
    for (final stem in [...potentialStems, current]) {
      for (final s in suffixes) {
        if (stem.endsWith(s) && stem.length - s.length >= 3) {
          potentialStems.add(stem.substring(0, stem.length - s.length));
        }
      }
    }

    // 4. استئصال أنماط المزيد بحرف أو حرفين (استفعل -> فعل، افتعل -> فعل، تفاعل -> فعل)
    for (final stem in List<String>.from(potentialStems)) {
      if (stem.startsWith('است') && stem.length >= 6) {
        potentialStems.add(stem.substring(3));
      }
      if (stem.startsWith('ت') && stem.length >= 5) {
        potentialStems.add(stem.substring(1));
      }
      if (stem.length == 4 && stem[1] == 'ا') {
        // فاعل -> فعل
        potentialStems.add('${stem[0]}${stem[2]}${stem[3]}');
      }
      if (stem.length == 5 && stem.startsWith('ا') && stem[2] == 'ت') {
        // افتعل -> فعل
        potentialStems.add('${stem[1]}${stem[3]}${stem[4]}');
      }
      if (stem.length == 5 && stem.startsWith('م') && stem[3] == 'و') {
        // مفعول -> فعل
        potentialStems.add('${stem[1]}${stem[2]}${stem[4]}');
      }
    }

    // 5. التحقق مما إذا كان أي جذع مستخرج يمثل جذرًا ثلاثيًا أو رباعيًا صحيحًا في قاعدة البيانات
    final candidateTokens = potentialStems.where((s) => s.length == 3 || s.length == 4).take(10).toList();
    if (candidateTokens.isEmpty) return const [];

    final placeholders = List.filled(candidateTokens.length, '?').join(',');
    final dbRoots = await _db.query(
      sql: '''
        SELECT root_normalized
        FROM roots
        WHERE root_normalized IN ($placeholders);
      ''',
      arguments: candidateTokens,
    );

    for (final row in dbRoots) {
      validRoots.add(row['root_normalized'] as String);
    }

    return validRoots;
  }

  /// التخمين بالحروف المرتبة كخيار أخير في حال عدم وجود أي مطابقة موثقة
  Future<List<String>> _suggestRootsByOrderedCharacters(String text) async {
    // نأخذ أول 3 حروف أو 4 حروف من الكلمة المطبّعة كمرشح للحروف المرتبة
    final clean = _normalizer.normalizeForRootSearch(text);
    if (clean.length < 3) return const [];

    // استعلام عينة من الجذور لمطابقة تسلسل الحروف
    final sampleRoots = await _db.query(
      sql: 'SELECT root_normalized FROM roots WHERE length(root_normalized) = 3 LIMIT 200;',
    );

    final suggestions = <String>[];
    for (final row in sampleRoots) {
      final root = row['root_normalized'] as String;
      // التحقق مما إذا كانت حروف الجذر مرتبة في كلمة البحث أو العكس
      if (_normalizer.containsCharactersInOrder(word: clean, root: root) ||
          (clean.length <= 4 && _normalizer.containsCharactersInOrder(word: root, root: clean))) {
        suggestions.add(root);
        if (suggestions.length >= 3) break;
      }
    }

    return suggestions;
  }
}
