import 'package:equatable/equatable.dart';

/// أنماط مشاريع الدراسة القرآنية المتاحة في التطبيق
enum StudyProjectType {
  /// مشروع دراسة الجذر الصرفي واللغوي
  root,

  /// مشروع دراسة الآيات القرآنية
  ayah,

  /// مشروع دراسة المفاهيم والمواضيع القرآنية
  concept;

  /// تحويل النص المخزن في قاعدة البيانات إلى نمط المشروع
  static StudyProjectType fromString(String value) {
    switch (value.toLowerCase()) {
      case 'root':
        return StudyProjectType.root;
      case 'ayah':
        return StudyProjectType.ayah;
      case 'concept':
        return StudyProjectType.concept;
      default:
        return StudyProjectType.concept;
    }
  }

  /// القيمة النصية لتخزينها في قاعدة البيانات
  String toDbValue() {
    switch (this) {
      case StudyProjectType.root:
        return 'root';
      case StudyProjectType.ayah:
        return 'ayah';
      case StudyProjectType.concept:
        return 'concept';
    }
  }

  /// الاسم المعروض باللغة العربية
  String get arabicLabel {
    switch (this) {
      case StudyProjectType.root:
        return 'دراسة جذر';
      case StudyProjectType.ayah:
        return 'دراسة آية';
      case StudyProjectType.concept:
        return 'دراسة مفهوم';
    }
  }
}

/// حالة تقدم مشروع الدراسة
enum StudyProjectStatus {
  /// مسودة أولية قيد البدء
  draft,

  /// قيد البحث والدراسة المستمرة
  inProgress,

  /// دراسة مكتملة وموثقة
  completed;

  /// تحويل النص المخزن في قاعدة البيانات إلى حالة المشروع
  static StudyProjectStatus fromString(String value) {
    switch (value.toLowerCase()) {
      case 'draft':
        return StudyProjectStatus.draft;
      case 'in_progress':
        return StudyProjectStatus.inProgress;
      case 'completed':
        return StudyProjectStatus.completed;
      default:
        return StudyProjectStatus.draft;
    }
  }

  /// القيمة النصية لتخزينها في قاعدة البيانات
  String toDbValue() {
    switch (this) {
      case StudyProjectStatus.draft:
        return 'draft';
      case StudyProjectStatus.inProgress:
        return 'in_progress';
      case StudyProjectStatus.completed:
        return 'completed';
    }
  }

  /// الاسم المعروض باللغة العربية
  String get arabicLabel {
    switch (this) {
      case StudyProjectStatus.draft:
        return 'مسودة';
      case StudyProjectStatus.inProgress:
        return 'قيد الإجراء';
      case StudyProjectStatus.completed:
        return 'مكتمل';
    }
  }
}

/// يمثل كيان مشروع الدراسة القرآني الأساسي وفق مبادئ المعمارية النظيفة (Clean Architecture)
class StudyProject extends Equatable {
  /// المعرف الفريد للمشروع في قاعدة البيانات
  final int? id;

  /// عنوان المشروع (مثل: "دراسة جذر علم"، "دراسة آية الكرسي"، "مفهوم العدل في القرآن")
  final String title;

  /// نمط المشروع (جذر، آية، مفهوم)
  final StudyProjectType projectType;

  /// المعرف المستهدف (مثل: اسم الجذر "علم"، أو معرف الآية "2:255"، أو اسم المفهوم "العدل")
  final String targetIdentifier;

  /// وصف أو تمهيد موجز للمشروع
  final String? description;

  /// تاريخ ووقت إنشاء المشروع
  final DateTime createdAt;

  /// تاريخ ووقت آخر تحديث للمشروع
  final DateTime updatedAt;

  /// حالة إنجاز المشروع
  final StudyProjectStatus status;

  /// نسبة اكتمال محاور الدراسة (من 0.0 إلى 1.0)
  final double progress;

  /// المنشئ الثابت لكائن مشروع الدراسة
  const StudyProject({
    this.id,
    required this.title,
    required this.projectType,
    required this.targetIdentifier,
    this.description,
    required this.createdAt,
    required this.updatedAt,
    this.status = StudyProjectStatus.draft,
    this.progress = 0.0,
  });

  /// إنشاء نسخة معدلة
  StudyProject copyWith({
    int? id,
    String? title,
    StudyProjectType? projectType,
    String? targetIdentifier,
    String? description,
    DateTime? createdAt,
    DateTime? updatedAt,
    StudyProjectStatus? status,
    double? progress,
  }) {
    return StudyProject(
      id: id ?? this.id,
      title: title ?? this.title,
      projectType: projectType ?? this.projectType,
      targetIdentifier: targetIdentifier ?? this.targetIdentifier,
      description: description ?? this.description,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      status: status ?? this.status,
      progress: progress ?? this.progress,
    );
  }

  /// تحويل كائن المشروع إلى خريطة بيانات SQLite
  Map<String, dynamic> toMap() {
    return {
      if (id != null) 'id': id,
      'title': title,
      'project_type': projectType.toDbValue(),
      'target_identifier': targetIdentifier,
      'description': description,
      'created_at': createdAt.toIso8601String(),
      'updated_at': updatedAt.toIso8601String(),
      'status': status.toDbValue(),
      'progress': progress,
    };
  }

  /// بناء كائن المشروع من صف في قاعدة البيانات
  factory StudyProject.fromMap(Map<String, dynamic> map) {
    return StudyProject(
      id: map['id'] as int?,
      title: map['title'] as String,
      projectType: StudyProjectType.fromString(map['project_type'] as String),
      targetIdentifier: map['target_identifier'] as String,
      description: map['description'] as String?,
      createdAt: DateTime.parse(map['created_at'] as String),
      updatedAt: DateTime.parse(map['updated_at'] as String),
      status: StudyProjectStatus.fromString(map['status'] as String),
      progress: (map['progress'] as num?)?.toDouble() ?? 0.0,
    );
  }

  @override
  List<Object?> get props => [
        id,
        title,
        projectType,
        targetIdentifier,
        description,
        createdAt,
        updatedAt,
        status,
        progress,
      ];
}
