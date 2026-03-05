import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'shop_provider.dart'; // ใช้ apiServiceProvider จากที่นี่
import 'auth_provider.dart';
import '../models/user_model.dart';

final userProfileProvider = FutureProvider.autoDispose<UserProfile>((ref) async {
  final apiService = ref.watch(apiServiceProvider);
  try {
    final responseData = await apiService.getUserProfile();
    print('👤 User Profile Data: $responseData'); // Debug log

    // ลองดึง User Data จากหลายๆ รูปแบบ (top level, user, หรือ data)
    final userData = responseData['user'] ?? responseData['data'] ?? responseData;
    
    // พยายามหาชื่อที่จะแสดงผล โดยเรียงลำดับความสำคัญ
    final displayName = userData['name'] ?? 
                      userData['fullName'] ?? 
                      userData['username'] ?? 
                      responseData['username'] ?? // กรณี username อยู่ชั้นนอกสุด
                      'สมาชิก GreenPoint';
    
    return UserProfile(
      name: displayName,
      level: userData['level'] ?? 1,
      currentXp: userData['currentXp'] ?? 0,
      maxXp: userData['maxXp'] ?? 100,
      plasticReduced: userData['plasticReduced'] ?? 0,
    );
  } on DioException catch (e) {
    if (e.response?.statusCode == 401) {
      print('🔐 Unauthorized access (401), logging out...');
      ref.read(authProvider.notifier).logout();
    }
    print('❌ Error in userProfileProvider: $e');
    rethrow;
  } catch (e) {
    print('❌ Error in userProfileProvider: $e');
    rethrow;
  }
});

final historyProvider = FutureProvider.autoDispose<List<Transaction>>((ref) async {
  final apiService = ref.watch(apiServiceProvider);
  final data = await apiService.getTransactionHistory();
  
  return (data as List).map((item) => Transaction(
    id: item['id']?.toString() ?? '',
    title: item['title'] ?? 'กิจกรรมรักษ์โลก',
    date: item['date'] ?? '-',
    points: item['points'] ?? 0,
    isNegative: item['isNegative'] ?? false,
  )).toList();
});
