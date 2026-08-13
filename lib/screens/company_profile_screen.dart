import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:provider/provider.dart';
import '../providers/company_provider.dart';
import '../models/company.dart';

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

  late TextEditingController _termsController;

  String? _logoBase64;
  String? _signatureBase64;

  final ImagePicker _picker = ImagePicker();

  @override
  void initState() {
    super.initState();
    _initControllers();
  }

  void _initControllers() {
    final provider = Provider.of<CompanyProvider>(context, listen: false);
    final comp = provider.company;

    _nameController = TextEditingController(text: comp?.name ?? '');
    _taglineController = TextEditingController(text: comp?.tagline ?? '');
    _phoneController = TextEditingController(text: comp?.phone ?? '');
    _emailController = TextEditingController(text: comp?.email ?? '');
    _addressController = TextEditingController(text: comp?.address ?? '');
    _gstController = TextEditingController(text: comp?.gstNumber ?? '');
    _stateCodeController = TextEditingController(text: comp?.stateCode ?? '');

    _bankNameController = TextEditingController(text: comp?.bankName ?? '');
    _accountNoController = TextEditingController(text: comp?.accountNumber ?? '');
    _ifscController = TextEditingController(text: comp?.ifscCode ?? '');
    _branchController = TextEditingController(text: comp?.bankBranch ?? '');
    _upiIdController = TextEditingController(text: comp?.upiId ?? '');
    _paymentDurationController = TextEditingController(text: comp?.paymentDurationDays.toString() ?? '15');

    _termsController = TextEditingController(text: comp?.termsAndConditions ?? '');

    _logoBase64 = comp?.logoBase64;
    _signatureBase64 = comp?.signatureBase64;
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
    _termsController.dispose();
    super.dispose();
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
      final provider = Provider.of<CompanyProvider>(context, listen: false);

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
        termsAndConditions: _termsController.text.trim(),
        logoBase64: _logoBase64,
        signatureBase64: _signatureBase64,
      );

      await provider.saveCompany(updatedCompany);

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Company details & images saved successfully!'),
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
          if (provider.isLoading) {
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

                  _buildTextField(_nameController, 'Business / Company Name', Icons.store),
                  const SizedBox(height: 12),
                  _buildTextField(_taglineController, 'Tagline / Slogan', Icons.subtitles),
                  const SizedBox(height: 12),
                  Row(
                    children: [
                      Expanded(child: _buildTextField(_phoneController, 'Phone Number', Icons.phone, keyboardType: TextInputType.phone)),
                      const SizedBox(width: 12),
                      Expanded(child: _buildTextField(_emailController, 'Email Address', Icons.email, keyboardType: TextInputType.emailAddress)),
                    ],
                  ),
                  const SizedBox(height: 12),
                  _buildTextField(_addressController, 'Full Business Address', Icons.location_on, maxLines: 2),
                  const SizedBox(height: 12),
                  Row(
                    children: [
                      Expanded(child: _buildTextField(_gstController, 'GSTIN Number', Icons.verified)),
                      const SizedBox(width: 12),
                      Expanded(child: _buildTextField(_stateCodeController, 'State Code (e.g. 27)', Icons.map)),
                    ],
                  ),
                  const SizedBox(height: 24),
                  
                  _buildSectionHeader(Icons.account_balance_rounded, "Bank & Payment Details"),
                  const SizedBox(height: 12),
                  Row(
                    children: [
                      Expanded(child: _buildTextField(_bankNameController, 'Bank Name', Icons.account_balance)),
                      const SizedBox(width: 12),
                      Expanded(child: _buildTextField(_branchController, 'Bank Branch', Icons.location_city)),
                    ],
                  ),
                  const SizedBox(height: 12),
                  Row(
                    children: [
                      Expanded(child: _buildTextField(_accountNoController, 'Account Number', Icons.numbers)),
                      const SizedBox(width: 12),
                      Expanded(child: _buildTextField(_ifscController, 'IFSC Code', Icons.code)),
                    ],
                  ),
                  const SizedBox(height: 12),
                  Row(
                    children: [
                      Expanded(child: _buildTextField(_upiIdController, 'UPI ID', Icons.qr_code_2)),
                      const SizedBox(width: 12),
                      Expanded(child: _buildTextField(_paymentDurationController, 'Default Payment Terms (Days)', Icons.timer, keyboardType: TextInputType.number)),
                    ],
                  ),
                  const SizedBox(height: 24),

                  _buildSectionHeader(Icons.gavel_rounded, "Invoice Terms & Signature"),
                  const SizedBox(height: 12),
                  _buildTextField(_termsController, 'Terms & Conditions', Icons.note, maxLines: 3),
                  const SizedBox(height: 16),

                  // Digital Signature / Stamp Picker Widget
                  _buildImagePickerCard(
                    title: 'Digital Signature / Stamp',
                    subtitle: 'Appears at bottom of invoices',
                    base64Data: _signatureBase64,
                    icon: Icons.draw_rounded,
                    onPick: () => _pickImage(isLogo: false),
                    onRemove: () => setState(() => _signatureBase64 = null),
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
  }) {
    return TextFormField(
      controller: controller,
      keyboardType: keyboardType,
      maxLines: maxLines,
      decoration: InputDecoration(
        labelText: label,
        prefixIcon: Icon(icon),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
        ),
      ),
    );
  }
}
