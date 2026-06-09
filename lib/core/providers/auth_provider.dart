import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import '../../core/network/api_service.dart';

final authProvider = AsyncNotifierProvider<AuthNotifier, bool>(() {
  return AuthNotifier();
});

class AuthNotifier extends AsyncNotifier<bool> {
  final FlutterSecureStorage _storage = const FlutterSecureStorage();
  
  @override
  Future<bool> build() async {
    final token = await _storage.read(key: 'jwt_token');
    return token != null && token.isNotEmpty;
  }

  Future<bool> login(String username, String password) async {
    state = const AsyncValue.loading();
    try {
      final apiService = ApiService();
      final response = await apiService.login(username, password);
      
      if (response.statusCode == 200 || response.statusCode == 201) {
        state = const AsyncValue.data(true);
        return true;
      }
      state = const AsyncValue.data(false);
      return false;
    } catch (e) {
      state = const AsyncValue.data(false);
      return false;
    }
  }

  Future<bool> register(String username, String password, String name, String phone) async {
    state = const AsyncValue.loading();
    try {
      final apiService = ApiService();
      final response = await apiService.register(username, password, name, phone);
      
      if (response.statusCode == 200 || response.statusCode == 201) {
        // Automatically login if token is returned, otherwise just return true
        if (response.data['token'] != null) {
          await _storage.write(key: 'jwt_token', value: response.data['token']);
          state = const AsyncValue.data(true);
        } else {
          state = const AsyncValue.data(false);
        }
        return true;
      }
      state = const AsyncValue.data(false);
      return false;
    } catch (e) {
      state = const AsyncValue.data(false);
      return false;
    }
  }

  Future<void> logout() async {
    state = const AsyncValue.loading();
    await _storage.delete(key: 'jwt_token');
    state = const AsyncValue.data(false);
  }
}
