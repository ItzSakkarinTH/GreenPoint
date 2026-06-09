import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:greenpoint/core/providers/shop_provider.dart'; // ใช้ apiServiceProvider จากที่นี่
import 'package:greenpoint/core/providers/auth_provider.dart';
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
      level: (userData['level'] as num?)?.toInt() ?? 1,
      currentXp: (userData['currentXp'] as num?)?.toInt() ?? 0,
      maxXp: (userData['maxXp'] as num?)?.toInt() ?? 100,
      plasticReduced: (userData['plasticReduced'] as num?)?.toDouble() ?? 0.0,
      totalPoints: ((userData['totalPointsEarned'] ?? userData['totalPoints'] ?? userData['points']) as num?)?.toInt() ?? 0,
      streakCount: ((userData['streakCount'] ?? userData['streak']) as num?)?.toInt() ?? 0,
      todaysPoints: (userData['todaysPoints'] as num?)?.toInt() ?? 0,
    );
  } on DioException catch (e) {
    if (e.response?.statusCode == 401) {
      print('🔐 Unauthorized access (401), logging out...');
      ref.read(authProvider.notifier).logout();
    }
    print('❌ Error in userProfileProvider: $e');
    rethrow;
  } catch (e) {
    final errStr = e.toString().toLowerCase();
    if (errStr.contains('401') || errStr.contains('unauthorized') || errStr.contains('unauth')) {
      print('🔐 Unauthorized access (Exception), logging out...');
      ref.read(authProvider.notifier).logout();
    }
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
    xp: item['xp'] ?? 0,
    isNegative: item['isNegative'] ?? false,
  )).toList();
});
final shopPointsProvider = FutureProvider.autoDispose.family<int, String>((ref, shopId) async {
  final apiService = ref.watch(apiServiceProvider);
  return await apiService.getUserPointsByShop(shopId);
});

class ActiveTabNotifier extends Notifier<int> {
  @override
  int build() => 0;

  @override
  set state(int value) => super.state = value;
}

final activeTabProvider = NotifierProvider<ActiveTabNotifier, int>(ActiveTabNotifier.new);


