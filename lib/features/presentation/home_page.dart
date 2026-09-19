import 'package:flutter/material.dart';
import 'dart:async';
import '../../core/localization/app_localization.dart';
import '../../core/theme/app_colors.dart';
import '../catalog/models/category.dart';
import '../catalog/models/product.dart';
import '../catalog/presentation/category_page.dart';
import '../catalog/presentation/product_details_page.dart';
import '../news/presentation/news_page.dart';
import '../admin/presentation/admin_create_doctor_page.dart';
import '../admin/presentation/admin_product_form_page.dart';
import 'substitute_page.dart';
import '../cart/presentation/cart_page.dart';
import '../chat/presentation/consultations_page.dart';
import '../profile/presentation/profile_page.dart';
import '../../../core/services/api_services.dart';
import '../../../core/services/auth_session.dart';
import '../../../core/services/push_notification_service.dart';
import '../auth/presentation/scan_prescription_screen.dart';

class HomePage extends StatefulWidget {
  const HomePage({super.key, required this.title});

  final String title;

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  final TextEditingController _searchController = TextEditingController();
  void _onSearchChanged(String value) {
    _searchDebounce?.cancel();
    _searchDebounce = Timer(const Duration(milliseconds: 500), () {
      _loadProducts(search: value);
    });
  }

  @override
  void dispose() {
    _searchDebounce?.cancel();
    _searchController.dispose();
    super.dispose();
  }

