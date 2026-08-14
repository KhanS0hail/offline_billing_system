import 'invoice_item.dart';

class Invoice {
  final int? id;
  final String invoiceType; // 'TAX INVOICE' or 'PROFORMA INVOICE'
  final String invoiceNumber;
  final String? challanNumber;
  final int? customerId;
  final String? customerName;
  final String? customerGstin;
  final String? customerStateCode;
  final String? customerAddress;
  final String date;
  final String? dueDate;
  final String status; // 'Unpaid', 'Paid', 'Partially Paid'
  final double subtotal;
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
  final String? notes;
  final List<InvoiceItem> items;

  Invoice({
    this.id,
    this.invoiceType = 'TAX INVOICE',
    required this.invoiceNumber,
    this.challanNumber,
    this.customerId,
    this.customerName,
    this.customerGstin,
    this.customerStateCode,
    this.customerAddress,
    required this.date,
    this.dueDate,
    this.status = 'Unpaid',
    this.subtotal = 0.0,
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
    this.notes,
    this.items = const [],
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'invoice_type': invoiceType,
      'invoice_number': invoiceNumber,
      'challan_number': challanNumber,
      'customer_id': customerId,
      'customer_name': customerName,
      'customer_gstin': customerGstin,
      'customer_state_code': customerStateCode,
      'customer_address': customerAddress,
      'date': date,
      'due_date': dueDate,
      'status': status,
      'subtotal': subtotal,
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
      'notes': notes,
    };
  }

  factory Invoice.fromMap(Map<String, dynamic> map, {List<InvoiceItem> items = const []}) {
    return Invoice(
      id: map['id'] as int?,
      invoiceType: map['invoice_type'] ?? 'TAX INVOICE',
      invoiceNumber: map['invoice_number'] ?? '',
      challanNumber: map['challan_number'],
      customerId: map['customer_id'] as int?,
      customerName: map['customer_name'],
      customerGstin: map['customer_gstin'],
      customerStateCode: map['customer_state_code'],
      customerAddress: map['customer_address'],
      date: map['date'] ?? '',
      dueDate: map['due_date'],
      status: map['status'] ?? 'Unpaid',
      subtotal: (map['subtotal'] as num?)?.toDouble() ?? 0.0,
      transportCharges: (map['transport_charges'] as num?)?.toDouble() ?? 0.0,
      taxableBase: (map['taxable_base'] as num?)?.toDouble() ?? 0.0,
      gstRate: (map['gst_rate'] as num?)?.toDouble() ?? 18.0,
      cgstTotal: (map['cgst_total'] as num?)?.toDouble() ?? 0.0,
      sgstTotal: (map['sgst_total'] as num?)?.toDouble() ?? 0.0,
      igstTotal: (map['igst_total'] as num?)?.toDouble() ?? 0.0,
      totalTax: (map['total_tax'] as num?)?.toDouble() ?? 0.0,
      discountAmount: (map['discount_amount'] as num?)?.toDouble() ?? 0.0,
      roundOff: (map['round_off'] as num?)?.toDouble() ?? 0.0,
      grandTotal: (map['grand_total'] as num?)?.toDouble() ?? 0.0,
      notes: map['notes'],
      items: items,
    );
  }
}
