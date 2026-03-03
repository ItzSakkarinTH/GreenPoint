import 'package:dio/dio.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';

class ApiService {
  late final Dio _dio;
  final FlutterSecureStorage _storage = const FlutterSecureStorage();
  
  // URL ของตั้งค่า Next.js Backend ของคุณ
  final String baseUrl = 'https://transaction-shop.vercel.app/api';

  ApiService() {
    _dio = Dio(BaseOptions(
      baseUrl: baseUrl,
      connectTimeout: const Duration(seconds: 10),
      receiveTimeout: const Duration(seconds: 10),
      responseType: ResponseType.json,
    ));

    // เพิ่ม Interceptor จัดการแนบ Token สมัยใหม่
    _dio.interceptors.add(
      InterceptorsWrapper(
        onRequest: (options, handler) async {
          // ดึง JWT token จากระบบความปลอดภัยของมือถือ
          final token = await _storage.read(key: 'jwt_token');
          
          if (token != null) {
            // แนบ Token ไปกับ Header (Bearer Authorization) อัตโนมัติทุก Request
            options.headers['Authorization'] = 'Bearer $token';
          }
          return handler.next(options); // ปล่อย Request ผ่านไปทำงานต่อ
        },
        onError: (DioException e, handler) {
          // จัดการเวลามี Error ตอบกลับจากเซิร์ฟเวอร์
          if (e.response?.statusCode == 401) {
            // กรณี Token หมดอายุ สามารถเขียน Logic ในการ Refresh Token
            // หรือเตะผู้ใช้กลับไปหน้า Login ได้ที่นี่
          }
          return handler.next(e);
        },
      ),
    );
  }

  // ตัวอย่างการเข้าสู่ระบบ
  Future<Response> login(String username, String password) async {
    try {
      final response = await _dio.post('/auth/login', data: {
        'username': username,
        'password': password,
      });
      
      // เมื่อ Next.js ตอบกลับมาพร้อม token, ให้บันทึกลงเครื่องอย่างปลอดภัย
      final token = response.data['token'];
      if (token != null) {
        await _storage.write(key: 'jwt_token', value: token);
      }
      
      return response;
    } catch (e) {
      rethrow;
    }
  }

  // ฟังก์ชันสมัครสมาชิก
  Future<Response> register(String username, String password, String name, String phone) async {
    try {
      print('🚀 Sending registration request to: $baseUrl/auth/register');
      print('📦 Data: {username: $username, name: $name, phone: $phone}');
      
      final response = await _dio.post('/auth/register', data: {
        'username': username,
        'password': password,
        'name': name,
        'phone': phone,
        'role': 'user', // กำหนดให้เป็นระดับ user ธรรมดาเสมอเมื่อสมัครจากแอป
      });
      
      print('✅ Registration Response: ${response.statusCode}');
      return response;
    } catch (e) {
      print('❌ Registration Error: $e');
      rethrow;
    }
  }

  // ตัวอย่างฟังก์ชัน Logout ลบ Token ทิ้ง
  Future<void> logout() async {
    await _storage.delete(key: 'jwt_token');
  }

  // ดึงข้อมูลร้านค้าทั้งหมด
  Future<List<dynamic>> getShops() async {
    try {
      final response = await _dio.get('/shops');
      return response.data;
    } catch (e) {
      print('❌ Fetch Shops Error: $e');
      rethrow;
    }
  }
  // ดึงข้อมูลโปรไฟล์ผู้ใช้
  Future<Map<String, dynamic>> getUserProfile() async {
    try {
      final response = await _dio.get('/auth/me'); // เปลี่ยนเป็น endpoint จริง (ปกติคือ /auth/me หรือ /profile)
      return response.data;
    } catch (e) {
      print('❌ Fetch Profile Error: $e');
      rethrow;
    }
  }

  // ดึงประวัติธุรกรรม
  Future<List<dynamic>> getTransactionHistory() async {
    try {
      final response = await _dio.get('/transactions/history');
      return response.data;
    } catch (e) {
      print('❌ Fetch History Error: $e');
      rethrow;
    }
  }

  // ดึงสินค้าแยกตามร้าน
  Future<List<dynamic>> getProducts(String shopId) async {
    try {
      final response = await _dio.get('/products', queryParameters: {'shopId': shopId});
      return response.data;
    } catch (e) {
      print('❌ Fetch Products Error: $e');
      rethrow;
    }
  }
}
