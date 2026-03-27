import '../../data/models/expense_model.dart';

abstract class ExpenseRepository {
  Future<void> saveExpense(final ExpenseModel expense);
  Future<List<ExpenseModel>> getExpenses(final String businessId);
  Future<void> deleteExpense(final String businessId, final String id);
}
