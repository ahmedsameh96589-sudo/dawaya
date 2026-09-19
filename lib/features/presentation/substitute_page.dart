import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;

import '../../core/theme/app_colors.dart';
import '../../../core/services/api_services.dart';
import '../catalog/models/product.dart';
import '../cart/presentation/cart_page.dart';
import '../chat/presentation/consultations_page.dart';
import '../profile/presentation/profile_page.dart';

class SubstitutePage extends StatefulWidget {
  const SubstitutePage({super.key});

  @override
  State<SubstitutePage> createState() => _SubstitutePageState();
}

class _SubstitutePageState extends State<SubstitutePage> {
  Product? _selectedProduct;
  Product? _substituteProduct;
  List<Product> _products = [];
  List<Product> _alternatives = [];
  bool _loading = true;
  bool _loadingAlternative = false;
  String? _error;

  @override
  void initState() {
    super.initState();
    _loadProducts();
  }

  Future<void> _loadProducts() async {
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      final products = await ApiService.fetchMedicines();
      setState(() {
        _products = products;
        _loading = false;
      });
    } catch (e) {
      setState(() {
        _error = e.toString();
        _loading = false;
      });
    }
  }

  Future<void> _selectProduct(Product product) async {
    setState(() {
      _selectedProduct = product;
      _substituteProduct = null;
      _alternatives = [];
      _loadingAlternative = true;
    });
    try {
      final alternatives = await _fetchAlternatives(product.id);
      final String ingredient = product.activeIngredient.trim().toLowerCase();
      final List<Product> filtered = alternatives.where((alt) {
        if (alt.id == product.id) return false;
        if (ingredient.isEmpty) return false;
        return alt.activeIngredient.trim().toLowerCase() == ingredient;
      }).toList();
      if (!mounted) return;
      setState(() {
        _alternatives = filtered;
        _loadingAlternative = false;
      });

      if (ingredient.isEmpty) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Active ingredient not available for this product.'),
          ),
        );
      }
    } catch (e) {
      if (!mounted) return;
      setState(() => _loadingAlternative = false);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(e.toString())),
      );
    }
  }

  Future<List<Product>> _fetchAlternatives(String medicineId) async {
    final response = await http
        .get(
          Uri.parse('${ApiService.baseUrl}/medicines/$medicineId/alternatives'),
        )
        .timeout(const Duration(seconds: 10));

    if (response.statusCode == 200) {
      final Map<String, dynamic> body =
          jsonDecode(response.body) as Map<String, dynamic>;
      final Map<String, dynamic> data =
          body['data'] as Map<String, dynamic>? ?? {};
      final List<dynamic> list = data['alternatives'] as List<dynamic>? ?? [];
      return list
          .map((e) => Product.fromJson(e as Map<String, dynamic>))
          .toList();
    }

    final Map<String, dynamic> body =
        jsonDecode(response.body) as Map<String, dynamic>;
    final String message =
        body['message'] as String? ?? 'Failed to load alternatives';
    throw Exception(message);
  }

  /// Opens a bottom sheet with a searchable product grid.
  /// Returns the selected [Product] or null if dismissed.
  Future<void> _openProductPicker() async {
    final Product? picked = await showModalBottomSheet<Product>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => _ProductPickerSheet(products: _products),
    );
    if (picked != null) {
      await _selectProduct(picked);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.surface,
      extendBody: true,
      body: Stack(
        children: [
          SafeArea(
            bottom: false,
            child: SingleChildScrollView(
              padding: const EdgeInsets.only(bottom: 120),
              child: Column(
                children: <Widget>[
                  const SizedBox(height: 12),
                  const Text(
                    'Substitute',
                    style: TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  const SizedBox(height: 18),
                  if (_loading) ...[
                    const SizedBox(height: 120),
                    const CircularProgressIndicator(),
                  ] else if (_error != null) ...[
                    const SizedBox(height: 80),
                    Text(
                      _error!,
                      style: const TextStyle(color: Colors.redAccent),
                    ),
                    const SizedBox(height: 12),
                    ElevatedButton(
                      onPressed: _loadProducts,
                      child: const Text('Retry'),
                    ),
                  ] else ...[
                    _buildSelectedSection(),
                    const SizedBox(height: 18),
                    _buildAlternativesSection(),
                  ],
                ],
              ),
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
      bottomNavigationBar: _buildBottomBar(),
    );
  }

Widget _buildSelectedSection() {
  return Padding(
    padding: const EdgeInsets.symmetric(horizontal: 20),
    child: Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          SizedBox(
            width: 200,
            height: 140,
            child: GestureDetector(
              onTap: _openProductPicker,
              child: _selectedProduct == null
                  ? _buildAddMedicineCard()
                  : _buildSelectedCard(_selectedProduct!),
            ),
          ),

          const SizedBox(height: 20),

          const Icon(
            Icons.swap_vert_rounded,
            size: 34,
            color: AppColors.brandBlue,
          ),

          const SizedBox(height: 20),

          SizedBox(
            width: 200,
            height: 140,
            child: _loadingAlternative
                ? _buildLoadingSubstituteCard()
                : _substituteProduct == null
                    ? _buildEmptySubstituteCard()
                    : _buildSelectedCard(_substituteProduct!),
          ),
        ],
      ),
    ),
  );
}
  Widget _buildAlternativesSection() {
    if (_selectedProduct == null) return const SizedBox.shrink();
    if (_loadingAlternative) {
      return const Padding(
        padding: EdgeInsets.symmetric(vertical: 8),
        child: Center(child: CircularProgressIndicator()),
      );
    }
    if (_alternatives.isEmpty) {
      return const Padding(
        padding: EdgeInsets.symmetric(horizontal: 20),
        child: Text(
          'No alternatives with the same active ingredient.',
          style: TextStyle(color: Colors.black54),
        ),
      );
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Padding(
          padding: EdgeInsets.symmetric(horizontal: 20),
          child: Text(
            'Alternatives',
            style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700),
          ),
        ),
        const SizedBox(height: 12),
        SizedBox(
          height: 170,
          child: ListView.separated(
            padding: const EdgeInsets.symmetric(horizontal: 20),
            scrollDirection: Axis.horizontal,
            itemCount: _alternatives.length,
            separatorBuilder: (_, __) => const SizedBox(width: 12),
            itemBuilder: (context, index) {
              final Product product = _alternatives[index];
              final bool isSelected = _substituteProduct?.id == product.id;
              return InkWell(
                borderRadius: BorderRadius.circular(16),
                onTap: () => setState(() => _substituteProduct = product),
                child: _buildAlternativeCard(product, isSelected),
              );
            },
          ),
        ),
      ],
    );
  }

  Widget _buildAddMedicineCard() {
    return Container(
      width: 120,
      height: 120,
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.brandAccent, width: 1.5),
        boxShadow: const <BoxShadow>[
          BoxShadow(
            color: AppColors.cardShadow,
            blurRadius: 10,
            offset: Offset(0, 6),
          ),
        ],
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: const <Widget>[
          Icon(Icons.add_box_outlined, color: AppColors.brandBlue),
          SizedBox(height: 6),
          Text(
            'Add Medicine',
            style: TextStyle(fontSize: 11, fontWeight: FontWeight.w600),
          ),
        ],
      ),
    );
  }

  Widget _buildEmptySubstituteCard() {
    return Container(
      width: 120,
      height: 120,
      decoration: BoxDecoration(
        color: AppColors.cardBlue,
        borderRadius: BorderRadius.circular(16),
        boxShadow: const <BoxShadow>[
          BoxShadow(
            color: AppColors.cardShadow,
            blurRadius: 10,
            offset: Offset(0, 6),
          ),
        ],
      ),
    );
  }

  Widget _buildLoadingSubstituteCard() {
    return Container(
      width: 120,
      height: 120,
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: const <BoxShadow>[
          BoxShadow(
            color: AppColors.cardShadow,
            blurRadius: 10,
            offset: Offset(0, 6),
          ),
        ],
      ),
      child: const Center(child: CircularProgressIndicator()),
    );
  }

  Widget _buildSelectedCard(Product product) {
    return Container(
      width: 160,
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: const <BoxShadow>[
          BoxShadow(
            color: AppColors.cardShadow,
            blurRadius: 10,
            offset: Offset(0, 6),
          ),
        ],
      ),
      child: Column(
        children: <Widget>[
          ClipRRect(
            borderRadius: const BorderRadius.vertical(top: Radius.circular(16)),
            child: Image.network(
              product.imageUrl,
              height: 90,
              width: double.infinity,
              fit: BoxFit.cover,
              errorBuilder: (_, __, ___) => Container(
                height: 90,
                color: Colors.grey.shade100,
                child: const Icon(Icons.medication_outlined),
              ),
            ),
          ),
          Container(
            width: double.infinity,
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
            decoration: const BoxDecoration(
              color: AppColors.cardBlue,
              borderRadius:
                  BorderRadius.vertical(bottom: Radius.circular(16)),
            ),
            child: Row(
              children: <Widget>[
                Expanded(
                  child: Text(
                    product.name,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
                const SizedBox(width: 6),
                Text(
                  product.price,
                  style: const TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildAlternativeCard(Product product, bool isSelected) {
    return Container(
      width: 140,
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: isSelected ? AppColors.brandBlue : Colors.transparent,
          width: 1.5,
        ),
        boxShadow: const <BoxShadow>[
          BoxShadow(
            color: AppColors.cardShadow,
            blurRadius: 10,
            offset: Offset(0, 6),
          ),
        ],
      ),
      child: Column(
        children: <Widget>[
          Expanded(
            child: ClipRRect(
              borderRadius:
                  const BorderRadius.vertical(top: Radius.circular(16)),
              child: Image.network(
                product.imageUrl,
                fit: BoxFit.cover,
                errorBuilder: (_, __, ___) => Container(
                  color: Colors.grey.shade100,
                  child: const Icon(Icons.medication_outlined, size: 40),
                ),
              ),
            ),
          ),
          Container(
            width: double.infinity,
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
            decoration: const BoxDecoration(
              color: AppColors.cardBlue,
              borderRadius:
                  BorderRadius.vertical(bottom: Radius.circular(16)),
            ),
            child: Row(
              children: <Widget>[
                Expanded(
                  child: Text(
                    product.name,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
                const SizedBox(width: 6),
                Text(
                  product.price,
                  style: const TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildBottomBar() {
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
                onTap: () => Navigator.of(context).pop(),
              ),
            ),
            const Expanded(
              child: _BottomNavItem(
                icon: Icons.swap_horiz,
                label: 'Substitute',
                isActive: true,
              ),
            ),
            const SizedBox(width: 36),
            Expanded(
              child: _BottomNavItem(
                icon: Icons.shopping_cart_outlined,
                label: 'Cart',
                onTap: () {
                  Navigator.of(context).push(
                    MaterialPageRoute<void>(builder: (_) => const CartPage()),
                  );
                },
              ),
            ),
            Expanded(
              child: _BottomNavItem(
                icon: Icons.person_outline,
                label: 'Profile',
                onTap: () {
                  Navigator.of(context).push(
                    MaterialPageRoute<void>(
                        builder: (_) => const ProfilePage()),
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
        heroTag: 'chatFabSubstitute',
        mini: true,
        backgroundColor: AppColors.brandBlue,
        onPressed: () {
          Navigator.of(context).push(
            MaterialPageRoute<void>(
                builder: (_) => const ConsultationsPage()),
          );
        },
        child: const Icon(Icons.chat_bubble_outline, color: Colors.white),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Bottom-sheet widget: searchable product picker
// ─────────────────────────────────────────────────────────────────────────────

class _ProductPickerSheet extends StatefulWidget {
  const _ProductPickerSheet({required this.products});

  final List<Product> products;

  @override
  State<_ProductPickerSheet> createState() => _ProductPickerSheetState();
}

class _ProductPickerSheetState extends State<_ProductPickerSheet> {
  String _query = '';

  @override
  Widget build(BuildContext context) {
    final String q = _query.toLowerCase();
    final List<Product> filtered = widget.products
        .where(
          (p) =>
              p.name.toLowerCase().contains(q) ||
              p.activeIngredient.toLowerCase().contains(q),
        )
        .toList();

    return DraggableScrollableSheet(
      initialChildSize: 0.85,
      minChildSize: 0.5,
      maxChildSize: 0.95,
      expand: false,
      builder: (context, scrollController) {
        return Container(
          decoration: const BoxDecoration(
            color: AppColors.surface,
            borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
          ),
          child: Column(
            children: [
              // Handle
              const SizedBox(height: 10),
              Container(
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: Colors.black26,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
              const SizedBox(height: 14),
              const Text(
                'Select Medicine',
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700),
              ),
              const SizedBox(height: 12),
              // Search
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 20),
                child: Container(
                  height: 42,
                  padding: const EdgeInsets.symmetric(horizontal: 12),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(22),
                    boxShadow: const [
                      BoxShadow(
                        color: AppColors.cardShadow,
                        blurRadius: 10,
                        offset: Offset(0, 6),
                      ),
                    ],
                  ),
                  child: Row(
                    children: [
                      const Icon(Icons.search, size: 18, color: Colors.black54),
                      const SizedBox(width: 8),
                      Expanded(
                        child: TextField(
                          autofocus: true,
                          onChanged: (v) => setState(() => _query = v),
                          decoration: const InputDecoration(
                            hintText: 'Search',
                            border: InputBorder.none,
                            isDense: true,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 12),
              // Grid
              Expanded(
                child: filtered.isEmpty
                    ? const Center(child: Text('No products found'))
                    : GridView.builder(
                        controller: scrollController,
                        padding: const EdgeInsets.fromLTRB(20, 4, 20, 20),
                        itemCount: filtered.length,
                        gridDelegate:
                            const SliverGridDelegateWithFixedCrossAxisCount(
                          crossAxisCount: 2,
                          mainAxisSpacing: 16,
                          crossAxisSpacing: 16,
                          childAspectRatio: 0.78,
                        ),
                        itemBuilder: (context, index) {
                          final Product product = filtered[index];
                          return InkWell(
                            borderRadius: BorderRadius.circular(16),
                            onTap: () => Navigator.of(context).pop(product),
                            child: Container(
                              decoration: BoxDecoration(
                                color: Colors.white,
                                borderRadius: BorderRadius.circular(16),
                                boxShadow: const [
                                  BoxShadow(
                                    color: AppColors.cardShadow,
                                    blurRadius: 10,
                                    offset: Offset(0, 6),
                                  ),
                                ],
                              ),
                              child: Column(
                                children: [
                                  Expanded(
                                    child: ClipRRect(
                                      borderRadius:
                                          const BorderRadius.vertical(
                                        top: Radius.circular(16),
                                      ),
                                      child: Image.network(
                                        product.imageUrl,
                                        fit: BoxFit.cover,
                                        errorBuilder: (_, __, ___) =>
                                            Container(
                                          color: Colors.grey.shade100,
                                          child: const Icon(
                                            Icons.medication_outlined,
                                            size: 40,
                                          ),
                                        ),
                                      ),
                                    ),
                                  ),
                                  Container(
                                    width: double.infinity,
                                    padding: const EdgeInsets.symmetric(
                                      horizontal: 10,
                                      vertical: 8,
                                    ),
                                    decoration: const BoxDecoration(
                                      color: AppColors.cardBlue,
                                      borderRadius: BorderRadius.vertical(
                                        bottom: Radius.circular(16),
                                      ),
                                    ),
                                    child: Row(
                                      children: [
                                        Expanded(
                                          child: Text(
                                            product.name,
                                            maxLines: 1,
                                            overflow: TextOverflow.ellipsis,
                                            style: const TextStyle(
                                              fontSize: 12,
                                              fontWeight: FontWeight.w600,
                                            ),
                                          ),
                                        ),
                                        const SizedBox(width: 6),
                                        Text(
                                          product.price,
                                          style: const TextStyle(
                                            fontSize: 12,
                                            fontWeight: FontWeight.w600,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          );
                        },
                      ),
              ),
            ],
          ),
        );
      },
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────

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