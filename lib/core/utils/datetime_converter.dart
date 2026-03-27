import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:json_annotation/json_annotation.dart';

class DateTimeConverter implements JsonConverter<DateTime?, dynamic> {
  const DateTimeConverter();

  @override
  DateTime? fromJson(dynamic json) {
    if (json == null) return null;
    
    // Handle Firestore Timestamp
    if (json is Timestamp) return json.toDate();
    
    // Handle ISO 8601 String or formatted date
    if (json is String) {
      if (json.trim().isEmpty) return null;
      return DateTime.tryParse(json);
    }
    
    return null;
  }

  @override
  dynamic toJson(DateTime? object) => object?.toIso8601String();
}
