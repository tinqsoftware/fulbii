import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/network/api_client.dart';

class AuthRepository {
  AuthRepository(this._api);

  final ApiClient _api;

  Future<Map<String, dynamic>> loginSocial({
    required String provider,
    required String idToken,
    String? email,
    String? name,
    String? avatarUrl,
    String? providerUid,
    String deviceName = 'flutter-app',
  }) {
    return _api.postMap(
      '/auth/social/login',
      data: {
        'provider': provider,
        'id_token': idToken,
        'email': email,
        'name': name,
        'avatar_url': avatarUrl,
        'provider_uid': providerUid,
        'device_name': deviceName,
      },
    );
  }

  Future<void> logout() async {
    await _api.postMap('/auth/logout');
  }
}

final authRepositoryProvider = Provider<AuthRepository>((ref) {
  final api = ref.watch(apiClientProvider);
  return AuthRepository(api);
});
