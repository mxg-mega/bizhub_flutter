import 'package:json_annotation/json_annotation.dart';

enum ImportStep { upload, mapping, preview, processing, complete }

class ImportMapping {
  final String userHeader;
  String? systemField; // e.g., 'name', 'sku'
  bool isIgnored;

  ImportMapping({
    required this.userHeader,
    this.systemField,
    this.isIgnored = false,
  });

  ImportMapping copyWith({
    String? systemField,
    bool? isIgnored,
  }) {
    return ImportMapping(
      userHeader: userHeader,
      systemField: systemField ?? this.systemField,
      isIgnored: isIgnored ?? this.isIgnored,
    );
  }
}

class ImportPreviewRow {
  final Map<String, dynamic> data;
  final List<String> errors;

  ImportPreviewRow({required this.data, this.errors = const []});
}

class ImportWizardState {
  final ImportStep step;
  final List<String> headers;
  final List<List<dynamic>> rawData;
  final List<ImportMapping> mappings;
  final List<ImportPreviewRow> previewData;
  final double progress;
  final String? errorMessage;

  const ImportWizardState({
    this.step = ImportStep.upload,
    this.headers = const [],
    this.rawData = const [],
    this.mappings = const [],
    this.previewData = const [],
    this.progress = 0.0,
    this.errorMessage,
  });

  ImportWizardState copyWith({
    ImportStep? step,
    List<String>? headers,
    List<List<dynamic>>? rawData,
    List<ImportMapping>? mappings,
    List<ImportPreviewRow>? previewData,
    double? progress,
    String? errorMessage,
  }) {
    return ImportWizardState(
      step: step ?? this.step,
      headers: headers ?? this.headers,
      rawData: rawData ?? this.rawData,
      mappings: mappings ?? this.mappings,
      previewData: previewData ?? this.previewData,
      progress: progress ?? this.progress,
      errorMessage: errorMessage,
    );
  }
}
