import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/customer_provider.dart';
import '../models/customer.dart';

class CustomersScreen extends StatelessWidget {
  const CustomersScreen({super.key});

  void _showCustomerDialog(BuildContext context, {Customer? customer}) {
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
        return AlertDialog(
          title: Text(isEditing ? 'Edit Customer' : 'Add New Customer'),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextField(
                  controller: nameController,
                  decoration: const InputDecoration(labelText: 'Customer / Business Name', prefixIcon: Icon(Icons.person)),
                ),
                const SizedBox(height: 8),
                TextField(
                  controller: contactPersonController,
                  decoration: const InputDecoration(labelText: 'Contact Person', prefixIcon: Icon(Icons.badge)),
                ),
                const SizedBox(height: 8),
                TextField(
                  controller: phoneController,
                  keyboardType: TextInputType.phone,
                  decoration: const InputDecoration(labelText: 'Phone Number', prefixIcon: Icon(Icons.phone)),
                ),
                const SizedBox(height: 8),
                TextField(
                  controller: emailController,
                  keyboardType: TextInputType.emailAddress,
                  decoration: const InputDecoration(labelText: 'Email Address', prefixIcon: Icon(Icons.email)),
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
                const SizedBox(height: 8),
                TextField(
                  controller: openingBalanceController,
                  keyboardType: const TextInputType.numberWithOptions(decimal: true),
                  decoration: const InputDecoration(labelText: 'Opening Balance (₹)', prefixIcon: Icon(Icons.account_balance_wallet)),
                ),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(ctx),
              child: const Text('Cancel'),
            ),
            ElevatedButton(
              onPressed: () async {
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
              },
              child: Text(isEditing ? 'Update' : 'Add'),
            ),
          ],
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
          final customers = provider.customers;

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
