import 'dart:io';
import 'package:camera/camera.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_mlkit_text_recognition/google_mlkit_text_recognition.dart';
import 'package:image_picker/image_picker.dart';
import 'package:permission_handler/permission_handler.dart';
import '../../catalog/data/prescription_parser.dart';
import '../../cart/presentation/cart_provider.dart';
import '../../catalog/data/catalog_repository.dart';
import '../../catalog/data/medicine_matcher.dart';
import '../../catalog/models/product.dart';
import '../../catalog/presentation/product_details_page.dart';
import '../../catalog/presentation/scan_match_tile.dart';

class ScanPrescriptionScreen extends StatefulWidget {
  const ScanPrescriptionScreen({super.key});

  @override
  State<ScanPrescriptionScreen> createState() =>
      _ScanPrescriptionScreenState();
}

class _ScanPrescriptionScreenState extends State<ScanPrescriptionScreen>
    with SingleTickerProviderStateMixin {
  CameraController? _controller;
  List<CameraDescription>? cameras;
  bool isCameraInitialized = false;
  bool isProcessing = false;
  bool isCameraPermissionDenied = false;
  bool _isPickerActive = false; // guard against double-invocation
  File? pickedImage;

  late AnimationController _pulseController;
  late Animation<double> _pulseAnimation;

  final TextRecognizer _textRecognizer = TextRecognizer();
  final ImagePicker _imagePicker = ImagePicker();

  // ── Theme colours ──────────────────────────────────────────────
  static const Color _bg = Color(0xFF0D1117);
  static const Color _surface = Color(0xFF161B22);
  static const Color _accent = Color(0xFF00D4AA);
  static const Color _accentDim = Color(0x3300D4AA);
  static const Color _warn = Color(0xFFFFB347);
  static const Color _textPrimary = Color(0xFFE6EDF3);
  static const Color _textSecondary = Color(0xFF8B949E);

  @override
  void initState() {
    super.initState();
    _pulseController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 2),
    )..repeat(reverse: true);
    _pulseAnimation =
        Tween<double>(begin: 0.6, end: 1.0).animate(_pulseController);
    _initEverything();
  }

  Future<void> _initEverything() async {
    await _requestCameraPermission();
    await _initCamera();
  }

  Future<void> _requestCameraPermission() async {
    final status = await Permission.camera.request();
    if (!status.isGranted) {
      setState(() => isCameraPermissionDenied = true);
    }
  }

  Future<void> _initCamera() async {
    try {
      cameras = await availableCameras();
      if (cameras == null || cameras!.isEmpty) return;
      _controller =
          CameraController(cameras!.first, ResolutionPreset.high, enableAudio: false);
      await _controller!.initialize();
      if (mounted) setState(() => isCameraInitialized = true);
    } catch (e) {
      debugPrint('Camera init error: $e');
    }
  }

  // ── Capture from camera ─────────────────────────────────────────
  Future<void> _captureImage() async {
    if (_controller == null || !_controller!.value.isInitialized) return;
    setState(() => isProcessing = true);
    try {
      final image = await _controller!.takePicture();
      await _processImageFile(image.path);
    } catch (e) {
      _showError('Capture failed: $e');
    } finally {
      if (mounted) setState(() => isProcessing = false);
    }
  }

  // ── Pick from gallery ───────────────────────────────────────────
  Future<void> _pickFromGallery() async {
    if (_isPickerActive) return; // prevent already_active exception
    _isPickerActive = true;
    try {
      final picked = await _imagePicker.pickImage(
        source: ImageSource.gallery,
        imageQuality: 95,
      );
      if (picked == null) return;
      setState(() {
        pickedImage = File(picked.path);
        isProcessing = true;
      });
      await _processImageFile(picked.path);
      if (mounted) setState(() => isProcessing = false);
    } finally {
      _isPickerActive = false;
    }
  }

  Future<void> _processImageFile(String path) async {
    try {
      final inputImage = InputImage.fromFilePath(path);
      final recognized = await _textRecognizer.processImage(inputImage);
      final meds = PrescriptionParser.extract(recognized.text);
      if (mounted) _showResult(meds, recognized.text);
    } catch (e) {
      _showError('OCR failed: $e');
    }
  }

  // ── Result bottom-sheet ─────────────────────────────────────────
  void _showResult(List<MedicineResult> meds, String rawText) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => _ResultSheet(
        medicines: meds,
        rawText: rawText,
        accent: _accent,
        surface: _surface,
        bg: _bg,
        textPrimary: _textPrimary,
        textSecondary: _textSecondary,
        warn: _warn,
      ),
    );
  }

  void _showError(String msg) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(msg),
        backgroundColor: Colors.redAccent,
      ),
    );
  }

  @override
  void dispose() {
    _controller?.dispose();
    _textRecognizer.close();
    _pulseController.dispose();
    super.dispose();
  }

  // ── Build ───────────────────────────────────────────────────────
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: _bg,
      appBar: _buildAppBar(),
      body: _buildBody(),
    );
  }

  AppBar _buildAppBar() {
    return AppBar(
      backgroundColor: _surface,
      elevation: 0,
      centerTitle: true,
      leading: IconButton(
        icon: const Icon(Icons.arrow_back_ios_new, color: _textSecondary, size: 18),
        onPressed: () => Navigator.pop(context),
      ),
      title: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            padding: const EdgeInsets.all(6),
            decoration: BoxDecoration(
              color: _accentDim,
              borderRadius: BorderRadius.circular(8),
            ),
            child: const Icon(Icons.document_scanner, color: _accent, size: 18),
          ),
          const SizedBox(width: 10),
          const Text(
            'Prescription Scanner',
            style: TextStyle(
              color: _textPrimary,
              fontSize: 17,
              fontWeight: FontWeight.w600,
              letterSpacing: 0.3,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildBody() {
    if (isCameraPermissionDenied) return _buildPermissionDenied();
    if (!isCameraInitialized) return _buildLoading();

    return Stack(
      children: [
        // Camera preview
        Positioned.fill(child: CameraPreview(_controller!)),

        // Dark vignette overlay
        Positioned.fill(
          child: DecoratedBox(
            decoration: BoxDecoration(
              gradient: RadialGradient(
                center: Alignment.center,
                radius: 1.2,
                colors: [
                  Colors.transparent,
                  Colors.black.withOpacity(0.55),
                ],
              ),
            ),
          ),
        ),

        // Scanning frame
        Center(child: _buildScanFrame()),

        // Bottom controls
        Positioned(
          bottom: 0,
          left: 0,
          right: 0,
          child: _buildControls(),
        ),

        // Processing overlay
        if (isProcessing) _buildProcessingOverlay(),
      ],
    );
  }

  Widget _buildScanFrame() {
    return AnimatedBuilder(
      animation: _pulseAnimation,
      builder: (_, __) {
        return Container(
          width: 280,
          height: 200,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(16),
            border: Border.all(
              color: _accent.withOpacity(_pulseAnimation.value),
              width: 2,
            ),
            boxShadow: [
              BoxShadow(
                color: _accent.withOpacity(_pulseAnimation.value * 0.3),
                blurRadius: 20,
                spreadRadius: 2,
              ),
            ],
          ),
          child: Stack(
            children: [
              // Corner accents
              ..._buildCorners(),
              // Scan label
              Positioned(
                bottom: 12,
                left: 0,
                right: 0,
                child: Center(
                  child: Container(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                    decoration: BoxDecoration(
                      color: _accentDim,
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: const Text(
                      'Align prescription here',
                      style: TextStyle(
                          color: _accent, fontSize: 11, letterSpacing: 0.5),
                    ),
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  List<Widget> _buildCorners() {
    const thickness = 3.0;
    return [
      _corner(top: 0, left: 0, borderT: thickness, borderL: thickness),
      _corner(top: 0, right: 0, borderT: thickness, borderR: thickness),
      _corner(bottom: 0, left: 0, borderB: thickness, borderL: thickness),
      _corner(bottom: 0, right: 0, borderB: thickness, borderR: thickness),
    ].map((w) => w).toList();
  }

  Widget _corner({
    double? top,
    double? bottom,
    double? left,
    double? right,
    double borderT = 0,
    double borderB = 0,
    double borderL = 0,
    double borderR = 0,
  }) {
    return Positioned(
      top: top,
      bottom: bottom,
      left: left,
      right: right,
      child: Container(
        width: 20,
        height: 20,
        decoration: BoxDecoration(
          border: Border(
            top: BorderSide(color: _accent, width: borderT),
            bottom: BorderSide(color: _accent, width: borderB),
            left: BorderSide(color: _accent, width: borderL),
            right: BorderSide(color: _accent, width: borderR),
          ),
        ),
      ),
    );
  }

  Widget _buildControls() {
    return Container(
      padding: const EdgeInsets.fromLTRB(24, 20, 24, 36),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [Colors.transparent, _bg.withOpacity(0.97)],
        ),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
        children: [
          // Gallery button
          _ControlButton(
            icon: Icons.photo_library_outlined,
            label: 'Gallery',
            onTap: _pickFromGallery,
            color: _warn,
          ),
          // Capture button
          GestureDetector(
            onTap: _captureImage,
            child: Container(
              width: 72,
              height: 72,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: _accent,
                boxShadow: [
                  BoxShadow(
                    color: _accent.withOpacity(0.45),
                    blurRadius: 20,
                    spreadRadius: 2,
                  ),
                ],
              ),
              child: const Icon(Icons.camera_alt, color: _bg, size: 30),
            ),
          ),
          // Flip camera (if multiple cameras)
          _ControlButton(
            icon: Icons.flip_camera_ios_outlined,
            label: 'Flip',
            onTap: _flipCamera,
            color: _textSecondary,
          ),
        ],
      ),
    );
  }

  Future<void> _flipCamera() async {
    if (cameras == null || cameras!.length < 2) return;
    final currentIdx = cameras!.indexOf(_controller!.description);
    final nextIdx = (currentIdx + 1) % cameras!.length;
    await _controller?.dispose();
    _controller =
        CameraController(cameras![nextIdx], ResolutionPreset.high, enableAudio: false);
    await _controller!.initialize();
    if (mounted) setState(() {});
  }

  Widget _buildProcessingOverlay() {
    return Positioned.fill(
      child: Container(
        color: Colors.black54,
        child: Center(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const SizedBox(
                width: 48,
                height: 48,
                child: CircularProgressIndicator(
                  color: _accent,
                  strokeWidth: 3,
                ),
              ),
              const SizedBox(height: 16),
              const Text('Scanning for medicines…',
                  style: TextStyle(color: _accent, fontSize: 14)),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildLoading() {
    return const Scaffold(
      backgroundColor: _bg,
      body: Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            CircularProgressIndicator(color: _accent),
            SizedBox(height: 16),
            Text('Initialising camera…',
                style: TextStyle(color: _textSecondary)),
          ],
        ),
      ),
    );
  }

  Widget _buildPermissionDenied() {
    return Scaffold(
      backgroundColor: _bg,
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(32),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(Icons.no_photography_outlined,
                  color: _warn, size: 64),
              const SizedBox(height: 16),
              const Text(
                'Camera permission required',
                style: TextStyle(
                    color: _textPrimary,
                    fontSize: 18,
                    fontWeight: FontWeight.w600),
              ),
              const SizedBox(height: 8),
              const Text(
                'Please allow camera access in Settings to use the scanner. You can still upload photos from your gallery.',
                textAlign: TextAlign.center,
                style: TextStyle(color: _textSecondary, height: 1.5),
              ),
              const SizedBox(height: 24),
              ElevatedButton.icon(
                onPressed: openAppSettings,
                icon: const Icon(Icons.settings),
                label: const Text('Open Settings'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: _accent,
                  foregroundColor: _bg,
                ),
              ),
              const SizedBox(height: 12),
              TextButton.icon(
                onPressed: _pickFromGallery,
                icon: const Icon(Icons.photo_library_outlined, color: _warn),
                label: const Text('Upload from Gallery',
                    style: TextStyle(color: _warn)),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// ── Supporting widgets ────────────────────────────────────────────

class _ControlButton extends StatelessWidget {
  final IconData icon;
  final String label;
  final VoidCallback onTap;
  final Color color;

  const _ControlButton({
    required this.icon,
    required this.label,
    required this.onTap,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 52,
            height: 52,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: color.withOpacity(0.12),
              border: Border.all(color: color.withOpacity(0.35)),
            ),
            child: Icon(icon, color: color, size: 22),
          ),
          const SizedBox(height: 6),
          Text(label,
              style: TextStyle(color: color, fontSize: 11)),
        ],
      ),
    );
  }
}

// ── Result bottom-sheet ───────────────────────────────────────────

class _ResultSheet extends ConsumerStatefulWidget {
  final List<MedicineResult> medicines;
  final String rawText;
  final Color accent, surface, bg, textPrimary, textSecondary, warn;

  const _ResultSheet({
    required this.medicines,
    required this.rawText,
    required this.accent,
    required this.surface,
    required this.bg,
    required this.textPrimary,
    required this.textSecondary,
    required this.warn,
  });

  @override
  ConsumerState<_ResultSheet> createState() => _ResultSheetState();
}

class _ResultSheetState extends ConsumerState<_ResultSheet> {
  bool showRaw = false;

  /// Product ids added to the cart from this sheet, and ids with a request
  /// in flight.
  final Set<String> _added = {};
  final Set<String> _busy = {};

  /// Substitutes the user asked for, by scanned-medicine index.
  final Map<int, Product> _substitutes = {};

  Product? _productFor(int index, List<MedicineMatch?> matches) =>
      _substitutes[index] ?? matches[index]?.product;

  Future<bool> _add(Product product) async {
    setState(() => _busy.add(product.id));
    try {
      await CartProvider.of(context).add(product);
      if (mounted) setState(() => _added.add(product.id));
      return true;
    } catch (e) {
      _toast(e.toString().replaceFirst('Exception: ', ''));
      return false;
    } finally {
      if (mounted) setState(() => _busy.remove(product.id));
    }
  }

  Future<void> _addAll(List<Product> products) async {
    for (final product in products) {
      // Stop at the first failure (e.g. signed out) instead of repeating it.
      if (!await _add(product)) return;
    }
    _toast('Added ${products.length} to your cart.');
  }

  void _open(Product product) {
    Navigator.of(context).push(
      MaterialPageRoute<void>(builder: (_) => ProductDetailsPage(product: product)),
    );
  }

  Future<void> _findSubstitute(int index, Product product) async {
    setState(() => _busy.add(product.id));
    try {
      final alternatives =
          await ref.read(catalogRepositoryProvider).fetchAlternatives(product.id);
      final inStock = alternatives
          .where((p) => p.id != product.id && !p.isOutOfStock)
          .toList();
      if (inStock.isEmpty) {
        _toast('No substitute is in stock right now.');
      } else if (mounted) {
        setState(() => _substitutes[index] = inStock.first);
      }
    } catch (e) {
      _toast(e.toString());
    } finally {
      if (mounted) setState(() => _busy.remove(product.id));
    }
  }

  ButtonStyle get _primaryButtonStyle => ElevatedButton.styleFrom(
        backgroundColor: widget.accent,
        foregroundColor: widget.bg,
        padding: const EdgeInsets.symmetric(vertical: 14),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      );

  void _toast(String message) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(message)));
  }

  @override
  Widget build(BuildContext context) {
    final catalog = ref.watch(medicinesProvider);
    final products = catalog.value ?? const <Product>[];
    final matches = [
      for (final med in widget.medicines)
        catalog.hasValue ? MedicineMatcher.match(med, products) : null,
    ];
    final addable = <Product>[
      for (var i = 0; i < widget.medicines.length; i++)
        if (_productFor(i, matches) case final product?)
          if (actionFor(product) == ScanMatchAction.add && !_added.contains(product.id))
            product,
    ];

    return DraggableScrollableSheet(
      initialChildSize: 0.55,
      minChildSize: 0.35,
      maxChildSize: 0.92,
      builder: (_, controller) {
        return Container(
          decoration: BoxDecoration(
            color: widget.surface,
            borderRadius:
                const BorderRadius.vertical(top: Radius.circular(24)),
          ),
          child: Column(
            children: [
              // Handle
              Padding(
                padding: const EdgeInsets.only(top: 12, bottom: 4),
                child: Container(
                  width: 40,
                  height: 4,
                  decoration: BoxDecoration(
                    color: widget.textSecondary.withOpacity(0.35),
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
              ),
              // Header
              Padding(
                padding:
                    const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                child: Row(
                  children: [
                    Icon(Icons.medication_rounded, color: widget.accent),
                    const SizedBox(width: 10),
                    Text(
                      'Detected Medicines',
                      style: TextStyle(
                        color: widget.textPrimary,
                        fontSize: 18,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    const Spacer(),
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 10, vertical: 4),
                      decoration: BoxDecoration(
                        color: widget.accent.withOpacity(0.15),
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: Text(
                        '${widget.medicines.length} found',
                        style: TextStyle(
                            color: widget.accent,
                            fontSize: 12,
                            fontWeight: FontWeight.w600),
                      ),
                    ),
                  ],
                ),
              ),
              const Divider(height: 1, color: Color(0xFF21262D)),
              // Body
              Expanded(
                child: widget.medicines.isEmpty
                    ? _buildEmpty()
                    : ListView(
                        controller: controller,
                        padding: const EdgeInsets.all(16),
                        children: [
                          for (var i = 0; i < widget.medicines.length; i++)
                            _MedCard(
                              med: widget.medicines[i],
                              accent: widget.accent,
                              textPrimary: widget.textPrimary,
                              textSecondary: widget.textSecondary,
                              footer: ScanMatchTile(
                                match: matches[i],
                                isLoadingCatalog: catalog.isLoading && !catalog.hasValue,
                                isAdded: _added.contains(_productFor(i, matches)?.id),
                                isBusy: _busy.contains(_productFor(i, matches)?.id),
                                substitute: _substitutes[i],
                                accent: widget.accent,
                                textPrimary: widget.textPrimary,
                                textSecondary: widget.textSecondary,
                                onAdd: _add,
                                onOpen: _open,
                                onFindSubstitute: (p) => _findSubstitute(i, p),
                              ),
                            ),
                          const SizedBox(height: 12),
                          // Raw text toggle
                          GestureDetector(
                            onTap: () =>
                                setState(() => showRaw = !showRaw),
                            child: Row(
                              children: [
                                Icon(
                                    showRaw
                                        ? Icons.expand_less
                                        : Icons.expand_more,
                                    color: widget.textSecondary,
                                    size: 18),
                                const SizedBox(width: 6),
                                Text(
                                  showRaw
                                      ? 'Hide raw text'
                                      : 'Show raw OCR text',
                                  style: TextStyle(
                                      color: widget.textSecondary,
                                      fontSize: 13),
                                ),
                              ],
                            ),
                          ),
                          if (showRaw) ...[
                            const SizedBox(height: 8),
                            Container(
                              padding: const EdgeInsets.all(12),
                              decoration: BoxDecoration(
                                color: widget.bg,
                                borderRadius: BorderRadius.circular(10),
                                border: Border.all(
                                    color: widget.textSecondary
                                        .withOpacity(0.15)),
                              ),
                              child: SelectableText(
                                widget.rawText.trim().isEmpty
                                    ? '(No text detected)'
                                    : widget.rawText,
                                style: TextStyle(
                                    color: widget.textSecondary,
                                    fontSize: 12,
                                    height: 1.6,
                                    fontFamily: 'monospace'),
                              ),
                            ),
                          ],
                        ],
                      ),
              ),
              // Add matched medicines to the cart, or close
              SafeArea(
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(20, 8, 20, 12),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      if (addable.isNotEmpty) ...[
                        SizedBox(
                          width: double.infinity,
                          child: ElevatedButton.icon(
                            onPressed:
                                _busy.isEmpty ? () => _addAll(addable) : null,
                            icon: const Icon(Icons.add_shopping_cart),
                            label: Text(
                              'Add ${addable.length} to cart',
                              style: const TextStyle(
                                  fontWeight: FontWeight.w700, fontSize: 15),
                            ),
                            style: _primaryButtonStyle,
                          ),
                        ),
                        const SizedBox(height: 6),
                        SizedBox(
                          width: double.infinity,
                          child: TextButton(
                            onPressed: () => Navigator.pop(context),
                            style: TextButton.styleFrom(
                                foregroundColor: widget.textSecondary),
                            child: const Text('Done'),
                          ),
                        ),
                      ] else
                        SizedBox(
                          width: double.infinity,
                          child: ElevatedButton(
                            onPressed: () => Navigator.pop(context),
                            style: _primaryButtonStyle,
                            child: const Text('Done',
                                style: TextStyle(
                                    fontWeight: FontWeight.w700, fontSize: 15)),
                          ),
                        ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildEmpty() {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(Icons.search_off_rounded,
              size: 56, color: widget.textSecondary.withOpacity(0.4)),
          const SizedBox(height: 12),
          Text('No medicines detected',
              style: TextStyle(
                  color: widget.textPrimary,
                  fontSize: 16,
                  fontWeight: FontWeight.w600)),
          const SizedBox(height: 6),
          Text('Try capturing the prescription more clearly.',
              style: TextStyle(color: widget.textSecondary, fontSize: 13)),
        ],
      ),
    );
  }
}

class _MedCard extends StatelessWidget {
  final MedicineResult med;
  final Color accent, textPrimary, textSecondary;
  final Widget? footer;

  const _MedCard({
    required this.med,
    required this.accent,
    required this.textPrimary,
    required this.textSecondary,
    this.footer,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: const Color(0xFF0D1117),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: accent.withOpacity(0.2)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.medication_outlined, color: accent, size: 18),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  med.name,
                  style: TextStyle(
                    color: textPrimary,
                    fontWeight: FontWeight.w600,
                    fontSize: 15,
                  ),
                ),
              ),
            ],
          ),
          if (med.dose != null || med.form != null || med.frequency != null) ...[
            const SizedBox(height: 8),
            Wrap(
              spacing: 8,
              runSpacing: 6,
              children: [
                if (med.dose != null)
                  _Chip(label: med.dose!, icon: Icons.scale, color: accent),
                if (med.form != null)
                  _Chip(label: med.form!, icon: Icons.medical_services_outlined, color: const Color(0xFFFFB347)),
                if (med.frequency != null)
                  _Chip(label: med.frequency!, icon: Icons.schedule, color: const Color(0xFF79C0FF)),
              ],
            ),
          ],
          if (footer != null) footer!,
        ],
      ),
    );
  }
}

class _Chip extends StatelessWidget {
  final String label;
  final IconData icon;
  final Color color;

  const _Chip({required this.label, required this.icon, required this.color});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: color.withOpacity(0.3)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 12, color: color),
          const SizedBox(width: 4),
          Text(label,
              style: TextStyle(
                  color: color, fontSize: 11, fontWeight: FontWeight.w500)),
        ],
      ),
    );
  }
}

// ── Data model ────────────────────────────────────────────────────
