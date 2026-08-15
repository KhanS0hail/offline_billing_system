import 'dart:convert';
import 'dart:typed_data';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import '../models/company.dart';
import '../models/customer.dart';
import '../models/invoice.dart';

class PdfStatementBuilder {
  /// Builds a professional A4 Customer Account Statement PDF
  static Future<Uint8List> buildCustomerStatement({
    required Company? company,
    required Customer customer,
    required List<Invoice> customerInvoices,
    required String startDateStr,
    required String endDateStr,
  }) async {
    final pdf = pw.Document();

    pw.MemoryImage? logoImage;
    if (company?.logoBase64 != null && company!.logoBase64!.isNotEmpty) {
      try {
        logoImage = pw.MemoryImage(base64Decode(company.logoBase64!));
      } catch (_) {}
    }

    double totalBilled = 0.0;
    double totalReceived = 0.0;
    double openingBal = customer.openingBalance ?? 0.0;

    // Calculate totals
    for (var inv in customerInvoices) {
      totalBilled += inv.grandTotal;
      totalReceived += inv.receivedAmount;
    }
    double netOutstanding = openingBal + totalBilled - totalReceived;

    pdf.addPage(
      pw.MultiPage(
        pageFormat: PdfPageFormat.a4,
        margin: const pw.EdgeInsets.all(32),
        build: (pw.Context context) {
          return [
            // 1. HEADER BLOCK
            pw.Row(
              mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
              crossAxisAlignment: pw.CrossAxisAlignment.start,
              children: [
                pw.Expanded(
                  flex: 65,
                  child: pw.Column(
                    crossAxisAlignment: pw.CrossAxisAlignment.start,
                    children: [
                      pw.Row(
                        children: [
                          if (logoImage != null)
                            pw.Container(
                              height: 45,
                              width: 65,
                              margin: const pw.EdgeInsets.only(right: 10),
                              child: pw.Image(logoImage, fit: pw.BoxFit.contain),
                            ),
                          pw.Column(
                            crossAxisAlignment: pw.CrossAxisAlignment.start,
                            children: [
                              pw.Text(
                                company?.name ?? 'Regal Steel Trader',
                                style: pw.TextStyle(fontSize: 18, fontWeight: pw.FontWeight.bold),
                              ),
                              if (company?.tagline != null && company!.tagline!.isNotEmpty)
                                pw.Text(company.tagline!, style: const pw.TextStyle(fontSize: 8, fontStyle: pw.FontStyle.italic)),
                            ],
                          ),
                        ],
                      ),
                      pw.SizedBox(height: 6),
                      if (company?.address != null) pw.Text('Address: ${company!.address}', style: const pw.TextStyle(fontSize: 8.5)),
                      if (company?.phone != null) pw.Text('Phone: ${company!.phone}', style: const pw.TextStyle(fontSize: 8.5)),
                      if (company?.gstNumber != null) pw.Text('GSTIN: ${company!.gstNumber}', style: const pw.TextStyle(fontSize: 8.5)),
                    ],
                  ),
                ),
                pw.Expanded(
                  flex: 35,
                  child: pw.Column(
                    crossAxisAlignment: pw.CrossAxisAlignment.end,
                    children: [
                      pw.Text('ACCOUNT STATEMENT', style: pw.TextStyle(fontSize: 14, fontWeight: pw.FontWeight.bold)),
                      pw.SizedBox(height: 6),
                      pw.Text('Period: $startDateStr to $endDateStr', style: const pw.TextStyle(fontSize: 8.5)),
                      pw.Text('Generated: ${DateTime.now().day}-${DateTime.now().month}-${DateTime.now().year}', style: const pw.TextStyle(fontSize: 8.5)),
                    ],
                  ),
                ),
              ],
            ),

            pw.SizedBox(height: 12),
            pw.Divider(thickness: 1, color: PdfColors.black),
            pw.SizedBox(height: 8),

            // 2. CUSTOMER INFO BLOCK
            pw.Container(
              padding: const pw.EdgeInsets.all(8),
              decoration: pw.BoxDecoration(
                border: pw.Border.all(color: PdfColors.grey400, width: 0.8),
                borderRadius: const pw.BorderRadius.all(pw.Radius.circular(4)),
              ),
              child: pw.Row(
                mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                children: [
                  pw.Column(
                    crossAxisAlignment: pw.CrossAxisAlignment.start,
                    children: [
                      pw.Text('STATEMENT FOR:', style: pw.TextStyle(fontSize: 8, fontWeight: pw.FontWeight.bold)),
                      pw.Text(customer.name ?? 'Customer', style: pw.TextStyle(fontSize: 12, fontWeight: pw.FontWeight.bold)),
                      if (customer.contactPerson != null && customer.contactPerson!.isNotEmpty)
                        pw.Text('Attn: ${customer.contactPerson}', style: const pw.TextStyle(fontSize: 8.5)),
                      if (customer.address != null && customer.address!.isNotEmpty)
                        pw.Text(customer.address!, style: const pw.TextStyle(fontSize: 8.5)),
                      if (customer.gstNumber != null && customer.gstNumber!.isNotEmpty)
                        pw.Text('GSTIN: ${customer.gstNumber}', style: const pw.TextStyle(fontSize: 8.5)),
                    ],
                  ),
                  pw.Column(
                    crossAxisAlignment: pw.CrossAxisAlignment.end,
                    children: [
                      pw.Text('Opening Balance: Rs ${openingBal.toStringAsFixed(2)}', style: pw.TextStyle(fontSize: 9, fontWeight: pw.FontWeight.bold)),
                      pw.Text('Total Billed: Rs ${totalBilled.toStringAsFixed(2)}', style: const pw.TextStyle(fontSize: 9)),
                      pw.Text('Total Received: Rs ${totalReceived.toStringAsFixed(2)}', style: const pw.TextStyle(fontSize: 9)),
                      pw.SizedBox(height: 4),
                      pw.Text('NET DUE: Rs ${netOutstanding.toStringAsFixed(2)}', style: pw.TextStyle(fontSize: 11, fontWeight: pw.FontWeight.bold, color: PdfColors.black)),
                    ],
                  ),
                ],
              ),
            ),

            pw.SizedBox(height: 14),

            // 3. RUNNING LEDGER TABLE
            pw.Table(
              border: pw.TableBorder.all(color: PdfColors.grey400, width: 0.5),
              columnWidths: {
                0: const pw.FlexColumnWidth(1.3), // Inv Date (13%)
                1: const pw.FlexColumnWidth(1.1), // Payment Date (11%)
                2: const pw.FlexColumnWidth(1.5), // Ref / Inv # (15%)
                3: const pw.FlexColumnWidth(2.3), // Description (23%)
                4: const pw.FlexColumnWidth(1.3), // Billed (Debit) (13%)
                5: const pw.FlexColumnWidth(1.3), // Received (Credit) (13%)
                6: const pw.FlexColumnWidth(1.2), // Balance (12%)
              },
              children: [
                // Header
                pw.TableRow(
                  decoration: const pw.BoxDecoration(color: PdfColors.grey200),
                  children: [
                    _th('Inv Date'),
                    _th('Payment Date'),
                    _th('Ref / Inv #'),
                    _th('Description'),
                    _th('Billed (Dr)', align: pw.TextAlign.right),
                    _th('Received (Cr)', align: pw.TextAlign.right),
                    _th('Balance (Rs)', align: pw.TextAlign.right),
                  ],
                ),
                // Opening Balance Row
                pw.TableRow(
                  children: [
                    _td(startDateStr),
                    _td('-'),
                    _td('-'),
                    _td('Opening Balance', isBold: true),
                    _td('-'),
                    _td('-'),
                    _td(openingBal.toStringAsFixed(2), align: pw.TextAlign.right, isBold: true),
                  ],
                ),
                // Transactions
                ...customerInvoices.map((inv) {
                  final pDate = inv.paymentDate ?? (inv.status == 'Unpaid' ? '-' : inv.date);
                  return pw.TableRow(
                    children: [
                      _td(inv.date),
                      _td(pDate),
                      _td(inv.invoiceNumber, isBold: true),
                      _td(inv.invoiceType),
                      _td(inv.grandTotal.toStringAsFixed(2), align: pw.TextAlign.right),
                      _td(inv.receivedAmount.toStringAsFixed(2), align: pw.TextAlign.right),
                      _td(inv.balanceAmount.toStringAsFixed(2), align: pw.TextAlign.right, isBold: true),
                    ],
                  );
                }),
                // Total Summary Row
                pw.TableRow(
                  decoration: const pw.BoxDecoration(color: PdfColors.grey100),
                  children: [
                    _td('TOTAL', isBold: true),
                    _td(''),
                    _td(''),
                    _td('${customerInvoices.length} Invoices', isBold: true),
                    _td(totalBilled.toStringAsFixed(2), align: pw.TextAlign.right, isBold: true),
                    _td(totalReceived.toStringAsFixed(2), align: pw.TextAlign.right, isBold: true),
                    _td(netOutstanding.toStringAsFixed(2), align: pw.TextAlign.right, isBold: true),
                  ],
                ),
              ],
            ),

            pw.SizedBox(height: 20),

            // 4. SIGNATURE BLOCK
            pw.Align(
              alignment: pw.Alignment.bottomRight,
              child: pw.Column(
                crossAxisAlignment: pw.CrossAxisAlignment.center,
                children: [
                  pw.SizedBox(height: 35),
                  pw.Text('For ${company?.name ?? "Company"}', style: pw.TextStyle(fontSize: 9, fontWeight: pw.FontWeight.bold)),
                  pw.Text('Authorized Signatory', style: const pw.TextStyle(fontSize: 8)),
                ],
              ),
            ),
          ];
        },
      ),
    );

    return pdf.save();
  }

