import 'package:isar/isar.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';
import 'package:uuid/uuid.dart';
import '../../../../core/database/isar_service.dart';
import '../../../../core/services/sync_service.dart';
import '../../../../core/models/transaction_model.dart';
import '../../domain/repositories/expense_repository.dart';
import '../models/expense_model.dart';

part 'expense_repository_impl.g.dart';

@riverpod
ExpenseRepository expenseRepository(final ExpenseRepositoryRef ref) {
  final isar = ref.watch(isarDatabaseProvider).value;
  final syncService = ref.watch(syncServiceProvider);
  if (isar == null) throw Exception('Isar not initialized');
  return ExpenseRepositoryImpl(isar, syncService);
}

class ExpenseRepositoryImpl implements ExpenseRepository {
  final Isar _isar;
  final SyncService _syncService;

  ExpenseRepositoryImpl(this._isar, this._syncService);

  String _getExpensesPath(final String businessId) => 'businesses/$businessId/expenses';
  String _getTransactionsPath(final String businessId) => 'businesses/$businessId/transactions';

  @override
  Future<void> saveExpense(final ExpenseModel expense) async {
    // 1. Save Expense locally
    await _isar.writeTxn(() async => await _isar.expenseModels.put(expense));

    // 2. Create and Save Financial Transaction locally
    final tx = TransactionModel(
      id: const Uuid().v4(),
      businessId: expense.businessId,
      type: 'Expense',
      amount: expense.amount,
      category: FinancialCategory.opex,
      subCategory: expense.category,
      createdAt: expense.date,
      date: expense.date,
      description: expense.description ?? 'Expense: ${expense.category}',
      referenceId: expense.id,
    );
    await _isar.writeTxn(() async => await _isar.transactionModels.put(tx));

    // 3. Queue both for sync
    await _syncService.addToQueue(
      action: 'create',
      collectionPath: _getExpensesPath(expense.businessId),
      docId: expense.id,
      payload: expense.toJson(),
    );
    await _syncService.addToQueue(
      action: 'create',
      collectionPath: _getTransactionsPath(expense.businessId),
      docId: tx.id,
      payload: tx.toJson(),
    );
  }

  @override
  Future<List<ExpenseModel>> getExpenses(final String businessId) async {
    final locals = await _isar.expenseModels
        .where()
        .filter()
        .businessIdEqualTo(businessId)
        .sortByDateDesc()
        .findAll();
    
    // Background pull
    _syncService.pull<ExpenseModel>(
      businessId: businessId,
      collectionPath: _getExpensesPath(businessId),
      fromJsons: (final jsons) => jsons.map((final j) => ExpenseModel.fromJson(j)).toList(),
    );

    return locals;
  }

  @override
  Future<void> deleteExpense(final String businessId, final String id) async {
    final local = await _isar.expenseModels.filter().idEqualTo(id).findFirst();
    if (local != null) {
      await _isar.writeTxn(() async => await _isar.expenseModels.delete(local.isarId));
    }

    await _syncService.addToQueue(
      action: 'delete',
      collectionPath: _getExpensesPath(businessId),
      docId: id,
      payload: {},
    );
  }
}
