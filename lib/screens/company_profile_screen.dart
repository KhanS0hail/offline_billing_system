import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:provider/provider.dart';
import '../providers/company_provider.dart';
import '../models/company.dart';
import 'backup_screen.dart';

class CompanyProfileScreen extends StatefulWidget {
  const CompanyProfileScreen({super.key});

  @override
  State<CompanyProfileScreen> createState() => _CompanyProfileScreenState();
}

class _CompanyProfileScreenState extends State<CompanyProfileScreen> {
  final _formKey = GlobalKey<FormState>();

  late TextEditingController _nameController;
  late TextEditingController _taglineController;
  late TextEditingController _phoneController;
  late TextEditingController _emailController;
  late TextEditingController _addressController;
  late TextEditingController _gstController;
  late TextEditingController _stateCodeController;

  late TextEditingController _bankNameController;
  late TextEditingController _accountNoController;
  late TextEditingController _ifscController;
  late TextEditingController _branchController;
  late TextEditingController _upiIdController;
  late TextEditingController _paymentDurationController;

  // Itemized List of Terms & Conditions
  List<TextEditingController> _tcControllers = [];

  String? _logoBase64;
  String? _signatureBase64;

  final ImagePicker _picker = ImagePicker();
  int? _lastLoadedCompanyId;
  bool _hasPopulatedFromProvider = false;

  @override
  void initState() {
    super.initState();
    _initBlankControllers();
  }

  void _initBlankControllers() {
    _nameController = TextEditingController();
    _taglineController = TextEditingController();
    _phoneController = TextEditingController();
    _emailController = TextEditingController();
    _addressController = TextEditingController();
    _gstController = TextEditingController();
    _stateCodeController = TextEditingController();

    _bankNameController = TextEditingController();
    _accountNoController = TextEditingController();
    _ifscController = TextEditingController();
    _branchController = TextEditingController();
    _upiIdController = TextEditingController();
    _paymentDurationController = TextEditingController(text: '15');

    _tcControllers = [
      TextEditingController(text: 'Subject to Mumbai jurisdiction.'),
      TextEditingController(text: 'Goods once sold will not be taken back.'),
      TextEditingController(text: 'Our responsibility ceases as soon as the goods leave our premises.'),
      TextEditingController(text: 'Interest @ 24% P.A. will be charged on all overdue payments.'),
    ];
  }

  void _populateFromCompany(Company? comp) {
    if (comp == null) return;

    _nameController.text = comp.name ?? '';
    _taglineController.text = comp.tagline ?? '';
    _phoneController.text = comp.phone ?? '';
    _emailController.text = comp.email ?? '';
    _addressController.text = comp.address ?? '';
    _gstController.text = comp.gstNumber ?? '';
    _stateCodeController.text = comp.stateCode ?? '';

    _bankNameController.text = comp.bankName ?? '';
    _accountNoController.text = comp.accountNumber ?? '';
    _ifscController.text = comp.ifscCode ?? '';
    _branchController.text = comp.bankBranch ?? '';
    _upiIdController.text = comp.upiId ?? '';
    _paymentDurationController.text = comp.paymentDurationDays.toString();

    _logoBase64 = comp.logoBase64;
    _signatureBase64 = comp.signatureBase64;

    // Parse T&C items into list of controllers
    for (var c in _tcControllers) {
      c.dispose();
    }
    _tcControllers = [];

    if (comp.termsAndConditions != null && comp.termsAndConditions!.trim().isNotEmpty) {
      final lines = comp.termsAndConditions!.trim().split('\n');
      for (var l in lines) {
        final trimmed = l.trim().replaceFirst(RegExp(r'^\d+[\.\)\]]\s*'), '');
        if (trimmed.isNotEmpty) {
          _tcControllers.add(TextEditingController(text: trimmed));
        }
      }
    }

    if (_tcControllers.isEmpty) {
      _tcControllers = [
        TextEditingController(text: 'Subject to Mumbai jurisdiction.'),
        TextEditingController(text: 'Goods once sold will not be taken back.'),
        TextEditingController(text: 'Our responsibility ceases as soon as the goods leave our premises.'),
        TextEditingController(text: 'Interest @ 24% P.A. will be charged on all overdue payments.'),
      ];
    }
    _lastLoadedCompanyId = comp.id;
    _hasPopulatedFromProvider = true;
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final provider = Provider.of<CompanyProvider>(context);
    final comp = provider.company;
    if (comp != null && (!_hasPopulatedFromProvider || comp.id != _lastLoadedCompanyId)) {
      _populateFromCompany(comp);
    }
  }

