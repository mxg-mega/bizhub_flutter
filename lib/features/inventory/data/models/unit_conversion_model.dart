import 'package:json_annotation/json_annotation.dart';

part 'unit_conversion_model.g.dart';

@JsonSerializable()
class UnitConversionModel {
  final String from;
  final String to;
  final double factor;
  @JsonKey(name: 'reverseFactor')
  final double reverseFactor;
  final bool bidirectional;
  final String? customName;

  const UnitConversionModel({
    required this.from,
    required this.to,
    required this.factor,
    required this.reverseFactor,
    this.bidirectional = true,
    this.customName,
  });

  factory UnitConversionModel.fromJson(final Map<String, dynamic> json) {
    if (!json.containsKey('reverseFactor') || json['reverseFactor'] == 0.0) {
      final double factor = (json['factor'] as num?)?.toDouble() ?? 1.0;
      json['reverseFactor'] = factor != 0 ? 1.0 / factor : 1.0;
    }
    return _$UnitConversionModelFromJson(json);
  }

  Map<String, dynamic> toJson() => _$UnitConversionModelToJson(this);
}
