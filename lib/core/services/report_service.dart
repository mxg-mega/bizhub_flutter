import 'dart:io';
import 'package:csv/csv.dart';
import 'package:path_provider/path_provider.dart';
import 'package:intl/intl.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import '../../features/pos/data/models/sale_model.dart';
import '../../features/inventory/data/models/product_model.dart';
import '../../shared/models/business_model.dart';

class ReportService {
  /// Generates a flattened CSV for Sales where each row is a line item.
  static Future<File> generateSalesCsv(final List<SaleModel> sales) async {
    final List<List<dynamic>> rows = [];
    rows.add(['Invoice ID', 'Date', 'Customer ID', 'Product Name', 'Quantity', 'Unit', 'Price', 'Total', 'Payment Method', 'Status']);

    for (final sale in sales) {
      for (final item in sale.items) {
        rows.add([
          sale.id,
          DateFormat('yyyy-MM-dd HH:mm').format(sale.date),
          sale.customerId ?? 'Guest',
          item.name,
          item.quantity,
          item.unit,
          item.unitPrice,
          item.totalPrice,
          sale.paymentMethod,
          sale.status
        ]);
      }
    }

    final String csvData = csv.encode(rows);
    final directory = await getTemporaryDirectory();
    final file = File("${directory.path}/sales_report_${DateFormat('yyyyMMdd').format(DateTime.now())}.csv");
    await file.writeAsString(csvData);
    return file;
  }

  /// Generates a professional Sales Performance PDF report.
  static Future<File> generateSalesPdf(final List<SaleModel> sales, final BusinessModel business) async {
    final pdf = pw.Document();
    final totalRevenue = sales.fold(0.0, (final sum, final s) => sum + s.total);
    final paidCount = sales.where((final s) => s.status == 'Paid').length;

    pdf.addPage(
      pw.MultiPage(
        pageFormat: PdfPageFormat.a4,
        header: (final context) => _buildReportHeader(business, 'SALES PERFORMANCE REPORT'),
        build: (final context) => [
          pw.SizedBox(height: 20),
          _buildSummaryGrid([
            _SummaryItem('Total Revenue', '₦${totalRevenue.toStringAsFixed(2)}'),
            _SummaryItem('Total Invoices', '${sales.length}'),
            _SummaryItem('Paid Invoices', '$paidCount'),
            _SummaryItem('Collection Rate', '${sales.isEmpty ? 0 : ((paidCount / sales.length) * 100).toStringAsFixed(1)}%'),
          ]),
          pw.SizedBox(height: 30),
          _buildSalesTable(sales),
        ],
        footer: (final context) => _buildReportFooter(context),
      ),
    );

    final directory = await getTemporaryDirectory();
    final file = File("${directory.path}/sales_report_${DateFormat('yyyyMMdd').format(DateTime.now())}.pdf");
    await file.writeAsBytes(await pdf.save());
    return file;
  }

  /// Generates an Inventory Backup CSV.
  static Future<File> generateInventoryCsv(final List<ProductModel> products) async {
    final List<List<dynamic>> rows = [];
    rows.add(['ID', 'SKU', 'Name', 'Category', 'Cost', 'Price', 'Total Stock']);

    for (final p in products) {
      rows.add([p.id, p.sku ?? '', p.name, p.category ?? 'N/A', p.cost, p.price, p.totalStock]);
    }

    final String csvData = csv.encode(rows);
    final directory = await getTemporaryDirectory();
    final file = File("${directory.path}/inventory_backup_${DateFormat('yyyyMMdd').format(DateTime.now())}.csv");
    await file.writeAsString(csvData);
    return file;
  }

  /// Generates a "Stock Health" PDF report highlighting critical issues.
  static Future<File> generateStockHealthPdf(final List<ProductModel> products, final BusinessModel business) async {
    final pdf = pw.Document();
    final lowStockItems = products.where((final p) => p.totalStock < 10).toList();
    final expiringSoon = products.where((final p) {
      if (p.expirationDate == null) return false;
      return p.expirationDate!.difference(DateTime.now()).inDays < 30;
    }).toList();

    pdf.addPage(
      pw.MultiPage(
        pageFormat: PdfPageFormat.a4,
        header: (final context) => _buildReportHeader(business, 'STOCK HEALTH & RISK REPORT'),
        build: (final context) => [
          pw.SizedBox(height: 20),
          _buildSummaryGrid([
            _SummaryItem('Total Items', '${products.length}'),
            _SummaryItem('Low Stock Alerts', '${lowStockItems.length}', color: PdfColors.red),
            _SummaryItem('Expiring Soon', '${expiringSoon.length}', color: PdfColors.orange),
            _SummaryItem('Inventory Worth', '₦${products.fold(0.0, (final sum, final p) => sum + (p.price * p.totalStock)).toStringAsFixed(2)}'),
          ]),
          pw.SizedBox(height: 30),
          pw.Text('LOW STOCK ALERT', style: pw.TextStyle(fontWeight: pw.FontWeight.bold, color: PdfColors.red)),
          _buildInventoryTable(lowStockItems),
          if (expiringSoon.isNotEmpty) ...[
            pw.SizedBox(height: 30),
            pw.Text('EXPIRATION WARNING (NEXT 30 DAYS)', style: pw.TextStyle(fontWeight: pw.FontWeight.bold, color: PdfColors.orange)),
            _buildInventoryTable(expiringSoon, showExpiration: true),
          ],
        ],
        footer: (final context) => _buildReportFooter(context),
      ),
    );

    final directory = await getTemporaryDirectory();
    final file = File("${directory.path}/stock_health_${DateFormat('yyyyMMdd').format(DateTime.now())}.pdf");
    await file.writeAsBytes(await pdf.save());
    return file;
  }

