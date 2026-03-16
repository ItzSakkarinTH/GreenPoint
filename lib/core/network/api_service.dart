import 'dart:convert';
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
      validateStatus: (status) => status != null && status < 500,
    ));

    // เพิ่ม Interceptor จัดการแนบ Token สมัยใหม่
    _dio.interceptors.add(
      InterceptorsWrapper(
        onRequest: (options, handler) async {
          // ดึง JWT token จากระบบความปลอดภัยของมือถือ
          final token = await _storage.read(key: 'jwt_token');
          
          if (token != null) {
            print('🔑 Attaching Token to ${options.path}');
            // แนบ Token ไปกับ Header (Bearer Authorization) อัตโนมัติทุก Request
            options.headers['Authorization'] = 'Bearer $token';
          } else {
            print('⚠️ No Token found for ${options.path}');
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

  void _checkAndThrowError(Response response, String defaultErrorMsg) {
    if (response.statusCode != 200 && response.statusCode != 201) {
      String errorMsg = defaultErrorMsg;
      if (response.data is Map<String, dynamic>) {
        errorMsg = response.data['error'] ?? response.data['message'] ?? defaultErrorMsg;
      } else if (response.data is String && response.data.toString().isNotEmpty) {
        if (!response.data.toString().trim().startsWith('<')) {
          errorMsg = response.data;
        }
      }
      throw Exception(errorMsg);
    }
  }

  // ดึงข้อมูลร้านค้าทั้งหมด
  Future<dynamic> getShops() async {
    try {
      final response = await _dio.get('/shops');
      _checkAndThrowError(response, 'ดึงข้อมูลร้านค้าล้มเหลว');
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
      _checkAndThrowError(response, 'ดึงข้อมูลโปรไฟล์ล้มเหลว');
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
      _checkAndThrowError(response, 'ดึงข้อมูลประวัติธุรกรรมล้มเหลว');
      return response.data;
    } catch (e) {
      print('❌ Fetch History Error: $e');
      rethrow;
    }
  }

  // ดึงสินค้าแยกตามร้าน
  Future<dynamic> getProducts(String shopId) async {
    try {
      final response = await _dio.get('/products', queryParameters: {'shopId': shopId});
      _checkAndThrowError(response, 'ดึงข้อมูลสินค้าล้มเหลว');
      return response.data;
    } catch (e) {
      print('❌ Fetch Products Error: $e');
      rethrow;
    }
  }

  // ส่งข้อมูล QR Code ไปยัง Backend เพื่อรับคะแนนสะสม
  Future<dynamic> scanQrCode(String qrData) async {
    try {
      Map<String, dynamic> data;
      try {
        data = jsonDecode(qrData);
      } catch (_) {
        throw Exception('รูปแบบของ QR Code ไม่ถูกต้อง');
      }

      if (data['type'] != 'collect_points') {
         throw Exception('นี่ไม่ใช่ QR Code สำหรับรับคะแนน');
      }

      final response = await _dio.post('/transactions/claim', data: data);
      _checkAndThrowError(response, 'การสแกน QR Code ล้มเหลว');
      return response.data;
    } catch (e) {
      print('❌ Scan QR Code Error: $e');
      rethrow;
    }
  }

  // ดึงข้อมูลอีเว้นท์/โปรโมชั่น
  Future<dynamic> getEvents() async {
    try {
      final response = await _dio.get('/events');
      _checkAndThrowError(response, 'ดึงข้อมูลอีเว้นท์ล้มเหลว');
      return response.data;
    } catch (e) {
      print('❌ Fetch Events Error: $e');
      rethrow;
    }
  }
}
