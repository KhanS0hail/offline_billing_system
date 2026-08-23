import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:printing/printing.dart';
import '../providers/invoice_provider.dart';
import '../providers/company_provider.dart';
import '../models/invoice.dart';
import '../utils/pdf_statement_builder.dart';
import 'pdf_preview_screen.dart';

enum SalesFilterMode { monthly, yearly, customRange }

class SalesReportView extends StatefulWidget {
  const SalesReportView({super.key});

  @override
  State<SalesReportView> createState() => _SalesReportViewState();
}

class _SalesReportViewState extends State<SalesReportView> {
  SalesFilterMode _filterMode = SalesFilterMode.monthly;

  String _selectedMonth = 'August';
  int _selectedYear = 2026;
  DateTime _startDate = DateTime(2026, 8, 1);
  DateTime _endDate = DateTime(2026, 8, 31);

  final List<String> _months = [
    'January', 'February', 'March', 'April', 'May', 'June',
    'July', 'August', 'September', 'October', 'November', 'December'
  ];

  final List<int> _years = [2024, 2025, 2026, 2027, 2028, 2029, 2030];

  @override
  void initState() {
    super.initState();
    final now = DateTime.now();
    _selectedMonth = _months[now.month - 1];
    _selectedYear = now.year;
    _startDate = DateTime(now.year, now.month, 1);
    _endDate = DateTime(now.year, now.month + 1, 0);
  }

  int _getMonthIndex(String monthName) {
    return _months.indexOf(monthName) + 1;
  }

  DateTime? _parseInvoiceDate(String dateStr) {
    if (dateStr.trim().isEmpty) return null;
    final clean = dateStr.trim();

    // 1. Try standard ISO parse (e.g. 2026-08-17)
    try {
      final isoDate = DateTime.tryParse(clean);
      if (isoDate != null) return isoDate;
    } catch (_) {}

    // 2. Try split with '-' or '/' or ' '
    final delimiters = RegExp(r'[-/ ]');
    final parts = clean.split(delimiters).where((p) => p.isNotEmpty).toList();
    if (parts.length >= 3) {
      int? day;
      int? month;
      int? year;

      final monthsShort = ['jan', 'feb', 'mar', 'apr', 'may', 'jun', 'jul', 'aug', 'sep', 'oct', 'nov', 'dec'];
      final monthsFull = [
        'january', 'february', 'march', 'april', 'may', 'june',
        'july', 'august', 'september', 'october', 'november', 'december'
      ];

      // Case A: YYYY-MM-DD
      if (parts[0].length == 4 && int.tryParse(parts[0]) != null) {
        year = int.parse(parts[0]);
        month = int.tryParse(parts[1]);
        day = int.tryParse(parts[2]);
      } else {
        // Case B: DD-MM-YYYY or DD-MMM-YYYY
        day = int.tryParse(parts[0]);

        // Try parsing month as number
        month = int.tryParse(parts[1]);
        if (month == null) {
          final mLower = parts[1].toLowerCase();
          final sIdx = monthsShort.indexWhere((m) => mLower.startsWith(m));
          if (sIdx != -1) {
            month = sIdx + 1;
          } else {
            final fIdx = monthsFull.indexOf(mLower);
            if (fIdx != -1) month = fIdx + 1;
          }
        }

        year = int.tryParse(parts[2]);
      }

      if (day != null && month != null && year != null) {
        if (year < 100) year += 2000;
        return DateTime(year, month, day);
      }
    }
    return null;
  }

  List<Invoice> _filterInvoices(List<Invoice> allInvoices) {
    return allInvoices.where((inv) {
      final invDate = _parseInvoiceDate(inv.date);
      if (invDate == null) return false;

      if (_filterMode == SalesFilterMode.monthly) {
        final mIdx = _getMonthIndex(_selectedMonth);
        return invDate.month == mIdx && invDate.year == _selectedYear;
      } else if (_filterMode == SalesFilterMode.yearly) {
        return invDate.year == _selectedYear;
      } else {
        // Custom Date Range
        final start = DateTime(_startDate.year, _startDate.month, _startDate.day);
        final end = DateTime(_endDate.year, _endDate.month, _endDate.day, 23, 59, 59);
        return invDate.isAfter(start.subtract(const Duration(seconds: 1))) &&
            invDate.isBefore(end.add(const Duration(seconds: 1)));
      }
    }).toList()
      ..sort((a, b) {
        final d1 = _parseInvoiceDate(a.date) ?? DateTime(2000);
        final d2 = _parseInvoiceDate(b.date) ?? DateTime(2000);
        return d2.compareTo(d1); // Newest first
      });
  }

