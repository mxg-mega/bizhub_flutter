import 'dart:convert';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:google_generative_ai/google_generative_ai.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

part 'import_ai_service.g.dart';

@riverpod
ImportAiService importAiService(final ImportAiServiceRef ref) {
  final String apiKey = dotenv.env['GEMINI_API_KEY'] ?? '';
  return ImportAiService(apiKey);
}

class ImportAiService {
  final GenerativeModel _model;

  ImportAiService(final String apiKey)
      : _model = GenerativeModel(
          model: 'gemini-1.5-flash',
          apiKey: apiKey,
        );

  Future<Map<String, String>> suggestMappings({
    required final List<String> userHeaders,
    required final List<String> systemFields,
  }) async {
    final prompt = '''
    You are a data migration expert. 
    Map the following user CSV headers to the system's internal field names.
    
    User Headers: ${userHeaders.join(', ')}
    System Fields: ${systemFields.join(', ')}
    
    Instructions:
    1. Perform semantic matching (e.g., "Item Name" -> "name", "Inventory" -> "stock").
    2. If a header doesn't match any system field, exclude it.
    3. Return ONLY a JSON map where keys are User Headers and values are System Fields.
    4. Format: {"Header1": "field1", "Header2": "field2"}
    ''';

    try {
      final content = [Content.text(prompt)];
      final response = await _model.generateContent(content);
      final String? text = response.text;
      if (text == null) return {};

      // Cleanup response (remove markdown code blocks if any)
      final cleanText = text.replaceAll('```json', '').replaceAll('```', '').trim();
      return Map<String, String>.from(jsonDecode(cleanText));
    } catch (e) {
      return {};
    }
  }
}
