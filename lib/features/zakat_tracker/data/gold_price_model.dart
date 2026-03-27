import 'package:json_annotation/json_annotation.dart';

part 'gold_price_model.g.dart';

@JsonSerializable()
class GoldPriceModel {
  final double price;
  final DateTime timestamp;
  @JsonKey(name: 'base')
  final String baseCurrency;
  final Map<String, double> rates;

  GoldPriceModel({
    required this.price,
    required this.timestamp,
    required this.baseCurrency,
    required this.rates,
  });

  factory GoldPriceModel.fromJson(final Map<String, dynamic> json) =>
      _$GoldPriceModelFromJson(json);

  Map<String, dynamic> toJson() => _$GoldPriceModelToJson(this);
}

@JsonSerializable()
class GoldPriceResponseModel {
  @JsonKey(name: 'success')
  final bool success;
  final String base;
  /// Some APIs return timestamp as Unix seconds (int), others as ISO string.
  /// json_serializable handles int as DateTime if it's a unix timestamp.
  final int timestamp;
  final Map<String, double> rates;

  GoldPriceResponseModel({
    required this.success,
    required this.base,
    required this.timestamp,
    required this.rates,
  });

  factory GoldPriceResponseModel.fromJson(final Map<String, dynamic> json) =>
      _$GoldPriceResponseModelFromJson(json);

  Map<String, dynamic> toJson() => _$GoldPriceResponseModelToJson(this);
}
