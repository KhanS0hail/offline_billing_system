import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:printing/printing.dart';
import '../providers/customer_provider.dart';
import '../providers/invoice_provider.dart';
import '../providers/company_provider.dart';
import '../models/customer.dart';
import '../models/invoice.dart';
import '../models/customer_payment.dart';
import '../utils/pdf_statement_builder.dart';
import '../utils/pdf_saver.dart';

class CustomerLedgerScreen extends StatefulWidget {
  const CustomerLedgerScreen({super.key});

  @override
  State<CustomerLedgerScreen> createState() => _CustomerLedgerScreenState();
}

class _LedgerDisplayRow {
  final DateTime dateObj;
  final String dateStr;
  final String referenceNo;
  final String details;
  final double debit;
  final double credit;
  final int? paymentId;

  _LedgerDisplayRow({
    required this.dateObj,
    required this.dateStr,
    required this.referenceNo,
    required this.details,
    required this.debit,
    required this.credit,
    this.paymentId,
  });
}

class _CustomerLedgerScreenState extends State<CustomerLedgerScreen> {
  Customer? _selectedCustomer;
  DateTime _startDate = DateTime.now().subtract(const Duration(days: 90));
  DateTime _endDate = DateTime.now();

  DateTime _parseDate(String dStr) {
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

  String _monthName(int m) {
    const months = ["Jan", "Feb", "Mar", "Apr", "May", "Jun", "Jul", "Aug", "Sep", "Oct", "Nov", "Dec"];
    return months[m - 1];
  }

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
    final customerProvider = Provider.of<CustomerProvider>(context, listen: false);
    final invoiceProvider = Provider.of<InvoiceProvider>(context, listen: false);

    final invoices = invoiceProvider.invoices
        .where((inv) => inv.customerId == _selectedCustomer!.id || inv.customerName == _selectedCustomer!.name)
        .toList();

    final payments = await customerProvider.getPaymentsForCustomer(_selectedCustomer!.id!);

    final startStr = "${_startDate.day}-${_startDate.month}-${_startDate.year}";
    final endStr = "${_endDate.day}-${_endDate.month}-${_endDate.year}";
    final monthYearStr = "${_monthName(_startDate.month)}_${_startDate.year}";

    final pdfBytes = await PdfStatementBuilder.buildCustomerStatement(
      company: company,
      customer: _selectedCustomer!,
      customerInvoices: invoices,
      customerPayments: payments,
      startDateStr: startStr,
      endDateStr: endStr,
    );

    final fileName = PdfStatementBuilder.getStatementFileName(_selectedCustomer!, monthYearStr);

    await Printing.layoutPdf(
      onLayout: (_) async => pdfBytes,
      name: fileName,
    );
  }

  void _downloadPdfStatement() async {
    if (_selectedCustomer == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please select a customer first!')),
      );
      return;
    }

    final company = Provider.of<CompanyProvider>(context, listen: false).company;
    final customerProvider = Provider.of<CustomerProvider>(context, listen: false);
    final invoiceProvider = Provider.of<InvoiceProvider>(context, listen: false);

    final invoices = invoiceProvider.invoices
        .where((inv) => inv.customerId == _selectedCustomer!.id || inv.customerName == _selectedCustomer!.name)
        .toList();

    final payments = await customerProvider.getPaymentsForCustomer(_selectedCustomer!.id!);

    final startStr = "${_startDate.day}-${_startDate.month}-${_startDate.year}";
    final endStr = "${_endDate.day}-${_endDate.month}-${_endDate.year}";
    final monthYearStr = "${_monthName(_startDate.month)}_${_startDate.year}";

    final pdfBytes = await PdfStatementBuilder.buildCustomerStatement(
      company: company,
      customer: _selectedCustomer!,
      customerInvoices: invoices,
      customerPayments: payments,
      startDateStr: startStr,
      endDateStr: endStr,
    );

    final fileName = PdfStatementBuilder.getStatementFileName(_selectedCustomer!, monthYearStr);

