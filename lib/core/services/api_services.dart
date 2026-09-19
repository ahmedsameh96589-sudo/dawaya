import 'dart:convert';
import 'package:http/http.dart' as http;

import '../config/app_config.dart';
import '../../features/catalog/models/category.dart';
import '../../features/catalog/models/product.dart';
import '../../features/news/models/news_item.dart';
import '../../features/chat/models/doctor_profile.dart';
import '../../features/chat/models/consultation.dart';
import '../../features/chat/models/chat_message.dart';
import '../../features/cart/models/order_request.dart';
import '../../features/cart/models/cart_model.dart';
import '../../features/orders/models/order_summary.dart';
import '../../features/profile/models/user_profile.dart';
import '../../features/notifications/models/app_notification.dart';
import 'auth_session.dart';

class LoginResult {
  const LoginResult({
    required this.userId,
    required this.needsVerification,
    required this.message,
    this.skipOtp = false,
    this.token,
    this.role,
    this.name,
  });

  final String userId;
  final bool needsVerification;
  final String message;

  /// Doctor accounts log in directly (no OTP on User collection).
  final bool skipOtp;
  final String? token;
  final String? role;
  final String? name;
}

class VerifyOtpResult {
  const VerifyOtpResult({
    this.token,
    this.resetToken,
    this.role,
    this.name,
    required this.message,
  });

  final String? token;
  final String? resetToken;
  final String? role;
  final String? name;
  final String message;
}

class ForgotPasswordResult {
  const ForgotPasswordResult({this.userId, required this.message});

  final String? userId;
  final String message;
}

class GoogleAuthResult {
  const GoogleAuthResult({
    required this.token,
    required this.userId,
    required this.message,
    this.role,
    this.name,
    this.isNewUser = false,
  });

  final String token;
  final String userId;
  final String message;
  final String? role;
  final String? name;
  final bool isNewUser;
}

class ApiService {
  static String get baseUrl => AppConfig.apiBaseUrl;
  static String get baseHostUrl => AppConfig.apiHost;
  static const String newsApiKey = 'c95bdaa2833743c0bba5cb3c029f6bf3';
  static const String newsBaseUrl = 'https://newsapi.org/v2';

  static String _extractMessage(http.Response response) {
    try {
      final Map<String, dynamic> body =
          jsonDecode(response.body) as Map<String, dynamic>;
      return body['message'] as String? ?? 'Request failed';
    } catch (_) {
      return 'Request failed';
    }
  }

  static Map<String, dynamic> _decode(http.Response response) {
    return jsonDecode(response.body) as Map<String, dynamic>;
  }

  static Map<String, String> _authHeaders({bool json = true}) {
    final headers = <String, String>{};
    if (json) headers['Content-Type'] = 'application/json';
    final token = AuthSession.token;
    if (token != null && token.isNotEmpty) {
      headers['Authorization'] = 'Bearer $token';
    }
    return headers;
  }

  static String resolveUploadUrl(String path) {
    if (path.isEmpty) return '';
    if (path.startsWith('http')) return path;
    if (path.startsWith('/uploads')) return '$baseHostUrl$path';
    return '$baseHostUrl/uploads/$path';
  }

  static Future<List<Category>> fetchCategories() async {
    final response = await http
        .get(Uri.parse('$baseUrl/categories'))
        .timeout(const Duration(seconds: 10));

    if (response.statusCode == 200) {
      final Map<String, dynamic> body =
          jsonDecode(response.body) as Map<String, dynamic>;
      final List<dynamic> list =
          (body['data'] as Map<String, dynamic>)['categories'] as List<dynamic>;
      return list
          .map((e) => Category.fromJson(e as Map<String, dynamic>))
          .toList();
    }
    throw Exception('Failed to load categories');
  }

  static Future<List<Product>> fetchMedicines({String? search}) async {
    final String query = (search == null || search.isEmpty)
        ? ''
        : '?search=$search';
    final response = await http
        .get(Uri.parse('$baseUrl/medicines$query'))
        .timeout(const Duration(seconds: 10));

    if (response.statusCode == 200) {
      final Map<String, dynamic> body =
          jsonDecode(response.body) as Map<String, dynamic>;
      final List<dynamic> list =
          (body['data'] as Map<String, dynamic>)['medicines'] as List<dynamic>;
      return list
          .map((e) => Product.fromJson(e as Map<String, dynamic>))
          .toList();
    }
    throw Exception('Failed to load medicines');
  }

