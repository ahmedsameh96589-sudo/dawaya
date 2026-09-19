import 'package:flutter/material.dart';
import '../presentation/login_page.dart';
import '../../../core/services/auth_session.dart';
import '../../../core/services/push_notification_service.dart';
import '../../cart/presentation/cart_provider.dart';
import '../../presentation/home_page.dart';
import 'reset_password_screen.dart';
import '../data/auth_repository.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

class OtpVerificationScreen extends ConsumerStatefulWidget {
  const OtpVerificationScreen({
    super.key,
    required this.userId,
    required this.purpose,
  });

  final String userId;
  final String purpose;

  @override
  ConsumerState<OtpVerificationScreen> createState() => _OtpVerificationScreenState();
}

class _OtpVerificationScreenState extends ConsumerState<OtpVerificationScreen> {
  final List<TextEditingController> otpControllers = List.generate(
    6,
    (_) => TextEditingController(),
  );
  final List<FocusNode> focusNodes = List.generate(6, (_) => FocusNode());

  bool isLoading = false;
  bool isResending = false;

  Future<void> verifyOtp() async {
    final otp = otpControllers.map((c) => c.text).join();

    if (otp.length < 6) {
      _showMessage("Please enter complete OTP");
      return;
    }

    setState(() => isLoading = true);
    try {
      final result = await ref.read(authRepositoryProvider).verifyOtp(
        userId: widget.userId,
        otp: otp,
        purpose: widget.purpose,
      );

      if (widget.purpose == 'forgot_password') {
        if (result.resetToken == null) {
          throw Exception('Missing reset token.');
        }
        if (!mounted) return;
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(
            builder: (_) => ResetPasswordScreen(
              userId: widget.userId,
              resetToken: result.resetToken!,
            ),
          ),
        );
        _showMessage(result.message);
        return;
      }

      if (result.token == null) {
        throw Exception('Missing auth token.');
      }

      await AuthSession.start(
        token: result.token!,
        userId: widget.userId,
        role: result.role ?? 'user',
        name: result.name,
      );
      if (!mounted) return;

      CartProvider.of(context).loadFromServer(force: true);
      await PushNotificationService.registerTokenWithBackend();

      if (!mounted) return;
      Navigator.pushAndRemoveUntil(
        context,
        MaterialPageRoute(builder: (_) => const HomePage(title: 'Dawaya')),
        (route) => false,
      );
      _showMessage(result.message);
    } catch (e) {
      _showMessage(e.toString());
    } finally {
      if (mounted) {
        setState(() => isLoading = false);
      }
    }
  }

  Future<void> resendOtp() async {
    setState(() => isResending = true);
    try {
      await ref.read(authRepositoryProvider).resendOtp(
        userId: widget.userId,
        purpose: widget.purpose,
      );
      _showMessage("OTP resent");
    } catch (e) {
      _showMessage(e.toString());
    } finally {
      if (mounted) {
        setState(() => isResending = false);
      }
    }
  }

  void _showMessage(String message) {
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(SnackBar(content: Text(message)));
  }

  @override
  void dispose() {
    for (var c in otpControllers) {
      c.dispose();
    }
    for (var f in focusNodes) {
      f.dispose();
    }
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              const SizedBox(height: 10),
              Align(
                alignment: Alignment.centerLeft,
                child: IconButton(
                  icon: const Icon(Icons.arrow_back_ios_new),
                  onPressed: () {
                    Navigator.pushReplacement(
                      context,
                      MaterialPageRoute(
                        builder: (context) => const LoginPage(),
                      ),
                    );
                  },
                ),
              ),
              const SizedBox(height: 20),
              const Text(
                "Enter OTP code",
                style: TextStyle(fontSize: 22, fontWeight: FontWeight.w600),
              ),
              const SizedBox(height: 6),
              const Text(
                "OTP code has been sent to your email",
                style: TextStyle(fontSize: 14, color: Colors.grey),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 40),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: List.generate(6, (index) => _otpBox(index)),
              ),
              const SizedBox(height: 40),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  OutlinedButton(
                    onPressed: isResending ? null : resendOtp,
                    style: OutlinedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 28,
                        vertical: 14,
                      ),
                      shape: const StadiumBorder(),
                      side: const BorderSide(color: Colors.grey),
                    ),
                    child: isResending
                        ? const SizedBox(
                            height: 16,
                            width: 16,
                            child: CircularProgressIndicator(strokeWidth: 2),
                          )
                        : const Text(
                            "Resend",
                            style: TextStyle(color: Colors.black),
                          ),
                  ),
                  ElevatedButton(
                    onPressed: isLoading ? null : verifyOtp,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF0B5ED7),
                      padding: const EdgeInsets.symmetric(
                        horizontal: 32,
                        vertical: 14,
                      ),
                      shape: const StadiumBorder(),
                    ),
                    child: isLoading
                        ? const SizedBox(
                            height: 20,
                            width: 20,
                            child: CircularProgressIndicator(
                              strokeWidth: 2,
                              color: Colors.white,
                            ),
                          )
                        : const Text(
                            "Verify",
                            style: TextStyle(
                              fontWeight: FontWeight.w600,
                              color: Colors.white,
                            ),
                          ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _otpBox(int index) {
    return SizedBox(
      width: 48,
      height: 56,
      child: TextField(
        controller: otpControllers[index],
        focusNode: focusNodes[index],
        textAlign: TextAlign.center,
        keyboardType: TextInputType.number,
        maxLength: 1,
        style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w600),
        onChanged: (value) {
          if (value.isNotEmpty && index < 5) {
            focusNodes[index + 1].requestFocus();
          }
          if (value.isEmpty && index > 0) {
            focusNodes[index - 1].requestFocus();
          }
        },
        decoration: InputDecoration(
          counterText: "",
          filled: true,
          fillColor: Colors.white,
          contentPadding: EdgeInsets.zero,
          enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(10),
            borderSide: BorderSide(color: Colors.grey.shade300),
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(10),
            borderSide: const BorderSide(color: Color(0xFF0B5ED7), width: 1.5),
          ),
        ),
      ),
    );
  }
}
