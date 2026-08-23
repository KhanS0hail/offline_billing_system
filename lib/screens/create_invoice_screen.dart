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
  late TextEditingController _poNumberController;
  late TextEditingController _challanController;
  late TextEditingController _vehicleController;
  late TextEditingController _transportModeController;
  late TextEditingController _loadingController;
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
    _poNumberController = TextEditingController(text: invProvider.poNumber ?? '');
    _challanController = TextEditingController(text: invProvider.challanNumber ?? '');
    _vehicleController = TextEditingController(text: invProvider.vehicleNumber);
    _transportModeController = TextEditingController(text: invProvider.transportMode);
    _loadingController = TextEditingController(text: invProvider.loadingCharges == 0 ? '' : invProvider.loadingCharges.toString());
    _transportController = TextEditingController(text: invProvider.transportCharges == 0 ? '' : invProvider.transportCharges.toString());
    _discountController = TextEditingController(text: invProvider.discountAmount == 0 ? '' : invProvider.discountAmount.toString());
    _receivedController = TextEditingController(text: invProvider.receivedAmount == 0 ? '' : invProvider.receivedAmount.toString());
    _notesController = TextEditingController(text: invProvider.notes);
  }

  @override
  void dispose() {
    _invoiceNumberController.dispose();
    _poNumberController.dispose();
    _challanController.dispose();
    _vehicleController.dispose();
    _transportModeController.dispose();
    _loadingController.dispose();
    _transportController.dispose();
    _discountController.dispose();
    _receivedController.dispose();
    _notesController.dispose();
    super.dispose();
  }

  void _showQuickAddCustomerDialog(BuildContext context) {
    final formKey = GlobalKey<FormState>();
    final nameController = TextEditingController();
    final phoneController = TextEditingController();
    final addressController = TextEditingController();
    final gstController = TextEditingController();
    final stateCodeController = TextEditingController();

    showDialog(
      context: context,
      builder: (ctx) {
        return StatefulBuilder(
          builder: (context, setDialogState) {
            return AlertDialog(
              title: const Text('Add New Customer'),
              content: SingleChildScrollView(
                child: Form(
                  key: formKey,
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      TextFormField(
                        controller: nameController,
                        validator: (v) => (v == null || v.trim().isEmpty) ? 'Customer name is required' : null,
                        decoration: const InputDecoration(labelText: 'Customer / Business Name *', prefixIcon: Icon(Icons.person)),
                      ),
                      const SizedBox(height: 8),
                      TextFormField(
                        controller: addressController,
                        validator: (v) => (v == null || v.trim().isEmpty) ? 'Full Address is required' : null,
                        decoration: const InputDecoration(labelText: 'Address *', prefixIcon: Icon(Icons.location_on)),
                      ),
                      const SizedBox(height: 8),
                      Row(
                        children: [
                          Expanded(
                            child: TextFormField(
                              controller: gstController,
                              validator: (v) {
                                if (v == null || v.trim().isEmpty) return 'GSTIN is required';
                                final clean = v.trim().toUpperCase();
                                final gstRegex = RegExp(r'^[0-9]{2}[A-Z]{5}[0-9]{4}[A-Z]{1}[1-9A-Z]{1}Z[0-9A-Z]{1}$');
                                if (!gstRegex.hasMatch(clean)) {
                                  return 'Enter valid 15-digit GSTIN';
                                }
                                return null;
                              },
                              onChanged: (v) {
                                final clean = v.trim().toUpperCase();
                                if (clean.length >= 2) {
                                  final prefix = clean.substring(0, 2);
                                  final codeNum = int.tryParse(prefix);
                                  if (codeNum != null && ((codeNum >= 1 && codeNum <= 37) || codeNum == 97)) {
                                    if (stateCodeController.text.trim() != prefix) {
                                      setDialogState(() {
                                        stateCodeController.text = prefix;
                                      });
                                    }
                                  }
                                }
                              },
                              decoration: const InputDecoration(labelText: 'GSTIN *', prefixIcon: Icon(Icons.verified)),
                            ),
                          ),
                          const SizedBox(width: 8),
                          Expanded(
                            child: TextFormField(
                              controller: stateCodeController,
                              keyboardType: TextInputType.number,
                              validator: (v) {
                                if (v == null || v.trim().isEmpty) return 'State code is required';
                                final code = int.tryParse(v.trim());
                                if (code == null || (code < 1 || (code > 37 && code != 97))) {
                                  return 'State Code (01-37)';
                                }
                                return null;
                              },
                              decoration: const InputDecoration(labelText: 'State Code *', prefixIcon: Icon(Icons.map)),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 8),
                      TextFormField(
                        controller: phoneController,
                        keyboardType: TextInputType.phone,
                        validator: (v) {
                          if (v != null && v.trim().isNotEmpty) {
                            final clean = v.trim().replaceAll(RegExp(r'[\s\-\+\(\)]'), '');
                            if (clean.length < 10 || clean.length > 12 || int.tryParse(clean) == null) {
                              return 'Enter valid 10-digit phone number';
                            }
                          }
                          return null;
                        },
                        decoration: const InputDecoration(labelText: 'Phone Number (Optional)', prefixIcon: Icon(Icons.phone)),
                      ),
                    ],
                  ),
                ),
              ),
              actions: [
                TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Cancel')),
                ElevatedButton(
                  onPressed: () async {
                    if (formKey.currentState!.validate()) {
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
                    }
                  },
                  child: const Text('Add Customer'),
                ),
              ],
            );
          },
        );
      },
    );
  }

  void _showQuickAddProductDialog(BuildContext context, {required VoidCallback onAdded}) {
    final formKey = GlobalKey<FormState>();
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
                child: Form(
                  key: formKey,
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      TextFormField(
                        controller: nameController,
                        validator: (v) => (v == null || v.trim().isEmpty) ? 'Product name is required' : null,
                        decoration: const InputDecoration(labelText: 'Product / Item Name *', prefixIcon: Icon(Icons.inventory_2)),
                      ),
                      const SizedBox(height: 8),
                      TextFormField(
                        controller: hsnController,
                        validator: (v) => (v == null || v.trim().isEmpty) ? 'HSN code is required' : null,
                        decoration: const InputDecoration(labelText: 'HSN / SAC Code *', prefixIcon: Icon(Icons.code)),
                      ),
                      const SizedBox(height: 8),
                      Row(
                        children: [
                          Expanded(
                            child: TextFormField(
                              controller: priceController,
                              keyboardType: const TextInputType.numberWithOptions(decimal: true),
                              validator: (v) {
                                if (v == null || v.trim().isEmpty) return 'Price is required';
                                final p = double.tryParse(v.trim());
                                if (p == null || p < 0) return 'Enter valid price';
                                return null;
                              },
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
                      DropdownButtonFormField<double>(
                        value: selectedGst,
                        decoration: const InputDecoration(labelText: 'GST Rate'),
                        items: [0.0, 5.0, 12.0, 18.0, 28.0]
                            .map((g) => DropdownMenuItem(value: g, child: Text('${g.toStringAsFixed(0)}%')))
                            .toList(),
                        onChanged: (v) {
                          if (v != null) setDialogState(() => selectedGst = v);
                        },
                      ),
                    ],
                  ),
                ),
              ),
              actions: [
                TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Cancel')),
                ElevatedButton(
                  onPressed: () async {
                    if (formKey.currentState!.validate()) {
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

  void _showCustomerPickerDialog(BuildContext context) {
    Provider.of<CustomerProvider>(context, listen: false).setSearchQuery('');
    showDialog(
      context: context,
      builder: (ctx) {
        return Consumer<CustomerProvider>(
          builder: (context, custProvider, child) {
            final customers = custProvider.customers;
            return AlertDialog(
              title: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text('Select Customer'),
                  TextButton.icon(
                    onPressed: () => _showQuickAddCustomerDialog(context),
                    icon: const Icon(Icons.person_add_alt_1, size: 18),
                    label: const Text('+ New Customer'),
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
                        hintText: 'Search customer name, GSTIN, phone...',
                        prefixIcon: const Icon(Icons.search),
                        border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
                      ),
                      onChanged: (v) => custProvider.setSearchQuery(v),
                    ),
                    const SizedBox(height: 12),
                    Expanded(
                      child: customers.isEmpty
                          ? Center(
                              child: Column(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  const Text('No customers found.'),
                                  const SizedBox(height: 8),
                                  ElevatedButton.icon(
                                    onPressed: () => _showQuickAddCustomerDialog(context),
                                    icon: const Icon(Icons.person_add_alt_1),
                                    label: const Text('Add New Customer'),
                                  ),
                                ],
                              ),
                            )
                          : ListView.builder(
                              itemCount: customers.length,
                              itemBuilder: (context, index) {
                                final cust = customers[index];
                                final gstin = (cust.gstNumber != null && cust.gstNumber!.isNotEmpty) ? cust.gstNumber! : 'No GSTIN';
                                final state = (cust.stateCode != null && cust.stateCode!.isNotEmpty) ? 'State: ${cust.stateCode}' : '';
                                return ListTile(
                                  leading: CircleAvatar(
                                    backgroundColor: Theme.of(context).colorScheme.primaryContainer,
                                    child: Text(cust.name?.isNotEmpty == true ? cust.name![0].toUpperCase() : 'C'),
                                  ),
                                  title: Text(cust.name ?? 'Unnamed Customer', style: const TextStyle(fontWeight: FontWeight.bold)),
                                  subtitle: Text('GSTIN: $gstin | $state\n${cust.address ?? ""}'),
                                  isThreeLine: cust.address != null && cust.address!.isNotEmpty,
                                  onTap: () {
                                    Provider.of<InvoiceProvider>(context, listen: false).setSelectedCustomer(cust);
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
    final formKey = GlobalKey<FormState>();
    final nameController = TextEditingController(text: item.productName);
    final hsnController = TextEditingController(text: item.hsnCode ?? '');
    final sizeController = TextEditingController(text: item.size ?? '');

    // Parse existing PCS count into number + unit
    String initialPcsNum = '';
    String selectedPcsUnit = 'Pcs';
    final pcsUnitsList = ['Pcs', 'Nag', 'Bdl', 'Box', 'Bundle', 'Roll', 'Carton'];
    if (item.pcsCount != null && item.pcsCount!.trim().isNotEmpty) {
      final match = RegExp(r'^([\d.]+)\s*(.*)$').firstMatch(item.pcsCount!.trim());
      if (match != null) {
        initialPcsNum = match.group(1) ?? '';
        final u = match.group(2)?.trim() ?? 'Pcs';
        if (pcsUnitsList.contains(u)) {
          selectedPcsUnit = u;
        }
      } else {
        initialPcsNum = item.pcsCount!.trim();
      }
    }

    final pcsNumController = TextEditingController(text: initialPcsNum);
    final qtyController = TextEditingController(text: item.quantity.toString());
    final priceController = TextEditingController(text: item.price.toString());
    String selectedBillingUnit = _availableUnits.contains(item.unit) ? item.unit : 'Pcs';

    showDialog(
      context: context,
      builder: (ctx) {
        return StatefulBuilder(
          builder: (context, setDialogState) {
            return AlertDialog(
              title: const Text('Edit Invoice Item'),
              content: SingleChildScrollView(
                child: Form(
                  key: formKey,
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      TextFormField(
                        controller: nameController,
                        validator: (v) => (v == null || v.trim().isEmpty) ? 'Item name is required' : null,
                        decoration: const InputDecoration(labelText: 'Item Name *', prefixIcon: Icon(Icons.inventory)),
                      ),
                      const SizedBox(height: 8),
                      TextFormField(
                        controller: hsnController,
                        keyboardType: TextInputType.number,
                        validator: (v) {
                          if (v == null || v.trim().isEmpty) return 'HSN code is required';
                          final clean = v.trim();
                          if (!RegExp(r'^\d{2,8}$').hasMatch(clean)) {
                            return 'Enter 2-8 digit HSN code';
                          }
                          return null;
                        },
                        decoration: const InputDecoration(labelText: 'HSN / SAC Code *', prefixIcon: Icon(Icons.code)),
                      ),
                      const SizedBox(height: 8),
                      TextFormField(
                        controller: sizeController,
                        decoration: const InputDecoration(labelText: 'Size (Optional, e.g. M, 10x12)', prefixIcon: Icon(Icons.straighten)),
                      ),
                      const SizedBox(height: 12),

                      // 1. PCS / Packaging Column (Number + Unit Selector)
                      Row(
                        children: [
                          Expanded(
                            flex: 5,
                            child: TextFormField(
                              controller: pcsNumController,
                              keyboardType: const TextInputType.numberWithOptions(decimal: true),
                              decoration: const InputDecoration(
                                labelText: 'PCS Count (Optional)',
                                hintText: 'e.g. 10',
                                border: OutlineInputBorder(),
                              ),
                            ),
                          ),
                          const SizedBox(width: 8),
                          Expanded(
                            flex: 4,
                            child: DropdownButtonFormField<String>(
                              value: selectedPcsUnit,
                              decoration: const InputDecoration(
                                labelText: 'PCS Unit',
                                border: OutlineInputBorder(),
                              ),
                              items: pcsUnitsList
                                  .map((u) => DropdownMenuItem(value: u, child: Text(u)))
                                  .toList(),
                              onChanged: (v) {
                                if (v != null) setDialogState(() => selectedPcsUnit = v);
                              },
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 12),

                      // 2. Billing Quantity & Unit Column (Number + Unit Selector)
                      Row(
                        children: [
                          Expanded(
                            flex: 5,
                            child: TextFormField(
                              controller: qtyController,
                              keyboardType: TextInputType.number,
                              validator: (v) {
                                if (v == null || v.trim().isEmpty) return 'Qty required';
                                final q = int.tryParse(v.trim());
                                if (q == null || q <= 0) return 'Must be > 0';
                                return null;
                              },
                              decoration: const InputDecoration(
                                labelText: 'Billed Qty *',
                                hintText: 'e.g. 100',
                                border: OutlineInputBorder(),
                              ),
                            ),
                          ),
                          const SizedBox(width: 8),
                          Expanded(
                            flex: 4,
                            child: DropdownButtonFormField<String>(
                              value: selectedBillingUnit,
                              decoration: const InputDecoration(
                                labelText: 'Billing Unit *',
                                border: OutlineInputBorder(),
                              ),
                              items: _availableUnits
                                  .map((u) => DropdownMenuItem(value: u, child: Text(u)))
                                  .toList(),
                              onChanged: (v) {
                                if (v != null) setDialogState(() => selectedBillingUnit = v);
                              },
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 12),
                      TextFormField(
                        controller: priceController,
                        keyboardType: const TextInputType.numberWithOptions(decimal: true),
                        validator: (v) {
                          if (v == null || v.trim().isEmpty) return 'Rate is required';
                          final p = double.tryParse(v.trim());
                          if (p == null || p < 0) return 'Must be >= 0';
                          return null;
                        },
                        decoration: const InputDecoration(
                          labelText: 'Rate / Price per Unit (₹) *',
                          prefixIcon: Icon(Icons.currency_rupee),
                          border: OutlineInputBorder(),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              actions: [
                TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Cancel')),
                ElevatedButton(
                  onPressed: () {
                    if (formKey.currentState!.validate()) {
                      final qty = int.tryParse(qtyController.text.trim()) ?? 1;
                      final price = double.tryParse(priceController.text.trim()) ?? item.price;

                      final rawPcsNum = pcsNumController.text.trim();
                      final formattedPcs = rawPcsNum.isNotEmpty ? "$rawPcsNum $selectedPcsUnit" : null;

                      final updatedItem = item.copyWith(
                        productName: nameController.text.trim(),
                        hsnCode: hsnController.text.trim(),
                        size: sizeController.text.trim().isEmpty ? null : sizeController.text.trim(),
                        pcsCount: formattedPcs,
                        quantity: qty > 0 ? qty : 1,
                        unit: selectedBillingUnit,
                        price: price,
                        amount: (qty > 0 ? qty : 1) * price,
                      );

                      Provider.of<InvoiceProvider>(context, listen: false).updateDraftItem(index, updatedItem);
                      Navigator.pop(ctx);
                    }
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
                              child: TextFormField(
                                controller: _poNumberController,
                                decoration: const InputDecoration(
                                  labelText: 'P.O. Number (Optional)',
                                  prefixIcon: Icon(Icons.assignment_turned_in_outlined),
                                  border: OutlineInputBorder(),
                                ),
                                onChanged: (v) => invProvider.setPoNumber(v),
                              ),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: TextField(
                                controller: _challanController,
                                decoration: const InputDecoration(
                                  labelText: 'Challan Number *',
                                  prefixIcon: Icon(Icons.numbers),
                                  border: OutlineInputBorder(),
                                ),
                                onChanged: (v) => invProvider.setChallanNumber(v),
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
                            InkWell(
                              onTap: () => _showCustomerPickerDialog(context),
                              child: InputDecorator(
                                decoration: const InputDecoration(
                                  labelText: 'Customer / Billed Company *',
                                  prefixIcon: Icon(Icons.business_rounded),
                                  suffixIcon: Icon(Icons.search),
                                  border: OutlineInputBorder(),
                                ),
                                child: Text(
                                  invProvider.selectedCustomer?.name ?? 'Tap to Search & Select Customer...',
                                  style: TextStyle(
                                    fontWeight: invProvider.selectedCustomer != null ? FontWeight.bold : FontWeight.normal,
                                    color: invProvider.selectedCustomer != null ? null : Colors.grey.shade600,
                                  ),
                                ),
                              ),
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

                // 4. INLINE EDITABLE ITEM DETAILS TABLE
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
                            Row(
                              children: [
                                Icon(Icons.inventory_2_rounded, color: Theme.of(context).colorScheme.primary),
                                const SizedBox(width: 8),
                                Text(
                                  'Item Details',
                                  style: TextStyle(fontSize: 17, fontWeight: FontWeight.bold, color: Theme.of(context).colorScheme.primary),
                                ),
                                const SizedBox(width: 8),
                                Chip(
                                  label: Text('${invProvider.draftItems.length} Items'),
                                  backgroundColor: Theme.of(context).colorScheme.primaryContainer,
                                  labelStyle: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: Theme.of(context).colorScheme.primary),
                                  visualDensity: VisualDensity.compact,
                                ),
                              ],
                            ),
                            ElevatedButton.icon(
                              onPressed: () {
                                final newItem = InvoiceItem(
                                  productName: '',
                                  hsnCode: '7304',
                                  quantity: 1,
                                  unit: 'Pcs',
                                  price: 0.0,
                                );
                                invProvider.addDraftItem(newItem);
                              },
                              icon: const Icon(Icons.add, size: 18),
                              label: const Text('Add Row'),
                            ),
                          ],
                        ),
                        const SizedBox(height: 12),

                        if (invProvider.draftItems.isEmpty)
                          Container(
                            padding: const EdgeInsets.all(36),
                            alignment: Alignment.center,
                            decoration: BoxDecoration(
                              color: Colors.grey.shade50,
                              border: Border.all(color: Colors.grey.shade300),
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: const Column(
                              children: [
                                Icon(Icons.post_add_rounded, size: 44, color: Colors.grey),
                                SizedBox(height: 8),
                                Text(
                                  'No line items added yet.',
                                  style: TextStyle(fontWeight: FontWeight.bold, color: Colors.grey),
                                ),
                                SizedBox(height: 4),
                                Text(
                                  'Click "+ Add Row" above to add line items!',
                                  style: TextStyle(fontSize: 12, color: Colors.grey),
                                ),
                              ],
                            ),
                          )
                        else
                          LayoutBuilder(
                            builder: (context, constraints) {
                              final parentWidth = constraints.maxWidth;
                              const double baseTotal = 856.0;
                              final double actualWidth = parentWidth > baseTotal ? parentWidth : baseTotal;
                              final double extra = actualWidth > baseTotal ? (actualWidth - baseTotal) : 0.0;

                              final double nameW = 160 + (extra * 0.35);
                              final double sizeW = 95 + (extra * 0.20);
                              final double hsnW = 85 + (extra * 0.15);
                              final double rateW = 90 + (extra * 0.15);
                              final double amountW = 100 + (extra * 0.15);

                              return SingleChildScrollView(
                                scrollDirection: Axis.horizontal,
                                child: SizedBox(
                                  width: actualWidth,
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      // Table Header Bar
                                      Container(
                                        padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 8),
                                        decoration: BoxDecoration(
                                          color: Theme.of(context).colorScheme.primary,
                                          borderRadius: BorderRadius.circular(6),
                                        ),
                                        child: Row(
                                          children: [
                                            const SizedBox(width: 28, child: Text('#', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 12), textAlign: TextAlign.center)),
                                            const SizedBox(width: 6),
                                            SizedBox(width: nameW, child: const Text('Item Name *', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 12))),
                                            const SizedBox(width: 6),
                                            SizedBox(width: hsnW, child: const Text('HSN *', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 12))),
                                            const SizedBox(width: 6),
                                            SizedBox(width: sizeW, child: const Text('Size', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 12))),
                                            const SizedBox(width: 6),
                                            const SizedBox(width: 70, child: Text('PCS Count', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 12), textAlign: TextAlign.center)),
                                            const SizedBox(width: 6),
                                            const SizedBox(width: 75, child: Text('PCS Unit', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 12))),
                                            const SizedBox(width: 6),
                                            const SizedBox(width: 75, child: Text('Billed Qty *', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 12), textAlign: TextAlign.center)),
                                            const SizedBox(width: 6),
                                            const SizedBox(width: 85, child: Text('Billing Unit *', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 12))),
                                            const SizedBox(width: 6),
                                            SizedBox(width: rateW, child: const Text('Rate (₹) *', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 12), textAlign: TextAlign.right)),
                                            const SizedBox(width: 6),
                                            SizedBox(width: amountW, child: const Text('Taxable Value (₹)', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 12), textAlign: TextAlign.right)),
                                            const SizedBox(width: 6),
                                            const SizedBox(width: 36, child: Text('', style: TextStyle(color: Colors.white))),
                                          ],
                                        ),
                                      ),
                                      const SizedBox(height: 6),

                                      // Table Rows
                                      ...List.generate(invProvider.draftItems.length, (index) {
                                        final item = invProvider.draftItems[index];
                                        return _InlineInvoiceItemRow(
                                          key: ValueKey('inline_item_row_$index'),
                                          index: index,
                                          item: item,
                                          nameWidth: nameW,
                                          sizeWidth: sizeW,
                                          hsnWidth: hsnW,
                                          rateWidth: rateW,
                                          amountWidth: amountW,
                                          availableUnits: _availableUnits,
                                          onChanged: (updated) {
                                            invProvider.updateDraftItem(index, updated);
                                          },
                                          onDelete: () {
                                            invProvider.removeDraftItem(index);
                                          },
                                        );
                                      }),
                                    ],
                                  ),
                                ),
                              );
                            },
                          ),
                      ],
                    ),
                  ),
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
                            const Expanded(child: Text('Loading / Packing Charges (₹)')),
                            SizedBox(
                              width: 120,
                              child: TextField(
                                controller: _loadingController,
                                keyboardType: const TextInputType.numberWithOptions(decimal: true),
                                decoration: const InputDecoration(isDense: true, border: OutlineInputBorder(), hintText: '0.00'),
                                onChanged: (v) => invProvider.setLoadingCharges(double.tryParse(v) ?? 0.0),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 8),
                        Row(
                          children: [
                            const Expanded(child: Text('Transport / Freight Charges (₹)')),
                            SizedBox(
                              width: 120,
                              child: TextField(
                                controller: _transportController,
                                keyboardType: const TextInputType.numberWithOptions(decimal: true),
                                decoration: const InputDecoration(isDense: true, border: OutlineInputBorder(), hintText: '0.00'),
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
                    onPressed: () async {
                      if (invProvider.selectedCustomer == null) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(content: Text('Please select a customer for this invoice.'), backgroundColor: Colors.red),
                        );
                        return;
                      }
                      if (_challanController.text.trim().isEmpty) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(content: Text('Challan number is required.'), backgroundColor: Colors.red),
                        );
                        return;
                      }
                      if (invProvider.draftItems.isEmpty) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(content: Text('Please add at least 1 line item.'), backgroundColor: Colors.red),
                        );
                        return;
                      }
                      if (invProvider.paymentStatus == 'Partially Paid' &&
                          (invProvider.receivedAmount <= 0 || invProvider.receivedAmount >= totals.grandTotal)) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(content: Text('Please enter a valid partial received amount (greater than 0 and less than Grand Total).'), backgroundColor: Colors.red),
                        );
                        return;
                      }

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

class _InlineInvoiceItemRow extends StatefulWidget {
  final int index;
  final InvoiceItem item;
  final double nameWidth;
  final double sizeWidth;
  final double hsnWidth;
  final double rateWidth;
  final double amountWidth;
  final List<String> availableUnits;
  final Function(InvoiceItem updatedItem) onChanged;
  final VoidCallback onDelete;

  const _InlineInvoiceItemRow({
    super.key,
    required this.index,
    required this.item,
    required this.nameWidth,
    required this.sizeWidth,
    required this.hsnWidth,
    required this.rateWidth,
    required this.amountWidth,
    required this.availableUnits,
    required this.onChanged,
    required this.onDelete,
  });

  @override
  State<_InlineInvoiceItemRow> createState() => _InlineInvoiceItemRowState();
}

class _InlineInvoiceItemRowState extends State<_InlineInvoiceItemRow> {
  late TextEditingController _nameController;
  late TextEditingController _hsnController;
  late TextEditingController _sizeController;
  late TextEditingController _pcsNumController;
  late String _selectedPcsUnit;
  late TextEditingController _qtyController;
  late String _selectedBillingUnit;
  late TextEditingController _priceController;

  final List<String> _pcsUnitsList = ['Pcs', 'Nag', 'Bdl', 'Box', 'Set', 'Pack', 'Mtr', 'Kg'];

  @override
  void initState() {
    super.initState();
    _nameController = TextEditingController(text: widget.item.productName);
    _hsnController = TextEditingController(text: widget.item.hsnCode ?? '');
    _sizeController = TextEditingController(text: widget.item.size ?? '');

    String rawPcsNum = '';
    String pcsUnit = 'Pcs';
    if (widget.item.pcsCount != null && widget.item.pcsCount!.isNotEmpty) {
      final parts = widget.item.pcsCount!.trim().split(' ');
      if (parts.isNotEmpty) {
        rawPcsNum = parts[0];
      }
      if (parts.length > 1) {
        pcsUnit = parts[1];
      }
    }
    _pcsNumController = TextEditingController(text: rawPcsNum);
    _selectedPcsUnit = _pcsUnitsList.contains(pcsUnit) ? pcsUnit : 'Pcs';

    _qtyController = TextEditingController(text: widget.item.quantity.toString());
    _selectedBillingUnit = widget.availableUnits.contains(widget.item.unit) ? widget.item.unit : widget.availableUnits.first;
    _priceController = TextEditingController(text: widget.item.price == 0 ? '' : widget.item.price.toString());
  }

  @override
  void didUpdateWidget(covariant _InlineInvoiceItemRow oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.item.productName != widget.item.productName && _nameController.text != widget.item.productName) {
      _nameController.text = widget.item.productName;
    }
    if (oldWidget.item.hsnCode != widget.item.hsnCode && _hsnController.text != (widget.item.hsnCode ?? '')) {
      _hsnController.text = widget.item.hsnCode ?? '';
    }
    if (oldWidget.item.size != widget.item.size && _sizeController.text != (widget.item.size ?? '')) {
      _sizeController.text = widget.item.size ?? '';
    }
    if (oldWidget.item.price != widget.item.price && _priceController.text != (widget.item.price == 0 ? '' : widget.item.price.toString())) {
      _priceController.text = widget.item.price == 0 ? '' : widget.item.price.toString();
    }
    if (oldWidget.item.quantity != widget.item.quantity && _qtyController.text != widget.item.quantity.toString()) {
      _qtyController.text = widget.item.quantity.toString();
    }
  }

  @override
  void dispose() {
    _nameController.dispose();
    _hsnController.dispose();
    _sizeController.dispose();
    _pcsNumController.dispose();
    _qtyController.dispose();
    _priceController.dispose();
    super.dispose();
  }

  void _notifyChange() {
    final qty = int.tryParse(_qtyController.text.trim()) ?? 1;
    final price = double.tryParse(_priceController.text.trim()) ?? 0.0;
    final amount = (qty > 0 ? qty : 1) * price;

    final rawPcs = _pcsNumController.text.trim();
    final formattedPcs = rawPcs.isNotEmpty ? "$rawPcs $_selectedPcsUnit" : null;

    final updated = widget.item.copyWith(
      productName: _nameController.text.trim(),
      hsnCode: _hsnController.text.trim(),
      size: _sizeController.text.trim().isEmpty ? null : _sizeController.text.trim(),
      pcsCount: formattedPcs,
      quantity: qty > 0 ? qty : 1,
      unit: _selectedBillingUnit,
      price: price,
      amount: amount,
    );

    widget.onChanged(updated);
  }

  void _showAddNewProductQuickDialog(BuildContext context, Function(Product newProd) onAdded) {
    final formKey = GlobalKey<FormState>();
    final nameCtrl = TextEditingController();
    final hsnCtrl = TextEditingController(text: '7304');
    final priceCtrl = TextEditingController();
    String unitVal = 'Pcs';

    showDialog(
      context: context,
      builder: (dlgCtx) {
        return AlertDialog(
          title: const Text('Add New Product to Catalog'),
          content: Form(
            key: formKey,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextFormField(
                  controller: nameCtrl,
                  validator: (v) => (v == null || v.trim().isEmpty) ? 'Product Name is required' : null,
                  decoration: const InputDecoration(labelText: 'Product Name *', border: OutlineInputBorder()),
                ),
                const SizedBox(height: 10),
                TextFormField(
                  controller: hsnCtrl,
                  validator: (v) => (v == null || v.trim().isEmpty) ? 'HSN Code is required' : null,
                  decoration: const InputDecoration(labelText: 'HSN / SAC Code *', border: OutlineInputBorder()),
                ),
                const SizedBox(height: 10),
                Row(
                  children: [
                    Expanded(
                      flex: 5,
                      child: TextFormField(
                        controller: priceCtrl,
                        keyboardType: const TextInputType.numberWithOptions(decimal: true),
                        decoration: const InputDecoration(labelText: 'Default Rate (₹)', border: OutlineInputBorder()),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      flex: 4,
                      child: DropdownButtonFormField<String>(
                        value: unitVal,
                        decoration: const InputDecoration(labelText: 'Unit', border: OutlineInputBorder()),
                        items: widget.availableUnits.map((u) => DropdownMenuItem(value: u, child: Text(u))).toList(),
                        onChanged: (v) {
                          if (v != null) unitVal = v;
                        },
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
          actions: [
            TextButton(onPressed: () => Navigator.pop(dlgCtx), child: const Text('Cancel')),
            ElevatedButton(
              onPressed: () async {
                if (formKey.currentState!.validate()) {
                  final newProd = Product(
                    name: nameCtrl.text.trim(),
                    hsnCode: hsnCtrl.text.trim(),
                    unit: unitVal,
                    price: double.tryParse(priceCtrl.text.trim()) ?? 0.0,
                    gstRate: 18.0,
                  );
                  await Provider.of<ProductProvider>(context, listen: false).addProduct(newProd);
                  onAdded(newProd);
                  if (dlgCtx.mounted) Navigator.pop(dlgCtx);
                }
              },
              child: const Text('Save & Select'),
            ),
          ],
        );
      },
    );
  }

  void _showProductSearchModal(BuildContext context) {
    final productProvider = Provider.of<ProductProvider>(context, listen: false);
    final allProducts = productProvider.products;

    final searchController = TextEditingController();
    List<Product> filteredProducts = List.from(allProducts);

    showDialog(
      context: context,
      builder: (ctx) {
        return StatefulBuilder(
          builder: (context, setModalState) {
            return AlertDialog(
              title: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Row(
                    children: [
                      Icon(Icons.search, color: Colors.blue),
                      SizedBox(width: 8),
                      Text('Select Product', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                    ],
                  ),
                  TextButton.icon(
                    onPressed: () {
                      _showAddNewProductQuickDialog(context, (newProd) {
                        setState(() {
                          _nameController.text = newProd.name ?? '';
                          if (newProd.hsnCode != null && newProd.hsnCode!.isNotEmpty) {
                            _hsnController.text = newProd.hsnCode!;
                          }
                          if (newProd.unit != null && widget.availableUnits.contains(newProd.unit)) {
                            _selectedBillingUnit = newProd.unit!;
                          }
                          if (newProd.price != null && newProd.price! > 0) {
                            _priceController.text = newProd.price.toString();
                          }
                        });
                        _notifyChange();
                        Navigator.pop(ctx);
                      });
                    },
                    icon: const Icon(Icons.add, size: 16),
                    label: const Text('+ Add New Product'),
                  ),
                ],
              ),
              content: SizedBox(
                width: 450,
                height: 420,
                child: Column(
                  children: [
                    TextField(
                      controller: searchController,
                      autofocus: true,
                      decoration: const InputDecoration(
                        hintText: 'Search product by name or HSN...',
                        prefixIcon: Icon(Icons.search),
                        border: OutlineInputBorder(),
                        isDense: true,
                      ),
                      onChanged: (val) {
                        setModalState(() {
                          final query = val.trim().toLowerCase();
                          if (query.isEmpty) {
                            filteredProducts = List.from(allProducts);
                          } else {
                            filteredProducts = allProducts.where((p) {
                              final name = (p.name ?? '').toLowerCase();
                              final hsn = (p.hsnCode ?? '').toLowerCase();
                              return name.contains(query) || hsn.contains(query);
                            }).toList();
                          }
                        });
                      },
                    ),
                    const SizedBox(height: 10),
                    Expanded(
                      child: filteredProducts.isEmpty
                          ? const Center(
                              child: Text('No matching products found.', style: TextStyle(color: Colors.grey)),
                            )
                          : ListView.separated(
                              itemCount: filteredProducts.length,
                              separatorBuilder: (_, __) => const Divider(height: 1),
                              itemBuilder: (context, idx) {
                                final p = filteredProducts[idx];
                                return ListTile(
                                  dense: true,
                                  title: Text(p.name ?? 'Unnamed Product', style: const TextStyle(fontWeight: FontWeight.bold)),
                                  subtitle: Text('HSN: ${p.hsnCode ?? "-"} • Unit: ${p.unit ?? "Pcs"}'),
                                  trailing: Text(
                                    '₹${(p.price ?? 0.0).toStringAsFixed(2)}',
                                    style: const TextStyle(fontWeight: FontWeight.bold, color: Colors.blue),
                                  ),
                                  onTap: () {
                                    setState(() {
                                      _nameController.text = p.name ?? '';
                                      if (p.hsnCode != null && p.hsnCode!.isNotEmpty) {
                                        _hsnController.text = p.hsnCode!;
                                      }
                                      if (p.unit != null && widget.availableUnits.contains(p.unit)) {
                                        _selectedBillingUnit = p.unit!;
                                      }
                                      if (p.price != null && p.price! > 0) {
                                        _priceController.text = p.price.toString();
                                      }
                                    });
                                    _notifyChange();
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
                TextButton(
                  onPressed: () => Navigator.pop(ctx),
                  child: const Text('Cancel'),
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
    final qty = int.tryParse(_qtyController.text.trim()) ?? 1;
    final price = double.tryParse(_priceController.text.trim()) ?? 0.0;
    final amount = (qty > 0 ? qty : 1) * price;

    return Container(
      padding: const EdgeInsets.symmetric(vertical: 6, horizontal: 8),
      decoration: BoxDecoration(
        color: widget.index % 2 == 0 ? Colors.grey.shade50 : Colors.white,
        border: Border(bottom: BorderSide(color: Colors.grey.shade300, width: 0.8)),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          // Index #
          SizedBox(
            width: 28,
            child: Text(
              '${widget.index + 1}',
              style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13, color: Colors.blueGrey),
              textAlign: TextAlign.center,
            ),
          ),
          const SizedBox(width: 6),

          // 1. Item Name * (Non-writable Tap-to-Select Dropdown Field)
          SizedBox(
            width: widget.nameWidth,
            child: InkWell(
              onTap: () => _showProductSearchModal(context),
              borderRadius: BorderRadius.circular(4),
              child: InputDecorator(
                decoration: const InputDecoration(
                  isDense: true,
                  contentPadding: EdgeInsets.symmetric(horizontal: 8, vertical: 8),
                  border: OutlineInputBorder(),
                  suffixIcon: Icon(Icons.arrow_drop_down_circle_outlined, color: Colors.blue, size: 18),
                ),
                child: Text(
                  _nameController.text.isNotEmpty ? _nameController.text : 'Select Item *',
                  style: TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                    color: _nameController.text.isNotEmpty ? Colors.black87 : Colors.grey.shade600,
                  ),
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ),
          ),
          const SizedBox(width: 6),

          // 2. HSN / SAC Code *
          SizedBox(
            width: widget.hsnWidth,
            child: TextField(
              controller: _hsnController,
              onChanged: (_) => _notifyChange(),
              style: const TextStyle(fontSize: 13),
              decoration: const InputDecoration(
                hintText: 'HSN *',
                isDense: true,
                contentPadding: EdgeInsets.symmetric(horizontal: 8, vertical: 10),
                border: OutlineInputBorder(),
              ),
            ),
          ),
          const SizedBox(width: 6),

          // 3. Size (Optional)
          SizedBox(
            width: widget.sizeWidth,
            child: TextField(
              controller: _sizeController,
              onChanged: (_) => _notifyChange(),
              style: const TextStyle(fontSize: 13),
              decoration: const InputDecoration(
                hintText: 'Size',
                isDense: true,
                contentPadding: EdgeInsets.symmetric(horizontal: 8, vertical: 10),
                border: OutlineInputBorder(),
              ),
            ),
          ),
          const SizedBox(width: 6),

          // 4. PCS Count (Optional)
          SizedBox(
            width: 70,
            child: TextField(
              controller: _pcsNumController,
              keyboardType: const TextInputType.numberWithOptions(decimal: true),
              onChanged: (_) => _notifyChange(),
              textAlign: TextAlign.center,
              style: const TextStyle(fontSize: 13),
              decoration: const InputDecoration(
                hintText: 'PCS',
                isDense: true,
                contentPadding: EdgeInsets.symmetric(horizontal: 6, vertical: 10),
                border: OutlineInputBorder(),
              ),
            ),
          ),
          const SizedBox(width: 6),

          // 5. PCS Unit Dropdown
          SizedBox(
            width: 75,
            child: DropdownButtonFormField<String>(
              value: _selectedPcsUnit,
              isExpanded: true,
              style: const TextStyle(fontSize: 12, color: Colors.black87),
              decoration: const InputDecoration(
                isDense: true,
                contentPadding: EdgeInsets.symmetric(horizontal: 4, vertical: 8),
                border: OutlineInputBorder(),
              ),
              items: _pcsUnitsList
                  .map((u) => DropdownMenuItem(value: u, child: Text(u, style: const TextStyle(fontSize: 11))))
                  .toList(),
              onChanged: (val) {
                if (val != null) {
                  setState(() => _selectedPcsUnit = val);
                  _notifyChange();
                }
              },
            ),
          ),
          const SizedBox(width: 6),

          // 6. Billed Qty *
          SizedBox(
            width: 75,
            child: TextField(
              controller: _qtyController,
              keyboardType: TextInputType.number,
              onChanged: (_) => _notifyChange(),
              textAlign: TextAlign.center,
              style: const TextStyle(fontSize: 13, fontWeight: FontWeight.bold),
              decoration: const InputDecoration(
                hintText: 'Billed Qty *',
                isDense: true,
                contentPadding: EdgeInsets.symmetric(horizontal: 6, vertical: 10),
                border: OutlineInputBorder(),
              ),
            ),
          ),
          const SizedBox(width: 6),

          // 7. Billing Unit * Dropdown
          SizedBox(
            width: 85,
            child: DropdownButtonFormField<String>(
              value: _selectedBillingUnit,
              isExpanded: true,
              style: const TextStyle(fontSize: 12, color: Colors.black87),
              decoration: const InputDecoration(
                isDense: true,
                contentPadding: EdgeInsets.symmetric(horizontal: 6, vertical: 8),
                border: OutlineInputBorder(),
              ),
              items: widget.availableUnits
                  .map((u) => DropdownMenuItem(value: u, child: Text(u, style: const TextStyle(fontSize: 11))))
                  .toList(),
              onChanged: (val) {
                if (val != null) {
                  setState(() => _selectedBillingUnit = val);
                  _notifyChange();
                }
              },
            ),
          ),
          const SizedBox(width: 6),

          // 8. Rate / Price (₹) *
          SizedBox(
            width: widget.rateWidth,
            child: TextField(
              controller: _priceController,
              keyboardType: const TextInputType.numberWithOptions(decimal: true),
              onChanged: (_) => _notifyChange(),
              textAlign: TextAlign.right,
              style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600),
              decoration: const InputDecoration(
                hintText: 'Rate (₹) *',
                isDense: true,
                contentPadding: EdgeInsets.symmetric(horizontal: 6, vertical: 10),
                border: OutlineInputBorder(),
              ),
            ),
          ),
          const SizedBox(width: 6),

          // 9. Taxable Value (₹)
          SizedBox(
            width: widget.amountWidth,
            child: Text(
              '₹${amount.toStringAsFixed(2)}',
              style: const TextStyle(fontSize: 13, fontWeight: FontWeight.bold, color: Colors.blue),
              textAlign: TextAlign.right,
            ),
          ),
          const SizedBox(width: 6),

          // 10. Delete Action Button
          IconButton(
            icon: const Icon(Icons.delete_outline_rounded, color: Colors.red, size: 20),
            tooltip: 'Remove Item',
            onPressed: widget.onDelete,
          ),
        ],
      ),
    );
  }
}
