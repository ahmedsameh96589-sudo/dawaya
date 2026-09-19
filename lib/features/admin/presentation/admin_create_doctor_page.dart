import 'package:flutter/material.dart';
import '../data/admin_repository.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';


class AdminCreateDoctorPage extends ConsumerStatefulWidget {
  const AdminCreateDoctorPage({super.key});

  @override
  ConsumerState<AdminCreateDoctorPage> createState() => _AdminCreateDoctorPageState();
}

class _AdminCreateDoctorPageState extends ConsumerState<AdminCreateDoctorPage> {
  final _formKey = GlobalKey<FormState>();
  final TextEditingController nameController = TextEditingController();
  final TextEditingController emailController = TextEditingController();
  final TextEditingController phoneController = TextEditingController();
  final TextEditingController passwordController = TextEditingController();
  final TextEditingController specialtyController = TextEditingController();
  final TextEditingController experienceController = TextEditingController();

  bool isLoading = false;

  Future<void> _createDoctor() async {
    if (!_formKey.currentState!.validate()) return;

    final experience = int.tryParse(experienceController.text.trim()) ?? 0;

    setState(() => isLoading = true);
    try {
      await ref.read(adminRepositoryProvider).createDoctor(
        name: nameController.text.trim(),
        email: emailController.text.trim(),
        phone: phoneController.text.trim(),
        password: passwordController.text,
        specialty: specialtyController.text.trim(),
        experience: experience,
      );

      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Doctor created successfully')),
      );
      _formKey.currentState?.reset();
      nameController.clear();
      emailController.clear();
      phoneController.clear();
      passwordController.clear();
      specialtyController.clear();
      experienceController.clear();
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(e.toString())),
      );
    } finally {
      if (mounted) setState(() => isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Create Doctor'),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Form(
          key: _formKey,
          child: Column(
            children: [
              _field(
                controller: nameController,
                label: 'Name',
                validator: (v) =>
                    v!.isEmpty ? 'Doctor name is required' : null,
              ),
              const SizedBox(height: 12),
              _field(
                controller: emailController,
                label: 'Email',
                keyboardType: TextInputType.emailAddress,
                validator: (v) {
                  if (v!.isEmpty) return 'Email is required';
                  if (!v.contains('@')) return 'Invalid email';
                  return null;
                },
              ),
              const SizedBox(height: 12),
              _field(
                controller: phoneController,
                label: 'Phone',
                keyboardType: TextInputType.phone,
                validator: (v) =>
                    v!.isEmpty ? 'Phone is required' : null,
              ),
              const SizedBox(height: 12),
              _field(
                controller: passwordController,
                label: 'Password',
                obscure: true,
                validator: (v) {
                  if (v!.isEmpty) return 'Password is required';
                  if (v.length < 6) return 'Min 6 characters';
                  return null;
                },
              ),
              const SizedBox(height: 12),
              _field(
                controller: specialtyController,
                label: 'Specialty',
                validator: (v) =>
                    v!.isEmpty ? 'Specialty is required' : null,
              ),
              const SizedBox(height: 12),
              _field(
                controller: experienceController,
                label: 'Experience (years)',
                keyboardType: TextInputType.number,
              ),
              const SizedBox(height: 24),
              SizedBox(
                width: double.infinity,
                height: 48,
                child: ElevatedButton(
                  onPressed: isLoading ? null : _createDoctor,
                  child: isLoading
                      ? const SizedBox(
                          height: 20,
                          width: 20,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            color: Colors.white,
                          ),
                        )
                      : const Text('Create Doctor'),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _field({
    required TextEditingController controller,
    required String label,
    bool obscure = false,
    TextInputType keyboardType = TextInputType.text,
    String? Function(String?)? validator,
  }) {
    return TextFormField(
      controller: controller,
      obscureText: obscure,
      keyboardType: keyboardType,
      validator: validator,
      decoration: InputDecoration(
        labelText: label,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
        ),
      ),
    );
  }
}
