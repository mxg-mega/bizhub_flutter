import 'package:json_annotation/json_annotation.dart';

part 'currency_model.g.dart';

@JsonSerializable()
class CurrencyModel {
  final String code; // 'USD', 'NGN'
  final String symbol; // '$', '₦'
  final double rateToBase; // e.g. 1.0 for base, 1500.0 for NGN if base is USD
  final bool isBase;

  const CurrencyModel({
    required this.code,
    required this.symbol,
    this.rateToBase = 1.0,
    this.isBase = false,
  });

  factory CurrencyModel.fromJson(final Map<String, dynamic> json) =>
      _$CurrencyModelFromJson(json);
  Map<String, dynamic> toJson() => _$CurrencyModelToJson(this);
}
