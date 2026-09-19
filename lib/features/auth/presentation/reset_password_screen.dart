import 'package:flutter/material.dart';
import '../data/auth_repository.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

class ResetPasswordScreen extends ConsumerStatefulWidget {
  const ResetPasswordScreen({
    super.key,
    required this.userId,
    required this.resetToken,
  });

  final String userId;
  final String resetToken;

  @override
  ConsumerState<ResetPasswordScreen> createState() => _ResetPasswordScreenState();
}

class _ResetPasswordScreenState extends ConsumerState<ResetPasswordScreen> {
  final _formKey = GlobalKey<FormState>();
  final TextEditingController passwordController = TextEditingController();
  final TextEditingController confirmPasswordController =
      TextEditingController();

  bool isLoading = false;

  Future<void> resetPassword() async {
    if (!_formKey.currentState!.validate()) return;

    if (passwordController.text != confirmPasswordController.text) {
      _showMessage("Passwords do not match");
      return;
    }

    setState(() => isLoading = true);
    try {
      await ref.read(authRepositoryProvider).resetPassword(
        userId: widget.userId,
        resetToken: widget.resetToken,
        newPassword: passwordController.text,
      );

      if (!mounted) return;
      _showMessage("Password reset successfully");
      Navigator.pushNamedAndRemoveUntil(context, '/login', (route) => false);
    } catch (e) {
      _showMessage(e.toString());
    } finally {
      if (mounted) {
        setState(() => isLoading = false);
      }
    }
  }

  void _showMessage(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message)),
    );
  }

  @override
  void dispose() {
    passwordController.dispose();
    confirmPasswordController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 24),
          child: Form(
            key: _formKey,
            child: Column(
              children: [
                const SizedBox(height: 10),
                Align(
                  alignment: Alignment.centerLeft,
                  child: IconButton(
                    icon: const Icon(Icons.arrow_back_ios_new),
                    onPressed: () => Navigator.pop(context),
                  ),
                ),
                const SizedBox(height: 20),
                const Text(
                  "Enter New Password",
                  style: TextStyle(
                    fontSize: 22,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 6),
                const Text(
                  "Please choose a new password",
                  style: TextStyle(
                    fontSize: 14,
                    color: Colors.grey,
                  ),
                ),
                const SizedBox(height: 32),
                _passwordField(
                  controller: passwordController,
                  hint: "New Password",
                  validator: (v) {
                    if (v!.isEmpty) return "Password is required";
                    if (v.length < 6) return "Minimum 6 characters";
                    return null;
                  },
                ),
                const SizedBox(height: 16),
                _passwordField(
                  controller: confirmPasswordController,
                  hint: "Confirm Password",
                  validator: (v) =>
                      v!.isEmpty ? "Confirm your password" : null,
                ),
                const SizedBox(height: 28),
                SizedBox(
                  width: double.infinity,
                  height: 48,
                  child: ElevatedButton(
                    onPressed: isLoading ? null : resetPassword,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF0B1C6D),
                      shape: const StadiumBorder(),
                      elevation: 3,
                    ),
                    child: isLoading
                        ? const SizedBox(
                            height: 22,
                            width: 22,
                            child: CircularProgressIndicator(
                              strokeWidth: 2,
                              color: Colors.white,
                            ),
                          )
                        : const Text(
                            "Create",
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.w600,
                              color: Colors.white,
                            ),
                          ),
                  ),
                ),
                const SizedBox(height: 28),
                Row(
                  children: const [
                    Expanded(child: Divider()),
                    Padding(
                      padding: EdgeInsets.symmetric(horizontal: 8),
                      child: Text(
                        "OR Sign in with",
                        style: TextStyle(color: Colors.grey),
                      ),
                    ),
                    Expanded(child: Divider()),
                  ],
                ),
                const SizedBox(height: 20),
                _socialButton(
                  color: const Color(0xFF03A9F4),
                  icon: Icons.g_mobiledata,
                  text: "Sign in with Google",
                ),
                const SizedBox(height: 12),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _passwordField({
    required TextEditingController controller,
    required String hint,
    required String? Function(String?) validator,
  }) {
    return TextFormField(
      controller: controller,
      obscureText: true,
      validator: validator,
      decoration: InputDecoration(
        hintText: hint,
        prefixIcon: const Icon(Icons.lock_outline),
        filled: true,
        fillColor: Colors.white,
        contentPadding: const EdgeInsets.symmetric(vertical: 14),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(30),
          borderSide: BorderSide(color: Colors.grey.shade300),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(30),
          borderSide: BorderSide(color: Colors.grey.shade300),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(30),
          borderSide:
              const BorderSide(color: Color(0xFF0B5ED7), width: 1.5),
        ),
      ),
    );
  }

  Widget _socialButton({
    required Color color,
    required IconData icon,
    required String text,
  }) {
    return SizedBox(
      width: double.infinity,
      height: 46,
      child: ElevatedButton.icon(
        onPressed: () => _showMessage(text),
        style: ElevatedButton.styleFrom(
          backgroundColor: color,
          shape: const StadiumBorder(),
        ),
        icon: Icon(icon, color: Colors.white),
        label: Text(
          text,
          style: const TextStyle(
            color: Colors.white,
            fontWeight: FontWeight.w600,
          ),
        ),
      ),
    );
  }
}
