import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

class TokenStore {
  TokenStore() : _storage = const FlutterSecureStorage();

  static const _key = 'fulbii_access_token';

  final FlutterSecureStorage _storage;
  String? _token;

  String? get token => _token;

  Future<String?> loadToken() async {
    _token ??= await _storage.read(key: _key);
    return _token;
  }

  Future<void> saveToken(String token) async {
    _token = token;
    await _storage.write(key: _key, value: token);
  }

  Future<void> clear() async {
    _token = null;
    await _storage.delete(key: _key);
  }
}

final tokenStoreProvider = Provider<TokenStore>((_) => TokenStore());
