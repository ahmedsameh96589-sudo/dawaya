import 'package:flutter/material.dart';

import '../../catalog/models/category.dart';
import '../../catalog/models/product.dart';
import '../../catalog/data/catalog_repository.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

class AdminProductFormPage extends ConsumerStatefulWidget {
  const AdminProductFormPage({
    super.key,
    this.product,
    required this.categories,
  });

  final Product? product;
  final List<Category> categories;

  @override
  ConsumerState<AdminProductFormPage> createState() => _AdminProductFormPageState();
}

class _AdminProductFormPageState extends ConsumerState<AdminProductFormPage> {
  final _formKey = GlobalKey<FormState>();
  final TextEditingController nameController = TextEditingController();
  final TextEditingController priceController = TextEditingController();
  final TextEditingController descriptionController = TextEditingController();
  final TextEditingController imageController = TextEditingController();
  final TextEditingController discountController = TextEditingController();
  final TextEditingController stockController = TextEditingController();

  bool isLoading = false;
  bool _isFeatured = false;
  bool _requiresPrescription = false;
  bool _loadingCategories = false;
  List<Category> _categories = [];
  String? _selectedCategoryId;

  @override
  void initState() {
    super.initState();
    _categories = List<Category>.from(widget.categories);
    _seedForm();
    if (_categories.isEmpty) {
      _loadCategories();
    }
  }

  @override
  void dispose() {
    nameController.dispose();
    priceController.dispose();
    descriptionController.dispose();
    imageController.dispose();
    discountController.dispose();
    stockController.dispose();
    super.dispose();
  }

  void _seedForm() {
    final Product? product = widget.product;
    if (product == null) return;

    nameController.text = product.name;
    priceController.text = product.priceValue > 0
        ? product.priceValue.toStringAsFixed(0)
        : _priceFromText(product.price);
    descriptionController.text = product.description;
    imageController.text = product.imageUrl;
    discountController.text = product.discountPercent > 0
        ? product.discountPercent.toStringAsFixed(0)
        : '';
    stockController.text = product.stock > 0 ? product.stock.toString() : '';
    _requiresPrescription = product.requiresPrescription;
    _isFeatured = product.isFeatured;
    _selectedCategoryId = _categories.any((c) => c.id == product.categoryId)
        ? product.categoryId
        : null;
  }

  String _priceFromText(String priceText) {
    final match = RegExp(r'[\d.]+').firstMatch(priceText);
    return match?.group(0) ?? '';
  }

