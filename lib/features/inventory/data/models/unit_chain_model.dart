import 'package:json_annotation/json_annotation.dart';
import '../../../../core/utils/datetime_converter.dart';
import 'unit_conversion_model.dart';

part 'unit_chain_model.g.dart';

@JsonSerializable()
class UnitChainModel {
  final String? id;
  @JsonKey(name: 'baseUnit')
  final String? baseUnit;
  final List<String>? units;
  final List<UnitConversionModel>? conversions;
  final String? template;
  
  @DateTimeConverter()
  final DateTime? createdAt;
  
  @DateTimeConverter()
  final DateTime? updatedAt;

  const UnitChainModel({
    this.id,
    this.baseUnit,
    this.units,
    this.conversions,
    this.template,
    this.createdAt,
    this.updatedAt,
  });

  factory UnitChainModel.fromJson(final Map<String, dynamic> json) =>
      _$UnitChainModelFromJson(json);

  Map<String, dynamic> toJson() => _$UnitChainModelToJson(this);

  double getFactor(final String fromUnit, final String toUnit) {
    if (fromUnit == toUnit) return 1.0;
    if (conversions == null) return 1.0;

    for (final conv in conversions!) {
      if (conv.from == fromUnit && conv.to == toUnit) return conv.factor;
      if (conv.bidirectional && conv.from == toUnit && conv.to == fromUnit) {
        return conv.reverseFactor;
      }
    }
    return 1.0;
  }
}
