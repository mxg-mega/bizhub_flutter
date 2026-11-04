import 'dart:convert';
import 'dart:io';
import 'package:csv/csv.dart';
import 'package:file_picker/file_picker.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';
import 'package:uuid/uuid.dart';
import '../../../features/inventory/data/repositories/product_repository_impl.dart';
import 'import_models.dart';
import 'import_ai_service.dart';
import '../../../features/inventory/domain/repositories/product_repository.dart';
import '../../../features/inventory/data/models/product_model.dart';
import '../../../shared/providers/auth_provider.dart';

part 'import_wizard_provider.g.dart';

@riverpod
class ImportWizard extends _$ImportWizard {
  @override
  ImportWizardState build() => const ImportWizardState();

  final List<String> _systemFields = [
    'name', 'sku', 'description', 'category', 'cost', 'price', 'stock', 'sellingUnit', 'purchaseUnit'
  ];

  Future<void> pickAndParseFile() async {
    final result = await FilePicker.platform.pickFiles(
      type: FileType.custom,
      allowedExtensions: ['csv'],
    );

    if (result == null || result.files.single.path == null) return;

    final file = File(result.files.single.path!);
    final input = file.readAsStringSync();
    // Using csv package to handle different CSV formats and edge cases
    // Decode the CSV file into a list of rows, where each row is a list of values
    final List<List<dynamic>> rows = Csv.excel().decode(input);

    if (rows.isEmpty) {
      state = state.copyWith(errorMessage: 'The file is empty.');
      return;
    }

    final headers = rows.first.map((final e) => e.toString()).toList();
    final data = rows.sublist(1);

    state = state.copyWith(
      step: ImportStep.mapping,
      headers: headers,
      rawData: data,
      mappings: headers.map((final h) => ImportMapping(userHeader: h)).toList(),
    );

    await autoMapColumns();
  }

  Future<void> autoMapColumns() async {
    final aiService = ref.read(importAiServiceProvider);
    final suggestions = await aiService.suggestMappings(
      userHeaders: state.headers,
      systemFields: _systemFields,
    );

    final newMappings = state.mappings.map((final m) {
      if (suggestions.containsKey(m.userHeader)) {
        return m.copyWith(systemField: suggestions[m.userHeader]);
      }
      return m;
    }).toList();

    state = state.copyWith(mappings: newMappings);
  }

  void updateMapping(final String userHeader, final String? systemField, final bool isIgnored) {
    final newMappings = state.mappings.map((final m) {
      if (m.userHeader == userHeader) {
        return m.copyWith(systemField: systemField, isIgnored: isIgnored);
      }
      return m;
    }).toList();
    state = state.copyWith(mappings: newMappings);
  }

  void goToPreview() {
    final previewRows = <ImportPreviewRow>[];
    
    for (final row in state.rawData) {
      final Map<String, dynamic> mappedData = {};
      final errors = <String>[];

      for (int i = 0; i < state.headers.length; i++) {
        final mapping = state.mappings[i];
        if (mapping.isIgnored || mapping.systemField == null) continue;
        
        final value = row[i];
        mappedData[mapping.systemField!] = value;
      }

      // Basic Validation
      if (mappedData['name'] == null || mappedData['name'].toString().isEmpty) {
        errors.add('Missing Product Name');
      }

      previewRows.add(ImportPreviewRow(data: mappedData, errors: errors));
    }

    state = state.copyWith(step: ImportStep.preview, previewData: previewRows);
  }

  Future<void> processImport() async {
    final businessId = ref.read(currentBusinessProvider)?.id;
    if (businessId == null) return;

    state = state.copyWith(step: ImportStep.processing, progress: 0.0);
    final repo = ref.read(productRepositoryProvider);
    
    int processed = 0;
    final total = state.previewData.length;

    for (final row in state.previewData) {
      if (row.errors.isNotEmpty) continue;

      final data = row.data;
      final product = ProductModel(
        id: const Uuid().v4(),
        name: data['name'].toString(),
        sku: data['sku']?.toString(),
        description: data['description']?.toString(),
        category: data['category']?.toString(),
        cost: double.tryParse(data['cost']?.toString() ?? '0') ?? 0.0,
        price: double.tryParse(data['price']?.toString() ?? '0') ?? 0.0,
        stockByLocation: {'main': double.tryParse(data['stock']?.toString() ?? '0') ?? 0.0},
        sellingUnit: data['sellingUnit']?.toString() ?? 'pcs',
        purchaseUnit: data['purchaseUnit']?.toString() ?? 'pcs',
      );

      await repo.saveProduct(businessId, product);
      
      processed++;
      state = state.copyWith(progress: processed / total);
    }

    state = state.copyWith(step: ImportStep.complete);
  }

  void reset() => state = const ImportWizardState();
}
