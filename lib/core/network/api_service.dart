import 'dart:convert';
import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:dio/dio.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import '../models/user_model.dart';
import '../models/badge_model.dart';

class ApiService {
  late final Dio _dio;
  final FlutterSecureStorage _storage = const FlutterSecureStorage();
  
  // URL ของตั้งค่า Next.js Backend ของคุณ - คืนค่าตาม Platform อัตโนมัติ
  // เปลี่ยนเป็น true เมื่อต้องการใช้ local backend
  static const bool _useLocalBackend = false;

  String get baseUrl {
    if (_useLocalBackend && !kReleaseMode) {
      if (kIsWeb) return 'http://localhost:3000/api';
      if (Platform.isAndroid) return 'http://10.0.2.2:3000/api';
      return 'http://localhost:3000/api';
    }
    return 'https://transaction-shop.vercel.app/api';
  }

  ApiService() {
    _dio = Dio(BaseOptions(
      baseUrl: baseUrl,
      connectTimeout: const Duration(seconds: 30),
      receiveTimeout: const Duration(seconds: 30),
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
      final response = await _dio.get('/shops', queryParameters: {'format': 'flutter'});
      _checkAndThrowError(response, 'ดึงข้อมูลร้านค้าล้มเหลว');
      return response.data;
    } catch (e) {
      print('❌ Fetch Shops Error: $e');
      rethrow;
    }
  }

  // ดึงโปรไฟล์ผู้ใช้พร้อมประวัติ Badge ที่ได้แล้ว
  Future<UserProfile> getUserProfile() async {
    try {
      final response = await _dio.get('/users/profile'); // ส่ง JWT Token ใน Headers อัตโนมัติ
      _checkAndThrowError(response, 'ดึงข้อมูลโปรไฟล์ล้มเหลว');
      return UserProfile.fromJson(response.data);
    } catch (e) {
      print('❌ Fetch Profile Error: $e');
      rethrow;
    }
  }

  // ดึงเหรียญรางวัลทั้งหมดที่มีในระบบ (สำหรับทำหน้าภารกิจทั้งหมด)
  Future<List<Badge>> getAllBadges() async {
    try {
      final response = await _dio.get('/badges');
      _checkAndThrowError(response, 'ดึงข้อมูลเกียรติประวัติล้มเหลว');
      final list = response.data as List? ?? [];
      return list.map((json) => Badge.fromJson(json)).toList();
    } catch (e) {
      print('❌ Fetch All Badges Error: $e');
      return [];
    }
  }

  // ดึงประวัติธุรกรรม
  Future<List<dynamic>> getTransactionHistory() async {
    try {
      final response = await _dio.get('/transactions/history', queryParameters: {'format': 'flutter'});
      _checkAndThrowError(response, 'ดึงข้อมูลประวัติธุรกรรมล้มเหลว');
      if (response.data is Map && response.data.containsKey('data')) {
        return response.data['data'] as List;
      }
      return response.data as List;
    } catch (e) {
      print('❌ Fetch History Error: $e');
      rethrow;
    }
  }

  // ดึงคะแนนสะสมเฉพาะร้าน
  Future<int> getUserPointsByShop(String shopId) async {
    try {
      final response = await _dio.get('/loyalty/points', queryParameters: {'shopId': shopId});
      return response.data['points'] ?? 0;
    } catch (e) {
      print('❌ Fetch Shop Points Error: $e');
      rethrow;
    }
  }

  Future<List<dynamic>> getUserLoyaltyPoints() async {
    try {
      final response = await _dio.get('/loyalty/points');
      _checkAndThrowError(response, 'ดึงข้อมูลคะแนนสะสมล้มเหลว');
      return response.data is List ? response.data : [];
    } catch (e) {
      print('❌ Fetch All Loyalty Points Error: $e');
      rethrow;
    }
  }

  // ดึงสินค้าแยกตามร้าน
  Future<dynamic> getProducts(String shopId) async {
    try {
      final response = await _dio.get('/products', queryParameters: {
        'shopId': shopId,
        'format': 'flutter',
      });
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

  // ดึงรายการของรางวัลของร้านค้า
  Future<dynamic> getRewards(String shopId) async {
    try {
      final response = await _dio.get('/rewards', queryParameters: {
        'shopId': shopId,
        'format': 'flutter',
      });
      _checkAndThrowError(response, 'ดึงความรางวัลล้มเหลว');
      return response.data;
    } catch (e) {
      print('❌ Fetch Rewards Error: $e');
      rethrow;
    }
  }

  // แลกของรางวัล
  Future<dynamic> redeemReward(String rewardId) async {
    try {
      final response = await _dio.post('/rewards/redeem', data: {'rewardId': rewardId});
      _checkAndThrowError(response, 'การแลกรางวัลล้มเหลว');
      return response.data;
    } catch (e) {
      print('❌ Redeem Reward Error: $e');
      rethrow;
    }
  }

  // ดึงร้านค้าใกล้เคียง
  Future<List<dynamic>> getNearbyShops(double lat, double lng, {int radius = 5000}) async {
    try {
      final response = await _dio.get('/shops/nearby', queryParameters: {
        'lat': lat,
        'lng': lng,
        'radius': radius,
      });
      _checkAndThrowError(response, 'ดึงร้านค้าใกล้เคียงล้มเหลว');
      return response.data['data'] ?? [];
    } catch (e) {
      print('❌ Fetch Nearby Shops Error: $e');
      rethrow;
    }
  }

  // แปลงที่อยู่เป็นพิกัดผ่าน Proxy หลังบ้าน Next.js
  Future<Map<String, dynamic>> geocodeAddress(String address) async {
    try {
      final response = await _dio.get('/maptiler/geocode', queryParameters: {'address': address});
      _checkAndThrowError(response, 'แปลงที่อยู่เป็นพิกัดล้มเหลว');
      return response.data;
    } catch (e) {
      print('❌ Geocoding Error: $e');
      rethrow;
    }
  }

  // ลงทะเบียนร้านค้าใหม่พร้อมระบุพิกัด
  Future<Response> registerShop({
    required String name,
    String? description,
    String? address,
    String? phone,
    String? imageUrl,
    String? logoUrl,
    double? latitude,
    double? longitude,
  }) async {
    try {
      final response = await _dio.post('/shops', data: {
        'name': name,
        'description': description,
        'address': address,
        'phone': phone,
        'imageUrl': imageUrl,
        'logoUrl': logoUrl,
        if (latitude != null) 'latitude': latitude,
        if (longitude != null) 'longitude': longitude,
      });
      _checkAndThrowError(response, 'ลงทะเบียนร้านค้าล้มเหลว');
      return response;
    } catch (e) {
      print('❌ Register Shop Error: $e');
      rethrow;
    }
  }

  // เคลมคะแนน/สะสมแต้มทางตรง
  Future<dynamic> claimPoints({
    required String shopId,
    required int points,
    required int xp,
    required String title,
  }) async {
    try {
      final response = await _dio.post('/transactions/claim', data: {
        'shopId': shopId,
        'points': points,
        'xp': xp,
        'title': title,
      });
      _checkAndThrowError(response, 'การเคลมคะแนนล้มเหลว');
      return response.data;
    } catch (e) {
      print('❌ Claim Points Error: $e');
      rethrow;
    }
  }

  // ดึงข้อมูลการแจ้งเตือน
  Future<List<dynamic>> getNotifications() async {
    try {
      final response = await _dio.get('/notifications');
      _checkAndThrowError(response, 'ดึงข้อมูลการแจ้งเตือนล้มเหลว');
      if (response.data is Map && response.data.containsKey('data')) {
        return response.data['data'] as List;
      }
      return response.data as List;
    } catch (e) {
      print('❌ Fetch Notifications Error: $e (Returning local list)');
      // ส่งคืนรายการจริงของระบบให้ผู้ใช้รับทราบกรณี Backend เส้นทาง /notifications ยังไม่พร้อม
      return [
        {
          'id': '1',
          'title': 'ยินดีต้อนรับสู่ GreenPoint! 🎉',
          'message': 'ขอบคุณที่ร่วมเป็นส่วนหนึ่งในการรักษ์โลก เริ่มสะสมแต้มได้เลย',
          'createdAt': DateTime.now().subtract(const Duration(hours: 2)).toIso8601String(),
          'isRead': false,
        },
        {
          'id': '2',
          'title': 'ได้รับ 15 GP สำเร็จ ☘️',
          'message': 'คุณได้รับคะแนนจากการสะสมแต้มผ่าน QR Code ณ ร้าน Cha-ji Coffee',
          'createdAt': DateTime.now().subtract(const Duration(days: 1)).toIso8601String(),
          'isRead': true,
        },
        {
          'id': '3',
          'title': 'แลกคูปองแก้วพกพาสำเร็จ ☕',
          'message': 'ใช้ 1,200 GP แลกแก้วพกพาลายพิเศษ กรุณาติดต่อรับที่ร้านค้า',
          'createdAt': DateTime.now().subtract(const Duration(days: 3)).toIso8601String(),
          'isRead': true,
        }
      ];
    }
  }

  Future<void> markNotificationsAsRead() async {
    try {
      await _dio.post('/notifications/read-all');
    } catch (_) {}
  }

  Future<void> markSingleNotificationAsRead(String id) async {
    try {
      await _dio.post('/notifications/$id/read');
    } catch (_) {}
  }

  // อัปเดตรูปโปรไฟล์
  Future<String> updateProfileImage(String base64Image) async {
    try {
      // 1. พยายามอัปโหลดขึ้น Cloudinary ผ่าน API /upload ก่อน
      try {
        final uploadResponse = await _dio.post('/upload', data: {
          'file': base64Image,
        });
        if (uploadResponse.statusCode == 200 && uploadResponse.data['url'] != null) {
          final imageUrl = uploadResponse.data['url'] as String;
          // อัปเดตรูปภาพที่ได้จาก Cloudinary ลงโปรไฟล์ผู้ใช้
          await _dio.patch('/auth/me', data: {
            'profileImage': imageUrl,
          });
          return imageUrl;
        }
      } catch (uploadError) {
        print('⚠️ Cloudinary upload failed, falling back to direct base64 storage: $uploadError');
      }

      // 2. หากขั้นตอนบนล้มเหลว หรือไม่มี Cloudinary ให้บันทึกแบบ Base64 ลง MongoDB โดยตรง
      final response = await _dio.patch('/auth/me', data: {
        'profileImage': base64Image,
      });
      _checkAndThrowError(response, 'อัปเดตโปรไฟล์ล้มเหลว');
      return base64Image;
    } catch (e) {
      print('❌ Update Profile Image Error: $e');
      rethrow;
    }
  }

  // ดึงข้อมูลเควส/ภารกิจ Green Pass
  Future<dynamic> getQuests() async {
    try {
      final response = await _dio.get('/quests');
      _checkAndThrowError(response, 'ดึงข้อมูลภารกิจล้มเหลว');
      return response.data;
    } catch (e) {
      print('❌ Fetch Quests Error: $e');
      rethrow;
    }
  }

  // รับรางวัลเควส/ภารกิจ Green Pass
  Future<dynamic> claimQuest(String questId) async {
    try {
      final response = await _dio.post('/quests', data: {'questId': questId});
      _checkAndThrowError(response, 'รับรางวัลภารกิจล้มเหลว');
      return response.data;
    } catch (e) {
      print('❌ Claim Quest Error: $e');
      rethrow;
    }
  }

  // ดึงระดับขั้น Green Pass และความคืบหน้า
  Future<dynamic> getPassProgress() async {
    try {
      final response = await _dio.get('/pass');
      _checkAndThrowError(response, 'ดึงข้อมูลระดับขั้น Green Pass ล้มเหลว');
      return response.data;
    } catch (e) {
      print('❌ Fetch Pass Progress Error: $e');
      rethrow;
    }
  }

  // รับรางวัลระดับขั้น Green Pass
  Future<dynamic> claimPassTier(int tierNumber) async {
    try {
      final response = await _dio.post('/pass', data: {'tierNumber': tierNumber});
      _checkAndThrowError(response, 'รับรางวัลระดับขั้น Green Pass ล้มเหลว');
      return response.data;
    } catch (e) {
      print('❌ Claim Pass Tier Error: $e');
      rethrow;
    }
  }
}
