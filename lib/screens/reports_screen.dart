import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/invoice_provider.dart';
import '../providers/customer_provider.dart';
import 'customer_ledger_screen.dart';
import 'gst_report_screen.dart';
import 'sales_report_view.dart';

class ReportsScreen extends StatelessWidget {
  const ReportsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return DefaultTabController(
      length: 4,
      child: Scaffold(
        appBar: AppBar(
          title: const Text('Reports & Analytics Hub'),
          bottom: const TabBar(
            isScrollable: true,
            tabAlignment: TabAlignment.start,
            tabs: [
              Tab(icon: Icon(Icons.analytics_rounded), text: 'Analytics'),
              Tab(icon: Icon(Icons.point_of_sale_rounded), text: 'Sales Reports'),
              Tab(icon: Icon(Icons.menu_book_rounded), text: 'Customer Ledgers'),
              Tab(icon: Icon(Icons.receipt_long_rounded), text: 'GST Tax Reports'),
            ],
          ),
        ),
        body: const TabBarView(
          children: [
            _AnalyticsOverviewTab(),
            SalesReportView(),
            CustomerLedgerScreen(),
            GstReportScreen(),
          ],
        ),
      ),
    );
  }
}

class _AnalyticsOverviewTab extends StatelessWidget {
  const _AnalyticsOverviewTab();

  @override
  Widget build(BuildContext context) {
    final invoiceProvider = Provider.of<InvoiceProvider>(context);
    final customerProvider = Provider.of<CustomerProvider>(context);

    final invoices = invoiceProvider.invoices;

    double totalRevenue = 0.0;
    double totalReceived = 0.0;
    double totalOutstanding = 0.0;
    double totalTaxable = 0.0;
    double totalGst = 0.0;

    // Customer Revenue Aggregation
    Map<String, double> customerSalesMap = {};

    for (var inv in invoices) {
      totalRevenue += inv.grandTotal;
      totalReceived += inv.receivedAmount;
      totalOutstanding += inv.balanceAmount;
      totalTaxable += inv.taxableBase;
      totalGst += (inv.cgstTotal + inv.sgstTotal + inv.igstTotal);

      String cName = inv.customerName ?? 'Cash Customer';
      customerSalesMap[cName] = (customerSalesMap[cName] ?? 0.0) + inv.grandTotal;
    }

    final topCustomers = customerSalesMap.entries.toList()
      ..sort((a, b) => b.value.compareTo(a.value));

    return SingleChildScrollView(
      padding: const EdgeInsets.all(16.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // 1. OVERVIEW METRIC TILES
          Row(
            children: [
              Expanded(
                child: _buildSummaryCard(
                  'Total Revenue',
                  '₹${totalRevenue.toStringAsFixed(2)}',
                  Colors.blue.shade700,
                  Icons.payments_rounded,
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: _buildSummaryCard(
                  'Total Received',
                  '₹${totalReceived.toStringAsFixed(2)}',
                  Colors.green.shade700,
                  Icons.check_circle_rounded,
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: _buildSummaryCard(
                  'Outstanding Due',
                  '₹${totalOutstanding.toStringAsFixed(2)}',
                  Colors.red.shade700,
                  Icons.pending_actions_rounded,
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: _buildSummaryCard(
                  'GST Liability',
                  '₹${totalGst.toStringAsFixed(2)}',
                  Colors.amber.shade800,
                  Icons.account_balance_rounded,
                ),
              ),
            ],
          ),

          const SizedBox(height: 20),

          // 2. TOP CUSTOMERS BY REVENUE CARD
          Card(
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            child: Padding(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Row(
                    children: [
                      Icon(Icons.leaderboard_rounded, color: Colors.blue),
                      SizedBox(width: 8),
                      Text('Top Customers by Sales Volume', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                    ],
                  ),
                  const SizedBox(height: 12),
                  topCustomers.isEmpty
                      ? const Padding(
                          padding: EdgeInsets.all(16.0),
                          child: Text('No invoice sales recorded yet.'),
                        )
                      : Column(
                          children: topCustomers.take(5).map((e) {
                            double percent = totalRevenue > 0 ? (e.value / totalRevenue) : 0;
                            return Padding(
                              padding: const EdgeInsets.only(bottom: 10.0),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Row(
                                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                    children: [
                                      Text(e.key, style: const TextStyle(fontWeight: FontWeight.w600)),
                                      Text('₹${e.value.toStringAsFixed(2)}', style: const TextStyle(fontWeight: FontWeight.bold)),
                                    ],
                                  ),
                                  const SizedBox(height: 4),
                                  LinearProgressIndicator(
                                    value: percent,
                                    backgroundColor: Colors.grey.shade200,
                                    color: Theme.of(context).colorScheme.primary,
                                    minHeight: 6,
                                    borderRadius: BorderRadius.circular(3),
                                  ),
                                ],
                              ),
                            );
                          }).toList(),
                        ),
                ],
              ),
            ),
          ),

          const SizedBox(height: 20),

          // 3. STATISTICAL QUICK BREAKDOWN
          Card(
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            child: Padding(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Row(
                    children: [
                      Icon(Icons.pie_chart_rounded, color: Colors.purple),
                      SizedBox(width: 8),
                      Text('Business Health Snapshot', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                    ],
                  ),
                  const SizedBox(height: 12),
                  ListTile(
                    leading: const CircleAvatar(child: Icon(Icons.receipt_rounded)),
                    title: const Text('Total Invoices Generated'),
                    trailing: Text('${invoices.length}', style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                  ),
                  const Divider(),
                  ListTile(
                    leading: const CircleAvatar(child: Icon(Icons.people_rounded)),
                    title: const Text('Total Customers Registered'),
                    trailing: Text('${customerProvider.customers.length}', style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                  ),
                  const Divider(),
                  ListTile(
                    leading: const CircleAvatar(child: Icon(Icons.request_quote_rounded)),
                    title: const Text('Net Taxable Base'),
                    trailing: Text('₹${totalTaxable.toStringAsFixed(2)}', style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSummaryCard(String title, String value, Color color, IconData icon) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: color.withOpacity(0.3)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icon, size: 16, color: color),
              const SizedBox(width: 4),
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
