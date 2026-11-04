import 'package:isar/isar.dart';

part 'local_models.g.dart';

@collection
class LocalProduct {
  Id get isarId => _fastHash(id);

  @Index(unique: true, replace: true)
  final String id;
  
  @Index(type: IndexType.value)
  final String name;
  
  @Index()
  final String? sku;
  
  final String businessId;
  final bool isArchived;
  final String data;

  LocalProduct({
    required this.id,
    required this.name,
    this.sku,
    required this.businessId,
    required this.isArchived,
    required this.data,
  });

  int _fastHash(final String string) {
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

@collection
class LocalLocation {
  Id get isarId => _fastHash(id);

  @Index(unique: true, replace: true)
  final String id;
  
  final String name;
  final String businessId;
  final String data;

  LocalLocation({
    required this.id,
    required this.name,
    required this.businessId,
    required this.data,
  });

  int _fastHash(final String string) {
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

@collection
class LocalSale {
  Id get isarId => _fastHash(id);

  @Index(unique: true, replace: true)
  final String id;
  
  @Index()
  final String businessId;
  
  @Index()
  final DateTime timestamp;
  
  final double total;
  final String data;

  LocalSale({
    required this.id,
    required this.businessId,
    required this.timestamp,
    required this.total,
    required this.data,
  });

  int _fastHash(final String string) {
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

@collection
class LocalCustomer {
  Id get isarId => _fastHash(id);

  @Index(unique: true, replace: true)
  final String id;
  
  @Index()
  final String businessId;
  
  @Index(type: IndexType.value)
  final String name;
  
  @Index()
  final String? phone;
  
  final String data;

  LocalCustomer({
    required this.id,
    required this.businessId,
    required this.name,
    this.phone,
    required this.data,
  });

  int _fastHash(final String string) {
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
