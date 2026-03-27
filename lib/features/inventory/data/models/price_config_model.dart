import 'package:json_annotation/json_annotation.dart';
import '../../../../core/utils/datetime_converter.dart';

part 'price_config_model.g.dart';

@JsonSerializable()
class PriceConfigModel {
  final String? unit;
  final double? price;
  @JsonKey(name: 'isAutoCalculated')
  final bool? isAutoCalculated;
  @JsonKey(name: 'isDefault')
  final bool? isDefault;
  @JsonKey(name: 'markupPercent')
  final double? markupPercent;
  @JsonKey(name: 'previousAutoPrice')
  final double? previousAutoPrice;
  
  @DateTimeConverter()
  final DateTime? lastUpdated;

  const PriceConfigModel({
    this.unit,
    this.price,
    this.isAutoCalculated = true,
    this.isDefault = false,
    this.markupPercent = 0.0,
    this.previousAutoPrice,
    this.lastUpdated,
  });

  factory PriceConfigModel.fromJson(final Map<String, dynamic> json) =>
      _$PriceConfigModelFromJson(json);

  Map<String, dynamic> toJson() => _$PriceConfigModelToJson(this);
}
