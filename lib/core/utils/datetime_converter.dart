import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:json_annotation/json_annotation.dart';

class DateTimeConverter implements JsonConverter<DateTime?, dynamic> {
  const DateTimeConverter();

  @override
  DateTime? fromJson(final dynamic json) {
    if (json == null) return null;

    // Handle Firestore Timestamp
    if (json is Timestamp) return json.toDate();

    // Handle DateTime instance
    if (json is DateTime) return json;

    // Handle epoch milliseconds
    if (json is int) return DateTime.fromMillisecondsSinceEpoch(json);

    // Handle ISO 8601 String or formatted date
    if (json is String) {
      if (json.trim().isEmpty) return null;
      return DateTime.tryParse(json);
    }

    return null;
  }

  @override
  dynamic toJson(final DateTime? object) => object?.toIso8601String();
}

/// A converter specifically for models writing directly to Firestore as Timestamps
class FirestoreDateTimeConverter implements JsonConverter<DateTime?, dynamic> {
  const FirestoreDateTimeConverter();

  @override
  DateTime? fromJson(final dynamic json) {
    if (json == null) return null;
    if (json is Timestamp) return json.toDate();
    if (json is DateTime) return json;
    if (json is int) return DateTime.fromMillisecondsSinceEpoch(json);
    if (json is String) {
      if (json.trim().isEmpty) return null;
      return DateTime.tryParse(json);
    }
    return null;
  }

  @override
  dynamic toJson(final DateTime? object) =>
      object == null ? null : Timestamp.fromDate(object);
}
