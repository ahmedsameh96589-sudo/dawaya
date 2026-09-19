import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/services/api_services.dart';

/// A page that collects Visa / credit-card details and saves them
/// via [ApiService.saveCardDetails].
///
/// Returns a [Map<String, String>] with the keys:
///   - 'cardHolder'
///   - 'cardNumber'   (full 16-digit string, no spaces)
///   - 'last4'        (last 4 digits)
///   - 'expiry'       (MM/YY)
///   - 'cvv'
///
/// to the previous route when the user taps "Save card".
class VisaDetailsPage extends StatefulWidget {
  const VisaDetailsPage({super.key, this.existingCard});

  final Map<String, String>? existingCard;

  @override
  State<VisaDetailsPage> createState() => _VisaDetailsPageState();
}

class _VisaDetailsPageState extends State<VisaDetailsPage> {
  final _formKey = GlobalKey<FormState>();
  bool _isLoading = false;
  bool _obscureCvv = true;

  late final TextEditingController _holderCtrl;
  late final TextEditingController _numberCtrl;
  late final TextEditingController _expiryCtrl;
  late final TextEditingController _cvvCtrl;

  @override
  void initState() {
    super.initState();
    final c = widget.existingCard;
    _holderCtrl = TextEditingController(text: c?['cardHolder'] ?? '');
    _numberCtrl = TextEditingController(text: c?['cardNumber'] ?? '');
    _expiryCtrl = TextEditingController(text: c?['expiry'] ?? '');
    _cvvCtrl    = TextEditingController(text: c?['cvv'] ?? '');
  }

  @override
  void dispose() {
    _holderCtrl.dispose();
    _numberCtrl.dispose();
    _expiryCtrl.dispose();
    _cvvCtrl.dispose();
    super.dispose();
  }

  // ── Helpers ───────────────────────────────────────────────────────────────

  /// Formats raw digits as "XXXX XXXX XXXX XXXX" while the user types.
  String _formatCardNumber(String raw) {
    final digits = raw.replaceAll(RegExp(r'\D'), '');
    final groups = <String>[];
    for (var i = 0; i < digits.length && i < 16; i += 4) {
      groups.add(digits.substring(i, (i + 4).clamp(0, digits.length)));
    }
    return groups.join(' ');
  }

  /// Formats raw digits as "MM/YY".
  String _formatExpiry(String raw) {
    final digits = raw.replaceAll(RegExp(r'\D'), '');
    if (digits.length <= 2) return digits;
    return '${digits.substring(0, 2)}/${digits.substring(2, digits.length.clamp(0, 4))}';
  }

