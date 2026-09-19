import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/network/api_client.dart';

class AdminRepository {
  AdminRepository(this._api);

  final ApiClient _api;

  Future<void> createDoctor({
    required String name,
    required String email,
    required String phone,
    required String password,
    required String specialty,
    int experience = 0,
  }) => _api.post(
    '/admin/doctors',
    body: {
      'name': name,
      'email': email,
      'phone': phone,
      'password': password,
      'specialty': specialty,
      'experience': experience,
    },
  );
}

final adminRepositoryProvider = Provider<AdminRepository>(
  (ref) => AdminRepository(ref.watch(apiClientProvider)),
);
