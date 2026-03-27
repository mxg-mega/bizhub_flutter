import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:google_generative_ai/google_generative_ai.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';
import 'zakat_calculation_model.dart';

part 'zakat_ai_service.g.dart';

@riverpod
ZakatAiService zakatAiService(final ZakatAiServiceRef ref) {
  final String apiKey = dotenv.env['GEMINI_API_KEY'] ?? '';
  return ZakatAiService(apiKey);
}

class ZakatAiService {
  final GenerativeModel _model;

  ZakatAiService(final String apiKey)
      : _model = GenerativeModel(
          model: 'gemini-3-flash-preview',
          apiKey: apiKey,
        );

  Future<String> generateZakatInsights({
    required final ZakatCalculationInput input,
    required final ZakatCalculationResult result,
  }) async {
    final prompt = '''
    You are an expert Islamic Financial Advisor. 
    Analyze the following Zakat calculation for a business owner and provide a concise, high-signal insight (max 100 words).
    
    Inputs:
    - Cash: ${input.cash} ${input.currencyCode}
    - Business Assets: ${input.businessAssets} ${input.currencyCode}
    - Investments: ${input.investments ?? 0} ${input.currencyCode}
    - Precious Metals: ${input.otherPreciousMetals ?? 0} ${input.currencyCode}
    - Liabilities: ${input.liabilities} ${input.currencyCode}
    
    Calculation Result:
    - Net Worth: ${result.netWorth} ${result.currency}
    - Nisab Threshold: ${result.nisabValue} ${result.currency}
    - Is Payable: ${result.isPayable}
    - Zakat Amount (2.5%): ${result.zakatAmount} ${result.currency}
    
    Instructions:
    1. If Zakat is payable, congratulate them and offer a brief tip on purifying wealth.
    2. If not payable, encourage them on their journey and mention how close they are to the Nisab.
    3. Analyze the ratio of assets to liabilities briefly if it stands out.
    4. Maintain a professional, empathetic, and religiously-respectful tone.
    5. Output ONLY the insight text.
    ''';

    try {
      final content = [Content.text(prompt)];
      final response = await _model.generateContent(content);
      return response.text ?? 'Unable to generate insights at this time.';
    } catch (e) {
      return 'Error generating AI insights: $e';
    }
  }
}
