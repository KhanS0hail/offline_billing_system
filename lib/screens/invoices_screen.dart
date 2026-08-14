import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/invoice_provider.dart';
import '../models/invoice.dart';
import 'create_invoice_screen.dart';

class InvoicesScreen extends StatelessWidget {
  const InvoicesScreen({super.key});

  void _confirmDelete(BuildContext context, Invoice invoice) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Delete Invoice?'),
        content: Text('Are you sure you want to delete invoice "${invoice.invoiceNumber}"?'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Cancel')),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            onPressed: () async {
              if (invoice.id != null) {
                await Provider.of<InvoiceProvider>(context, listen: false).deleteInvoice(invoice.id!);
              }
              if (ctx.mounted) Navigator.pop(ctx);
            },
            child: const Text('Delete', style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Invoices History'),
      ),
      body: Consumer<InvoiceProvider>(
        builder: (context, provider, child) {
          final invoices = provider.invoices;

          double totalSales = 0.0;
          double paidAmount = 0.0;
          double unpaidAmount = 0.0;

          for (var inv in provider.invoices) {
            totalSales += inv.grandTotal;
            if (inv.status == 'Paid') {
              paidAmount += inv.grandTotal;
            } else {
              unpaidAmount += inv.grandTotal;
            }
          }

          return Column(
            children: [
              // 1. OVERVIEW STATS CARD
              Padding(
                padding: const EdgeInsets.all(16.0),
                child: Row(
                  children: [
                    Expanded(
                      child: _buildStatCard(
                        context,
                        'Total Sales',
                        '₹${totalSales.toStringAsFixed(2)}',
                        Colors.blue.shade700,
                        Icons.trending_up,
                      ),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: _buildStatCard(
                        context,
                        'Paid',
                        '₹${paidAmount.toStringAsFixed(2)}',
                        Colors.green.shade700,
                        Icons.check_circle_outline,
                      ),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: _buildStatCard(
                        context,
                        'Unpaid',
                        '₹${unpaidAmount.toStringAsFixed(2)}',
                        Colors.red.shade700,
                        Icons.pending_actions,
                      ),
                    ),
                  ],
                ),
              ),

              // 2. SEARCH & FILTER BAR
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16.0),
                child: Column(
                  children: [
                    TextField(
                      decoration: InputDecoration(
                        hintText: 'Search by Invoice # or Customer...',
                        prefixIcon: const Icon(Icons.search),
                        border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                        contentPadding: const EdgeInsets.symmetric(horizontal: 16),
                      ),
                      onChanged: (v) => provider.setSearchQuery(v),
                    ),
                    const SizedBox(height: 8),
                    SegmentedButton<String>(
                      segments: const [
                        ButtonSegment(value: 'All', label: Text('All')),
                        ButtonSegment(value: 'Unpaid', label: Text('Unpaid')),
                        ButtonSegment(value: 'Paid', label: Text('Paid')),
                      ],
                      selected: {provider.filterStatus},
                      onSelectionChanged: (s) => provider.setFilterStatus(s.first),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 12),

              // 3. INVOICE LIST VIEW
              Expanded(
                child: provider.isLoading
                    ? const Center(child: CircularProgressIndicator())
                    : invoices.isEmpty
                        ? const Center(
                            child: Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Icon(Icons.receipt_outlined, size: 64, color: Colors.grey),
                                SizedBox(height: 16),
                                Text('No invoices found. Click + to create an invoice!'),
                              ],
                            ),
                          )
                        : ListView.builder(
                            itemCount: invoices.length,
                            padding: const EdgeInsets.symmetric(horizontal: 16),
                            itemBuilder: (context, index) {
                              final inv = invoices[index];
                              final isPaid = inv.status == 'Paid';

                              return Card(
                                margin: const EdgeInsets.only(bottom: 12),
                                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                                child: ListTile(
                                  leading: CircleAvatar(
                                    backgroundColor: isPaid ? Colors.green.shade100 : Colors.red.shade100,
                                    child: Icon(
                                      isPaid ? Icons.check_circle : Icons.pending,
                                      color: isPaid ? Colors.green.shade800 : Colors.red.shade800,
                                    ),
                                  ),
                                  title: Row(
                                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                    children: [
                                      Text(inv.invoiceNumber, style: const TextStyle(fontWeight: FontWeight.bold)),
                                      Text(
                                        '₹${inv.grandTotal.toStringAsFixed(2)}',
                                        style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16, color: Theme.of(context).colorScheme.primary),
                                      ),
                                    ],
                                  ),
                                  subtitle: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Text('Customer: ${inv.customerName ?? "Cash Customer"}'),
                                      Text('Date: ${inv.date}${inv.dueDate != null ? " | Due: ${inv.dueDate}" : ""}'),
                                      if (inv.challanNumber != null && inv.challanNumber!.isNotEmpty)
                                        Text('Challan #: ${inv.challanNumber}'),
                                    ],
                                  ),
                                  trailing: Row(
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      IconButton(
                                        icon: Icon(
                                          isPaid ? Icons.undo : Icons.task_alt,
                                          color: isPaid ? Colors.orange : Colors.green,
                                        ),
                                        tooltip: isPaid ? 'Mark as Unpaid' : 'Mark as Paid',
                                        onPressed: () async {
                                          if (inv.id != null) {
                                            await provider.updateInvoiceStatus(inv.id!, isPaid ? 'Unpaid' : 'Paid');
                                          }
                                        },
                                      ),
                                      IconButton(
                                        icon: const Icon(Icons.delete, color: Colors.red),
                                        onPressed: () => _confirmDelete(context, inv),
                                      ),
                                    ],
                                  ),
                                ),
                              );
                            },
                          ),
              ),
            ],
          );
        },
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () async {
          final invProvider = Provider.of<InvoiceProvider>(context, listen: false);
          await invProvider.prepareNewInvoice();
          if (context.mounted) {
            Navigator.push(
              context,
              MaterialPageRoute(builder: (_) => const CreateInvoiceScreen()),
            );
          }
        },
        icon: const Icon(Icons.post_add),
        label: const Text('Create Invoice'),
      ),
    );
  }

  Widget _buildStatCard(BuildContext context, String title, String value, Color color, IconData icon) {
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