  @override
  void dispose() {
    _nameController.dispose();
    _taglineController.dispose();
    _phoneController.dispose();
    _emailController.dispose();
    _addressController.dispose();
    _gstController.dispose();
    _stateCodeController.dispose();
    _bankNameController.dispose();
    _accountNoController.dispose();
    _ifscController.dispose();
    _branchController.dispose();
    _upiIdController.dispose();
    _paymentDurationController.dispose();
    for (var c in _tcControllers) {
      c.dispose();
    }
    super.dispose();
  }

  void _addTcItem() {
    setState(() {
      _tcControllers.add(TextEditingController());
    });
  }

  void _removeTcItem(int index) {
    setState(() {
      _tcControllers[index].dispose();
      _tcControllers.removeAt(index);
    });
  }

  Future<void> _pickImage({required bool isLogo}) async {
    try {
      final XFile? image = await _picker.pickImage(
        source: ImageSource.gallery,
        maxWidth: 800,
        maxHeight: 800,
        imageQuality: 85,
      );

      if (image != null) {
        final bytes = await image.readAsBytes();
        final base64String = base64Encode(bytes);
        setState(() {
          if (isLogo) {
            _logoBase64 = base64String;
          } else {
            _signatureBase64 = base64String;
          }
        });
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to pick image: $e')),
        );
      }
    }
  }

  void _saveProfile() async {
    if (_formKey.currentState!.validate()) {
      // Check for at least 1 T&C clause
      final validTc = _tcControllers
          .map((c) => c.text.trim())
          .where((t) => t.isNotEmpty)
          .toList();

      if (validTc.isEmpty) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Please add at least 1 Terms & Conditions clause.'),
            backgroundColor: Colors.red,
          ),
        );
        return;
      }

      final provider = Provider.of<CompanyProvider>(context, listen: false);
      final tcString = validTc.join('\n');

      final updatedCompany = Company(
        id: provider.company?.id,
        name: _nameController.text.trim(),
        tagline: _taglineController.text.trim(),
        phone: _phoneController.text.trim(),
        email: _emailController.text.trim(),
        address: _addressController.text.trim(),
        gstNumber: _gstController.text.trim(),
        stateCode: _stateCodeController.text.trim(),
        bankName: _bankNameController.text.trim(),
        accountNumber: _accountNoController.text.trim(),
        ifscCode: _ifscController.text.trim(),
        bankBranch: _branchController.text.trim(),
        upiId: _upiIdController.text.trim(),
        paymentDurationDays: int.tryParse(_paymentDurationController.text.trim()) ?? 15,
        termsAndConditions: tcString,
        logoBase64: _logoBase64,
        signatureBase64: _signatureBase64,
      );

      await provider.saveCompany(updatedCompany);
      _populateFromCompany(updatedCompany);

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Company details, T&C list & images saved successfully!'),
            backgroundColor: Colors.green,
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Company Profile & Settings'),
        actions: [
          IconButton(
            icon: const Icon(Icons.save_rounded),
            onPressed: _saveProfile,
            tooltip: 'Save Profile',
          ),
        ],
      ),
      body: Consumer<CompanyProvider>(
        builder: (context, provider, child) {
          if (provider.isLoading && !_hasPopulatedFromProvider) {
            return const Center(child: CircularProgressIndicator());
          }

          return SingleChildScrollView(
            padding: const EdgeInsets.all(16.0),
            child: Form(
              key: _formKey,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _buildSectionHeader(Icons.business_rounded, "General Information"),
                  const SizedBox(height: 12),
                  
                  // Company Logo Picker Widget
                  _buildImagePickerCard(
                    title: 'Company Logo',
                    subtitle: 'Appears at top of invoices',
                    base64Data: _logoBase64,
                    icon: Icons.storefront_rounded,
                    onPick: () => _pickImage(isLogo: true),
                    onRemove: () => setState(() => _logoBase64 = null),
                  ),
                  const SizedBox(height: 16),

                  _buildTextField(_nameController, 'Business / Company Name', Icons.store, isRequired: true),
                  const SizedBox(height: 12),
                  _buildTextField(_taglineController, 'Tagline / Slogan', Icons.subtitles),
                  const SizedBox(height: 12),
                  Row(
                    children: [
                      Expanded(
                        child: _buildTextField(
                          _phoneController,
                          'Phone Number',
                          Icons.phone,
                          keyboardType: TextInputType.phone,
                          validator: (v) {
                            if (v != null && v.trim().isNotEmpty) {
                              final clean = v.trim().replaceAll(RegExp(r'[\s\-\+\(\)]'), '');
                              if (clean.length < 10 || clean.length > 12 || int.tryParse(clean) == null) {
                                return 'Enter valid 10-digit phone number';
                              }
                            }
                            return null;
                          },
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: _buildTextField(
                          _emailController,
                          'Email Address',
                          Icons.email,
                          keyboardType: TextInputType.emailAddress,
                          validator: (v) {
                            if (v != null && v.trim().isNotEmpty) {
                              final emailRegex = RegExp(r'^[\w-\.]+@([\w-]+\.)+[\w-]{2,4}$');
                              if (!emailRegex.hasMatch(v.trim())) {
                                return 'Enter valid email (e.g. name@domain.com)';
                              }
                            }
                            return null;
                          },
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  _buildTextField(_addressController, 'Full Business Address', Icons.location_on, maxLines: 2, isRequired: true),
                  const SizedBox(height: 12),
                  Row(
                    children: [
                      Expanded(
                        child: _buildTextField(
                          _gstController,
                          'GSTIN Number',
                          Icons.verified,
                          isRequired: true,
                          validator: (v) {
                            if (v == null || v.trim().isEmpty) return 'GSTIN Number is required';
                            final clean = v.trim().toUpperCase();
                            final gstRegex = RegExp(r'^[0-9]{2}[A-Z]{5}[0-9]{4}[A-Z]{1}[1-9A-Z]{1}Z[0-9A-Z]{1}$');
                            if (!gstRegex.hasMatch(clean)) {
                              return 'Enter valid 15-digit GSTIN (e.g. 27AAAAA0000A1Z5)';
                            }
                            return null;
                          },
                          onChanged: (v) {
                            final clean = v.trim().toUpperCase();
                            if (clean.length >= 2) {
                              final prefix = clean.substring(0, 2);
                              final codeNum = int.tryParse(prefix);
                              if (codeNum != null && ((codeNum >= 1 && codeNum <= 37) || codeNum == 97)) {
                                if (_stateCodeController.text.trim() != prefix) {
                                  setState(() {
                                    _stateCodeController.text = prefix;
                                  });
                                }
                              }
                            }
                          },
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: _buildTextField(
                          _stateCodeController,
                          'State Code (e.g. 27)',
                          Icons.map,
                          isRequired: true,
                          keyboardType: TextInputType.number,
                          validator: (v) {
                            if (v == null || v.trim().isEmpty) return 'State Code is required';
                            final code = int.tryParse(v.trim());
                            if (code == null || (code < 1 || (code > 37 && code != 97))) {
                              return 'Enter valid 2-digit State Code (01-37)';
                            }
                            return null;
                          },
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 24),
                  
                  _buildSectionHeader(Icons.account_balance_rounded, "Bank & Payment Details"),
                  const SizedBox(height: 12),
                  Row(
                    children: [
                      Expanded(child: _buildTextField(_bankNameController, 'Bank Name', Icons.account_balance, isRequired: true)),
                      const SizedBox(width: 12),
                      Expanded(child: _buildTextField(_branchController, 'Bank Branch', Icons.location_city, isRequired: true)),
                    ],
                  ),
                  const SizedBox(height: 12),
                  Row(
                    children: [
                      Expanded(
                        child: _buildTextField(
                          _accountNoController,
                          'Account Number',
                          Icons.numbers,
                          isRequired: true,
                          validator: (v) {
                            if (v == null || v.trim().isEmpty) return 'Account Number is required';
                            final clean = v.trim();
                            if (clean.length < 8 || clean.length > 20) {
                              return 'Account number must be 8-20 digits';
                            }
                            return null;
                          },
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: _buildTextField(
                          _ifscController,
                          'IFSC Code',
                          Icons.code,
                          isRequired: true,
                          validator: (v) {
                            if (v == null || v.trim().isEmpty) return 'IFSC Code is required';
                            final clean = v.trim().toUpperCase();
                            final ifscRegex = RegExp(r'^[A-Z]{4}0[A-Z0-9]{6}$');
                            if (!ifscRegex.hasMatch(clean)) {
                              return 'Enter valid 11-char IFSC code (e.g. SBIN0001234)';
                            }
                            return null;
                          },
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  Row(
                    children: [
                      Expanded(
                        child: _buildTextField(
                          _upiIdController,
                          'UPI ID',
                          Icons.qr_code_2,
                          validator: (v) {
                            if (v != null && v.trim().isNotEmpty) {
                              final upiRegex = RegExp(r'^[a-zA-Z0-9.\-_]{2,256}@[a-zA-Z]{2,64}$');
                              if (!upiRegex.hasMatch(v.trim())) {
                                return 'Enter valid UPI ID (e.g. name@upi)';
                              }
                            }
                            return null;
                          },
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: _buildTextField(
                          _paymentDurationController,
                          'Default Payment Terms (Days)',
                          Icons.timer,
                          keyboardType: TextInputType.number,
                          validator: (v) {
                            if (v == null || v.trim().isEmpty) return 'Payment terms days is required';
                            final days = int.tryParse(v.trim());
                            if (days == null || days < 1 || days > 365) {
                              return 'Enter valid days (1 to 365)';
                            }
                            return null;
                          },
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 24),

                  // ITEMAZE TERMS & CONDITIONS SECTION
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      _buildSectionHeader(Icons.gavel_rounded, "Terms & Conditions"),
                      TextButton.icon(
                        onPressed: _addTcItem,
                        icon: const Icon(Icons.add_circle_outline, size: 18),
                        label: const Text('+ Add Clause'),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Card(
                    elevation: 0,
                    shape: RoundedRectangleBorder(
                      side: BorderSide(color: Theme.of(context).colorScheme.outlineVariant),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Padding(
                      padding: const EdgeInsets.all(12.0),
                      child: Column(
                        children: [
                          ..._tcControllers.asMap().entries.map((entry) {
                            final idx = entry.key;
                            final controller = entry.value;
                            return Padding(
                              padding: const EdgeInsets.only(bottom: 8.0),
                              child: Row(
                                children: [
                                  CircleAvatar(
                                    radius: 12,
                                    backgroundColor: Theme.of(context).colorScheme.primaryContainer,
                                    child: Text(
                                      '${idx + 1}',
                                      style: TextStyle(
                                        fontSize: 11,
                                        fontWeight: FontWeight.bold,
                                        color: Theme.of(context).colorScheme.onPrimaryContainer,
                                      ),
                                    ),
                                  ),
                                  const SizedBox(width: 8),
                                  Expanded(
                                    child: TextFormField(
                                      controller: controller,
                                      decoration: InputDecoration(
                                        hintText: 'Enter term/clause condition...',
                                        isDense: true,
                                        contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                                        border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
                                      ),
                                    ),
                                  ),
                                  IconButton(
                                    icon: const Icon(Icons.delete_outline, color: Colors.red, size: 20),
                                    onPressed: () => _removeTcItem(idx),
                                    tooltip: 'Delete clause',
                                  ),
                                ],
                              ),
                            );
                          }),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 24),

                  _buildSectionHeader(Icons.draw_rounded, "Digital Signature / Stamp"),
                  const SizedBox(height: 12),
                  _buildImagePickerCard(
                    title: 'Digital Signature / Stamp',
                    subtitle: 'Appears at bottom of invoices',
                    base64Data: _signatureBase64,
                    icon: Icons.draw_rounded,
                    onPick: () => _pickImage(isLogo: false),
                    onRemove: () => setState(() => _signatureBase64 = null),
                  ),
                  const SizedBox(height: 24),

                  _buildSectionHeader(Icons.security_rounded, "Database Backup & Security"),
                  const SizedBox(height: 12),
                  Card(
                    elevation: 0,
                    shape: RoundedRectangleBorder(
                      side: BorderSide(color: Theme.of(context).colorScheme.outlineVariant),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: ListTile(
                      leading: const CircleAvatar(
                        child: Icon(Icons.shield_outlined),
                      ),
                      title: const Text('Database Backup & PIN Lock', style: TextStyle(fontWeight: FontWeight.bold)),
                      subtitle: const Text('Export, import & share offline database backup and manage PIN lock'),
                      trailing: const Icon(Icons.chevron_right),
                      onTap: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(builder: (_) => const BackupScreen()),
                        );
                      },
                    ),
                  ),
                  const SizedBox(height: 32),

                  SizedBox(
                    width: double.infinity,
                    height: 50,
                    child: ElevatedButton.icon(
                      onPressed: _saveProfile,
                      icon: const Icon(Icons.check_circle_rounded),
                      label: const Text('Save Business Profile', style: TextStyle(fontSize: 16)),
                    ),
                  ),
                  const SizedBox(height: 40),
                ],
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _buildSectionHeader(IconData icon, String title) {
    return Row(
      children: [
        Icon(icon, color: Theme.of(context).colorScheme.primary),
        const SizedBox(width: 8),
        Text(
          title,
          style: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.bold,
            color: Theme.of(context).colorScheme.primary,
          ),
        ),
      ],
    );
  }

  Widget _buildImagePickerCard({
    required String title,
    required String subtitle,
    required String? base64Data,
    required IconData icon,
    required VoidCallback onPick,
    required VoidCallback onRemove,
  }) {
    final hasImage = base64Data != null && base64Data.isNotEmpty;

    return Card(
      elevation: 0,
      shape: RoundedRectangleBorder(
        side: BorderSide(color: Theme.of(context).colorScheme.outlineVariant),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Padding(
        padding: const EdgeInsets.all(12.0),
        child: Row(
          children: [
            Container(
              width: 70,
              height: 70,
              decoration: BoxDecoration(
                color: Theme.of(context).colorScheme.surfaceVariant,
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: Colors.grey.shade300),
              ),
              child: hasImage
                  ? ClipRRect(
                      borderRadius: BorderRadius.circular(8),
                      child: Image.memory(
                        base64Decode(base64Data),
                        fit: BoxFit.contain,
                        errorBuilder: (_, __, ___) => Icon(icon, size: 32),
                      ),
                    )
                  : Icon(icon, size: 32, color: Colors.grey),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15),
                  ),
                  Text(
                    subtitle,
                    style: TextStyle(fontSize: 12, color: Colors.grey.shade600),
                  ),
                  const SizedBox(height: 8),
                  Row(
                    children: [
                      OutlinedButton.icon(
                        onPressed: onPick,
                        icon: const Icon(Icons.upload_file, size: 16),
                        label: Text(hasImage ? 'Change' : 'Upload'),
                        style: OutlinedButton.styleFrom(
                          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                          visualDensity: VisualDensity.compact,
                        ),
                      ),
                      if (hasImage) ...[
                        const SizedBox(width: 8),
                        IconButton(
                          icon: const Icon(Icons.delete_outline, color: Colors.red, size: 20),
                          onPressed: onRemove,
                          tooltip: 'Remove',
                        ),
                      ]
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTextField(
    TextEditingController controller,
    String label,
    IconData icon, {
    TextInputType keyboardType = TextInputType.text,
    int maxLines = 1,
    bool isRequired = false,
    String? Function(String?)? validator,
    ValueChanged<String>? onChanged,
  }) {
    return TextFormField(
      controller: controller,
      keyboardType: keyboardType,
      maxLines: maxLines,
      onChanged: onChanged,
      validator: validator ??
          (isRequired
              ? (value) {
                  if (value == null || value.trim().isEmpty) {
                    return '$label is required';
                  }
                  return null;
                }
              : null),
      decoration: InputDecoration(
        labelText: isRequired ? '$label *' : label,
        prefixIcon: Icon(icon),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
        ),
      ),
    );
  }
}
