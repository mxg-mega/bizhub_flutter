import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:uuid/uuid.dart';
import 'package:share_plus/share_plus.dart';
import '../../../../shared/providers/auth_provider.dart';
import '../../data/models/customer_model.dart';
import '../../data/models/customer_payment_model.dart';
import '../providers/customer_providers.dart';
import '../providers/sales_providers.dart';
import '../../../../shared/presentation/widgets/common_app_bar.dart';
import '../../../../core/services/receipt/customer_statement_service.dart';

class CustomerManagementPage extends ConsumerWidget {
  const CustomerManagementPage({super.key});

  @override
  Widget build(final BuildContext context, final WidgetRef ref) {
    final customersAsync = ref.watch(customerListProvider);

    return Scaffold(
      appBar: const CommonAppBar(),
      body: RefreshIndicator(
        onRefresh: () async => ref.invalidate(customerListProvider),
        child: customersAsync.when(
          data: (final customers) => _buildCustomerList(context, ref, customers),
          loading: () => const Center(child: CircularProgressIndicator()),
          error: (final e, _) => Center(child: Text('Error: $e')),
        ),
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => _showAddCustomerDialog(context, ref),
        label: const Text('Add Customer'),
        icon: const Icon(Icons.person_add),
      ),
    );
  }

  Widget _buildCustomerList(final BuildContext context, final WidgetRef ref, final List<CustomerModel> customers) {
    if (customers.isEmpty) {
      return const Center(child: Text('No customers found.'));
    }

    return ListView.builder(
      padding: EdgeInsets.all(16.w),
      itemCount: customers.length,
      itemBuilder: (final context, final index) {
        final customer = customers[index];
        return Card(
          margin: EdgeInsets.only(bottom: 12.h),
          elevation: 0,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12.r),
            side: BorderSide(color: Colors.grey[200]!),
          ),
          child: ListTile(
            leading: CircleAvatar(
              backgroundColor: Colors.blue[50],
              child: Text(customer.name[0].toUpperCase(), style: TextStyle(color: Colors.blue[700])),
            ),
            title: Text(customer.name, style: const TextStyle(fontWeight: FontWeight.bold)),
            subtitle: Text(customer.phone ?? 'No phone number'),
            trailing: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    Text(
                      '\$${customer.outstandingBalance.toStringAsFixed(2)}',
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        color: customer.outstandingBalance > 0 ? Colors.red : Colors.green,
                      ),
                    ),
                    Text('Balance', style: TextStyle(fontSize: 10.sp, color: Colors.grey)),
                  ],
                ),
                SizedBox(width: 8.w),
                IconButton(
                  icon: const Icon(Icons.payment, color: Colors.green),
                  onPressed: () => _showRecordPaymentDialog(context, ref, customer),
                ),
                IconButton(
                  icon: const Icon(Icons.description, color: Colors.blue),
                  onPressed: () => _generateStatement(context, ref, customer),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Future<void> _generateStatement(final BuildContext context, final WidgetRef ref, final CustomerModel customer) async {
    final business = ref.read(currentBusinessProvider);
    final allSales = await ref.read(salesHistoryProvider.future);
    final customerSales = allSales.where((final s) => s.customerId == customer.id).toList();
    
    // For payments, we need to fetch from the provider
    final payments = await ref.read(customerPaymentsProvider(customer.id).future);

    final file = await CustomerStatementService.generateStatement(
      customer: customer,
      business: business!,
      sales: customerSales,
      payments: payments,
    );

    await Share.shareXFiles([XFile(file.path)], text: 'Statement for ${customer.name}');
  }

  void _showAddCustomerDialog(final BuildContext context, final WidgetRef ref) {
    final nameController = TextEditingController();
    final phoneController = TextEditingController();

    showDialog(
      context: context,
      builder: (final context) => AlertDialog(
        title: const Text('New Customer'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(controller: nameController, decoration: const InputDecoration(labelText: 'Name')),
            SizedBox(height: 16.h),
            TextField(
              controller: phoneController, 
              decoration: const InputDecoration(labelText: 'Phone'),
              keyboardType: TextInputType.phone,
            ),
          ],
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text('Cancel')),
          ElevatedButton(
            onPressed: () async {
              final businessId = ref.read(currentBusinessProvider)?.id;
              if (nameController.text.isNotEmpty && businessId != null) {
                final customer = CustomerModel(
                  id: const Uuid().v4(),
                  businessId: businessId,
                  name: nameController.text,
                  phone: phoneController.text.isNotEmpty ? phoneController.text : null,
                  createdAt: DateTime.now(),
                );
                await ref.read(customerActionsProvider.notifier).saveCustomer(customer);
                Navigator.pop(context);
              }
            },
            child: const Text('Save'),
          ),
        ],
      ),
    );
  }

  void _showRecordPaymentDialog(final BuildContext context, final WidgetRef ref, final CustomerModel customer) {
    final amountController = TextEditingController();
    String method = 'cash';

    showDialog(
      context: context,
      builder: (final context) => StatefulBuilder(
        builder: (final context, final setDialogState) => AlertDialog(
          title: Text('Record Payment: ${customer.name}'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: amountController,
                decoration: const InputDecoration(labelText: 'Amount Paid'),
                keyboardType: TextInputType.number,
              ),
              SizedBox(height: 16.h),
              DropdownButtonFormField<String>(
                initialValue: method,
                decoration: const InputDecoration(labelText: 'Payment Method'),
                items: const [
                  DropdownMenuItem(value: 'cash', child: Text('Cash')),
                  DropdownMenuItem(value: 'transfer', child: Text('Bank Transfer')),
                ],
                onChanged: (final val) => setDialogState(() => method = val!),
              ),
            ],
          ),
          actions: [
            TextButton(onPressed: () => Navigator.pop(context), child: const Text('Cancel')),
            ElevatedButton(
              onPressed: () async {
                final amount = double.tryParse(amountController.text);
                final businessId = ref.read(currentBusinessProvider)?.id;
                if (amount != null && businessId != null) {
                  final payment = CustomerPaymentModel(
                    id: const Uuid().v4(),
                    businessId: businessId,
                    customerId: customer.id,
                    amount: amount,
                    paymentMethod: method,
                    timestamp: DateTime.now(),
                  );
                  await ref.read(customerActionsProvider.notifier).recordPayment(payment);
                  if (context.mounted) Navigator.pop(context);
                }
              },
              child: const Text('Record'),
            ),
          ],
        ),
      ),
    );
  }
}
