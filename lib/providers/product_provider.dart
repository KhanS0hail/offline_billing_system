import 'package:flutter/material.dart';
import '../database/database_helper.dart';
import '../models/product.dart';

class ProductProvider extends ChangeNotifier {
  List<Product> _products = [];
  bool _isLoading = false;
  String _searchQuery = '';

  /// Returns full product list from database (isolated from Product Page search query)
  List<Product> get products => _products;

  /// Returns filtered products for Product Page search view
  List<Product> get filteredProducts {
    if (_searchQuery.trim().isEmpty) return _products;
    return _products.where((product) {
      final name = product.name?.toLowerCase() ?? '';
      final hsn = product.hsnCode?.toLowerCase() ?? '';
      final query = _searchQuery.toLowerCase();
      return name.contains(query) || hsn.contains(query);
    }).toList();
  }

  bool get isLoading => _isLoading;
  String get searchQuery => _searchQuery;

  ProductProvider() {
    loadProducts();
  }

  Future<void> loadProducts() async {
    _isLoading = true;
    notifyListeners();
    _searchQuery = ''; // Reset search on fresh load/navigation
    _products = await DatabaseHelper.instance.getProducts();
    _isLoading = false;
    notifyListeners();
  }

  void setSearchQuery(String query) {
    _searchQuery = query;
    notifyListeners();
  }

  Future<void> addProduct(Product product) async {
    await DatabaseHelper.instance.insertProduct(product);
    await loadProducts();
  }

  Future<void> updateProduct(Product product) async {
    await DatabaseHelper.instance.updateProduct(product);
    await loadProducts();
  }

  Future<void> deleteProduct(int id) async {
    await DatabaseHelper.instance.deleteProduct(id);
    await loadProducts();
  }
}
