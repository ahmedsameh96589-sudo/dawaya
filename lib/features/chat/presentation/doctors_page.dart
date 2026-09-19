import 'package:flutter/material.dart';

import '../models/doctor_profile.dart';
import '../widgets/doctor_rating_badge.dart';
import 'chat_page.dart';
import '../../../core/network/uploads.dart';
import '../data/chat_repository.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

class DoctorsPage extends ConsumerStatefulWidget {
  const DoctorsPage({super.key});

  @override
  ConsumerState<DoctorsPage> createState() => _DoctorsPageState();
}

class _DoctorsPageState extends ConsumerState<DoctorsPage> {
  List<DoctorProfile> _doctors = [];
  bool _loading = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    _loadDoctors();
  }

  Future<void> _loadDoctors() async {
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      final doctors = await ref.read(chatRepositoryProvider).fetchDoctors();
      setState(() {
        _doctors = doctors;
        _loading = false;
      });
    } catch (e) {
      setState(() {
        _error = e.toString();
        _loading = false;
      });
    }
  }

  Future<void> _startConsultation(DoctorProfile doctor) async {
    try {
      final consultation =
          await ref.read(chatRepositoryProvider).startConsultation(doctorId: doctor.id);
      if (!mounted) return;
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (_) => ChatPage(consultationId: consultation.id),
        ),
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(e.toString())),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Choose Doctor'),
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : _error != null
              ? Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Icon(Icons.wifi_off, size: 48, color: Colors.grey),
                      const SizedBox(height: 12),
                      const Text('تعذّر تحميل الدكاترة'),
                      const SizedBox(height: 8),
                      ElevatedButton(
                        onPressed: _loadDoctors,
                        child: const Text('إعادة المحاولة'),
                      ),
                    ],
                  ),
                )
              : ListView.separated(
                  padding: const EdgeInsets.all(16),
                  itemCount: _doctors.length,
                  separatorBuilder: (_, __) => const SizedBox(height: 12),
                  itemBuilder: (context, index) {
                    final doctor = _doctors[index];
                    final avatarUrl =
                        Uploads.resolve(doctor.avatarUrl);
                    return InkWell(
                      onTap: () => _startConsultation(doctor),
                      borderRadius: BorderRadius.circular(16),
                      child: Container(
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(16),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withOpacity(0.06),
                              blurRadius: 10,
                              offset: const Offset(0, 6),
                            ),
                          ],
                        ),
                        child: Row(
                          children: [
                            CircleAvatar(
                              radius: 28,
                              backgroundColor: Colors.grey.shade200,
                              backgroundImage: avatarUrl.isEmpty
                                  ? null
                                  : NetworkImage(avatarUrl),
                              child: avatarUrl.isEmpty
                                  ? const Icon(Icons.person_outline)
                                  : null,
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  DoctorNameWithRating(
                                    name: doctor.name,
                                    ratingAverage: doctor.ratingAverage,
                                    ratingCount: doctor.ratingCount,
                                    showWhenEmpty: true,
                                  ),
                                  const SizedBox(height: 4),
                                  Text(
                                    doctor.specialty,
                                    style: const TextStyle(
                                      color: Colors.black54,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 10,
                                vertical: 6,
                              ),
                              decoration: BoxDecoration(
                                color: doctor.isAvailable
                                    ? Colors.green.shade50
                                    : Colors.grey.shade200,
                                borderRadius: BorderRadius.circular(12),
                              ),
                              child: Text(
                                doctor.isAvailable ? 'Online' : 'Offline',
                                style: TextStyle(
                                  color: doctor.isAvailable
                                      ? Colors.green
                                      : Colors.black54,
                                  fontSize: 12,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    );
                  },
                ),
    );
  }
}