  static Future<void> createMedicine({
    required String name,
    required double price,
    required String categoryId,
    String? description,
    double discountPercent = 0,
    int stock = 0,
    List<String> images = const [],
    bool requiresPrescription = false,
    bool isFeatured = false,
  }) async {
    final response = await http
        .post(
          Uri.parse('$baseUrl/medicines'),
          headers: _authHeaders(),
          body: jsonEncode({
            'name': name,
            'price': price,
            'category': categoryId,
            if (description != null) 'description': description,
            if (images.isNotEmpty) 'images': images,
            'discountPercent': discountPercent,
            'stock': stock,
            'requiresPrescription': requiresPrescription,
            'isFeatured': isFeatured,
          }),
        )
        .timeout(const Duration(seconds: 10));

    if (response.statusCode != 201) {
      throw Exception(_extractMessage(response));
    }
  }

  static Future<void> updateMedicine({
    required String id,
    required String name,
    required double price,
    required String categoryId,
    String? description,
    double discountPercent = 0,
    int stock = 0,
    List<String> images = const [],
    bool requiresPrescription = false,
    bool isFeatured = false,
  }) async {
    final response = await http
        .put(
          Uri.parse('$baseUrl/medicines/$id'),
          headers: _authHeaders(),
          body: jsonEncode({
            'name': name,
            'price': price,
            'category': categoryId,
            if (description != null) 'description': description,
            if (images.isNotEmpty) 'images': images,
            'discountPercent': discountPercent,
            'stock': stock,
            'requiresPrescription': requiresPrescription,
            'isFeatured': isFeatured,
          }),
        )
        .timeout(const Duration(seconds: 10));

    if (response.statusCode != 200) {
      throw Exception(_extractMessage(response));
    }
  }

  static Future<void> deleteMedicine({required String id}) async {
    final response = await http
        .delete(Uri.parse('$baseUrl/medicines/$id'), headers: _authHeaders())
        .timeout(const Duration(seconds: 10));

    if (response.statusCode != 200) {
      throw Exception(_extractMessage(response));
    }
  }

  static Future<String> placeOrder(OrderRequest request) async {
    final response = await http
        .post(
          Uri.parse('$baseUrl/orders'),
          headers: _authHeaders(),
          body: jsonEncode(request.toJson()),
        )
        .timeout(const Duration(seconds: 15));

    if (response.statusCode == 201) {
      final Map<String, dynamic> body = _decode(response);
      final Map<String, dynamic> data =
          body['data'] as Map<String, dynamic>? ?? {};
      final Map<String, dynamic>? order =
          data['order'] as Map<String, dynamic>?;
      return order?['_id'] as String? ?? '';
    }

    throw Exception(_extractMessage(response));
  }

  static List<CartItem> _parseCartItems(Map<String, dynamic> body) {
    final Map<String, dynamic> data =
        body['data'] as Map<String, dynamic>? ?? {};
    final Map<String, dynamic> cart =
        data['cart'] as Map<String, dynamic>? ?? {};
    final List<dynamic> items = cart['items'] as List<dynamic>? ?? [];
    return items
        .map((e) => CartItem.fromJson(e as Map<String, dynamic>))
        .toList();
  }

  static Future<List<CartItem>> fetchCart() async {
    final response = await http
        .get(Uri.parse('$baseUrl/cart'), headers: _authHeaders())
        .timeout(const Duration(seconds: 10));

    if (response.statusCode == 200) {
      final body = _decode(response);
      return _parseCartItems(body);
    }
    throw Exception(_extractMessage(response));
  }

  static Future<List<CartItem>> addToCart({
    required String medicineId,
    int quantity = 1,
  }) async {
    final response = await http
        .post(
          Uri.parse('$baseUrl/cart/add'),
          headers: _authHeaders(),
          body: jsonEncode({'medicineId': medicineId, 'quantity': quantity}),
        )
        .timeout(const Duration(seconds: 10));

    if (response.statusCode == 200) {
      final body = _decode(response);
      return _parseCartItems(body);
    }
    throw Exception(_extractMessage(response));
  }

