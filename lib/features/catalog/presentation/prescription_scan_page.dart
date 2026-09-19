import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:image_picker/image_picker.dart';
import '../../../core/theme/app_colors.dart';
import '../data/prescription_repository.dart';
import 'package:path_provider/path_provider.dart';

class PrescriptionScanPage extends ConsumerStatefulWidget {
  const PrescriptionScanPage({
    super.key,
    required this.productId,
    required this.medicineName,
  });

  final String productId;
  final String medicineName;

  @override
  ConsumerState<PrescriptionScanPage> createState() => _PrescriptionScanPageState();
}

class _PrescriptionScanPageState extends ConsumerState<PrescriptionScanPage> {
  File? _image;
  bool _isUploading = false;
  final ImagePicker _picker = ImagePicker();

  // ── Pick image from camera or gallery ──────────────────────────────────────
Future<void> _pick(ImageSource source) async {
  final XFile? picked = await _picker.pickImage(
    source: source,
    imageQuality: 85,
  );

  if (picked == null) return;

  try {
    // الملف المؤقت
    final tempImage = File(picked.path);

    // تأكد إنه موجود
    if (!await tempImage.exists()) {
      throw Exception("Selected image does not exist");
    }

    // حفظ نسخة دائمة داخل التطبيق
    final dir = await getApplicationDocumentsDirectory();

    final savedImage = await tempImage.copy(
      '${dir.path}/${DateTime.now().millisecondsSinceEpoch}.jpg',
    );

    setState(() {
      _image = savedImage;
    });

    print("Saved image path: ${savedImage.path}");
  } catch (e) {
    print("Image pick error: $e");

    if (!mounted) return;

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('Failed to load image: $e'),
      ),
    );
  }
}

  // ── Upload to backend and return requestId to caller ───────────────────────
Future<void> _submit() async {
  if (_image == null) return;

  if (!await _image!.exists()) {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Image file is missing'),
      ),
    );
    return;
  }

  setState(() => _isUploading = true);

  try {
    final String requestId =
        await ref.read(prescriptionRepositoryProvider).submit(
      productId: widget.productId,
      productName: widget.medicineName,
      imagePath: _image!.path,
    );

    if (!mounted) return;

    Navigator.of(context).pop(requestId);
  } catch (e) {
    if (!mounted) return;

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('Upload failed: $e'),
        backgroundColor: Colors.red.shade400,
      ),
    );
  } finally {
    if (mounted) setState(() => _isUploading = false);
  }
}

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.surface,
      appBar: AppBar(
        title: const Text('Upload Prescription'),
        backgroundColor: Colors.white,
        foregroundColor: Colors.black,
        elevation: 0,
      ),
      body: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: <Widget>[
            // ── Info banner ────────────────────────────────────────────────
            Container(
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                color: Colors.blue.shade50,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: Colors.blue.shade200),
              ),
              child: Row(
                children: <Widget>[
                  Icon(Icons.medical_information_outlined,
                      color: Colors.blue.shade700, size: 28),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: <Widget>[
                        Text(
                          '"${widget.medicineName}"',
                          style: const TextStyle(
                              fontWeight: FontWeight.w700, fontSize: 13),
                        ),
                        const SizedBox(height: 2),
                        const Text(
                          'Upload a clear photo of your prescription. '
                          'A pharmacist will review and confirm it.',
                          style:
                              TextStyle(fontSize: 12, color: Colors.black54),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 24),
            const Text(
              'Prescription photo',
              style: TextStyle(fontSize: 15, fontWeight: FontWeight.w600),
            ),
            const SizedBox(height: 10),

            // ── Image preview / placeholder ────────────────────────────────
            Expanded(
              child: _image == null
                  ? _buildPlaceholder()
                  : ClipRRect(
                      borderRadius: BorderRadius.circular(16),
                      child: Image.file(
                        _image!,
                        fit: BoxFit.cover,
                        width: double.infinity,
                      ),
                    ),
            ),

            const SizedBox(height: 20),

            // ── Action buttons ─────────────────────────────────────────────
            if (_image == null) ...<Widget>[
              _sourceButton(
                icon: Icons.camera_alt_outlined,
                label: 'Take a Photo',
                onTap: () => _pick(ImageSource.camera),
              ),
              const SizedBox(height: 12),
              _sourceButton(
                icon: Icons.photo_library_outlined,
                label: 'Choose from Gallery',
                onTap: () => _pick(ImageSource.gallery),
              ),
            ] else ...<Widget>[
              Row(
                children: <Widget>[
                  // Retake
                  Expanded(
                    child: OutlinedButton.icon(
                      icon: const Icon(Icons.refresh),
                      label: const Text('Retake'),
                      onPressed:
                          _isUploading ? null : () => setState(() => _image = null),
                      style: OutlinedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(vertical: 14),
                        shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12)),
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  // Submit
                  Expanded(
                    child: ElevatedButton.icon(
                      icon: _isUploading
                          ? const SizedBox(
                              width: 16,
                              height: 16,
                              child: CircularProgressIndicator(
                                strokeWidth: 2,
                                color: Colors.white,
                              ),
                            )
                          : const Icon(Icons.send_outlined, color: Colors.white),
                      label: Text(
                        _isUploading ? 'Sending…' : 'Submit',
                        style: const TextStyle(color: Colors.white),
                      ),
                      onPressed: _isUploading ? null : _submit,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.brandBlue,
                        padding: const EdgeInsets.symmetric(vertical: 14),
                        shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12)),
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildPlaceholder() {
    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        color: Colors.grey.shade100,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.grey.shade300, width: 2),
      ),
      child: const Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: <Widget>[
          Icon(Icons.document_scanner_outlined, size: 64, color: Colors.grey),
          SizedBox(height: 12),
          Text(
            'No image selected',
            style: TextStyle(color: Colors.grey, fontSize: 15),
          ),
          SizedBox(height: 4),
          Text(
            'Use the buttons below to add one',
            style: TextStyle(color: Colors.grey, fontSize: 12),
          ),
        ],
      ),
    );
  }

  Widget _sourceButton({
    required IconData icon,
    required String label,
    required VoidCallback onTap,
  }) {
    return SizedBox(
      width: double.infinity,
      child: OutlinedButton.icon(
        icon: Icon(icon),
        label: Text(label),
        onPressed: onTap,
        style: OutlinedButton.styleFrom(
          padding: const EdgeInsets.symmetric(vertical: 14),
          shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12)),
        ),
      ),
    );
  }
}