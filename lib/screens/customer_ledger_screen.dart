import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:printing/printing.dart';
import '../providers/customer_provider.dart';
import '../providers/invoice_provider.dart';
import '../providers/company_provider.dart';
import '../models/customer.dart';
import '../models/invoice.dart';
import '../utils/pdf_statement_builder.dart';

class CustomerLedgerScreen extends StatefulWidget {
  const CustomerLedgerScreen({super.key});

  @override
  State<CustomerLedgerScreen> createState() => _CustomerLedgerScreenState();
}

class _CustomerLedgerScreenState extends State<CustomerLedgerScreen> {
  Customer? _selectedCustomer;
  DateTime _startDate = DateTime.now().subtract(const Duration(days: 90));
  DateTime _endDate = DateTime.now();

  Future<void> _selectDateRange(BuildContext context) async {
    final picked = await showDateRangePicker(
      context: context,
      firstDate: DateTime(2020),
      lastDate: DateTime(2030),
      initialDateRange: DateTimeRange(start: _startDate, end: _endDate),
    );

    if (picked != null) {
      setState(() {
        _startDate = picked.start;
        _endDate = picked.end;
      });
    }
  }

  void _exportPdfStatement() async {
    if (_selectedCustomer == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please select a customer first!')),
      );
      return;
    }

    final company = Provider.of<CompanyProvider>(context, listen: false).company;
    final invoices = Provider.of<InvoiceProvider>(context, listen: false)
        .invoices
        .where((inv) => inv.customerName == _selectedCustomer!.name)
        .toList();

    final startStr = "${_startDate.day}-${_startDate.month}-${_startDate.year}";
    final endStr = "${_endDate.day}-${_endDate.month}-${_endDate.year}";

    final pdfBytes = await PdfStatementBuilder.buildCustomerStatement(
      company: company,
      customer: _selectedCustomer!,
      customerInvoices: invoices,
      startDateStr: startStr,
      endDateStr: endStr,
    );

