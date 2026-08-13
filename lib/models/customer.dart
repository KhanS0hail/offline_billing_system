class Customer {
  final int? id;
  final String? name;
  final String? contactPerson;
  final String? phone;
  final String? email;
  final String? address;
  final String? gstNumber;
  final String? stateCode;
  final double? openingBalance;

  Customer({
    this.id,
    this.name,
    this.contactPerson,
    this.phone,
    this.email,
    this.address,
    this.gstNumber,
    this.stateCode,
    this.openingBalance = 0.0,
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'name': name,
      'contact_person': contactPerson,
      'phone': phone,
      'email': email,
      'address': address,
      'gst_number': gstNumber,
      'state_code': stateCode,
      'opening_balance': openingBalance,
    };
  }

  factory Customer.fromMap(Map<String, dynamic> map) {
    return Customer(
      id: map['id'] as int?,
      name: map['name'],
      contactPerson: map['contact_person'],
      phone: map['phone'],
      email: map['email'],
      address: map['address'],
      gstNumber: map['gst_number'],
      stateCode: map['state_code'],
      openingBalance: (map['opening_balance'] as num?)?.toDouble(),
    );
  }

  Customer copyWith({
    int? id,
    String? name,
    String? contactPerson,
    String? phone,
    String? email,
    String? address,
    String? gstNumber,
    String? stateCode,
    double? openingBalance,
  }) {
    return Customer(
      id: id ?? this.id,
      name: name ?? this.name,
      contactPerson: contactPerson ?? this.contactPerson,
      phone: phone ?? this.phone,
      email: email ?? this.email,
      address: address ?? this.address,
      gstNumber: gstNumber ?? this.gstNumber,
      stateCode: stateCode ?? this.stateCode,
      openingBalance: openingBalance ?? this.openingBalance,
    );
  }
}
