import 'package:isar/isar.dart';
import 'package:json_annotation/json_annotation.dart';
import '../../../../core/utils/datetime_converter.dart';

part 'invitation_model.g.dart';

@collection
@JsonSerializable()
class InvitationModel {
  Id get isarId => _fastHash(id);

  final String id;
  final String from; // Admin UID
  final String to; // Recipient Email
  final String role;
  final String businessId;
  final String businessName;
  
  /// 'pending' | 'accepted' | 'expired'
  final String status;
  
  @DateTimeConverter()
  final DateTime createdAt;

  const InvitationModel({
    required this.id,
    required this.from,
    required this.to,
    required this.role,
    required this.businessId,
    required this.businessName,
    this.status = 'pending',
    required this.createdAt,
  });

  factory InvitationModel.fromJson(Map<String, dynamic> json) =>
      _$InvitationModelFromJson(json);
  Map<String, dynamic> toJson() => _$InvitationModelToJson(this);

  int _fastHash(String string) {
    var hash = 0xcbf29ce484222325;
    var i = 0;
    while (i < string.length) {
      final codeUnit = string.codeUnitAt(i++);
      hash ^= codeUnit;
      hash *= 0x100000001b3;
    }
    return hash;
  }
}
