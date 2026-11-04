import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import 'package:uuid/uuid.dart';
import '../providers/expense_providers.dart';
import '../../data/models/expense_model.dart';
import '../../../../shared/providers/auth_provider.dart';
import '../../../../shared/presentation/widgets/common_app_bar.dart';

class ExpensesPage extends ConsumerWidget {
  const ExpensesPage({super.key});

  @override
  Widget build(final BuildContext context, final WidgetRef ref) {
    final expensesAsync = ref.watch(expenseListProvider);

    return Scaffold(
      appBar: const CommonAppBar(),
      body: RefreshIndicator(
        onRefresh: () async => ref.invalidate(expenseListProvider),
        child: expensesAsync.when(
          data: (final expenses) => _buildExpenseList(context, ref, expenses),
          loading: () => const Center(child: CircularProgressIndicator()),
          error: (final e, _) => Center(child: Text('Error: $e')),
        ),
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => _showAddExpenseSheet(context, ref),
        label: const Text('Record Expense'),
        icon: const Icon(Icons.add),
      ),
    );
  }

  Widget _buildExpenseList(final BuildContext context, final WidgetRef ref, final List<ExpenseModel> expenses) {
    if (expenses.isEmpty) {
      return const Center(child: Text('No expenses recorded yet.'));
    }

    final total = expenses.fold(0.0, (final sum, final e) => sum + e.amount);

    return Column(
      children: [
        _buildSummaryHeader(total),
        Expanded(
          child: ListView.builder(
            padding: EdgeInsets.all(16.w),
            itemCount: expenses.length,
            itemBuilder: (final context, final index) {
              final expense = expenses[index];
              return _ExpenseCard(expense: expense);
            },
          ),
        ),
      ],
    );
  }

  Widget _buildSummaryHeader(final double total) => Container(
      padding: EdgeInsets.all(24.w),
      width: double.infinity,
      color: Colors.red[50],
      child: Column(
        children: [
          Text('Total Expenses', style: TextStyle(color: Colors.red[700], fontSize: 14.sp)),
          Text('\$${total.toStringAsFixed(2)}', style: GoogleFonts.inter(fontSize: 28.sp, fontWeight: FontWeight.bold, color: Colors.red[900])),
        ],
      ),
    );

  void _showAddExpenseSheet(final BuildContext context, final WidgetRef ref) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      builder: (final context) => _AddExpenseForm(),
    );
  }
}

class _AddExpenseForm extends ConsumerStatefulWidget {
  @override
  ConsumerState<_AddExpenseForm> createState() => _AddExpenseFormState();
}

class _AddExpenseFormState extends ConsumerState<_AddExpenseForm> {
  final _amountController = TextEditingController();
  final _descController = TextEditingController();
  String _category = 'General';
  final List<String> _categories = ['Rent', 'Salaries', 'Utilities', 'Inventory', 'General', 'Marketing'];

  @override
  Widget build(final BuildContext context) => Padding(
      padding: EdgeInsets.all(24.w).copyWith(bottom: MediaQuery.of(context).viewInsets.bottom + 24.w),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text('Record Business Expense', style: GoogleFonts.inter(fontSize: 18.sp, fontWeight: FontWeight.bold)),
          SizedBox(height: 24.h),
          TextField(
            controller: _amountController,
            keyboardType: TextInputType.number,
            decoration: const InputDecoration(labelText: 'Amount', prefixText: '\$ '),
          ),
          SizedBox(height: 16.h),
          DropdownButtonFormField<String>(
            initialValue: _category,
            items: _categories.map((final c) => DropdownMenuItem(value: c, child: Text(c))).toList(),
            onChanged: (final val) => setState(() => _category = val!),
            decoration: const InputDecoration(labelText: 'Category'),
          ),
          SizedBox(height: 16.h),
          TextField(
            controller: _descController,
            decoration: const InputDecoration(labelText: 'Description (Optional)'),
          ),
          SizedBox(height: 24.h),
          SizedBox(
            width: double.infinity,
            height: 50.h,
            child: ElevatedButton(
              onPressed: () async {
                final amount = double.tryParse(_amountController.text);
                final businessId = ref.read(currentBusinessProvider)?.id;
                if (amount != null && businessId != null) {
                  final expense = ExpenseModel(
                    id: const Uuid().v4(),
                    businessId: businessId,
                    category: _category,
                    amount: amount,
                    date: DateTime.now(),
                    description: _descController.text,
                  );
                  await ref.read(expenseActionsProvider.notifier).saveExpense(expense);
                  if (mounted) Navigator.pop(context);
                }
              },
              child: const Text('Save Expense'),
            ),
          ),
        ],
      ),
    );
}

class _ExpenseCard extends StatelessWidget {
  final ExpenseModel expense;
  const _ExpenseCard({required this.expense});

  @override
  Widget build(final BuildContext context) => Card(
      elevation: 0,
      margin: EdgeInsets.only(bottom: 12.h),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12.r), side: BorderSide(color: Colors.grey[200]!)),
      child: ListTile(
        leading: CircleAvatar(backgroundColor: Colors.red[50], child: const Icon(Icons.outbound_outlined, color: Colors.red, size: 20)),
        title: Text(expense.category, style: const TextStyle(fontWeight: FontWeight.bold)),
        subtitle: Text(DateFormat('MMM dd, yyyy').format(expense.date)),
        trailing: Text('-\$${expense.amount.toStringAsFixed(2)}', style: const TextStyle(color: Colors.red, fontWeight: FontWeight.bold)),
      ),
    );
}
