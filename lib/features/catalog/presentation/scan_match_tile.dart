import 'package:flutter/material.dart';

import '../data/medicine_matcher.dart';
import '../models/product.dart';

/// What the user can do with a scanned medicine that matched the catalog.
enum ScanMatchAction {
  /// In stock and needs no prescription: add straight to the cart.
  add,

  /// Needs a pharmacist-approved prescription: open the product page.
  open,

  /// Out of stock: look for an alternative with the same active ingredient.
  findSubstitute,
}

ScanMatchAction actionFor(Product product) {
  if (product.isOutOfStock) return ScanMatchAction.findSubstitute;
  if (product.requiresPrescription) return ScanMatchAction.open;
  return ScanMatchAction.add;
}

/// The catalog product found for one scanned prescription line, shown under
/// the scanned text in the scan results sheet.
class ScanMatchTile extends StatelessWidget {
  const ScanMatchTile({
    super.key,
    required this.match,
    required this.isLoadingCatalog,
    required this.isAdded,
    required this.isBusy,
    required this.substitute,
    required this.accent,
    required this.textPrimary,
    required this.textSecondary,
    required this.onAdd,
    required this.onOpen,
    required this.onFindSubstitute,
  });

  final MedicineMatch? match;
  final bool isLoadingCatalog;
  final bool isAdded;
  final bool isBusy;

  /// An in-stock alternative, once the user asked for one.
  final Product? substitute;

  final Color accent, textPrimary, textSecondary;
  final ValueChanged<Product> onAdd;
  final ValueChanged<Product> onOpen;
  final ValueChanged<Product> onFindSubstitute;

  @override
  Widget build(BuildContext context) {
    if (isLoadingCatalog) {
      return _note(Icons.sync, 'Looking for this medicine in the pharmacy…');
    }
    final match = this.match;
    if (match == null) {
      return _note(
        Icons.help_outline,
        'Not found in our catalog. Ask a pharmacist.',
      );
    }

    final product = substitute ?? match.product;
    final action = actionFor(product);

    return Container(
      margin: const EdgeInsets.only(top: 12),
      padding: const EdgeInsets.all(10),
      decoration: BoxDecoration(
        color: accent.withOpacity(0.08),
        borderRadius: BorderRadius.circular(10),
      ),
      child: Row(
        children: [
          ClipRRect(
            borderRadius: BorderRadius.circular(8),
            child: Image.network(
              product.imageUrl,
              width: 44,
              height: 44,
              fit: BoxFit.cover,
              errorBuilder: (_, __, ___) => Container(
                width: 44,
                height: 44,
                color: accent.withOpacity(0.15),
                child: Icon(Icons.medication, color: accent, size: 22),
              ),
            ),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                if (substitute != null)
                  Text(
                    'Substitute (same active ingredient)',
                    style: TextStyle(
                      color: accent,
                      fontSize: 11,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                Text(
                  product.name,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    color: textPrimary,
                    fontWeight: FontWeight.w600,
                    fontSize: 14,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  _subtitle(product, match),
                  style: TextStyle(color: textSecondary, fontSize: 12),
                ),
              ],
            ),
          ),
          const SizedBox(width: 8),
          _actionButton(product, action),
        ],
      ),
    );
  }

  String _subtitle(Product product, MedicineMatch match) {
    final parts = <String>[product.price];
    if (product.requiresPrescription) parts.add('Rx required');
    if (product.isOutOfStock) parts.add('Out of stock');
    if (substitute == null && match.confidence < 0.9) parts.add('Best guess');
    return parts.join(' · ');
  }

  Widget _actionButton(Product product, ScanMatchAction action) {
    if (isBusy) {
      return SizedBox(
        width: 22,
        height: 22,
        child: CircularProgressIndicator(strokeWidth: 2, color: accent),
      );
    }
    if (isAdded) {
      return Icon(
        Icons.check_circle,
        color: accent,
        semanticLabel: 'Added to cart',
      );
    }
    return switch (action) {
      ScanMatchAction.add => _button(
        'Add',
        Icons.add_shopping_cart,
        () => onAdd(product),
      ),
      ScanMatchAction.open => _button(
        'Upload Rx',
        Icons.upload_file,
        () => onOpen(product),
      ),
      ScanMatchAction.findSubstitute => _button(
        'Substitute',
        Icons.swap_horiz,
        () => onFindSubstitute(product),
      ),
    };
  }

  Widget _button(String label, IconData icon, VoidCallback onPressed) {
    return TextButton.icon(
      onPressed: onPressed,
      icon: Icon(icon, size: 16),
      label: Text(label),
      style: TextButton.styleFrom(
        foregroundColor: accent,
        padding: const EdgeInsets.symmetric(horizontal: 10),
        visualDensity: VisualDensity.compact,
      ),
    );
  }

  Widget _note(IconData icon, String text) {
    return Padding(
      padding: const EdgeInsets.only(top: 10),
      child: Row(
        children: [
          Icon(icon, size: 14, color: textSecondary),
          const SizedBox(width: 6),
          Expanded(
            child: Text(
              text,
              style: TextStyle(color: textSecondary, fontSize: 12),
            ),
          ),
        ],
      ),
    );
  }
}
