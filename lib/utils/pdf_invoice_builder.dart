import 'dart:convert';
import 'dart:typed_data';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import '../models/invoice.dart';
import '../models/company.dart';
import 'number_to_words.dart';

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
    final isIntraState = (company?.stateCode != null &&
        invoice.customerStateCode != null &&
        company!.stateCode!.trim().isNotEmpty &&
        company.stateCode!.trim() == invoice.customerStateCode!.trim());

    pdf.addPage(
      pw.MultiPage(
        pageFormat: PdfPageFormat.a4,
        margin: const pw.EdgeInsets.all(32),
        build: (pw.Context context) {
          return [
            // 1. TOP HEADER BLOCK (MATCHING EXACT USER REFERENCE IMAGE)
            pw.Row(
              crossAxisAlignment: pw.CrossAxisAlignment.start,
              mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
              children: [
                // LEFT SIDE: LOGO + TITLE + ADDRESS BLOCK (65% width)
                pw.Expanded(
                  flex: 65,
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
                                    style: pw.TextStyle(fontSize: 8, fontStyle: pw.FontStyle.italic, color: PdfColors.grey700),
                                  ),
                              ],
                            ),
                          ),
                        ],
                      ),
                      pw.SizedBox(height: 10),

                      // Address, Phone, Email, GSTIN Below Logo & Title
                      if (company?.address != null && company!.address!.isNotEmpty)
                        pw.RichText(
                          text: pw.TextSpan(
                            children: [
                              pw.TextSpan(text: 'Address: ', style: pw.TextStyle(fontWeight: pw.FontWeight.bold, fontSize: 9.5)),
                              pw.TextSpan(text: company.address!, style: const pw.TextStyle(fontSize: 9.5)),
                            ],
                          ),
                        ),
                      pw.SizedBox(height: 2),
                      pw.Row(
                        children: [
                          if (company?.phone != null && company!.phone!.isNotEmpty)
                            pw.RichText(
                              text: pw.TextSpan(
                                children: [
                                  pw.TextSpan(text: 'Phone: ', style: pw.TextStyle(fontWeight: pw.FontWeight.bold, fontSize: 9.5)),
                                  pw.TextSpan(text: '${company.phone}', style: const pw.TextStyle(fontSize: 9.5)),
                                ],
                              ),
                            ),
                          if (company?.phone != null && company!.phone!.isNotEmpty && company?.email != null && company!.email!.isNotEmpty)
                            pw.Text(' | ', style: pw.TextStyle(fontWeight: pw.FontWeight.bold, fontSize: 9.5)),
                          if (company?.email != null && company!.email!.isNotEmpty)
                            pw.RichText(
                              text: pw.TextSpan(
                                children: [
                                  pw.TextSpan(text: 'Email: ', style: pw.TextStyle(fontWeight: pw.FontWeight.bold, fontSize: 9.5)),
                                  pw.TextSpan(text: '${company.email}', style: const pw.TextStyle(fontSize: 9.5)),
                                ],
                              ),
                            ),
                        ],
                      ),
                      pw.SizedBox(height: 2),
                      if (company?.gstNumber != null && company!.gstNumber!.isNotEmpty)
                        pw.RichText(
                          text: pw.TextSpan(
                            children: [
                              pw.TextSpan(text: 'GSTIN: ', style: pw.TextStyle(fontWeight: pw.FontWeight.bold, fontSize: 9.5)),
                              pw.TextSpan(text: company.gstNumber!, style: const pw.TextStyle(fontSize: 9.5)),
                            ],
                          ),
                        ),
                    ],
                  ),
                ),

                pw.SizedBox(width: 15),

                // RIGHT SIDE: TAX INVOICE TITLE + META LIST (35% width)
                pw.Expanded(
                  flex: 35,
                  child: pw.Column(
                    crossAxisAlignment: pw.CrossAxisAlignment.start,
                    children: [
                      pw.Align(
                        alignment: pw.Alignment.topRight,
                        child: pw.Text(
                          invoice.invoiceType.toUpperCase(),
                          style: pw.TextStyle(fontSize: 18, fontWeight: pw.FontWeight.bold, color: PdfColors.black),
                        ),
                      ),
                      pw.SizedBox(height: 14),

                      _metaRow('Invoice No. :', invoice.invoiceNumber),
                      if (invoice.challanNumber != null && invoice.challanNumber!.trim().isNotEmpty)
                        _metaRow('Challan No. :', invoice.challanNumber!),
                      _metaRow('Invoice Date:', invoice.date),
                      if (invoice.dueDate != null && invoice.dueDate!.isNotEmpty)
                        _metaRow('Payment Due:', invoice.dueDate!, isBoldValue: true),
                    ],
                  ),
                ),
              ],
            ),

            pw.SizedBox(height: 10),
            pw.Divider(thickness: 1, color: PdfColors.grey400),
            pw.SizedBox(height: 8),

            // 2. CUSTOMER & BILLING INFO BLOCK
            pw.Container(
              padding: const pw.EdgeInsets.all(8),
              decoration: pw.BoxDecoration(
                color: PdfColors.grey100,
                borderRadius: pw.BorderRadius.circular(4),
                border: pw.Border.all(color: PdfColors.grey300),
              ),
              child: pw.Row(
                crossAxisAlignment: pw.CrossAxisAlignment.start,
                mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                children: [
                  pw.Column(
                    crossAxisAlignment: pw.CrossAxisAlignment.start,
                    children: [
                      pw.Text('BILLED TO:', style: pw.TextStyle(fontSize: 9, fontWeight: pw.FontWeight.bold, color: PdfColors.grey700)),
                      pw.Text(
                        invoice.customerName ?? 'Cash / Walk-in Customer',
                        style: pw.TextStyle(fontSize: 12, fontWeight: pw.FontWeight.bold),
                      ),
                      if (invoice.customerAddress != null && invoice.customerAddress!.isNotEmpty)
                        pw.Text(invoice.customerAddress!, style: const pw.TextStyle(fontSize: 9)),
                      if (invoice.customerGstin != null && invoice.customerGstin!.isNotEmpty)
                        pw.Text('GSTIN: ${invoice.customerGstin}', style: pw.TextStyle(fontSize: 9, fontWeight: pw.FontWeight.bold)),
                    ],
                  ),
                  pw.Container(
                    padding: const pw.EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                    decoration: pw.BoxDecoration(
                      color: isIntraState ? PdfColors.blue50 : PdfColors.purple50,
                      borderRadius: pw.BorderRadius.circular(4),
                      border: pw.Border.all(color: isIntraState ? PdfColors.blue300 : PdfColors.purple300),
                    ),
                    child: pw.Text(
                      isIntraState ? 'Taxation: Intra-State (CGST + SGST)' : 'Taxation: Inter-State (IGST)',
                      style: pw.TextStyle(fontSize: 8, fontWeight: pw.FontWeight.bold, color: isIntraState ? PdfColors.blue900 : PdfColors.purple900),
                    ),
                  ),
                ],
              ),
            ),

            pw.SizedBox(height: 12),

            // 3. LINE ITEMS TABLE BLOCK
            pw.Table(
              border: pw.TableBorder.all(color: PdfColors.grey400, width: 0.5),
              columnWidths: {
                0: const pw.FixedColumnWidth(28), // S.No
                1: const pw.FlexColumnWidth(3),   // Item & Description
                2: const pw.FlexColumnWidth(1.2), // Size
                3: const pw.FlexColumnWidth(1.2), // Pcs/Bdl
                4: const pw.FixedColumnWidth(45), // HSN
                5: const pw.FixedColumnWidth(45), // Qty/Unit
                6: const pw.FixedColumnWidth(55), // Rate
                7: const pw.FixedColumnWidth(65), // Amount
              },
              children: [
                // Table Header Row
                pw.TableRow(
                  decoration: const pw.BoxDecoration(color: PdfColors.blue900),
                  children: [
                    _cellHeader('S.No'),
                    _cellHeader('Item & Description'),
                    _cellHeader('Size'),
                    _cellHeader('Pcs/Bdl'),
                    _cellHeader('HSN'),
                    _cellHeader('Qty'),
                    _cellHeader('Rate (Rs)'),
                    _cellHeader('Amount (Rs)'),
                  ],
                ),
                // Item Rows
                ...invoice.items.asMap().entries.map((entry) {
                  final idx = entry.key + 1;
                  final item = entry.value;
                  return pw.TableRow(
                    children: [
                      _cellContent(idx.toString(), align: pw.TextAlign.center),
                      _cellContent(item.productName, isBold: true),
                      _cellContent(item.size ?? '-', align: pw.TextAlign.center),
                      _cellContent(item.pcsCount ?? '-', align: pw.TextAlign.center),
                      _cellContent(item.hsnCode ?? '-', align: pw.TextAlign.center),
                      _cellContent('${item.quantity} ${item.unit}', align: pw.TextAlign.center),
                      _cellContent(item.price.toStringAsFixed(2), align: pw.TextAlign.right),
                      _cellContent(item.amount.toStringAsFixed(2), align: pw.TextAlign.right, isBold: true),
                    ],
                  );
                }),
              ],
            ),

            pw.SizedBox(height: 12),

            // 4. CALCULATIONS & PAYMENT DETAILS SPLIT BLOCK
            pw.Row(
              crossAxisAlignment: pw.CrossAxisAlignment.start,
              children: [
                // Left Side: Amount in Words, Bank Info, Payment Status
                pw.Expanded(
                  flex: 5,
                  child: pw.Column(
                    crossAxisAlignment: pw.CrossAxisAlignment.start,
                    children: [
                      pw.Container(
                        padding: const pw.EdgeInsets.all(6),
                        decoration: pw.BoxDecoration(color: PdfColors.grey100, borderRadius: pw.BorderRadius.circular(4)),
                        child: pw.Column(
                          crossAxisAlignment: pw.CrossAxisAlignment.start,
                          children: [
                            pw.Text('AMOUNT IN WORDS:', style: pw.TextStyle(fontSize: 8, fontWeight: pw.FontWeight.bold, color: PdfColors.grey700)),
                            pw.Text(amountInWords, style: pw.TextStyle(fontSize: 9, fontWeight: pw.FontWeight.bold, color: PdfColors.blue900)),
                          ],
                        ),
                      ),
                      pw.SizedBox(height: 8),

                      // Bank Details (if present)
                      if ((company?.bankName != null && company!.bankName!.isNotEmpty) ||
                          (company?.accountNumber != null && company!.accountNumber!.isNotEmpty))
                        pw.Container(
                          padding: const pw.EdgeInsets.all(6),
                          decoration: pw.BoxDecoration(
                            border: pw.Border.all(color: PdfColors.grey300),
                            borderRadius: pw.BorderRadius.circular(4),
                          ),
                          child: pw.Column(
                            crossAxisAlignment: pw.CrossAxisAlignment.start,
                            children: [
                              pw.Text('BANK & PAYMENT DETAILS:', style: pw.TextStyle(fontSize: 8, fontWeight: pw.FontWeight.bold, color: PdfColors.grey800)),
                              if (company?.bankName != null && company!.bankName!.isNotEmpty)
                                pw.Text('Bank: ${company.bankName}${company.bankBranch != null && company.bankBranch!.isNotEmpty ? " (${company.bankBranch})" : ""}', style: const pw.TextStyle(fontSize: 8)),
                              if (company?.accountNumber != null && company!.accountNumber!.isNotEmpty)
                                pw.Text('A/C No: ${company.accountNumber}', style: pw.TextStyle(fontSize: 8, fontWeight: pw.FontWeight.bold)),
                              if (company?.ifscCode != null && company!.ifscCode!.isNotEmpty)
                                pw.Text('IFSC Code: ${company.ifscCode}', style: const pw.TextStyle(fontSize: 8)),
                              if (company?.upiId != null && company!.upiId!.isNotEmpty)
                                pw.Text('UPI ID: ${company.upiId}', style: pw.TextStyle(fontSize: 8, fontWeight: pw.FontWeight.bold, color: PdfColors.green800)),
                            ],
                          ),
                        ),
                      pw.SizedBox(height: 6),

                      // Payment Status
                      pw.Row(
                        children: [
                          pw.Text('Status: ', style: pw.TextStyle(fontSize: 9, fontWeight: pw.FontWeight.bold)),
                          pw.Container(
                            padding: const pw.EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                            decoration: pw.BoxDecoration(
                              color: invoice.status == 'Paid'
                                  ? PdfColors.green100
                                  : (invoice.status == 'Partially Paid' ? PdfColors.orange100 : PdfColors.red100),
                              borderRadius: pw.BorderRadius.circular(3),
                            ),
                            child: pw.Text(
                              invoice.status.toUpperCase(),
                              style: pw.TextStyle(
                                fontSize: 8,
                                fontWeight: pw.FontWeight.bold,
                                color: invoice.status == 'Paid'
                                    ? PdfColors.green900
                                    : (invoice.status == 'Partially Paid' ? PdfColors.orange900 : PdfColors.red900),
                              ),
                            ),
                          ),
                        ],
                      ),
                      if (invoice.status == 'Partially Paid') ...[
                        pw.Text('Received: Rs ${invoice.receivedAmount.toStringAsFixed(2)} | Balance Due: Rs ${invoice.balanceAmount.toStringAsFixed(2)}',
                            style: pw.TextStyle(fontSize: 8, fontWeight: pw.FontWeight.bold, color: PdfColors.orange900)),
                      ],
                    ],
                  ),
                ),

                pw.SizedBox(width: 16),

                // Right Side: Summary Totals
                pw.Expanded(
                  flex: 4,
                  child: pw.Container(
                    padding: const pw.EdgeInsets.all(6),
                    decoration: pw.BoxDecoration(
                      border: pw.Border.all(color: PdfColors.grey300),
                      borderRadius: pw.BorderRadius.circular(4),
                    ),
                    child: pw.Column(
                      children: [
                        _calcRow('Subtotal', invoice.subtotal.toStringAsFixed(2)),
                        if (invoice.transportCharges > 0)
                          _calcRow('Transport / Charges', '+ Rs ${invoice.transportCharges.toStringAsFixed(2)}'),
                        _calcRow('Taxable Base', invoice.taxableBase.toStringAsFixed(2), isBold: true),
                        pw.Divider(thickness: 0.5, color: PdfColors.grey300),
                        if (isIntraState) ...[
                          _calcRow('CGST (${(invoice.gstRate / 2).toStringAsFixed(1)}%)', '+ Rs ${invoice.cgstTotal.toStringAsFixed(2)}'),
                          _calcRow('SGST (${(invoice.gstRate / 2).toStringAsFixed(1)}%)', '+ Rs ${invoice.sgstTotal.toStringAsFixed(2)}'),
                        ] else ...[
                          _calcRow('IGST (${invoice.gstRate.toStringAsFixed(1)}%)', '+ Rs ${invoice.igstTotal.toStringAsFixed(2)}'),
                        ],
                        if (invoice.discountAmount > 0)
                          _calcRow('Discount', '- Rs ${invoice.discountAmount.toStringAsFixed(2)}'),
                        _calcRow('Round Off', '${invoice.roundOff >= 0 ? "+" : ""}Rs ${invoice.roundOff.toStringAsFixed(2)}'),
                        pw.Divider(thickness: 1, color: PdfColors.grey800),
                        pw.Container(
                          padding: const pw.EdgeInsets.all(4),
                          color: PdfColors.blue900,
                          child: pw.Row(
                            mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                            children: [
                              pw.Text('GRAND TOTAL', style: pw.TextStyle(color: PdfColors.white, fontWeight: pw.FontWeight.bold, fontSize: 10)),
                              pw.Text('Rs ${invoice.grandTotal.toStringAsFixed(2)}', style: pw.TextStyle(color: PdfColors.white, fontWeight: pw.FontWeight.bold, fontSize: 12)),
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

            // 5. FOOTER BLOCK (TERMS & SIGNATURE)
            pw.Row(
              crossAxisAlignment: pw.CrossAxisAlignment.end,
              mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
              children: [
                // Left: Terms & Conditions
                pw.Expanded(
                  child: company?.termsAndConditions != null && company!.termsAndConditions!.isNotEmpty
                      ? pw.Column(
                          crossAxisAlignment: pw.CrossAxisAlignment.start,
                          children: [
                            pw.Text('TERMS & CONDITIONS:', style: pw.TextStyle(fontSize: 8, fontWeight: pw.FontWeight.bold, color: PdfColors.grey700)),
                            pw.Text(company.termsAndConditions!, style: const pw.TextStyle(fontSize: 7, color: PdfColors.grey800)),
                          ],
                        )
                      : pw.SizedBox(),
                ),
                pw.SizedBox(width: 20),

                // Right: Authorized Signature / Stamp
                pw.Column(
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
                    pw.Text('Authorized Signatory', style: const pw.TextStyle(fontSize: 8, color: PdfColors.grey700)),
                  ],
                ),
              ],
            ),
          ];
        },
      ),
    );

    return pdf.save();
  }

  static pw.Widget _metaRow(String label, String value, {bool isBoldValue = false}) {
    return pw.Padding(
      padding: const pw.EdgeInsets.symmetric(vertical: 1),
      child: pw.Row(
        mainAxisAlignment: pw.MainAxisAlignment.end,
        children: [
          pw.Text(label, style: pw.TextStyle(fontWeight: pw.FontWeight.bold, fontSize: 9.5)),
          pw.SizedBox(width: 4),
          pw.Text(
            value,
            style: pw.TextStyle(
              fontSize: 9.5,
              fontWeight: isBoldValue ? pw.FontWeight.bold : pw.FontWeight.normal,
              color: isBoldValue ? PdfColors.red800 : PdfColors.black,
            ),
          ),
        ],
      ),
    );
  }

  static pw.Widget _cellHeader(String text) {
    return pw.Padding(
      padding: const pw.EdgeInsets.symmetric(horizontal: 4, vertical: 5),
      child: pw.Text(
        text,
        style: pw.TextStyle(color: PdfColors.white, fontWeight: pw.FontWeight.bold, fontSize: 8),
        textAlign: pw.TextAlign.center,
      ),
    );
  }

  static pw.Widget _cellContent(String text, {pw.TextAlign align = pw.TextAlign.left, bool isBold = false}) {
    return pw.Padding(
      padding: const pw.EdgeInsets.symmetric(horizontal: 4, vertical: 4),
      child: pw.Text(
        text,
        style: pw.TextStyle(fontSize: 8, fontWeight: isBold ? pw.FontWeight.bold : pw.FontWeight.normal),
        textAlign: align,
      ),
    );
  }

  static pw.Widget _calcRow(String label, String value, {bool isBold = false}) {
    return pw.Padding(
      padding: const pw.EdgeInsets.symmetric(vertical: 1.5),
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
