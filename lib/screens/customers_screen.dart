import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/customer_provider.dart';
import '../models/customer.dart';

class CustomersScreen extends StatelessWidget {
  const CustomersScreen({super.key});

  void _showCustomerDialog(BuildContext context, {Customer? customer}) {
    final formKey = GlobalKey<FormState>();
    final nameController = TextEditingController(text: customer?.name ?? '');
    final contactPersonController = TextEditingController(text: customer?.contactPerson ?? '');
    final phoneController = TextEditingController(text: customer?.phone ?? '');
    final emailController = TextEditingController(text: customer?.email ?? '');
    final addressController = TextEditingController(text: customer?.address ?? '');
    final gstController = TextEditingController(text: customer?.gstNumber ?? '');
    final stateCodeController = TextEditingController(text: customer?.stateCode ?? '');
    final openingBalanceController = TextEditingController(text: customer?.openingBalance?.toString() ?? '0.0');

    final isEditing = customer != null;

    showDialog(
      context: context,
      builder: (ctx) {
        return StatefulBuilder(
          builder: (context, setDialogState) {
            return AlertDialog(
              title: Text(isEditing ? 'Edit Customer' : 'Add New Customer'),
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
                        decoration: const InputDecoration(labelText: 'Full Address *', prefixIcon: Icon(Icons.location_on)),
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
                        controller: contactPersonController,
                        decoration: const InputDecoration(labelText: 'Contact Person (Optional)', prefixIcon: Icon(Icons.badge)),
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
                      const SizedBox(height: 8),
                      TextFormField(
                        controller: emailController,
                        keyboardType: TextInputType.emailAddress,
                        validator: (v) {
                          if (v != null && v.trim().isNotEmpty) {
                            final emailRegex = RegExp(r'^[\w-\.]+@([\w-]+\.)+[\w-]{2,4}$');
                            if (!emailRegex.hasMatch(v.trim())) {
                              return 'Enter valid email address';
                            }
                          }
                          return null;
                        },
                        decoration: const InputDecoration(labelText: 'Email Address (Optional)', prefixIcon: Icon(Icons.email)),
                      ),
                      const SizedBox(height: 8),
                      TextFormField(
                        controller: openingBalanceController,
                        keyboardType: const TextInputType.numberWithOptions(decimal: true),
                        validator: (v) {
                          if (v != null && v.trim().isNotEmpty) {
                            if (double.tryParse(v.trim()) == null) {
                              return 'Enter valid numeric balance';
                            }
                          }
                          return null;
                        },
                        decoration: const InputDecoration(labelText: 'Opening Balance (₹, Optional)', prefixIcon: Icon(Icons.account_balance_wallet)),
                      ),
                    ],
                  ),
                ),
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(ctx),
                  child: const Text('Cancel'),
                ),
                ElevatedButton(
                  onPressed: () async {
                    if (formKey.currentState!.validate()) {
                      final newCust = Customer(
                        id: customer?.id,
                        name: nameController.text.trim(),
                        contactPerson: contactPersonController.text.trim(),
                        phone: phoneController.text.trim(),
                        email: emailController.text.trim(),
                        address: addressController.text.trim(),
                        gstNumber: gstController.text.trim(),
                        stateCode: stateCodeController.text.trim(),
                        openingBalance: double.tryParse(openingBalanceController.text.trim()) ?? 0.0,
                      );

                      final provider = Provider.of<CustomerProvider>(context, listen: false);
                      if (isEditing) {
                        await provider.updateCustomer(newCust);
                      } else {
                        await provider.addCustomer(newCust);
                      }

                      if (ctx.mounted) Navigator.pop(ctx);
                    }
                  },
                  child: Text(isEditing ? 'Update' : 'Add'),
                ),
              ],
            );
          },
        );
      },
    );
  }

  void _confirmDelete(BuildContext context, Customer customer) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Delete Customer?'),
        content: Text('Are you sure you want to delete "${customer.name ?? "this customer"}"?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            onPressed: () async {
              if (customer.id != null) {
                await Provider.of<CustomerProvider>(context, listen: false).deleteCustomer(customer.id!);
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
        title: const Text('Customer Directory'),
      ),
      body: Consumer<CustomerProvider>(
        builder: (context, provider, child) {
          final customers = provider.filteredCustomers;

          return Column(
            children: [
              Padding(
                padding: const EdgeInsets.all(16.0),
                child: TextField(
                  decoration: InputDecoration(
                    hintText: 'Search customer by name, phone, or GSTIN...',
                    prefixIcon: const Icon(Icons.search),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    contentPadding: const EdgeInsets.symmetric(horizontal: 16),
                  ),
                  onChanged: (value) => provider.setSearchQuery(value),
                ),
              ),
              Expanded(
                child: provider.isLoading
                    ? const Center(child: CircularProgressIndicator())
                    : customers.isEmpty
                        ? const Center(
                            child: Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Icon(Icons.people_outline, size: 64, color: Colors.grey),
                                SizedBox(height: 16),
                                Text('No customers found. Click + to add your first customer!'),
                              ],
                            ),
                          )
                        : ListView.builder(
                            itemCount: customers.length,
                            padding: const EdgeInsets.fromLTRB(16, 0, 16, 88),
                            itemBuilder: (context, index) {
                              final cust = customers[index];
                              return Card(
                                margin: const EdgeInsets.only(bottom: 12),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(12),
                                ),
                                child: ListTile(
                                  leading: CircleAvatar(
                                    child: Text(
                                      (cust.name != null && cust.name!.isNotEmpty)
                                          ? cust.name![0].toUpperCase()
                                          : 'C',
                                    ),
                                  ),
                                  title: Text(
                                    cust.name ?? 'Unnamed Customer',
                                    style: const TextStyle(fontWeight: FontWeight.bold),
                                  ),
                                  subtitle: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      if (cust.contactPerson != null && cust.contactPerson!.isNotEmpty)
                                        Text('Contact Person: ${cust.contactPerson}'),
                                      if (cust.phone != null && cust.phone!.isNotEmpty)
                                        Text('Phone: ${cust.phone}'),
                                      if (cust.gstNumber != null && cust.gstNumber!.isNotEmpty)
                                        Text('GSTIN: ${cust.gstNumber}'),
                                    ],
                                  ),
                                  trailing: Row(
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      IconButton(
                                        icon: const Icon(Icons.edit, color: Colors.blue),
                                        onPressed: () => _showCustomerDialog(context, customer: cust),
                                      ),
                                      IconButton(
                                        icon: const Icon(Icons.delete, color: Colors.red),
                                        onPressed: () => _confirmDelete(context, cust),
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
        onPressed: () => _showCustomerDialog(context),
        icon: const Icon(Icons.person_add),
        label: const Text('Add Customer'),
      ),
    );
  }
}
