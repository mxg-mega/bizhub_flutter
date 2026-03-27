import 'package:riverpod_annotation/riverpod_annotation.dart';
import '../../data/gold_price_model.dart';
import '../../data/zakat_calculation_model.dart';
import '../../domain/zakat_calculator.dart';
import 'gold_price_provider.dart';

part 'zakat_calculation_provider.g.dart';

@riverpod
class ZakatCalculationFlow extends _$ZakatCalculationFlow {
  @override
  FutureOr<ZakatCalculationResult?> build() => null;

  Future<void> performCalculation({
    required final double cash,
    required final double businessAssets,
    final double? investments,
    final double? otherPreciousMetals,
    final double? inventoryValue,
    required final double liabilities,
    final String currency = 'USD',
  }) async {
    state = const AsyncLoading();

    state = await AsyncValue.guard(() async {
      // 1. Fetch current gold price (standard for business zakat)
      final GoldPriceModel goldPrice = await ref.read(goldPriceProvider(currency: currency).future);

      // 2. Prepare Input
      final ZakatCalculationInput input = ZakatCalculationInput(
        cash: cash,
        businessAssets: businessAssets,
        investments: investments,
        otherPreciousMetals: otherPreciousMetals,
        inventoryValue: inventoryValue,
        liabilities: liabilities,
        currencyCode: currency,
      );

      // 3. Perform Calculation (includes AI insights)
      final calculator = ref.read(zakatCalculatorProvider);
      return await calculator.calculate(
        input: input,
        goldPricePerGram: goldPrice.price / 31.1035, // Convert price per ounce to gram
      );
    });
  }
}
