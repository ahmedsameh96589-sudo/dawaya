import 'dart:async';

import 'package:flutter/material.dart';

import '../../../core/services/api_services.dart';
import '../../../core/services/auth_session.dart';
import '../models/consultation.dart';
import '../widgets/doctor_rating_badge.dart';
import 'chat_page.dart';
import 'doctors_page.dart';

class ConsultationsPage extends StatefulWidget {
  const ConsultationsPage({super.key});

  @override
  State<ConsultationsPage> createState() => _ConsultationsPageState();
}

class _ConsultationsPageState extends State<ConsultationsPage> {
  List<Consultation> _consultations = [];
  bool _loading = true;
  String? _error;
  Timer? _pollTimer;
  static const Duration _pollInterval = Duration(seconds: 5);

  @override
  void initState() {
    super.initState();
    _loadConsultations().then((_) => _startPolling());
  }

  void _startPolling() {
    _pollTimer?.cancel();
    _pollTimer = Timer.periodic(_pollInterval, (_) {
      if (mounted && !_loading) {
        _loadConsultations(silent: true);
      }
    });
  }

  Future<void> _loadConsultations({bool silent = false}) async {
    if (!silent) {
      setState(() {
        _loading = true;
        _error = null;
      });
    }
    try {
      final data = await ApiService.fetchMyConsultations();
      if (!mounted) return;
      setState(() {
        _consultations = data;
        _loading = false;
        _error = null;
      });
    } catch (e) {
      if (!mounted) return;
      if (!silent) {
        setState(() {
          _error = e.toString();
          _loading = false;
        });
      }
    }
  }

  @override
  void dispose() {
    _pollTimer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isDoctor = AuthSession.role == 'doctor';
    return Scaffold(
      appBar: AppBar(
        title: Text(isDoctor ? 'محادثات المرضى' : 'Consultations'),
        actions: [
          if (!isDoctor)
            IconButton(
              icon: const Icon(Icons.add_comment_outlined),
              onPressed: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (_) => const DoctorsPage()),
                );
              },
            ),
        ],
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
                      const Text('تعذّر تحميل المحادثات'),
                      const SizedBox(height: 8),
                      ElevatedButton(
                        onPressed: _loadConsultations,
                        child: const Text('إعادة المحاولة'),
                      ),
                    ],
                  ),
                )
              : _consultations.isEmpty
                  ? Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          const Icon(Icons.chat_bubble_outline,
                              size: 48, color: Colors.grey),
                          const SizedBox(height: 12),
                          Text(
                            isDoctor
                                ? 'لا توجد محادثات من المرضى بعد'
                                : 'لا توجد محادثات حالياً',
                          ),
                          if (!isDoctor) ...[
                            const SizedBox(height: 8),
                            ElevatedButton(
                              onPressed: () {
                                Navigator.push(
                                  context,
                                  MaterialPageRoute(
                                    builder: (_) => const DoctorsPage(),
                                  ),
                                );
                              },
                              child: const Text('ابدأ محادثة'),
                            ),
                          ],
                        ],
                      ),
                    )
                  : RefreshIndicator(
                      onRefresh: _loadConsultations,
                      child: ListView.separated(
                        padding: const EdgeInsets.all(16),
                        itemCount: _consultations.length,
                        separatorBuilder: (_, __) => const SizedBox(height: 12),
                        itemBuilder: (context, index) {
                          final item = _consultations[index];
                          final avatarUrl = ApiService.resolveUploadUrl(
                            item.displayAvatarUrl(
                              viewingAsDoctor: isDoctor,
                            ),
                          );
                          final title = item.displayName(
                            viewingAsDoctor: isDoctor,
                          );
                          return InkWell(
                            onTap: () async {
                              await Navigator.push<void>(
                                context,
                                MaterialPageRoute(
                                  builder: (_) =>
                                      ChatPage(consultationId: item.id),
                                ),
                              );
                              if (mounted) _loadConsultations(silent: true);
                            },
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
                                    radius: 26,
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
                                      crossAxisAlignment:
                                          CrossAxisAlignment.start,
                                      children: [
                                        isDoctor
                                            ? Text(
                                                title,
                                                style: const TextStyle(
                                                  fontWeight: FontWeight.w600,
                                                  fontSize: 16,
                                                ),
                                              )
                                            : DoctorNameWithRating(
                                                name: title,
                                                ratingAverage:
                                                    item.doctor.ratingAverage,
                                                ratingCount:
                                                    item.doctor.ratingCount,
                                              ),
                                        const SizedBox(height: 4),
                                        Text(
                                          item.lastMessageText.isEmpty
                                              ? item.topic
                                              : item.lastMessageText,
                                          maxLines: 1,
                                          overflow: TextOverflow.ellipsis,
                                          style: const TextStyle(
                                            color: Colors.black54,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                  const Icon(
                                    Icons.chevron_right,
                                    color: Colors.black38,
                                  ),
                                ],
                              ),
                            ),
                          );
                        },
                      ),
                    ),
    );
  }
}
