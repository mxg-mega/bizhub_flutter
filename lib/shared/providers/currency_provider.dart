import 'package:riverpod_annotation/riverpod_annotation.dart';
import '../../core/models/currency_model.dart';
import 'auth_provider.dart';

part 'currency_provider.g.dart';

const Map<String, String> kCurrencySymbols = {
  'USD': '\$',
  'NGN': '₦',
  'EUR': '€',
  'GBP': '£',
  'KES': 'KSh',
  'GHS': 'GH₵',
  'CAD': 'CA\$',
  'AUD': 'A\$',
  'ZAR': 'R',
  'INR': '₹',
  'AED': 'AED',
  'JPY': '¥',
  'CNY': '¥',
};

String getCurrencySymbol(final String code) =>
    kCurrencySymbols[code.toUpperCase()] ?? code;

@riverpod
class CurrencyNotifier extends _$CurrencyNotifier {
  @override
  List<CurrencyModel> build() {
    final business = ref.watch(currentBusinessProvider);
    final baseCode = business?.currency ?? 'NGN';

    // Assume business settings has currencies list
    final List<dynamic>? currenciesJson = business?.settings?['currencies'];
    if (currenciesJson == null || currenciesJson.isEmpty) {
      return [
        CurrencyModel(
          code: baseCode,
          symbol: getCurrencySymbol(baseCode),
          isBase: true,
          rateToBase: 1.0,
        ),
      ];
    }

    return currenciesJson.map((final c) => CurrencyModel.fromJson(c)).toList();
  }

  CurrencyModel _defaultCurrency() {
    final business = ref.read(currentBusinessProvider);
    final baseCode = business?.currency ?? 'NGN';
    return CurrencyModel(
      code: baseCode,
      symbol: getCurrencySymbol(baseCode),
      isBase: true,
      rateToBase: 1.0,
    );
  }

  CurrencyModel get baseCurrency =>
      state.firstWhere((final c) => c.isBase, orElse: () => state.first);

  double convert(
    final double amount,
    final String fromCode,
    final String toCode,
  ) {
    if (fromCode == toCode) return amount;

    final from = state.firstWhere(
      (final c) => c.code == fromCode,
      orElse: () => _defaultCurrency(),
    );
    final to = state.firstWhere(
      (final c) => c.code == toCode,
      orElse: () => _defaultCurrency(),
    );

    // amount * (toRate / fromRate)
    return amount * (to.rateToBase / from.rateToBase);
  }
}

@riverpod
CurrencyModel activeDisplayCurrency(final ActiveDisplayCurrencyRef ref) {
  // For now, return the base currency. Can be updated to allow user to toggle display currency.
  return ref.watch(currencyNotifierProvider.notifier).baseCurrency;
}
