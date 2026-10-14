import 'dart:convert';
import 'package:equatable/equatable.dart';

/// يمثل عنصر ربط كلمة بجذر لأغراض التصدير والاستيراد
class ExportedWordRootLink extends Equatable {
  final int wordId;
  final String root;
  final String rootNormalized;
  final String? wordUthmani;
  final String? source;

  const ExportedWordRootLink({
    required this.wordId,
    required this.root,
    required this.rootNormalized,
    this.wordUthmani,
    this.source,
  });

  Map<String, dynamic> toMap() {
    return {
      'word_id': wordId,
      'root': root,
      'root_normalized': rootNormalized,
      if (wordUthmani != null) 'word_uthmani': wordUthmani,
      if (source != null) 'source': source,
    };
  }

  factory ExportedWordRootLink.fromMap(Map<String, dynamic> map) {
    final rawRoot = (map['root'] ?? '') as String;
    return ExportedWordRootLink(
      wordId: (map['word_id'] as num?)?.toInt() ?? 0,
      root: rawRoot,
      rootNormalized: (map['root_normalized'] as String?) ?? rawRoot.replaceAll(RegExp(r'[\u064B-\u065F\u0670]'), ''),
      wordUthmani: map['word_uthmani'] as String?,
      source: map['source'] as String?,
    );
  }

  @override
  List<Object?> get props => [wordId, root, rootNormalized, wordUthmani, source];
}

/// يمثل جذر مخصص أو معدل لأغراض التصدير والاستيراد
class ExportedRootEntry extends Equatable {
  final String root;
  final String rootNormalized;
  final String? descriptionAr;

  const ExportedRootEntry({
    required this.root,
    required this.rootNormalized,
    this.descriptionAr,
  });

  Map<String, dynamic> toMap() {
    return {
      'root': root,
      'root_normalized': rootNormalized,
      if (descriptionAr != null) 'description_ar': descriptionAr,
    };
  }

  factory ExportedRootEntry.fromMap(Map<String, dynamic> map) {
    final rawRoot = (map['root'] ?? '') as String;
    return ExportedRootEntry(
      root: rawRoot,
      rootNormalized: (map['root_normalized'] as String?) ?? rawRoot.replaceAll(RegExp(r'[\u064B-\u065F\u0670]'), ''),
      descriptionAr: (map['description_ar'] ?? map['meaning'] ?? map['description']) as String?,
    );
  }

  @override
  List<Object?> get props => [root, rootNormalized, descriptionAr];
}

/// كائن حزمة تصدير واستيراد تصحيحات المعجم القرآني (LexiconExportData).
class LexiconExportData extends Equatable {
  /// إصدار هيكل ملف التصدير
  final String version;

  /// توقيت التصدير الزمني بتنسيق ISO 8601
  final String exportedAt;

  /// وصف أو ملاحظات عن حزمة التصدير
  final String? notes;

  /// قائمة الجذور المصدرة
  final List<ExportedRootEntry> roots;

  /// قائمة روابط الكلمات المصححة
  final List<ExportedWordRootLink> wordLinks;

  const LexiconExportData({
    this.version = '1.0',
    required this.exportedAt,
    this.notes,
    this.roots = const [],
    this.wordLinks = const [],
  });

  Map<String, dynamic> toMap() {
    return {
      'version': version,
      'exported_at': exportedAt,
      if (notes != null) 'notes': notes,
      'roots': roots.map((r) => r.toMap()).toList(),
      'word_links': wordLinks.map((l) => l.toMap()).toList(),
    };
  }

  String toJsonString({bool pretty = true}) {
    final map = toMap();
    if (pretty) {
      return const JsonEncoder.withIndent('  ').convert(map);
    }
    return jsonEncode(map);
  }

  factory LexiconExportData.fromMap(Map<String, dynamic> map) {
    return LexiconExportData(
      version: (map['version'] ?? '1.0') as String,
      exportedAt: (map['exported_at'] ?? DateTime.now().toIso8601String()) as String,
      notes: map['notes'] as String?,
      roots: (map['roots'] as List<dynamic>?)
              ?.map((e) => ExportedRootEntry.fromMap(e as Map<String, dynamic>))
              .toList() ??
          const [],
      wordLinks: (map['word_links'] as List<dynamic>?)
              ?.map((e) => ExportedWordRootLink.fromMap(e as Map<String, dynamic>))
              .toList() ??
          const [],
    );
  }

  factory LexiconExportData.fromJsonString(String jsonString) {
    final decoded = jsonDecode(jsonString) as Map<String, dynamic>;
    return LexiconExportData.fromMap(decoded);
  }

  @override
  List<Object?> get props => [version, exportedAt, notes, roots, wordLinks];
}

/// نتيجة عملية استيراد تصحيحات المعجم
class LexiconImportResult extends Equatable {
  final bool isSuccess;
  final int importedRootsCount;
  final int updatedWordsCount;
  final List<String> warnings;
  final String? errorMessage;

  const LexiconImportResult({
    required this.isSuccess,
    this.importedRootsCount = 0,
    this.updatedWordsCount = 0,
    this.warnings = const [],
    this.errorMessage,
  });

  @override
  List<Object?> get props => [
        isSuccess,
        importedRootsCount,
        updatedWordsCount,
        warnings,
        errorMessage,
      ];
}