  // --- PDF Component Builders ---

  static pw.Widget _buildReportHeader(final BusinessModel business, final String title) => pw.Column(
      children: [
        pw.Row(
          mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
          children: [
            pw.Column(
              crossAxisAlignment: pw.CrossAxisAlignment.start,
              children: [
                pw.Text(business.name ?? 'BUSINESS REPORT', style: pw.TextStyle(fontSize: 18, fontWeight: pw.FontWeight.bold)),
                pw.Text(business.address ?? '', style: const pw.TextStyle(fontSize: 10)),
              ],
            ),
            pw.Column(
              crossAxisAlignment: pw.CrossAxisAlignment.end,
              children: [
                pw.Text(title, style: pw.TextStyle(fontSize: 14, fontWeight: pw.FontWeight.bold, color: PdfColors.blue900)),
                pw.Text('Generated: ${DateFormat('MMM dd, yyyy HH:mm').format(DateTime.now())}', style: const pw.TextStyle(fontSize: 8)),
              ],
            ),
          ],
        ),
        pw.Divider(thickness: 2, color: PdfColors.blue900),
      ],
    );

  static pw.Widget _buildSummaryGrid(final List<_SummaryItem> items) => pw.Row(
      mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
      children: items.map((final item) => pw.Container(
        padding: const pw.EdgeInsets.all(10),
        decoration: pw.BoxDecoration(
          border: pw.Border.all(color: PdfColors.grey300),
          borderRadius: const pw.BorderRadius.all(pw.Radius.circular(5)),
        ),
        child: pw.Column(
          children: [
            pw.Text(item.label, style: const pw.TextStyle(fontSize: 8, color: PdfColors.grey700)),
            pw.Text(item.value, style: pw.TextStyle(fontSize: 12, fontWeight: pw.FontWeight.bold, color: item.color ?? PdfColors.black)),
          ],
        ),
      )).toList(),
    );

  static pw.Widget _buildSalesTable(final List<SaleModel> sales) => pw.TableHelper.fromTextArray(
      headers: ['Invoice', 'Date', 'Customer', 'Items', 'Total', 'Status'],
      data: sales.map((final s) => [
        s.id.substring(0, 8).toUpperCase(),
        DateFormat('MM/dd/yy').format(s.date),
        s.customerId ?? 'Guest',
        s.items.length.toString(),
        '₦${s.total.toStringAsFixed(2)}',
        s.status,
      ]).toList(),
      headerStyle: pw.TextStyle(fontWeight: pw.FontWeight.bold, color: PdfColors.white),
      headerDecoration: const pw.BoxDecoration(color: PdfColors.blue900),
      cellAlignment: pw.Alignment.centerLeft,
    );

  static pw.Widget _buildInventoryTable(final List<ProductModel> products, {final bool showExpiration = false}) => pw.TableHelper.fromTextArray(
      headers: ['SKU', 'Name', 'Stock', 'Category', if (showExpiration) 'Expires'],
      data: products.map((final p) => [
        p.sku ?? 'N/A',
        p.name,
        p.totalStock.toString(),
        p.category ?? 'N/A',
        if (showExpiration) DateFormat('MM/dd/yy').format(p.expirationDate!),
      ]).toList(),
      headerStyle: pw.TextStyle(fontWeight: pw.FontWeight.bold, color: PdfColors.white),
      headerDecoration: const pw.BoxDecoration(color: PdfColors.blueGrey900),
      cellAlignment: pw.Alignment.centerLeft,
    );

  static pw.Widget _buildReportFooter(final pw.Context context) => pw.Container(
      alignment: pw.Alignment.centerRight,
      margin: const pw.EdgeInsets.only(top: 10),
      child: pw.Text('Page ${context.pageNumber} of ${context.pagesCount}', style: const pw.TextStyle(fontSize: 8, color: PdfColors.grey)),
    );
}

class _SummaryItem {
  final String label;
  final String value;
  final PdfColor? color;
  _SummaryItem(this.label, this.value, {this.color});
}
