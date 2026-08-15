import 'package:flutter/material.dart';
import '../database/database_helper.dart';
import '../models/company.dart';
import '../models/customer.dart';
import '../models/product.dart';
import '../models/invoice.dart';
import '../models/invoice_item.dart';
import '../utils/gst_calculator.dart';

class InvoiceProvider extends ChangeNotifier {
  List<Invoice> _invoices = [];
  bool _isLoading = false;
  String _filterStatus = 'All'; // 'All', 'Paid', 'Unpaid', 'Partially Paid'
  String _searchQuery = '';

  // --- DRAFT INVOICE STATE ---
  int? _editingInvoiceId; // null if creating new, non-null if editing existing
  String _invoiceType = 'TAX INVOICE'; // 'TAX INVOICE' or 'PROFORMA INVOICE'
  String _nextInvoiceNumber = '';
  String? _challanNumber;
  DateTime _deliveryDate = DateTime.now();
  String _vehicleNumber = '';
  String _transportMode = '';
  Customer? _selectedCustomer;
  DateTime _invoiceDate = DateTime.now();
  DateTime _dueDate = DateTime.now().add(const Duration(days: 15)); // Default 15 days
  List<InvoiceItem> _draftItems = [];
  double _transportCharges = 0.0;
  double _gstRate = 18.0;
  double _discountAmount = 0.0;
  String _paymentStatus = 'Unpaid'; // 'Unpaid', 'Paid', 'Partially Paid'
  double _receivedAmount = 0.0;
  String _notes = '';

  // Getters
  List<Invoice> get invoices {
    var filtered = _invoices;
    if (_filterStatus != 'All') {
      filtered = filtered.where((inv) => inv.status == _filterStatus).toList();
    }
    if (_searchQuery.isNotEmpty) {
      filtered = filtered.where((inv) {
        final num = inv.invoiceNumber.toLowerCase();
        final cust = (inv.customerName ?? '').toLowerCase();
        final query = _searchQuery.toLowerCase();
        return num.contains(query) || cust.contains(query);
      }).toList();
    }
    return filtered;
  }

  bool get isLoading => _isLoading;
  String get filterStatus => _filterStatus;
  String get searchQuery => _searchQuery;

  // Draft Getters
  int? get editingInvoiceId => _editingInvoiceId;
  bool get isEditing => _editingInvoiceId != null;
  String get invoiceType => _invoiceType;
  String get nextInvoiceNumber => _nextInvoiceNumber;
  String? get challanNumber => _challanNumber;
  DateTime get deliveryDate => _deliveryDate;
  String get vehicleNumber => _vehicleNumber;
  String get transportMode => _transportMode;
  Customer? get selectedCustomer => _selectedCustomer;
  DateTime get invoiceDate => _invoiceDate;
  DateTime get dueDate => _dueDate;
  List<InvoiceItem> get draftItems => _draftItems;
  double get transportCharges => _transportCharges;
  double get gstRate => _gstRate;
  double get discountAmount => _discountAmount;
  String get paymentStatus => _paymentStatus;
  double get receivedAmount => _receivedAmount;
  String get notes => _notes;

  InvoiceProvider() {
    loadInvoices();
  }

  Future<void> loadInvoices() async {
    _isLoading = true;
    notifyListeners();
    _invoices = await DatabaseHelper.instance.getInvoices();
    _isLoading = false;
    notifyListeners();
  }

  void setFilterStatus(String status) {
    _filterStatus = status;
    notifyListeners();
  }

  void setSearchQuery(String query) {
    _searchQuery = query;
    notifyListeners();
  }

  // --- DRAFT CREATION / EDIT METHODS ---
  Future<void> prepareNewInvoice() async {
    _editingInvoiceId = null;
    _invoiceType = 'TAX INVOICE';
    _nextInvoiceNumber = await DatabaseHelper.instance.generateNextInvoiceNumber();
    _challanNumber = null;
    _deliveryDate = DateTime.now();
    _vehicleNumber = '';
    _transportMode = '';
    _selectedCustomer = null;
    _invoiceDate = DateTime.now();
    _dueDate = DateTime.now().add(const Duration(days: 15));
    _draftItems = [];
    _transportCharges = 0.0;
    _gstRate = 18.0;
    _discountAmount = 0.0;
    _paymentStatus = 'Unpaid';
    _receivedAmount = 0.0;
    _notes = '';
    notifyListeners();
  }

