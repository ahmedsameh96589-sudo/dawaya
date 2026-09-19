import 'package:flutter/material.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/services/api_services.dart';
import '../models/checkout_address.dart';
import '../models/order_request.dart';
import 'cart_provider.dart';
import 'visa_details_page.dart';

class PaymentPage extends StatefulWidget {
  const PaymentPage({super.key, required this.address});

  final CheckoutAddress address;

  @override
  State<PaymentPage> createState() => _PaymentPageState();
}

class _PaymentPageState extends State<PaymentPage> {
  bool _isLoading = false;

  // cash | visa
  String _selectedMethod = 'cash';

  // Holds card details returned from VisaDetailsPage
  Map<String, String>? _savedCard;

  Future<void> _placeOrder(BuildContext context) async {
    if (_selectedMethod == 'visa' && _savedCard == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please add your Visa card details first.'),
        ),
      );
      return;
    }

    setState(() => _isLoading = true);

    try {
      final request = OrderRequest(
        deliveryAddress: widget.address,

        // FIXED HERE
        paymentMethod: _selectedMethod == 'visa'
            ? 'credit_card'
            : 'cash_on_delivery',

        notes: _selectedMethod == 'visa'
            ? 'Visa card ending in ${_savedCard!['last4']}'
            : 'Cash on delivery',
      );

      await ApiService.placeOrder(request);

      if (!mounted) return;

      try {
        await CartProvider.of(context).clear();
      } catch (_) {}

      _showPendingDialog();
    } catch (e) {
      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            e.toString().replaceAll('Exception:', '').trim(),
          ),
        ),
      );
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  void _showPendingDialog() {
    showDialog<void>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Order confirmed'),
        content: Text(
          _selectedMethod == 'visa'
              ? 'Your order has been placed successfully. Paid with Visa card ending in ${_savedCard!['last4']}.'
              : 'Your order has been placed successfully. Cash on delivery.',
        ),
        actions: [
          TextButton(
            onPressed: () {
              Navigator.of(context).popUntil((route) => route.isFirst);
            },
            child: const Text('OK'),
          ),
        ],
      ),
    );
  }

  Future<void> _onVisaTap() async {
    setState(() => _selectedMethod = 'visa');

    final result = await Navigator.of(context).push<Map<String, String>>(
      MaterialPageRoute(
        builder: (_) => VisaDetailsPage(
          existingCard: _savedCard,
        ),
      ),
    );

    if (result != null) {
      setState(() => _savedCard = result);
    }
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
        title: const Text('Payment'),
      ),

      body: Padding(
        padding: const EdgeInsets.fromLTRB(20, 12, 20, 24),

        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: <Widget>[
            // Cash on delivery
            _PaymentOption(
              label: 'Cash on delivery',
              icon: Icons.payments_outlined,
              isActive: _selectedMethod == 'cash',
              onTap: () {
                setState(() => _selectedMethod = 'cash');
              },
            ),

            const SizedBox(height: 12),

            // Visa
            _PaymentOption(
              label: 'Visa / Credit card',
              icon: Icons.credit_card,
              isActive: _selectedMethod == 'visa',
              onTap: _onVisaTap,
              trailing: _savedCard != null
                  ? Text(
                      '**** **** **** ${_savedCard!['last4']}',
                      style: const TextStyle(
                        fontSize: 12,
                        color: Colors.black54,
                        fontWeight: FontWeight.w500,
                      ),
                    )
                  : null,
            ),

            if (_savedCard != null &&
                _selectedMethod == 'visa') ...[
              const SizedBox(height: 6),

              GestureDetector(
                onTap: _onVisaTap,
                child: Padding(
                  padding: const EdgeInsets.only(left: 4),
                  child: Text(
                    'Edit card details',
                    style: TextStyle(
                      fontSize: 13,
                      color: AppColors.brandBlue,
                      decoration: TextDecoration.underline,
                    ),
                  ),
                ),
              ),
            ],

            const Spacer(),

            SizedBox(
              width: double.infinity,

              child: ElevatedButton(
                onPressed: _isLoading
                    ? null
                    : () => _placeOrder(context),

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
                    : const Text('Place order'),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────
// Reusable selectable payment option tile
// ─────────────────────────────────────────────
class _PaymentOption extends StatelessWidget {
  const _PaymentOption({
    required this.label,
    required this.icon,
    this.isActive = false,
    this.onTap,
    this.trailing,
  });

  final String label;
  final IconData icon;
  final bool isActive;
  final VoidCallback? onTap;
  final Widget? trailing;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,

      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),

        padding: const EdgeInsets.symmetric(
          horizontal: 16,
          vertical: 14,
        ),

        decoration: BoxDecoration(
          color: isActive
              ? AppColors.brandAccent
              : Colors.white,

          borderRadius: BorderRadius.circular(18),

          border: Border.all(
            color: isActive
                ? AppColors.brandBlue
                : Colors.grey.shade300,

            width: isActive ? 1.5 : 1,
          ),
        ),

        child: Row(
          children: <Widget>[
            Icon(
              isActive
                  ? Icons.radio_button_checked
                  : Icons.radio_button_off,

              color: isActive
                  ? AppColors.brandBlue
                  : Colors.black38,

              size: 18,
            ),

            const SizedBox(width: 10),

            Icon(
              icon,
              size: 20,
              color: Colors.black87,
            ),

            const SizedBox(width: 8),

            Expanded(
              child: Text(
                label,
                style: const TextStyle(
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),

            if (trailing != null) trailing!,
          ],
        ),
      ),
    );
  }
}