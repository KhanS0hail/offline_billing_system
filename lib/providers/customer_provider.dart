import 'package:flutter/material.dart';
import '../database/database_helper.dart';
import '../models/customer.dart';
import '../models/customer_payment.dart';

class CustomerProvider extends ChangeNotifier {
  List<Customer> _customers = [];
  bool _isLoading = false;
  String _searchQuery = '';

  /// Returns full customer list from database (isolated from Customer Page search query)
  List<Customer> get customers => _customers;

  /// Returns filtered customers for Customer Page search view
  List<Customer> get filteredCustomers {
    if (_searchQuery.trim().isEmpty) return _customers;
    return _customers.where((customer) {
      final name = customer.name?.toLowerCase() ?? '';
      final phone = customer.phone?.toLowerCase() ?? '';
      final gstin = customer.gstNumber?.toLowerCase() ?? '';
      final query = _searchQuery.toLowerCase();
      return name.contains(query) || phone.contains(query) || gstin.contains(query);
    }).toList();
  }

  bool get isLoading => _isLoading;
  String get searchQuery => _searchQuery;

  CustomerProvider() {
    loadCustomers();
  }

  Future<void> loadCustomers() async {
    _isLoading = true;
    notifyListeners();
    _searchQuery = ''; // Reset search on fresh load/navigation
    _customers = await DatabaseHelper.instance.getCustomers();
    _isLoading = false;
    notifyListeners();
  }

  void setSearchQuery(String query) {
    _searchQuery = query;
    notifyListeners();
  }

  Future<void> addCustomer(Customer customer) async {
    await DatabaseHelper.instance.insertCustomer(customer);
    await loadCustomers();
  }

  Future<void> updateCustomer(Customer customer) async {
    await DatabaseHelper.instance.updateCustomer(customer);
    await loadCustomers();
  }

  Future<void> deleteCustomer(int id) async {
    await DatabaseHelper.instance.deleteCustomer(id);
    await loadCustomers();
  }

  // Payments Helper
  Future<String> generateNextReceiptNumber() async {
    return await DatabaseHelper.instance.generateNextReceiptNumber();
  }

  Future<List<CustomerPayment>> getPaymentsForCustomer(int customerId) async {
    return await DatabaseHelper.instance.getPaymentsForCustomer(customerId);
  }

  Future<void> addPayment(CustomerPayment payment) async {
    await DatabaseHelper.instance.insertCustomerPayment(payment);
    notifyListeners();
  }

  Future<void> deletePayment(int paymentId, int customerId) async {
    await DatabaseHelper.instance.deleteCustomerPayment(paymentId, customerId);
    notifyListeners();
  }
}
