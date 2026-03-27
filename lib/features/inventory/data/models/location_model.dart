import 'package:json_annotation/json_annotation.dart';

part 'location_model.g.dart';

@JsonSerializable()
class LocationModel {
  final String id;
  final String name;

  const LocationModel({
    required this.id,
    required this.name,
  });

  factory LocationModel.fromJson(final Map<String, dynamic> json) =>
      _$LocationModelFromJson(json);

  Map<String, dynamic> toJson() => _$LocationModelToJson(this);
}