    if (mounted) {
      await PdfSaver.savePdf(
        context: context,
        pdfBytes: pdfBytes,
        fileName: fileName,
      );
    }
  }

  void _showRecordPaymentDialog(BuildContext context) async {
    if (_selectedCustomer == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please select a customer first!')),
      );
      return;
    }

    final custProvider = Provider.of<CustomerProvider>(context, listen: false);
    final invProvider = Provider.of<InvoiceProvider>(context, listen: false);

    final nextReceiptNo = await custProvider.generateNextReceiptNumber();
    final receiptController = TextEditingController(text: nextReceiptNo);
    final amountController = TextEditingController();
    final refController = TextEditingController();
    final notesController = TextEditingController();

    DateTime selectedDate = DateTime.now();
    String? selectedMode = 'Bank Transfer (NEFT/RTGS/IMPS)';

    if (!mounted) return;

    showDialog(
      context: context,
      builder: (ctx) {
        return StatefulBuilder(
          builder: (context, setDialogState) {
            final formattedDateStr = "${selectedDate.day.toString().padLeft(2, '0')}-${_monthName(selectedDate.month)}-${selectedDate.year}";

            return AlertDialog(
              title: Text('Record Payment: ${_selectedCustomer!.name}'),
              content: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Receipt Number
                    TextField(
                      controller: receiptController,
                      decoration: const InputDecoration(
                        labelText: 'Receipt / Voucher #',
                        prefixIcon: Icon(Icons.receipt),
                        border: OutlineInputBorder(),
                      ),
                    ),
                    const SizedBox(height: 12),

                    // Payment Date
                    InkWell(
                      onTap: () async {
                        final picked = await showDatePicker(
                          context: context,
                          initialDate: selectedDate,
                          firstDate: DateTime(2020),
                          lastDate: DateTime(2035),
                        );
                        if (picked != null) {
                          setDialogState(() => selectedDate = picked);
                        }
                      },
                      child: InputDecorator(
                        decoration: const InputDecoration(
                          labelText: 'Payment Date *',
                          prefixIcon: Icon(Icons.calendar_today),
                          border: OutlineInputBorder(),
                        ),
                        child: Text(formattedDateStr),
                      ),
                    ),
                    const SizedBox(height: 12),

                    // Amount Received
                    TextField(
                      controller: amountController,
                      keyboardType: const TextInputType.numberWithOptions(decimal: true),
                      decoration: const InputDecoration(
                        labelText: 'Amount Received (₹) *',
                        prefixIcon: Icon(Icons.currency_rupee),
                        border: OutlineInputBorder(),
                      ),
                    ),
                    const SizedBox(height: 12),

                    // Payment Mode (Optional)
                    DropdownButtonFormField<String>(
                      value: selectedMode,
                      decoration: const InputDecoration(
                        labelText: 'Payment Mode (Optional)',
                        prefixIcon: Icon(Icons.payment),
                        border: OutlineInputBorder(),
                      ),
                      items: [
                        'Bank Transfer (NEFT/RTGS/IMPS)',
                        'UPI',
                        'Cheque',
                        'Cash',
                        'Other',
                      ].map((m) => DropdownMenuItem(value: m, child: Text(m))).toList(),
                      onChanged: (val) => setDialogState(() => selectedMode = val),
                    ),
                    const SizedBox(height: 12),

                    // Reference Note (Optional)
                    TextField(
                      controller: refController,
                      decoration: const InputDecoration(
                        labelText: 'Reference / UTR / Cheque # (Optional)',
                        prefixIcon: Icon(Icons.pin),
                        border: OutlineInputBorder(),
                      ),
                    ),
                    const SizedBox(height: 12),

                    // Notes (Optional)
                    TextField(
                      controller: notesController,
                      decoration: const InputDecoration(
                        labelText: 'Notes / Remarks (Optional)',
                        prefixIcon: Icon(Icons.note),
                        border: OutlineInputBorder(),
                      ),
                    ),
                  ],
                ),
              ),
              actions: [
                TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Cancel')),
                ElevatedButton.icon(
                  icon: const Icon(Icons.check),
                  label: const Text('Save Payment'),
                  onPressed: () async {
                    final amt = double.tryParse(amountController.text.trim());
                    if (amt == null || amt <= 0) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(content: Text('Please enter a valid amount greater than ₹0')),
                      );
                      return;
                    }

                    final newPayment = CustomerPayment(
                      receiptNumber: receiptController.text.trim().isEmpty ? nextReceiptNo : receiptController.text.trim(),
                      customerId: _selectedCustomer!.id!,
                      customerName: _selectedCustomer!.name,
                      paymentDate: formattedDateStr,
                      amount: amt,
                      paymentMode: selectedMode,
                      referenceNote: refController.text.trim().isNotEmpty ? refController.text.trim() : null,
                      notes: notesController.text.trim().isNotEmpty ? notesController.text.trim() : null,
                    );

                    await custProvider.addPayment(newPayment);
                    await invProvider.loadInvoices(); // Refresh FIFO knockoff statuses

                    if (ctx.mounted) Navigator.pop(ctx);
                    setState(() {});

                    if (context.mounted) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(content: Text('Payment of ₹${amt.toStringAsFixed(2)} recorded successfully! FIFO invoice balances updated.')),
                      );
                    }
                  },
                ),
              ],
            );
          },
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final customerProvider = Provider.of<CustomerProvider>(context);
    final invoiceProvider = Provider.of<InvoiceProvider>(context);
    final customers = customerProvider.customers;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Customer Statement & Ledger'),
        actions: [
          IconButton(
            icon: const Icon(Icons.download_rounded),
            tooltip: 'Download PDF',
            onPressed: _downloadPdfStatement,
          ),
          IconButton(
            icon: const Icon(Icons.picture_as_pdf_rounded),
            tooltip: 'Print / Export PDF',
            onPressed: _exportPdfStatement,
          ),
        ],
      ),
      body: FutureBuilder<List<CustomerPayment>>(
        future: _selectedCustomer != null
            ? customerProvider.getPaymentsForCustomer(_selectedCustomer!.id!)
            : Future.value([]),
        builder: (context, snapshot) {
          final customerPayments = snapshot.data ?? [];

          // Filter invoices for selected customer
          final customerInvoices = _selectedCustomer == null
              ? <Invoice>[]
              : invoiceProvider.invoices
                  .where((inv) => inv.customerId == _selectedCustomer!.id || inv.customerName == _selectedCustomer!.name)
                  .toList();

          // Build unified 6-column display list
          List<_LedgerDisplayRow> displayRows = [];

          for (var inv in customerInvoices) {
            displayRows.add(_LedgerDisplayRow(
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

            displayRows.add(_LedgerDisplayRow(
              dateObj: _parseDate(pay.paymentDate),
              dateStr: pay.paymentDate,
              referenceNo: pay.receiptNumber,
              details: detailStr,
              debit: 0.0,
              credit: pay.amount,
              paymentId: pay.id,
            ));
          }

          displayRows.sort((a, b) => a.dateObj.compareTo(b.dateObj));

          double openingBal = _selectedCustomer?.openingBalance ?? 0.0;
          double totalBilled = 0.0;
          double totalReceived = 0.0;

          for (var r in displayRows) {
            totalBilled += r.debit;
            totalReceived += r.credit;
          }

          double netBalance = openingBal + totalBilled - totalReceived;

          return SingleChildScrollView(
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
                              style: ElevatedButton.styleFrom(backgroundColor: Colors.green.shade700),
                              onPressed: () => _showRecordPaymentDialog(context),
                              icon: const Icon(Icons.add_card, color: Colors.white),
                              label: const Text('Record Payment', style: TextStyle(color: Colors.white)),
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
                          'Total Billed (Dr)',
                          '₹${totalBilled.toStringAsFixed(2)}',
                          Colors.purple.shade700,
                        ),
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: _buildMetricTile(
                          'Total Received (Cr)',
                          '₹${totalReceived.toStringAsFixed(2)}',
                          Colors.green.shade700,
                        ),
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: _buildMetricTile(
                          'Net Outstanding',
                          '₹${netBalance.toStringAsFixed(2)}',
                          netBalance > 0 ? Colors.red.shade700 : Colors.teal.shade700,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),

                  // 3. 6-COLUMN UNIFIED RUNNING LEDGER TABLE
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
                                'Statement Ledger for ${_selectedCustomer!.name}',
                                style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                              ),
                              Row(
                                children: [
                                  OutlinedButton.icon(
                                    onPressed: _downloadPdfStatement,
                                    icon: const Icon(Icons.download_rounded),
                                    label: const Text('Download PDF'),
                                  ),
                                  const SizedBox(width: 8),
                                  ElevatedButton.icon(
                                    onPressed: _exportPdfStatement,
                                    icon: const Icon(Icons.print_rounded),
                                    label: const Text('Print PDF'),
                                  ),
                                ],
                              ),
                            ],
                          ),
                          const SizedBox(height: 12),

                          SingleChildScrollView(
                            scrollDirection: Axis.horizontal,
                            child: Builder(
                              builder: (context) {
                                double runningBalTracker = openingBal;

                                return DataTable(
                                  columnSpacing: 16,
                                  columns: const [
                                    DataColumn(label: Text('Date', style: TextStyle(fontWeight: FontWeight.bold))),
                                    DataColumn(label: Text('Reference #', style: TextStyle(fontWeight: FontWeight.bold))),
                                    DataColumn(label: Text('Transaction Details', style: TextStyle(fontWeight: FontWeight.bold))),
                                    DataColumn(label: Text('Debit (Dr.) ₹', style: TextStyle(fontWeight: FontWeight.bold))),
                                    DataColumn(label: Text('Credit (Cr.) ₹', style: TextStyle(fontWeight: FontWeight.bold))),
                                    DataColumn(label: Text('Running Balance ₹', style: TextStyle(fontWeight: FontWeight.bold))),
                                    DataColumn(label: Text('Action', style: TextStyle(fontWeight: FontWeight.bold))),
                                  ],
                                  rows: [
                                    // Opening Balance Row
                                    DataRow(cells: [
                                      DataCell(Text('${_startDate.day}/${_startDate.month}/${_startDate.year}')),
                                      const DataCell(Text('-')),
                                      const DataCell(Text('Opening Balance', style: TextStyle(fontStyle: FontStyle.italic, fontWeight: FontWeight.bold))),
                                      const DataCell(Text('-')),
                                      const DataCell(Text('-')),
                                      DataCell(Text('₹${openingBal.toStringAsFixed(2)}', style: const TextStyle(fontWeight: FontWeight.bold))),
                                      const DataCell(Text('-')),
                                    ]),

                                    // Transaction Rows
                                    ...displayRows.map((r) {
                                      runningBalTracker = runningBalTracker + r.debit - r.credit;
                                      final currentBal = runningBalTracker;

                                      return DataRow(cells: [
                                        DataCell(Text(r.dateStr)),
                                        DataCell(Text(r.referenceNo, style: const TextStyle(fontWeight: FontWeight.bold))),
                                        DataCell(Text(r.details)),
                                        DataCell(Text(r.debit > 0 ? '₹${r.debit.toStringAsFixed(2)}' : '-')),
                                        DataCell(Text(
                                          r.credit > 0 ? '₹${r.credit.toStringAsFixed(2)}' : '-',
                                          style: TextStyle(color: r.credit > 0 ? Colors.green.shade700 : Colors.black87, fontWeight: r.credit > 0 ? FontWeight.bold : FontWeight.normal),
                                        )),
                                        DataCell(Text(
                                          '₹${currentBal.toStringAsFixed(2)}',
                                          style: TextStyle(
                                            fontWeight: FontWeight.bold,
                                            color: currentBal > 0 ? Colors.red.shade700 : Colors.teal.shade700,
                                          ),
                                        )),
                                        DataCell(
                                          r.paymentId != null
                                              ? IconButton(
                                                  icon: const Icon(Icons.delete_outline, color: Colors.red, size: 20),
                                                  tooltip: 'Delete Payment Receipt',
                                                  onPressed: () async {
                                                    await customerProvider.deletePayment(r.paymentId!, _selectedCustomer!.id!);
                                                    await invoiceProvider.loadInvoices();
                                                    setState(() {});
                                                  },
                                                )
                                              : const Text('-'),
                                        ),
                                      ]);
                                    }),
                                  ],
                                );
                              },
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
          );
        },
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
