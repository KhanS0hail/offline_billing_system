import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/invoice_provider.dart';
import '../models/invoice.dart';
import 'create_invoice_screen.dart';
import 'pdf_preview_screen.dart';

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

  void _showUpdatePaymentDialog(BuildContext context, Invoice invoice) {
    String selectedStatus = invoice.status;
    final receivedController = TextEditingController(text: invoice.receivedAmount.toString());

    showDialog(
      context: context,
      builder: (ctx) {
        return StatefulBuilder(
          builder: (context, setDialogState) {
            return AlertDialog(
              title: Text('Update Payment: ${invoice.invoiceNumber}'),
              content: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('Total Bill: ₹${invoice.grandTotal.toStringAsFixed(2)}', style: const TextStyle(fontWeight: FontWeight.bold)),
                  const SizedBox(height: 12),
                  const Text('Payment Status:'),
                  const SizedBox(height: 6),
                  DropdownButtonFormField<String>(
                    value: selectedStatus,
                    decoration: const InputDecoration(border: OutlineInputBorder()),
                    items: ['Unpaid', 'Partially Paid', 'Paid']
                        .map((s) => DropdownMenuItem(value: s, child: Text(s)))
                        .toList(),
                    onChanged: (val) {
                      if (val != null) {
                        setDialogState(() {
                          selectedStatus = val;
                          if (val == 'Paid') {
                            receivedController.text = invoice.grandTotal.toString();
                          } else if (val == 'Unpaid') {
                            receivedController.text = '0.0';
                          }
                        });
                      }
                    },
                  ),
                  if (selectedStatus == 'Partially Paid') ...[
                    const SizedBox(height: 12),
                    TextField(
                      controller: receivedController,
                      keyboardType: const TextInputType.numberWithOptions(decimal: true),
                      decoration: const InputDecoration(labelText: 'Received Amount (₹)', border: OutlineInputBorder()),
                    ),
                  ],
                ],
              ),
              actions: [
                TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Cancel')),
                ElevatedButton(
                  onPressed: () async {
                    double rec = double.tryParse(receivedController.text.trim()) ?? 0.0;
                    if (selectedStatus == 'Paid') rec = invoice.grandTotal;
                    if (selectedStatus == 'Unpaid') rec = 0.0;
                    double bal = invoice.grandTotal - rec;
                    if (bal < 0) bal = 0.0;

                    if (invoice.id != null) {
                      await Provider.of<InvoiceProvider>(context, listen: false).updateInvoicePayment(
                        invoice.id!,
                        selectedStatus,
                        received: rec,
                        balance: bal,
                      );
                    }
                    if (ctx.mounted) Navigator.pop(ctx);
                  },
                  child: const Text('Update Payment'),
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
            paidAmount += inv.receivedAmount;
            unpaidAmount += inv.balanceAmount;
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
                        'Received',
                        '₹${paidAmount.toStringAsFixed(2)}',
                        Colors.green.shade700,
                        Icons.check_circle_outline,
                      ),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: _buildStatCard(
                        context,
                        'Outstanding',
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
                        ButtonSegment(value: 'Partially Paid', label: Text('Partial')),
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
                              final isPartial = inv.status == 'Partially Paid';

                              Color statusColor = Colors.red;
                              IconData statusIcon = Icons.pending;
                              if (isPaid) {
                                statusColor = Colors.green;
                                statusIcon = Icons.check_circle;
                              } else if (isPartial) {
                                statusColor = Colors.orange;
                                statusIcon = Icons.rule;
                              }

                              return Card(
                                margin: const EdgeInsets.only(bottom: 12),
                                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                                child: ListTile(
                                  onTap: () {
                                    Navigator.push(
                                      context,
                                      MaterialPageRoute(
                                        builder: (_) => PdfPreviewScreen(invoice: inv),
                                      ),
                                    );
                                  },
                                  leading: CircleAvatar(
                                    backgroundColor: statusColor.withOpacity(0.2),
                                    child: Icon(statusIcon, color: statusColor),
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
                                      if (isPartial)
                                        Text(
                                          'Received: ₹${inv.receivedAmount.toStringAsFixed(2)} | Due: ₹${inv.balanceAmount.toStringAsFixed(2)}',
                                          style: const TextStyle(color: Colors.orange, fontWeight: FontWeight.bold),
                                        ),
                                    ],
                                  ),
                                  trailing: Row(
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      IconButton(
                                        icon: const Icon(Icons.picture_as_pdf, color: Colors.blue),
                                        tooltip: 'View / Print PDF',
                                        onPressed: () {
                                          Navigator.push(
                                            context,
                                            MaterialPageRoute(
                                              builder: (_) => PdfPreviewScreen(invoice: inv),
                                            ),
                                          );
                                        },
                                      ),
                                      IconButton(
                                        icon: Icon(Icons.edit_note, color: statusColor),
                                        tooltip: 'Update Payment Status',
                                        onPressed: () => _showUpdatePaymentDialog(context, inv),
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
