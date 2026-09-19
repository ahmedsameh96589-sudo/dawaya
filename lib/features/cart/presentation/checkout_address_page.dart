import 'package:flutter/material.dart';

import '../../../core/theme/app_colors.dart';
import '../models/checkout_address.dart';
import 'payment_page.dart';

class CheckoutAddressPage extends StatefulWidget {
  const CheckoutAddressPage({super.key});

  @override
  State<CheckoutAddressPage> createState() => _CheckoutAddressPageState();
}

class _CheckoutAddressPageState extends State<CheckoutAddressPage> {
  final _formKey = GlobalKey<FormState>();
  final TextEditingController firstNameController = TextEditingController();
  final TextEditingController lastNameController = TextEditingController();
  final TextEditingController phoneController = TextEditingController();
  final TextEditingController emailController = TextEditingController();
  final TextEditingController addressController = TextEditingController();
  String _selectedLabel = 'Home';

  @override
  void dispose() {
    firstNameController.dispose();
    lastNameController.dispose();
    phoneController.dispose();
    emailController.dispose();
    addressController.dispose();
    super.dispose();
  }

  void _submit() {
    if (!_formKey.currentState!.validate()) return;
    final address = CheckoutAddress(
      label: _selectedLabel,
      street: addressController.text.trim(),
      city: 'Cairo',
    );
    Navigator.of(context).push(
      MaterialPageRoute<void>(
        builder: (_) => PaymentPage(address: address),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.white,
        foregroundColor: Colors.black,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new),
          onPressed: () => Navigator.of(context).pop(),
        ),
        title: const Text('Address'),
      ),
      body: Padding(
        padding: const EdgeInsets.fromLTRB(20, 12, 20, 24),
        child: Form(
          key: _formKey,
          child: Column(
            children: <Widget>[
              _InputField(
                label: 'First Name',
                controller: firstNameController,
                validator: (value) =>
                    value!.trim().isEmpty ? 'First name is required' : null,
              ),
              const SizedBox(height: 12),
              _InputField(
                label: 'Last Name',
                controller: lastNameController,
                validator: (value) =>
                    value!.trim().isEmpty ? 'Last name is required' : null,
              ),
              const SizedBox(height: 12),
              _InputField(
                label: 'Phone Number',
                controller: phoneController,
                keyboardType: TextInputType.phone,
                validator: (value) =>
                    value!.trim().isEmpty ? 'Phone number is required' : null,
              ),
              const SizedBox(height: 12),
              _InputField(
                label: 'Email',
                controller: emailController,
                keyboardType: TextInputType.emailAddress,
                validator: (value) =>
                    value!.trim().isEmpty ? 'Email is required' : null,
              ),
              const SizedBox(height: 12),
              Row(
                children: <Widget>[
                  _ChoiceChip(
                    label: 'Home',
                    isActive: _selectedLabel == 'Home',
                    onTap: () => setState(() => _selectedLabel = 'Home'),
                  ),
                  const SizedBox(width: 8),
                  _ChoiceChip(
                    label: 'Office',
                    isActive: _selectedLabel == 'Office',
                    onTap: () => setState(() => _selectedLabel = 'Office'),
                  ),
                  const SizedBox(width: 8),
                  _ChoiceChip(
                    label: 'Other',
                    isActive: _selectedLabel == 'Other',
                    onTap: () => setState(() => _selectedLabel = 'Other'),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              _InputField(
                label: 'Address Details',
                controller: addressController,
                validator: (value) =>
                    value!.trim().isEmpty ? 'Address is required' : null,
              ),
              const Spacer(),
              SizedBox(
                width: 160,
                child: ElevatedButton(
                  onPressed: _submit,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.brandBlue,
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(18),
                    ),
                  ),
                  child: const Text('Next'),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _InputField extends StatelessWidget {
  const _InputField({
    required this.label,
    required this.controller,
    this.keyboardType = TextInputType.text,
    this.validator,
  });

  final String label;
  final TextEditingController controller;
  final TextInputType keyboardType;
  final String? Function(String?)? validator;

  @override
  Widget build(BuildContext context) {
    return TextFormField(
      controller: controller,
      keyboardType: keyboardType,
      validator: validator,
      decoration: InputDecoration(
        hintText: label,
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(18),
          borderSide: BorderSide(color: Colors.grey.shade300),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(18),
          borderSide: BorderSide(color: Colors.grey.shade300),
        ),
      ),
    );
  }
}

class _ChoiceChip extends StatelessWidget {
  const _ChoiceChip({
    required this.label,
    this.isActive = false,
    this.onTap,
  });

  final String label;
  final bool isActive;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(16),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        decoration: BoxDecoration(
          color: isActive ? AppColors.brandBlue : Colors.white,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: Colors.grey.shade300),
        ),
        child: Text(
          label,
          style: TextStyle(
            color: isActive ? Colors.white : Colors.black87,
            fontSize: 12,
            fontWeight: FontWeight.w600,
          ),
        ),
      ),
    );
  }
}
