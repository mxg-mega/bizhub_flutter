import 'package:json_annotation/json_annotation.dart';
import 'price_config_model.dart';
import 'unit_chain_model.dart';
import '../../../../core/utils/datetime_converter.dart';

part 'product_model.g.dart';

@JsonSerializable()
class ProductModel {
  final String id;
  final String name;
  final String? sku;
  final String? description;
  final String? category;

  @JsonKey(name: 'stockByLocation')
  final Map<String, double> stockByLocation;

  final double? stock;
  
  /// Legacy pricing list
  final List<Map<String, dynamic>>? unitPrices;
  
  /// Base price for display and calculation
  final double price;
  
  final double cost;

  @JsonKey(name: 'unitSystemVersion')
  final String unitSystemVersion;

  final UnitChainModel? unitChain;
  final List<PriceConfigModel>? priceConfigs;
  final bool isArchived;
  
  final String? sellingUnit;
  final String? purchaseUnit;

  @DateTimeConverter()
  final DateTime? updatedAt;

  @DateTimeConverter()
  final DateTime? expirationDate;

  const ProductModel({
    required this.id,
    required this.name,
    this.sku,
    this.description,
    this.category,
    required this.stockByLocation,
    this.stock,
    this.unitPrices,
    this.price = 0.0,
    required this.cost,
    this.unitSystemVersion = 'enhanced',
    this.unitChain,
    this.priceConfigs,
    this.isArchived = false,
    this.sellingUnit,
    this.purchaseUnit,
    this.updatedAt,
    this.expirationDate,
  });

  double get totalStock =>
      stockByLocation.values.fold(0, (sum, val) => sum + val);

  double calculatePriceForUnit(final String unitName) {
    // 1. Try modern PriceConfigs first
    if (priceConfigs != null && priceConfigs!.isNotEmpty) {
      final config = priceConfigs!.firstWhere(
        (c) => c.unit == unitName,
        orElse: () => priceConfigs!.first,
      );
      
      if (!(config.isAutoCalculated ?? true)) return config.price ?? 0.0;
      if (unitChain == null) return config.price ?? 0.0;
      
      final baseConfig = priceConfigs!.firstWhere(
        (c) => c.unit == unitChain!.baseUnit,
        orElse: () => priceConfigs!.first,
      );
      
      final factor = unitChain!.getFactor(unitChain!.baseUnit ?? '', unitName);
      return factor != 0
          ? (baseConfig.price ?? 0.0) / factor
          : (baseConfig.price ?? 0.0);
    }

    // 2. Fallback to Legacy UnitPrices
    if (unitPrices != null && unitPrices!.isNotEmpty) {
      final match = unitPrices!.firstWhere(
        (u) => u['unit'] == unitName,
        orElse: () => unitPrices!.first,
      );
      return (match['price'] as num?)?.toDouble() ?? 0.0;
    }

    // 3. Last resort: Root price
    return price;
  }

  factory ProductModel.fromJson(final Map<String, dynamic> json) {
    // --- Pre-Serialization Interceptor ---
    
    // Normalize basic fields
    json['id'] ??= 'unknown';
    json['name'] ??= 'Unnamed Product';
    json['isArchived'] ??= false;

    // Normalize stock
    if (!json.containsKey('stockByLocation') || (json['stockByLocation'] as Map).isEmpty) {
      final double legacyStock = ((json['stock'] ?? json['quantity']) as num?)?.toDouble() ?? 0.0;
      json['stockByLocation'] = {'main': legacyStock};
    }
    
    final sellingUnit = json['sellingUnit'] ?? json['purchaseUnit'] ?? 'pcs';
    
    // Ensure 'price' is present at root (it's 3500 in your JSON)
    json['price'] = (json['price'] ?? json['cost'] ?? 0.0).toDouble();

    // Migrate unitPrices -> priceConfigs if modern configs are missing
    if (json['priceConfigs'] == null && json.containsKey('unitPrices')) {
      final rawList = json['unitPrices'] as List?;
      if (rawList != null) {
        json['priceConfigs'] = rawList.map((up) {
          final map = up as Map<String, dynamic>;
          return {
            'unit': map['unit'] ?? sellingUnit,
            'price': (map['price'] as num?)?.toDouble() ?? json['price'],
            'isAutoCalculated': false,
            'isDefault': map['isDefault'] ?? false,
            'lastUpdated': DateTime.now().toIso8601String(),
          };
        }).toList();
      }
    }

    // If still no priceConfigs, create one from root price
    if (json['priceConfigs'] == null || (json['priceConfigs'] as List).isEmpty) {
       json['priceConfigs'] = [{
         'unit': sellingUnit,
         'price': json['price'],
         'isAutoCalculated': false,
         'isDefault': true,
         'lastUpdated': DateTime.now().toIso8601String(),
       }];
    }

    return _$ProductModelFromJson(json);
  }

  Map<String, dynamic> toJson() => _$ProductModelToJson(this);
}
