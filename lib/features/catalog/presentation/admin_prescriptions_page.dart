import 'package:flutter/material.dart';
import '../../../core/services/api_services.dart';
import '../../../core/theme/app_colors.dart';
import 'prescription_service.dart';
import 'prescription_request.dart';

class AdminPrescriptionsPage extends StatefulWidget {
  const AdminPrescriptionsPage({super.key});

  @override
  State<AdminPrescriptionsPage> createState() => _AdminPrescriptionsPageState();
}

class _AdminPrescriptionsPageState extends State<AdminPrescriptionsPage> {
  List<PrescriptionRequest> _requests = [];
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() => _loading = true);
    try {
      final list = await PrescriptionService.instance.fetchPending();
      setState(() => _requests = list);
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context)
          .showSnackBar(SnackBar(content: Text('Error: $e')));
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.surface,
      appBar: AppBar(
        title: const Text('Prescription Requests'),
        backgroundColor: Colors.white,
        foregroundColor: Colors.black,
        elevation: 0,
        actions: [
          IconButton(icon: const Icon(Icons.refresh), onPressed: _load),
        ],
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : _requests.isEmpty
              ? const Center(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(Icons.inbox_outlined, size: 64, color: Colors.grey),
                      SizedBox(height: 12),
                      Text('No pending prescriptions',
                          style: TextStyle(color: Colors.grey)),
                    ],
                  ),
                )
              : RefreshIndicator(
                  onRefresh: _load,
                  child: ListView.separated(
                    padding: const EdgeInsets.all(16),
                    itemCount: _requests.length,
                    separatorBuilder: (_, __) => const SizedBox(height: 12),
                    itemBuilder: (context, i) => _PrescriptionCard(
                      request: _requests[i],
                      onReviewed: _load,
                    ),
                  ),
                ),
    );
  }
}

class _PrescriptionCard extends StatefulWidget {
  const _PrescriptionCard({required this.request, required this.onReviewed});
  final PrescriptionRequest request;
  final VoidCallback onReviewed;

  @override
  State<_PrescriptionCard> createState() => _PrescriptionCardState();
}

class _PrescriptionCardState extends State<_PrescriptionCard> {
  final _noteController = TextEditingController();
  bool _loading = false;

  Future<void> _review(bool approve) async {
    setState(() => _loading = true);
    try {
      final note = _noteController.text.trim();
      if (approve) {
        await PrescriptionService.instance
            .approve(widget.request.id, note: note.isEmpty ? null : note);
      } else {
        await PrescriptionService.instance
            .reject(widget.request.id, note: note.isEmpty ? null : note);
      }
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
          content: Text(approve
              ? '✅ Prescription approved'
              : '❌ Prescription rejected')));
      widget.onReviewed();
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context)
          .showSnackBar(SnackBar(content: Text('Error: $e')));
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  @override
  void dispose() {
    _noteController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final req = widget.request;
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: const [
          BoxShadow(
              color: AppColors.cardShadow,
              blurRadius: 10,
              offset: Offset(0, 4)),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Prescription image
          ClipRRect(
            borderRadius:
                const BorderRadius.vertical(top: Radius.circular(16)),
            child: Image.network(
              ApiService.resolveUploadUrl(req.imageUrl),
              headers: ApiService.uploadHeaders,
              height: 200,
              width: double.infinity,
              fit: BoxFit.cover,
              errorBuilder: (_, __, ___) => Container(
                height: 200,
                color: Colors.grey.shade100,
                child: const Icon(Icons.broken_image_outlined,
                    size: 48, color: Colors.grey),
              ),
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(14),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Product name + status badge
                Row(
                  children: [
                    Expanded(
                      child: Text(req.productName,
                          style: const TextStyle(
                              fontSize: 15, fontWeight: FontWeight.w700)),
                    ),
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 8, vertical: 4),
                      decoration: BoxDecoration(
                        color: Colors.orange.shade100,
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Text(
                        req.status.name.toUpperCase(),
                        style: TextStyle(
                            fontSize: 10,
                            fontWeight: FontWeight.w700,
                            color: Colors.orange.shade700),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 4),
                Text('User ID: ${req.userId}',
                    style: const TextStyle(
                        fontSize: 12, color: Colors.black45)),
                Text(
                    'Submitted: ${req.createdAt.day}/${req.createdAt.month}/${req.createdAt.year}',
                    style: const TextStyle(
                        fontSize: 12, color: Colors.black45)),
                const SizedBox(height: 12),

                // Optional admin note
                TextField(
                  controller: _noteController,
                  decoration: InputDecoration(
                    hintText: 'Add a note for the patient (optional)…',
                    contentPadding: const EdgeInsets.symmetric(
                        horizontal: 12, vertical: 10),
                    border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(10)),
                    isDense: true,
                  ),
                  style: const TextStyle(fontSize: 13),
                ),
                const SizedBox(height: 12),

                // Approve / Reject buttons
                if (_loading)
                  const Center(child: CircularProgressIndicator())
                else
                  Row(
                    children: [
                      Expanded(
                        child: OutlinedButton.icon(
                          icon: const Icon(Icons.close, color: Colors.red),
                          label: const Text('Reject',
                              style: TextStyle(color: Colors.red)),
                          onPressed: () => _review(false),
                          style: OutlinedButton.styleFrom(
                            side: const BorderSide(color: Colors.red),
                            shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(10)),
                            padding:
                                const EdgeInsets.symmetric(vertical: 12),
                          ),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: ElevatedButton.icon(
                          icon: const Icon(Icons.check, color: Colors.white),
                          label: const Text('Approve',
                              style: TextStyle(color: Colors.white)),
                          onPressed: () => _review(true),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.green,
                            shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(10)),
                            padding:
                                const EdgeInsets.symmetric(vertical: 12),
                          ),
                        ),
                      ),
                    ],
                  ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}