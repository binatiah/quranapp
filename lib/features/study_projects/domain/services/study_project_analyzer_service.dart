import 'dart:convert';
import '../entities/study_project.dart';
import '../entities/study_project_full.dart';

/// نتيجة التحليل الآلي للجذر اللغوي
class RootAnalysisResult {
  /// نوع الجذر الصرفي (ثنائي، ثلاثي، رباعي، خماسي)
  final String rootType;

  /// هل يحتوي الجذر على أحرف علة؟
  final bool hasVowels;

  /// عدد أحرف العلة المكتشفة
  final int vowelsCount;

  /// نص سردي لأحرف العلة الموجودة
  final String vowelsList;

  /// المنشئ الثابت
  const RootAnalysisResult({
    required this.rootType,
    required this.hasVowels,
    required this.vowelsCount,
    required this.vowelsList,
  });
}

/// خدمة تحليل مشاريع الدراسة القرآنية وحساب نسب الإنجاز والتوليد الذكي
class StudyProjectAnalyzerService {
  /// منشئ الخدمة
  const StudyProjectAnalyzerService();

  /// تحليل الجذر الصرفي واستنتاج نوعه ووجود حروف العلة وأعدادها
  RootAnalysisResult analyzeRoot(String root) {
    final cleanRoot = root.trim().replaceAll(RegExp(r'\s+'), '');
    final length = cleanRoot.runes.length;

    // استنتاج نوع الجذر اللغوي
    final String type;
    switch (length) {
      case 2:
        type = 'ثنائي';
        break;
      case 3:
        type = 'ثلاثي';
        break;
      case 4:
        type = 'رباعي';
        break;
      case 5:
        type = 'خماسي';
        break;
      default:
        type = length > 5 ? 'متعدد الحروف ($length)' : 'أحادي';
        break;
    }

    // رصد أحرف العلة (الألف، الواو، الياء ومشتقاتها كالألف المقصورة والهمزة)
    const vowelChars = {'و', 'ي', 'ا', 'ى', 'ء', 'أ', 'إ', 'آ'};
    final detectedVowels = <String>{};
    int count = 0;

    for (final rune in cleanRoot.runes) {
      final char = String.fromCharCode(rune);
      if (vowelChars.contains(char)) {
        detectedVowels.add(char);
        count++;
      }
    }

    final hasVowels = count > 0;
    final vowelsListStr = detectedVowels.isEmpty ? 'لا يوجد' : detectedVowels.join('، ');

    return RootAnalysisResult(
      rootType: type,
      hasVowels: hasVowels,
      vowelsCount: count,
      vowelsList: vowelsListStr,
    );
  }

  /// احتساب نسبة الإنجاز المئوية (Progress 0.0 -> 1.0) لمشروع الدراسة بناءً على إجابات المحاور
  double calculateProgress(StudyProjectFull full) {
    int totalCriteria = 0;
    int completedCriteria = 0;

    switch (full.project.projectType) {
      case StudyProjectType.root:
        final d = full.rootDetails;
        totalCriteria = 9;
        if (d != null) {
          if (d.rootType != null && d.rootType!.trim().isNotEmpty) completedCriteria++;
          if (d.hasVowels || d.vowelsList != null) completedCriteria++;
          if (d.cognatesOtherLanguages != null && d.cognatesOtherLanguages!.trim().isNotEmpty) completedCriteria++;
          if (d.oldestUsage != null && d.oldestUsage!.trim().isNotEmpty) completedCriteria++;
          if (d.usageNature != null && d.usageNature!.trim().isNotEmpty) completedCriteria++;
          if (d.synonyms != null && d.synonyms!.trim().isNotEmpty) completedCriteria++;
          if (d.antonyms != null && d.antonyms!.trim().isNotEmpty) completedCriteria++;
          if (d.researcherNotes != null && d.researcherNotes!.trim().isNotEmpty) completedCriteria++;
        }
        if (full.linkedAyahs.isNotEmpty || (full.targetRootDerivedWordsCount ?? 0) > 0) {
          completedCriteria++;
        }
        break;

      case StudyProjectType.ayah:
        final d = full.ayahDetails;
        totalCriteria = 9;
        if (d != null) {
          if (d.topic != null && d.topic!.trim().isNotEmpty) completedCriteria++;
          if (d.traditionalTafseer != null && d.traditionalTafseer!.trim().isNotEmpty) completedCriteria++;
          if (d.revelationContext != null && d.revelationContext!.trim().isNotEmpty) completedCriteria++;
          if (d.crossReferences != null && d.crossReferences!.trim().isNotEmpty) completedCriteria++;
          if (d.otherScripturesParallels != null && d.otherScripturesParallels!.trim().isNotEmpty) completedCriteria++;
          if (d.apparentConcept != null && d.apparentConcept!.trim().isNotEmpty) completedCriteria++;
          if (d.rulingOrStatus != null && d.rulingOrStatus!.trim().isNotEmpty) completedCriteria++;
          if (d.researcherNotes != null && d.researcherNotes!.trim().isNotEmpty) completedCriteria++;
        }
        if (full.linkedAyahs.isNotEmpty) completedCriteria++;
        break;

      case StudyProjectType.concept:
        final d = full.conceptDetails;
        totalCriteria = 9;
        if (d != null) {
          if (d.term.trim().isNotEmpty) completedCriteria++;
          if (d.denotationType != null && d.denotationType!.trim().isNotEmpty) completedCriteria++;
          if (d.quranicVsContemporaryMeaning != null && d.quranicVsContemporaryMeaning!.trim().isNotEmpty) completedCriteria++;
          if (d.oppositeConcept != null && d.oppositeConcept!.trim().isNotEmpty) completedCriteria++;
          if (d.relatedConcepts != null && d.relatedConcepts!.trim().isNotEmpty) completedCriteria++;
          if (d.quranicDiscourse != null && d.quranicDiscourse!.trim().isNotEmpty) completedCriteria++;
          if (d.researcherNotes != null && d.researcherNotes!.trim().isNotEmpty) completedCriteria++;
        }
        if (full.linkedAyahs.isNotEmpty) completedCriteria++;
        if (full.linkedRoots.isNotEmpty) completedCriteria++;
        break;
    }

    if (totalCriteria == 0) return 0.0;
    final ratio = completedCriteria / totalCriteria;
    return (ratio > 1.0) ? 1.0 : double.parse(ratio.toStringAsFixed(2));
  }

