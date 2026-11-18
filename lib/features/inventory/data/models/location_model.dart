import 'package:json_annotation/json_annotation.dart';
import '../../../../core/utils/datetime_converter.dart';

part 'location_model.g.dart';

@JsonSerializable()
class LocationModel {
  final String id;
  final String name;

  /// Web stamps a Timestamp on every update (use-locations.tsx:85-88) —
  /// additive field; queued writes carry an ISO string until M6 sanitizes.
  @DateTimeConverter()
  final DateTime? updatedAt;

  const LocationModel({
    required this.id,
    required this.name,
    this.updatedAt,
  });

  LocationModel copyWith({
    final String? name,
    final DateTime? updatedAt,
  }) =>
      LocationModel(
        id: id,
        name: name ?? this.name,
        updatedAt: updatedAt ?? this.updatedAt,
      );

  factory LocationModel.fromJson(final Map<String, dynamic> json) =>
      _$LocationModelFromJson(json);

  Map<String, dynamic> toJson() => _$LocationModelToJson(this);
}
