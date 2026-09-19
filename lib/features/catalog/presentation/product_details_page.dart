import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/theme/app_colors.dart';
import '../../cart/presentation/cart_provider.dart';
import '../data/prescription_repository.dart';
import 'prescription_request.dart';
import '../data/catalog_data.dart';
import '../models/product.dart';
import 'prescription_scan_page.dart';
import '../../reminders/presentation/add_reminder_sheet.dart';

class ProductDetailsPage extends StatefulWidget {
  const ProductDetailsPage({super.key, required this.product});

  final Product product;

  @override
  State<ProductDetailsPage> createState() => _ProductDetailsPageState();
}

class _ProductDetailsPageState extends State<ProductDetailsPage> {
  // Set after user submits a prescription — used to poll status
  String? _requestId;

  // ── Add to cart (shared between prescription-gated and normal) ─────────────
  Future<void> _addToCart() async {
    if (widget.product.isOutOfStock) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('Out of stock')));
      return;
    }
    try {
      await CartProvider.of(context).add(widget.product);
      if (!mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('Added to cart ✅')));
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text(e.toString())));
    }
  }

  @override
  Widget build(BuildContext context) {
    final List<Product> related = CatalogData.relatedProducts(
      widget.product,
      limit: 2,
    );

    return Scaffold(
      backgroundColor: AppColors.surface,
      appBar: AppBar(
        elevation: 0,
        backgroundColor: Colors.white,
        foregroundColor: Colors.black,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new),
          onPressed: () => Navigator.of(context).pop(),
        ),
        actions: <Widget>[
          IconButton(
            tooltip: 'Set a reminder',
            onPressed: () => showAddReminderSheet(
              context,
              medicineName: widget.product.name,
              productId: widget.product.id,
            ),
            icon: const Icon(Icons.alarm_add_outlined),
          ),
          IconButton(onPressed: () {}, icon: const Icon(Icons.favorite_border)),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.fromLTRB(20, 12, 20, 20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: <Widget>[
            // ── Hero image ─────────────────────────────────────────────────
            _buildHeroImage(widget.product.imageUrl),
            const SizedBox(height: 16),

            // ── Name + price ───────────────────────────────────────────────
            Row(
              children: <Widget>[
                Expanded(
                  child: Text(
                    widget.product.name,
                    style: const TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
                Text(
                  widget.product.price,
                  style: const TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 6),

            // ── Description ────────────────────────────────────────────────
            Text(
              widget.product.description,
              style: const TextStyle(color: Colors.black54, height: 1.4),
            ),
            if (widget.product.isOutOfStock) ...<Widget>[
              const SizedBox(height: 12),
              _buildOutOfStockBanner(),
            ],
            const SizedBox(height: 16),

            // ── Info card ──────────────────────────────────────────────────
            _buildInfoCard(widget.product),
            const SizedBox(height: 18),

            // ── Prescription section ───────────────────────────────────────
            if (widget.product.requiresPrescription) ...<Widget>[
              // Show plain warning before submission, live status after
              _requestId == null
                  ? _buildWarningBanner()
                  : _buildStatusBanner(_requestId!),
              const SizedBox(height: 12),
            ],

            // ── Add to Cart button ─────────────────────────────────────────
            widget.product.requiresPrescription
                ? _buildPrescriptionButton()
                : _buildNormalAddButton(),

            const SizedBox(height: 22),

            // ── Related products ───────────────────────────────────────────
            const Text(
              'Related products',
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
            ),
            const SizedBox(height: 12),
            SizedBox(
              height: 150,
              child: ListView.separated(
                scrollDirection: Axis.horizontal,
                itemCount: related.length,
                separatorBuilder: (_, __) => const SizedBox(width: 12),
                itemBuilder: (BuildContext context, int index) {
                  final Product item = related[index];
                  return _RelatedCard(
                    product: item,
                    onTap: () => Navigator.of(context).push(
                      MaterialPageRoute<void>(
                        builder: (_) => ProductDetailsPage(product: item),
                      ),
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

  // ── Static orange warning (not yet submitted) ──────────────────────────────
  Widget _buildWarningBanner() {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.orange.shade50,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.orange.shade200),
      ),
      child: Row(
        children: <Widget>[
          Icon(Icons.warning_amber_rounded, color: Colors.orange.shade700),
          const SizedBox(width: 10),
          const Expanded(
            child: Text(
              'This medicine requires a valid prescription. '
              'You will need to upload it before adding to cart.',
              style: TextStyle(fontSize: 12),
            ),
          ),
        ],
      ),
    );
  }

  // ── Live status banner — polls every 5 s via Stream ───────────────────────
  Widget _buildStatusBanner(String requestId) {
    return Consumer(
      builder: (BuildContext context, WidgetRef ref, _) {
            final AsyncValue<PrescriptionRequest?> snap =
                ref.watch(prescriptionStatusProvider(requestId));
            // Still loading first result
            if (!snap.hasValue) {
              return const LinearProgressIndicator();
            }

            final PrescriptionRequest? req = snap.value;
            if (req == null) return const SizedBox.shrink();

            switch (req.status) {
              case PrescriptionStatus.pending:
                return _statusTile(
                  icon: Icons.hourglass_top_rounded,
                  color: Colors.orange,
                  title: 'Prescription under review',
                  subtitle: 'Our pharmacist will confirm it shortly.',
                );

              case PrescriptionStatus.approved:
                return _statusTile(
                  icon: Icons.check_circle_outline,
                  color: Colors.green,
                  title: 'Prescription approved!',
                  subtitle:
                      req.adminNote ??
                      'You can now add this item to your cart.',
                );

              case PrescriptionStatus.rejected:
                return _statusTile(
                  icon: Icons.cancel_outlined,
                  color: Colors.red,
                  title: 'Prescription rejected',
                  subtitle:
                      req.adminNote ?? 'Please upload a new prescription.',
                  // Let the user try again
                  onRetry: () => setState(() => _requestId = null),
                );
            }
          },
    );
  }

  Widget _statusTile({
    required IconData icon,
    required Color color,
    required String title,
    required String subtitle,
    VoidCallback? onRetry,
  }) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: color.withValues(alpha: 0.35)),
      ),
      child: Row(
        children: <Widget>[
          Icon(icon, color: color),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: <Widget>[
                Text(
                  title,
                  style: TextStyle(
                    fontWeight: FontWeight.w600,
                    color: color,
                    fontSize: 13,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  subtitle,
                  style: const TextStyle(fontSize: 12, color: Colors.black54),
                ),
              ],
            ),
          ),
          if (onRetry != null)
            TextButton(onPressed: onRetry, child: const Text('Retry')),
        ],
      ),
    );
  }

  // ── Prescription-gated Add to Cart button ──────────────────────────────────
  Widget _buildPrescriptionButton() {
    if (widget.product.isOutOfStock) {
      return _cartButton(
        label: 'Out of stock',
        icon: Icons.inventory_2_outlined,
        onPressed: null,
      );
    }

    // Step 1 — no submission yet → open scan page
    if (_requestId == null) {
      return _cartButton(
        label: 'Scan Prescription & Add to Cart',
        icon: Icons.document_scanner_outlined,
        onPressed: () async {
          final String? requestId = await Navigator.of(context).push<String>(
            MaterialPageRoute<String>(
              builder: (_) => PrescriptionScanPage(
                productId: widget.product.id,
                medicineName: widget.product.name,
              ),
            ),
          );
          if (requestId != null) {
            setState(() => _requestId = requestId);
          }
        },
      );
    }

    // Step 2 — prescription submitted → react to live status
    return Consumer(
      builder: (BuildContext context, WidgetRef ref, _) {
            final AsyncValue<PrescriptionRequest?> snap =
                ref.watch(prescriptionStatusProvider(_requestId!));
            final PrescriptionStatus? status = snap.value?.status;

            // ✅ Approved — enable the real Add to Cart
            if (status == PrescriptionStatus.approved) {
              return _cartButton(
                label: 'Add to Cart',
                icon: Icons.shopping_cart_outlined,
                onPressed: _addToCart,
              );
            }

            // ❌ Rejected — show retry button
            if (status == PrescriptionStatus.rejected) {
              return _cartButton(
                label: 'Prescription Rejected — Tap to Retry',
                icon: Icons.cancel_outlined,
                onPressed: () => setState(() => _requestId = null),
                color: Colors.red.shade400,
              );
            }

            // ⏳ Pending (or still loading) — disabled
            return _cartButton(
              label: 'Awaiting Pharmacist Approval…',
              icon: Icons.hourglass_top_rounded,
              onPressed: null,
            );
          },
    );
  }

  // ── Normal Add to Cart (no prescription needed) ───────────────────────────
  Widget _buildNormalAddButton() {
    return _cartButton(
      label: widget.product.isOutOfStock ? 'Out of stock' : 'Add to Cart',
      icon: widget.product.isOutOfStock
          ? Icons.inventory_2_outlined
          : Icons.shopping_cart_outlined,
      onPressed: widget.product.isOutOfStock ? null : _addToCart,
    );
  }

  // ── Reusable styled button ─────────────────────────────────────────────────
  Widget _cartButton({
    required String label,
    required IconData icon,
    required VoidCallback? onPressed,
    Color? color,
  }) {
    final Color bg = onPressed == null
        ? Colors.grey.shade400
        : (color ?? AppColors.brandBlue);

    return SizedBox(
      width: double.infinity,
      child: ElevatedButton.icon(
        icon: Icon(icon, color: Colors.white, size: 18),
        label: Text(
          label,
          style: const TextStyle(
            fontWeight: FontWeight.w600,
            color: Colors.white,
          ),
        ),
        onPressed: onPressed,
        style: ElevatedButton.styleFrom(
          backgroundColor: bg,
          padding: const EdgeInsets.symmetric(vertical: 14),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(14),
          ),
        ),
      ),
    );
  }

  // ── Hero image ─────────────────────────────────────────────────────────────
  Widget _buildHeroImage(String url) {
    return Container(
      height: 220,
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
        boxShadow: const <BoxShadow>[
          BoxShadow(
            color: AppColors.cardShadow,
            blurRadius: 12,
            offset: Offset(0, 6),
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(18),
        child: Image.network(
          url,
          fit: BoxFit.cover,
          errorBuilder: (_, __, ___) => Container(
            color: Colors.grey.shade100,
            child: const Icon(Icons.medication_outlined, size: 60),
          ),
        ),
      ),
    );
  }

  Widget _buildOutOfStockBanner() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.red.shade50,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.red.shade200),
      ),
      child: Row(
        children: <Widget>[
          Icon(Icons.inventory_2_outlined, color: Colors.red.shade700),
          const SizedBox(width: 10),
          const Expanded(
            child: Text(
              'Out of stock',
              style: TextStyle(fontWeight: FontWeight.w700),
            ),
          ),
        ],
      ),
    );
  }

  // ── Info card ──────────────────────────────────────────────────────────────
  Widget _buildInfoCard(Product product) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        boxShadow: const <BoxShadow>[
          BoxShadow(
            color: AppColors.cardShadow,
            blurRadius: 8,
            offset: Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        children: <Widget>[
          _infoRow(
            Icons.science_outlined,
            'Active Ingredient',
            product.activeIngredient,
          ),
          _infoRow(Icons.straighten, 'Strength', product.strength),
          _infoRow(
            Icons.inventory_2_outlined,
            'Stock',
            product.isOutOfStock ? 'Out of stock' : '${product.stock} units',
          ),
          if (product.discountPercent > 0)
            _infoRow(
              Icons.local_offer_outlined,
              'Discount',
              '${product.discountPercent.toInt()}% off',
            ),
          _infoRow(
            Icons.verified_user_outlined,
            'Prescription',
            product.requiresPrescription ? 'Required' : 'Not required',
          ),
          if (product.isFeatured)
            _infoRow(Icons.star_outline, 'Featured', 'Yes ⭐'),
          _infoRow(Icons.tag, 'Product ID', product.id),
        ],
      ),
    );
  }

  Widget _infoRow(IconData icon, String label, String value) {
    if (value.isEmpty) return const SizedBox.shrink();
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Row(
        children: <Widget>[
          Icon(icon, size: 18, color: AppColors.brandBlue),
          const SizedBox(width: 10),
          Text(
            label,
            style: const TextStyle(color: Colors.black54, fontSize: 13),
          ),
          const Spacer(),
          Text(
            value,
            style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 13),
          ),
        ],
      ),
    );
  }
}

// ── Related product card (unchanged) ──────────────────────────────────────────
class _RelatedCard extends StatelessWidget {
  const _RelatedCard({required this.product, required this.onTap});

  final Product product;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(16),
      child: Stack(
        children: [
          Container(
            width: 140,
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
                Expanded(
                  child: ClipRRect(
                    borderRadius: const BorderRadius.vertical(
                      top: Radius.circular(16),
                    ),
                    child: Image.network(
                      product.imageUrl,
                      fit: BoxFit.cover,
                      errorBuilder: (_, __, ___) => Container(
                        color: Colors.grey.shade100,
                        child: const Icon(Icons.medication_outlined),
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
          ),
          if (product.isOutOfStock)
            Positioned(
              top: 8,
              left: 8,
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: Colors.red.shade600,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: const Text(
                  'Out of stock',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 10,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }
}