  void prepareEditInvoice(Invoice invoice, List<Customer> customers) {
    _editingInvoiceId = invoice.id;
    _invoiceType = invoice.invoiceType;
    _nextInvoiceNumber = invoice.invoiceNumber;
    _challanNumber = invoice.challanNumber;
    _vehicleNumber = invoice.vehicleNumber ?? '';
    _transportMode = invoice.transportMode ?? '';

    // Parse delivery date if exists
    if (invoice.deliveryDate != null && invoice.deliveryDate!.isNotEmpty) {
      try {
        final parts = invoice.deliveryDate!.split('-');
        if (parts.length == 3) {
          final day = int.parse(parts[0]);
          final monthStr = parts[1];
          final year = int.parse(parts[2]);
          const months = ["Jan", "Feb", "Mar", "Apr", "May", "Jun", "Jul", "Aug", "Sep", "Oct", "Nov", "Dec"];
          final month = months.indexOf(monthStr) + 1;
          _deliveryDate = DateTime(year, month > 0 ? month : 1, day);
        }
      } catch (_) {
        _deliveryDate = DateTime.now();
      }
    } else {
      _deliveryDate = DateTime.now();
    }
    
    // Find matching customer
    _selectedCustomer = null;
    if (invoice.customerId != null) {
      try {
        _selectedCustomer = customers.firstWhere((c) => c.id == invoice.customerId);
      } catch (_) {}
    }

    _draftItems = List.from(invoice.items);
    _transportCharges = invoice.transportCharges;
    _gstRate = invoice.gstRate;
    _discountAmount = invoice.discountAmount;
    _paymentStatus = invoice.status;
    _receivedAmount = invoice.receivedAmount;
    _notes = invoice.notes ?? '';
    notifyListeners();
  }

  void setInvoiceType(String type) {
    _invoiceType = type;
    notifyListeners();
  }

  void setChallanNumber(String? challan) {
    _challanNumber = challan;
    notifyListeners();
  }

  void setDeliveryDate(DateTime date) {
    _deliveryDate = date;
    notifyListeners();
  }

  void setVehicleNumber(String vehicle) {
    _vehicleNumber = vehicle;
    notifyListeners();
  }

  void setTransportMode(String mode) {
    _transportMode = mode;
    notifyListeners();
  }

  void setSelectedCustomer(Customer? customer) {
    _selectedCustomer = customer;
    notifyListeners();
  }

  void setInvoiceDate(DateTime date) {
    _invoiceDate = date;
    _deliveryDate = date; // Default delivery date to invoice date
    _dueDate = date.add(const Duration(days: 15));
    notifyListeners();
  }

  void setDueDate(DateTime date) {
    _dueDate = date;
    notifyListeners();
  }

  void setTransportCharges(double charges) {
    _transportCharges = charges;
    notifyListeners();
  }

  void setGstRate(double rate) {
    _gstRate = rate;
    notifyListeners();
  }

  void setDiscountAmount(double discount) {
    _discountAmount = discount;
    notifyListeners();
  }

  void setPaymentStatus(String status) {
    _paymentStatus = status;
    notifyListeners();
  }

  void setReceivedAmount(double amount) {
    _receivedAmount = amount;
    notifyListeners();
  }

  void setNotes(String n) {
    _notes = n;
    notifyListeners();
  }

  void addProductToDraft(Product product) {
    final newItem = InvoiceItem(
      productId: product.id,
      productName: product.name ?? 'Item',
      size: '',
      pcsCount: '',
      hsnCode: product.hsnCode,
      quantity: 1,
      unit: product.unit ?? 'Pcs',
      price: product.price ?? 0.0,
    );
    _draftItems.add(newItem);
    notifyListeners();
  }

  void updateDraftItem(int index, InvoiceItem updatedItem) {
    if (index >= 0 && index < _draftItems.length) {
      _draftItems[index] = updatedItem;
      notifyListeners();
    }
  }

  void removeDraftItem(int index) {
    if (index >= 0 && index < _draftItems.length) {
      _draftItems.removeAt(index);
      notifyListeners();
    }
  }

