import 'dart:io';
import 'package:csv/csv.dart';
import 'package:path_provider/path_provider.dart';
import 'package:intl/intl.dart';
import '../../features/pos/data/models/sale_model.dart';
import '../../features/inventory/data/models/product_model.dart';

class ReportService {
  /// Generates a flattened CSV for Sales where each row is a line item.
  static Future<File> generateSalesCsv(List<SaleModel> sales) async {
    List<List<dynamic>> rows = [];
    
    // Header
    rows.add([
      'Invoice ID',
      'Date',
      'Customer ID',
      'Product Name',
      'Quantity',
      'Unit',
      'Price',
      'Total',
      'Payment Method',
      'Status'
    ]);

    for (final sale in sales) {
      for (final item in sale.items) {
        rows.add([
          sale.id,
          DateFormat('yyyy-MM-dd HH:mm').format(sale.timestamp),
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

    String csvData = csv.encode(rows);
    final directory = await getTemporaryDirectory();
    final file = File("${directory.path}/sales_report_${DateFormat('yyyyMMdd').format(DateTime.now())}.csv");
    await file.writeAsString(csvData);
    return file;
  }

  /// Generates an Inventory Backup CSV compatible with the Import Wizard.
  static Future<File> generateInventoryCsv(List<ProductModel> products) async {
    List<List<dynamic>> rows = [];
    
    rows.add([
      'ID',
      'SKU',
      'Name',
      'Description',
      'Category',
      'Cost',
      'Price',
      'Total Stock',
      'Unit System'
    ]);

    for (final p in products) {
      rows.add([
        p.id,
        p.sku ?? '',
        p.name,
        p.description ?? '',
        p.category ?? 'Uncategorized',
        p.cost,
        p.priceConfigs?.first.price ?? 0.0,
        p.totalStock,
        p.unitSystemVersion
      ]);
    }

    String csvData = csv.encode(rows);
    final directory = await getTemporaryDirectory();
    final file = File("${directory.path}/inventory_backup_${DateFormat('yyyyMMdd').format(DateTime.now())}.csv");
    await file.writeAsString(csvData);
    return file;
  }
}