  static Future<List<CartItem>> updateCartItem({
    required String medicineId,
    required int quantity,
  }) async {
    final response = await http
        .put(
          Uri.parse('$baseUrl/cart/update'),
          headers: _authHeaders(),
          body: jsonEncode({'medicineId': medicineId, 'quantity': quantity}),
        )
        .timeout(const Duration(seconds: 10));

    if (response.statusCode == 200) {
      final body = _decode(response);
      return _parseCartItems(body);
    }
    throw Exception(_extractMessage(response));
  }

  static Future<List<CartItem>> removeFromCart(String medicineId) async {
    final response = await http
        .delete(
          Uri.parse('$baseUrl/cart/remove/$medicineId'),
          headers: _authHeaders(),
        )
        .timeout(const Duration(seconds: 10));

    if (response.statusCode == 200) {
      final body = _decode(response);
      return _parseCartItems(body);
    }
    throw Exception(_extractMessage(response));
  }

  static Future<List<CartItem>> clearCart() async {
    final response = await http
        .delete(Uri.parse('$baseUrl/cart/clear'), headers: _authHeaders())
        .timeout(const Duration(seconds: 10));

    if (response.statusCode == 200) {
      final body = _decode(response);
      return _parseCartItems(body);
    }
    throw Exception(_extractMessage(response));
  }

  static Future<List<OrderSummary>> fetchMyOrders({
    int page = 1,
    int limit = 20,
  }) async {
    final uri = Uri.parse(
      '$baseUrl/orders',
    ).replace(queryParameters: {'page': '$page', 'limit': '$limit'});
    final response = await http
        .get(uri, headers: _authHeaders())
        .timeout(const Duration(seconds: 10));

    if (response.statusCode == 200) {
      final body = _decode(response);
      final Map<String, dynamic> data =
          body['data'] as Map<String, dynamic>? ?? {};
      final List<dynamic> orders = data['orders'] as List<dynamic>? ?? [];
      return orders
          .map((e) => OrderSummary.fromJson(e as Map<String, dynamic>))
          .toList();
    }
    throw Exception(_extractMessage(response));
  }

  static Future<NotificationFeed> fetchNotifications({
    int page = 1,
    int limit = 20,
  }) async {
    final uri = Uri.parse(
      '$baseUrl/notifications',
    ).replace(queryParameters: {'page': '$page', 'limit': '$limit'});
    final response = await http
        .get(uri, headers: _authHeaders())
        .timeout(const Duration(seconds: 10));

    if (response.statusCode == 200) {
      return NotificationFeed.fromJson(_decode(response));
    }
    throw Exception(_extractMessage(response));
  }

  static Future<AppNotification> markNotificationAsRead(String id) async {
    final response = await http
        .put(
          Uri.parse('$baseUrl/notifications/$id/read'),
          headers: _authHeaders(),
        )
        .timeout(const Duration(seconds: 10));

    if (response.statusCode == 200) {
      final body = _decode(response);
      final data = body['data'] as Map<String, dynamic>? ?? {};
      final notification = data['notification'] as Map<String, dynamic>? ?? {};
      return AppNotification.fromJson(notification);
    }
    throw Exception(_extractMessage(response));
  }

  static Future<void> markAllNotificationsAsRead() async {
    final response = await http
        .put(
          Uri.parse('$baseUrl/notifications/read-all'),
          headers: _authHeaders(),
        )
        .timeout(const Duration(seconds: 10));

    if (response.statusCode != 200) {
      throw Exception(_extractMessage(response));
    }
  }

  static Future<void> deleteNotification(String id) async {
    final response = await http
        .delete(
          Uri.parse('$baseUrl/notifications/$id'),
          headers: _authHeaders(),
        )
        .timeout(const Duration(seconds: 10));

    if (response.statusCode != 200) {
      throw Exception(_extractMessage(response));
    }
  }

  static Future<void> registerFcmToken(String fcmToken) async {
    final response = await http
        .put(
          Uri.parse('$baseUrl/notifications/fcm-token'),
          headers: _authHeaders(),
          body: jsonEncode({'fcmToken': fcmToken}),
        )
        .timeout(const Duration(seconds: 10));

    if (response.statusCode != 200) {
      throw Exception(_extractMessage(response));
    }
  }

