import 'package:equatable/equatable.dart';

/// أصناف الدلالات الفكرية واللغوية للمفاهيم القرآنية
enum ConceptDenotationType {
  /// معنوي: يُرصد أثره بالمشاعر والوجدان (مثل الحب، الرحمة، الخوف)
  moral,

  /// قياسي: يُستخدم للمقادير والموازنة (مثل كبير، صغير، قليل، كثير)
  scalar,

  /// تجريدي: لا يخضع لقوانين الزمكان والمادة (مثل الحق، العلم، الحكمة)
  abstractType,

  /// مادي: يرتبط بالأجرام والأعيان المحسوسة (مثل جبل، شجر، ماء)
  material,

  /// فكري: يرصده العقل والاستنباط القيمي (مثل الأخلاق، العدل، البرهان)
  intellectual;

  /// التحويل من النص المخزن في قاعدة البيانات
  static ConceptDenotationType? fromString(String? value) {
    if (value == null) return null;
    switch (value.toLowerCase()) {
      case 'moral':
      case 'معنوي':
        return ConceptDenotationType.moral;
      case 'scalar':
      case 'قياسي':
        return ConceptDenotationType.scalar;
      case 'abstract':
      case 'تجريدي':
        return ConceptDenotationType.abstractType;
      case 'material':
      case 'مادي':
        return ConceptDenotationType.material;
      case 'intellectual':
      case 'فكري':
        return ConceptDenotationType.intellectual;
      default:
        return null;
    }
  }

  /// القيمة المخزنة في قاعدة البيانات
  String toDbValue() {
    switch (this) {
      case ConceptDenotationType.moral:
        return 'moral';
      case ConceptDenotationType.scalar:
        return 'scalar';
      case ConceptDenotationType.abstractType:
        return 'abstract';
      case ConceptDenotationType.material:
        return 'material';
      case ConceptDenotationType.intellectual:
        return 'intellectual';
    }
  }

  /// الاسم المعروض باللغة العربية
  String get arabicLabel {
    switch (this) {
      case ConceptDenotationType.moral:
        return 'معنوي (وجداني/شعوري)';
      case ConceptDenotationType.scalar:
        return 'قياسي (مقادير/موازنة)';
      case ConceptDenotationType.abstractType:
        return 'تجريدي (يتجاوز الزمكان)';
      case ConceptDenotationType.material:
        return 'مادي (محسوس/أعيان)';
      case ConceptDenotationType.intellectual:
        return 'فكري (عقلي/قيمي)';
    }
  }

  /// الشرح الإيضاحي للدلالة لتوجيه الباحث
  String get explanation {
    switch (this) {
      case ConceptDenotationType.moral:
        return 'يُرصد أثره بالمشاعر والوجدان البشري مثل الحب أو الرحمة أو السكينة.';
      case ConceptDenotationType.scalar:
        return 'يُستخدم للمفاضلة والمقادير والموازنة مثل كبير أو صغير أو كثير أو قليل.';
      case ConceptDenotationType.abstractType:
        return 'مفهوم كلي لا يخضع لقيود الزمان والمكان والمادة مثل الحق أو العلم أو الحكمة.';
      case ConceptDenotationType.material:
        return 'يرتبط بالأعيان والمحسوسات في الطبيعة والكون مثل جبل أو شجر أو بحر.';
      case ConceptDenotationType.intellectual:
        return 'يرصده العقل بالتأمل والاستنباط النظري مثل الأخلاق أو العدل أو البرهان.';
    }
  }
}

/// يحتوي على تفاصيل وأسئلة مشروع دراسة المفاهيم والمواضيع القرآنية
class ConceptStudyDetails extends Equatable {
  /// المعرف المرجعي للمشروع
  final int projectId;

  /// اسم المفهوم أو المصطلح (العنوان الأساسي: مثل الحق، العدل، التربية، التجارة)
  final String term;

  /// نوع الدلالة الفكرية أو المعنوية أو القياسية أو التجريدية أو المادية
  final String? denotationType;

  /// المقارنة بين المعنى القرآني والمعنى المعاصر المتداول
  final String? quranicVsContemporaryMeaning;

  /// المفهوم المغاير أو المضاد المقابل في القرآن (مثل الحق في مقابلة الباطل)
  final String? oppositeConcept;

  /// علاقة المفهوم بمفاهيم قرآنية أخرى وشبكته الدلالية
  final String? relatedConcepts;

  /// كيف ناقش القرآن هذا المفهوم وبنى سياقه العام عبر تقاطع الآيات
  final String? quranicDiscourse;

  /// رأي الباحث وملاحظاته التحليلية وخلاصاته
  final String? researcherNotes;

  /// المنشئ الثابت لتفاصيل دراسة المفاهيم
  const ConceptStudyDetails({
    required this.projectId,
    required this.term,
    this.denotationType,
    this.quranicVsContemporaryMeaning,
    this.oppositeConcept,
    this.relatedConcepts,
    this.quranicDiscourse,
    this.researcherNotes,
  });

  /// إنشاء نسخة معدلة
  ConceptStudyDetails copyWith({
    int? projectId,
    String? term,
    String? denotationType,
    String? quranicVsContemporaryMeaning,
    String? oppositeConcept,
    String? relatedConcepts,
    String? quranicDiscourse,
    String? researcherNotes,
  }) {
    return ConceptStudyDetails(
      projectId: projectId ?? this.projectId,
      term: term ?? this.term,
      denotationType: denotationType ?? this.denotationType,
      quranicVsContemporaryMeaning:
          quranicVsContemporaryMeaning ?? this.quranicVsContemporaryMeaning,
      oppositeConcept: oppositeConcept ?? this.oppositeConcept,
      relatedConcepts: relatedConcepts ?? this.relatedConcepts,
      quranicDiscourse: quranicDiscourse ?? this.quranicDiscourse,
      researcherNotes: researcherNotes ?? this.researcherNotes,
    );
  }

  /// تحويل الكائن إلى خريطة بيانات SQLite
  Map<String, dynamic> toMap() {
    return {
      'project_id': projectId,
      'term': term,
      'denotation_type': denotationType,
      'quranic_vs_contemporary_meaning': quranicVsContemporaryMeaning,
      'opposite_concept': oppositeConcept,
      'related_concepts': relatedConcepts,
      'quranic_discourse': quranicDiscourse,
      'researcher_notes': researcherNotes,
    };
  }

  /// إنشاء كائن تفاصيل المفهوم من صف في قاعدة البيانات
  factory ConceptStudyDetails.fromMap(Map<String, dynamic> map) {
    return ConceptStudyDetails(
      projectId: map['project_id'] as int,
      term: map['term'] as String,
      denotationType: map['denotation_type'] as String?,
      quranicVsContemporaryMeaning:
          map['quranic_vs_contemporary_meaning'] as String?,
      oppositeConcept: map['opposite_concept'] as String?,
      relatedConcepts: map['related_concepts'] as String?,
      quranicDiscourse: map['quranic_discourse'] as String?,
      researcherNotes: map['researcher_notes'] as String?,
    );
  }

  @override
  List<Object?> get props => [
        projectId,
        term,
        denotationType,
        quranicVsContemporaryMeaning,
        oppositeConcept,
        relatedConcepts,
        quranicDiscourse,
        researcherNotes,
      ];
}