  String _getPeriodTitle() {
    if (_filterMode == SalesFilterMode.monthly) {
      return '$_selectedMonth $_selectedYear';
    } else if (_filterMode == SalesFilterMode.yearly) {
      return 'Annual FY $_selectedYear';
    } else {
      return '${_startDate.day}/${_startDate.month}/${_startDate.year} to ${_endDate.day}/${_endDate.month}/${_endDate.year}';
    }
  }

  Future<void> _exportPdf(
    BuildContext context, {
    required List<Invoice> filteredInvoices,
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
    final company = Provider.of<CompanyProvider>(context, listen: false).company;
    final periodTitle = _getPeriodTitle();

    final pdfBytes = await PdfStatementBuilder.buildSalesReport(
      company: company,
      periodTitle: periodTitle,
      invoices: filteredInvoices,
      totalSales: totalSales,
      totalTaxable: totalTaxable,
      totalCgst: totalCgst,
      totalSgst: totalSgst,
      totalIgst: totalIgst,
      totalReceived: totalReceived,
      totalOutstanding: totalOutstanding,
      productSalesMap: productSalesMap,
      customerSalesMap: customerSalesMap,
    );

    await Printing.layoutPdf(
      onLayout: (_) => pdfBytes,
      name: 'Sales_Report_${periodTitle.replaceAll(' ', '_')}.pdf',
    );
  }

  @override
  Widget build(BuildContext context) {
    final invProvider = Provider.of<InvoiceProvider>(context);
    final allInvoices = invProvider.invoices;
    final filteredInvoices = _filterInvoices(allInvoices);

    double totalSales = 0.0;
    double totalTaxable = 0.0;
    double totalCgst = 0.0;
    double totalSgst = 0.0;
    double totalIgst = 0.0;
    double totalReceived = 0.0;
    double totalOutstanding = 0.0;

    int paidCount = 0;
    int partialCount = 0;
    int unpaidCount = 0;

    // Aggregations
    final Map<String, Map<String, dynamic>> productSalesMap = {};
    final Map<String, Map<String, dynamic>> customerSalesMap = {};

    for (var inv in filteredInvoices) {
      totalSales += inv.grandTotal;
      totalTaxable += inv.taxableBase;
      totalCgst += inv.cgstTotal;
      totalSgst += inv.sgstTotal;
      totalIgst += inv.igstTotal;
      totalReceived += inv.receivedAmount;
      totalOutstanding += inv.balanceAmount;

      if (inv.status == 'Paid') paidCount++;
      if (inv.status == 'Partially Paid') partialCount++;
      if (inv.status == 'Unpaid') unpaidCount++;

      // Customer sales aggregation
      final cName = inv.customerName ?? 'Cash Customer';
      if (!customerSalesMap.containsKey(cName)) {
        customerSalesMap[cName] = {
          'count': 0,
          'billed': 0.0,
          'received': 0.0,
          'balance': 0.0,
        };
      }
      customerSalesMap[cName]!['count'] = (customerSalesMap[cName]!['count'] as int) + 1;
      customerSalesMap[cName]!['billed'] = (customerSalesMap[cName]!['billed'] as double) + inv.grandTotal;
      customerSalesMap[cName]!['received'] = (customerSalesMap[cName]!['received'] as double) + inv.receivedAmount;
      customerSalesMap[cName]!['balance'] = (customerSalesMap[cName]!['balance'] as double) + inv.balanceAmount;

      // Product sales aggregation
      for (var item in inv.items) {
        final pName = item.productName.trim().isEmpty ? 'Unnamed Product' : item.productName.trim();
        if (!productSalesMap.containsKey(pName)) {
          productSalesMap[pName] = {
            'qty': 0,
            'unit': item.unit,
            'revenue': 0.0,
          };
        }
        productSalesMap[pName]!['qty'] = (productSalesMap[pName]!['qty'] as int) + item.quantity;
        productSalesMap[pName]!['revenue'] = (productSalesMap[pName]!['revenue'] as double) + item.amount;
      }
    }

    final double totalTax = totalCgst + totalSgst + totalIgst;

    return SingleChildScrollView(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 88),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // 1. FILTER CONTROLLER CARD
          Card(
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            child: Padding(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Filter Mode Dropdown
                  DropdownButtonFormField<SalesFilterMode>(
                    value: _filterMode,
                    decoration: const InputDecoration(
                      labelText: 'Report Period',
                      prefixIcon: Icon(Icons.filter_alt_rounded, color: Colors.blue),
                      border: OutlineInputBorder(),
                    ),
                    items: const [
                      DropdownMenuItem(
                        value: SalesFilterMode.monthly,
                        child: Text('Monthly Sales Report'),
                      ),
                      DropdownMenuItem(
                        value: SalesFilterMode.yearly,
                        child: Text('Yearly (Annual FY) Report'),
                      ),
                      DropdownMenuItem(
                        value: SalesFilterMode.customRange,
                        child: Text('Custom Date Range Report'),
                      ),
                    ],
                    onChanged: (SalesFilterMode? mode) {
                      if (mode != null) {
                        setState(() => _filterMode = mode);
                      }
                    },
                  ),
                  const Divider(height: 24),

                  // Filter Inputs
                  if (_filterMode == SalesFilterMode.monthly)
                    Row(
                      children: [
                        Expanded(
                          child: DropdownButtonFormField<String>(
                            value: _selectedMonth,
                            decoration: const InputDecoration(
                              labelText: 'Month',
                              prefixIcon: Icon(Icons.calendar_month),
                              border: OutlineInputBorder(),
                            ),
                            items: _months.map((m) => DropdownMenuItem(value: m, child: Text(m))).toList(),
                            onChanged: (v) {
                              if (v != null) setState(() => _selectedMonth = v);
                            },
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: DropdownButtonFormField<int>(
                            value: _selectedYear,
                            decoration: const InputDecoration(
                              labelText: 'Year',
                              prefixIcon: Icon(Icons.today),
                              border: OutlineInputBorder(),
                            ),
                            items: _years.map((y) => DropdownMenuItem(value: y, child: Text(y.toString()))).toList(),
                            onChanged: (v) {
                              if (v != null) setState(() => _selectedYear = v);
                            },
                          ),
                        ),
                      ],
                    )
                  else if (_filterMode == SalesFilterMode.yearly)
                    DropdownButtonFormField<int>(
                      value: _selectedYear,
                      decoration: const InputDecoration(
                        labelText: 'Select Financial / Calendar Year',
                        prefixIcon: Icon(Icons.calendar_today_rounded),
                        border: OutlineInputBorder(),
                      ),
                      items: _years.map((y) => DropdownMenuItem(value: y, child: Text('Full Year $y'))).toList(),
                      onChanged: (v) {
                        if (v != null) setState(() => _selectedYear = v);
                      },
                    )
                  else
                    Row(
                      children: [
                        Expanded(
                          child: OutlinedButton.icon(
                            icon: const Icon(Icons.date_range),
                            label: Text('From: ${_startDate.day}/${_startDate.month}/${_startDate.year}'),
                            style: OutlinedButton.styleFrom(padding: const EdgeInsets.symmetric(vertical: 16)),
                            onPressed: () async {
                              final picked = await showDatePicker(
                                context: context,
                                initialDate: _startDate,
                                firstDate: DateTime(2020),
                                lastDate: DateTime(2035),
                              );
                              if (picked != null) setState(() => _startDate = picked);
                            },
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: OutlinedButton.icon(
                            icon: const Icon(Icons.event),
                            label: Text('To: ${_endDate.day}/${_endDate.month}/${_endDate.year}'),
                            style: OutlinedButton.styleFrom(padding: const EdgeInsets.symmetric(vertical: 16)),
                            onPressed: () async {
                              final picked = await showDatePicker(
                                context: context,
                                initialDate: _endDate,
                                firstDate: DateTime(2020),
                                lastDate: DateTime(2035),
                              );
                              if (picked != null) setState(() => _endDate = picked);
                            },
                          ),
                        ),
                      ],
                    ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 16),

          // 2. FINANCIAL SUMMARY METRIC CARDS
          Row(
            children: [
              Expanded(
                child: _buildMetricTile(
                  'Total Billed Sales',
                  '₹${totalSales.toStringAsFixed(2)}',
                  Colors.blue.shade700,
                  Icons.payments_rounded,
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: _buildMetricTile(
                  'Taxable Base',
                  '₹${totalTaxable.toStringAsFixed(2)}',
                  Colors.purple.shade700,
                  Icons.account_balance_wallet_rounded,
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: _buildMetricTile(
                  'Total GST Collected',
                  '₹${totalTax.toStringAsFixed(2)}',
                  Colors.teal.shade700,
                  Icons.receipt_long_rounded,
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Row(
            children: [
              Expanded(
                child: _buildMetricTile(
                  'Total Received',
                  '₹${totalReceived.toStringAsFixed(2)}',
                  Colors.green.shade700,
                  Icons.check_circle_rounded,
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: _buildMetricTile(
                  'Outstanding Due',
                  '₹${totalOutstanding.toStringAsFixed(2)}',
                  Colors.red.shade700,
                  Icons.pending_actions_rounded,
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: _buildMetricTile(
                  'Total Invoices',
                  '${filteredInvoices.length}',
                  Colors.indigo.shade700,
                  Icons.description_rounded,
                ),
              ),
            ],
          ),
          const SizedBox(height: 20),

          // 3. EXPORT BUTTON & SECTION TITLE
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Sales Performance for ${_getPeriodTitle()}',
                style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
              ),
              ElevatedButton.icon(
                onPressed: filteredInvoices.isEmpty
                    ? null
                    : () => _exportPdf(
                          context,
                          filteredInvoices: filteredInvoices,
                          totalSales: totalSales,
                          totalTaxable: totalTaxable,
                          totalCgst: totalCgst,
                          totalSgst: totalSgst,
                          totalIgst: totalIgst,
                          totalReceived: totalReceived,
                          totalOutstanding: totalOutstanding,
                          productSalesMap: productSalesMap,
                          customerSalesMap: customerSalesMap,
                        ),
                icon: const Icon(Icons.picture_as_pdf_rounded, size: 18),
                label: const Text('Export Sales PDF'),
              ),
            ],
          ),
          const SizedBox(height: 12),

          // 4. PRODUCT-WISE SALES BREAKDOWN
          if (productSalesMap.isNotEmpty) ...[
            Card(
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Row(
                      children: [
                        Icon(Icons.inventory_2_rounded, color: Colors.indigo, size: 20),
                        SizedBox(width: 8),
                        Text('Product-Wise Sales Volume', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 15)),
                      ],
                    ),
                    const Divider(height: 20),
                    ...productSalesMap.entries.map((entry) {
                      final pName = entry.key;
                      final data = entry.value;
                      final qty = data['qty'] as int;
                      final unit = data['unit'] ?? 'Pcs';
                      final rev = data['revenue'] as double;
                      final pct = totalSales > 0 ? (rev / totalSales) : 0.0;

                      return Padding(
                        padding: const EdgeInsets.only(bottom: 12.0),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Text(pName, style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 14)),
                                Text('₹${rev.toStringAsFixed(2)} ($qty $unit)', style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
                              ],
                            ),
                            const SizedBox(height: 4),
                            ClipRRect(
                              borderRadius: BorderRadius.circular(4),
                              child: LinearProgressIndicator(
                                value: pct.clamp(0.0, 1.0),
                                minHeight: 6,
                                backgroundColor: Colors.grey.shade200,
                                color: Colors.indigo,
                              ),
                            ),
                          ],
                        ),
                      );
                    }),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 16),
          ],

          // 5. CUSTOMER-WISE SALES BREAKDOWN
          if (customerSalesMap.isNotEmpty) ...[
            Card(
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Row(
                      children: [
                        Icon(Icons.people_alt_rounded, color: Colors.teal, size: 20),
                        SizedBox(width: 8),
                        Text('Customer-Wise Sales Summary', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 15)),
                      ],
                    ),
                    const Divider(height: 20),
                    SingleChildScrollView(
                      scrollDirection: Axis.horizontal,
                      child: DataTable(
                        headingRowColor: MaterialStateProperty.all(Theme.of(context).colorScheme.primaryContainer.withOpacity(0.3)),
                        columns: const [
                          DataColumn(label: Text('Customer Name', style: TextStyle(fontWeight: FontWeight.bold))),
                          DataColumn(label: Text('Invoices', style: TextStyle(fontWeight: FontWeight.bold))),
                          DataColumn(label: Text('Total Billed', style: TextStyle(fontWeight: FontWeight.bold))),
                          DataColumn(label: Text('Received', style: TextStyle(fontWeight: FontWeight.bold))),
                          DataColumn(label: Text('Balance Due', style: TextStyle(fontWeight: FontWeight.bold))),
                        ],
                        rows: customerSalesMap.entries.map((entry) {
                          final cName = entry.key;
                          final data = entry.value;
                          final count = data['count'] as int;
                          final billed = data['billed'] as double;
                          final rec = data['received'] as double;
                          final bal = data['balance'] as double;

                          return DataRow(
                            cells: [
                              DataCell(Text(cName, style: const TextStyle(fontWeight: FontWeight.bold))),
                              DataCell(Text('$count')),
                              DataCell(Text('₹${billed.toStringAsFixed(2)}')),
                              DataCell(Text('₹${rec.toStringAsFixed(2)}', style: const TextStyle(color: Colors.green))),
                              DataCell(Text('₹${bal.toStringAsFixed(2)}', style: TextStyle(color: bal > 0 ? Colors.red : Colors.grey, fontWeight: FontWeight.bold))),
                            ],
                          );
                        }).toList(),
                      ),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 16),
          ],

          // 6. INVOICES SCHEDULE LIST
          Card(
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            child: Padding(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Row(
                        children: [
                          const Icon(Icons.receipt_long_rounded, color: Colors.blue, size: 20),
                          const SizedBox(width: 8),
                          Text('Invoices in this Period (${filteredInvoices.length})', style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15)),
                        ],
                      ),
                      if (filteredInvoices.isNotEmpty)
                        Text('Total: ₹${totalSales.toStringAsFixed(2)}', style: const TextStyle(fontWeight: FontWeight.bold, color: Colors.blue)),
                    ],
                  ),
                  const Divider(height: 20),
                  if (filteredInvoices.isEmpty)
                    const Padding(
                      padding: EdgeInsets.symmetric(vertical: 24.0),
                      child: Center(
                        child: Text('No invoices found for the selected period.', style: TextStyle(color: Colors.grey)),
                      ),
                    )
                  else
                    ListView.separated(
                      shrinkWrap: true,
                      physics: const NeverScrollableScrollPhysics(),
                      itemCount: filteredInvoices.length,
                      separatorBuilder: (_, __) => const Divider(height: 1),
                      itemBuilder: (ctx, idx) {
                        final inv = filteredInvoices[idx];
                        final isPaid = inv.status == 'Paid';
                        final isPartial = inv.status == 'Partially Paid';

                        return ListTile(
                          contentPadding: EdgeInsets.zero,
                          leading: CircleAvatar(
                            backgroundColor: isPaid ? Colors.green.shade100 : (isPartial ? Colors.orange.shade100 : Colors.red.shade100),
                            child: Icon(
                              isPaid ? Icons.check_circle : (isPartial ? Icons.rule : Icons.pending),
                              color: isPaid ? Colors.green.shade800 : (isPartial ? Colors.orange.shade800 : Colors.red.shade800),
                              size: 18,
                            ),
                          ),
                          title: Text(inv.invoiceNumber, style: const TextStyle(fontWeight: FontWeight.bold)),
                          subtitle: Text('${inv.customerName ?? "Cash"} • ${inv.date}'),
                          trailing: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Column(
                                mainAxisAlignment: MainAxisAlignment.center,
                                crossAxisAlignment: CrossAxisAlignment.end,
                                children: [
                                  Text('₹${inv.grandTotal.toStringAsFixed(2)}', style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
                                  Text(inv.status, style: TextStyle(fontSize: 11, color: isPaid ? Colors.green : (isPartial ? Colors.orange : Colors.red))),
                                ],
                              ),
                              const SizedBox(width: 8),
                              IconButton(
                                icon: const Icon(Icons.picture_as_pdf, color: Colors.blue, size: 20),
                                tooltip: 'View Invoice PDF',
                                onPressed: () {
                                  Navigator.push(
                                    context,
                                    MaterialPageRoute(builder: (_) => PdfPreviewScreen(invoice: inv)),
                                  );
                                },
                              ),
                            ],
                          ),
                        );
                      },
                    ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMetricTile(String title, String value, Color color, IconData icon) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: color.withOpacity(0.08),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: color.withOpacity(0.25)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icon, size: 16, color: color),
              const SizedBox(width: 6),
              Expanded(
                child: Text(
                  title,
                  style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: color),
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ],
          ),
          const SizedBox(height: 6),
          Text(
            value,
            style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: color),
            overflow: TextOverflow.ellipsis,
          ),
        ],
      ),
    );
  }
}
