class Company {
  final int? id;
  final String name;
  final String? tagline;
  final String? phone;
  final String? email;
  final String? address;
  final String? gstNumber;
  final String? stateCode;
  
  // Bank & Payment Info
  final String? bankName;
  final String? accountNumber;
  final String? ifscCode;
  final String? bankBranch;
  final String? upiId;
  final int paymentDurationDays; // e.g. 15 days default payment due term

  // Branding & Digital Assets
  final String? logoBase64;
  final String? signatureBase64; // Authorized Signature / Stamp PNG
  final String? termsAndConditions;

  Company({
    this.id,
    required this.name,
    this.tagline,
    this.phone,
    this.email,
    this.address,
    this.gstNumber,
    this.stateCode,
    this.bankName,
    this.accountNumber,
    this.ifscCode,
    this.bankBranch,
    this.upiId,
    this.paymentDurationDays = 15,
    this.logoBase64,
    this.signatureBase64,
    this.termsAndConditions,
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'name': name,
      'tagline': tagline,
      'phone': phone,
      'email': email,
      'address': address,
      'gst_number': gstNumber,
      'state_code': stateCode,
      'bank_name': bankName,
      'account_number': accountNumber,
      'ifsc_code': ifscCode,
      'bank_branch': bankBranch,
      'upi_id': upiId,
      'payment_duration_days': paymentDurationDays,
      'logo_base64': logoBase64,
      'signature_base64': signatureBase64,
      'terms_and_conditions': termsAndConditions,
    };
  }

  factory Company.fromMap(Map<String, dynamic> map) {
    return Company(
      id: map['id'] as int?,
      name: map['name'] ?? '',
      tagline: map['tagline'],
      phone: map['phone'],
      email: map['email'],
      address: map['address'],
      gstNumber: map['gst_number'],
      stateCode: map['state_code'],
      bankName: map['bank_name'],
      accountNumber: map['account_number'],
      ifscCode: map['ifsc_code'],
      bankBranch: map['bank_branch'],
      upiId: map['upi_id'],
      paymentDurationDays: map['payment_duration_days'] ?? 15,
      logoBase64: map['logo_base64'],
      signatureBase64: map['signature_base64'],
      termsAndConditions: map['terms_and_conditions'],
    );
  }

  Company copyWith({
    int? id,
    String? name,
    String? tagline,
    String? phone,
    String? email,
    String? address,
    String? gstNumber,
    String? stateCode,
    String? bankName,
    String? accountNumber,
    String? ifscCode,
    String? bankBranch,
    String? upiId,
    int? paymentDurationDays,
    String? logoBase64,
    String? signatureBase64,
    String? termsAndConditions,
  }) {
    return Company(
      id: id ?? this.id,
      name: name ?? this.name,
      tagline: tagline ?? this.tagline,
      phone: phone ?? this.phone,
      email: email ?? this.email,
      address: address ?? this.address,
      gstNumber: gstNumber ?? this.gstNumber,
      stateCode: stateCode ?? this.stateCode,
      bankName: bankName ?? this.bankName,
      accountNumber: accountNumber ?? this.accountNumber,
      ifscCode: ifscCode ?? this.ifscCode,
      bankBranch: bankBranch ?? this.bankBranch,
      upiId: upiId ?? this.upiId,
      paymentDurationDays: paymentDurationDays ?? this.paymentDurationDays,
      logoBase64: logoBase64 ?? this.logoBase64,
      signatureBase64: signatureBase64 ?? this.signatureBase64,
      termsAndConditions: termsAndConditions ?? this.termsAndConditions,
    );
  }
}