  static Future<void> clearNotifications() async {
    final response = await http
        .delete(Uri.parse('$baseUrl/notifications'), headers: _authHeaders())
        .timeout(const Duration(seconds: 10));

    if (response.statusCode != 200) {
      throw Exception(_extractMessage(response));
    }
  }

  static Future<List<Product>> fetchAlternatives(String medicineId) async {
    final response = await http
        .get(Uri.parse('$baseUrl/medicines/$medicineId/alternatives'))
        .timeout(const Duration(seconds: 10));

    if (response.statusCode == 200) {
      final body = _decode(response);
      final Map<String, dynamic> data =
          body['data'] as Map<String, dynamic>? ?? {};
      final List<dynamic> list = data['alternatives'] as List<dynamic>? ?? [];
      return list
          .map((e) => Product.fromJson(e as Map<String, dynamic>))
          .toList();
    }

    throw Exception(_extractMessage(response));
  }

  static bool get _isDoctorAccount => AuthSession.role == 'doctor';

  static UserProfile _parseProfileResponse(
    Map<String, dynamic> body, {
    required bool isDoctor,
  }) {
    final Map<String, dynamic> data =
        body['data'] as Map<String, dynamic>? ?? {};
    final Map<String, dynamic> profile = isDoctor
        ? data['doctor'] as Map<String, dynamic>? ?? {}
        : data['user'] as Map<String, dynamic>? ?? {};
    return UserProfile.fromJson(profile);
  }

  static Future<UserProfile> fetchMyProfile() async {
    final isDoctor = _isDoctorAccount;
    final response = await http
        .get(
          Uri.parse(
            isDoctor ? '$baseUrl/doctors/me/profile' : '$baseUrl/users/me',
          ),
          headers: _authHeaders(),
        )
        .timeout(const Duration(seconds: 10));

    if (response.statusCode == 200) {
      return _parseProfileResponse(_decode(response), isDoctor: isDoctor);
    }

    throw Exception(_extractMessage(response));
  }

  static Future<UserProfile> updateMyProfile({
    required String name,
    required String email,
    required String phone,
  }) async {
    final isDoctor = _isDoctorAccount;
    final response = await http
        .put(
          Uri.parse(
            isDoctor ? '$baseUrl/doctors/me/profile' : '$baseUrl/users/me',
          ),
          headers: _authHeaders(),
          body: jsonEncode({'name': name, 'email': email, 'phone': phone}),
        )
        .timeout(const Duration(seconds: 10));

    if (response.statusCode == 200) {
      return _parseProfileResponse(_decode(response), isDoctor: isDoctor);
    }

    throw Exception(_extractMessage(response));
  }

  static Future<List<DoctorProfile>> fetchDoctors() async {
    final response = await http
        .get(Uri.parse('$baseUrl/doctors'))
        .timeout(const Duration(seconds: 10));

    if (response.statusCode == 200) {
      final body = _decode(response);
      final List<dynamic> list =
          (body['data'] as Map<String, dynamic>)['doctors'] as List<dynamic>;
      return list
          .map((e) => DoctorProfile.fromJson(e as Map<String, dynamic>))
          .toList();
    }
    throw Exception(_extractMessage(response));
  }

  static Future<Consultation> startConsultation({
    required String doctorId,
    String? topic,
  }) async {
    final response = await http
        .post(
          Uri.parse('$baseUrl/consultations'),
          headers: _authHeaders(),
          body: jsonEncode({
            'doctorId': doctorId,
            if (topic != null && topic.isNotEmpty) 'topic': topic,
          }),
        )
        .timeout(const Duration(seconds: 10));

    if (response.statusCode == 201) {
      final body = _decode(response);
      final consultation =
          (body['data'] as Map<String, dynamic>)['consultation']
              as Map<String, dynamic>;
      return Consultation.fromJson(consultation);
    }

    if (response.statusCode == 400) {
      final body = _decode(response);
      final data = body['data'] as Map<String, dynamic>? ?? {};
      final existingId = data['consultationId'] as String?;
      if (existingId != null && existingId.isNotEmpty) {
        return fetchConsultation(existingId);
      }
    }

    throw Exception(_extractMessage(response));
  }

