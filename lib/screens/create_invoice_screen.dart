import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/invoice_provider.dart';
import '../providers/customer_provider.dart';
import '../providers/product_provider.dart';
import '../providers/company_provider.dart';
import '../models/customer.dart';
import '../models/product.dart';
import '../models/invoice_item.dart';
import '../utils/number_to_words.dart';
import '../database/database_helper.dart';
import 'pdf_preview_screen.dart';

class CreateInvoiceScreen extends StatefulWidget {
  const CreateInvoiceScreen({super.key});

  @override
  State<CreateInvoiceScreen> createState() => _CreateInvoiceScreenState();
}

class _CreateInvoiceScreenState extends State<CreateInvoiceScreen> {
  late TextEditingController _invoiceNumberController;
  late TextEditingController _challanController;
  late TextEditingController _vehicleController;
  late TextEditingController _transportModeController;
  late TextEditingController _transportController;
  late TextEditingController _discountController;
  late TextEditingController _receivedController;
  late TextEditingController _notesController;

  final List<String> _availableUnits = [
    'Pcs', 'Nag', 'Bdl', 'Box', 'Kg', 'Gm', 'Mtr', 'Ltr', 'Set', 'Pack'
  ];

  @override
  void initState() {
    super.initState();
    final invProvider = Provider.of<InvoiceProvider>(context, listen: false);
    _invoiceNumberController = TextEditingController(text: invProvider.nextInvoiceNumber);
    _challanController = TextEditingController(text: invProvider.challanNumber ?? '');
    _vehicleController = TextEditingController(text: invProvider.vehicleNumber);
    _transportModeController = TextEditingController(text: invProvider.transportMode);
    _transportController = TextEditingController(text: invProvider.transportCharges == 0 ? '' : invProvider.transportCharges.toString());
    _discountController = TextEditingController(text: invProvider.discountAmount == 0 ? '' : invProvider.discountAmount.toString());
    _receivedController = TextEditingController(text: invProvider.receivedAmount == 0 ? '' : invProvider.receivedAmount.toString());
    _notesController = TextEditingController(text: invProvider.notes);
  }

  @override
  void dispose() {
    _invoiceNumberController.dispose();
    _challanController.dispose();
    _vehicleController.dispose();
    _transportModeController.dispose();
    _transportController.dispose();
    _discountController.dispose();
    _receivedController.dispose();
    _notesController.dispose();
    super.dispose();
  }

