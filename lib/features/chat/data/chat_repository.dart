import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/network/api_client.dart';
import '../../../core/services/auth_session.dart';
import '../models/chat_message.dart';
import '../models/consultation.dart';
import '../models/doctor_profile.dart';

/// Doctors and patient–doctor consultations (chat).
class ChatRepository {
  ChatRepository(this._api);

  final ApiClient _api;

  bool get _isDoctor => AuthSession.role == 'doctor';
  String get _consultationsPath =>
      _isDoctor ? '/doctors/me/consultations' : '/consultations';

  Future<List<DoctorProfile>> fetchDoctors() async => dataList(
    await _api.get('/doctors'),
    'doctors',
  ).map(DoctorProfile.fromJson).toList();

  /// Starts a consultation, or returns the open one with this doctor.
  Future<Consultation> startConsultation({
    required String doctorId,
    String? topic,
  }) async {
    try {
      final body = await _api.post(
        '/consultations',
        body: {
          'doctorId': doctorId,
          if (topic != null && topic.isNotEmpty) 'topic': topic,
        },
      );
      return Consultation.fromJson(dataObject(body, 'consultation'));
    } on ApiException catch (e) {
      final existingId =
          (e.body['data'] as Json? ?? const {})['consultationId'] as String?;
      if (e.statusCode == 400 && existingId != null && existingId.isNotEmpty) {
        return fetchConsultation(existingId);
      }
      rethrow;
    }
  }

  Future<List<Consultation>> fetchMyConsultations() async => dataList(
    await _api.get(_consultationsPath),
    'consultations',
  ).map(Consultation.fromJson).toList();

  Future<Consultation> fetchConsultation(String id) async =>
      Consultation.fromJson(
        dataObject(await _api.get('$_consultationsPath/$id'), 'consultation'),
      );

  Future<Consultation> closeConsultation({
    required String consultationId,
    String? reason,
    int? rating,
    String? comment,
  }) async {
    final body = await _api.put(
      '/consultations/$consultationId/close',
      body: {
        if (reason != null && reason.isNotEmpty) 'reason': reason,
        if (rating != null) 'rating': rating,
        if (comment != null && comment.isNotEmpty) 'comment': comment,
      },
    );
    return Consultation.fromJson(dataObject(body, 'consultation'));
  }

  Future<Consultation> rateConsultation({
    required String consultationId,
    required int rating,
    String? comment,
  }) async {
    final body = await _api.put(
      '/consultations/$consultationId/rate',
      body: {
        'rating': rating,
        if (comment != null && comment.isNotEmpty) 'comment': comment,
      },
    );
    return Consultation.fromJson(dataObject(body, 'consultation'));
  }

  /// Sends a text message, optionally with an image attachment.
  Future<ChatMessage> sendMessage({
    required String consultationId,
    String? text,
    String? imagePath,
  }) async {
    final path = '/consultations/$consultationId/messages';
    final body = (imagePath != null && imagePath.isNotEmpty)
        ? await _api.upload(
            path,
            fileField: 'attachment',
            filePath: imagePath,
            fields: {if (text != null && text.isNotEmpty) 'text': text},
          )
        : await _api.post(path, body: {'text': text ?? ''});
    return ChatMessage.fromJson(dataObject(body, 'message'));
  }
}

final chatRepositoryProvider = Provider<ChatRepository>(
  (ref) => ChatRepository(ref.watch(apiClientProvider)),
);

final doctorsProvider = FutureProvider.autoDispose<List<DoctorProfile>>(
  (ref) => ref.watch(chatRepositoryProvider).fetchDoctors(),
);