  Future<void> _saveCard() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isLoading = true);
    try {
      final rawNumber = _numberCtrl.text.replaceAll(' ', '');
      final cardData = {
        'cardHolder': _holderCtrl.text.trim(),
        'cardNumber': rawNumber,
        'last4'     : rawNumber.substring(rawNumber.length - 4),
        'expiry'    : _expiryCtrl.text.trim(),
        'cvv'       : _cvvCtrl.text.trim(),
      };

      // Save to your backend / Firebase
      await ApiService.saveCardDetails(cardData);

      if (!mounted) return;
      Navigator.of(context).pop(cardData); // return data to PaymentPage
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(e.toString())),
      );
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  // ── Build ─────────────────────────────────────────────────────────────────

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
        title: const Text('Card details'),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.fromLTRB(20, 12, 20, 32),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // ── Visual card preview ────────────────────────────
              _CardPreview(
                holder: _holderCtrl.text,
                number: _numberCtrl.text,
                expiry: _expiryCtrl.text,
              ),

              const SizedBox(height: 28),

              // ── Cardholder name ───────────────────────────────
              _FieldLabel('Cardholder name'),
              const SizedBox(height: 6),
              _buildTextField(
                controller: _holderCtrl,
                hint: 'Full name as on card',
                keyboardType: TextInputType.name,
                textCapitalization: TextCapitalization.words,
                inputFormatters: [
                  FilteringTextInputFormatter.allow(RegExp(r'[a-zA-Z\s]')),
                ],
                validator: (v) {
                  if (v == null || v.trim().isEmpty) return 'Required';
                  if (v.trim().split(' ').length < 2) {
                    return 'Enter first and last name';
                  }
                  return null;
                },
                onChanged: (_) => setState(() {}),
              ),

              const SizedBox(height: 16),

              // ── Card number ───────────────────────────────────
              _FieldLabel('Card number'),
              const SizedBox(height: 6),
              _buildTextField(
                controller: _numberCtrl,
                hint: '0000 0000 0000 0000',
                keyboardType: TextInputType.number,
                inputFormatters: [
                  FilteringTextInputFormatter.digitsOnly,
                  _CardNumberFormatter(),
                ],
                maxLength: 19, // 16 digits + 3 spaces
                prefixIcon: const Icon(Icons.credit_card, size: 20),
                suffixIcon: _visaLogo(),
                validator: (v) {
                  final digits = (v ?? '').replaceAll(' ', '');
                  if (digits.length != 16) return 'Enter a valid 16-digit number';
                  return null;
                },
                onChanged: (_) => setState(() {}),
              ),

              const SizedBox(height: 16),

              // ── Expiry + CVV side by side ──────────────────────
              Row(
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        _FieldLabel('Expiry date'),
                        const SizedBox(height: 6),
                        _buildTextField(
                          controller: _expiryCtrl,
                          hint: 'MM/YY',
                          keyboardType: TextInputType.number,
                          inputFormatters: [
                            FilteringTextInputFormatter.digitsOnly,
                            _ExpiryFormatter(),
                          ],
                          maxLength: 5,
                          validator: (v) {
                            if (v == null || v.length < 5) return 'MM/YY';
                            final parts = v.split('/');
                            final month = int.tryParse(parts[0]) ?? 0;
                            if (month < 1 || month > 12) return 'Invalid month';
                            return null;
                          },
                          onChanged: (_) => setState(() {}),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        _FieldLabel('CVV'),
                        const SizedBox(height: 6),
                        _buildTextField(
                          controller: _cvvCtrl,
                          hint: '•••',
                          keyboardType: TextInputType.number,
                          obscureText: _obscureCvv,
                          inputFormatters: [
                            FilteringTextInputFormatter.digitsOnly,
                          ],
                          maxLength: 3,
                          suffixIcon: GestureDetector(
                            onTap: () =>
                                setState(() => _obscureCvv = !_obscureCvv),
                            child: Icon(
                              _obscureCvv
                                  ? Icons.visibility_off_outlined
                                  : Icons.visibility_outlined,
                              size: 18,
                              color: Colors.black54,
                            ),
                          ),
                          validator: (v) {
                            if (v == null || v.length != 3) return '3 digits';
                            return null;
                          },
                          onChanged: (_) => setState(() {}),
                        ),
                      ],
                    ),
                  ),
                ],
              ),

              const SizedBox(height: 12),

              // ── Security note ──────────────────────────────────
              Row(
                children: const [
                  Icon(Icons.lock_outline, size: 14, color: Colors.black38),
                  SizedBox(width: 6),
                  Text(
                    'Your card data is encrypted and stored securely.',
                    style: TextStyle(fontSize: 12, color: Colors.black38),
                  ),
                ],
              ),

              const SizedBox(height: 32),

              // ── Save button ────────────────────────────────────
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: _isLoading ? null : _saveCard,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.brandBlue,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(18),
                    ),
                  ),
                  child: _isLoading
                      ? const SizedBox(
                          height: 20,
                          width: 20,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            color: Colors.white,
                          ),
                        )
                      : const Text('Save card'),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  // ── Helpers ───────────────────────────────────────────────────────────────

  Widget _buildTextField({
    required TextEditingController controller,
    required String hint,
    TextInputType keyboardType = TextInputType.text,
    bool obscureText = false,
    TextCapitalization textCapitalization = TextCapitalization.none,
    List<TextInputFormatter>? inputFormatters,
    int? maxLength,
    Widget? prefixIcon,
    Widget? suffixIcon,
    String? Function(String?)? validator,
    ValueChanged<String>? onChanged,
  }) {
    return TextFormField(
      controller: controller,
      keyboardType: keyboardType,
      obscureText: obscureText,
      textCapitalization: textCapitalization,
      inputFormatters: inputFormatters,
      maxLength: maxLength,
      onChanged: onChanged,
      validator: validator,
      decoration: InputDecoration(
        hintText: hint,
        hintStyle: const TextStyle(color: Colors.black26),
        counterText: '',
        prefixIcon: prefixIcon,
        suffixIcon: suffixIcon != null
            ? Padding(
                padding: const EdgeInsets.only(right: 12),
                child: suffixIcon,
              )
            : null,
        suffixIconConstraints:
            const BoxConstraints(minHeight: 20, minWidth: 20),
        filled: true,
        fillColor: const Color(0xFFF7F7F7),
        contentPadding:
            const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: BorderSide.none,
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: BorderSide(color: Colors.grey.shade200),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: BorderSide(color: AppColors.brandBlue, width: 1.5),
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: const BorderSide(color: Colors.redAccent),
        ),
        focusedErrorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: const BorderSide(color: Colors.redAccent, width: 1.5),
        ),
      ),
    );
  }

  Widget _visaLogo() {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 8),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
        decoration: BoxDecoration(
          color: const Color(0xFF1A1F71),
          borderRadius: BorderRadius.circular(4),
        ),
        child: const Text(
          'VISA',
          style: TextStyle(
            color: Colors.white,
            fontWeight: FontWeight.w800,
            fontSize: 11,
            letterSpacing: 1,
          ),
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Label widget
// ─────────────────────────────────────────────────────────────────────────────
class _FieldLabel extends StatelessWidget {
  const _FieldLabel(this.text);
  final String text;

  @override
  Widget build(BuildContext context) {
    return Text(
      text,
      style: const TextStyle(
        fontWeight: FontWeight.w600,
        fontSize: 13,
        color: Colors.black87,
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Visual card preview
// ─────────────────────────────────────────────────────────────────────────────
class _CardPreview extends StatelessWidget {
  const _CardPreview({
    required this.holder,
    required this.number,
    required this.expiry,
  });

  final String holder;
  final String number;
  final String expiry;

  @override
  Widget build(BuildContext context) {
    final displayNumber = number.isEmpty
        ? '**** **** **** ****'
        : number.padRight(19, '*');
    final displayHolder = holder.isEmpty ? 'YOUR NAME' : holder.toUpperCase();
    final displayExpiry = expiry.isEmpty ? 'MM/YY' : expiry;

    return Container(
      width: double.infinity,
      height: 180,
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(20),
        gradient: const LinearGradient(
          colors: [Color(0xFF1A1F71), Color(0xFF2563EB)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF2563EB).withOpacity(0.35),
            blurRadius: 20,
            offset: const Offset(0, 10),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Top row: chip + VISA
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              // Chip
              Container(
                width: 36,
                height: 26,
                decoration: BoxDecoration(
                  color: const Color(0xFFFFD700),
                  borderRadius: BorderRadius.circular(4),
                ),
              ),
              const Text(
                'VISA',
                style: TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.w800,
                  fontSize: 18,
                  letterSpacing: 2,
                ),
              ),
            ],
          ),
          const Spacer(),
          // Card number
          Text(
            displayNumber,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 16,
              letterSpacing: 2.5,
              fontWeight: FontWeight.w500,
            ),
          ),
          const SizedBox(height: 16),
          // Holder + expiry
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'CARD HOLDER',
                    style: TextStyle(color: Colors.white54, fontSize: 9),
                  ),
                  Text(
                    displayHolder,
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 13,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
              ),
              Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  const Text(
                    'EXPIRES',
                    style: TextStyle(color: Colors.white54, fontSize: 9),
                  ),
                  Text(
                    displayExpiry,
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 13,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
              ),
            ],
          ),
        ],
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Custom text input formatters
// ─────────────────────────────────────────────────────────────────────────────

class _CardNumberFormatter extends TextInputFormatter {
  @override
  TextEditingValue formatEditUpdate(
    TextEditingValue oldValue,
    TextEditingValue newValue,
  ) {
    final digits = newValue.text.replaceAll(RegExp(r'\D'), '');
    final buffer = StringBuffer();
    for (var i = 0; i < digits.length && i < 16; i++) {
      if (i > 0 && i % 4 == 0) buffer.write(' ');
      buffer.write(digits[i]);
    }
    final formatted = buffer.toString();
    return TextEditingValue(
      text: formatted,
      selection: TextSelection.collapsed(offset: formatted.length),
    );
  }
}

class _ExpiryFormatter extends TextInputFormatter {
  @override
  TextEditingValue formatEditUpdate(
    TextEditingValue oldValue,
    TextEditingValue newValue,
  ) {
    final digits = newValue.text.replaceAll(RegExp(r'\D'), '');
    final buffer = StringBuffer();
    for (var i = 0; i < digits.length && i < 4; i++) {
      if (i == 2) buffer.write('/');
      buffer.write(digits[i]);
    }
    final formatted = buffer.toString();
    return TextEditingValue(
      text: formatted,
      selection: TextSelection.collapsed(offset: formatted.length),
    );
  }
}