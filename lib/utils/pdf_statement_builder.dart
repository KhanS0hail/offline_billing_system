import 'dart:convert';
import 'dart:typed_data';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import '../models/company.dart';
import '../models/customer.dart';
import '../models/invoice.dart';
import '../models/customer_payment.dart';

class _LedgerEntry {
  final DateTime dateObj;
  final String dateStr;
  final String referenceNo;
  final String details;
  final double debit;
  final double credit;

  _LedgerEntry({
    required this.dateObj,
    required this.dateStr,
    required this.referenceNo,
    required this.details,
    required this.debit,
    required this.credit,
  });
}

class PdfStatementBuilder {
  static String getStatementFileName(Customer customer, String monthYearStr) {
    final nameClean = (customer.name ?? 'Customer').replaceAll(RegExp(r'[^\w\s\-]'), '').trim().replaceAll(RegExp(r'\s+'), '_');
    final dateClean = monthYearStr.replaceAll(RegExp(r'[^\w\s\-]'), '').trim().replaceAll(RegExp(r'\s+'), '_');
    return "STATEMENT_${nameClean}_$dateClean.pdf";
  }

  static DateTime _parseDate(String dStr) {
    try {
      final parts = dStr.split('-');
      if (parts.length == 3) {
        final day = int.parse(parts[0]);
        final monthStr = parts[1];
        final year = int.parse(parts[2]);
        const months = ["Jan", "Feb", "Mar", "Apr", "May", "Jun", "Jul", "Aug", "Sep", "Oct", "Nov", "Dec"];
        final month = months.indexOf(monthStr) + 1;
        if (month > 0) return DateTime(year, month, day);
      }
    } catch (_) {}
    try {
      return DateTime.parse(dStr);
    } catch (_) {}
    return DateTime(2000);
  }

