import 'package:equatable/equatable.dart';

/// يمثل كلمة قرآنية مشتقة من جذر لغوي مع عدد مرات تكرارها في المصحف.
class DerivedWord extends Equatable {
  /// الكلمة بالرسم العثماني
  final String wordUthmani;

  /// الكلمة المطبّعة منزوعة التشكيل
  final String wordNormalized;

  /// عدد مرات ورود هذه الكلمة المشتقة في القرآن الكريم
  final int occurrenceCount;

  /// المنشئ الثابت للكلمة المشتقة
  const DerivedWord({
    required this.wordUthmani,
    required this.wordNormalized,
    required this.occurrenceCount,
  });

  /// تحويل من صف قاعدة البيانات
  factory DerivedWord.fromMap(Map<String, Object?> map) {
    return DerivedWord(
      wordUthmani: (map['display_word'] ?? map['word_uthmani'] ?? '') as String,
      wordNormalized: (map['word_normalized'] ?? '') as String,
      occurrenceCount: (map['occurrence_count'] as num?)?.toInt() ?? 0,
    );
  }

  @override
  List<Object?> get props => [wordUthmani, wordNormalized, occurrenceCount];
}
