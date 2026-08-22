import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/invoice_provider.dart';
import '../providers/customer_provider.dart';
import '../models/invoice.dart';
import 'create_invoice_screen.dart';
import 'pdf_preview_screen.dart';

class InvoicesScreen extends StatefulWidget {
  const InvoicesScreen({super.key});

  @override
  State<InvoicesScreen> createState() => _InvoicesScreenState();
}

class _InvoicesScreenState extends State<InvoicesScreen> {
  String _searchQuery = '';
  String _dateFilterMode = 'All Time'; // 'All Time', 'This Month', 'This FY', 'Custom Range'
  DateTime? _customStartDate;
  DateTime? _customEndDate;
  String _statusFilter = 'All'; // 'All', 'Unpaid', 'Partially Paid', 'Paid'
  String _sortOrder = 'Newest First'; // 'Newest First', 'Oldest First', 'Amount: High to Low', 'Amount: Low to High', 'Invoice #: A-Z'

  DateTime? _parseInvoiceDate(String dateStr) {
    try {
      final parts = dateStr.split('-');
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
      return DateTime.parse(dateStr);
    } catch (_) {}
    return null;
  }

  bool _isDateInFilter(DateTime? date) {
    if (date == null) return true;

    final now = DateTime.now();
    if (_dateFilterMode == 'This Month') {
      return date.year == now.year && date.month == now.month;
    } else if (_dateFilterMode == 'This FY') {
      int startYear = now.month >= 4 ? now.year : now.year - 1;
      final fyStart = DateTime(startYear, 4, 1);
      final fyEnd = DateTime(startYear + 1, 3, 31, 23, 59, 59);
      return date.isAfter(fyStart.subtract(const Duration(seconds: 1))) && date.isBefore(fyEnd.add(const Duration(seconds: 1)));
    } else if (_dateFilterMode == 'Custom Range') {
      if (_customStartDate != null && date.isBefore(DateTime(_customStartDate!.year, _customStartDate!.month, _customStartDate!.day))) {
        return false;
      }
      if (_customEndDate != null && date.isAfter(DateTime(_customEndDate!.year, _customEndDate!.month, _customEndDate!.day, 23, 59, 59))) {
        return false;
      }
      return true;
    }
    return true; // All Time
  }

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

  String _monthName(int m) {
    const months = ["Jan", "Feb", "Mar", "Apr", "May", "Jun", "Jul", "Aug", "Sep", "Oct", "Nov", "Dec"];
    return months[m - 1];
  }

