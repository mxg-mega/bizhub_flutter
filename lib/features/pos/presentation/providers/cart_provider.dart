import 'package:riverpod_annotation/riverpod_annotation.dart';
import 'package:uuid/uuid.dart';
import '../../../../shared/providers/auth_provider.dart';
import '../../../inventory/data/repositories/product_repository_impl.dart';
import '../../data/models/sale_model.dart';
import '../../data/models/sale_item_model.dart';
import '../../data/repositories/customer_repository_impl.dart';
import '../../data/repositories/pos_repository_impl.dart';
import '../../../inventory/data/models/product_model.dart';
import '../../../inventory/domain/services/inventory_service.dart';
import '../../../../core/database/isar_service.dart';
import '../../../../core/services/sync_service.dart';
import '../../../../core/models/transaction_model.dart';

part 'cart_provider.g.dart';

class CartState {
  final List<SaleItemModel> items;
  final double discount;
  final double taxRate;
  final String? customerId;

  const CartState({
    this.items = const [],
    this.discount = 0.0,
    this.taxRate = 0.0,
    this.customerId,
  });

  double get subtotal => items.fold(0, (final sum, final item) => sum + item.totalPrice);
  double get taxAmount => subtotal * taxRate;
  double get total => subtotal + taxAmount - discount;

  CartState copyWith({
    final List<SaleItemModel>? items,
    final double? discount,
    final double? taxRate,
    final String? customerId,
    final bool clearCustomer = false,
  }) => CartState(
      items: items ?? this.items,
      discount: discount ?? this.discount,
      taxRate: taxRate ?? this.taxRate,
      customerId: clearCustomer ? null : (customerId ?? this.customerId),
    );
}

@riverpod
class Cart extends _$Cart {
  @override
  CartState build() => const CartState();

  void setCustomer(final String? id) => state = state.copyWith(customerId: id, clearCustomer: id == null);

  void addItem(final ProductModel product, final String unit, final double quantity) {
    final unitPrice = product.calculatePriceForUnit(unit);
    final existingIndex = state.items.indexWhere((final i) => i.productId == product.id && i.unit == unit);

    if (existingIndex >= 0) {
      final existing = state.items[existingIndex];
      final updatedItem = SaleItemModel(
        productId: existing.productId,
        name: existing.name,
        quantity: existing.quantity + quantity,
        unit: existing.unit,
        unitPrice: unitPrice,
        totalPrice: (existing.quantity + quantity) * unitPrice,
      );
      final newItems = List<SaleItemModel>.from(state.items);
      newItems[existingIndex] = updatedItem;
      state = state.copyWith(items: newItems);
    } else {
      final newItem = SaleItemModel(
        productId: product.id,
        name: product.name,
        quantity: quantity,
        unit: unit,
        unitPrice: unitPrice,
        totalPrice: quantity * unitPrice,
      );
      state = state.copyWith(items: [...state.items, newItem]);
    }
  }

  void removeItem(final String productId, final String unit) {
    state = state.copyWith(
      items: state.items.where((final i) => !(i.productId == productId && i.unit == unit)).toList(),
    );
  }

  void clear() => state = const CartState();

  Future<SaleModel> checkout(final String paymentMethod, final String locationId, {final bool isDraft = false}) async {
    final authState = ref.read(authProvider);
    final business = authState.activeBusiness;
    final user = authState.user;

    if (business == null || user == null) throw Exception('Auth context missing');
    if (state.items.isEmpty) throw Exception('Cart is empty');

    final workflowEnabled = business.settings?['requireApproval'] ?? false;
    String status = isDraft ? 'Draft' : (workflowEnabled ? 'PendingPayment' : 'Paid');
    if (paymentMethod == 'on_credit') status = 'Pending';

    final sale = SaleModel(
      id: const Uuid().v4(),
      businessId: business.id!,
      userId: user.id,
      customerId: state.customerId,
      customer: state.customerName,
      items: state.items,
      subtotal: state.subtotal,
      tax: state.taxAmount,
      discount: state.discount,
      totalAmount: state.total,
      paymentMethod: paymentMethod,
      timestamp: DateTime.now(),
      createdAt: DateTime.now(),
      locationId: locationId,
      status: status,
      workflow: SaleWorkflowModel(
        enabled: workflowEnabled,
        createdBy: user.id,
        createdByName: user.name ?? 'Unknown',
        history: [
          SaleWorkflowStage(status: status, timestamp: DateTime.now(), actorId: user.id, notes: 'Sale created'),
        ],
      ),
    );

    await ref.read(posRepositoryProvider).saveSale(sale);

    if (status == 'Paid' || status == 'Pending') {
      if (paymentMethod == 'on_credit' && state.customerId != null) {
        await ref.read(customerRepositoryProvider).updateBalance(state.customerId!, sale.total);
      }

      final financialTransaction = TransactionModel(
        id: const Uuid().v4(),
        businessId: business.id!,
        type: 'income',
        amount: sale.total,
        category: FinancialCategory.revenue,
        timestamp: DateTime.now(),
        description: 'POS Sale #${sale.id.substring(0, 8).toUpperCase()}',
        referenceId: sale.id,
        paymentMethod: paymentMethod,
      );

      final isar = ref.read(isarDatabaseProvider).value!;
      await isar.writeTxn(() async => await isar.transactionModels.put(financialTransaction));
      await ref.read(syncServiceProvider).addToQueue(
        action: 'create',
        collectionPath: 'businesses/${business.id}/transactions',
        docId: financialTransaction.id,
        payload: financialTransaction.toJson(),
      );

      final inventoryService = ref.read(inventoryServiceProvider);
      final productRepo = ref.read(productRepositoryProvider);

      for (final item in state.items) {
        final product = await productRepo.getProduct(business.id!, item.productId);
        if (product == null) continue;

        double delta = item.quantity;
        if (product.unitChain != null) {
          final factor = product.unitChain!.getFactor(item.unit, product.unitChain!.baseUnit ?? '');
          delta = item.quantity * factor;
        }

        await inventoryService.incrementStock(
          businessId: business.id!,
          productId: item.productId,
          locationId: locationId,
          delta: -delta,
          userId: user.id,
          reason: 'Sale #${sale.id.substring(0, 8)}',
          type: 'sale',
        );
      }
    }

    final finalizedSale = sale;
    clear();
    return finalizedSale;
  }
}