  Timer? _searchDebounce;
  List<Category> _categories = [];
  List<Product> _products = [];
  bool _loading = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    if (AuthSession.token != null && AuthSession.token!.isNotEmpty) {
      PushNotificationService.startInAppNotificationPolling();
      PushNotificationService.registerTokenWithBackend();
    }
    _loadInitialData();
  }

  Future<void> _loadInitialData() async {
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      final results = await Future.wait([
        ApiService.fetchCategories(),
        ApiService.fetchMedicines(),
      ]);
      setState(() {
        _categories = results[0] as List<Category>;
        _products = results[1] as List<Product>;
        _loading = false;
      });
    } catch (e) {
      setState(() {
        _error = e.toString();
        _loading = false;
      });
    }
  }

  Future<void> _loadProducts({String? search}) async {
    try {
      final products = await ApiService.fetchMedicines(search: search);
      setState(() {
        _products = products;
        _error = null;
      });
    } catch (e) {
      setState(() {
        _error = e.toString();
      });
    }
  }

  Future<void> _openProductForm({Product? product}) async {
    final bool? updated = await Navigator.of(context).push(
      MaterialPageRoute<bool>(
        builder: (_) =>
            AdminProductFormPage(product: product, categories: _categories),
      ),
    );
    if (updated == true) {
      await _loadInitialData();
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizer.of(context);
    final bool isAdmin = AuthSession.role == 'admin';
    return Scaffold(
      backgroundColor: AppColors.surface,
      extendBody: true,
      body: Stack(
        children: [
          SafeArea(
            bottom: false,
            child: _loading
                ? const Center(child: CircularProgressIndicator())
                : _error != null
                ? Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const Icon(
                          Icons.wifi_off,
                          size: 48,
                          color: Colors.grey,
                        ),
                        const SizedBox(height: 12),
                        Text(l10n.t('serverError')),
                        const SizedBox(height: 8),
                        ElevatedButton(
                          onPressed: _loadInitialData,
                          child: Text(l10n.t('retry')),
                        ),
                      ],
                    ),
                  )
                : SingleChildScrollView(
                    padding: const EdgeInsets.only(bottom: 120),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: <Widget>[
                        _buildHeader(context),
                        const SizedBox(height: 16),
                        _buildSectionHeader(title: l10n.t('categories')),
                        const SizedBox(height: 12),
                        _buildCategoryList(),
                        const SizedBox(height: 16),
                        _buildSectionHeader(title: l10n.t('items')),
                        const SizedBox(height: 12),
                        _buildProductGrid(isAdmin: isAdmin),
                      ],
                    ),
                  ),
          ),
          _buildChatFab(context),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () {
          Navigator.push(
            context,
            MaterialPageRoute(builder: (context) => ScanPrescriptionScreen()),
          );
        },
        backgroundColor: AppColors.brandAccent,
        child: const Icon(Icons.qr_code_scanner, color: Colors.black),
      ),
      floatingActionButtonLocation: FloatingActionButtonLocation.centerDocked,
      bottomNavigationBar: _buildBottomBar(context),
    );
  }

  Widget _buildHeader(BuildContext context) {
    final l10n = AppLocalizer.of(context);
    final bool isAdmin = AuthSession.role == 'admin';
    return Container(
      padding: const EdgeInsets.fromLTRB(20, 18, 20, 22),
      decoration: const BoxDecoration(
        color: AppColors.brandBlue,
        borderRadius: BorderRadius.vertical(bottom: Radius.circular(22)),
      ),
      child: Row(
        children: <Widget>[
          Expanded(
            child: Container(
              height: 46,
              padding: const EdgeInsets.symmetric(horizontal: 14),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(28),
                boxShadow: const <BoxShadow>[
                  BoxShadow(
                    color: AppColors.cardShadow,
                    blurRadius: 12,
                    offset: Offset(0, 6),
                  ),
                ],
              ),
              child: Row(
                children: <Widget>[
                  const Icon(Icons.search, color: Colors.black54),
                  const SizedBox(width: 8),
                  Expanded(
                    child: TextField(
                      controller: _searchController,
                      onChanged: _onSearchChanged,
                      decoration: InputDecoration(
                        hintText: l10n.t('search'),
                        border: InputBorder.none,
                        isDense: true,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(width: 14),
          Container(
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.08),
              borderRadius: BorderRadius.circular(16),
            ),
            child: IconButton(
              onPressed: () {
                Navigator.of(context).push(
                  MaterialPageRoute<void>(builder: (_) => const NewsPage()),
                );
              },
              icon: const Icon(Icons.campaign_outlined, color: Colors.white),
              tooltip: l10n.t('news'),
            ),
          ),
          if (isAdmin) ...[
            const SizedBox(width: 10),
            Container(
              decoration: BoxDecoration(
                color: Colors.white.withValues(alpha: 0.08),
                borderRadius: BorderRadius.circular(16),
              ),
              child: IconButton(
                onPressed: () => _openProductForm(),
                icon: const Icon(Icons.add_box_outlined, color: Colors.white),
                tooltip: 'Add Product',
              ),
            ),
            const SizedBox(width: 10),
            Container(
              decoration: BoxDecoration(
                color: Colors.white.withValues(alpha: 0.08),
                borderRadius: BorderRadius.circular(16),
              ),
              child: IconButton(
                onPressed: () {
                  Navigator.of(context).push(
                    MaterialPageRoute<void>(
                      builder: (_) => const AdminCreateDoctorPage(),
                    ),
                  );
                },
                icon: const Icon(
                  Icons.medical_services_outlined,
                  color: Colors.white,
                ),
                tooltip: 'Create Doctor',
              ),
            ),
          ],
          const SizedBox(width: 10),
        ],
      ),
    );
  }

  Widget _buildSectionHeader({required String title}) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: <Widget>[
          Text(
            title,
            style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w600),
          ),
        ],
      ),
    );
  }

  Widget _buildCategoryList() {
    final l10n = AppLocalizer.of(context);
    return SizedBox(
      height: 110,
      child: ListView.separated(
        padding: const EdgeInsets.symmetric(horizontal: 20),
        scrollDirection: Axis.horizontal,

        itemBuilder: (BuildContext context, int index) {
          final Category item = _categories[index];
          return InkWell(
            onTap: () {
              Navigator.of(context).push(
                MaterialPageRoute<void>(
                  builder: (_) =>
                      CategoryPage(category: item, products: _products),
                ),
              );
            },
            borderRadius: BorderRadius.circular(16),
            child: SizedBox(
              width: 84,
              child: Column(
                children: <Widget>[
                  _buildCircleImage(item.imageUrl),
                  const SizedBox(height: 8),
                  Text(
                    item.localizedName(l10n.languageCode),
                    maxLines: 2,
                    textAlign: TextAlign.center,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(fontSize: 12),
                  ),
                ],
              ),
            ),
          );
        },
        separatorBuilder: (_, __) => const SizedBox(width: 12),
        itemCount: _categories.length,
      ),
    );
  }

  Widget _buildProductGrid({required bool isAdmin}) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: GridView.builder(
        itemCount: _products.length,
        shrinkWrap: true,
        physics: const NeverScrollableScrollPhysics(),
        gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
          crossAxisCount: 2,
          mainAxisSpacing: 16,
          crossAxisSpacing: 16,
          childAspectRatio: 0.78,
        ),
        itemBuilder: (BuildContext context, int index) {
          final Product item = _products[index];
          return Stack(
            children: [
              InkWell(
                borderRadius: BorderRadius.circular(18),
                onTap: () {
                  Navigator.of(context).push(
                    MaterialPageRoute<void>(
                      builder: (_) => ProductDetailsPage(product: item),
                    ),
                  );
                },
                child: Container(
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
                  child: Column(
                    children: <Widget>[
                      Expanded(
                        child: ClipRRect(
                          borderRadius: const BorderRadius.vertical(
                            top: Radius.circular(18),
                          ),
                          child: _buildRectImage(item.imageUrl),
                        ),
                      ),
                      Container(
                        width: double.infinity,
                        padding: const EdgeInsets.symmetric(
                          horizontal: 12,
                          vertical: 10,
                        ),
                        decoration: const BoxDecoration(
                          color: AppColors.cardBlue,
                          borderRadius: BorderRadius.vertical(
                            bottom: Radius.circular(18),
                          ),
                        ),
                        child: Row(
                          children: <Widget>[
                            Expanded(
                              child: Text(
                                item.name,
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                style: const TextStyle(
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ),
                            const SizedBox(width: 8),
                            Text(
                              item.price,
                              style: const TextStyle(
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              if (isAdmin)
                Positioned(
                  top: 8,
                  right: 8,
                  child: Material(
                    color: Colors.white.withValues(alpha: 0.9),
                    shape: const CircleBorder(),
                    child: IconButton(
                      icon: const Icon(Icons.edit, size: 18),
                      color: AppColors.brandBlue,
                      onPressed: () => _openProductForm(product: item),
                      tooltip: 'Edit Product',
                    ),
                  ),
                ),
              if (item.isOutOfStock)
                const Positioned(top: 8, left: 8, child: _OutOfStockBadge()),
            ],
          );
        },
      ),
    );
  }

  Widget _buildCircleImage(String url) {
    return ClipOval(
      child: SizedBox(
        width: 58,
        height: 58,
        child: Image.network(
          url,
          fit: BoxFit.cover,
          errorBuilder: (_, __, ___) => Container(
            color: Colors.grey.shade200,
            child: const Icon(Icons.medical_services_outlined),
          ),
        ),
      ),
    );
  }

  Widget _buildRectImage(String url) {
    return Image.network(
      url,
      fit: BoxFit.cover,
      errorBuilder: (_, __, ___) => Container(
        color: Colors.grey.shade100,
        child: const Icon(Icons.medication_outlined, size: 48),
      ),
    );
  }

  Widget _buildBottomBar(BuildContext context) {
    final l10n = AppLocalizer.of(context);
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
                label: l10n.t('home'),
                isActive: true,
                onTap: () {},
              ),
            ),
            Expanded(
              child: _BottomNavItem(
                icon: Icons.swap_horiz,
                label: l10n.t('substitute'),
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
            Expanded(
              child: _BottomNavItem(
                icon: Icons.shopping_cart_outlined,
                label: l10n.t('cart'),
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
                label: l10n.t('profile'),
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
        heroTag: 'chatFabHome',
        mini: true,
        backgroundColor: AppColors.brandBlue,
        onPressed: () {
          Navigator.of(context).push(
            MaterialPageRoute<void>(builder: (_) => const ConsultationsPage()),
          );
        },
        child: const Icon(Icons.chat_bubble_outline, color: Colors.white),
      ),
    );
  }
}

class _OutOfStockBadge extends StatelessWidget {
  const _OutOfStockBadge();

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: Colors.red.shade600,
        borderRadius: BorderRadius.circular(12),
      ),
      child: const Text(
        'Out of stock',
        style: TextStyle(
          color: Colors.white,
          fontSize: 11,
          fontWeight: FontWeight.w700,
        ),
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
