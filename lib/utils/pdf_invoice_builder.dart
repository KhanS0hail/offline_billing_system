import 'dart:convert';
import 'dart:typed_data';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import '../models/invoice.dart';
import '../models/company.dart';
import 'number_to_words.dart';
import 'state_codes.dart';

class PdfInvoiceBuilder {
  static Future<Uint8List> buildPdf({
    required Invoice invoice,
    required Company? company,
  }) async {
    final pdf = pw.Document();

    // Memory Images for Logo and Signature
    pw.MemoryImage? logoImage;
    pw.MemoryImage? signatureImage;

    if (company?.logoBase64 != null && company!.logoBase64!.isNotEmpty) {
      try {
        final logoBytes = base64Decode(company.logoBase64!);
        logoImage = pw.MemoryImage(logoBytes);
      } catch (_) {}
    }

    if (company?.signatureBase64 != null && company!.signatureBase64!.isNotEmpty) {
      try {
        final sigBytes = base64Decode(company.signatureBase64!);
        signatureImage = pw.MemoryImage(sigBytes);
      } catch (_) {}
    }

    final amountInWords = NumberToWords.convert(invoice.grandTotal);
    final companyStateStr = StateCodes.getFormattedState(company?.stateCode);
    final billedStateStr = StateCodes.getFormattedState(invoice.customerStateCode);
    final shippedStateStr = StateCodes.getFormattedState(invoice.shippingStateCode.toString().isNotEmpty ? invoice.shippingStateCode : invoice.customerStateCode);

    final isIntraState = (company?.stateCode != null &&
        invoice.customerStateCode != null &&
        company!.stateCode!.trim().isNotEmpty &&
        company.stateCode!.trim() == invoice.customerStateCode!.trim());

    final supplyTypeStr = isIntraState ? 'Intra-State (CGST + SGST)' : 'Inter-State (IGST)';
    final deliveryDateStr = (invoice.deliveryDate != null && invoice.deliveryDate!.trim().isNotEmpty)
        ? invoice.deliveryDate!
        : invoice.date;

    // Multi-Unit Smart Aggregation for PCS and QTY
    Map<String, double> pcsMap = {};
    Map<String, double> qtyMap = {};

    for (var item in invoice.items) {
      // 1. PCS Column Unit Aggregation
      final rawPcs = item.pcsCount?.trim() ?? '';
      if (rawPcs.isNotEmpty) {
        final match = RegExp(r'^([\d.]+)\s*(.*)$').firstMatch(rawPcs);
        if (match != null) {
          double val = double.tryParse(match.group(1)!) ?? 0.0;
          String unit = match.group(2)!.trim();
          if (unit.isEmpty) unit = 'Pcs';
          pcsMap[unit] = (pcsMap[unit] ?? 0.0) + val;
        } else {
          pcsMap[rawPcs] = (pcsMap[rawPcs] ?? 0.0) + 1;
        }
      }

      // 2. Quantity Column Unit Aggregation
      String qUnit = item.unit.trim();
      if (qUnit.isEmpty) qUnit = 'Pcs';
      qtyMap[qUnit] = (qtyMap[qUnit] ?? 0.0) + item.quantity;
    }

    String totalPcsStr = pcsMap.entries.map((e) {
      String valStr = e.value.truncateToDouble() == e.value ? e.value.toInt().toString() : e.value.toStringAsFixed(2);
      return "$valStr ${e.key}";
    }).join(', ');

    String totalQtyStr = qtyMap.entries.map((e) {
      String valStr = e.value.truncateToDouble() == e.value ? e.value.toInt().toString() : e.value.toStringAsFixed(2);
      return "$valStr ${e.key}";
    }).join(', ');

    if (totalPcsStr.isEmpty) totalPcsStr = '-';
    if (totalQtyStr.isEmpty) totalQtyStr = '-';

    // Parse T&C items into structured list
    List<String> tcItems = [];
    if (company?.termsAndConditions != null && company!.termsAndConditions!.trim().isNotEmpty) {
      final rawTc = company.termsAndConditions!.trim();
      final lines = rawTc.split('\n');
      for (var l in lines) {
        final trimmed = l.trim();
        if (trimmed.isNotEmpty) {
          final cleaned = trimmed.replaceFirst(RegExp(r'^\d+[\.\)\]]\s*'), '');
          if (cleaned.isNotEmpty) tcItems.add(cleaned);
        }
      }
    }

    // Fixed Minimum 6 Table Rows as default
    const int minTableRows = 6;
    final int emptyRowsCount = minTableRows - invoice.items.length;

    pdf.addPage(
      pw.MultiPage(
        pageFormat: PdfPageFormat.a4,
        margin: const pw.EdgeInsets.all(32),
        build: (pw.Context context) {
          return [
            // 1. TOP HEADER BLOCK (70% LEFT / 30% RIGHT SPLIT WITH 5PT RIGHT PADDING ON LEFT COL)
            pw.Row(
              crossAxisAlignment: pw.CrossAxisAlignment.start,
              mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
              children: [
                // LEFT SIDE: LOGO + TITLE + ADDRESS BLOCK (70% width)
                pw.Expanded(
                  flex: 70,
                  child: pw.Padding(
                    padding: const pw.EdgeInsets.only(right: 5),
                    child: pw.Column(
                      crossAxisAlignment: pw.CrossAxisAlignment.start,
                      children: [
                        // Logo + Company Title & Subtitle side-by-side
                        pw.Row(
                          crossAxisAlignment: pw.CrossAxisAlignment.center,
                          children: [
                            if (logoImage != null)
                              pw.Container(
                                height: 55,
                                width: 80,
                                margin: const pw.EdgeInsets.only(right: 10),
                                child: pw.Image(logoImage, fit: pw.BoxFit.contain),
                              ),
                            pw.Expanded(
                              child: pw.Column(
                                crossAxisAlignment: pw.CrossAxisAlignment.start,
                                children: [
                                  pw.Text(
                                    company?.name ?? 'Regal Steel Trader',
                                    style: pw.TextStyle(fontSize: 22, fontWeight: pw.FontWeight.bold, color: PdfColors.black),
                                  ),
                                  pw.SizedBox(height: 2),
                                  if (company?.tagline != null && company!.tagline!.isNotEmpty)
                                    pw.Text(
                                      company.tagline!,
                                      style: pw.TextStyle(fontSize: 8, fontStyle: pw.FontStyle.italic, color: PdfColors.black),
                                    ),
                                ],
                              ),
                            ),
                          ],
                        ),
                        pw.SizedBox(height: 10),

                        // Address, Phone (Separate Row), Email (Separate Row), GSTIN, State
                        if (company?.address != null && company!.address!.isNotEmpty)
                          pw.RichText(
                            text: pw.TextSpan(
                              children: [
                                pw.TextSpan(text: 'Address: ', style: pw.TextStyle(fontWeight: pw.FontWeight.bold, fontSize: 9.5)),
                                pw.TextSpan(text: company.address!, style: const pw.TextStyle(fontSize: 9.5)),
                              ],
                            ),
                          ),
                        if (company?.phone != null && company!.phone!.isNotEmpty) ...[
                          pw.SizedBox(height: 2),
                          pw.RichText(
                            text: pw.TextSpan(
                              children: [
                                pw.TextSpan(text: 'Phone: ', style: pw.TextStyle(fontWeight: pw.FontWeight.bold, fontSize: 9.5)),
                                pw.TextSpan(text: '${company.phone}', style: const pw.TextStyle(fontSize: 9.5)),
                              ],
                            ),
                          ),
                        ],
                        if (company?.email != null && company!.email!.isNotEmpty) ...[
                          pw.SizedBox(height: 2),
                          pw.RichText(
                            text: pw.TextSpan(
                              children: [
                                pw.TextSpan(text: 'Email: ', style: pw.TextStyle(fontWeight: pw.FontWeight.bold, fontSize: 9.5)),
                                pw.TextSpan(text: '${company.email}', style: const pw.TextStyle(fontSize: 9.5)),
                              ],
                            ),
                          ),
                        ],
                        if (company?.gstNumber != null && company!.gstNumber!.isNotEmpty) ...[
                          pw.SizedBox(height: 2),
                          pw.RichText(
                            text: pw.TextSpan(
                              children: [
                                pw.TextSpan(text: 'GSTIN: ', style: pw.TextStyle(fontWeight: pw.FontWeight.bold, fontSize: 9.5)),
                                pw.TextSpan(text: company.gstNumber!, style: const pw.TextStyle(fontSize: 9.5)),
                              ],
                            ),
                          ),
                        ],
                        if (companyStateStr.isNotEmpty) ...[
                          pw.SizedBox(height: 2),
                          pw.RichText(
                            text: pw.TextSpan(
                              children: [
                                pw.TextSpan(text: 'State: ', style: pw.TextStyle(fontWeight: pw.FontWeight.bold, fontSize: 9.5)),
                                pw.TextSpan(text: companyStateStr, style: const pw.TextStyle(fontSize: 9.5)),
                              ],
                            ),
                          ),
                        ],
                      ],
                    ),
                  ),
                ),

                pw.SizedBox(width: 10),

                // RIGHT SIDE: TAX INVOICE TITLE (16pt, weight 800) + METADATA TABLE (30% width)
                pw.Expanded(
                  flex: 30,
                  child: pw.Column(
                    crossAxisAlignment: pw.CrossAxisAlignment.end,
                    children: [
                      // TAX INVOICE Title: 16pt, bold (weight 800)
                      pw.Text(
                        invoice.invoiceType.toUpperCase(),
                        style: pw.TextStyle(fontSize: 16, fontWeight: pw.FontWeight.bold, color: PdfColors.black),
                        textAlign: pw.TextAlign.right,
                      ),
                      pw.SizedBox(height: 6),

                      // Dedicated Key-Colon-Value Table (46% Key, 4% Colon, 50% Value)
                      pw.Table(
                        columnWidths: {
                          0: const pw.FlexColumnWidth(0.46), // Col 1: 46% Key (Left Aligned)
                          1: const pw.FlexColumnWidth(0.04), // Col 2: 4% Colon (Centered)
                          2: const pw.FlexColumnWidth(0.50), // Col 3: 50% Value (Right Aligned)
                        },
                        children: [
                          _keyColonValueRow('Invoice No.', invoice.invoiceNumber),
                          if (invoice.challanNumber != null && invoice.challanNumber!.trim().isNotEmpty)
                            _keyColonValueRow('Challan No.', invoice.challanNumber!),
                          _keyColonValueRow('Invoice Date', invoice.date),
                          _keyColonValueRow('Delivery Date', deliveryDateStr),
                          if (invoice.dueDate != null && invoice.dueDate!.isNotEmpty)
                            _keyColonValueRow('Payment Due', invoice.dueDate!, isBoldValue: true),
                          if (invoice.vehicleNumber != null && invoice.vehicleNumber!.trim().isNotEmpty)
                            _keyColonValueRow('Vehicle No.', invoice.vehicleNumber!),
                          if (invoice.transportMode != null && invoice.transportMode!.trim().isNotEmpty)
                            _keyColonValueRow('Transport', invoice.transportMode!),
                        ],
                      ),
                    ],
                  ),
                ),
              ],
            ),

            pw.SizedBox(height: 10),

            // 2. BILLED TO & SHIPPED TO (WITH VERTICALLY CENTERED HALF-HEIGHT SUBTLE DIVIDER)
            pw.Container(
              padding: const pw.EdgeInsets.symmetric(vertical: 8),
              decoration: const pw.BoxDecoration(
                border: pw.Border(
                  top: pw.BorderSide(color: PdfColors.black, width: 1),
                  bottom: pw.BorderSide(color: PdfColors.black, width: 1),
                ),
              ),
              child: pw.Row(
                crossAxisAlignment: pw.CrossAxisAlignment.center, // Centered alignment for vertical divider
                children: [
                  // COL 1: BILLED TO
                  pw.Expanded(
                    child: pw.Column(
                      crossAxisAlignment: pw.CrossAxisAlignment.start,
                      children: [
                        pw.Text('BILLED TO:', style: pw.TextStyle(fontSize: 9, fontWeight: pw.FontWeight.bold, color: PdfColors.black)),
                        pw.SizedBox(height: 2),
                        pw.Text(
                          invoice.customerName ?? 'Cash / Walk-in Customer',
                          style: pw.TextStyle(fontSize: 11, fontWeight: pw.FontWeight.bold),
                        ),
                        if (invoice.customerAddress != null && invoice.customerAddress!.isNotEmpty)
                          pw.Text(invoice.customerAddress!, style: const pw.TextStyle(fontSize: 8.5)),
                        if (invoice.customerGstin != null && invoice.customerGstin!.isNotEmpty)
                          pw.Text('GSTIN: ${invoice.customerGstin}', style: pw.TextStyle(fontSize: 8.5, fontWeight: pw.FontWeight.bold)),
                        if (billedStateStr.isNotEmpty)
                          pw.Text('State: $billedStateStr', style: pw.TextStyle(fontSize: 8.5, fontWeight: pw.FontWeight.bold)),
                      ],
                    ),
                  ),

                  // VERTICALLY CENTERED HALF-HEIGHT SUBTLE GREY DIVIDER LINE
                  pw.Container(
                    width: 0.7,
                    height: 42, // Half-height (~42pt)
                    margin: const pw.EdgeInsets.symmetric(horizontal: 14),
                    color: PdfColors.grey400, // Subtle low-opacity grey
                  ),

                  // COL 2: SHIPPED TO
                  pw.Expanded(
                    child: pw.Column(
                      crossAxisAlignment: pw.CrossAxisAlignment.start,
                      children: [
                        pw.Text('SHIPPED TO:', style: pw.TextStyle(fontSize: 9, fontWeight: pw.FontWeight.bold, color: PdfColors.black)),
                        pw.SizedBox(height: 2),
                        pw.Text(
                          (invoice.shippingCustomerName != null && invoice.shippingCustomerName!.isNotEmpty)
                              ? invoice.shippingCustomerName!
                              : (invoice.customerName ?? 'Cash / Walk-in Customer'),
                          style: pw.TextStyle(fontSize: 11, fontWeight: pw.FontWeight.bold),
                        ),
                        if ((invoice.shippingAddress != null && invoice.shippingAddress!.isNotEmpty) ||
                            (invoice.customerAddress != null && invoice.customerAddress!.isNotEmpty))
                          pw.Text(
                            (invoice.shippingAddress != null && invoice.shippingAddress!.isNotEmpty)
                                ? invoice.shippingAddress!
                                : invoice.customerAddress!,
                            style: const pw.TextStyle(fontSize: 8.5),
                          ),
                        if ((invoice.shippingGstin != null && invoice.shippingGstin!.isNotEmpty) ||
                            (invoice.customerGstin != null && invoice.customerGstin!.isNotEmpty))
                          pw.Text(
                            'GSTIN: ${(invoice.shippingGstin != null && invoice.shippingGstin!.isNotEmpty) ? invoice.shippingGstin! : invoice.customerGstin!}',
                            style: pw.TextStyle(fontSize: 8.5, fontWeight: pw.FontWeight.bold),
                          ),
                        if (shippedStateStr.isNotEmpty)
                          pw.Text('State: $shippedStateStr', style: pw.TextStyle(fontSize: 8.5, fontWeight: pw.FontWeight.bold)),
                        pw.SizedBox(height: 1),
                        pw.RichText(
                          text: pw.TextSpan(
                            children: [
                              pw.TextSpan(text: 'Supply Type: ', style: pw.TextStyle(fontWeight: pw.FontWeight.bold, fontSize: 8.5, color: PdfColors.black)),
                              pw.TextSpan(text: supplyTypeStr, style: pw.TextStyle(fontWeight: pw.FontWeight.bold, fontSize: 8.5, color: PdfColors.black)),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),

            pw.SizedBox(height: 12),

            // 3. LINE ITEMS TABLE BLOCK
            pw.Table(
              border: const pw.TableBorder(
                bottom: pw.BorderSide(color: PdfColors.black, width: 1),
              ),
              columnWidths: {
                0: const pw.FlexColumnWidth(0.5), // 1. S.No (5%)
                1: const pw.FlexColumnWidth(2.4), // 2. Item & Description (24%)
                2: const pw.FlexColumnWidth(1.8), // 3. Size (18%)
                3: const pw.FlexColumnWidth(1.1), // 4. HSN/SAC Code (11%)
                4: const pw.FlexColumnWidth(0.9), // 5. PCS (9%)
                5: const pw.FlexColumnWidth(1.2), // 6. Quantity / Unit (12%)
                6: const pw.FlexColumnWidth(0.9), // 7. Rate Per Unit (9%)
                7: const pw.FlexColumnWidth(1.2), // 8. Amount (Rs) (12%)
              },
              children: [
                // Table Header Row
                pw.TableRow(
                  decoration: const pw.BoxDecoration(
                    border: pw.Border(bottom: pw.BorderSide(color: PdfColors.black, width: 1)),
                  ),
                  children: [
                    _cellHeader('S.No'),
                    _cellHeader('Item & Description', align: pw.TextAlign.left, padding: const pw.EdgeInsets.only(left: 8, right: 4, top: 4, bottom: 4)),
                    _cellHeader('Size'),
                    _cellHeader('HSN/SAC Code'),
                    _cellHeader('PCS'),
                    _cellHeader('Quantity / Unit'),
                    _cellHeader('Rate Per Unit'),
                    _cellHeader('Amount (Rs)'),
                  ],
                ),
                // Actual Item Rows
                ...invoice.items.asMap().entries.map((entry) {
                  final idx = entry.key + 1;
                  final item = entry.value;
                  return pw.TableRow(
                    children: [
                      _cellContent(idx.toString(), align: pw.TextAlign.center),
                      _cellContent(item.productName, isBold: true, padding: const pw.EdgeInsets.only(left: 8, right: 4, top: 2, bottom: 2)),
                      _cellContent(item.size ?? '-', align: pw.TextAlign.center),
                      _cellContent(item.hsnCode ?? '-', align: pw.TextAlign.center),
                      _cellContent(item.pcsCount ?? '-', align: pw.TextAlign.center),
                      _cellContent('${item.quantity} ${item.unit}', align: pw.TextAlign.center),
                      _cellContent(item.price.toStringAsFixed(2), align: pw.TextAlign.center),
                      _cellContent(item.amount.toStringAsFixed(2), align: pw.TextAlign.right, isBold: true),
                    ],
                  );
                }),

                // Empty Rows padding up to minTableRows (6 rows default)
                ...List.generate(emptyRowsCount > 0 ? emptyRowsCount : 0, (index) {
                  return pw.TableRow(
                    children: [
                      _cellContent('', align: pw.TextAlign.center),
                      _cellContent(''),
                      _cellContent(''),
                      _cellContent(''),
                      _cellContent(''),
                      _cellContent(''),
                      _cellContent(''),
                      _cellContent(''),
                    ],
                  );
                }),

                // Table Footer Totals Row (Multi-Unit Grouped Sums)
                pw.TableRow(
                  decoration: const pw.BoxDecoration(
                    border: pw.Border(
                      top: pw.BorderSide(color: PdfColors.black, width: 1),
                      bottom: pw.BorderSide(color: PdfColors.black, width: 1),
                    ),
                  ),
                  children: [
                    _cellContent('', align: pw.TextAlign.center),
                    _cellContent('TOTAL', isBold: true, padding: const pw.EdgeInsets.only(left: 8, right: 4, top: 2, bottom: 2)),
                    _cellContent('-', align: pw.TextAlign.center),
                    _cellContent('-', align: pw.TextAlign.center),
                    _cellContent(totalPcsStr, align: pw.TextAlign.center, isBold: true),
                    _cellContent(totalQtyStr, align: pw.TextAlign.center, isBold: true),
                    _cellContent('', align: pw.TextAlign.center),
                    _cellContent(invoice.subtotal.toStringAsFixed(2), align: pw.TextAlign.right, isBold: true),
                  ],
                ),
              ],
            ),

            pw.SizedBox(height: 14),

            // 4. CALCULATIONS, BANK DETAILS & ITEMAZE T&C SPLIT BLOCK
            pw.Row(
              cross: pw.CrossAxisAlignment.start,
              children: [
                // Left Side: Amount in Words, Bank Info, AND Itemized T&C List
                pw.Expanded(
                  flex: 5,
                  child: pw.Column(
                    crossAxisAlignment: pw.CrossAxisAlignment.start,
                    children: [
                      pw.Container(
                        padding: const pw.EdgeInsets.symmetric(vertical: 4),
                        decoration: const pw.BoxDecoration(
                          border: pw.Border(
                            bottom: pw.BorderSide(color: PdfColors.black, width: 0.8),
                          ),
                        ),
                        child: pw.Column(
                          crossAxisAlignment: pw.CrossAxisAlignment.start,
                          children: [
                            pw.Text('AMOUNT IN WORDS:', style: pw.TextStyle(fontSize: 8, fontWeight: pw.FontWeight.bold, color: PdfColors.black)),
                            pw.Text(amountInWords, style: pw.TextStyle(fontSize: 9, fontWeight: pw.FontWeight.bold, color: PdfColors.black)),
                          ],
                        ),
                      ),
                      pw.SizedBox(height: 6),

                      // Bank Details with Vertically Aligned Colons Table
                      if ((company?.bankName != null && company!.bankName!.isNotEmpty) ||
                          (company?.accountNumber != null && company!.accountNumber!.isNotEmpty))
                        pw.Container(
                          padding: const pw.EdgeInsets.symmetric(vertical: 4),
                          decoration: const pw.BoxDecoration(
                            border: pw.Border(
                              bottom: pw.BorderSide(color: PdfColors.black, width: 0.8),
                            ),
                          ),
                          child: pw.Column(
                            crossAxisAlignment: pw.CrossAxisAlignment.start,
                            children: [
                              pw.Text('BANK & PAYMENT DETAILS:', style: pw.TextStyle(fontSize: 8, fontWeight: pw.FontWeight.bold, color: PdfColors.black)),
                              pw.SizedBox(height: 3),
                              pw.Table(
                                columnWidths: {
                                  0: const pw.FixedColumnWidth(55),
                                  1: const pw.FixedColumnWidth(10),
                                  2: const pw.FlexColumnWidth(),
                                },
                                children: [
                                  if (company?.bankName != null && company!.bankName!.isNotEmpty)
                                    pw.TableRow(
                                      children: [
                                        pw.Text('Bank', style: pw.TextStyle(fontSize: 8, fontWeight: pw.FontWeight.bold)),
                                        pw.Text(':', style: pw.TextStyle(fontSize: 8, fontWeight: pw.FontWeight.bold)),
                                        pw.Text('${company!.bankName}${company!.bankBranch != null && company!.bankBranch!.isNotEmpty ? " (${company!.bankBranch})" : ""}', style: const pw.TextStyle(fontSize: 8)),
                                      ],
                                    ),
                                  if (company?.accountNumber != null && company!.accountNumber!.isNotEmpty)
                                    pw.TableRow(
                                      children: [
                                        pw.Text('A/C No', style: pw.TextStyle(fontSize: 8, fontWeight: pw.FontWeight.bold)),
                                        pw.Text(':', style: pw.TextStyle(fontSize: 8, fontWeight: pw.FontWeight.bold)),
                                        pw.Text(company!.accountNumber!, style: pw.TextStyle(fontSize: 8, fontWeight: pw.FontWeight.bold)),
                                      ],
                                    ),
                                  if (company?.ifscCode != null && company!.ifscCode!.isNotEmpty)
                                    pw.TableRow(
                                      children: [
                                        pw.Text('IFSC Code', style: pw.TextStyle(fontSize: 8, fontWeight: pw.FontWeight.bold)),
                                        pw.Text(':', style: pw.TextStyle(fontSize: 8, fontWeight: pw.FontWeight.bold)),
                                        pw.Text(company!.ifscCode!, style: const pw.TextStyle(fontSize: 8)),
                                      ],
                                    ),
                                  if (company?.upiId != null && company!.upiId!.isNotEmpty)
                                    pw.TableRow(
                                      children: [
                                        pw.Text('UPI ID', style: pw.TextStyle(fontSize: 8, fontWeight: pw.FontWeight.bold)),
                                        pw.Text(':', style: pw.TextStyle(fontSize: 8, fontWeight: pw.FontWeight.bold)),
                                        pw.Text(company!.upiId!, style: const pw.TextStyle(fontSize: 8)),
                                      ],
                                    ),
                                ],
                              ),
                            ],
                          ),
                        ),

                      // Itemized Terms & Conditions List DIRECTLY below Bank Details
                      if (tcItems.isNotEmpty) ...[
                        pw.SizedBox(height: 6),
                        pw.Column(
                          crossAxisAlignment: pw.CrossAxisAlignment.start,
                          children: [
                            pw.Text('TERMS & CONDITIONS:', style: pw.TextStyle(fontSize: 8, fontWeight: pw.FontWeight.bold, color: PdfColors.black)),
                            pw.SizedBox(height: 2),
                            ...tcItems.asMap().entries.map((e) {
                              final idx = e.key + 1;
                              final itemText = e.value;
                              return pw.Padding(
                                padding: const pw.EdgeInsets.only(bottom: 1.5),
                                child: pw.Row(
                                  cross: pw.CrossAxisAlignment.start,
                                  children: [
                                    pw.Text('$idx] ', style: pw.TextStyle(fontSize: 7, fontWeight: pw.FontWeight.bold, color: PdfColors.black)),
                                    pw.Expanded(
                                      child: pw.Text(itemText, style: const pw.TextStyle(fontSize: 7, color: PdfColors.black)),
                                    ),
                                  ],
                                ),
                              );
                            }),
                          ],
                        ),
                      ],
                    ],
                  ),
                ),

                pw.SizedBox(width: 20),

                // Right Side: Summary Totals
                pw.Expanded(
                  flex: 4,
                  child: pw.Container(
                    padding: const pw.EdgeInsets.symmetric(vertical: 2),
                    decoration: const pw.BoxDecoration(
                      border: pw.Border(
                        bottom: pw.BorderSide(color: PdfColors.black, width: 0.8),
                      ),
                    ),
                    child: pw.Column(
                      children: [
                        _calcRow('Subtotal', invoice.subtotal.toStringAsFixed(2)),
                        if (invoice.transportCharges > 0)
                          _calcRow('Transport / Charges', '+ Rs ${invoice.transportCharges.toStringAsFixed(2)}'),
                        _calcRow('Taxable Base', invoice.taxableBase.toStringAsFixed(2), isBold: true),
                        pw.Divider(thickness: 0.5, color: PdfColors.grey400),
                        if (isIntraState) ...[
                          _calcRow('CGST (${(invoice.gstRate / 2).toStringAsFixed(1)}%)', '+ Rs ${invoice.cgstTotal.toStringAsFixed(2)}'),
                          _calcRow('SGST (${(invoice.gstRate / 2).toStringAsFixed(1)}%)', '+ Rs ${invoice.sgstTotal.toStringAsFixed(2)}'),
                        ] else ...[
                          _calcRow('IGST (${invoice.gstRate.toStringAsFixed(1)}%)', '+ Rs ${invoice.igstTotal.toStringAsFixed(2)}'),
                        ],
                        if (invoice.discountAmount > 0)
                          _calcRow('Discount', '- Rs ${invoice.discountAmount.toStringAsFixed(2)}'),
                        _calcRow('Round Off', '${invoice.roundOff >= 0 ? "+" : ""}Rs ${invoice.roundOff.toStringAsFixed(2)}'),
                        pw.Divider(thickness: 1, color: PdfColors.black),
                        pw.Container(
                          padding: const pw.EdgeInsets.symmetric(vertical: 3),
                          child: pw.Row(
                            mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                            children: [
                              pw.Text('GRAND TOTAL', style: pw.TextStyle(color: PdfColors.black, fontWeight: pw.FontWeight.bold, fontSize: 10)),
                              pw.Text('Rs ${invoice.grandTotal.toStringAsFixed(2)}', style: pw.TextStyle(color: PdfColors.black, fontWeight: pw.FontWeight.bold, fontSize: 12)),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),

            pw.SizedBox(height: 16),

            // 5. FOOTER SIGNATURE BLOCK
            pw.Align(
              alignment: pw.Alignment.bottomRight,
              child: pw.Column(
                crossAxisAlignment: pw.CrossAxisAlignment.center,
                children: [
                  if (signatureImage != null)
                    pw.Container(
                      height: 45,
                      width: 100,
                      margin: const pw.EdgeInsets.only(bottom: 4),
                      child: pw.Image(signatureImage, fit: pw.BoxFit.contain),
                    )
                  else
                    pw.SizedBox(height: 40),
                  pw.Text('For ${company?.name ?? "Company"}', style: pw.TextStyle(fontSize: 9, fontWeight: pw.FontWeight.bold)),
                  pw.Text('Authorized Signatory', style: const pw.TextStyle(fontSize: 8, color: PdfColors.black)),
                ],
              ),
            ),
          ];
        },
      ),
    );

    return pdf.save();
  }

  static pw.TableRow _keyColonValueRow(String label, String value, {bool isBoldValue = false}) {
    return pw.TableRow(
      children: [
        pw.Padding(
          padding: const pw.EdgeInsets.symmetric(vertical: 1.5),
          child: pw.Text(
            label,
            style: pw.TextStyle(fontWeight: pw.FontWeight.bold, fontSize: 9.0),
            textAlign: pw.TextAlign.left,
          ),
        ),
        pw.Padding(
          padding: const pw.EdgeInsets.symmetric(vertical: 1.5),
          child: pw.Text(
            ':',
            style: pw.TextStyle(fontWeight: pw.FontWeight.bold, fontSize: 9.0),
            textAlign: pw.TextAlign.center,
          ),
        ),
        pw.Padding(
          padding: const pw.EdgeInsets.symmetric(vertical: 1.5),
          child: pw.Text(
            value,
            style: pw.TextStyle(
              fontSize: 9.0,
              fontWeight: isBoldValue ? pw.FontWeight.bold : pw.FontWeight.normal,
              color: PdfColors.black,
            ),
            textAlign: pw.TextAlign.right,
          ),
        ),
      ],
    );
  }

  static pw.Widget _cellHeader(String text, {pw.TextAlign align = pw.TextAlign.center, pw.EdgeInsets? padding}) {
    return pw.Padding(
      padding: padding ?? const pw.EdgeInsets.symmetric(horizontal: 4, vertical: 4),
      child: pw.Text(
        text,
        style: pw.TextStyle(color: PdfColors.black, fontWeight: pw.FontWeight.bold, fontSize: 8),
        textAlign: align,
      ),
    );
  }

  static pw.Widget _cellContent(String text, {pw.TextAlign align = pw.TextAlign.left, bool isBold = false, pw.EdgeInsets? padding}) {
    return pw.Padding(
      padding: padding ?? const pw.EdgeInsets.symmetric(horizontal: 4, vertical: 2),
      child: pw.Text(
        text,
        style: pw.TextStyle(fontSize: 8, fontWeight: isBold ? pw.FontWeight.bold : pw.FontWeight.normal),
        textAlign: align,
      ),
    );
  }

  static pw.Widget _calcRow(String label, String value, {bool isBold = false}) {
    return pw.Padding(
      padding: const pw.EdgeInsets.symmetric(vertical: 1.0),
      child: pw.Row(
        mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
        children: [
          pw.Text(label, style: pw.TextStyle(fontSize: 8, fontWeight: isBold ? pw.FontWeight.bold : pw.FontWeight.normal)),
          pw.Text(value, style: pw.TextStyle(fontSize: 8, fontWeight: isBold ? pw.FontWeight.bold : pw.FontWeight.normal)),
        ],
      ),
    );
  }
}
