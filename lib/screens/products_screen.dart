import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/product_provider.dart';
import '../models/product.dart';

class ProductsScreen extends StatelessWidget {
  const ProductsScreen({super.key});

  void _showProductDialog(BuildContext context, {Product? product}) {
    final formKey = GlobalKey<FormState>();
    final nameController = TextEditingController(text: product?.name ?? '');
    final descriptionController = TextEditingController(text: product?.description ?? '');
    final hsnController = TextEditingController(text: product?.hsnCode ?? '');
    final priceController = TextEditingController(text: product?.price?.toString() ?? '');
    
    String selectedUnit = product?.unit ?? 'Pcs';
    double selectedGst = product?.gstRate ?? 18.0;

    final isEditing = product != null;

    showDialog(
      context: context,
      builder: (ctx) {
        return StatefulBuilder(
          builder: (context, setDialogState) {
            return AlertDialog(
              title: Text(isEditing ? 'Edit Product' : 'Add New Product'),
              content: SingleChildScrollView(
                child: Form(
                  key: formKey,
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      TextFormField(
                        controller: nameController,
                        validator: (v) => (v == null || v.trim().isEmpty) ? 'Product name is required' : null,
                        decoration: const InputDecoration(labelText: 'Item / Product Name *', prefixIcon: Icon(Icons.inventory_2)),
                      ),
                      const SizedBox(height: 8),
                      Row(
                        children: [
                          Expanded(
                            child: TextFormField(
                              controller: hsnController,
                              validator: (v) => (v == null || v.trim().isEmpty) ? 'HSN code is required' : null,
                              decoration: const InputDecoration(labelText: 'HSN / SAC Code *', prefixIcon: Icon(Icons.qr_code)),
                            ),
                          ),
                          const SizedBox(width: 8),
                          Expanded(
                            child: DropdownButtonFormField<String>(
                              value: selectedUnit,
                              decoration: const InputDecoration(labelText: 'Unit'),
                              items: ['Pcs', 'Kg', 'Gm', 'Mtr', 'Ltr', 'Box', 'Set', 'Pack']
                                  .map((u) => DropdownMenuItem(value: u, child: Text(u)))
                                  .toList(),
                              onChanged: (val) {
                                if (val != null) setDialogState(() => selectedUnit = val);
                              },
                            ),
                          ),
                        ],
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
                                final numVal = double.tryParse(v.trim());
                                if (numVal == null || numVal < 0) return 'Enter valid price';
                                return null;
                              },
                              decoration: const InputDecoration(labelText: 'Selling Price (₹) *', prefixIcon: Icon(Icons.currency_rupee)),
                            ),
                          ),
                          const SizedBox(width: 8),
                          Expanded(
                            child: DropdownButtonFormField<double>(
                              value: selectedGst,
                              decoration: const InputDecoration(labelText: 'GST %'),
                              items: [0.0, 5.0, 12.0, 18.0, 28.0]
                                  .map((g) => DropdownMenuItem(value: g, child: Text('${g.toStringAsFixed(0)}%')))
                                  .toList(),
                              onChanged: (val) {
                                if (val != null) setDialogState(() => selectedGst = val);
                              },
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 8),
                      TextFormField(
                        controller: descriptionController,
                        decoration: const InputDecoration(labelText: 'Description / Specs (Optional)', prefixIcon: Icon(Icons.description)),
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
                      final newProd = Product(
                        id: product?.id,
                        name: nameController.text.trim(),
                        description: descriptionController.text.trim(),
                        hsnCode: hsnController.text.trim(),
                        unit: selectedUnit,
                        price: double.tryParse(priceController.text.trim()),
                        gstRate: selectedGst,
                      );

                      final provider = Provider.of<ProductProvider>(context, listen: false);
                      if (isEditing) {
                        await provider.updateProduct(newProd);
                      } else {
                        await provider.addProduct(newProd);
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

  void _confirmDelete(BuildContext context, Product product) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Delete Product?'),
        content: Text('Are you sure you want to delete "${product.name ?? "this item"}"?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            onPressed: () async {
              if (product.id != null) {
                await Provider.of<ProductProvider>(context, listen: false).deleteProduct(product.id!);
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
        title: const Text('Products & Services Catalog'),
      ),
      body: Consumer<ProductProvider>(
        builder: (context, provider, child) {
          final products = provider.products;

          return Column(
            children: [
              Padding(
                padding: const EdgeInsets.all(16.0),
                child: TextField(
                  decoration: InputDecoration(
                    hintText: 'Search product by name or HSN code...',
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
                    : products.isEmpty
                        ? const Center(
                            child: Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Icon(Icons.inventory_2_outlined, size: 64, color: Colors.grey),
                                SizedBox(height: 16),
                                Text('No products found. Click + to add your first item!'),
                              ],
                            ),
                          )
                        : ListView.builder(
                            itemCount: products.length,
                            padding: const EdgeInsets.fromLTRB(16, 0, 16, 88),
                            itemBuilder: (context, index) {
                              final prod = products[index];
                              return Card(
                                margin: const EdgeInsets.only(bottom: 12),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(12),
                                ),
                                child: ListTile(
                                  leading: CircleAvatar(
                                    backgroundColor: Theme.of(context).colorScheme.primaryContainer,
                                    child: Icon(
                                      Icons.shopping_bag_outlined,
                                      color: Theme.of(context).colorScheme.onPrimaryContainer,
                                    ),
                                  ),
                                  title: Text(
                                    prod.name ?? 'Unnamed Item',
                                    style: const TextStyle(fontWeight: FontWeight.bold),
                                  ),
                                  subtitle: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      if (prod.hsnCode != null && prod.hsnCode!.isNotEmpty)
                                        Text('HSN: ${prod.hsnCode}'),
                                      Text(
                                        'Price: ₹${prod.price?.toStringAsFixed(2) ?? "0.00"} / ${prod.unit ?? "Pcs"}  (GST: ${prod.gstRate?.toStringAsFixed(0)}%)',
                                        style: TextStyle(
                                          fontWeight: FontWeight.w600,
                                          color: Theme.of(context).colorScheme.primary,
                                        ),
                                      ),
                                    ],
                                  ),
                                  trailing: Row(
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      IconButton(
                                        icon: const Icon(Icons.edit, color: Colors.blue),
                                        onPressed: () => _showProductDialog(context, product: prod),
                                      ),
                                      IconButton(
                                        icon: const Icon(Icons.delete, color: Colors.red),
                                        onPressed: () => _confirmDelete(context, prod),
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
        onPressed: () => _showProductDialog(context),
        icon: const Icon(Icons.add_shopping_cart),
        label: const Text('Add Product'),
      ),
    );
  }
}
