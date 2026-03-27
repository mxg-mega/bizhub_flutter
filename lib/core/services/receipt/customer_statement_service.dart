import 'dart:io';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:path_provider/path_provider.dart';
import 'package:intl/intl.dart';
import '../../../features/pos/data/models/customer_model.dart';
import '../../../features/pos/data/models/sale_model.dart';
import '../../../features/pos/data/models/customer_payment_model.dart';
import '../../../shared/models/business_model.dart';

class CustomerStatementService {
  static Future<File> generateStatement({
    required CustomerModel customer,
    required BusinessModel business,
    required List<SaleModel> sales,
    required List<CustomerPaymentModel> payments,
  }) async {
    final pdf = pw.Document();

    // Sort all transactions by date
    final List<dynamic> transactions = [...sales, ...payments];
    transactions.sort((a, b) => (a.timestamp as DateTime).compareTo(b.timestamp as DateTime));

    pdf.addPage(
      pw.MultiPage(
        pageFormat: PdfPageFormat.a4,
        build: (context) => [
          _buildHeader(business, customer),
          pw.SizedBox(height: 20),
          _buildSummary(customer),
          pw.SizedBox(height: 20),
          _buildTransactionTable(transactions),
          pw.SizedBox(height: 20),
          pw.Divider(),
          pw.Align(
            alignment: pw.Alignment.centerRight,
            child: pw.Text(
              'Final Balance: \$${customer.outstandingBalance.toStringAsFixed(2)}',
              style: pw.TextStyle(fontSize: 16, fontWeight: pw.FontWeight.bold),
            ),
          ),
        ],
      ),
    );

    final output = await getTemporaryDirectory();
    final file = File("${output.path}/statement_${customer.name.replaceAll(' ', '_')}.pdf");
    await file.writeAsBytes(await pdf.save());
    return file;
  }

  static pw.Widget _buildHeader(BusinessModel business, CustomerModel customer) {
    return pw.Row(
      mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
      children: [
        pw.Column(
          crossAxisAlignment: pw.CrossAxisAlignment.start,
          children: [
            pw.Text(business.name ?? 'Your Business', style: pw.TextStyle(fontSize: 20, fontWeight: pw.FontWeight.bold)),
            pw.Text(business.address ?? ''),
          ],
        ),
        pw.Column(
          crossAxisAlignment: pw.CrossAxisAlignment.end,
          children: [
            pw.Text('CUSTOMER STATEMENT', style: pw.TextStyle(fontSize: 18, fontWeight: pw.FontWeight.bold, color: PdfColors.blue)),
            pw.Text('Date: ${DateFormat('MMM dd, yyyy').format(DateTime.now())}'),
          ],
        ),
      ],
    );
  }

  static pw.Widget _buildSummary(CustomerModel customer) {
    return pw.Container(
      padding: const pw.EdgeInsets.all(10),
      decoration: pw.BoxDecoration(border: pw.Border.all(color: PdfColors.grey300)),
      child: pw.Column(
        crossAxisAlignment: pw.CrossAxisAlignment.start,
        children: [
          pw.Text('Bill To:', style: pw.TextStyle(fontWeight: pw.FontWeight.bold)),
          pw.Text(customer.name),
          pw.Text(customer.phone ?? ''),
          pw.Text(customer.email ?? ''),
        ],
      ),
    );
  }

  static pw.Widget _buildTransactionTable(List<dynamic> transactions) {
    return pw.Table(
      border: pw.TableBorder.all(color: PdfColors.grey300),
      children: [
        pw.TableRow(
          decoration: const pw.BoxDecoration(color: PdfColors.grey100),
          children: [
            pw.Padding(padding: const pw.EdgeInsets.all(5), child: pw.Text('Date', style: pw.TextStyle(fontWeight: pw.FontWeight.bold))),
            pw.Padding(padding: const pw.EdgeInsets.all(5), child: pw.Text('Description', style: pw.TextStyle(fontWeight: pw.FontWeight.bold))),
            pw.Padding(padding: const pw.EdgeInsets.all(5), child: pw.Text('Debit', style: pw.TextStyle(fontWeight: pw.FontWeight.bold))),
            pw.Padding(padding: const pw.EdgeInsets.all(5), child: pw.Text('Credit', style: pw.TextStyle(fontWeight: pw.FontWeight.bold))),
          ],
        ),
        ...transactions.map((tx) {
          final isSale = tx is SaleModel;
          return pw.TableRow(
            children: [
              pw.Padding(padding: const pw.EdgeInsets.all(5), child: pw.Text(DateFormat('MM/dd/yy').format(tx.timestamp))),
              pw.Padding(padding: const pw.EdgeInsets.all(5), child: pw.Text(isSale ? 'Sale #${tx.id.substring(0,6)}' : 'Payment (${tx.paymentMethod})')),
              pw.Padding(padding: const pw.EdgeInsets.all(5), child: pw.Text(isSale ? tx.total.toStringAsFixed(2) : '', textAlign: pw.TextAlign.right)),
              pw.Padding(padding: const pw.EdgeInsets.all(5), child: pw.Text(!isSale ? tx.amount.toStringAsFixed(2) : '', textAlign: pw.TextAlign.right)),
            ],
          );
        }),
      ],
    );
  }
}
