import 'package:flutter/material.dart';

import '../../../core/theme/app_colors.dart';
import '../models/cart_controller.dart';
import '../models/cart_model.dart';
import 'cart_provider.dart';
import 'checkout_address_page.dart';
import '../../presentation/home_page.dart';
import '../../presentation/substitute_page.dart';
import '../../chat/presentation/consultations_page.dart';
import '../../profile/presentation/profile_page.dart';

class CartPage extends StatefulWidget {
  const CartPage({super.key});

  @override
  State<CartPage> createState() => _CartPageState();
}

class _CartPageState extends State<CartPage> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      CartProvider.of(context).loadFromServer();
    });
  }

  Future<void> _runCartAction(
    BuildContext context,
    Future<void> Function() action,
  ) async {
    try {
      await action();
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(e.toString())),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final cart = CartProvider.of(context);
    final List<CartItem> items = cart.items;
    return Scaffold(
      backgroundColor: AppColors.surface,
      extendBody: true,
      appBar: AppBar(
        backgroundColor: Colors.white,
        foregroundColor: Colors.black,
        elevation: 0,
        centerTitle: true,
        title: const Text('Cart'),
      ),
      body: Stack(
        children: [
          SafeArea(
            bottom: false,
            child: Column(
              children: <Widget>[
                if (cart.isSyncing)
                  const LinearProgressIndicator(minHeight: 2),
                if (cart.error != null && items.isEmpty)
                  Padding(
                    padding: const EdgeInsets.fromLTRB(20, 12, 20, 0),
                    child: Row(
                      children: [
                        Expanded(
                          child: Text(
                            cart.error!,
                            style: const TextStyle(color: Colors.redAccent),
                          ),
                        ),
                        TextButton(
                          onPressed: () => cart.loadFromServer(force: true),
                          child: const Text('Retry'),
                        ),
                      ],
                    ),
                  ),
                Expanded(
                  child: items.isEmpty
                      ? _buildEmptyState()
                      : ListView.separated(
                          padding: const EdgeInsets.fromLTRB(20, 12, 20, 0),
                          itemCount: items.length,
                          separatorBuilder: (_, __) => const SizedBox(height: 12),
                          itemBuilder: (BuildContext context, int index) {
                            final CartItem item = items[index];
                            return _CartItemCard(
                              item: item,
                              onRemove: () {
                                _runCartAction(
                                  context,
                                  () => cart.remove(item.product),
                                );
                              },
                              onDecrement: () {
                                _runCartAction(
                                  context,
                                  () => cart.decrement(item.product),
                                );
                              },
                              onIncrement: () {
                                _runCartAction(
                                  context,
                                  () => cart.increment(item.product),
                                );
                              },
                            );
                          },
                        ),
                ),
                _buildSummary(context, cart),
              ],
            ),
          ),
          _buildChatFab(context),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () {},
        backgroundColor: AppColors.brandAccent,
        child: const Icon(Icons.qr_code_scanner, color: Colors.black),
      ),
      floatingActionButtonLocation: FloatingActionButtonLocation.centerDocked,
      bottomNavigationBar: _buildBottomBar(context),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: const <Widget>[
          Icon(Icons.shopping_cart_outlined, size: 56, color: Colors.black38),
          SizedBox(height: 12),
          Text('Cart is empty'),
        ],
      ),
    );
  }

  Widget _buildSummary(BuildContext context, CartController cart) {
    return Container(
      margin: const EdgeInsets.fromLTRB(20, 12, 20, 90),
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      decoration: BoxDecoration(
        color: AppColors.brandAccent,
        borderRadius: BorderRadius.circular(18),
        boxShadow: const <BoxShadow>[
          BoxShadow(
            color: AppColors.cardShadow,
            blurRadius: 10,
            offset: Offset(0, 6),
          ),
        ],
      ),
      child: Row(
        children: <Widget>[
          Expanded(
            child: Text(
              'Total: ${cart.totalPrice.toStringAsFixed(0)} EGP',
              style: const TextStyle(
                fontWeight: FontWeight.w600,
                color: Colors.black87,
              ),
            ),
          ),
          ElevatedButton(
            onPressed: cart.items.isEmpty
                ? null
                : () {
                    Navigator.of(context).push(
                      MaterialPageRoute<void>(
                        builder: (_) => const CheckoutAddressPage(),
                      ),
                    );
                  },
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.brandBlue,
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 10),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(16),
              ),
            ),
            child: const Text('Checkout'),
          ),
        ],
      ),
    );
  }

  Widget _buildBottomBar(BuildContext context) {
    return BottomAppBar(
      color: AppColors.brandBlue,
      shape: const CircularNotchedRectangle(),
      notchMargin: 8,
      child: SizedBox(
        height: 72,
        child: Row(
          children: <Widget>[
            Expanded(
              child: _BottomNavItem(
                icon: Icons.home_outlined,
                label: 'Home',
                onTap: () {
                  Navigator.of(context).pushAndRemoveUntil(
                    MaterialPageRoute<void>(
                      builder: (_) => const HomePage(title: 'Dawayaa'),
                    ),
                    (route) => false,
                  );
                },
              ),
            ),
            Expanded(
              child: _BottomNavItem(
                icon: Icons.swap_horiz,
                label: 'Substitute',
                onTap: () {
                  Navigator.of(context).push(
                    MaterialPageRoute<void>(
                      builder: (_) => const SubstitutePage(),
                    ),
                  );
                },
              ),
            ),
            const SizedBox(width: 36),
            const Expanded(
              child: _BottomNavItem(
                icon: Icons.shopping_cart_outlined,
                label: 'Cart',
                isActive: true,
              ),
            ),
            Expanded(
              child: _BottomNavItem(
                icon: Icons.person_outline,
                label: 'Profile',
                onTap: () {
                  Navigator.of(context).push(
                    MaterialPageRoute<void>(
                      builder: (_) => const ProfilePage(),
                    ),
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildChatFab(BuildContext context) {
    return Positioned(
      right: 16,
      bottom: 120,
      child: FloatingActionButton(
        heroTag: 'chatFabCart',
        mini: true,
        backgroundColor: AppColors.brandBlue,
        onPressed: () {
          Navigator.of(context).push(
            MaterialPageRoute<void>(
              builder: (_) => const ConsultationsPage(),
            ),
          );
        },
        child: const Icon(Icons.chat_bubble_outline, color: Colors.white),
      ),
    );
  }

}

class _CartItemCard extends StatelessWidget {
  const _CartItemCard({
    required this.item,
    required this.onRemove,
    required this.onDecrement,
    required this.onIncrement,
  });

  final CartItem item;
  final VoidCallback onRemove;
  final VoidCallback onDecrement;
  final VoidCallback onIncrement;

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
        boxShadow: const <BoxShadow>[
          BoxShadow(
            color: AppColors.cardShadow,
            blurRadius: 10,
            offset: Offset(0, 6),
          ),
        ],
      ),
      child: Row(
        children: <Widget>[
          ClipRRect(
            borderRadius: const BorderRadius.horizontal(
              left: Radius.circular(18),
            ),
            child: Image.network(
              item.product.imageUrl,
              width: 72,
              height: 72,
              fit: BoxFit.cover,
              errorBuilder: (_, __, ___) => Container(
                width: 72,
                height: 72,
                color: Colors.grey.shade100,
                child: const Icon(Icons.medication_outlined),
              ),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: <Widget>[
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: <Widget>[
                    Text(
                      item.product.name,
                      style: const TextStyle(fontWeight: FontWeight.w600),
                    ),
                    IconButton(
                      onPressed: onRemove,
                      icon: const Icon(Icons.close, size: 18),
                      splashRadius: 18,
                    ),
                  ],
                ),
                Row(
                  children: <Widget>[
                    Text(
                      item.product.price,
                      style: const TextStyle(color: Colors.black54),
                    ),
                    const Spacer(),
                    _QuantityButton(
                      icon: Icons.remove,
                      onTap: onDecrement,
                    ),
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 8),
                      child: Text('${item.quantity}'),
                    ),
                    _QuantityButton(
                      icon: Icons.add,
                      onTap: onIncrement,
                    ),
                  ],
                ),
                const SizedBox(height: 8),
              ],
            ),
          ),
          const SizedBox(width: 6),
        ],
      ),
    );
  }
}

class _QuantityButton extends StatelessWidget {
  const _QuantityButton({required this.icon, required this.onTap});

  final IconData icon;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(10),
      child: Container(
        width: 24,
        height: 24,
        decoration: BoxDecoration(
          color: AppColors.cardBlue,
          borderRadius: BorderRadius.circular(8),
        ),
        child: Icon(icon, size: 14),
      ),
    );
  }
}

class _BottomNavItem extends StatelessWidget {
  const _BottomNavItem({
    required this.icon,
    required this.label,
    this.isActive = false,
    this.onTap,
  });

  final IconData icon;
  final String label;
  final bool isActive;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final Color color = isActive ? Colors.white : Colors.white70;
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(14),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: <Widget>[
          Icon(icon, color: color),
          const SizedBox(height: 4),
          Text(
            label,
            style: TextStyle(
              color: color,
              fontSize: 11,
              fontWeight: isActive ? FontWeight.w600 : FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }
}
