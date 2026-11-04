import 'package:riverpod_annotation/riverpod_annotation.dart';
import '../../core/models/currency_model.dart';
import 'auth_provider.dart';

part 'currency_provider.g.dart';

@riverpod
class CurrencyNotifier extends _$CurrencyNotifier {
  @override
  List<CurrencyModel> build() {
    final business = ref.watch(currentBusinessProvider);
    if (business == null) return [_defaultCurrency()];

    // Assume business settings has currencies list
    final List<dynamic>? currenciesJson = business.settings?['currencies'];
    if (currenciesJson == null || currenciesJson.isEmpty) {
      return [_defaultCurrency()];
    }

    return currenciesJson.map((final c) => CurrencyModel.fromJson(c)).toList();
  }

  CurrencyModel _defaultCurrency() => const CurrencyModel(code: 'NGN', symbol: '₦', isBase: true);

  CurrencyModel get baseCurrency => state.firstWhere((final c) => c.isBase, orElse: () => state.first);

  double convert(final double amount, final String fromCode, final String toCode) {
    if (fromCode == toCode) return amount;
    
    final from = state.firstWhere((final c) => c.code == fromCode, orElse: () => _defaultCurrency());
    final to = state.firstWhere((final c) => c.code == toCode, orElse: () => _defaultCurrency());

    // amount * (toRate / fromRate)
    return amount * (to.rateToBase / from.rateToBase);
  }
}

@riverpod
CurrencyModel activeDisplayCurrency(final ActiveDisplayCurrencyRef ref) {
  // For now, return the base currency. Can be updated to allow user to toggle display currency.
  return ref.watch(currencyNotifierProvider.notifier).baseCurrency;
}
