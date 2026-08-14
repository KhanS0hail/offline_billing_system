class InvoiceItem {
  final int? id;
  final int? invoiceId;
  final int? productId;
  final String productName;
  final String? size;
  final String? pcsCount; // e.g. "10 Pcs", "2 BDL", "5 Nag"
  final String? hsnCode;
  final int quantity;
  final String unit;
  final double price;
  final double amount; // quantity * price

  InvoiceItem({
    this.id,
    this.invoiceId,
    this.productId,
    required this.productName,
    this.size,
    this.pcsCount,
    this.hsnCode,
    this.quantity = 1,
    this.unit = 'Pcs',
    required this.price,
    double? amount,
  }) : amount = amount ?? (quantity * price);

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'invoice_id': invoiceId,
      'product_id': productId,
      'product_name': productName,
      'size': size,
      'pcs_count': pcsCount,
      'hsn_code': hsnCode,
      'quantity': quantity,
      'unit': unit,
      'price': price,
      'amount': amount,
    };
  }

  factory InvoiceItem.fromMap(Map<String, dynamic> map) {
    return InvoiceItem(
      id: map['id'] as int?,
      invoiceId: map['invoice_id'] as int?,
      productId: map['product_id'] as int?,
      productName: map['product_name'] ?? '',
      size: map['size'],
      pcsCount: map['pcs_count'],
      hsnCode: map['hsn_code'],
      quantity: (map['quantity'] as num?)?.toInt() ?? 1,
      unit: map['unit'] ?? 'Pcs',
      price: (map['price'] as num?)?.toDouble() ?? 0.0,
      amount: (map['amount'] as num?)?.toDouble(),
    );
  }

  InvoiceItem copyWith({
    int? id,
    int? invoiceId,
    int? productId,
    String? productName,
    String? size,
    String? pcsCount,
    String? hsnCode,
    int? quantity,
    String? unit,
    double? price,
    double? amount,
  }) {
    return InvoiceItem(
      id: id ?? this.id,
      invoiceId: invoiceId ?? this.invoiceId,
      productId: productId ?? this.productId,
      productName: productName ?? this.productName,
      size: size ?? this.size,
      pcsCount: pcsCount ?? this.pcsCount,
      hsnCode: hsnCode ?? this.hsnCode,
      quantity: quantity ?? this.quantity,
      unit: unit ?? this.unit,
      price: price ?? this.price,
      amount: amount ?? this.amount,
    );
  }
}
