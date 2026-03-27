import 'dart:io';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart';
import 'package:share_plus/share_plus.dart';
import 'package:path_provider/path_provider.dart';
import '../../../features/pos/data/models/sale_model.dart';
import '../../../shared/models/business_model.dart';

class ReceiptService {
  static Future<void> generateAndShareReceipt(SaleModel sale, BusinessModel business) async {
    final pdf = pw.Document();

    pdf.addPage(
      pw.Page(
        pageFormat: PdfPageFormat.roll80, // Typical thermal paper width
        build: (pw.Context context) => pw.Column(
            crossAxisAlignment: pw.CrossAxisAlignment.start,
            children: [
              pw.Center(
                child: pw.Text(business.name ?? 'Business Name', style: pw.TextStyle(fontSize: 18, fontWeight: pw.FontWeight.bold)),
              ),
              pw.Center(
                child: pw.Text(business.settings!['address'] ?? 'Address Not Set'),
              ),
              pw.SizedBox(height: 20),
              pw.Text('Receipt #: ${sale.id.substring(0, 8).toUpperCase()}'),
              pw.Text('Date: ${sale.timestamp.toString()}'),
              pw.Divider(),
              pw.Table(
                children: [
                  pw.TableRow(
                    children: [
                      pw.Text('Item', style: pw.TextStyle(fontWeight: pw.FontWeight.bold)),
                      pw.Text('Qty', textAlign: pw.TextAlign.center, style: pw.TextStyle(fontWeight: pw.FontWeight.bold)),
                      pw.Text('Price', textAlign: pw.TextAlign.right, style: pw.TextStyle(fontWeight: pw.FontWeight.bold)),
                    ],
                  ),
                  ...sale.items.map((item) => pw.TableRow(
                    children: [
                      pw.Text(item.name),
                      pw.Text(item.quantity.toString(), textAlign: pw.TextAlign.center),
                      pw.Text(item.totalPrice.toStringAsFixed(2), textAlign: pw.TextAlign.right),
                    ],
                  )),
                ],
              ),
              pw.Divider(),
              pw.Row(
                mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                children: [
                  pw.Text('Total:', style: pw.TextStyle(fontSize: 16, fontWeight: pw.FontWeight.bold)),
                  pw.Text('\$${sale.total.toStringAsFixed(2)}', style: pw.TextStyle(fontSize: 16, fontWeight: pw.FontWeight.bold)),
                ],
              ),
              pw.SizedBox(height: 30),
              pw.Center(
                child: pw.Text('Thank you for your business!', style: pw.TextStyle(fontStyle: pw.FontStyle.italic)),
              ),
            ],
          ),
      ),
    );

    // Save PDF to temp file
    final output = await getTemporaryDirectory();
    final file = File("${output.path}/receipt_${sale.id.substring(0, 8)}.pdf");
    await file.writeAsBytes(await pdf.save());

    // Share via share_plus
    await Share.shareXFiles([XFile(file.path)], text: 'Receipt from ${business.name}');
  }

  static Future<void> printToThermal(SaleModel sale, BusinessModel business) async {
    // This requires a connected Bluetooth printer. 
    // For now, we open the native print dialog which works with thermal printers if installed.
    final pdf = pw.Document();
    // (Build the same PDF as above)
    // ...
    await Printing.layoutPdf(onLayout: (PdfPageFormat format) async => pdf.save());
  }
}
