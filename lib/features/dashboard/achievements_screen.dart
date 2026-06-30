import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/models/user_model.dart';

const Color primaryGreen = Color(0xFF2E7D32);
const Color secondaryGreen = Color(0xFF4CAF50);

class AchievementsScreen extends ConsumerWidget {
  final UserProfile profile;
  const AchievementsScreen({super.key, required this.profile});

  bool _isUnlocked(String key, int tierLevel) {
    // tierLevel: 1 (Platinum), 2 (Gold), 3 (Silver), 4 (Bronze)
    if (key == 'Eco Starter') {
      if (tierLevel == 4) return profile.level >= 1;
      if (tierLevel == 3) return profile.level >= 2;
      if (tierLevel == 2) return profile.level >= 5;
      if (tierLevel == 1) return profile.level >= 8;
    } else if (key == 'Green Shopper') {
      if (tierLevel == 4) return profile.totalPoints >= 10;
      if (tierLevel == 3) return profile.totalPoints >= 100;
      if (tierLevel == 2) return profile.totalPoints >= 500;
      if (tierLevel == 1) return profile.totalPoints >= 1000;
    } else if (key == 'Eco Explorer') {
      if (tierLevel == 4) return profile.level >= 1;
      if (tierLevel == 3) return profile.level >= 2;
      if (tierLevel == 2) return profile.level >= 4;
      if (tierLevel == 1) return profile.level >= 7;
    } else if (key == 'No Plastic') {
      if (tierLevel == 4) return profile.totalPoints >= 50;
      if (tierLevel == 3) return profile.totalPoints >= 80;
      if (tierLevel == 2) return profile.totalPoints >= 400;
      if (tierLevel == 1) return profile.totalPoints >= 800;
    } else if (key == 'Eco Hero') {
      if (tierLevel == 4) return profile.totalPoints >= 100;
      if (tierLevel == 3) return profile.totalPoints >= 200;
      if (tierLevel == 2) return profile.totalPoints >= 600;
      if (tierLevel == 1) return profile.totalPoints >= 1200;
    }
    return false;
  }

