import 'package:flutter_secure_storage/flutter_secure_storage.dart';

class AuthStorage {
  const AuthStorage();

  static const _tokenKey = 'jwt';
  final FlutterSecureStorage _storage = const FlutterSecureStorage();

  Future<void> saveToken(String token) async {
    await _storage.write(key: _tokenKey, value: token);
  }

  Future<String?> readToken() async {
    return _storage.read(key: _tokenKey);
  }

  Future<void> clear() async {
    await _storage.delete(key: _tokenKey);
  }
}
