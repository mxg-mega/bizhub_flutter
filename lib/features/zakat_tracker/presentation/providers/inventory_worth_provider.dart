import 'package:riverpod_annotation/riverpod_annotation.dart';
import '../../../inventory/presentation/providers/inventory_providers.dart';

part 'inventory_worth_provider.g.dart';

@riverpod
Future<double> totalInventoryWorth(final TotalInventoryWorthRef ref) async {
  final products = await ref.watch(productListProvider.future);
  
  double total = 0.0;
  for (final product in products) {
    // We use the root price (base price) for Zakat calculation of business assets
    total += (product.price * product.totalStock);
  }
  
  return total;
}
