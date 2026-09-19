import 'package:flutter/material.dart';
import 'otp_verification_screen.dart';
import '../data/auth_repository.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

class ForgetPasswordScreen extends ConsumerStatefulWidget {
  const ForgetPasswordScreen({super.key});

  @override
  ConsumerState<ForgetPasswordScreen> createState() =>
      _ForgetPasswordScreenState();
}

class _ForgetPasswordScreenState
    extends ConsumerState<ForgetPasswordScreen> {
  final _formKey = GlobalKey<FormState>();

  final TextEditingController emailController =
      TextEditingController();

  bool isLoading = false;

  @override
  void dispose() {
    emailController.dispose();
    super.dispose();
  }

  Future<void> sendOtp() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => isLoading = true);

    try {
      final result = await ref.read(authRepositoryProvider).forgotPassword(
        email: emailController.text.trim(),
      );

      _showMessage(result.message);

      /// Navigate to OTP Screen
      if (mounted) {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (_) => OtpVerificationScreen(
              userId: result.userId ?? "",
              purpose: 'forgot_password',
            ),
          ),
        );
      }
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
      SnackBar(
        content: Text(message),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,

      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 24),

          child: Form(
            key: _formKey,

            child: Column(
              children: [
                const SizedBox(height: 10),

                /// Back Button
                Align(
                  alignment: Alignment.centerLeft,
                  child: IconButton(
                    onPressed: () => Navigator.pop(context),
                    icon: const Icon(
                      Icons.arrow_back_ios_new,
                    ),
                  ),
                ),

                const SizedBox(height: 10),

                /// Image
                Image.asset(
                  "lib/assets/image11.jpg",
                  height: 200,
                  fit: BoxFit.contain,

                  errorBuilder:
                      (
                        context,
                        error,
                        stackTrace,
                      ) {
                        return const Column(
                          children: [
                            Icon(
                              Icons.image_not_supported,
                              size: 80,
                              color: Colors.grey,
                            ),
                            SizedBox(height: 10),
                            Text(
                              "Image not found",
                              style: TextStyle(
                                color: Colors.red,
                              ),
                            ),
                          ],
                        );
                      },
                ),

                const SizedBox(height: 24),

                /// Title
                const Text(
                  "Forget Password",
                  style: TextStyle(
                    fontSize: 24,
                    fontWeight: FontWeight.w700,
                  ),
                ),

                const SizedBox(height: 8),

                /// Subtitle
                Text(
                  "Enter your Email to reset password",
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    color: Colors.grey.shade600,
                    fontSize: 14,
                  ),
                ),

                const SizedBox(height: 28),

                /// Email Field
                TextFormField(
                  controller: emailController,
                  keyboardType:
                      TextInputType.emailAddress,

                  validator: (v) {
                    if (v == null || v.isEmpty) {
                      return "Email is required";
                    }

                    if (!v.contains('@')) {
                      return "Enter a valid email";
                    }

                    return null;
                  },

                  decoration: InputDecoration(
                    hintText: "Enter Email",
                    prefixIcon: const Icon(
                      Icons.email_outlined,
                    ),

                    filled: true,
                    fillColor:
                        const Color(0xFFF5F5F5),

                    border: OutlineInputBorder(
                      borderRadius:
                          BorderRadius.circular(30),
                      borderSide: BorderSide.none,
                    ),
                  ),
                ),

                const SizedBox(height: 24),

                /// Next Button
                SizedBox(
                  width: double.infinity,
                  height: 52,

                  child: ElevatedButton(
                    onPressed:
                        isLoading ? null : sendOtp,

                    style: ElevatedButton.styleFrom(
                      backgroundColor:
                          const Color(0xFF0B1C6D),

                      shape: RoundedRectangleBorder(
                        borderRadius:
                            BorderRadius.circular(
                              30,
                            ),
                      ),
                    ),

                    child:
                        isLoading
                            ? const SizedBox(
                              width: 22,
                              height: 22,

                              child:
                                  CircularProgressIndicator(
                                    color:
                                        Colors.white,
                                    strokeWidth: 2,
                                  ),
                            )
                            : const Text(
                              "Next",
                              style: TextStyle(
                                color: Colors.white,
                                fontSize: 16,
                                fontWeight:
                                    FontWeight.w600,
                              ),
                            ),
                  ),
                ),

                const SizedBox(height: 28),

                /// Divider
                Row(
                  children: const [
                    Expanded(child: Divider()),

                    Padding(
                      padding:
                          EdgeInsets.symmetric(
                            horizontal: 8,
                          ),
                      child: Text(
                        "Or Sign in with",
                      ),
                    ),

                    Expanded(child: Divider()),
                  ],
                ),

                const SizedBox(height: 20),

                /// Google Button
                _socialButton(
                  text: "Sign in with Google",
                  color: Colors.lightBlue,
                  icon: Icons.g_mobiledata,
                ),

                const SizedBox(height: 12),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _socialButton({
    required String text,
    required Color color,
    required IconData icon,
  }) {
    return SizedBox(
      width: double.infinity,
      height: 50,

      child: ElevatedButton.icon(
        onPressed: () {},

        icon: Icon(
          icon,
          color: Colors.white,
        ),

        label: Text(
          text,
          style: const TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.w600,
            color: Colors.white,
          ),
        ),

        style: ElevatedButton.styleFrom(
          backgroundColor: color,

          shape: RoundedRectangleBorder(
            borderRadius:
                BorderRadius.circular(30),
          ),
        ),
      ),
    );
  }
}