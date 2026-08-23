import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:printing/printing.dart';
import '../providers/invoice_provider.dart';
import '../providers/company_provider.dart';
import '../models/invoice.dart';
import '../utils/pdf_statement_builder.dart';

import 'pdf_preview_screen.dart';

class GstReportScreen extends StatefulWidget {
  const GstReportScreen({super.key});

  @override
  State<GstReportScreen> createState() => _GstReportScreenState();
}

class _GstReportScreenState extends State<GstReportScreen> {
  int _selectedMonth = DateTime.now().month;
  int _selectedYear = DateTime.now().year;

  final List<String> _months = [
    'January', 'February', 'March', 'April', 'May', 'June',
    'July', 'August', 'September', 'October', 'November', 'December'
  ];

  void _openGstPdfPreview(BuildContext context) {
    final monthStr = "${_months[_selectedMonth - 1]} $_selectedYear";
    final fileName = 'GST_Report_${_months[_selectedMonth - 1]}_$_selectedYear.pdf';

    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => PdfPreviewScreen.custom(
          title: 'GST Report ($monthStr)',
          pdfFileName: fileName,
          buildPdfBytes: (ctx, format) async {
            final company = Provider.of<CompanyProvider>(ctx, listen: false).company;
            final allInvoices = Provider.of<InvoiceProvider>(ctx, listen: false).invoices;

            final monthInvoices = allInvoices.where((inv) {
              try {
                final parts = inv.date.split('-');
                if (parts.length >= 3) {
                  int y = int.parse(parts[2]);
                  int m = _getMonthIndex(parts[1]);
                  return y == _selectedYear && m == _selectedMonth;
                }
              } catch (_) {}
              return true;
            }).toList();

            double totalSales = 0.0;
            double totalTaxable = 0.0;
            double totalCgst = 0.0;
            double totalSgst = 0.0;
            double totalIgst = 0.0;

            for (var inv in monthInvoices) {
              totalSales += inv.grandTotal;
              totalTaxable += inv.taxableBase;
              totalCgst += inv.cgstTotal;
              totalSgst += inv.sgstTotal;
              totalIgst += inv.igstTotal;
            }

            return await PdfStatementBuilder.buildGstReport(
              company: company,
              monthYearStr: monthStr,
              monthInvoices: monthInvoices,
              totalSales: totalSales,
              totalTaxable: totalTaxable,
              totalCgst: totalCgst,
              totalSgst: totalSgst,
              totalIgst: totalIgst,
            );
          },
        ),
      ),
    );
  }

  int _getMonthIndex(String mon) {
    mon = mon.toLowerCase();
    if (mon.contains('jan')) return 1;
    if (mon.contains('feb')) return 2;
    if (mon.contains('mar')) return 3;
    if (mon.contains('apr')) return 4;
    if (mon.contains('may')) return 5;
    if (mon.contains('jun')) return 6;
    if (mon.contains('jul')) return 7;
    if (mon.contains('aug')) return 8;
    if (mon.contains('sep')) return 9;
    if (mon.contains('oct')) return 10;
    if (mon.contains('nov')) return 11;
    if (mon.contains('dec')) return 12;
    return DateTime.now().month;
  }

  @override
  Widget build(BuildContext context) {
    final invoiceProvider = Provider.of<InvoiceProvider>(context);
    final allInvoices = invoiceProvider.invoices;

    // Filter invoices by month and year
    final monthInvoices = allInvoices.where((inv) {
      try {
        final parts = inv.date.split('-');
        if (parts.length >= 3) {
          int y = int.parse(parts[2]);
          int m = _getMonthIndex(parts[1]);
          return y == _selectedYear && m == _selectedMonth;
        }
      } catch (_) {}
      return true;
    }).toList();

    double totalSales = 0.0;
    double totalTaxable = 0.0;
    double totalCgst = 0.0;
    double totalSgst = 0.0;
    double totalIgst = 0.0;

    for (var inv in monthInvoices) {
      totalSales += inv.grandTotal;
      totalTaxable += inv.taxableBase;
      totalCgst += inv.cgstTotal;
      totalSgst += inv.sgstTotal;
      totalIgst += inv.igstTotal;
    }

    double totalGstLiability = totalCgst + totalSgst + totalIgst;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Monthly GST Tax Reports'),
        actions: [
          IconButton(
            icon: const Icon(Icons.picture_as_pdf_rounded),
            tooltip: 'Preview / Export GST Report PDF',
            onPressed: () => _openGstPdfPreview(context),
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // 1. MONTH & YEAR SELECTOR CARD
            Card(
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              child: Padding(
                padding: const EdgeInsets.all(14.0),
                child: Row(
                  children: [
                    Expanded(
                      flex: 2,
                      child: DropdownButtonFormField<int>(
                        value: _selectedMonth,
                        decoration: const InputDecoration(
                          labelText: 'Select Month',
                          prefixIcon: Icon(Icons.calendar_month),
                          border: OutlineInputBorder(),
                        ),
                        items: List.generate(12, (index) {
                          return DropdownMenuItem(
                            value: index + 1,
                            child: Text(_months[index]),
                          );
                        }),
                        onChanged: (val) {
                          if (val != null) setState(() => _selectedMonth = val);
                        },
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      flex: 1,
                      child: DropdownButtonFormField<int>(
                        value: _selectedYear,
                        decoration: const InputDecoration(
                          labelText: 'Year',
                          border: OutlineInputBorder(),
                        ),
                        items: [2024, 2025, 2026, 2027, 2028, 2029, 2030]
                            .map((y) => DropdownMenuItem(value: y, child: Text(y.toString())))
                            .toList(),
                        onChanged: (val) {
                          if (val != null) setState(() => _selectedYear = val);
                        },
                      ),
                    ),
                  ],
                ),
              ),
            ),

            const SizedBox(height: 16),

            // 2. GST TAX METRICS SUMMARY GRID
            Row(
              children: [
                Expanded(
                  child: _buildMetricTile(
                    'Total Sales',
                    '₹${totalSales.toStringAsFixed(2)}',
                    Colors.blue.shade700,
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: _buildMetricTile(
                    'Taxable Base',
                    '₹${totalTaxable.toStringAsFixed(2)}',
                    Colors.purple.shade700,
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: _buildMetricTile(
                    'CGST (9%)',
                    '₹${totalCgst.toStringAsFixed(2)}',
                    Colors.indigo.shade700,
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: _buildMetricTile(
                    'SGST (9%)',
                    '₹${totalSgst.toStringAsFixed(2)}',
                    Colors.teal.shade700,
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: _buildMetricTile(
                    'IGST (18%)',
                    '₹${totalIgst.toStringAsFixed(2)}',
                    Colors.deepOrange.shade700,
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: _buildMetricTile(
                    'Total GST',
                    '₹${totalGstLiability.toStringAsFixed(2)}',
                    Colors.green.shade800,
                  ),
                ),
              ],
            ),

            const SizedBox(height: 16),

            // 3. INVOICE SCHEDULE TABLE FOR GSTR-1
            Card(
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              child: Padding(
                padding: const EdgeInsets.all(14.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          'GSTR-1 Sales Schedule (${_months[_selectedMonth - 1]} $_selectedYear)',
                          style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                        ),
                        ElevatedButton.icon(
                          onPressed: () => _openGstPdfPreview(context),
                          icon: const Icon(Icons.picture_as_pdf_rounded),
                          label: const Text('PDF Preview & Print'),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),

                    monthInvoices.isEmpty
                        ? const Center(
                            child: Padding(
                              padding: EdgeInsets.symmetric(vertical: 30),
                              child: Text('No invoices recorded for this selected month.'),
                            ),
                          )
                        : SingleChildScrollView(
                            scrollDirection: Axis.horizontal,
                            child: DataTable(
                              columnSpacing: 20,
                              columns: const [
                                DataColumn(label: Text('Inv #', style: TextStyle(fontWeight: FontWeight.bold))),
                                DataColumn(label: Text('Date', style: TextStyle(fontWeight: FontWeight.bold))),
                                DataColumn(label: Text('Customer Name', style: TextStyle(fontWeight: FontWeight.bold))),
                                DataColumn(label: Text('Customer GSTIN', style: TextStyle(fontWeight: FontWeight.bold))),
                                DataColumn(label: Text('Taxable Base (₹)', style: TextStyle(fontWeight: FontWeight.bold))),
                                DataColumn(label: Text('CGST (₹)', style: TextStyle(fontWeight: FontWeight.bold))),
                                DataColumn(label: Text('SGST (₹)', style: TextStyle(fontWeight: FontWeight.bold))),
                                DataColumn(label: Text('IGST (₹)', style: TextStyle(fontWeight: FontWeight.bold))),
                                DataColumn(label: Text('Total Invoice (₹)', style: TextStyle(fontWeight: FontWeight.bold))),
                              ],
                              rows: monthInvoices.map((inv) {
                                return DataRow(cells: [
                                  DataCell(Text(inv.invoiceNumber, style: const TextStyle(fontWeight: FontWeight.bold))),
                                  DataCell(Text(inv.date)),
                                  DataCell(Text(inv.customerName ?? 'Cash Customer')),
                                  DataCell(Text(inv.customerGstin ?? '-')),
                                  DataCell(Text('₹${inv.taxableBase.toStringAsFixed(2)}')),
                                  DataCell(Text('₹${inv.cgstTotal.toStringAsFixed(2)}')),
                                  DataCell(Text('₹${inv.sgstTotal.toStringAsFixed(2)}')),
                                  DataCell(Text('₹${inv.igstTotal.toStringAsFixed(2)}')),
                                  DataCell(Text('₹${inv.grandTotal.toStringAsFixed(2)}', style: const TextStyle(fontWeight: FontWeight.bold))),
                                ]);
                              }).toList(),
                            ),
                          ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildMetricTile(String title, String value, Color color) {
    return Container(
      padding: const EdgeInsets.all(10),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: color.withOpacity(0.3)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: color),
            overflow: TextOverflow.ellipsis,
          ),
          const SizedBox(height: 4),
          Text(
            value,
            style: TextStyle(fontSize: 13, fontWeight: FontWeight.bold, color: color),
            overflow: TextOverflow.ellipsis,
          ),
        ],
      ),
    );
  }
}
