import 'doctor_profile.dart';
import 'chat_message.dart';

/// Patient info when a doctor views their consultations list.
class ChatPeer {
  const ChatPeer({
    required this.id,
    required this.name,
    required this.avatarUrl,
  });

  final String id;
  final String name;
  final String avatarUrl;

  factory ChatPeer.fromJson(Map<String, dynamic> json) {
    return ChatPeer(
      id: json['_id'] as String? ?? '',
      name: json['name'] as String? ?? 'Patient',
      avatarUrl: json['avatar'] as String? ?? '',
    );
  }
}

class ConsultationRating {
  const ConsultationRating({
    required this.rating,
    required this.comment,
    this.ratedAt,
  });

  final int rating;
  final String comment;
  final DateTime? ratedAt;

  factory ConsultationRating.fromJson(Map<String, dynamic> json) {
    return ConsultationRating(
      rating: (json['rating'] as num?)?.toInt() ?? 0,
      comment: json['comment'] as String? ?? '',
      ratedAt: json['ratedAt'] == null
          ? null
          : DateTime.tryParse(json['ratedAt'] as String),
    );
  }
}

class Consultation {
  const Consultation({
    required this.id,
    required this.status,
    required this.topic,
    required this.lastMessageText,
    required this.lastMessageAt,
    required this.doctor,
    this.patient,
    required this.messages,
    this.userRating,
  });

  final String id;
  final String status;
  final String topic;
  final String lastMessageText;
  final DateTime? lastMessageAt;
  final DoctorProfile doctor;
  final ChatPeer? patient;
  final List<ChatMessage> messages;
  final ConsultationRating? userRating;

  bool get isClosed => status == 'closed' || status == 'cancelled';
  bool get hasUserRating => (userRating?.rating ?? 0) > 0;

  /// Title shown in list / app bar depending on who is logged in.
  String displayName({required bool viewingAsDoctor}) {
    if (viewingAsDoctor) {
      return patient?.name ?? 'Patient';
    }
    return doctor.name;
  }

  String displayAvatarUrl({required bool viewingAsDoctor}) {
    if (viewingAsDoctor) {
      return patient?.avatarUrl ?? '';
    }
    return doctor.avatarUrl;
  }

  factory Consultation.fromJson(Map<String, dynamic> json) {
    final messagesJson = json['messages'] as List<dynamic>? ?? [];
    return Consultation(
      id: json['_id'] as String,
      status: json['status'] as String? ?? 'pending',
      topic: json['topic'] as String? ?? '',
      lastMessageText: json['lastMessageText'] as String? ?? '',
      lastMessageAt: json['lastMessageAt'] == null
          ? null
          : DateTime.tryParse(json['lastMessageAt'] as String),
      doctor: _parseDoctor(json),
      patient: _parsePatient(json),
      messages: messagesJson
          .map((e) => ChatMessage.fromJson(e as Map<String, dynamic>))
          .toList(),
      userRating: _parseUserRating(json),
    );
  }

  static ConsultationRating? _parseUserRating(Map<String, dynamic> json) {
    final ratingJson = json['userRating'];
    if (ratingJson is Map<String, dynamic> &&
        (ratingJson['rating'] as num? ?? 0) > 0) {
      return ConsultationRating.fromJson(ratingJson);
    }
    return null;
  }

  static DoctorProfile _parseDoctor(Map<String, dynamic> json) {
    final doctorJson = json['doctor'];
    if (doctorJson is Map<String, dynamic>) {
      return DoctorProfile.fromJson(doctorJson);
    }
    return const DoctorProfile(
      id: '',
      name: 'Doctor',
      specialty: '',
      avatarUrl: '',
      isAvailable: false,
      ratingAverage: 0,
      ratingCount: 0,
    );
  }

  static ChatPeer? _parsePatient(Map<String, dynamic> json) {
    final userJson = json['user'];
    if (userJson is Map<String, dynamic>) {
      return ChatPeer.fromJson(userJson);
    }
    return null;
  }
}