  static Future<List<Consultation>> fetchMyConsultations() async {
    final isDoctor = _isDoctorAccount;
    final response = await http
        .get(
          Uri.parse(
            isDoctor
                ? '$baseUrl/doctors/me/consultations'
                : '$baseUrl/consultations',
          ),
          headers: _authHeaders(),
        )
        .timeout(const Duration(seconds: 10));

    if (response.statusCode == 200) {
      final body = _decode(response);
      final List<dynamic> list =
          (body['data'] as Map<String, dynamic>)['consultations']
              as List<dynamic>;
      return list
          .map((e) => Consultation.fromJson(e as Map<String, dynamic>))
          .toList();
    }
    throw Exception(_extractMessage(response));
  }

  static Future<Consultation> fetchConsultation(String id) async {
    final isDoctor = _isDoctorAccount;
    final response = await http
        .get(
          Uri.parse(
            isDoctor
                ? '$baseUrl/doctors/me/consultations/$id'
                : '$baseUrl/consultations/$id',
          ),
          headers: _authHeaders(),
        )
        .timeout(const Duration(seconds: 10));

    if (response.statusCode == 200) {
      final body = _decode(response);
      final consultation =
          (body['data'] as Map<String, dynamic>)['consultation']
              as Map<String, dynamic>;
      return Consultation.fromJson(consultation);
    }
    throw Exception(_extractMessage(response));
  }

  static Future<Consultation> closeConsultation({
    required String consultationId,
    String? reason,
    int? rating,
    String? comment,
  }) async {
    final response = await http
        .put(
          Uri.parse('$baseUrl/consultations/$consultationId/close'),
          headers: _authHeaders(),
          body: jsonEncode({
            if (reason != null && reason.isNotEmpty) 'reason': reason,
            if (rating != null) 'rating': rating,
            if (comment != null && comment.isNotEmpty) 'comment': comment,
          }),
        )
        .timeout(const Duration(seconds: 10));

    if (response.statusCode == 200) {
      final body = _decode(response);
      final consultation =
          (body['data'] as Map<String, dynamic>)['consultation']
              as Map<String, dynamic>;
      return Consultation.fromJson(consultation);
    }
    throw Exception(_extractMessage(response));
  }

  static Future<Consultation> rateConsultation({
    required String consultationId,
    required int rating,
    String? comment,
  }) async {
    final response = await http
        .put(
          Uri.parse('$baseUrl/consultations/$consultationId/rate'),
          headers: _authHeaders(),
          body: jsonEncode({
            'rating': rating,
            if (comment != null && comment.isNotEmpty) 'comment': comment,
          }),
        )
        .timeout(const Duration(seconds: 10));

    if (response.statusCode == 200) {
      final body = _decode(response);
      final consultation =
          (body['data'] as Map<String, dynamic>)['consultation']
              as Map<String, dynamic>;
      return Consultation.fromJson(consultation);
    }
    throw Exception(_extractMessage(response));
  }

  static Future<ChatMessage> sendConsultationMessage({
    required String consultationId,
    String? text,
    String? imagePath,
  }) async {
    if (imagePath != null && imagePath.isNotEmpty) {
      final request = http.MultipartRequest(
        'POST',
        Uri.parse('$baseUrl/consultations/$consultationId/messages'),
      );
      request.headers.addAll(_authHeaders(json: false));
      if (text != null && text.isNotEmpty) {
        request.fields['text'] = text;
      }
      request.files.add(
        await http.MultipartFile.fromPath('attachment', imagePath),
      );
      final streamed = await request.send();
      final response = await http.Response.fromStream(streamed);
      if (response.statusCode == 201) {
        final body = _decode(response);
        final message =
            (body['data'] as Map<String, dynamic>)['message']
                as Map<String, dynamic>;
        return ChatMessage.fromJson(message);
      }
      throw Exception(_extractMessage(response));
    }

    final response = await http
        .post(
          Uri.parse('$baseUrl/consultations/$consultationId/messages'),
          headers: _authHeaders(),
          body: jsonEncode({'text': text ?? ''}),
        )
        .timeout(const Duration(seconds: 10));

    if (response.statusCode == 201) {
      final body = _decode(response);
      final message =
          (body['data'] as Map<String, dynamic>)['message']
              as Map<String, dynamic>;
      return ChatMessage.fromJson(message);
    }
    throw Exception(_extractMessage(response));
  }

