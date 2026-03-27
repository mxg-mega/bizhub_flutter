import 'package:json_annotation/json_annotation.dart';

part 'zakat_calculation_model.g.dart';

@JsonSerializable()
class ZakatCalculationInput {
  final double cash;
  @JsonKey(name: 'business_assets')
  final double businessAssets;
  
  /// Stocks, mutual funds, or other tradable financial assets.
  final double? investments;
  
  /// Value of other metals like silver or diamonds (if part of business stock).
  @JsonKey(name: 'other_precious_metals')
  final double? otherPreciousMetals;
  
  /// Value from the future inventory system.
  /// TODO: Integrate with Inventory Module for automated inventory valuation.
  @JsonKey(name: 'inventory_value')
  final double? inventoryValue;

  final double liabilities;
  @JsonKey(name: 'currency_code')
  final String currencyCode;

  @JsonKey(name: 'silver_price_per_gram')
  final double? silverPricePerGram;

  const ZakatCalculationInput({
    required this.cash,
    required this.businessAssets,
    this.investments,
    this.otherPreciousMetals,
    this.inventoryValue,
    required this.liabilities,
    required this.currencyCode,
    this.silverPricePerGram,
  });

  factory ZakatCalculationInput.fromJson(final Map<String, dynamic> json) =>
      _$ZakatCalculationInputFromJson(json);

  Map<String, dynamic> toJson() => _$ZakatCalculationInputToJson(this);
}

@JsonSerializable()
class ZakatCalculationResult {
  @JsonKey(name: 'gold_price_per_gram')
  final double goldPricePerGram;
  @JsonKey(name: 'silver_price_per_gram')
  final double? silverPricePerGram;
  @JsonKey(name: 'nisab_value')
  final double nisabValue;
  @JsonKey(name: 'net_worth')
  final double netWorth;
  @JsonKey(name: 'is_payable')
  final bool isPayable;
  @JsonKey(name: 'zakat_amount')
  final double zakatAmount;
  final String currency;
  final String? insights;
  @JsonKey(name: 'calculation_date')
  final DateTime calculationDate;

  const ZakatCalculationResult({
    required this.goldPricePerGram,
    this.silverPricePerGram,
    required this.nisabValue,
    required this.netWorth,
    required this.isPayable,
    required this.zakatAmount,
    required this.currency,
    this.insights,
    required this.calculationDate,
  });

  factory ZakatCalculationResult.fromJson(final Map<String, dynamic> json) =>
      _$ZakatCalculationResultFromJson(json);

  Map<String, dynamic> toJson() => _$ZakatCalculationResultToJson(this);
}

@JsonSerializable()
class ZakatCalculation {
  final String id;
  @JsonKey(name: 'user_id')
  final String userId;
  final DateTime timestamp;
  final bool? notified;

  // Flattened fields from ZakatCalculationInput
  final double cash;
  @JsonKey(name: 'business_assets')
  final double businessAssets;
  final double? investments;
  @JsonKey(name: 'other_precious_metals')
  final double? otherPreciousMetals;
  @JsonKey(name: 'inventory_value')
  final double? inventoryValue;
  final double liabilities;
  @JsonKey(name: 'currency_code')
  final String currencyCode;

  // Flattened fields from ZakatCalculationResult
  @JsonKey(name: 'gold_price_per_gram')
  final double goldPricePerGram;
  @JsonKey(name: 'silver_price_per_gram')
  final double? silverPricePerGram;
  @JsonKey(name: 'nisab_value')
  final double nisabValue;
  @JsonKey(name: 'net_worth')
  final double netWorth;
  @JsonKey(name: 'is_payable')
  final bool isPayable;
  @JsonKey(name: 'zakat_amount')
  final double zakatAmount;
  final String currency;
  final String? insights;
  @JsonKey(name: 'calculation_date')
  final DateTime calculationDate;

  const ZakatCalculation({
    required this.id,
    required this.userId,
    required this.timestamp,
    this.notified,
    required this.cash,
    required this.businessAssets,
    this.investments,
    this.otherPreciousMetals,
    this.inventoryValue,
    required this.liabilities,
    required this.currencyCode,
    required this.goldPricePerGram,
    this.silverPricePerGram,
    required this.nisabValue,
    required this.netWorth,
    required this.isPayable,
    required this.zakatAmount,
    required this.currency,
    this.insights,
    required this.calculationDate,
  });

  factory ZakatCalculation.fromJson(final Map<String, dynamic> json) =>
      _$ZakatCalculationFromJson(json);

  Map<String, dynamic> toJson() => _$ZakatCalculationToJson(this);
}

@JsonSerializable()
class ZakatHistoryFilter {
  final int? limit;
  @JsonKey(name: 'start_date')
  final DateTime? startDate;
  @JsonKey(name: 'end_date')
  final DateTime? endDate;
  @JsonKey(name: 'is_payable')
  final bool? isPayable;

  const ZakatHistoryFilter({
    this.limit,
    this.startDate,
    this.endDate,
    this.isPayable,
  });

  factory ZakatHistoryFilter.fromJson(final Map<String, dynamic> json) =>
      _$ZakatHistoryFilterFromJson(json);

  Map<String, dynamic> toJson() => _$ZakatHistoryFilterToJson(this);
}