  Future<void> _loadCategories() async {
    setState(() => _loadingCategories = true);
    try {
      final categories = await ref.read(catalogRepositoryProvider).fetchCategories();
      if (!mounted) return;
      setState(() {
        _categories = categories;
        final String? preferredCategoryId = widget.product?.categoryId;
        if (preferredCategoryId != null &&
            categories.any((c) => c.id == preferredCategoryId)) {
          _selectedCategoryId = preferredCategoryId;
        } else if (_selectedCategoryId == null && categories.isNotEmpty) {
          _selectedCategoryId = categories.first.id;
        }
      });
    } catch (_) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Failed to load categories')),
      );
    } finally {
      if (mounted) setState(() => _loadingCategories = false);
    }
  }

  Future<void> _saveProduct() async {
    if (!_formKey.currentState!.validate()) return;
    final String? categoryId = _selectedCategoryId;
    if (categoryId == null) return;

    final double price = double.parse(priceController.text.trim());
    final double discount =
        double.tryParse(discountController.text.trim()) ?? 0;
    final int stock = int.tryParse(stockController.text.trim()) ?? 0;
    final String? description = descriptionController.text.trim().isEmpty
        ? null
        : descriptionController.text.trim();
    final String? imageUrl = imageController.text.trim().isEmpty
        ? null
        : imageController.text.trim();
    final List<String> images = imageUrl == null ? [] : [imageUrl];

    final input = MedicineInput(
      name: nameController.text.trim(),
      price: price,
      categoryId: categoryId,
      description: description,
      discountPercent: discount,
      stock: stock,
      images: images,
      requiresPrescription: _requiresPrescription,
      isFeatured: _isFeatured,
    );
    final catalog = ref.read(catalogRepositoryProvider);

    setState(() => isLoading = true);
    try {
      if (widget.product == null) {
        await catalog.createMedicine(input);
      } else {
        await catalog.updateMedicine(widget.product!.id, input);
      }
      ref.invalidate(medicinesProvider);

      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            widget.product == null
                ? 'Product added successfully'
                : 'Product updated successfully',
          ),
        ),
      );
      Navigator.of(context).pop(true);
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(e.toString())),
      );
    } finally {
      if (mounted) setState(() => isLoading = false);
    }
  }

  Future<void> _deleteProduct() async {
    if (widget.product == null) return;
    final bool? confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete product'),
        content: const Text('Are you sure you want to delete this product?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.of(context).pop(true),
            child: const Text('Delete'),
          ),
        ],
      ),
    );

    if (confirm != true) return;

    setState(() => isLoading = true);
    try {
      await ref.read(catalogRepositoryProvider).deleteMedicine(widget.product!.id);
      ref.invalidate(medicinesProvider);
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Product deleted successfully')),
      );
      Navigator.of(context).pop(true);
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(e.toString())),
      );
    } finally {
      if (mounted) setState(() => isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final bool hasCategories = _categories.isNotEmpty;
    final String title = widget.product == null ? 'Add Product' : 'Edit Product';
    return Scaffold(
      appBar: AppBar(
        title: Text(title),
        backgroundColor: Colors.white,
        foregroundColor: Colors.black,
        elevation: 0,
        actions: [
          if (widget.product != null)
            IconButton(
              onPressed: isLoading ? null : _deleteProduct,
              icon: const Icon(Icons.delete_outline),
              tooltip: 'Delete product',
            ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Form(
          key: _formKey,
          child: Column(
            children: [
              if (_loadingCategories)
                const Padding(
                  padding: EdgeInsets.only(bottom: 12),
                  child: LinearProgressIndicator(),
                ),
              _buildField(
                controller: nameController,
                label: 'Name',
                validator: (value) =>
                    value!.trim().isEmpty ? 'Name is required' : null,
              ),
              const SizedBox(height: 12),
              _buildField(
                controller: priceController,
                label: 'Price',
                keyboardType: TextInputType.number,
                validator: (value) {
                  if (value == null || value.trim().isEmpty) {
                    return 'Price is required';
                  }
                  final parsed = double.tryParse(value.trim());
                  if (parsed == null || parsed <= 0) {
                    return 'Enter a valid price';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 12),
              DropdownButtonFormField<String>(
                value: hasCategories ? _selectedCategoryId : null,
                items: _categories
                    .map(
                      (Category category) => DropdownMenuItem<String>(
                        value: category.id,
                        child: Text(category.name),
                      ),
                    )
                    .toList(),
                onChanged: hasCategories
                    ? (value) => setState(() => _selectedCategoryId = value)
                    : null,
                validator: (value) {
                  if (!hasCategories) return 'No categories available';
                  if (value == null || value.isEmpty) {
                    return 'Category is required';
                  }
                  return null;
                },
                decoration: InputDecoration(
                  labelText: 'Category',
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(14),
                  ),
                ),
              ),
              const SizedBox(height: 12),
              _buildField(
                controller: descriptionController,
                label: 'Description',
                maxLines: 3,
              ),
              const SizedBox(height: 12),
              _buildField(
                controller: imageController,
                label: 'Image URL',
              ),
              const SizedBox(height: 12),
              _buildField(
                controller: discountController,
                label: 'Discount %',
                keyboardType: TextInputType.number,
                validator: (value) {
                  if (value == null || value.trim().isEmpty) {
                    return null;
                  }
                  final parsed = double.tryParse(value.trim());
                  if (parsed == null || parsed < 0 || parsed > 100) {
                    return 'Enter a valid discount';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 12),
              _buildField(
                controller: stockController,
                label: 'Stock',
                keyboardType: TextInputType.number,
                validator: (value) {
                  if (value == null || value.trim().isEmpty) {
                    return null;
                  }
                  final parsed = int.tryParse(value.trim());
                  if (parsed == null || parsed < 0) {
                    return 'Enter a valid stock';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 8),
              SwitchListTile(
                value: _requiresPrescription,
                onChanged: (value) =>
                    setState(() => _requiresPrescription = value),
                title: const Text('Requires prescription'),
                contentPadding: EdgeInsets.zero,
              ),
             
              const SizedBox(height: 16),
              SizedBox(
                width: double.infinity,
                height: 48,
                child: ElevatedButton(
                  onPressed: isLoading ? null : _saveProduct,
                  child: isLoading
                      ? const SizedBox(
                          height: 20,
                          width: 20,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            color: Colors.white,
                          ),
                        )
                      : Text(title),
                ),
              ),
              if (widget.product != null) ...[
                const SizedBox(height: 12),
                SizedBox(
                  width: double.infinity,
                  height: 48,
                  child: OutlinedButton(
                    onPressed: isLoading ? null : _deleteProduct,
                    style: OutlinedButton.styleFrom(
                      foregroundColor: Colors.redAccent,
                      side: const BorderSide(color: Colors.redAccent),
                    ),
                    child: const Text('Delete Product'),
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildField({
    required TextEditingController controller,
    required String label,
    TextInputType keyboardType = TextInputType.text,
    String? Function(String?)? validator,
    int maxLines = 1,
  }) {
    return TextFormField(
      controller: controller,
      keyboardType: keyboardType,
      validator: validator,
      maxLines: maxLines,
      decoration: InputDecoration(
        labelText: label,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
        ),
      ),
    );
  }
}