  static Future<LoginResult> login({
    required String email,
    required String password,
  }) async {
    final response = await http
        .post(
          Uri.parse('$baseUrl/auth/login'),
          headers: {'Content-Type': 'application/json'},
          body: jsonEncode({'email': email, 'password': password}),
        )
        .timeout(const Duration(seconds: 10));

    if (response.statusCode == 200) {
      final body = _decode(response);
      final data = body['data'] as Map<String, dynamic>? ?? {};
      final userId = data['userId'] as String? ?? '';
      final token = body['token'] as String?;
      final role = data['role'] as String?;
      final accountType = data['accountType'] as String?;
      final isDoctor = role == 'doctor' || accountType == 'doctor';

      if (isDoctor && token != null && token.isNotEmpty) {
        return LoginResult(
          userId: userId,
          needsVerification: false,
          skipOtp: true,
          token: token,
          role: role ?? 'doctor',
          name: data['name'] as String?,
          message: body['message'] as String? ?? 'Doctor login successful.',
        );
      }

      return LoginResult(
        userId: userId,
        needsVerification: false,
        message: body['message'] as String? ?? 'Login OTP sent.',
      );
    }

    if (response.statusCode == 403) {
      final body = _decode(response);
      final data = body['data'] as Map<String, dynamic>? ?? {};
      final userId = data['userId'] as String? ?? '';
      final needsVerification = data['needsVerification'] == true;
      if (needsVerification && userId.isNotEmpty) {
        return LoginResult(
          userId: userId,
          needsVerification: true,
          message: body['message'] as String? ?? 'Account needs verification.',
        );
      }
    }

    throw Exception(_extractMessage(response));
  }

  static Future<String> register({
    required String name,
    required String email,
    required String phone,
    required String password,
  }) async {
    final response = await http
        .post(
          Uri.parse('$baseUrl/auth/register'),
          headers: {'Content-Type': 'application/json'},
          body: jsonEncode({
            'name': name,
            'email': email,
            'phone': phone,
            'password': password,
          }),
        )
        .timeout(const Duration(seconds: 10));

    if (response.statusCode == 201) {
      final body = _decode(response);
      final data = body['data'] as Map<String, dynamic>? ?? {};
      final userId = data['userId'] as String? ?? '';
      return userId;
    }

    throw Exception(_extractMessage(response));
  }

  // ── BUG FIX: verifyOtp now saves the token, role, and name to
  // AuthSession immediately after the server returns them.
  // Previously the token was returned to the caller but never
  // stored, so every subsequent authenticated request (including
  // PrescriptionService) had no token and got 401 "Invalid or
  // expired token".
  static Future<VerifyOtpResult> verifyOtp({
    required String userId,
    required String otp,
    required String purpose,
  }) async {
    final response = await http
        .post(
          Uri.parse('$baseUrl/auth/verify-otp'),
          headers: {'Content-Type': 'application/json'},
          body: jsonEncode({'userId': userId, 'otp': otp, 'purpose': purpose}),
        )
        .timeout(const Duration(seconds: 10));

    if (response.statusCode == 200) {
      final body = _decode(response);
      final data = body['data'] as Map<String, dynamic>? ?? {};
      final user = data['user'] as Map<String, dynamic>?;

      final token = body['token'] as String?;
      final resetToken = data['resetToken'] as String?;
      final role = user?['role'] as String?;
      final name = user?['name'] as String?;

      // ── Save to AuthSession so every service can use it ──────
      if (token != null && token.isNotEmpty) {
        AuthSession.token = token;
        AuthSession.userId = userId;
        AuthSession.role = role;
        AuthSession.name = name;
      }

      return VerifyOtpResult(
        token: token,
        resetToken: resetToken,
        role: role,
        name: name,
        message: body['message'] as String? ?? 'OTP verified.',
      );
    }

    throw Exception(_extractMessage(response));
  }

