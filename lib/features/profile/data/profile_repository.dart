import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/network/api_client.dart';
import '../../../core/services/auth_session.dart';
import '../models/user_profile.dart';

/// The signed-in account's profile. Doctors and patients live in separate
/// collections on the backend, so the endpoint depends on the role.
class ProfileRepository {
  ProfileRepository(this._api);

  final ApiClient _api;

  bool get _isDoctor => AuthSession.role == 'doctor';
  String get _path => _isDoctor ? '/doctors/me/profile' : '/users/me';

  Future<UserProfile> fetchMyProfile() async => _parse(await _api.get(_path));

  Future<UserProfile> updateMyProfile({
    required String name,
    required String email,
    required String phone,
  }) async => _parse(
    await _api.put(_path, body: {'name': name, 'email': email, 'phone': phone}),
  );

  UserProfile _parse(Json body) =>
      UserProfile.fromJson(dataObject(body, _isDoctor ? 'doctor' : 'user'));
}

final profileRepositoryProvider = Provider<ProfileRepository>(
  (ref) => ProfileRepository(ref.watch(apiClientProvider)),
);