  GstCalculationResult calculateCurrentTotals(Company? company) {
    return GstCalculator.calculateInvoiceTotals(
      items: _draftItems,
      companyStateCode: company?.stateCode,
      customerStateCode: _selectedCustomer?.stateCode,
      transportCharges: _transportCharges,
      gstRate: _gstRate,
      discountAmount: _discountAmount,
    );
  }

  Future<int> saveDraftInvoice(Company? company) async {
    final totals = calculateCurrentTotals(company);
    final formattedDate = "${_invoiceDate.day.toString().padLeft(2, '0')}-${_monthName(_invoiceDate.month)}-${_invoiceDate.year}";
    final formattedDeliveryDate = "${_deliveryDate.day.toString().padLeft(2, '0')}-${_monthName(_deliveryDate.month)}-${_deliveryDate.year}";
    final formattedDueDate = "${_dueDate.day.toString().padLeft(2, '0')}-${_monthName(_dueDate.month)}-${_dueDate.year}";

    double actualReceived = 0.0;
    if (_paymentStatus == 'Paid') {
      actualReceived = totals.grandTotal;
    } else if (_paymentStatus == 'Partially Paid') {
      actualReceived = _receivedAmount;
    }
    final actualBalance = totals.grandTotal - actualReceived;

    final invoice = Invoice(
      id: _editingInvoiceId,
      invoiceType: _invoiceType,
      invoiceNumber: _nextInvoiceNumber,
      challanNumber: (_challanNumber != null && _challanNumber!.trim().isNotEmpty) ? _challanNumber!.trim() : null,
      deliveryDate: formattedDeliveryDate,
      vehicleNumber: (_vehicleNumber.trim().isNotEmpty) ? _vehicleNumber.trim() : null,
      transportMode: (_transportMode.trim().isNotEmpty) ? _transportMode.trim() : null,
      customerId: _selectedCustomer?.id,
      customerName: _selectedCustomer?.name,
      customerGstin: _selectedCustomer?.gstNumber,
      customerStateCode: _selectedCustomer?.stateCode,
      customerAddress: _selectedCustomer?.address,
      date: formattedDate,
      dueDate: formattedDueDate,
      paymentDate: (_paymentStatus == 'Paid' || _paymentStatus == 'Partially Paid') ? formattedDate : null,
      status: _paymentStatus,
      subtotal: totals.subtotal,
      transportCharges: totals.transportCharges,
      taxableBase: totals.taxableBase,
      gstRate: totals.gstRate,
      cgstTotal: totals.cgstTotal,
      sgstTotal: totals.sgstTotal,
      igstTotal: totals.igstTotal,
      totalTax: totals.totalTax,
      discountAmount: totals.discountAmount,
      roundOff: totals.roundOff,
      grandTotal: totals.grandTotal,
      receivedAmount: actualReceived,
      balanceAmount: actualBalance,
      notes: (_notes.trim().isNotEmpty) ? _notes.trim() : null,
      items: _draftItems,
    );

    int returnId;
    if (_editingInvoiceId != null) {
      await DatabaseHelper.instance.updateInvoice(invoice);
      returnId = _editingInvoiceId!;
    } else {
      returnId = await DatabaseHelper.instance.insertInvoice(invoice);
    }
    await loadInvoices();
    return returnId;
  }

  Future<void> updateInvoicePayment(int id, String status, {double? received, double? balance, String? paymentDate}) async {
    final todayStr = "${DateTime.now().day.toString().padLeft(2, '0')}-${_monthName(DateTime.now().month)}-${DateTime.now().year}";
    final dateToSave = paymentDate ?? ((status == 'Paid' || status == 'Partially Paid') ? todayStr : null);
    await DatabaseHelper.instance.updateInvoiceStatus(id, status, receivedAmount: received, balanceAmount: balance, paymentDate: dateToSave);
    await loadInvoices();
  }

  Future<void> deleteInvoice(int id) async {
    await DatabaseHelper.instance.deleteInvoice(id);
    await loadInvoices();
  }

  String _monthName(int m) {
    const months = ["Jan", "Feb", "Mar", "Apr", "May", "Jun", "Jul", "Aug", "Sep", "Oct", "Nov", "Dec"];
    return months[m - 1];
  }
}
