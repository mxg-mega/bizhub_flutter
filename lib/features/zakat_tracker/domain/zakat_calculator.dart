import 'package:riverpod_annotation/riverpod_annotation.dart';
import '../data/zakat_ai_service.dart';
import '../data/zakat_calculation_model.dart';

part 'zakat_calculator.g.dart';

@riverpod
ZakatCalculator zakatCalculator(final ZakatCalculatorRef ref) {
  final aiService = ref.watch(zakatAiServiceProvider);
  return ZakatCalculator(aiService);
}

class ZakatCalculator {
  final ZakatAiService _aiService;

  ZakatCalculator(this._aiService);

  Future<ZakatCalculationResult> calculate({
    required final ZakatCalculationInput input,
    required final double goldPricePerGram,
    final double? silverPricePerGram,
    final bool useSilverNisab = false,
  }) async {
    final double totalAssets = input.cash +
        input.businessAssets +
        (input.investments ?? 0) +
        (input.otherPreciousMetals ?? 0) +
        (input.inventoryValue ?? 0);

    final double netWorth = totalAssets - input.liabilities;

    double nisabValue;
    if (useSilverNisab && silverPricePerGram != null) {
      nisabValue = silverPricePerGram * 595.0;
    } else {
      nisabValue = goldPricePerGram * 85.0;
    }

    final bool isPayable = netWorth >= nisabValue;
    final double zakatAmount = isPayable ? (netWorth * 0.025) : 0.0;

    final ZakatCalculationResult result = ZakatCalculationResult(
      goldPricePerGram: goldPricePerGram,
      silverPricePerGram: silverPricePerGram,
      nisabValue: nisabValue,
      netWorth: netWorth,
      isPayable: isPayable,
      zakatAmount: zakatAmount,
      currency: input.currencyCode,
      calculationDate: DateTime.now(),
    );

    try {
      final String insights = await _aiService.generateZakatInsights(
        input: input,
        result: result,
      );
      
      return ZakatCalculationResult(
        goldPricePerGram: result.goldPricePerGram,
        silverPricePerGram: result.silverPricePerGram,
        nisabValue: result.nisabValue,
        netWorth: result.netWorth,
        isPayable: result.isPayable,
        zakatAmount: result.zakatAmount,
        currency: result.currency,
        insights: insights,
        calculationDate: result.calculationDate,
      );
    } catch (e) {
      return result;
    }
  }
}