  /// تصدير تقرير مشروع الدراسة المكتمل بصيغة Markdown منسقة واحترافية
  String exportToMarkdown(StudyProjectFull full) {
    final buffer = StringBuffer();
    final p = full.project;

    buffer.writeln('# مشروع دراسة قرآنية: ${p.title}');
    buffer.writeln();
    buffer.writeln('- **النمط**: ${p.projectType.arabicLabel}');
    buffer.writeln('- **المستهدف**: ${p.targetIdentifier}');
    buffer.writeln('- **الحالة**: ${p.status.arabicLabel}');
    buffer.writeln('- **نسبة الإنجاز**: ${(p.progress * 100).toInt()}%');
    buffer.writeln('- **تاريخ الإنشاء**: ${p.createdAt.toLocal().toString().split('.')[0]}');
    buffer.writeln('- **آخر تحديث**: ${p.updatedAt.toLocal().toString().split('.')[0]}');
    if (p.description != null && p.description!.trim().isNotEmpty) {
      buffer.writeln();
      buffer.writeln('### التمهيد والوصف العام');
      buffer.writeln(p.description);
    }
    buffer.writeln();

    // تفاصيل محاور دراسة الجذر
    if (full.rootDetails != null) {
      final r = full.rootDetails!;
      buffer.writeln('## محاور دراسة الجذر الصرفي');
      buffer.writeln('- **نوع الجذر**: ${r.rootType ?? "غير محدد"}');
      buffer.writeln('- **أحرف العلة**: ${r.hasVowels ? "نعم (${r.vowelsList})" : "لا يوجد"}');
      buffer.writeln('- **التطابقات في لغات أخرى**: ${r.cognatesOtherLanguages ?? "لم تُرصد"}');
      buffer.writeln('- **أقدم استخدام مرصود**: ${r.oldestUsage ?? "قيد البحث"}');
      buffer.writeln('- **الاستخدام اليوم**: ${r.isUsedToday ? "مستمر في الاستعمال" : "نادر/مهجور"}');
      buffer.writeln('- **طبيعة الدلالة**: ${r.usageNature ?? "غير محدد"}');
      buffer.writeln('- **المعنى المرادف**: ${r.synonyms ?? "لم يُحدد"}');
      buffer.writeln('- **المعنى المضاد**: ${r.antonyms ?? "لم يُحدد"}');
      buffer.writeln();
      buffer.writeln('### رأي الباحث وملاحظاته');
      buffer.writeln(r.researcherNotes ?? "لا توجد ملاحظات مدونة.");
      buffer.writeln();
    }

    // تفاصيل محاور دراسة الآية
    if (full.ayahDetails != null) {
      final a = full.ayahDetails!;
      buffer.writeln('## محاور دراسة الآية القرآنية');
      if (full.targetVerseText != null) {
        buffer.writeln('> "${full.targetVerseText}"');
        buffer.writeln('> — [سورة ${full.targetSurahName ?? a.surahId}: آية ${a.ayahNumber}]');
        buffer.writeln();
      }
      buffer.writeln('- **موضوع الآية**: ${a.topic ?? "قيد التحرير"}');
      buffer.writeln('- **زمن ومناسبات وسبب النزول**: ${a.revelationContext ?? "قيد البحث"}');
      buffer.writeln('- **المفهوم الظاهر من الآية**: ${a.apparentConcept ?? "قيد التحرير"}');
      buffer.writeln('- **هل هي دليل على حكم شرعي؟**: ${a.rulingOrStatus ?? "غير محدد"}');
      buffer.writeln('- **التقاطعات والآيات المفسرة**: ${a.crossReferences ?? "لا توجد"}');
      buffer.writeln('- **التشابهات في كتب مقدسة أخرى**: ${a.otherScripturesParallels ?? "لا توجد"}');
      buffer.writeln();
      buffer.writeln('### التفسير من الموروث');
      buffer.writeln(a.traditionalTafseer ?? "لم يُدوّن تفسير بعد.");
      buffer.writeln();
      buffer.writeln('### رأي الباحث وملاحظاته التدبرية');
      buffer.writeln(a.researcherNotes ?? "لا توجد ملاحظات مدونة.");
      buffer.writeln();
    }

    // تفاصيل محاور دراسة المفهوم
    if (full.conceptDetails != null) {
      final c = full.conceptDetails!;
      buffer.writeln('## محاور دراسة المفهوم القرآني');
      buffer.writeln('- **المفهوم / المصطلح**: ${c.term}');
      buffer.writeln('- **نوع الدلالة**: ${c.denotationType ?? "غير محدد"}');
      buffer.writeln('- **المعنى القرآني والمعنى المعاصر**: ${c.quranicVsContemporaryMeaning ?? "قيد المقارنة"}');
      buffer.writeln('- **المفهوم المغاير أو المضاد**: ${c.oppositeConcept ?? "غير محدد"}');
      buffer.writeln('- **العلاقة بمفاهيم أخرى**: ${c.relatedConcepts ?? "غير محدد"}');
      buffer.writeln();
      buffer.writeln('### المعالجة القرآنية والسياق العام');
      buffer.writeln(c.quranicDiscourse ?? "قيد التدوين والتحليل.");
      buffer.writeln();
      buffer.writeln('### رأي الباحث وملاحظاته');
      buffer.writeln(c.researcherNotes ?? "لا توجد ملاحظات مدونة.");
      buffer.writeln();
    }

    // الآيات المرتبطة
    if (full.linkedAyahs.isNotEmpty) {
      buffer.writeln('## الآيات القرآنية ذات الصلة والتقاطعات');
      for (final link in full.linkedAyahs) {
        buffer.writeln('- **سورة ${link.surahName} [${link.ayahNumber}]** (${link.relationTypeArabic}):');
        buffer.writeln('  > "${link.textUthmani}"');
        if (link.note != null && link.note!.trim().isNotEmpty) {
          buffer.writeln('  *ملاحظة: ${link.note}*');
        }
      }
      buffer.writeln();
    }

    // الجذور المرتبطة
    if (full.linkedRoots.isNotEmpty) {
      buffer.writeln('## شبكة الجذور اللغوية المعبرة عن المفهوم');
      for (final root in full.linkedRoots) {
        buffer.writeln('- **جذر (${root.rootNormalized})** - ورود في المصحف: ${root.occurrenceCount} مرة');
        if (root.note != null && root.note!.trim().isNotEmpty) {
          buffer.writeln('  *ملاحظة: ${root.note}*');
        }
      }
      buffer.writeln();
    }

    buffer.writeln('---');
    buffer.writeln('*تم إنشاء هذا التقرير تلقائياً عبر تطبيق مصحف البحث والدراسة القرآني.*');

    return buffer.toString();
  }

  /// تصدير المشروع كحزمة JSON قياسية للنسخ الاحتياطي والمشاركة
  String exportToJson(StudyProjectFull full) {
    final map = {
      'project': full.project.toMap(),
      'root_details': full.rootDetails?.toMap(),
      'ayah_details': full.ayahDetails?.toMap(),
      'concept_details': full.conceptDetails?.toMap(),
      'linked_ayahs': full.linkedAyahs
          .map((a) => {
                'ayah_id': a.ayahId,
                'surah_id': a.surahId,
                'ayah_number': a.ayahNumber,
                'note': a.note,
                'relation_type': a.relationType,
              })
          .toList(),
      'linked_roots': full.linkedRoots
          .map((r) => {
                'root_normalized': r.rootNormalized,
                'note': r.note,
              })
          .toList(),
      'exported_at': DateTime.now().toIso8601String(),
      'app_version': '1.0.0',
    };

    return const JsonEncoder.withIndent('  ').convert(map);
  }
}
