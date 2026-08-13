class Product {
  final int? id;
  final String? name;
  final String? description;
  final String? hsnCode;
  final String? unit;
  final double? price;
  final double? gstRate;

  Product({
    this.id,
    this.name,
    this.description,
    this.hsnCode,
    this.unit = 'Pcs',
    this.price,
    this.gstRate = 18.0,
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'name': name,
      'description': description,
      'hsn_code': hsnCode,
      'unit': unit,
      'price': price,
      'gst_rate': gstRate,
    };
  }

  factory Product.fromMap(Map<String, dynamic> map) {
    return Product(
      id: map['id'] as int?,
      name: map['name'],
      description: map['description'],
      hsnCode: map['hsn_code'],
      unit: map['unit'],
      price: (map['price'] as num?)?.toDouble(),
      gstRate: (map['gst_rate'] as num?)?.toDouble(),
    );
  }

  Product copyWith({
    int? id,
    String? name,
    String? description,
    String? hsnCode,
    String? unit,
    double? price,
    double? gstRate,
  }) {
    return Product(
      id: id ?? this.id,
      name: name ?? this.name,
      description: description ?? this.description,
      hsnCode: hsnCode ?? this.hsnCode,
      unit: unit ?? this.unit,
      price: price ?? this.price,
      gstRate: gstRate ?? this.gstRate,
    );
  }
}
