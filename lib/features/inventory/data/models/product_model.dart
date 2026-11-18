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

  /// Legacy denormalized total. Web type comment: computed, never persisted —
  /// excluded from every write payload (recompute via [totalStock]).
  @JsonKey(includeToJson: false)
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

  /// Enhanced-unit-system template id the web writes (e.g. 'pieces').
  final String? unitChainTemplate;

  /// How many stock-denominated units one PURCHASE unit adds on restock
  /// (web: `qty × conversionFactor`, use-inventory.tsx:564). Web type is a
  /// REQUIRED number — `undefined × n` is NaN and breaks web restock for
  /// Flutter-created products. Always written; derived in fromJson when absent.
  final double conversionFactor;

  final bool isArchived;

  final String? sellingUnit;
  final String? purchaseUnit;

  @DateTimeConverter()
  final DateTime? updatedAt;

  /// Wire format: `yyyy-MM-dd` string (web contract) — see [FlexibleDateConverter].
  @FlexibleDateConverter()
  final DateTime? expirationDate;

  /// Bag unit extensions (web `BagUnitConfig`). Flutter reads/passes through
  /// only — full bag pricing support is deferred.
  final Map<String, dynamic>? bagUnit;

  // --- Soft delete + audit trail (web contract §3.5) ---
  @DateTimeConverter()
  final DateTime? archivedAt;
  final String? archivedBy;
  final String? archivedByName;
  final String? archivedReason;
  final String? createdBy;
  final String? createdByName;
  final String? lastModifiedBy;
  final String? lastModifiedByName;

  /// Fields that must be Firestore Timestamps on the wire (§2).
  /// `expirationDate` deliberately absent — it stays a `yyyy-MM-dd` string.
  static const Set<String> firestoreTimestampFields = {'updatedAt', 'archivedAt'};

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
    this.unitChainTemplate,
    this.conversionFactor = 1.0,
    this.isArchived = false,
    this.sellingUnit,
    this.purchaseUnit,
    this.updatedAt,
    this.expirationDate,
    this.bagUnit,
    this.archivedAt,
    this.archivedBy,
    this.archivedByName,
    this.archivedReason,
    this.createdBy,
    this.createdByName,
    this.lastModifiedBy,
    this.lastModifiedByName,
  });

  double get totalStock =>
      stockByLocation.values.fold(0, (final sum, final val) => sum + val);

  ProductModel copyWith({
    final String? name,
    final String? sku,
    final String? description,
    final String? category,
    final Map<String, double>? stockByLocation,
    final double? stock,
    final List<Map<String, dynamic>>? unitPrices,
    final double? price,
    final double? cost,
    final String? unitSystemVersion,
    final UnitChainModel? unitChain,
    final List<PriceConfigModel>? priceConfigs,
    final String? unitChainTemplate,
    final double? conversionFactor,
    final bool? isArchived,
    final String? sellingUnit,
    final String? purchaseUnit,
    final DateTime? updatedAt,
    final DateTime? expirationDate,
    final Map<String, dynamic>? bagUnit,
    final DateTime? archivedAt,
    final String? archivedBy,
    final String? archivedByName,
    final String? archivedReason,
    final String? createdBy,
    final String? createdByName,
    final String? lastModifiedBy,
    final String? lastModifiedByName,
  }) =>
      ProductModel(
        id: id,
        name: name ?? this.name,
        sku: sku ?? this.sku,
        description: description ?? this.description,
        category: category ?? this.category,
        stockByLocation: stockByLocation ?? this.stockByLocation,
        stock: stock ?? this.stock,
        unitPrices: unitPrices ?? this.unitPrices,
        price: price ?? this.price,
        cost: cost ?? this.cost,
        unitSystemVersion: unitSystemVersion ?? this.unitSystemVersion,
        unitChain: unitChain ?? this.unitChain,
        priceConfigs: priceConfigs ?? this.priceConfigs,
        unitChainTemplate: unitChainTemplate ?? this.unitChainTemplate,
        conversionFactor: conversionFactor ?? this.conversionFactor,
        isArchived: isArchived ?? this.isArchived,
        sellingUnit: sellingUnit ?? this.sellingUnit,
        purchaseUnit: purchaseUnit ?? this.purchaseUnit,
        updatedAt: updatedAt ?? this.updatedAt,
        expirationDate: expirationDate ?? this.expirationDate,
        bagUnit: bagUnit ?? this.bagUnit,
        archivedAt: archivedAt ?? this.archivedAt,
        archivedBy: archivedBy ?? this.archivedBy,
        archivedByName: archivedByName ?? this.archivedByName,
        archivedReason: archivedReason ?? this.archivedReason,
        createdBy: createdBy ?? this.createdBy,
        createdByName: createdByName ?? this.createdByName,
        lastModifiedBy: lastModifiedBy ?? this.lastModifiedBy,
        lastModifiedByName: lastModifiedByName ?? this.lastModifiedByName,
      );

  double calculatePriceForUnit(final String unitName) {
    // 1. Try modern PriceConfigs first
    if (priceConfigs != null && priceConfigs!.isNotEmpty) {
      final config = priceConfigs!.firstWhere(
        (final c) => c.unit == unitName,
        orElse: () => priceConfigs!.first,
      );
      
      if (!(config.isAutoCalculated ?? true)) return config.price ?? 0.0;
      if (unitChain == null) return config.price ?? 0.0;
      
      final baseConfig = priceConfigs!.firstWhere(
        (final c) => c.unit == unitChain!.baseUnit,
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
        (final u) => u['unit'] == unitName,
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
    json['isArchived'] ??= json['is_archived'] ?? false;
    json['cost'] = ((json['cost'] ?? 0.0) as num).toDouble();

    // Web type marks sku/category as REQUIRED strings — never emit null
    json['sku'] ??= '';
    json['category'] ??= '';

    // Normalize stock
    if (!json.containsKey('stockByLocation') || (json['stockByLocation'] as Map).isEmpty) {
      final double legacyStock = ((json['stock'] ?? json['quantity']) as num?)?.toDouble() ?? 0.0;
      json['stockByLocation'] = {'main': legacyStock};
    }
    
    final sellingUnit = json['sellingUnit'] ?? json['purchaseUnit'] ?? 'pcs';
    json['sellingUnit'] ??= sellingUnit;
    json['purchaseUnit'] ??= sellingUnit;

    // Ensure 'price' is present at root (it's 3500 in your JSON)
    json['price'] = (json['price'] ?? json['cost'] ?? 0.0).toDouble();

    // conversionFactor is REQUIRED on the web wire (restock: qty × factor) —
    // derive from the unit chain when absent, else 1.0.
    if (json['conversionFactor'] == null) {
      double derived = 1.0;
      final chain = json['unitChain'];
      final purchaseUnit = json['purchaseUnit'];
      if (chain != null && purchaseUnit != null) {
        try {
          final unitChain = UnitChainModel.fromJson(chain as Map<String, dynamic>);
          final f = unitChain.getFactor(purchaseUnit as String, sellingUnit as String);
          if (f > 0) derived = f;
        } catch (_) {}
      }
      json['conversionFactor'] = derived;
    } else {
      json['conversionFactor'] = ((json['conversionFactor'] ?? 1.0) as num).toDouble();
    }

    // Migrate unitPrices -> priceConfigs if modern configs are missing
    if (json['priceConfigs'] == null && json.containsKey('unitPrices')) {
      final rawList = json['unitPrices'] as List?;
      if (rawList != null) {
        json['priceConfigs'] = rawList.map((final up) {
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
