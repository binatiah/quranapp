import '../entities/lexicon_export_data.dart';

/// واجهة مستودع تصدير واستيراد تصحيحات المعجم القرآني (LexiconIORepository Interface).
abstract interface class LexiconIORepository {
  /// تصدير التعديلات والتصحيحات المخصصة أو كامل بيانات المعجم بصيغة JSON
  Future<LexiconExportData> exportLexiconData({bool customOnly = true});

  /// تصدير البيانات كنص JSON جاهز للمشاركة أو الحفظ في ملف
  Future<String> exportLexiconJson({bool customOnly = true, bool pretty = true});

  /// استيراد حزمة تصحيحات وتحديث قاعدة بيانات SQLite محلياً بأمان تام
  Future<LexiconImportResult> importLexiconJson(String jsonString);
}
