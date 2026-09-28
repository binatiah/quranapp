import 'package:equatable/equatable.dart';
import 'search_match_type.dart';

/// يمثل مرشحًا لجذر مستخرج لكلمة بحث مدخلة، مع درجة الثقة ومصدر الاستخراج.
class RootCandidate extends Equatable {
  /// الجذر المقترح بالحروف المطبّعة (مثل: علم)
  final String root;

  /// درجة الثقة الصرفية (من 0.0 إلى 1.0)
  final double confidence;

  /// مصدر الاستخراج (مثل: قاعدة البيانات الموثقة، القاموس المعجمي، استنباط صرفي، تطابق حروف مرتبة)
  final String source;

  /// هل النتيجة موثقة صرفياً ومؤكدة؟
  final bool isVerified;

  /// نوع المطابقة المرتبطة بهذا الجذر
  final SearchMatchType matchType;

  /// المنشئ الثابت لتهيئة كائن مرشح الجذر
  const RootCandidate({
    required this.root,
    required this.confidence,
    required this.source,
    required this.isVerified,
    required this.matchType,
  });

  /// إنشاء نسخة جديدة مع تعديل بعض الخصائص
  RootCandidate copyWith({
    String? root,
    double? confidence,
    String? source,
    bool? isVerified,
    SearchMatchType? matchType,
  }) {
    return RootCandidate(
      root: root ?? this.root,
      confidence: confidence ?? this.confidence,
      source: source ?? this.source,
      isVerified: isVerified ?? this.isVerified,
      matchType: matchType ?? this.matchType,
    );
  }

  @override
  List<Object?> get props => [
        root,
        confidence,
        source,
        isVerified,
        matchType,
      ];
}
