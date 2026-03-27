import 'package:biz_module/features/inventory/data/models/unit_chain_model.dart';
import 'package:biz_module/features/inventory/data/models/unit_conversion_model.dart';
import 'package:biz_module/features/inventory/domain/services/unit_conversion_service.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  late UnitConversionService service;
  late UnitChainModel retailChain;

  setUp(() {
    service = UnitConversionService();

    // Create a chain: Carton (6) -> Box (12) -> Piece
    retailChain = UnitChainModel(
      id: 'retail_chain',
      baseUnit: 'carton',
      units: const ['carton', 'box', 'piece'],
      conversions: const [
        UnitConversionModel(
          from: 'carton',
          to: 'box',
          factor: 6.0,
          reverseFactor: 1 / 6,
          bidirectional: true,
        ),
        UnitConversionModel(
          from: 'box',
          to: 'piece',
          factor: 12.0,
          reverseFactor: 1 / 12,
          bidirectional: true,
        ),
      ],
      template: 'retail',
      createdAt: DateTime(2024),
      updatedAt: DateTime(2024),
    );
  });

  group('UnitConversionService BFS Pathfinder', () {
    test('calculateFactor: Same unit should return 1.0', () {
      expect(service.calculateFactor(retailChain, 'box', 'box'), 1.0);
    });

    test('calculateFactor: Direct forward conversion (Carton -> Box)', () {
      expect(service.calculateFactor(retailChain, 'carton', 'box'), 6.0);
    });

    test('calculateFactor: Direct inverse conversion (Box -> Carton)', () {
      expect(service.calculateFactor(retailChain, 'box', 'carton'), closeTo(0.166666, 0.000001));
    });

    test('calculateFactor: Transitive forward conversion (Carton -> Piece)', () {
      // 1 Carton = 6 Boxes * 12 Pieces = 72 Pieces
      expect(service.calculateFactor(retailChain, 'carton', 'piece'), 72.0);
    });

    test('calculateFactor: Transitive inverse conversion (Piece -> Carton)', () {
      // 1 Piece = 1/72 Carton
      expect(service.calculateFactor(retailChain, 'piece', 'carton'), closeTo(1 / 72, 0.000001));
    });

    test('calculateFactor: Should throw exception for unreachable units', () {
      final isolatedChain = UnitChainModel(
        id: 'isolated',
        baseUnit: 'A',
        units: const ['A', 'B', 'C'],
        conversions: const [
          UnitConversionModel(from: 'A', to: 'B', factor: 2, reverseFactor: 0.5),
          // C is isolated
        ],
        template: 'test',
        createdAt: DateTime(2024),
        updatedAt: DateTime(2024),
      );

      expect(() => service.calculateFactor(isolatedChain, 'A', 'C'), throwsException);
    });
  });
}
