import 'invoice_item.dart';

class Invoice {
  final int? id;
  final String invoiceType; // 'TAX INVOICE' or 'PROFORMA INVOICE'
  final String invoiceNumber;
  final String? poNumber;
  final String? challanNumber;
  final String? deliveryDate;
  final String? vehicleNumber;
  final String? transportMode;
  final int? customerId;
  final String? customerName;
  final String? customerGstin;
  final String? customerStateCode;
  final String? customerAddress;
  
  // Shipping Customer Fields (Optional, defaults to Billed To if null/empty)
  final String? shippingCustomerName;
  final String? shippingAddress;
  final String? shippingGstin;
  final String? shippingStateCode;

  final String date;
  final String? dueDate;
  final String? paymentDate; // Date when payment was received
  final String status; // 'Unpaid', 'Paid', 'Partially Paid'
  final double subtotal;
  final double loadingCharges;
  final double transportCharges;
  final double taxableBase;
  final double gstRate;
  final double cgstTotal;
  final double sgstTotal;
  final double igstTotal;
  final double totalTax;
  final double discountAmount;
  final double roundOff;
  final double grandTotal;
  final double receivedAmount; // Amount received so far
  final double balanceAmount;  // Remaining unpaid balance
  final String? notes;
  final List<InvoiceItem> items;

  Invoice({
    this.id,
    this.invoiceType = 'TAX INVOICE',
    required this.invoiceNumber,
    this.poNumber,
    this.challanNumber,
    this.deliveryDate,
    this.vehicleNumber,
    this.transportMode,
    this.customerId,
    this.customerName,
    this.customerGstin,
    this.customerStateCode,
    this.customerAddress,
    this.shippingCustomerName,
    this.shippingAddress,
    this.shippingGstin,
    this.shippingStateCode,
    required this.date,
    this.dueDate,
    this.paymentDate,
    this.status = 'Unpaid',
    this.subtotal = 0.0,
    this.loadingCharges = 0.0,
    this.transportCharges = 0.0,
    this.taxableBase = 0.0,
    this.gstRate = 18.0,
    this.cgstTotal = 0.0,
    this.sgstTotal = 0.0,
    this.igstTotal = 0.0,
    this.totalTax = 0.0,
    this.discountAmount = 0.0,
    this.roundOff = 0.0,
    required this.grandTotal,
    double? receivedAmount,
    double? balanceAmount,
    this.notes,
    this.items = const [],
  })  : receivedAmount = receivedAmount ?? (status == 'Paid' ? grandTotal : 0.0),
        balanceAmount = balanceAmount ?? (status == 'Paid' ? 0.0 : (grandTotal - (receivedAmount ?? 0.0)));

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'invoice_type': invoiceType,
      'invoice_number': invoiceNumber,
      'po_number': poNumber,
      'challan_number': challanNumber,
      'delivery_date': deliveryDate,
      'vehicle_number': vehicleNumber,
      'transport_mode': transportMode,
      'customer_id': customerId,
      'customer_name': customerName,
      'customer_gstin': customerGstin,
      'customer_state_code': customerStateCode,
      'customer_address': customerAddress,
      'shipping_customer_name': shippingCustomerName,
      'shipping_address': shippingAddress,
      'shipping_gstin': shippingGstin,
      'shipping_state_code': shippingStateCode,
      'date': date,
      'due_date': dueDate,
      'payment_date': paymentDate,
      'status': status,
      'subtotal': subtotal,
      'loading_charges': loadingCharges,
      'transport_charges': transportCharges,
      'taxable_base': taxableBase,
      'gst_rate': gstRate,
      'cgst_total': cgstTotal,
      'sgst_total': sgstTotal,
      'igst_total': igstTotal,
      'total_tax': totalTax,
      'discount_amount': discountAmount,
      'round_off': roundOff,
      'grand_total': grandTotal,
      'received_amount': receivedAmount,
      'balance_amount': balanceAmount,
      'notes': notes,
    };
  }

  factory Invoice.fromMap(Map<String, dynamic> map, {List<InvoiceItem> items = const []}) {
    final status = map['status'] ?? 'Unpaid';
    final grandTotal = (map['grand_total'] as num?)?.toDouble() ?? 0.0;
    final received = (map['received_amount'] as num?)?.toDouble() ?? (status == 'Paid' ? grandTotal : 0.0);
    final balance = (map['balance_amount'] as num?)?.toDouble() ?? (grandTotal - received);

    return Invoice(
      id: map['id'] as int?,
      invoiceType: map['invoice_type'] ?? 'TAX INVOICE',
      invoiceNumber: map['invoice_number'] ?? '',
      poNumber: map['po_number'],
      challanNumber: map['challan_number'],
      deliveryDate: map['delivery_date'],
      vehicleNumber: map['vehicle_number'],
      transportMode: map['transport_mode'],
      customerId: map['customer_id'] as int?,
      customerName: map['customer_name'],
      customerGstin: map['customer_gstin'],
      customerStateCode: map['customer_state_code'],
      customerAddress: map['customer_address'],
      shippingCustomerName: map['shipping_customer_name'],
      shippingAddress: map['shipping_address'],
      shippingGstin: map['shipping_gstin'],
      shippingStateCode: map['shipping_state_code'],
      date: map['date'] ?? '',
      dueDate: map['due_date'],
      paymentDate: map['payment_date'],
      status: status,
      subtotal: (map['subtotal'] as num?)?.toDouble() ?? 0.0,
      loadingCharges: (map['loading_charges'] as num?)?.toDouble() ?? 0.0,
      transportCharges: (map['transport_charges'] as num?)?.toDouble() ?? 0.0,
      taxableBase: (map['taxable_base'] as num?)?.toDouble() ?? 0.0,
      gstRate: (map['gst_rate'] as num?)?.toDouble() ?? 18.0,
      cgstTotal: (map['cgst_total'] as num?)?.toDouble() ?? 0.0,
      sgstTotal: (map['sgst_total'] as num?)?.toDouble() ?? 0.0,
      igstTotal: (map['igst_total'] as num?)?.toDouble() ?? 0.0,
      totalTax: (map['total_tax'] as num?)?.toDouble() ?? 0.0,
      discountAmount: (map['discount_amount'] as num?)?.toDouble() ?? 0.0,
      roundOff: (map['round_off'] as num?)?.toDouble() ?? 0.0,
      grandTotal: grandTotal,
      receivedAmount: received,
      balanceAmount: balance,
      notes: map['notes'],
      items: items,
    );
  }
}
