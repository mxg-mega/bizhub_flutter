import 'package:riverpod_annotation/riverpod_annotation.dart';

import '../../../../shared/providers/auth_provider.dart';
import '../../data/models/expense_model.dart';
import '../../data/repositories/expense_repository_impl.dart';


part 'expense_providers.g.dart';

@riverpod
Future<List<ExpenseModel>> expenseList(final ExpenseListRef ref) {
  final businessId = ref.watch(currentBusinessProvider)?.id;
  if (businessId == null) return Future.value([]);
  return ref.watch(expenseRepositoryProvider).getExpenses(businessId);
}

@riverpod
class ExpenseActions extends _$ExpenseActions {
  @override
  AsyncValue<void> build() => const AsyncValue.data(null);

  Future<void> saveExpense(final ExpenseModel expense) async {
    state = const AsyncValue.loading();
    state = await AsyncValue.guard(() async {
      await ref.read(expenseRepositoryProvider).saveExpense(expense);
      ref.invalidate(expenseListProvider);
    });
  }

  Future<void> deleteExpense(final String expenseId) async {
    final businessId = ref.read(currentBusinessProvider)?.id;
    if (businessId == null) return;

    state = const AsyncValue.loading();
    state = await AsyncValue.guard(() async {
      await ref.read(expenseRepositoryProvider).deleteExpense(businessId, expenseId);
      ref.invalidate(expenseListProvider);
    });
  }
}
