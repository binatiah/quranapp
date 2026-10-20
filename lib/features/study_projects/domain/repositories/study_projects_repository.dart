import '../entities/study_project.dart';
import '../entities/study_project_full.dart';
import '../entities/root_study_details.dart';
import '../entities/ayah_study_details.dart';
import '../entities/concept_study_details.dart';

/// واجهة مستودع إدارة مشاريع الدراسة القرآنية (StudyProjectsRepository)
abstract interface class StudyProjectsRepository {
  /// جلب قائمة المشاريع مع دعم التصفية حسب النمط والحالة والبحث النصي
  Future<List<StudyProject>> getProjects({
    StudyProjectType? type,
    StudyProjectStatus? status,
    String? query,
  });

  /// جلب مشروع الدراسة الكامل بكافة تفاصيله التخصصية وروابطه بواسطة المعرف
  Future<StudyProjectFull?> getProjectById(int id);

  /// إنشاء مشروع دراسة جديد مع تفاصيله التخصصية
  Future<int> createProject(
    StudyProject project, {
    RootStudyDetails? rootDetails,
    AyahStudyDetails? ayahDetails,
    ConceptStudyDetails? conceptDetails,
  });

  /// تحديث البيانات العامة للمشروع (العنوان، الحالة، نسبة الإنجاز...)
  Future<void> updateProject(StudyProject project);

  /// تحديث تفاصيل مشروع دراسة الجذر الصرفي
  Future<void> updateRootDetails(RootStudyDetails details);

  /// تحديث تفاصيل مشروع دراسة الآية القرآنية
  Future<void> updateAyahDetails(AyahStudyDetails details);

  /// تحديث تفاصيل مشروع دراسة المفهوم والموضوع
  Future<void> updateConceptDetails(ConceptStudyDetails details);

  /// حذف مشروع الدراسة وكافة تفاصيله وروابطه المرتبطة به بالتتابع (Cascade)
  Future<void> deleteProject(int projectId);

  /// إضافة رابط آية قرآنية إلى المشروع
  Future<int> addAyahLink({
    required int projectId,
    required int ayahId,
    String? note,
    String relationType = 'related',
  });

  /// إزالة رابط آية من المشروع
  Future<void> removeAyahLink(int linkId);

  /// إضافة رابط جذر لغوي إلى المشروع (لمشاريع المفاهيم)
  Future<int> addRootLink({
    required int projectId,
    required String rootNormalized,
    String? note,
  });

  /// إزالة رابط جذر من المشروع
  Future<void> removeRootLink(int linkId);

  /// جلب إحصائيات عامة للمشاريع (إجمالي، مسودات، قيد الإجراء، مكتملة، حسب الأنماط)
  Future<Map<String, int>> getProjectsStatistics();
}
