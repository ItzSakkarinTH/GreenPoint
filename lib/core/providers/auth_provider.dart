import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import '../../core/network/api_service.dart';

final authProvider = NotifierProvider<AuthNotifier, bool>(() {
  return AuthNotifier();
});

class AuthNotifier extends Notifier<bool> {
  final FlutterSecureStorage _storage = const FlutterSecureStorage();
  
  @override
  bool build() {
    checkLoginStatus();
    return false;
  }

  Future<void> checkLoginStatus() async {
    final token = await _storage.read(key: 'jwt_token');
    if (token != null && token.isNotEmpty) {
      state = true;
    } else {
      state = false;
    }
  }

  Future<bool> login(String username, String password) async {
    try {
      final apiService = ApiService();
      final response = await apiService.login(username, password);
      
      if (response.statusCode == 200 || response.statusCode == 201) {
        state = true;
        return true;
      }
      return false;
    } catch (e) {
      return false;
    }
  }

  Future<bool> register(String username, String password, String name, String phone) async {
    try {
      final apiService = ApiService();
      final response = await apiService.register(username, password, name, phone);
      
      if (response.statusCode == 200 || response.statusCode == 201) {
        // Automatically login if token is returned, otherwise just return true
        if (response.data['token'] != null) {
          await _storage.write(key: 'jwt_token', value: response.data['token']);
          state = true;
        }
        return true;
      }
      return false;
    } catch (e) {
      return false;
    }
  }

  Future<void> logout() async {
    await _storage.delete(key: 'jwt_token');
    state = false;
  }
}