  /// Builds a Monthly GST Tax Summary PDF Report (GSTR-1 Ready)
  static Future<Uint8List> buildGstReport({
    required Company? company,
    required String monthYearStr,
    required List<Invoice> monthInvoices,
    required double totalSales,
    required double totalTaxable,
    required double totalCgst,
    required double totalSgst,
    required double totalIgst,
  }) async {
    final pdf = pw.Document();

    pdf.addPage(
      pw.MultiPage(
        pageFormat: PdfPageFormat.a4,
        margin: const pw.EdgeInsets.all(32),
        build: (pw.Context context) {
          return [
            // Title Header
            pw.Row(
              mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
              children: [
                pw.Column(
                  crossAxisAlignment: pw.CrossAxisAlignment.start,
                  children: [
                    pw.Text(company?.name ?? 'Company', style: pw.TextStyle(fontSize: 16, fontWeight: pw.FontWeight.bold)),
                    if (company?.gstNumber != null) pw.Text('GSTIN: ${company!.gstNumber}', style: const pw.TextStyle(fontSize: 9)),
                  ],
                ),
                pw.Column(
                  crossAxisAlignment: pw.CrossAxisAlignment.end,
                  children: [
                    pw.Text('MONTHLY GST REPORT', style: pw.TextStyle(fontSize: 14, fontWeight: pw.FontWeight.bold)),
                    pw.Text('Period: $monthYearStr', style: const pw.TextStyle(fontSize: 9, fontWeight: pw.FontWeight.bold)),
                  ],
                ),
              ],
            ),
            pw.SizedBox(height: 10),
            pw.Divider(thickness: 1, color: PdfColors.black),
            pw.SizedBox(height: 10),

            // Summary Table
            pw.Text('TAX LIABILITY SUMMARY', style: pw.TextStyle(fontSize: 10, fontWeight: pw.FontWeight.bold)),
            pw.SizedBox(height: 4),
            pw.Table(
              border: pw.TableBorder.all(color: PdfColors.grey400, width: 0.5),
              children: [
                pw.TableRow(
                  decoration: const pw.BoxDecoration(color: PdfColors.grey200),
                  children: [
                    _th('Total Billed Sales'),
                    _th('Taxable Value'),
                    _th('CGST (Intra)'),
                    _th('SGST (Intra)'),
                    _th('IGST (Inter)'),
                    _th('Total GST Liability'),
                  ],
                ),
                pw.TableRow(
                  children: [
                    _td('Rs ${totalSales.toStringAsFixed(2)}', align: pw.TextAlign.right, isBold: true),
                    _td('Rs ${totalTaxable.toStringAsFixed(2)}', align: pw.TextAlign.right),
                    _td('Rs ${totalCgst.toStringAsFixed(2)}', align: pw.TextAlign.right),
                    _td('Rs ${totalSgst.toStringAsFixed(2)}', align: pw.TextAlign.right),
                    _td('Rs ${totalIgst.toStringAsFixed(2)}', align: pw.TextAlign.right),
                    _td('Rs ${(totalCgst + totalSgst + totalIgst).toStringAsFixed(2)}', align: pw.TextAlign.right, isBold: true),
                  ],
                ),
              ],
            ),

            pw.SizedBox(height: 16),

            // Invoice Schedule Table
            pw.Text('INVOICE TAX SCHEDULE ($monthYearStr)', style: pw.TextStyle(fontSize: 10, fontWeight: pw.FontWeight.bold)),
            pw.SizedBox(height: 4),
            pw.Table(
              border: pw.TableBorder.all(color: PdfColors.grey400, width: 0.5),
              columnWidths: {
                0: const pw.FlexColumnWidth(0.8), // Inv #
                1: const pw.FlexColumnWidth(0.8), // Date
                2: const pw.FlexColumnWidth(1.8), // Customer
                3: const pw.FlexColumnWidth(1.1), // GSTIN
                4: const pw.FlexColumnWidth(1.0), // Taxable
                5: const pw.FlexColumnWidth(0.8), // CGST
                6: const pw.FlexColumnWidth(0.8), // SGST
                7: const pw.FlexColumnWidth(0.8), // IGST
                8: const pw.FlexColumnWidth(1.1), // Total
              },
              children: [
                pw.TableRow(
                  decoration: const pw.BoxDecoration(color: PdfColors.grey200),
                  children: [
                    _th('Inv #'),
                    _th('Date'),
                    _th('Customer'),
                    _th('GSTIN'),
                    _th('Taxable'),
                    _th('CGST'),
                    _th('SGST'),
                    _th('IGST'),
                    _th('Total (Rs)'),
                  ],
                ),
                ...monthInvoices.map((inv) {
                  return pw.TableRow(
                    children: [
                      _td(inv.invoiceNumber),
                      _td(inv.date),
                      _td(inv.customerName ?? 'Cash'),
                      _td(inv.customerGstin ?? '-'),
                      _td(inv.taxableBase.toStringAsFixed(2), align: pw.TextAlign.right),
                      _td(inv.cgstTotal.toStringAsFixed(2), align: pw.TextAlign.right),
                      _td(inv.sgstTotal.toStringAsFixed(2), align: pw.TextAlign.right),
                      _td(inv.igstTotal.toStringAsFixed(2), align: pw.TextAlign.right),
                      _td(inv.grandTotal.toStringAsFixed(2), align: pw.TextAlign.right, isBold: true),
                    ],
                  );
                }),
              ],
            ),
          ];
        },
      ),
    );

    return pdf.save();
  }

  static pw.Widget _th(String text, {pw.TextAlign align = pw.TextAlign.left}) {
    return pw.Padding(
      padding: const pw.EdgeInsets.all(4),
      child: pw.Text(text, style: pw.TextStyle(fontSize: 8, fontWeight: pw.FontWeight.bold), textAlign: align),
    );
  }

  static pw.Widget _td(String text, {pw.TextAlign align = pw.TextAlign.left, bool isBold = false}) {
    return pw.Padding(
      padding: const pw.EdgeInsets.all(4),
      child: pw.Text(text, style: pw.TextStyle(fontSize: 7.5, fontWeight: isBold ? pw.FontWeight.bold : pw.FontWeight.normal), textAlign: align),
    );
  }
}
