import 'dart:io';
import 'dart:typed_data';
import 'package:blue_thermal_printer/blue_thermal_printer.dart';
import 'package:esc_pos_utils_plus/esc_pos_utils_plus.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:path_provider/path_provider.dart';
import '../../../features/pos/data/models/sale_model.dart';
import '../../../features/receipts/data/models/receipt_template_model.dart';
import '../../../shared/models/business_model.dart';

class ReceiptGenerator {
  final BlueThermalPrinter _bluetooth = BlueThermalPrinter.instance;

  Future<void> printThermal(final SaleModel sale, final BusinessModel business, final ReceiptTemplateModel template) async {
    if ((await _bluetooth.isConnected) == true) {
      final profile = await CapabilityProfile.load();
      final generator = Generator(template.paperSize == '80mm' ? PaperSize.mm80 : PaperSize.mm58, profile);
      List<int> bytes = [];

      final isMinimal = template.layoutStyle == 'Minimal';
      final isModern = template.layoutStyle == 'Modern';
      final align = isMinimal ? PosAlign.left : PosAlign.center;

      if (template.headerText != null && template.headerText!.isNotEmpty) {
        bytes += generator.text(template.headerText!, styles: PosStyles(align: align, bold: !isMinimal));
        if (!isMinimal) bytes += generator.hr();
      }

      bytes += generator.text(business.name ?? '', styles: PosStyles(align: align, height: isModern ? PosTextSize.size2 : PosTextSize.size1, width: isModern ? PosTextSize.size2 : PosTextSize.size1, bold: true));
      if (business.address != null) bytes += generator.text(business.address!, styles: PosStyles(align: align));
      bytes += generator.hr();

      bytes += generator.row([
        PosColumn(text: 'Item', width: 6, styles: const PosStyles(bold: true)),
        PosColumn(text: 'Qty', width: 2, styles: const PosStyles(bold: true, align: PosAlign.center)),
        PosColumn(text: 'Price', width: 4, styles: const PosStyles(align: PosAlign.right, bold: true)),
      ]);
      
      for (final item in sale.items) {
        bytes += generator.row([
          PosColumn(text: item.name, width: 6),
          PosColumn(text: item.quantity.toStringAsFixed(0), width: 2, styles: const PosStyles(align: PosAlign.center)),
          PosColumn(text: item.totalPrice.toStringAsFixed(2), width: 4, styles: const PosStyles(align: PosAlign.right)),
        ]);
      }
      
      bytes += generator.hr();

      bytes += generator.row([
        PosColumn(text: 'TOTAL', width: 6, styles: const PosStyles(bold: true, height: PosTextSize.size2)),
        PosColumn(text: '', width: 2),
        PosColumn(text: sale.total.toStringAsFixed(2), width: 4, styles: const PosStyles(align: PosAlign.right, bold: true, height: PosTextSize.size2)),
      ]);

      if (template.footerText != null && template.footerText!.isNotEmpty) {
        bytes += generator.hr();
        bytes += generator.text(template.footerText!, styles: const PosStyles(align: PosAlign.center));
      }

      bytes += generator.feed(2);
      bytes += generator.cut();

      await _bluetooth.writeBytes(Uint8List.fromList(bytes));
    }
  }

  Future<File> generatePdf(final SaleModel sale, final BusinessModel business, final ReceiptTemplateModel template) async {
    final pdf = pw.Document();

    pdf.addPage(
      pw.Page(
        pageFormat: PdfPageFormat.roll80,
        build: (final pw.Context context) {
          final isMinimal = template.layoutStyle == 'Minimal';
          final isModern = template.layoutStyle == 'Modern';
          final align = isMinimal ? pw.CrossAxisAlignment.start : pw.CrossAxisAlignment.center;

          return pw.Column(
            crossAxisAlignment: align,
            children: [
              if (template.headerText != null && template.headerText!.isNotEmpty) 
                pw.Paragraph(
                  text: template.headerText!, 
                  textAlign: isMinimal ? pw.TextAlign.left : pw.TextAlign.center,
                  style: pw.TextStyle(fontSize: 10, fontWeight: isMinimal ? pw.FontWeight.normal : pw.FontWeight.bold),
                ),
              
              pw.SizedBox(height: 10),
              pw.Text(
                business.name ?? '', 
                style: pw.TextStyle(fontSize: isModern ? 22 : 18, fontWeight: pw.FontWeight.bold),
              ),
              if (business.address != null) pw.Text(business.address!, style: const pw.TextStyle(fontSize: 10)),
              pw.Divider(),
              
              pw.Table(
                children: [
                  pw.TableRow(children: [
                    pw.Text('Item', style: pw.TextStyle(fontWeight: pw.FontWeight.bold)),
                    pw.Text('Qty', textAlign: pw.TextAlign.center, style: pw.TextStyle(fontWeight: pw.FontWeight.bold)),
                    pw.Text('Price', textAlign: pw.TextAlign.right, style: pw.TextStyle(fontWeight: pw.FontWeight.bold)),
                  ]),
                  pw.TableRow(children: [pw.Divider(), pw.Divider(), pw.Divider()]),
                  ...sale.items.map((final item) => pw.TableRow(children: [
                    pw.Padding(padding: const pw.EdgeInsets.symmetric(vertical: 2), child: pw.Text(item.name)),
                    pw.Padding(padding: const pw.EdgeInsets.symmetric(vertical: 2), child: pw.Text(item.quantity.toStringAsFixed(0), textAlign: pw.TextAlign.center)),
                    pw.Padding(padding: const pw.EdgeInsets.symmetric(vertical: 2), child: pw.Text(item.totalPrice.toStringAsFixed(2), textAlign: pw.TextAlign.right)),
                  ])),
                ],
              ),
              pw.Divider(),
              
              pw.Row(
                mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                children: [
                  pw.Text('TOTAL', style: pw.TextStyle(fontWeight: pw.FontWeight.bold, fontSize: 16)),
                  pw.Text(sale.total.toStringAsFixed(2), style: pw.TextStyle(fontWeight: pw.FontWeight.bold, fontSize: 16)),
                ],
              ),
              
              pw.SizedBox(height: 20),
              if (template.footerText != null && template.footerText!.isNotEmpty) 
                pw.Center(
                  child: pw.Text(
                    template.footerText!, 
                    textAlign: pw.TextAlign.center,
                    style: pw.TextStyle(fontSize: 9, fontStyle: pw.FontStyle.italic),
                  ),
                ),
            ],
          );
        },
      ),
    );

    final output = await getTemporaryDirectory();
    final file = File('${output.path}/receipt_${sale.id.substring(0, 8)}.pdf');
    await file.writeAsBytes(await pdf.save());
    return file;
  }
}
