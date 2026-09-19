class DoctorProfile {
  const DoctorProfile({
    required this.id,
    required this.name,
    required this.specialty,
    required this.avatarUrl,
    required this.isAvailable,
    this.ratingAverage = 0,
    this.ratingCount = 0,
  });

  final String id;
  final String name;
  final String specialty;
  final String avatarUrl;
  final bool isAvailable;
  final double ratingAverage;
  final int ratingCount;

  bool get hasRatings => ratingCount > 0;

  factory DoctorProfile.fromJson(Map<String, dynamic> json) {
    final ratingJson = json['rating'];
    var average = 0.0;
    var count = 0;
    if (ratingJson is Map<String, dynamic>) {
      average = (ratingJson['average'] as num?)?.toDouble() ?? 0;
      count = (ratingJson['count'] as num?)?.toInt() ?? 0;
    }

    return DoctorProfile(
      id: json['_id'] as String,
      name: json['name'] as String? ?? 'Doctor',
      specialty: json['specialty'] as String? ?? '',
      avatarUrl: json['avatar'] as String? ?? '',
      isAvailable: json['isAvailable'] as bool? ?? false,
      ratingAverage: average,
      ratingCount: count,
    );
  }
}