  /// Builds a professional A4 Statement of Account PDF
  static Future<Uint8List> buildCustomerStatement({
    required Company? company,
    required Customer customer,
    required List<Invoice> customerInvoices,
    List<CustomerPayment> customerPayments = const [],
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

    pw.MemoryImage? signatureImage;
    if (company?.signatureBase64 != null && company!.signatureBase64!.isNotEmpty) {
      try {
        signatureImage = pw.MemoryImage(base64Decode(company.signatureBase64!));
      } catch (_) {}
    }

    // 1. Build unified chronological ledger entries
    List<_LedgerEntry> entries = [];

    for (var inv in customerInvoices) {
      entries.add(_LedgerEntry(
        dateObj: _parseDate(inv.date),
        dateStr: inv.date,
        referenceNo: inv.invoiceNumber,
        details: "Tax Invoice (${inv.items.length} Item${inv.items.length == 1 ? '' : 's'})",
        debit: inv.grandTotal,
        credit: 0.0,
      ));
    }

    for (var pay in customerPayments) {
      String detailStr = "Payment Received";
      if (pay.paymentMode != null && pay.paymentMode!.isNotEmpty) {
        detailStr += " via ${pay.paymentMode}";
      }
      if (pay.referenceNote != null && pay.referenceNote!.isNotEmpty) {
        detailStr += " (Ref: ${pay.referenceNote})";
      }

      entries.add(_LedgerEntry(
        dateObj: _parseDate(pay.paymentDate),
        dateStr: pay.paymentDate,
        referenceNo: pay.receiptNumber,
        details: detailStr,
        debit: 0.0,
        credit: pay.amount,
      ));
    }

    entries.sort((a, b) => a.dateObj.compareTo(b.dateObj));

    double totalBilled = 0.0;
    double totalReceived = 0.0;
    double openingBal = customer.openingBalance ?? 0.0;

    for (var e in entries) {
      totalBilled += e.debit;
      totalReceived += e.credit;
    }
    double netOutstanding = openingBal + totalBilled - totalReceived;

    final String companyStateStr = (company?.stateCode != null && company!.stateCode!.isNotEmpty)
        ? "${company.stateCode}"
        : "";

    pdf.addPage(
      pw.MultiPage(
        pageFormat: PdfPageFormat.a4,
        margin: const pw.EdgeInsets.all(32),
        build: (pw.Context context) {
          double runningBalanceTracker = openingBal;

          return [
            // 1. HEADER BLOCK (65% LEFT / 35% RIGHT SPLIT)
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
                        crossAxisAlignment: pw.CrossAxisAlignment.center,
                        children: [
                          if (logoImage != null)
                            pw.Container(
                              height: 50,
                              width: 75,
                              margin: const pw.EdgeInsets.only(right: 10),
                              child: pw.Image(logoImage, fit: pw.BoxFit.contain),
                            ),
                          pw.Expanded(
                            child: pw.Column(
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
                          ),
                        ],
                      ),
                      pw.SizedBox(height: 6),
                      if (company?.address != null && company!.address!.isNotEmpty)
                        pw.Text('Address: ${company!.address}', style: const pw.TextStyle(fontSize: 8.5)),
                      if ((company?.phone != null && company!.phone!.isNotEmpty) ||
                          (company?.email != null && company!.email!.isNotEmpty))
                        pw.RichText(
                          text: pw.TextSpan(
                            children: [
                              if (company?.phone != null && company!.phone!.isNotEmpty)
                                pw.TextSpan(text: 'Phone: ${company!.phone}  ', style: const pw.TextStyle(fontSize: 8.5)),
                              if (company?.email != null && company!.email!.isNotEmpty)
                                pw.TextSpan(text: 'Email: ${company!.email}', style: const pw.TextStyle(fontSize: 8.5)),
                            ],
                          ),
                        ),
                      if (company?.gstNumber != null && company!.gstNumber!.isNotEmpty)
                        pw.Text('GSTIN: ${company!.gstNumber}${companyStateStr.isNotEmpty ? " (State: $companyStateStr)" : ""}', style: const pw.TextStyle(fontSize: 8.5)),
                    ],
                  ),
                ),
                pw.Expanded(
                  flex: 35,
                  child: pw.Column(
                    crossAxisAlignment: pw.CrossAxisAlignment.end,
                    children: [
                      pw.Text('Statement of Account', style: pw.TextStyle(fontSize: 15, fontWeight: pw.FontWeight.bold, color: PdfColors.black)),
                      pw.SizedBox(height: 6),
                      pw.Text('Period: $startDateStr to $endDateStr', style: pw.TextStyle(fontSize: 8.5, fontWeight: pw.FontWeight.bold)),
                      pw.Text('Generated: ${DateTime.now().day}-${DateTime.now().month}-${DateTime.now().year}', style: const pw.TextStyle(fontSize: 8)),
                    ],
                  ),
                ),
              ],
            ),

            pw.SizedBox(height: 10),
            pw.Divider(thickness: 1, color: PdfColors.black),
            pw.SizedBox(height: 8),

            // 2. CUSTOMER & FINANCIAL SUMMARY BOX (65% / 35% SPLIT)
            pw.Container(
              padding: const pw.EdgeInsets.all(10),
              decoration: pw.BoxDecoration(
                border: pw.Border.all(color: PdfColors.grey400, width: 0.8),
                borderRadius: const pw.BorderRadius.all(pw.Radius.circular(4)),
              ),
              child: pw.Row(
                crossAxisAlignment: pw.CrossAxisAlignment.start,
                children: [
                  // Left 65%: Customer Details
                  pw.Expanded(
                    flex: 65,
                    child: pw.Column(
                      crossAxisAlignment: pw.CrossAxisAlignment.start,
                      children: [
                        pw.Text('STATEMENT FOR:', style: pw.TextStyle(fontSize: 8, fontWeight: pw.FontWeight.bold, color: PdfColors.black)),
                        pw.SizedBox(height: 2),
                        pw.Text(customer.name ?? 'Customer Name', style: pw.TextStyle(fontSize: 11, fontWeight: pw.FontWeight.bold)),
                        if (customer.contactPerson != null && customer.contactPerson!.isNotEmpty)
                          pw.Text('Attn: ${customer.contactPerson}', style: const pw.TextStyle(fontSize: 8.5)),
                        if (customer.address != null && customer.address!.isNotEmpty)
                          pw.Text(customer.address!, style: const pw.TextStyle(fontSize: 8.5)),
                        if (customer.phone != null && customer.phone!.isNotEmpty)
                          pw.Text('Phone: ${customer.phone}', style: const pw.TextStyle(fontSize: 8.5)),
                        if (customer.gstNumber != null && customer.gstNumber!.isNotEmpty)
                          pw.Text('GSTIN: ${customer.gstNumber}', style: pw.TextStyle(fontSize: 8.5, fontWeight: pw.FontWeight.bold)),
                      ],
                    ),
                  ),

                  // Divider
                  pw.Container(
                    width: 0.7,
                    height: 55,
                    margin: const pw.EdgeInsets.symmetric(horizontal: 10),
                    color: PdfColors.grey400,
                  ),

                  // Right 35%: Financial Summary Box
                  pw.Expanded(
                    flex: 35,
                    child: pw.Column(
                      crossAxisAlignment: pw.CrossAxisAlignment.start,
                      children: [
                        pw.Text('ACCOUNT SUMMARY:', style: pw.TextStyle(fontSize: 8, fontWeight: pw.FontWeight.bold, color: PdfColors.black)),
                        pw.SizedBox(height: 4),
                        pw.Row(
                          mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                          children: [
                            pw.Text('Opening Bal:', style: const pw.TextStyle(fontSize: 8)),
                            pw.Text('Rs ${openingBal.toStringAsFixed(2)}', style: pw.TextStyle(fontSize: 8, fontWeight: pw.FontWeight.bold)),
                          ],
                        ),
                        pw.Row(
                          mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                          children: [
                            pw.Text('Total Billed (Dr):', style: const pw.TextStyle(fontSize: 8)),
                            pw.Text('Rs ${totalBilled.toStringAsFixed(2)}', style: const pw.TextStyle(fontSize: 8)),
                          ],
                        ),
                        pw.Row(
                          mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                          children: [
                            pw.Text('Total Recd (Cr):', style: const pw.TextStyle(fontSize: 8)),
                            pw.Text('Rs ${totalReceived.toStringAsFixed(2)}', style: const pw.TextStyle(fontSize: 8)),
                          ],
                        ),
                        pw.Divider(thickness: 0.5, color: PdfColors.grey400),
                        pw.Row(
                          mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                          children: [
                            pw.Text('NET DUE:', style: pw.TextStyle(fontSize: 9, fontWeight: pw.FontWeight.bold)),
                            pw.Text('Rs ${netOutstanding.toStringAsFixed(2)}', style: pw.TextStyle(fontSize: 10, fontWeight: pw.FontWeight.bold, color: PdfColors.black)),
                          ],
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),

            pw.SizedBox(height: 14),

            // 3. 6-COLUMN UNIFIED RUNNING LEDGER TABLE
            pw.Table(
              border: pw.TableBorder.all(color: PdfColors.grey400, width: 0.5),
              columnWidths: {
                0: const pw.FlexColumnWidth(1.1), // Date (11%)
                1: const pw.FlexColumnWidth(1.3), // Reference # (13%)
                2: const pw.FlexColumnWidth(3.0), // Transaction Details (30%)
                3: const pw.FlexColumnWidth(1.4), // Debit Dr. (14%)
                4: const pw.FlexColumnWidth(1.4), // Credit Cr. (14%)
                5: const pw.FlexColumnWidth(1.8), // Running Balance (18%)
              },
              children: [
                // Header Row
                pw.TableRow(
                  decoration: const pw.BoxDecoration(color: PdfColors.grey200),
                  children: [
                    _th('Date'),
                    _th('Reference #'),
                    _th('Transaction Details'),
                    _th('Debit (Dr) Rs', align: pw.TextAlign.right),
                    _th('Credit (Cr) Rs', align: pw.TextAlign.right),
                    _th('Running Bal Rs', align: pw.TextAlign.right),
                  ],
                ),
                // Opening Balance Row
                pw.TableRow(
                  children: [
                    _td(startDateStr),
                    _td('-'),
                    _td('Opening Balance', isBold: true),
                    _td('-'),
                    _td('-'),
                    _td(openingBal.toStringAsFixed(2), align: pw.TextAlign.right, isBold: true),
                  ],
                ),
                // Ledger Transaction Rows
                ...entries.map((entry) {
                  runningBalanceTracker = runningBalanceTracker + entry.debit - entry.credit;

                  return pw.TableRow(
                    children: [
                      _td(entry.dateStr),
                      _td(entry.referenceNo, isBold: true),
                      _td(entry.details),
                      _td(entry.debit > 0 ? entry.debit.toStringAsFixed(2) : '-', align: pw.TextAlign.right),
                      _td(entry.credit > 0 ? entry.credit.toStringAsFixed(2) : '-', align: pw.TextAlign.right),
                      _td(runningBalanceTracker.toStringAsFixed(2), align: pw.TextAlign.right, isBold: true),
                    ],
                  );
                }),
                // Total Summary Row
                pw.TableRow(
                  decoration: const pw.BoxDecoration(color: PdfColors.grey100),
                  children: [
                    _td('TOTAL', isBold: true),
                    _td(''),
                    _td('${entries.length} Transactions', isBold: true),
                    _td(totalBilled.toStringAsFixed(2), align: pw.TextAlign.right, isBold: true),
                    _td(totalReceived.toStringAsFixed(2), align: pw.TextAlign.right, isBold: true),
                    _td(netOutstanding.toStringAsFixed(2), align: pw.TextAlign.right, isBold: true),
                  ],
                ),
              ],
            ),

            pw.SizedBox(height: 16),

            // 4. BANK DETAILS & AUTHORIZED SIGNATORY BLOCK
            pw.Row(
              crossAxisAlignment: pw.CrossAxisAlignment.start,
              children: [
                // Left: Bank Details
                pw.Expanded(
                  flex: 6,
                  child: company?.bankName != null && company!.bankName!.isNotEmpty
                      ? pw.Container(
                          padding: const pw.EdgeInsets.all(6),
                          decoration: pw.BoxDecoration(
                            border: pw.Border.all(color: PdfColors.grey300, width: 0.5),
                            borderRadius: const pw.BorderRadius.all(pw.Radius.circular(4)),
                          ),
                          child: pw.Column(
                            crossAxisAlignment: pw.CrossAxisAlignment.start,
                            children: [
                              pw.Text('COMPANY BANK DETAILS:', style: pw.TextStyle(fontSize: 7.5, fontWeight: pw.FontWeight.bold)),
                              pw.SizedBox(height: 2),
                              pw.Text('Bank: ${company.bankName}${company.bankBranch != null && company.bankBranch!.isNotEmpty ? " (${company.bankBranch})" : ""}', style: const pw.TextStyle(fontSize: 7.5)),
                              if (company.accountNumber != null) pw.Text('A/C No: ${company.accountNumber}', style: pw.TextStyle(fontSize: 7.5, fontWeight: pw.FontWeight.bold)),
                              if (company.ifscCode != null) pw.Text('IFSC: ${company.ifscCode}', style: const pw.TextStyle(fontSize: 7.5)),
                              if (company.upiId != null && company.upiId!.isNotEmpty) pw.Text('UPI ID: ${company.upiId}', style: const pw.TextStyle(fontSize: 7.5)),
                            ],
                          ),
                        )
                      : pw.SizedBox(),
                ),

                pw.SizedBox(width: 20),

                // Right: Signatory Block
                pw.Expanded(
                  flex: 4,
                  child: pw.Column(
                    crossAxisAlignment: pw.CrossAxisAlignment.center,
                    children: [
                      if (signatureImage != null)
                        pw.Container(
                          height: 40,
                          width: 90,
                          margin: const pw.EdgeInsets.only(bottom: 2),
                          child: pw.Image(signatureImage, fit: pw.BoxFit.contain),
                        )
                      else
                        pw.SizedBox(height: 30),
                      pw.Text('For ${company?.name ?? "Company"}', style: pw.TextStyle(fontSize: 8.5, fontWeight: pw.FontWeight.bold)),
                      pw.Text('Authorized Signatory', style: const pw.TextStyle(fontSize: 7.5, color: PdfColors.black)),
                    ],
                  ),
                ),
              ],
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

  /// Builds a Comprehensive Period Sales Report PDF (Monthly, Yearly, Custom Range)
  static Future<Uint8List> buildSalesReport({
    required Company? company,
    required String periodTitle,
    required List<Invoice> invoices,
    required double totalSales,
    required double totalTaxable,
    required double totalCgst,
    required double totalSgst,
    required double totalIgst,
    required double totalReceived,
    required double totalOutstanding,
    required Map<String, Map<String, dynamic>> productSalesMap,
    required Map<String, Map<String, dynamic>> customerSalesMap,
  }) async {
    final pdf = pw.Document();

    pw.MemoryImage? logoImage;
    if (company?.logoBase64 != null && company!.logoBase64!.isNotEmpty) {
      try {
        logoImage = pw.MemoryImage(base64Decode(company.logoBase64!));
      } catch (_) {}
    }

    final double totalTax = totalCgst + totalSgst + totalIgst;

    pdf.addPage(
      pw.MultiPage(
        pageFormat: PdfPageFormat.a4,
        margin: const pw.EdgeInsets.all(32),
        build: (pw.Context context) {
          return [
            // Title Header
            pw.Row(
              mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
              crossAxisAlignment: pw.CrossAxisAlignment.start,
              children: [
                pw.Expanded(
                  child: pw.Row(
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
                          pw.Text(company?.name ?? 'Company', style: pw.TextStyle(fontSize: 15, fontWeight: pw.FontWeight.bold)),
                          if (company?.gstNumber != null && company!.gstNumber!.isNotEmpty)
                            pw.Text('GSTIN: ${company.gstNumber}', style: const pw.TextStyle(fontSize: 8.5)),
                          if (company?.phone != null && company!.phone!.isNotEmpty)
                            pw.Text('Phone: ${company.phone}', style: const pw.TextStyle(fontSize: 8.5)),
                        ],
                      ),
                    ],
                  ),
                ),
                pw.Column(
                  crossAxisAlignment: pw.CrossAxisAlignment.end,
                  children: [
                    pw.Text('SALES PERFORMANCE REPORT', style: pw.TextStyle(fontSize: 13, fontWeight: pw.FontWeight.bold, color: PdfColors.blue800)),
                    pw.Text(periodTitle, style: pw.TextStyle(fontSize: 9.5, fontWeight: pw.FontWeight.bold)),
                    pw.Text('Generated: ${DateTime.now().day}-${DateTime.now().month}-${DateTime.now().year}', style: const pw.TextStyle(fontSize: 7.5, color: PdfColors.grey700)),
                  ],
                ),
              ],
            ),
            pw.SizedBox(height: 8),
            pw.Divider(thickness: 1, color: PdfColors.black),
            pw.SizedBox(height: 8),

            // Key Metrics Summary Table
            pw.Text('REVENUE & FINANCIAL SUMMARY', style: pw.TextStyle(fontSize: 9.5, fontWeight: pw.FontWeight.bold)),
            pw.SizedBox(height: 4),
            pw.Table(
              border: pw.TableBorder.all(color: PdfColors.grey400, width: 0.5),
              children: [
                pw.TableRow(
                  decoration: const pw.BoxDecoration(color: PdfColors.grey200),
                  children: [
                    _th('Total Invoices'),
                    _th('Total Billed Sales'),
                    _th('Taxable Base'),
                    _th('Total Tax (GST)'),
                    _th('Total Received'),
                    _th('Outstanding Due'),
                  ],
                ),
                pw.TableRow(
                  children: [
                    _td('${invoices.length}', align: pw.TextAlign.center, isBold: true),
                    _td('Rs ${totalSales.toStringAsFixed(2)}', align: pw.TextAlign.right, isBold: true),
                    _td('Rs ${totalTaxable.toStringAsFixed(2)}', align: pw.TextAlign.right),
                    _td('Rs ${totalTax.toStringAsFixed(2)}', align: pw.TextAlign.right),
                    _td('Rs ${totalReceived.toStringAsFixed(2)}', align: pw.TextAlign.right),
                    _td('Rs ${totalOutstanding.toStringAsFixed(2)}', align: pw.TextAlign.right, isBold: true),
                  ],
                ),
              ],
            ),

            // Product-Wise Sales Breakdown
            if (productSalesMap.isNotEmpty) ...[
              pw.SizedBox(height: 14),
              pw.Text('PRODUCT-WISE SALES SUMMARY', style: pw.TextStyle(fontSize: 9.5, fontWeight: pw.FontWeight.bold)),
              pw.SizedBox(height: 4),
              pw.Table(
                border: pw.TableBorder.all(color: PdfColors.grey400, width: 0.5),
                columnWidths: {
                  0: const pw.FlexColumnWidth(3),
                  1: const pw.FlexColumnWidth(1.5),
                  2: const pw.FlexColumnWidth(1.5),
                },
                children: [
                  pw.TableRow(
                    decoration: const pw.BoxDecoration(color: PdfColors.grey200),
                    children: [
                      _th('Product Name'),
                      _th('Quantity Sold'),
                      _th('Total Revenue (Rs)'),
                    ],
                  ),
                  ...productSalesMap.entries.map((e) {
                    final data = e.value;
                    return pw.TableRow(
                      children: [
                        _td(e.key, isBold: true),
                        _td('${data['qty']} ${data['unit'] ?? ""}', align: pw.TextAlign.center),
                        _td((data['revenue'] as double).toStringAsFixed(2), align: pw.TextAlign.right),
                      ],
                    );
                  }),
                ],
              ),
            ],

            // Customer-Wise Sales Breakdown
            if (customerSalesMap.isNotEmpty) ...[
              pw.SizedBox(height: 14),
              pw.Text('CUSTOMER-WISE SALES SUMMARY', style: pw.TextStyle(fontSize: 9.5, fontWeight: pw.FontWeight.bold)),
              pw.SizedBox(height: 4),
              pw.Table(
                border: pw.TableBorder.all(color: PdfColors.grey400, width: 0.5),
                columnWidths: {
                  0: const pw.FlexColumnWidth(2.5),
                  1: const pw.FlexColumnWidth(1),
                  2: const pw.FlexColumnWidth(1.5),
                  3: const pw.FlexColumnWidth(1.5),
                  4: const pw.FlexColumnWidth(1.5),
                },
                children: [
                  pw.TableRow(
                    decoration: const pw.BoxDecoration(color: PdfColors.grey200),
                    children: [
                      _th('Customer Name'),
                      _th('Invoices'),
                      _th('Total Billed (Rs)'),
                      _th('Received (Rs)'),
                      _th('Balance Due (Rs)'),
                    ],
                  ),
                  ...customerSalesMap.entries.map((e) {
                    final data = e.value;
                    return pw.TableRow(
                      children: [
                        _td(e.key, isBold: true),
                        _td('${data['count']}', align: pw.TextAlign.center),
                        _td((data['billed'] as double).toStringAsFixed(2), align: pw.TextAlign.right),
                        _td((data['received'] as double).toStringAsFixed(2), align: pw.TextAlign.right),
                        _td((data['balance'] as double).toStringAsFixed(2), align: pw.TextAlign.right, isBold: (data['balance'] as double) > 0),
                      ],
                    );
                  }),
                ],
              ),
            ],

            // Invoice Breakdown Schedule
            pw.SizedBox(height: 14),
            pw.Text('INVOICES SCHEDULE (${invoices.length} Records)', style: pw.TextStyle(fontSize: 9.5, fontWeight: pw.FontWeight.bold)),
            pw.SizedBox(height: 4),
            pw.Table(
              border: pw.TableBorder.all(color: PdfColors.grey400, width: 0.5),
              columnWidths: {
                0: const pw.FlexColumnWidth(1.1),
                1: const pw.FlexColumnWidth(1.1),
                2: const pw.FlexColumnWidth(2.2),
                3: const pw.FlexColumnWidth(1.1),
                4: const pw.FlexColumnWidth(1.2),
                5: const pw.FlexColumnWidth(1.1),
                6: const pw.FlexColumnWidth(1.3),
              },
              children: [
                pw.TableRow(
                  decoration: const pw.BoxDecoration(color: PdfColors.grey200),
                  children: [
                    _th('Invoice #'),
                    _th('Date'),
                    _th('Customer'),
                    _th('Status'),
                    _th('Taxable (Rs)'),
                    _th('Tax (Rs)'),
                    _th('Total (Rs)'),
                  ],
                ),
                ...invoices.map((inv) {
                  return pw.TableRow(
                    children: [
                      _td(inv.invoiceNumber, isBold: true),
                      _td(inv.date),
                      _td(inv.customerName ?? 'Cash'),
                      _td(inv.status),
                      _td(inv.taxableBase.toStringAsFixed(2), align: pw.TextAlign.right),
                      _td((inv.cgstTotal + inv.sgstTotal + inv.igstTotal).toStringAsFixed(2), align: pw.TextAlign.right),
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
