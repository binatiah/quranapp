import 'package:equatable/equatable.dart';

/// يمثل كيان الكلمة القرآنية مع بياناتها الصرفية والتحليلية.
class QuranWord extends Equatable {
  /// المعرف الفريد للكلمة في قاعدة البيانات
  final int id;

  /// معرف الآية التي تتبع لها الكلمة
  final int ayahId;

  /// رقم السورة
  final int surahId;

  /// رقم الآية داخل السورة
  final int ayahNumber;

  /// ترتيب الكلمة داخل الآية (1, 2, 3...)
  final int wordPosition;

  /// الكلمة بالرسم العثماني والتشكيل
  final String wordUthmani;

  /// الكلمة مجردة من التشكيل
  final String wordSimple;

  /// الكلمة مطبّعة لعمليات البحث
  final String wordNormalized;

  /// أصل الكلمة أو اللفظ المجرد (Lemma)
  final String? lemma;

  /// اللفظ المجرد المطبّع
  final String? lemmaNormalized;

  /// الجذر اللغوي للكلمة (مثل: ع-ل-م)
  final String? root;

  /// الجذر المطبّع (مثل: علم)
  final String? rootNormalized;

  /// السابقة (مثل حروف العطف أو أل التعريف)
  final String? prefix;

  /// الجذع الصرفي الأساسي (Stem)
  final String? stem;

  /// اللاحقة (مثل الضمائر المتصلة)
  final String? suffix;

  /// نوع الكلمة النحوي (اسم، فعل، حرف...)
  final String? partOfSpeech;

  /// الوصف الصرفي التفصيلي
  final String? morphology;

  /// المنشئ الثابت لتهيئة كائن الكلمة القرآنية
  const QuranWord({
    required this.id,
    required this.ayahId,
    required this.surahId,
    required this.ayahNumber,
    required this.wordPosition,
    required this.wordUthmani,
    required this.wordSimple,
    required this.wordNormalized,
    this.lemma,
    this.lemmaNormalized,
    this.root,
    this.rootNormalized,
    this.prefix,
    this.stem,
    this.suffix,
    this.partOfSpeech,
    this.morphology,
  });

  /// إنشاء نسخة جديدة مع تعديل بعض الخصائص
  QuranWord copyWith({
    int? id,
    int? ayahId,
    int? surahId,
    int? ayahNumber,
    int? wordPosition,
    String? wordUthmani,
    String? wordSimple,
    String? wordNormalized,
    String? lemma,
    String? lemmaNormalized,
    String? root,
    String? rootNormalized,
    String? prefix,
    String? stem,
    String? suffix,
    String? partOfSpeech,
    String? morphology,
  }) {
    return QuranWord(
      id: id ?? this.id,
      ayahId: ayahId ?? this.ayahId,
      surahId: surahId ?? this.surahId,
      ayahNumber: ayahNumber ?? this.ayahNumber,
      wordPosition: wordPosition ?? this.wordPosition,
      wordUthmani: wordUthmani ?? this.wordUthmani,
      wordSimple: wordSimple ?? this.wordSimple,
      wordNormalized: wordNormalized ?? this.wordNormalized,
      lemma: lemma ?? this.lemma,
      lemmaNormalized: lemmaNormalized ?? this.lemmaNormalized,
      root: root ?? this.root,
      rootNormalized: rootNormalized ?? this.rootNormalized,
      prefix: prefix ?? this.prefix,
      stem: stem ?? this.stem,
      suffix: suffix ?? this.suffix,
      partOfSpeech: partOfSpeech ?? this.partOfSpeech,
      morphology: morphology ?? this.morphology,
    );
  }

  /// تحويل كائن الكلمة القرآنية إلى Map لقاعدة البيانات
  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'ayah_id': ayahId,
      'surah_id': surahId,
      'ayah_number': ayahNumber,
      'word_position': wordPosition,
      'word_uthmani': wordUthmani,
      'word_simple': wordSimple,
      'word_normalized': wordNormalized,
      'lemma': lemma,
      'lemma_normalized': lemmaNormalized,
      'root': root,
      'root_normalized': rootNormalized,
      'prefix': prefix,
      'stem': stem,
      'suffix': suffix,
      'part_of_speech': partOfSpeech,
      'morphology': morphology,
    };
  }

  /// إنشاء كائن كلمة قرآنية من Map
  factory QuranWord.fromMap(Map<String, dynamic> map) {
    return QuranWord(
      id: map['id'] as int,
      ayahId: map['ayah_id'] as int,
      surahId: map['surah_id'] as int,
      ayahNumber: map['ayah_number'] as int,
      wordPosition: map['word_position'] as int,
      wordUthmani: map['word_uthmani'] as String,
      wordSimple: (map['word_simple'] ?? '') as String,
      wordNormalized: (map['word_normalized'] ?? '') as String,
      lemma: map['lemma'] as String?,
      lemmaNormalized: map['lemma_normalized'] as String?,
      root: map['root'] as String?,
      rootNormalized: map['root_normalized'] as String?,
      prefix: map['prefix'] as String?,
      stem: map['stem'] as String?,
      suffix: map['suffix'] as String?,
      partOfSpeech: map['part_of_speech'] as String?,
      morphology: map['morphology'] as String?,
    );
  }

  @override
  List<Object?> get props => [
        id,
        ayahId,
        surahId,
        ayahNumber,
        wordPosition,
        wordUthmani,
        wordSimple,
        wordNormalized,
        lemma,
        lemmaNormalized,
        root,
        rootNormalized,
        prefix,
        stem,
        suffix,
        partOfSpeech,
        morphology,
      ];
}
