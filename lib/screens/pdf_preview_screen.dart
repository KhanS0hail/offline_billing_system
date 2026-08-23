import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:pdf/pdf.dart';
import 'package:printing/printing.dart';
import 'package:provider/provider.dart';
import '../models/invoice.dart';
import '../providers/company_provider.dart';
import '../utils/pdf_invoice_builder.dart';
import '../utils/pdf_saver.dart';

class PdfPreviewScreen extends StatelessWidget {
  final String title;
  final String pdfFileName;
  final Future<Uint8List> Function(BuildContext context, PdfPageFormat format) buildPdfBytes;

  const PdfPreviewScreen.custom({
    super.key,
    required this.title,
    required this.pdfFileName,
    required this.buildPdfBytes,
  });

  factory PdfPreviewScreen({Key? key, required Invoice invoice}) {
    return PdfPreviewScreen.custom(
      key: key,
      title: 'Invoice #${invoice.invoiceNumber}',
      pdfFileName: 'Invoice_${invoice.invoiceNumber}.pdf',
      buildPdfBytes: (context, format) async {
        final company = Provider.of<CompanyProvider>(context, listen: false).company;
        return await PdfInvoiceBuilder.buildPdf(
          invoice: invoice,
          company: company,
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(title),
        actions: [
          IconButton(
            icon: const Icon(Icons.download_rounded),
            tooltip: 'Download / Save PDF',
            onPressed: () async {
              final pdfBytes = await buildPdfBytes(context, PdfPageFormat.a4);
              if (context.mounted) {
                await PdfSaver.savePdf(
                  context: context,
                  pdfBytes: pdfBytes,
                  fileName: pdfFileName,
                );
              }
            },
          ),
        ],
      ),
      body: PdfPreview(
        build: (format) => buildPdfBytes(context, format),
        allowPrinting: true,
        allowSharing: true,
        canChangeOrientation: false,
        canChangePageFormat: false,
        pdfFileName: pdfFileName,
        actions: [
          PdfPreviewAction(
            icon: const Icon(Icons.download_rounded),
            onPressed: (ctx, build, pageFormat) async {
              final pdfBytes = await build(pageFormat);
              await PdfSaver.savePdf(
                context: context,
                pdfBytes: pdfBytes,
                fileName: pdfFileName,
              );
            },
          ),
        ],
      ),
    );
  }
}
