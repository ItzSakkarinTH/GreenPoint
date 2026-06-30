import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
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
      profileImage: userData['profileImage']?.toString() ?? '',
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
  
  return data.map((item) {
    final id = item['id']?.toString() ?? item['_id']?.toString() ?? '';
    final title = item['title'] ?? item['description'] ?? 'กิจกรรมรักษ์โลก';
    
    // แปลงพิกัดวันเวลา ISO ให้อยู่ในฟอร์แมตปฏิทินไทย พ.ศ.
    String date = item['date'] ?? item['createdAt'] ?? '-';
    if (date != '-') {
      try {
        DateTime dt = DateTime.parse(date).toLocal();
        int thaiYear = dt.year + 543;
        date = DateFormat('dd/MM/').format(dt) + 
            thaiYear.toString() + 
            DateFormat(' • HH:mm').format(dt);
      } catch (_) {}
    }
    
    final int points = (item['points'] as num?)?.toInt() ?? 0;
    final int xp = (item['xp'] as num?)?.toInt() ?? 0;
    
    bool isNegative = item['isNegative'] ?? false;
    if (item['type'] == 'claim' || item['type'] == 'redeem') {
      isNegative = true;
    }
    
    return Transaction(
      id: id,
      title: title,
      date: date,
      points: points,
      xp: xp,
      isNegative: isNegative,
    );
  }).toList();
});
final shopPointsProvider = FutureProvider.autoDispose.family<int, String>((ref, shopId) async {
  final apiService = ref.watch(apiServiceProvider);
  return await apiService.getUserPointsByShop(shopId);
});

final userLoyaltyPointsProvider = FutureProvider.autoDispose<List<dynamic>>((ref) async {
  final apiService = ref.watch(apiServiceProvider);
  return await apiService.getUserLoyaltyPoints();
});

class ActiveTabNotifier extends Notifier<int> {
  @override
  int build() => 0;

  @override
  set state(int value) => super.state = value;
}

final activeTabProvider = NotifierProvider<ActiveTabNotifier, int>(ActiveTabNotifier.new);


