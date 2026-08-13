import 'package:flutter/material.dart';
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
        logoBase64: provider.company?.logoBase64,
        signatureBase64: provider.company?.signatureBase64,
      );

      await provider.saveCompany(updatedCompany);

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Company details saved successfully!'),
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

                  _buildSectionHeader(Icons.gavel_rounded, "Invoice Terms & Notes"),
                  const SizedBox(height: 12),
                  _buildTextField(_termsController, 'Terms & Conditions', Icons.note, maxLines: 3),
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