  void _showUpdatePaymentDialog(BuildContext context, Invoice invoice) {
    String selectedStatus = invoice.status;
    final receivedController = TextEditingController(text: invoice.receivedAmount.toString());
    DateTime selectedPaymentDate = _parseInvoiceDate(invoice.paymentDate ?? invoice.date) ?? DateTime.now();

    showDialog(
      context: context,
      builder: (ctx) {
        return StatefulBuilder(
          builder: (context, setDialogState) {
            final formattedDateStr = "${selectedPaymentDate.day.toString().padLeft(2, '0')}-${_monthName(selectedPaymentDate.month)}-${selectedPaymentDate.year}";

            return AlertDialog(
              title: Text('Update Payment: ${invoice.invoiceNumber}'),
              content: SingleChildScrollView(
                child: Column(
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
                    if (selectedStatus == 'Paid' || selectedStatus == 'Partially Paid') ...[
                      const SizedBox(height: 12),
                      InkWell(
                        onTap: () async {
                          final picked = await showDatePicker(
                            context: context,
                            initialDate: selectedPaymentDate,
                            firstDate: DateTime(2020),
                            lastDate: DateTime(2035),
                          );
                          if (picked != null) {
                            setDialogState(() => selectedPaymentDate = picked);
                          }
                        },
                        child: InputDecorator(
                          decoration: const InputDecoration(
                            labelText: 'Payment Received Date',
                            prefixIcon: Icon(Icons.calendar_today),
                            border: OutlineInputBorder(),
                          ),
                          child: Text(formattedDateStr),
                        ),
                      ),
                    ],
                  ],
                ),
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

                    final paymentDateToSave = (selectedStatus == 'Paid' || selectedStatus == 'Partially Paid')
                        ? formattedDateStr
                        : null;

                    if (invoice.id != null) {
                      await Provider.of<InvoiceProvider>(context, listen: false).updateInvoicePayment(
                        invoice.id!,
                        selectedStatus,
                        received: rec,
                        balance: bal,
                        paymentDate: paymentDateToSave,
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

  void _showFilterBottomSheet(BuildContext context) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (ctx) {
        return StatefulBuilder(
          builder: (context, setSheetState) {
            return Container(
              constraints: BoxConstraints(
                maxHeight: MediaQuery.of(context).size.height * 0.82,
              ),
              padding: EdgeInsets.only(
                left: 20,
                right: 20,
                top: 20,
                bottom: MediaQuery.of(context).viewInsets.bottom + 20,
              ),
              child: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const Text(
                          'Filter & Sort Invoices',
                          style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                        ),
                        TextButton(
                          onPressed: () {
                            setSheetState(() {
                              _dateFilterMode = 'All Time';
                              _customStartDate = null;
                              _customEndDate = null;
                              _statusFilter = 'All';
                              _sortOrder = 'Newest First';
                            });
                            setState(() {});
                          },
                          child: const Text('Reset All'),
                        ),
                      ],
                    ),
                    const Divider(),
                    const SizedBox(height: 12),

                    // 1. DATE RANGE FILTER
                    const Text('Date Range Period', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
                    const SizedBox(height: 8),
                    DropdownButtonFormField<String>(
                      value: _dateFilterMode,
                      decoration: const InputDecoration(
                        border: OutlineInputBorder(),
                        contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 12),
                        prefixIcon: Icon(Icons.date_range),
                      ),
                      items: ['All Time', 'This Month', 'This FY', 'Custom Range']
                          .map((d) => DropdownMenuItem(value: d, child: Text(d)))
                          .toList(),
                      onChanged: (val) {
                        if (val != null) {
                          setSheetState(() {
                            _dateFilterMode = val;
                          });
                        }
                      },
                    ),
                    if (_dateFilterMode == 'Custom Range') ...[
                      const SizedBox(height: 8),
                      Row(
                        children: [
                          Expanded(
                            child: OutlinedButton.icon(
                              icon: const Icon(Icons.calendar_month, size: 16),
                              label: Text(_customStartDate != null ? "${_customStartDate!.day}/${_customStartDate!.month}/${_customStartDate!.year}" : "Start Date"),
                              onPressed: () async {
                                final picked = await showDatePicker(
                                  context: context,
                                  initialDate: _customStartDate ?? DateTime.now(),
                                  firstDate: DateTime(2020),
                                  lastDate: DateTime(2035),
                                );
                                if (picked != null) {
                                  setSheetState(() => _customStartDate = picked);
                                }
                              },
                            ),
                          ),
                          const SizedBox(width: 8),
                          Expanded(
                            child: OutlinedButton.icon(
                              icon: const Icon(Icons.calendar_month, size: 16),
                              label: Text(_customEndDate != null ? "${_customEndDate!.day}/${_customEndDate!.month}/${_customEndDate!.year}" : "End Date"),
                              onPressed: () async {
                                final picked = await showDatePicker(
                                  context: context,
                                  initialDate: _customEndDate ?? DateTime.now(),
                                  firstDate: DateTime(2020),
                                  lastDate: DateTime(2035),
                                );
                                if (picked != null) {
                                  setSheetState(() => _customEndDate = picked);
                                }
                              },
                            ),
                          ),
                        ],
                      ),
                    ],
                    const SizedBox(height: 16),

                    // 2. PAYMENT STATUS FILTER
                    const Text('Payment Status', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
                    const SizedBox(height: 8),
                    DropdownButtonFormField<String>(
                      value: _statusFilter,
                      decoration: const InputDecoration(
                        border: OutlineInputBorder(),
                        contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 12),
                        prefixIcon: Icon(Icons.payments),
                      ),
                      items: [
                        const DropdownMenuItem(value: 'All', child: Text('All Statuses')),
                        const DropdownMenuItem(value: 'Unpaid', child: Text('Unpaid Only')),
                        const DropdownMenuItem(value: 'Partially Paid', child: Text('Partially Paid Only')),
                        const DropdownMenuItem(value: 'Paid', child: Text('Paid Only')),
                      ],
                      onChanged: (val) {
                        if (val != null) {
                          setSheetState(() => _statusFilter = val);
                        }
                      },
                    ),
                    const SizedBox(height: 16),

                    // 3. SORTING ORDER
                    const Text('Sort By', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
                    const SizedBox(height: 8),
                    DropdownButtonFormField<String>(
                      value: _sortOrder,
                      decoration: const InputDecoration(
                        border: OutlineInputBorder(),
                        contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 12),
                        prefixIcon: Icon(Icons.sort),
                      ),
                      items: [
                        'Newest First',
                        'Oldest First',
                        'Amount: High to Low',
                        'Amount: Low to High',
                        'Invoice #: A-Z',
                      ].map((s) => DropdownMenuItem(value: s, child: Text(s))).toList(),
                      onChanged: (val) {
                        if (val != null) {
                          setSheetState(() => _sortOrder = val);
                        }
                      },
                    ),
                    const SizedBox(height: 24),

                    // APPLY BUTTON
                    SizedBox(
                      width: double.infinity,
                      height: 48,
                      child: ElevatedButton(
                        style: ElevatedButton.styleFrom(
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                        ),
                        onPressed: () {
                          setState(() {});
                          Navigator.pop(ctx);
                        },
                        child: const Text('Apply Filters & Sort', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                      ),
                    ),
                  ],
                ),
              ),
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
          // 1. FILTERING INVOICE LIST
          List<Invoice> filteredInvoices = provider.invoices.where((inv) {
            // Search Query Filter
            if (_searchQuery.isNotEmpty) {
              final query = _searchQuery.toLowerCase();
              final numMatch = inv.invoiceNumber.toLowerCase().contains(query);
              final poMatch = (inv.poNumber ?? '').toLowerCase().contains(query);
              final custMatch = (inv.customerName ?? '').toLowerCase().contains(query);
              final gstinMatch = (inv.customerGstin ?? '').toLowerCase().contains(query);
              if (!numMatch && !poMatch && !custMatch && !gstinMatch) return false;
            }

            // Payment Status Filter
            if (_statusFilter != 'All' && inv.status != _statusFilter) {
              return false;
            }

            // Date Period Filter
            final dt = _parseInvoiceDate(inv.date);
            if (!_isDateInFilter(dt)) {
              return false;
            }

            return true;
          }).toList();

          // 2. SORTING INVOICE LIST
          filteredInvoices.sort((a, b) {
            if (_sortOrder == 'Oldest First') {
              final dtA = _parseInvoiceDate(a.date) ?? DateTime(2000);
              final dtB = _parseInvoiceDate(b.date) ?? DateTime(2000);
              return dtA.compareTo(dtB);
            } else if (_sortOrder == 'Amount: High to Low') {
              return b.grandTotal.compareTo(a.grandTotal);
            } else if (_sortOrder == 'Amount: Low to High') {
              return a.grandTotal.compareTo(b.grandTotal);
            } else if (_sortOrder == 'Invoice #: A-Z') {
              return a.invoiceNumber.compareTo(b.invoiceNumber);
            } else {
              // Default: Newest First
              final dtA = _parseInvoiceDate(a.date) ?? DateTime(2000);
              final dtB = _parseInvoiceDate(b.date) ?? DateTime(2000);
              return dtB.compareTo(dtA);
            }
          });

          // 3. STATS RE-CALCULATION BASED ON FILTERED LIST
          double totalSales = 0.0;
          double paidAmount = 0.0;
          double unpaidAmount = 0.0;

          for (var inv in filteredInvoices) {
            totalSales += inv.grandTotal;
            paidAmount += inv.receivedAmount;
            unpaidAmount += inv.balanceAmount;
          }

          int activeFilterCount = 0;
          if (_dateFilterMode != 'All Time') activeFilterCount++;
          if (_statusFilter != 'All') activeFilterCount++;
          if (_sortOrder != 'Newest First') activeFilterCount++;

          return Column(
            children: [
              // 1. OVERVIEW STATS CARD (DYNAMICALLY SYNCED)
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

              // 2. 70% SEARCH / 30% FILTER BUTTON ROW
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16.0),
                child: Row(
                  children: [
                    // 70% Search Input
                    Expanded(
                      flex: 7,
                      child: TextField(
                        decoration: InputDecoration(
                          hintText: 'Search #, PO, Customer...',
                          prefixIcon: const Icon(Icons.search),
                          border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                          contentPadding: const EdgeInsets.symmetric(horizontal: 14),
                          isDense: true,
                        ),
                        onChanged: (v) {
                          setState(() {
                            _searchQuery = v;
                          });
                        },
                      ),
                    ),
                    const SizedBox(width: 8),

                    // 30% Filter & Sort Action Button
                    Expanded(
                      flex: 3,
                      child: SizedBox(
                        height: 48,
                        child: OutlinedButton(
                          style: OutlinedButton.styleFrom(
                            padding: const EdgeInsets.symmetric(horizontal: 8),
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                            side: BorderSide(
                              color: activeFilterCount > 0 ? Theme.of(context).colorScheme.primary : Colors.grey.shade400,
                              width: activeFilterCount > 0 ? 1.8 : 1.0,
                            ),
                          ),
                          onPressed: () => _showFilterBottomSheet(context),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(
                                Icons.tune,
                                size: 18,
                                color: activeFilterCount > 0 ? Theme.of(context).colorScheme.primary : Colors.grey.shade700,
                              ),
                              const SizedBox(width: 4),
                              Flexible(
                                child: Text(
                                  activeFilterCount > 0 ? 'Filter ($activeFilterCount)' : 'Filter',
                                  style: TextStyle(
                                    fontSize: 13,
                                    fontWeight: activeFilterCount > 0 ? FontWeight.bold : FontWeight.normal,
                                    color: activeFilterCount > 0 ? Theme.of(context).colorScheme.primary : Colors.grey.shade800,
                                  ),
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 12),

              // 3. INVOICE LIST VIEW
              Expanded(
                child: provider.isLoading
                    ? const Center(child: CircularProgressIndicator())
                    : filteredInvoices.isEmpty
                        ? const Center(
                            child: Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Icon(Icons.receipt_outlined, size: 64, color: Colors.grey),
                                SizedBox(height: 16),
                                Text('No matching invoices found.'),
                              ],
                            ),
                          )
                        : ListView.builder(
                            itemCount: filteredInvoices.length,
                            padding: const EdgeInsets.fromLTRB(16, 0, 16, 88),
                            itemBuilder: (context, index) {
                              final inv = filteredInvoices[index];
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
                                child: InkWell(
                                  borderRadius: BorderRadius.circular(12),
                                  onTap: () {
                                    Navigator.push(
                                      context,
                                      MaterialPageRoute(
                                        builder: (_) => PdfPreviewScreen(invoice: inv),
                                      ),
                                    );
                                  },
                                  child: Padding(
                                    padding: const EdgeInsets.all(14.0),
                                    child: Column(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      children: [
                                        // 1. Top Row: Status Avatar + Invoice Number (Left Aligned) & Date (Right Aligned)
                                        Row(
                                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                          children: [
                                            Row(
                                              children: [
                                                CircleAvatar(
                                                  radius: 14,
                                                  backgroundColor: statusColor.withOpacity(0.15),
                                                  child: Icon(statusIcon, color: statusColor, size: 16),
                                                ),
                                                const SizedBox(width: 8),
                                                Text(
                                                  inv.invoiceNumber,
                                                  style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                                                ),
                                              ],
                                            ),
                                            Text(
                                              inv.date,
                                              style: TextStyle(fontSize: 13, color: Colors.grey.shade700, fontWeight: FontWeight.w500),
                                            ),
                                          ],
                                        ),
                                        const SizedBox(height: 8),

                                        // 2. Customer
                                        Text(
                                          'Customer: ${inv.customerName ?? "Cash Customer"}',
                                          style: const TextStyle(fontSize: 14, color: Colors.black87),
                                        ),
                                        const SizedBox(height: 4),

                                        // 3. Grand Total Amount & Due Amount Line
                                        RichText(
                                          text: TextSpan(
                                            style: const TextStyle(fontSize: 14, color: Colors.black87),
                                            children: [
                                              const TextSpan(text: 'Grand Total: '),
                                              TextSpan(
                                                text: '₹${inv.grandTotal.toStringAsFixed(2)}',
                                                style: TextStyle(
                                                  fontWeight: FontWeight.bold,
                                                  color: Theme.of(context).colorScheme.primary,
                                                ),
                                              ),
                                              const TextSpan(text: '  |  Due: '),
                                              TextSpan(
                                                text: '₹${inv.balanceAmount.toStringAsFixed(2)}',
                                                style: TextStyle(
                                                  fontWeight: FontWeight.bold,
                                                  color: inv.balanceAmount > 0 ? Colors.red.shade700 : Colors.green.shade700,
                                                ),
                                              ),
                                            ],
                                          ),
                                        ),
                                        const SizedBox(height: 8),

                                        const Divider(height: 1, thickness: 0.8),
                                        const SizedBox(height: 4),

                                        // 4. Last Line: All Action Buttons
                                        Row(
                                          mainAxisAlignment: MainAxisAlignment.end,
                                          children: [
                                            TextButton.icon(
                                              icon: const Icon(Icons.picture_as_pdf, color: Colors.blue, size: 18),
                                              label: const Text('PDF'),
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
                                              icon: const Icon(Icons.edit, color: Colors.amber),
                                              tooltip: 'Edit Invoice',
                                              onPressed: () {
                                                final customers = Provider.of<CustomerProvider>(context, listen: false).customers;
                                                provider.prepareEditInvoice(inv, customers);
                                                Navigator.push(
                                                  context,
                                                  MaterialPageRoute(builder: (_) => const CreateInvoiceScreen()),
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
                                              tooltip: 'Delete Invoice',
                                              onPressed: () => _confirmDelete(context, inv),
                                            ),
                                          ],
                                        ),
                                      ],
                                    ),
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