  void _showQuickAddCustomerDialog(BuildContext context) {
    final nameController = TextEditingController();
    final phoneController = TextEditingController();
    final addressController = TextEditingController();
    final gstController = TextEditingController();
    final stateCodeController = TextEditingController();

    showDialog(
      context: context,
      builder: (ctx) {
        return AlertDialog(
          title: const Text('Add New Customer'),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextField(
                  controller: nameController,
                  decoration: const InputDecoration(labelText: 'Customer / Business Name *', prefixIcon: Icon(Icons.person)),
                ),
                const SizedBox(height: 8),
                TextField(
                  controller: phoneController,
                  keyboardType: TextInputType.phone,
                  decoration: const InputDecoration(labelText: 'Phone Number', prefixIcon: Icon(Icons.phone)),
                ),
                const SizedBox(height: 8),
                TextField(
                  controller: addressController,
                  decoration: const InputDecoration(labelText: 'Address', prefixIcon: Icon(Icons.location_on)),
                ),
                const SizedBox(height: 8),
                Row(
                  children: [
                    Expanded(
                      child: TextField(
                        controller: gstController,
                        decoration: const InputDecoration(labelText: 'GSTIN', prefixIcon: Icon(Icons.verified)),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: TextField(
                        controller: stateCodeController,
                        decoration: const InputDecoration(labelText: 'State Code', prefixIcon: Icon(Icons.map)),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
          actions: [
            TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Cancel')),
            ElevatedButton(
              onPressed: () async {
                if (nameController.text.trim().isEmpty) return;

                final newCust = Customer(
                  name: nameController.text.trim(),
                  phone: phoneController.text.trim(),
                  address: addressController.text.trim(),
                  gstNumber: gstController.text.trim(),
                  stateCode: stateCodeController.text.trim(),
                );

                final custProvider = Provider.of<CustomerProvider>(context, listen: false);
                await custProvider.addCustomer(newCust);

                // Auto-select the newly added customer
                if (custProvider.customers.isNotEmpty) {
                  final added = custProvider.customers.last;
                  if (context.mounted) {
                    Provider.of<InvoiceProvider>(context, listen: false).setSelectedCustomer(added);
                  }
                }

                if (ctx.mounted) Navigator.pop(ctx);
              },
              child: const Text('Add & Select'),
            ),
          ],
        );
      },
    );
  }

  void _showQuickAddProductDialog(BuildContext context, {required VoidCallback onAdded}) {
    final nameController = TextEditingController();
    final priceController = TextEditingController();
    final hsnController = TextEditingController();
    String selectedUnit = 'Pcs';
    double selectedGst = 18.0;

    showDialog(
      context: context,
      builder: (ctx) {
        return StatefulBuilder(
          builder: (context, setDialogState) {
            return AlertDialog(
              title: const Text('Add New Product / Item'),
              content: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    TextField(
                      controller: nameController,
                      decoration: const InputDecoration(labelText: 'Product / Item Name *', prefixIcon: Icon(Icons.inventory_2)),
                    ),
                    const SizedBox(height: 8),
                    Row(
                      children: [
                        Expanded(
                          child: TextField(
                            controller: priceController,
                            keyboardType: const TextInputType.numberWithOptions(decimal: true),
                            decoration: const InputDecoration(labelText: 'Price / Rate (₹) *', prefixIcon: Icon(Icons.currency_rupee)),
                          ),
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: DropdownButtonFormField<String>(
                            value: selectedUnit,
                            decoration: const InputDecoration(labelText: 'Unit'),
                            items: _availableUnits.map((u) => DropdownMenuItem(value: u, child: Text(u))).toList(),
                            onChanged: (v) {
                              if (v != null) setDialogState(() => selectedUnit = v);
                            },
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    Row(
                      children: [
                        Expanded(
                          child: TextField(
                            controller: hsnController,
                            decoration: const InputDecoration(labelText: 'HSN Code', prefixIcon: Icon(Icons.code)),
                          ),
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: DropdownButtonFormField<double>(
                            value: selectedGst,
                            decoration: const InputDecoration(labelText: 'GST Rate'),
                            items: [0.0, 5.0, 12.0, 18.0, 28.0]
                                .map((g) => DropdownMenuItem(value: g, child: Text('${g.toStringAsFixed(0)}%')))
                                .toList(),
                            onChanged: (v) {
                              if (v != null) setDialogState(() => selectedGst = v);
                            },
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              actions: [
                TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Cancel')),
                ElevatedButton(
                  onPressed: () async {
                    if (nameController.text.trim().isEmpty) return;
                    final price = double.tryParse(priceController.text.trim()) ?? 0.0;

                    final newProduct = Product(
                      name: nameController.text.trim(),
                      price: price,
                      unit: selectedUnit,
                      hsnCode: hsnController.text.trim(),
                      gstRate: selectedGst,
                    );

                    final prodProvider = Provider.of<ProductProvider>(context, listen: false);
                    await prodProvider.addProduct(newProduct);

                    // Add directly to draft
                    if (context.mounted) {
                      Provider.of<InvoiceProvider>(context, listen: false).addProductToDraft(newProduct);
                    }

                    if (ctx.mounted) {
                      Navigator.pop(ctx); // Close add product dialog
                      onAdded();          // Close picker dialog
                    }
                  },
                  child: const Text('Save & Add to Invoice'),
                ),
              ],
            );
          },
        );
      },
    );
  }

  void _showProductPickerDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (ctx) {
        return Consumer<ProductProvider>(
          builder: (context, prodProvider, child) {
            final products = prodProvider.products;
            return AlertDialog(
              title: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text('Select Product'),
                  TextButton.icon(
                    onPressed: () => _showQuickAddProductDialog(context, onAdded: () {
                      if (ctx.mounted) Navigator.pop(ctx);
                    }),
                    icon: const Icon(Icons.add_circle, size: 18),
                    label: const Text('+ New Item'),
                  ),
                ],
              ),
              content: SizedBox(
                width: double.maxFinite,
                height: 400,
                child: Column(
                  children: [
                    TextField(
                      decoration: InputDecoration(
                        hintText: 'Search product...',
                        prefixIcon: const Icon(Icons.search),
                        border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
                      ),
                      onChanged: (v) => prodProvider.setSearchQuery(v),
                    ),
                    const SizedBox(height: 12),
                    Expanded(
                      child: products.isEmpty
                          ? Center(
                              child: Column(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  const Text('No products found.'),
                                  const SizedBox(height: 8),
                                  ElevatedButton.icon(
                                    onPressed: () => _showQuickAddProductDialog(context, onAdded: () {
                                      if (ctx.mounted) Navigator.pop(ctx);
                                    }),
                                    icon: const Icon(Icons.add),
                                    label: const Text('Create New Product'),
                                  ),
                                ],
                              ),
                            )
                          : ListView.builder(
                              itemCount: products.length,
                              itemBuilder: (context, index) {
                                final prod = products[index];
                                return ListTile(
                                  title: Text(prod.name ?? 'Unnamed Product', style: const TextStyle(fontWeight: FontWeight.bold)),
                                  subtitle: Text('HSN: ${prod.hsnCode ?? "-"} | Rate: ₹${prod.price?.toStringAsFixed(2) ?? "0.00"} / ${prod.unit ?? "Pcs"}'),
                                  trailing: const Icon(Icons.add_circle_outline, color: Colors.blue),
                                  onTap: () {
                                    Provider.of<InvoiceProvider>(context, listen: false).addProductToDraft(prod);
                                    Navigator.pop(ctx);
                                  },
                                );
                              },
                            ),
                    ),
                  ],
                ),
              ),
              actions: [
                TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Close')),
              ],
            );
          },
        );
      },
    );
  }

  void _showEditItemDialog(BuildContext context, int index, InvoiceItem item) {
    final nameController = TextEditingController(text: item.productName);
    final sizeController = TextEditingController(text: item.size ?? '');
    final qtyController = TextEditingController(text: item.quantity.toString());
    final priceController = TextEditingController(text: item.price.toString());
    String selectedUnit = _availableUnits.contains(item.unit) ? item.unit : 'Pcs';

    showDialog(
      context: context,
      builder: (ctx) {
        return StatefulBuilder(
          builder: (context, setDialogState) {
            return AlertDialog(
              title: const Text('Edit Invoice Item'),
              content: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    TextField(
                      controller: nameController,
                      decoration: const InputDecoration(labelText: 'Item Name *'),
                    ),
                    const SizedBox(height: 8),
                    TextField(
                      controller: sizeController,
                      decoration: const InputDecoration(labelText: 'Size (Optional, e.g. M, 10x12)'),
                    ),
                    const SizedBox(height: 8),
                    Row(
                      children: [
                        Expanded(
                          child: TextField(
                            controller: qtyController,
                            keyboardType: TextInputType.number,
                            decoration: const InputDecoration(labelText: 'Quantity *'),
                          ),
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: DropdownButtonFormField<String>(
                            value: selectedUnit,
                            decoration: const InputDecoration(labelText: 'Unit (Pcs/Nag/Bdl)'),
                            items: _availableUnits
                                .map((u) => DropdownMenuItem(value: u, child: Text(u)))
                                .toList(),
                            onChanged: (v) {
                              if (v != null) setDialogState(() => selectedUnit = v);
                            },
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    TextField(
                      controller: priceController,
                      keyboardType: const TextInputType.numberWithOptions(decimal: true),
                      decoration: const InputDecoration(labelText: 'Rate / Price per Unit (₹) *'),
                    ),
                  ],
                ),
              ),
              actions: [
                TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Cancel')),
                ElevatedButton(
                  onPressed: () {
                    final qty = int.tryParse(qtyController.text.trim()) ?? 1;
                    final price = double.tryParse(priceController.text.trim()) ?? item.price;
                    final pcsFormatted = "$qty $selectedUnit";

                    final updatedItem = item.copyWith(
                      productName: nameController.text.trim().isEmpty ? item.productName : nameController.text.trim(),
                      size: sizeController.text.trim().isEmpty ? null : sizeController.text.trim(),
                      pcsCount: pcsFormatted,
                      quantity: qty > 0 ? qty : 1,
                      unit: selectedUnit,
                      price: price,
                      amount: (qty > 0 ? qty : 1) * price,
                    );

                    Provider.of<InvoiceProvider>(context, listen: false).updateDraftItem(index, updatedItem);
                    Navigator.pop(ctx);
                  },
                  child: const Text('Save Changes'),
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
    final company = Provider.of<CompanyProvider>(context).company;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Create New Invoice'),
      ),
      body: Consumer<InvoiceProvider>(
        builder: (context, invProvider, child) {
          final totals = invProvider.calculateCurrentTotals(company);
          final amountInWords = NumberToWords.convert(totals.grandTotal);

          return SingleChildScrollView(
            padding: const EdgeInsets.fromLTRB(16, 16, 16, 88),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // 1. INVOICE TYPE SELECTOR (TAX INVOICE vs PROFORMA INVOICE)
                SizedBox(
                  width: double.infinity,
                  child: SegmentedButton<String>(
                    segments: const [
                      ButtonSegment(value: 'TAX INVOICE', label: Text('Tax Invoice'), icon: Icon(Icons.receipt_long)),
                      ButtonSegment(value: 'PROFORMA INVOICE', label: Text('Proforma Invoice'), icon: Icon(Icons.description_outlined)),
                    ],
                    selected: {invProvider.invoiceType},
                    onSelectionChanged: (Set<String> selection) {
                      invProvider.setInvoiceType(selection.first);
                    },
                  ),
                ),
                const SizedBox(height: 16),

                // 2. HEADER META CARD (WITH EDITABLE INVOICE NUMBER, DATES & TRANSPORT)
                Card(
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  child: Padding(
                    padding: const EdgeInsets.all(16.0),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // Editable Invoice Number Row
                        Row(
                          children: [
                            Expanded(
                              child: TextFormField(
                                controller: _invoiceNumberController,
                                decoration: InputDecoration(
                                  labelText: 'Invoice Number',
                                  prefixIcon: const Icon(Icons.tag_rounded),
                                  border: const OutlineInputBorder(),
                                  suffixIcon: IconButton(
                                    icon: const Icon(Icons.refresh, size: 20),
                                    tooltip: 'Reset to Auto Next Number',
                                    onPressed: () async {
                                      await invProvider.resetToAutoInvoiceNumber();
                                      _invoiceNumberController.text = invProvider.nextInvoiceNumber;
                                    },
                                  ),
                                ),
                                onChanged: (v) => invProvider.setInvoiceNumber(v),
                              ),
                            ),
                            const SizedBox(width: 12),
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 16),
                              decoration: BoxDecoration(
                                color: Theme.of(context).colorScheme.primaryContainer.withOpacity(0.5),
                                borderRadius: BorderRadius.circular(8),
                                border: Border.all(color: Theme.of(context).colorScheme.primary.withOpacity(0.3)),
                              ),
                              child: Text(
                                invProvider.invoiceType,
                                style: TextStyle(
                                  fontSize: 12,
                                  fontWeight: FontWeight.bold,
                                  color: Theme.of(context).colorScheme.primary,
                                ),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 12),
                        Row(
                          children: [
                            Expanded(
                              child: TextField(
                                controller: _challanController,
                                decoration: const InputDecoration(
                                  labelText: 'Challan No. (Optional)',
                                  prefixIcon: Icon(Icons.numbers),
                                  border: OutlineInputBorder(),
                                ),
                                onChanged: (v) => invProvider.setChallanNumber(v),
                              ),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: InkWell(
                                onTap: () async {
                                  final picked = await showDatePicker(
                                    context: context,
                                    initialDate: invProvider.invoiceDate,
                                    firstDate: DateTime(2020),
                                    lastDate: DateTime(2035),
                                  );
                                  if (picked != null) invProvider.setInvoiceDate(picked);
                                },
                                child: InputDecorator(
                                  decoration: const InputDecoration(labelText: 'Invoice Date', prefixIcon: Icon(Icons.calendar_today), border: OutlineInputBorder()),
                                  child: Text("${invProvider.invoiceDate.day}/${invProvider.invoiceDate.month}/${invProvider.invoiceDate.year}"),
                                ),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 12),
                        Row(
                          children: [
                            Expanded(
                              child: InkWell(
                                onTap: () async {
                                  final picked = await showDatePicker(
                                    context: context,
                                    initialDate: invProvider.deliveryDate,
                                    firstDate: DateTime(2020),
                                    lastDate: DateTime(2035),
                                  );
                                  if (picked != null) invProvider.setDeliveryDate(picked);
                                },
                                child: InputDecorator(
                                  decoration: const InputDecoration(labelText: 'Delivery Date', prefixIcon: Icon(Icons.local_shipping_outlined), border: OutlineInputBorder()),
                                  child: Text("${invProvider.deliveryDate.day}/${invProvider.deliveryDate.month}/${invProvider.deliveryDate.year}"),
                                ),
                              ),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: InkWell(
                                onTap: () async {
                                  final picked = await showDatePicker(
                                    context: context,
                                    initialDate: invProvider.dueDate,
                                    firstDate: DateTime(2020),
                                    lastDate: DateTime(2035),
                                  );
                                  if (picked != null) invProvider.setDueDate(picked);
                                },
                                child: InputDecorator(
                                  decoration: const InputDecoration(labelText: 'Payment Due Date', prefixIcon: Icon(Icons.timer), border: OutlineInputBorder()),
                                  child: Text("${invProvider.dueDate.day}/${invProvider.dueDate.month}/${invProvider.dueDate.year}"),
                                ),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 12),
                        Row(
                          children: [
                            Expanded(
                              child: TextField(
                                controller: _vehicleController,
                                decoration: const InputDecoration(
                                  labelText: 'Vehicle / Lorry No. (Optional)',
                                  prefixIcon: Icon(Icons.directions_car),
                                  border: OutlineInputBorder(),
                                ),
                                onChanged: (v) => invProvider.setVehicleNumber(v),
                              ),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: TextField(
                                controller: _transportModeController,
                                decoration: const InputDecoration(
                                  labelText: 'Transport Mode (e.g. By Road)',
                                  prefixIcon: Icon(Icons.commute),
                                  border: OutlineInputBorder(),
                                ),
                                onChanged: (v) => invProvider.setTransportMode(v),
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 16),

                // 3. CUSTOMER SELECTOR CARD (WITH QUICK ADD BUTTON)
                Card(
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  child: Padding(
                    padding: const EdgeInsets.all(16.0),
                    child: Consumer<CustomerProvider>(
                      builder: (context, custProvider, child) {
                        final customers = custProvider.customers;
                        return Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Row(
                                  children: [
                                    Icon(Icons.person, color: Theme.of(context).colorScheme.primary),
                                    const SizedBox(width: 8),
                                    Text('Billed To Customer', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Theme.of(context).colorScheme.primary)),
                                  ],
                                ),
                                TextButton.icon(
                                  onPressed: () => _showQuickAddCustomerDialog(context),
                                  icon: const Icon(Icons.person_add_alt_1, size: 18),
                                  label: const Text('+ Add New'),
                                ),
                              ],
                            ),
                            const SizedBox(height: 8),
                            DropdownButtonFormField<Customer>(
                              value: invProvider.selectedCustomer,
                              decoration: const InputDecoration(labelText: 'Select Customer', border: OutlineInputBorder()),
                              items: customers
                                  .map((c) => DropdownMenuItem(value: c, child: Text(c.name ?? 'Unnamed Customer')))
                                  .toList(),
                              onChanged: (c) => invProvider.setSelectedCustomer(c),
                            ),
                            if (invProvider.selectedCustomer != null) ...[
                              const SizedBox(height: 12),
                              Container(
                                padding: const EdgeInsets.all(12),
                                decoration: BoxDecoration(
                                  color: Theme.of(context).colorScheme.surfaceVariant,
                                  borderRadius: BorderRadius.circular(8),
                                ),
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    if (invProvider.selectedCustomer!.address != null && invProvider.selectedCustomer!.address!.isNotEmpty)
                                      Text('Address: ${invProvider.selectedCustomer!.address}'),
                                    if (invProvider.selectedCustomer!.gstNumber != null && invProvider.selectedCustomer!.gstNumber!.isNotEmpty)
                                      Text('GSTIN: ${invProvider.selectedCustomer!.gstNumber}'),
                                    const SizedBox(height: 4),
                                    Container(
                                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                                      decoration: BoxDecoration(
                                        color: totals.isIntraState ? Colors.blue.shade100 : Colors.purple.shade100,
                                        borderRadius: BorderRadius.circular(6),
                                      ),
                                      child: Text(
                                        totals.isIntraState ? 'Taxation: Intra-State (CGST + SGST)' : 'Taxation: Inter-State (IGST)',
                                        style: TextStyle(
                                          fontSize: 11,
                                          fontWeight: FontWeight.bold,
                                          color: totals.isIntraState ? Colors.blue.shade900 : Colors.purple.shade900,
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ],
                        );
                      },
                    ),
                  ),
                ),
                const SizedBox(height: 16),

                // 4. LINE ITEMS SECTION
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text('Line Items', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Theme.of(context).colorScheme.primary)),
                    ElevatedButton.icon(
                      onPressed: () => _showProductPickerDialog(context),
                      icon: const Icon(Icons.add),
                      label: const Text('Add Item'),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                invProvider.draftItems.isEmpty
                    ? Container(
                        padding: const EdgeInsets.all(32),
                        alignment: Alignment.center,
                        decoration: BoxDecoration(
                          border: Border.all(color: Colors.grey.shade300),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: const Text('No line items added yet. Click "+ Add Item" above!'),
                      )
                    : ListView.builder(
                        shrinkWrap: true,
                        physics: const NeverScrollableScrollPhysics(),
                        itemCount: invProvider.draftItems.length,
                        itemBuilder: (context, index) {
                          final item = invProvider.draftItems[index];
                          final sizeText = (item.size != null && item.size!.isNotEmpty) ? " | Size: ${item.size}" : "";

                          return Card(
                            margin: const EdgeInsets.only(bottom: 8),
                            child: ListTile(
                              title: Text(
                                '${index + 1}. ${item.productName}$sizeText',
                                style: const TextStyle(fontWeight: FontWeight.bold),
                              ),
                              subtitle: Text(
                                'Qty: ${item.quantity} ${item.unit} x ₹${item.price.toStringAsFixed(2)} = ₹${item.amount.toStringAsFixed(2)}',
                                style: const TextStyle(fontWeight: FontWeight.w500),
                              ),
                              trailing: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  IconButton(
                                    icon: const Icon(Icons.edit, color: Colors.blue),
                                    onPressed: () => _showEditItemDialog(context, index, item),
                                  ),
                                  IconButton(
                                    icon: const Icon(Icons.delete, color: Colors.red),
                                    onPressed: () => invProvider.removeDraftItem(index),
                                  ),
                                ],
                              ),
                            ),
                          );
                        },
                      ),
                const SizedBox(height: 24),

                // 5. CALCULATIONS & PAYMENT STATUS CARD
                Card(
                  elevation: 2,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  child: Padding(
                    padding: const EdgeInsets.all(16.0),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text('Calculations & Payment Status', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Theme.of(context).colorScheme.primary)),
                        const SizedBox(height: 12),
                        _buildSummaryRow('Subtotal', '₹${totals.subtotal.toStringAsFixed(2)}'),
                        const SizedBox(height: 8),
                        Row(
                          children: [
                            const Expanded(child: Text('Transport / Loading Charges (₹)')),
                            SizedBox(
                              width: 120,
                              child: TextField(
                                controller: _transportController,
                                keyboardType: const TextInputType.numberWithOptions(decimal: true),
                                decoration: const InputDecoration(isDense: true, border: OutlineInputBorder()),
                                onChanged: (v) => invProvider.setTransportCharges(double.tryParse(v) ?? 0.0),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 8),
                        _buildSummaryRow('Total Taxable Base', '₹${totals.taxableBase.toStringAsFixed(2)}', isBold: true),
                        const Divider(height: 20),
                        Row(
                          children: [
                            const Text('GST Tax Rate: '),
                            const SizedBox(width: 8),
                            DropdownButton<double>(
                              value: invProvider.gstRate,
                              items: [0.0, 5.0, 12.0, 18.0, 28.0]
                                  .map((g) => DropdownMenuItem(value: g, child: Text('${g.toStringAsFixed(0)}%')))
                                  .toList(),
                              onChanged: (v) {
                                if (v != null) invProvider.setGstRate(v);
                              },
                            ),
                          ],
                        ),
                        if (totals.isIntraState) ...[
                          _buildSummaryRow('CGST (${(totals.gstRate / 2).toStringAsFixed(1)}%)', '+ ₹${totals.cgstTotal.toStringAsFixed(2)}'),
                          _buildSummaryRow('SGST (${(totals.gstRate / 2).toStringAsFixed(1)}%)', '+ ₹${totals.sgstTotal.toStringAsFixed(2)}'),
                        ] else ...[
                          _buildSummaryRow('IGST (${totals.gstRate.toStringAsFixed(1)}%)', '+ ₹${totals.igstTotal.toStringAsFixed(2)}'),
                        ],
                        const SizedBox(height: 8),
                        Row(
                          children: [
                            const Expanded(child: Text('Discount Amount (₹)')),
                            SizedBox(
                              width: 120,
                              child: TextField(
                                controller: _discountController,
                                keyboardType: const TextInputType.numberWithOptions(decimal: true),
                                decoration: const InputDecoration(isDense: true, border: OutlineInputBorder()),
                                onChanged: (v) => invProvider.setDiscountAmount(double.tryParse(v) ?? 0.0),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 8),
                        _buildSummaryRow('Round Off', '${totals.roundOff >= 0 ? "+" : ""}₹${totals.roundOff.toStringAsFixed(2)}'),
                        const Divider(height: 20),

                        // GRAND TOTAL BANNER
                        Container(
                          padding: const EdgeInsets.all(12),
                          decoration: BoxDecoration(
                            color: Theme.of(context).colorScheme.primary,
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              const Text('GRAND TOTAL', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 16)),
                              Text('₹${totals.grandTotal.toStringAsFixed(2)}', style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 18)),
                            ],
                          ),
                        ),
                        const SizedBox(height: 12),
                        Text(
                          'Amount in Words: $amountInWords',
                          style: TextStyle(fontSize: 12, fontStyle: FontStyle.italic, color: Theme.of(context).colorScheme.primary),
                        ),
                        const Divider(height: 24),

                        // PAYMENT STATUS SELECTOR (Unpaid, Paid, Partially Paid)
                        Text('Payment Status:', style: TextStyle(fontWeight: FontWeight.bold, color: Theme.of(context).colorScheme.primary)),
                        const SizedBox(height: 8),
                        SegmentedButton<String>(
                          segments: const [
                            ButtonSegment(value: 'Unpaid', label: Text('Unpaid'), icon: Icon(Icons.pending, color: Colors.red)),
                            ButtonSegment(value: 'Partially Paid', label: Text('Partially Paid'), icon: Icon(Icons.rule, color: Colors.orange)),
                            ButtonSegment(value: 'Paid', label: Text('Paid'), icon: Icon(Icons.check_circle, color: Colors.green)),
                          ],
                          selected: {invProvider.paymentStatus},
                          onSelectionChanged: (s) => invProvider.setPaymentStatus(s.first),
                        ),
                        if (invProvider.paymentStatus == 'Partially Paid') ...[
                          const SizedBox(height: 12),
                          Row(
                            children: [
                              const Expanded(child: Text('Received Amount (₹):', style: TextStyle(fontWeight: FontWeight.bold))),
                              SizedBox(
                                width: 140,
                                child: TextField(
                                  controller: _receivedController,
                                  keyboardType: const TextInputType.numberWithOptions(decimal: true),
                                  decoration: const InputDecoration(isDense: true, border: OutlineInputBorder(), prefixText: '₹'),
                                  onChanged: (v) => invProvider.setReceivedAmount(double.tryParse(v) ?? 0.0),
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 6),
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              const Text('Remaining Balance Due:'),
                              Text(
                                '₹${(totals.grandTotal - invProvider.receivedAmount).toStringAsFixed(2)}',
                                style: const TextStyle(fontWeight: FontWeight.bold, color: Colors.red),
                              ),
                            ],
                          ),
                        ],
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 24),

                // 6. SAVE BUTTON
                SizedBox(
                  width: double.infinity,
                  height: 50,
                  child: ElevatedButton.icon(
                    onPressed: invProvider.draftItems.isEmpty
                        ? null
                        : () async {
                            int savedId = await invProvider.saveDraftInvoice(company);
                            final savedInvoice = await DatabaseHelper.instance.getInvoiceById(savedId);
                            if (mounted) {
                              ScaffoldMessenger.of(context).showSnackBar(
                                const SnackBar(content: Text('Invoice saved successfully!'), backgroundColor: Colors.green),
                              );
                              if (savedInvoice != null) {
                                Navigator.pushReplacement(
                                  context,
                                  MaterialPageRoute(
                                    builder: (_) => PdfPreviewScreen(invoice: savedInvoice),
                                  ),
                                );
                              } else {
                                Navigator.pop(context);
                              }
                            }
                          },
                    icon: const Icon(Icons.check_circle),
                    label: const Text('Save & Preview PDF Invoice', style: TextStyle(fontSize: 16)),
                  ),
                ),
                const SizedBox(height: 40),
              ],
            ),
          );
        },
      ),
    );
  }

  Widget _buildSummaryRow(String label, String value, {bool isBold = false}) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(label, style: TextStyle(fontWeight: isBold ? FontWeight.bold : FontWeight.normal)),
        Text(value, style: TextStyle(fontWeight: isBold ? FontWeight.bold : FontWeight.normal)),
      ],
    );
  }
}
