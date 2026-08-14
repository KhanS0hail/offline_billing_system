import 'package:flutter/material.dart';
import 'package:printing/printing.dart';
import 'package:provider/provider.dart';
import '../models/invoice.dart';
import '../providers/company_provider.dart';
import '../utils/pdf_invoice_builder.dart';

class PdfPreviewScreen extends StatelessWidget {
  final Invoice invoice;

  const PdfPreviewScreen({super.key, required this.invoice});

  @override
  Widget build(BuildContext context) {
    final company = Provider.of<CompanyProvider>(context, listen: false).company;

    return Scaffold(
      appBar: AppBar(
        title: Text('Invoice #${invoice.invoiceNumber}'),
      ),
      body: PdfPreview(
        build: (format) => PdfInvoiceBuilder.buildPdf(
          invoice: invoice,
          company: company,
        ),
        allowPrinting: true,
        allowSharing: true,
        canChangeOrientation: false,
        canChangePageFormat: false,
        pdfFileName: 'Invoice_${invoice.invoiceNumber}.pdf',
      ),
    );
  }
}