  static Future<GoogleAuthResult> googleAuth({required String idToken}) async {
    final response = await http
        .post(
          Uri.parse('$baseUrl/auth/google'),
          headers: {'Content-Type': 'application/json'},
          body: jsonEncode({'idToken': idToken}),
        )
        .timeout(const Duration(seconds: 15));

    if (response.statusCode == 200 || response.statusCode == 201) {
      final body = _decode(response);
      final data = body['data'] as Map<String, dynamic>? ?? {};
      final user = data['user'] as Map<String, dynamic>? ?? {};
      final token = body['token'] as String?;
      final userId = user['_id'] as String? ?? user['id'] as String? ?? '';

      if (token == null || token.isEmpty || userId.isEmpty) {
        throw Exception('Invalid Google auth response from server.');
      }

      final role = user['role'] as String?;
      final name = user['name'] as String?;

      AuthSession.token = token;
      AuthSession.userId = userId;
      AuthSession.role = role ?? 'user';
      AuthSession.name = name;

      return GoogleAuthResult(
        token: token,
        userId: userId,
        role: role,
        name: name,
        isNewUser: response.statusCode == 201,
        message: body['message'] as String? ?? 'Google sign-in successful.',
      );
    }

    throw Exception(_extractMessage(response));
  }

  static Future<ForgotPasswordResult> forgotPassword({
    required String email,
  }) async {
    final response = await http
        .post(
          Uri.parse('$baseUrl/auth/forgot-password'),
          headers: {'Content-Type': 'application/json'},
          body: jsonEncode({'email': email}),
        )
        .timeout(const Duration(seconds: 10));

    if (response.statusCode == 200) {
      final body = _decode(response);
      return ForgotPasswordResult(
        userId: body['userId'] as String?,
        message: body['message'] as String? ?? 'OTP sent.',
      );
    }

    throw Exception(_extractMessage(response));
  }

  static Future<void> resendOtp({
    required String userId,
    required String purpose,
  }) async {
    final response = await http
        .post(
          Uri.parse('$baseUrl/auth/resend-otp'),
          headers: {'Content-Type': 'application/json'},
          body: jsonEncode({'userId': userId, 'purpose': purpose}),
        )
        .timeout(const Duration(seconds: 10));

    if (response.statusCode != 200) {
      throw Exception(_extractMessage(response));
    }
  }

  static Future<void> createDoctor({
    required String name,
    required String email,
    required String phone,
    required String password,
    required String specialty,
    int experience = 0,
  }) async {
    final response = await http
        .post(
          Uri.parse('$baseUrl/admin/doctors'),
          headers: _authHeaders(),
          body: jsonEncode({
            'name': name,
            'email': email,
            'phone': phone,
            'password': password,
            'specialty': specialty,
            'experience': experience,
          }),
        )
        .timeout(const Duration(seconds: 10));

    if (response.statusCode != 201) {
      throw Exception(_extractMessage(response));
    }
  }

  static Future<void> resetPassword({
    required String userId,
    required String resetToken,
    required String newPassword,
  }) async {
    final response = await http
        .post(
          Uri.parse('$baseUrl/auth/reset-password'),
          headers: {'Content-Type': 'application/json'},
          body: jsonEncode({
            'userId': userId,
            'resetToken': resetToken,
            'newPassword': newPassword,
          }),
        )
        .timeout(const Duration(seconds: 10));

    if (response.statusCode != 200) {
      throw Exception(_extractMessage(response));
    }
  }

  static Future<List<NewsItem>> fetchNews({String language = 'en'}) async {
    final normalizedLanguage = language.toLowerCase() == 'ar' ? 'ar' : 'en';
    final uri = Uri.parse('$newsBaseUrl/everything').replace(
      queryParameters: {
        'q': 'medicine OR health OR pharmacy',
        'language': normalizedLanguage,
        'pageSize': '20',
        'apiKey': newsApiKey,
      },
    );
    final response = await http
        .get(uri, headers: {'X-Api-Key': newsApiKey})
        .timeout(const Duration(seconds: 10));

    if (response.statusCode == 200) {
      final Map<String, dynamic> body =
          jsonDecode(response.body) as Map<String, dynamic>;
      final List<dynamic> list = body['articles'] as List<dynamic>;
      return list
          .map((e) => NewsItem.fromJson(e as Map<String, dynamic>))
          .toList();
    }
    throw Exception('Failed to load news');
  }

  static Future<void> saveCardDetails(Map<String, String> cardData) async {}
}
