class CustomerPayment {
  final int? id;
  final String receiptNumber;
  final int customerId;
  final String? customerName;
  final String? companyName;
  final String paymentDate;
  final double amount;
  final String? paymentMode;
  final String? referenceNote;
  final String? notes;

  CustomerPayment({
    this.id,
    required this.receiptNumber,
    required this.customerId,
    this.customerName,
    this.companyName,
    required this.paymentDate,
    required this.amount,
    this.paymentMode,
    this.referenceNote,
    this.notes,
  });

  Map<String, dynamic> toMap() {
    return {
      if (id != null) 'id': id,
      'receipt_number': receiptNumber,
      'customer_id': customerId,
      'customer_name': customerName,
      'company_name': companyName,
      'payment_date': paymentDate,
      'amount': amount,
      'payment_mode': paymentMode,
      'reference_note': referenceNote,
      'notes': notes,
    };
  }

  factory CustomerPayment.fromMap(Map<String, dynamic> map) {
    return CustomerPayment(
      id: map['id'] as int?,
      receiptNumber: map['receipt_number'] as String? ?? '',
      customerId: map['customer_id'] as int? ?? 0,
      customerName: map['customer_name'] as String?,
      companyName: map['company_name'] as String?,
      paymentDate: map['payment_date'] as String? ?? '',
      amount: (map['amount'] as num?)?.toDouble() ?? 0.0,
      paymentMode: map['payment_mode'] as String?,
      referenceNote: map['reference_note'] as String?,
      notes: map['notes'] as String?,
    );
  }
}
