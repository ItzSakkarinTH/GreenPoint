import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:app_links/app_links.dart';
import '../../core/network/api_service.dart';

final authProvider = AsyncNotifierProvider<AuthNotifier, bool>(() {
  return AuthNotifier();
});

class AuthNotifier extends AsyncNotifier<bool> {
  final FlutterSecureStorage _storage = const FlutterSecureStorage();
  late final AppLinks _appLinks;
  
  @override
  Future<bool> build() async {
    _appLinks = AppLinks();

    // Listen to incoming deep links (Warm start)
    _appLinks.uriLinkStream.listen((uri) {
      _handleDeepLink(uri);
    });

    // Check if the app was opened via a deep link (Cold start)
    try {
      final initialUri = await _appLinks.getInitialLink();
      if (initialUri != null) {
        _handleDeepLink(initialUri);
      }
    } catch (e) {
      print('❌ AppLinks initial link error: $e');
    }

    final token = await _storage.read(key: 'jwt_token');
    return token != null && token.isNotEmpty;
  }

  void _handleDeepLink(Uri uri) async {
    print('🔗 Processing incoming deep link: $uri');
    
    // Check if it is a mobile deep link OR a web URL containing the token
    final bool isMobileDeepLink = uri.scheme == 'greenpoint' && uri.host == 'login-success';
    final bool isWebRedirect = (uri.scheme == 'http' || uri.scheme == 'https') && uri.queryParameters.containsKey('token');

    if (isMobileDeepLink || isWebRedirect) {
      final token = uri.queryParameters['token'];
      if (token != null && token.isNotEmpty) {
        state = const AsyncValue.loading();
        await _storage.write(key: 'jwt_token', value: token);
        state = const AsyncValue.data(true);
        print('🔑 Successfully authenticated via LINE login callback');
      }
    }
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
