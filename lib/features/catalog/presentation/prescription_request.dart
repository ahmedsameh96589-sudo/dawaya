// lib/features/prescriptions/models/prescription_request.dart

enum PrescriptionStatus { pending, approved, rejected }

class PrescriptionRequest {
  const PrescriptionRequest({
    required this.id,
    required this.userId,
    required this.productId,
    required this.productName,
    required this.imageUrl,
    required this.status,
    required this.createdAt,
    this.reviewedAt,
    this.adminNote,
  });

  final String id;
  final String userId;
  final String productId;
  final String productName;
  final String imageUrl;
  final PrescriptionStatus status;
  final DateTime createdAt;
  final DateTime? reviewedAt;
  final String? adminNote;

  factory PrescriptionRequest.fromJson(Map<String, dynamic> json) {
    return PrescriptionRequest(
      id:          json['id'] as String,
      userId:      json['userId'] as String,
      productId:   json['productId'] as String,
      productName: json['productName'] as String,
      imageUrl:    json['imageUrl'] as String,
      status: PrescriptionStatus.values.firstWhere(
        (e) => e.name == (json['status'] as String),
        orElse: () => PrescriptionStatus.pending,
      ),
      createdAt:  DateTime.parse(json['createdAt'] as String),
      reviewedAt: json['reviewedAt'] != null
          ? DateTime.parse(json['reviewedAt'] as String)
          : null,
      adminNote: json['adminNote'] as String?,
    );
  }
}