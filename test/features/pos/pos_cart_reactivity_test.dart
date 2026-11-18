import 'package:flutter_test/flutter_test.dart';
import 'package:biz_module/features/inventory/data/models/product_model.dart';
import 'package:biz_module/features/inventory/data/models/unit_chain_model.dart';
import 'package:biz_module/features/inventory/data/models/unit_conversion_model.dart';
import 'package:biz_module/features/pos/data/models/sale_item_model.dart';
import 'package:biz_module/features/pos/presentation/pages/pos_page.dart';
import 'package:biz_module/features/pos/presentation/providers/cart_provider.dart';

ProductModel _product({
  required final double stock,
  final UnitChainModel? unitChain,
}) => ProductModel(
  id: 'rice',
  name: 'Rice 5kg',
  stockByLocation: {'main': stock},
  price: 4500,
  cost: 3500,
  unitChain: unitChain,
);

SaleItemModel _item({
  required final double quantity,
  final String unit = 'Piece',
  final double unitPrice = 4500,
}) => SaleItemModel(
  productId: 'rice',
  name: 'Rice 5kg',
  quantity: quantity,
  unit: unit,
  unitPrice: unitPrice,
);

void main() {
  group('availableBaseStock', () {
    test('returns full location stock when cart is empty', () {
      expect(availableBaseStock(_product(stock: 8), 'main', const []), 8.0);
    });

    test('decreases immediately as items are added to the cart', () {
      final product = _product(stock: 8);
      expect(availableBaseStock(product, 'main', [_item(quantity: 1)]), 7.0);
      expect(availableBaseStock(product, 'main', [_item(quantity: 3)]), 5.0);
    });

    test('reports zero once reserved quantity exhausts stock', () {
      expect(
        availableBaseStock(_product(stock: 2), 'main', [_item(quantity: 3)]),
        0.0,
      );
    });

    test('converts cart units before comparing with base-unit stock', () {
      final product = _product(
        stock: 20,
        unitChain: const UnitChainModel(
          baseUnit: 'Piece',
          units: ['Piece', 'Pack'],
          conversions: [
            UnitConversionModel(
              from: 'Pack',
              to: 'Piece',
              factor: 10,
              reverseFactor: 0.1,
            ),
          ],
        ),
      );

      expect(
        availableBaseStock(product, 'main', [_item(quantity: 2, unit: 'Pack')]),
        0.0,
      );
    });
  });

  group('CartState', () {
    test(
      'subtotal, tax and total update from the current items immediately',
      () {
        const empty = CartState();
        expect(empty.subtotal, 0.0);
        expect(empty.total, 0.0);

        final withItem = empty.copyWith(items: [_item(quantity: 2)]);
        expect(withItem.subtotal, 9000.0);

        final taxed = withItem.copyWith(taxRate: 0.1);
        expect(taxed.taxAmount, 900.0);
        expect(taxed.total, 9900.0);

        final edited = taxed.copyWith(items: [_item(quantity: 1)]);
        expect(edited.subtotal, 4500.0);
        expect(edited.total, 4950.0);

        final cleared = edited.copyWith(items: const []);
        expect(cleared.total, 0.0);
      },
    );
  });
}