  String _getRequirementText(String key, int tierLevel) {
    if (key == 'Eco Starter') {
      if (tierLevel == 4) return 'เลเวล 1 ขึ้นไป';
      if (tierLevel == 3) return 'เลเวล 2 ขึ้นไป';
      if (tierLevel == 2) return 'เลเวล 5 ขึ้นไป';
      if (tierLevel == 1) return 'เลเวล 8 ขึ้นไป';
    } else if (key == 'Green Shopper') {
      if (tierLevel == 4) return 'สะสม 10 GP';
      if (tierLevel == 3) return 'สะสม 100 GP';
      if (tierLevel == 2) return 'สะสม 500 GP';
      if (tierLevel == 1) return 'สะสม 1000 GP';
    } else if (key == 'Eco Explorer') {
      if (tierLevel == 4) return 'เลเวล 1 ขึ้นไป';
      if (tierLevel == 3) return 'เลเวล 2 ขึ้นไป';
      if (tierLevel == 2) return 'เลเวล 4 ขึ้นไป';
      if (tierLevel == 1) return 'เลเวล 7 ขึ้นไป';
    } else if (key == 'No Plastic') {
      if (tierLevel == 4) return 'สะสม 50 GP';
      if (tierLevel == 3) return 'สะสม 80 GP';
      if (tierLevel == 2) return 'สะสม 400 GP';
      if (tierLevel == 1) return 'สะสม 800 GP';
    } else if (key == 'Eco Hero') {
      if (tierLevel == 4) return 'สะสม 100 GP';
      if (tierLevel == 3) return 'สะสม 200 GP';
      if (tierLevel == 2) return 'สะสม 600 GP';
      if (tierLevel == 1) return 'สะสม 1200 GP';
    }
    return '';
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final List<Map<String, dynamic>> categories = [
      {
        'key': 'Eco Starter',
        'title': 'Eco Starter',
        'desc': 'เริ่มใช้งานแอป',
        'icon': Icons.spa,
        'color': Colors.green,
      },
      {
        'key': 'Green Shopper',
        'title': 'Green Shopper',
        'desc': 'ซื้อสินค้าจากร้านค้า',
        'icon': Icons.shopping_cart,
        'color': Colors.amber,
      },
      {
        'key': 'Eco Explorer',
        'title': 'Eco Explorer',
        'desc': 'ใช้บริการหลายร้าน',
        'icon': Icons.explore,
        'color': Colors.teal,
      },
      {
        'key': 'No Plastic',
        'title': 'No Plastic',
        'desc': 'แลกของรางวัล',
        'icon': Icons.card_membership,
        'color': Colors.blueAccent,
      },
      {
        'key': 'Eco Hero',
        'title': 'Eco Hero',
        'desc': 'สะสมแต้มระยะยาว',
        'icon': Icons.emoji_events,
        'color': Colors.purple,
      },
    ];

    final List<Map<String, dynamic>> tiers = [
      {'level': 1, 'name': 'Platinum (ระดับแพลทินัม)', 'color': const Color(0xFFB2DFDB)},
      {'level': 2, 'name': 'Gold (ระดับโกลด์)', 'color': const Color(0xFFFFE082)},
      {'level': 3, 'name': 'Silver (ระดับซิลเวอร์)', 'color': const Color(0xFFEEEEEE)},
      {'level': 4, 'name': 'Bronze (ระดับบรอนซ์)', 'color': const Color(0xFFFFCC80)},
    ];

    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0.5,
        title: const Text(
          'เกียรติประวัติทั้งหมด',
          style: TextStyle(color: primaryGreen, fontWeight: FontWeight.bold, fontSize: 16),
        ),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new, color: primaryGreen, size: 20),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: ListView.builder(
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
        physics: const BouncingScrollPhysics(),
        itemCount: tiers.length,
        itemBuilder: (context, tierIndex) {
          final tier = tiers[tierIndex];
          return Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Tier Header
              Container(
                margin: const EdgeInsets.only(bottom: 12, top: 8),
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                decoration: BoxDecoration(
                  color: tier['color'].withOpacity(0.3),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Text(
                  tier['name'],
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.bold,
                    color: Colors.grey.shade800,
                  ),
                ),
              ),
              
              // Achievements Grid for this Tier
              GridView.builder(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: 3,
                  crossAxisSpacing: 12,
                  mainAxisSpacing: 12,
                  childAspectRatio: 0.85,
                ),
                itemCount: categories.length,
                itemBuilder: (context, catIndex) {
                  final cat = categories[catIndex];
                  final bool unlocked = _isUnlocked(cat['key'], tier['level']);
                  final String assetPath = 'assets/images/badges/${cat['title']} ${tier['level']}.jpg';
                  final String reqText = _getRequirementText(cat['key'], tier['level']);
                  
                  return Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: unlocked ? Colors.white : const Color(0xFFF9F9F9),
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(
                        color: unlocked ? Colors.grey.shade200 : Colors.grey.shade100,
                      ),
                    ),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        // Badge Image
                        Container(
                          width: 52,
                          height: 52,
                          decoration: const BoxDecoration(shape: BoxShape.circle),
                          child: ClipOval(
                            child: unlocked
                                ? Image.asset(
                                    assetPath,
                                    fit: BoxFit.cover,
                                    errorBuilder: (context, error, stackTrace) => Container(
                                      decoration: BoxDecoration(
                                        gradient: LinearGradient(
                                          colors: [cat['color'].withOpacity(0.85), cat['color']],
                                        ),
                                        shape: BoxShape.circle,
                                      ),
                                      child: Center(
                                        child: Icon(cat['icon'], color: Colors.white, size: 22),
                                      ),
                                    ),
                                  )
                                : Container(
                                    color: Colors.grey.shade200,
                                    child: const Center(
                                      child: Icon(Icons.lock, color: Colors.grey, size: 20),
                                    ),
                                  ),
                          ),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          cat['title'],
                          style: TextStyle(
                            fontSize: 10,
                            fontWeight: FontWeight.bold,
                            color: unlocked ? const Color(0xFF333333) : Colors.grey,
                          ),
                          textAlign: TextAlign.center,
                        ),
                        const SizedBox(height: 2),
                        Text(
                          reqText,
                          style: TextStyle(
                            fontSize: 8,
                            color: unlocked ? primaryGreen : Colors.grey,
                            fontWeight: unlocked ? FontWeight.bold : FontWeight.normal,
                          ),
                          textAlign: TextAlign.center,
                        ),
                      ],
                    ),
                  );
                },
              ),
              const Divider(height: 24),
            ],
          );
        },
      ),
    );
  }
}