    await Printing.layoutPdf(
      onLayout: (_) async => pdfBytes,
      name: 'Statement_${_selectedCustomer!.name ?? "Customer"}.pdf',
    );
  }

  @override
  Widget build(BuildContext context) {
    final customerProvider = Provider.of<CustomerProvider>(context);
    final invoiceProvider = Provider.of<InvoiceProvider>(context);
    final customers = customerProvider.customers;

    // Filter invoices for selected customer
    final customerInvoices = _selectedCustomer == null
        ? <Invoice>[]
        : invoiceProvider.invoices
            .where((inv) => inv.customerName == _selectedCustomer!.name)
            .toList();

    double openingBal = _selectedCustomer?.openingBalance ?? 0.0;
    double totalBilled = 0.0;
    double totalReceived = 0.0;

    for (var inv in customerInvoices) {
      totalBilled += inv.grandTotal;
      totalReceived += inv.receivedAmount;
    }

    double netBalance = openingBal + totalBilled - totalReceived;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Customer Statement & Ledger'),
        actions: [
          IconButton(
            icon: const Icon(Icons.picture_as_pdf_rounded),
            tooltip: 'Export Statement PDF',
            onPressed: _exportPdfStatement,
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // 1. CUSTOMER SELECTOR & DATE FILTER CARD
            Card(
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              child: Padding(
                padding: const EdgeInsets.all(14.0),
                child: Column(
                  children: [
                    DropdownButtonFormField<Customer>(
                      value: _selectedCustomer,
                      decoration: const InputDecoration(
                        labelText: 'Select Customer',
                        prefixIcon: Icon(Icons.person_pin_rounded),
                        border: OutlineInputBorder(),
                      ),
                      items: customers
                          .map((c) => DropdownMenuItem(
                                value: c,
                                child: Text(c.name ?? 'Unnamed Customer'),
                              ))
                          .toList(),
                      onChanged: (val) => setState(() => _selectedCustomer = val),
                    ),
                    const SizedBox(height: 12),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        OutlinedButton.icon(
                          onPressed: () => _selectDateRange(context),
                          icon: const Icon(Icons.date_range_rounded),
                          label: Text(
                            '${_startDate.day}/${_startDate.month}/${_startDate.year} - ${_endDate.day}/${_endDate.month}/${_endDate.year}',
                          ),
                        ),
                        ElevatedButton.icon(
                          onPressed: _exportPdfStatement,
                          icon: const Icon(Icons.print_rounded),
                          label: const Text('Print PDF'),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),

            const SizedBox(height: 16),

            // 2. LEDGER METRICS SUMMARY CARDS
            if (_selectedCustomer != null) ...[
              Row(
                children: [
                  Expanded(
                    child: _buildMetricTile(
                      'Opening Balance',
                      '₹${openingBal.toStringAsFixed(2)}',
                      Colors.blue.shade700,
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: _buildMetricTile(
                      'Total Billed',
                      '₹${totalBilled.toStringAsFixed(2)}',
                      Colors.purple.shade700,
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: _buildMetricTile(
                      'Total Received',
                      '₹${totalReceived.toStringAsFixed(2)}',
                      Colors.green.shade700,
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: _buildMetricTile(
                      'Net Due',
                      '₹${netBalance.toStringAsFixed(2)}',
                      netBalance > 0 ? Colors.red.shade700 : Colors.teal.shade700,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),

              // 3. LEDGER TABLE LIST
              Card(
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                child: Padding(
                  padding: const EdgeInsets.all(14.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Statement Ledger for ${_selectedCustomer!.name}',
                        style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                      ),
                      const SizedBox(height: 12),

                      SingleChildScrollView(
                        scrollDirection: Axis.horizontal,
                        child: DataTable(
                          columnSpacing: 18,
                          columns: const [
                            DataColumn(label: Text('Inv Date', style: TextStyle(fontWeight: FontWeight.bold))),
                            DataColumn(label: Text('Payment Date', style: TextStyle(fontWeight: FontWeight.bold))),
                            DataColumn(label: Text('Ref / Inv #', style: TextStyle(fontWeight: FontWeight.bold))),
                            DataColumn(label: Text('Description', style: TextStyle(fontWeight: FontWeight.bold))),
                            DataColumn(label: Text('Billed (Dr)', style: TextStyle(fontWeight: FontWeight.bold))),
                            DataColumn(label: Text('Received (Cr)', style: TextStyle(fontWeight: FontWeight.bold))),
                            DataColumn(label: Text('Balance (₹)', style: TextStyle(fontWeight: FontWeight.bold))),
                          ],
                          rows: [
                            // Opening Balance Row
                            DataRow(cells: [
                              DataCell(Text('${_startDate.day}/${_startDate.month}/${_startDate.year}')),
                              const DataCell(Text('-')),
                              const DataCell(Text('-')),
                              const DataCell(Text('Opening Balance', style: TextStyle(fontStyle: FontStyle.italic))),
                              const DataCell(Text('-')),
                              const DataCell(Text('-')),
                              DataCell(Text('₹${openingBal.toStringAsFixed(2)}', style: const TextStyle(fontWeight: FontWeight.bold))),
                            ]),

                            // Invoices Rows
                            ...customerInvoices.map((inv) {
                              return DataRow(cells: [
                                DataCell(Text(inv.date)),
                                DataCell(Text(inv.paymentDate ?? (inv.status == 'Unpaid' ? '-' : inv.date))),
                                DataCell(Text(inv.invoiceNumber, style: const TextStyle(fontWeight: FontWeight.bold))),
                                DataCell(Text(inv.invoiceType)),
                                DataCell(Text('₹${inv.grandTotal.toStringAsFixed(2)}')),
                                DataCell(Text('₹${inv.receivedAmount.toStringAsFixed(2)}')),
                                DataCell(Text(
                                  '₹${inv.balanceAmount.toStringAsFixed(2)}',
                                  style: TextStyle(
                                    fontWeight: FontWeight.bold,
                                    color: inv.balanceAmount > 0 ? Colors.red.shade700 : Colors.green.shade700,
                                  ),
                                )),
                              ]);
                            }),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ] else
              const Center(
                child: Padding(
                  padding: EdgeInsets.symmetric(vertical: 40),
                  child: Column(
                    children: [
                      Icon(Icons.account_box_outlined, size: 64, color: Colors.grey),
                      SizedBox(height: 12),
                      Text('Please select a customer from the dropdown above to view statement.'),
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
