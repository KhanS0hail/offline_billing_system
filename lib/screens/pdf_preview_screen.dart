import 'package:flutter/material.dart';
import 'package:printing/printing.dart';
import 'package:provider/provider.dart';
import '../models/invoice.dart';
import '../providers/company_provider.dart';
import '../utils/pdf_invoice_builder.dart';
import '../utils/pdf_saver.dart';

class PdfPreviewScreen extends StatelessWidget {
  final Invoice invoice;

  const PdfPreviewScreen({super.key, required this.invoice});

  @override
  Widget build(BuildContext context) {
    final company = Provider.of<CompanyProvider>(context, listen: false).company;
    final fileName = 'Invoice_${invoice.invoiceNumber}.pdf';

    return Scaffold(
      appBar: AppBar(
        title: Text('Invoice #${invoice.invoiceNumber}'),
        actions: [
          IconButton(
            icon: const Icon(Icons.download_rounded),
            tooltip: 'Download / Save PDF',
            onPressed: () async {
              final pdfBytes = await PdfInvoiceBuilder.buildPdf(
                invoice: invoice,
                company: company,
              );
              if (context.mounted) {
                await PdfSaver.savePdf(
                  context: context,
                  pdfBytes: pdfBytes,
                  fileName: fileName,
                );
              }
            },
          ),
        ],
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
        pdfFileName: fileName,
        actions: [
          PdfPreviewAction(
            icon: const Icon(Icons.download_rounded),
            onPressed: (context, build, pageFormat) async {
              final pdfBytes = await build(pageFormat);
              await PdfSaver.savePdf(
                context: context,
                pdfBytes: pdfBytes,
                fileName: fileName,
              );
            },
          ),
        ],
      ),
    );
  }
}
