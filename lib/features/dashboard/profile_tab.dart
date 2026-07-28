import 'package:flutter/material.dart' hide Badge;
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'dart:convert';
import 'package:image_picker/image_picker.dart';
import '../../core/providers/shop_provider.dart';
import '../../core/providers/user_provider.dart';
import '../../core/providers/auth_provider.dart';
import '../../core/models/user_model.dart';
import '../../core/models/badge_model.dart';
import 'streak_screen.dart';
import 'achievements_screen.dart';
import 'dashboard_screen.dart';
import '../../core/providers/notification_provider.dart';
import 'widgets/greenpass_card.dart';

const Color primaryGreen = Color(0xFF2E7D32);
const Color secondaryGreen = Color(0xFF4CAF50);
const Color accentLightGreen = Color(0xFFE8F5E9);

// =========================================================================
// 💡 INSTRUCTIONS FOR THE USER (วิธีการใส่รูปภาพ Achievements ของคุณเอง):
// 1. นำไฟล์รูปภาพเหรียญรางวัล/ตราความสำเร็จของคุณไปวางไว้ที่โฟลเดอร์โครงการ:
//    - assets/images/badges/lock.jpg (รูปกุญแจล็อค)
//    - assets/images/badges/Eco Starter 1.jpg ...
// =========================================================================

class ProfileTab extends ConsumerWidget {
  const ProfileTab({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final profileAsync = ref.watch(userProfileProvider);
    final historyAsync = ref.watch(historyProvider);

    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        centerTitle: false,
        title: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(4),
              decoration: const BoxDecoration(
                color: primaryGreen,
                shape: BoxShape.circle,
              ),
              child: const Icon(Icons.eco, color: Colors.white, size: 20),
            ),
            const SizedBox(width: 8),
            const Text(
              'GreenPoint',
              style: TextStyle(
                color: primaryGreen,
                fontWeight: FontWeight.w900,
                fontSize: 22,
              ),
            ),
          ],
        ),
        actions: [
          // Notification Bell
          Consumer(
            builder: (context, ref, child) {
              final notifications = ref.watch(notificationsProvider);
              final unreadCount = notifications.where((n) => !n.isRead).length;
              return Stack(
                alignment: Alignment.center,
                children: [
                  IconButton(
                    icon: const Icon(Icons.notifications_none_outlined, size: 26, color: Colors.grey),
                    onPressed: () => NotificationBottomSheet.show(context),
                  ),
                  if (unreadCount > 0)
                    Positioned(
                      right: 6,
                      top: 10,
                      child: Container(
                        padding: const EdgeInsets.all(2),
                        decoration: const BoxDecoration(
                          color: Colors.red,
                          shape: BoxShape.circle,
                        ),
                        constraints: const BoxConstraints(
                          minWidth: 14,
                          minHeight: 14,
                        ),
                        child: Text(
                          '$unreadCount',
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 8,
                            fontWeight: FontWeight.bold,
                          ),
                          textAlign: TextAlign.center,
                        ),
                      ),
                    ),
                ],
              );
            },
          ),
          // Logout Button
          IconButton(
            icon: const Icon(Icons.logout, color: Colors.redAccent),
            onPressed: () => _showLogoutDialog(context, ref),
          ),
          const SizedBox(width: 8),
        ],
      ),
      body: profileAsync.when(
        data: (profile) => SingleChildScrollView(
          physics: const BouncingScrollPhysics(),
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // 1. Profile Card
              _buildProfileCard(context, ref, profile),
              const SizedBox(height: 16),

              // Green Pass Card
              const GreenPassCard(),
              const SizedBox(height: 16),

              // 2. GreenPoint Mascot
              _buildMascotSpeechBubble(),
              const SizedBox(height: 16),

              // 3. Streak Counter
              _buildStreakCard(context, profile),
              const SizedBox(height: 24),

              // 4. Achievements Section
              _buildAchievementsSection(context, ref, profile),
              const SizedBox(height: 24),

              // 5. Activity History
              historyAsync.when(
                data: (transactions) => _buildHistorySection(context, transactions),
                loading: () => const Center(child: CircularProgressIndicator(color: primaryGreen)),
                error: (e, _) => Center(child: Text('ไม่สามารถโหลดประวัติได้: $e')),
              ),
              const SizedBox(height: 32),
            ],
          ),
        ),
        loading: () => const Center(child: CircularProgressIndicator(color: primaryGreen)),
        error: (e, _) => Center(child: Text('เกิดข้อผิดพลาด: $e')),
      ),
    );
  }

  // 1. Profile Card
  Widget _buildProfileCard(BuildContext context, WidgetRef ref, UserProfile profile) {
    final int remainingXp = profile.maxXp - profile.currentXp;
    final double xpProgress = profile.maxXp > 0 ? (profile.currentXp / profile.maxXp).clamp(0.0, 1.0) : 0.7;

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: Colors.grey.shade100, width: 1.5),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.02),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        children: [
          Row(
            children: [
              // Avatar Stack
              GestureDetector(
                onTap: () => _showImageSourcePicker(context, ref),
                child: Stack(
                  children: [
                    Container(
                      width: 72,
                      height: 72,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: Colors.grey.shade100,
                        border: Border.all(color: Colors.grey.shade200, width: 2),
                      ),
                      child: ClipOval(
                        child: _buildAvatar(profile.profileImage),
                      ),
                    ),
                    Positioned(
                      bottom: 0,
                      right: 0,
                      child: Container(
                        padding: const EdgeInsets.all(4),
                        decoration: const BoxDecoration(
                          color: Colors.white,
                          shape: BoxShape.circle,
                          boxShadow: [BoxShadow(color: Colors.black12, blurRadius: 4)],
                        ),
                        child: const Icon(Icons.camera_alt, size: 12, color: Colors.grey),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 16),
              // User Info details
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Text(
                          profile.name.isEmpty ? 'Mr. G' : profile.name,
                          style: const TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                            color: Color(0xFF333333),
                          ),
                        ),
                        const SizedBox(width: 6),
                        // Level Badge
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                          decoration: BoxDecoration(
                            color: primaryGreen,
                            borderRadius: BorderRadius.circular(6),
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              const Icon(Icons.shield, size: 8, color: Colors.white),
                              const SizedBox(width: 2),
                              Text(
                                'Level ${profile.level}',
                                style: const TextStyle(
                                  color: Colors.white,
                                  fontSize: 8,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 2),
                    const Text(
                      'รักษ์โลกในแบบของเรา ☘️',
                      style: TextStyle(
                        fontSize: 11,
                        color: Colors.grey,
                        fontStyle: FontStyle.italic,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          // XP progress indicator
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'XP Progress',
                style: TextStyle(fontSize: 10, color: Colors.grey.shade500, fontWeight: FontWeight.bold),
              ),
              Text(
                '${profile.currentXp} XP / ${profile.maxXp} XP',
                style: const TextStyle(fontSize: 10, color: primaryGreen, fontWeight: FontWeight.bold),
              ),
            ],
          ),
          const SizedBox(height: 6),
          ClipRRect(
            borderRadius: BorderRadius.circular(10),
            child: LinearProgressIndicator(
              value: xpProgress,
              minHeight: 8,
              backgroundColor: Colors.grey.shade100,
              valueColor: const AlwaysStoppedAnimation<Color>(secondaryGreen),
            ),
          ),
          const SizedBox(height: 6),
          Align(
            alignment: Alignment.centerLeft,
            child: Text(
              'อีก $remainingXp XP เพื่อเลื่อนเป็น Level ${profile.level + 1}',
              style: TextStyle(
                fontSize: 9,
                color: Colors.grey.shade500,
              ),
            ),
          ),
        ],
      ),
    );
  }

  // 2. Nong Thung speech bubble card
  Widget _buildMascotSpeechBubble() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        color: const Color(0xFFF9FBF9),
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: const Color(0xFFE8F5E9), width: 1),
      ),
      child: Row(
        children: [
          Image.asset(
            'assets/images/nong_thung.png',
            height: 48,
            fit: BoxFit.contain,
            errorBuilder: (context, error, stackTrace) => const Icon(
              Icons.eco,
              size: 44,
              color: secondaryGreen,
            ),
          ),
          const SizedBox(width: 14),
          const Expanded(
            child: Text(
              'ยอดเยี่ยมมาก! คุณกำลังช่วยโลก\nไปพร้อมกับสร้างสิ่งดีๆ ให้ตัวเอง',
              style: TextStyle(
                color: Color(0xFF2E7D32),
                fontSize: 11,
                fontWeight: FontWeight.bold,
                height: 1.4,
              ),
            ),
          ),
        ],
      ),
    );
  }

  // 3. Streak Counter
  Widget _buildStreakCard(BuildContext context, UserProfile profile) {
    return GestureDetector(
      onTap: () {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => StreakScreen(
              plasticCount: profile.plasticReduced,
              streakCount: profile.streakCount,
            ),
          ),
        );
      },
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: Colors.grey.shade100, width: 1.5),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header Pill
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
              decoration: BoxDecoration(
                color: accentLightGreen,
                borderRadius: BorderRadius.circular(8),
              ),
              child: const Text(
                'ใช้แอปต่อเนื่อง',
                style: TextStyle(
                  color: primaryGreen,
                  fontSize: 10,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
            const SizedBox(height: 12),
            Row(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                // Flame Counter
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        const Icon(Icons.local_fire_department, color: Colors.orange, size: 24),
                        const SizedBox(width: 4),
                        Text(
                          '${profile.streakCount} วัน',
                          style: const TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                            color: Color(0xFF333333),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 4),
                    const Text(
                      'เก่งมาก! รักษ์โลกอย่างต่อเนื่อง',
                      style: TextStyle(
                        fontSize: 10,
                        color: Colors.grey,
                      ),
                    ),
                  ],
                ),
                const Spacer(),
                // 7 Days Circles
                _build7DaysRow(profile.streakCount),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _build7DaysRow(int streakCount) {
    final List<String> days = ['จ.', 'อ.', 'พ.', 'พฤ.', 'ศ.', 'ส.', 'อา.'];
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: List.generate(7, (index) {
        final bool isChecked = streakCount >= 7 || (streakCount % 7 > index);
        return Container(
          margin: const EdgeInsets.only(left: 4),
          child: Column(
            children: [
              Container(
                width: 22,
                height: 22,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: isChecked ? primaryGreen : Colors.white,
                  border: Border.all(
                    color: isChecked ? primaryGreen : Colors.grey.shade300,
                    width: 1,
                  ),
                ),
                child: Center(
                  child: isChecked
                      ? const Icon(Icons.check, size: 12, color: Colors.white)
                      : Text(
                          days[index],
                          style: TextStyle(
                            fontSize: 8,
                            color: Colors.grey.shade600,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                ),
              ),
              if (isChecked) ...[
                const SizedBox(height: 2),
                Text(
                  days[index],
                  style: const TextStyle(
                    fontSize: 7,
                    color: primaryGreen,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ],
          ),
        );
      }),
    );
  }

  // 4. Achievements Section
  Widget _buildAchievementsSection(BuildContext context, WidgetRef ref, UserProfile profile) {
    final allBadgesAsync = ref.watch(allBadgesProvider);
    
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            const Text(
              'Achievements',
              style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.bold,
                color: Color(0xFF333333),
              ),
            ),
            TextButton(
              onPressed: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => AchievementsScreen(profile: profile),
                  ),
                );
              },
              style: TextButton.styleFrom(
                padding: EdgeInsets.zero,
                minimumSize: const Size(0, 0),
                tapTargetSize: MaterialTapTargetSize.shrinkWrap,
              ),
              child: const Text(
                'ดูทั้งหมด >',
                style: TextStyle(
                  fontSize: 11,
                  color: primaryGreen,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),
        allBadgesAsync.when(
          data: (allBadges) {
            if (allBadges.isEmpty) {
              return const SizedBox(
                height: 80,
                child: Center(
                  child: Text('ไม่มีเกียรติประวัติ', style: TextStyle(color: Colors.grey, fontSize: 12)),
                ),
              );
            }
            
            // Group badges by baseName to find the highest unlocked tier for each unique badge group
            final Map<String, List<Badge>> groupedBadges = {};
            for (var badge in allBadges) {
              final baseName = badge.name.replaceAll(RegExp(r'\s*\(.*\)'), '').trim();
              groupedBadges.putIfAbsent(baseName, () => []).add(badge);
            }

            final List<Map<String, dynamic>> displayItems = [];
            
            groupedBadges.forEach((baseName, badgesForGroup) {
              // Check which of these are unlocked by the user
              Badge? highestUnlocked;
              int highestTierValue = 99; // Lower number means higher tier: 1 = Platinum, 4 = Bronze
              
              for (var badge in badgesForGroup) {
                final isUnlocked = profile.badges.any((b) => b.id == badge.id);
                if (isUnlocked) {
                  final tierVal = _rarityToTier(badge.rarity);
                  if (tierVal < highestTierValue) {
                    highestTierValue = tierVal;
                    highestUnlocked = badge;
                  }
                }
              }

              final templateBadge = badgesForGroup.first;
              
              displayItems.add({
                'name': highestUnlocked?.name ?? baseName,
                'description': highestUnlocked?.description ?? templateBadge.description,
                'iconUrl': highestUnlocked?.iconUrl ?? templateBadge.iconUrl,
                'tier': highestUnlocked != null ? _rarityToTier(highestUnlocked.rarity) : null,
                'criteriaType': templateBadge.criteriaType,
                'isUnlocked': highestUnlocked != null,
              });
            });

            // เรียงลำดับ: ปลดล็อกแล้ว (isUnlocked: true) ขึ้นก่อน, ยังไม่ปลดล็อกไว้ข้างหลัง
            displayItems.sort((a, b) {
              final bool aUnlocked = a['isUnlocked'] as bool;
              final bool bUnlocked = b['isUnlocked'] as bool;
              if (aUnlocked && !bUnlocked) return -1;
              if (!aUnlocked && bUnlocked) return 1;
              return 0;
            });

            final List<Widget> items = displayItems.map((item) {
              return _buildDynamicAchievementItem(
                item['name'] as String,
                item['description'] as String,
                item['iconUrl'] as String,
                item['tier'] as int?,
                item['criteriaType'] as String,
              );
            }).toList();

            return SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              physics: const BouncingScrollPhysics(),
              child: Row(children: items),
            );
          },
          loading: () => const SizedBox(
            height: 80,
            child: Center(child: CircularProgressIndicator(color: primaryGreen, strokeWidth: 2)),
          ),
          error: (err, _) => const SizedBox(
            height: 80,
            child: Center(
              child: Text('โหลดข้อมูลล้มเหลว', style: TextStyle(color: Colors.redAccent, fontSize: 12)),
            ),
          ),
        ),
      ],
    );
  }

  int _rarityToTier(String rarity) {
    switch (rarity.toLowerCase()) {
      case 'legendary': return 1;
      case 'epic': return 2;
      case 'rare': return 3;
      case 'common': return 4;
      default: return 4;
    }
  }

  Widget _buildDynamicAchievementItem(
    String name,
    String desc,
    String iconUrl,
    int? tier,
    String criteriaType,
  ) {
    final bool isLocked = tier == null;
    
    IconData fallbackIcon = Icons.spa;
    Color themeColor = Colors.green;
    if (criteriaType == 'total_points') {
      fallbackIcon = Icons.emoji_events_rounded;
      themeColor = Colors.amber;
    } else if (criteriaType == 'plastic_reduced') {
      fallbackIcon = Icons.eco_rounded;
      themeColor = Colors.teal;
    } else if (criteriaType == 'level') {
      fallbackIcon = Icons.military_tech_rounded;
      themeColor = Colors.blueAccent;
    }

    if (tier == 1) themeColor = const Color(0xFFB2DFDB); // Platinum
    if (tier == 2) themeColor = const Color(0xFFFFE082); // Gold
    if (tier == 3) themeColor = const Color(0xFFEEEEEE); // Silver
    if (tier == 4) themeColor = const Color(0xFFFFCC80); // Bronze

    String tierText = 'ยังไม่สำเร็จ';
    if (tier == 1) tierText = 'ระดับแพลทินัม';
    if (tier == 2) tierText = 'ระดับโกลด์';
    if (tier == 3) tierText = 'ระดับซิลเวอร์';
    if (tier == 4) tierText = 'ระดับบรอนซ์';

    final cleanName = name.replaceAll(RegExp(r'\s*\(.*\)'), '').trim();

    return Container(
      width: 76,
      margin: const EdgeInsets.only(right: 12),
      child: Column(
        children: [
          Container(
            width: 56,
            height: 56,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              boxShadow: [
                BoxShadow(
                  color: isLocked ? Colors.black.withOpacity(0.02) : themeColor.withOpacity(0.15),
                  blurRadius: 8,
                  offset: const Offset(0, 3),
                ),
              ],
            ),
            child: ClipOval(
              child: isLocked
                  ? Container(
                      decoration: BoxDecoration(
                        color: const Color(0xFFF1F1F1),
                        shape: BoxShape.circle,
                        border: Border.all(color: Colors.white, width: 2),
                      ),
                      child: const Center(
                        child: Icon(Icons.lock, color: Colors.grey, size: 24),
                      ),
                    )
                  : (iconUrl.startsWith('http')
                      ? Image.network(
                          iconUrl,
                          fit: BoxFit.cover,
                          errorBuilder: (context, error, stackTrace) => Container(
                            color: themeColor,
                            child: Center(
                              child: Icon(fallbackIcon, color: Colors.white, size: 24),
                            ),
                          ),
                        )
                      : Container(
                          color: themeColor,
                          child: Center(
                            child: Icon(fallbackIcon, color: Colors.white, size: 24),
                          ),
                        )),
            ),
          ),
          const SizedBox(height: 8),
          Text(
            cleanName,
            style: TextStyle(
              fontSize: 10,
              fontWeight: FontWeight.bold,
              color: isLocked ? Colors.grey : const Color(0xFF333333),
            ),
            textAlign: TextAlign.center,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
          const SizedBox(height: 2),
          Text(
            tierText,
            style: TextStyle(
              fontSize: 8,
              color: isLocked ? Colors.grey : primaryGreen,
              fontWeight: isLocked ? FontWeight.normal : FontWeight.bold,
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  // 5. Activity History (ประวัติการทำกิจกรรม)
  Widget _buildHistorySection(BuildContext context, List<Transaction> transactions) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            const Text(
              'ประวัติการทำรายการ',
              style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.bold,
                color: Color(0xFF333333),
              ),
            ),
            TextButton(
              onPressed: () {},
              style: TextButton.styleFrom(
                padding: EdgeInsets.zero,
                minimumSize: const Size(0, 0),
                tapTargetSize: MaterialTapTargetSize.shrinkWrap,
              ),
              child: const Text(
                'ดูทั้งหมด >',
                style: TextStyle(
                  fontSize: 11,
                  color: primaryGreen,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),
        if (transactions.isEmpty)
          const Padding(
            padding: EdgeInsets.symmetric(vertical: 24),
            child: Center(child: Text('ไม่มีประวัติการทำรายการ')),
          )
        else
          ListView.builder(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            itemCount: transactions.length,
            itemBuilder: (context, index) {
              final tx = transactions[index];
              
              // Dynamic values based on XP/GP status
              final String unit = tx.xp != 0 ? 'XP' : 'GP';
              final int val = tx.xp != 0 ? tx.xp : tx.points;
              final String sign = tx.isNegative ? '-' : '+';
              final Color valColor = tx.isNegative ? Colors.red : primaryGreen;
              
              // Choose Icon dynamically based on action
              IconData itemIcon = Icons.qr_code_scanner;
              Color itemColor = Colors.green;
              
              if (tx.title.contains('แลก')) {
                itemIcon = Icons.redeem;
                itemColor = Colors.orange;
              } else if (tx.title.contains('โบนัส')) {
                itemIcon = Icons.star;
                itemColor = Colors.amber;
              }
              
              return Container(
                margin: const EdgeInsets.only(bottom: 12),
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: Colors.grey.shade100),
                ),
                child: Row(
                  children: [
                    // Icon wrapper
                    Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: itemColor.withOpacity(0.1),
                        shape: BoxShape.circle,
                      ),
                      child: Icon(itemIcon, color: itemColor, size: 18),
                    ),
                    const SizedBox(width: 12),
                    // Title and dates
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            tx.title,
                            style: const TextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.bold,
                              color: Color(0xFF333333),
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                          const SizedBox(height: 2),
                          Text(
                            tx.date,
                            style: TextStyle(
                              fontSize: 9,
                              color: Colors.grey.shade500,
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(width: 8),
                    // Points changes
                    Row(
                      children: [
                        Text(
                          '$sign$val $unit',
                          style: TextStyle(
                            color: valColor,
                            fontSize: 12,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(width: 4),
                        Icon(
                          Icons.chevron_right,
                          size: 14,
                          color: Colors.grey.shade400,
                        ),
                      ],
                    ),
                  ],
                ),
              );
            },
          ),
      ],
    );
  }

  void _showLogoutDialog(BuildContext context, WidgetRef ref) {
    showDialog(
      context: context,
      builder: (BuildContext dialogContext) {
        return AlertDialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
          title: const Text(
            'ออกจากระบบ',
            style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
          ),
          content: const Text(
            'คุณต้องการออกจากระบบสะสมแต้มใช่หรือไม่?',
            style: TextStyle(fontSize: 13),
          ),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.of(dialogContext).pop();
              },
              child: const Text(
                'ยกเลิก',
                style: TextStyle(
                  color: Colors.grey,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
            TextButton(
              onPressed: () {
                Navigator.of(dialogContext).pop();
                ref.read(authProvider.notifier).logout();
              },
              child: const Text(
                'ออกจากระบบ',
                style: TextStyle(
                  color: Colors.red,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ],
        );
      },
    );
  }

  Widget _buildAvatar(String profileImage) {
    if (profileImage.isEmpty) {
      return const Icon(Icons.person, size: 48, color: Colors.grey);
    }
    
    if (profileImage.startsWith('data:image') && profileImage.contains('base64,')) {
      try {
        final base64Str = profileImage.split('base64,').last;
        return Image.memory(
          base64Decode(base64Str),
          width: 72,
          height: 72,
          fit: BoxFit.cover,
        );
      } catch (_) {
        return const Icon(Icons.person, size: 48, color: Colors.grey);
      }
    }

    return Image.network(
      profileImage,
      width: 72,
      height: 72,
      fit: BoxFit.cover,
      errorBuilder: (context, error, stackTrace) {
        return const Icon(Icons.person, size: 48, color: Colors.grey);
      },
    );
  }

  void _showImageSourcePicker(BuildContext context, WidgetRef ref) {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.only(
          topLeft: Radius.circular(20),
          topRight: Radius.circular(20),
        ),
      ),
      builder: (context) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Padding(
              padding: EdgeInsets.symmetric(vertical: 16),
              child: Text(
                'เลือกรูปภาพโปรไฟล์',
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Color(0xFF333333)),
              ),
            ),
            const Divider(height: 1),
            ListTile(
              leading: const Icon(Icons.photo_library, color: primaryGreen),
              title: const Text('เลือกจากคลังภาพ'),
              onTap: () {
                Navigator.pop(context);
                _pickAndUploadImage(context, ref, ImageSource.gallery);
              },
            ),
            ListTile(
              leading: const Icon(Icons.camera_alt, color: primaryGreen),
              title: const Text('ถ่ายรูปภาพใหม่'),
              onTap: () {
                Navigator.pop(context);
                _pickAndUploadImage(context, ref, ImageSource.camera);
              },
            ),
            const SizedBox(height: 8),
          ],
        ),
      ),
    );
  }

  Future<void> _pickAndUploadImage(BuildContext context, WidgetRef ref, ImageSource source) async {
    try {
      final ImagePicker picker = ImagePicker();
      final XFile? image = await picker.pickImage(
        source: source,
        maxWidth: 512,
        maxHeight: 512,
        imageQuality: 75,
      );

      if (image == null) return;

      // Show loading indicator
      if (!context.mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Row(
            children: [
              SizedBox(
                width: 20,
                height: 20,
                child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2),
              ),
              SizedBox(width: 16),
              Text('กำลังอัปโหลดรูปภาพโปรไฟล์...'),
            ],
          ),
          duration: Duration(seconds: 15),
        ),
      );

      // Convert to Base64
      final bytes = await image.readAsBytes();
      final base64Image = 'data:image/jpeg;base64,${base64Encode(bytes)}';

      // Call API
      final apiService = ref.read(apiServiceProvider);
      await apiService.updateProfileImage(base64Image);

      // Refresh Profile Provider
      ref.invalidate(userProfileProvider);

      if (!context.mounted) return;
      ScaffoldMessenger.of(context).clearSnackBars();
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('อัปเดตรูปภาพโปรไฟล์สำเร็จ!'),
          backgroundColor: Colors.green,
        ),
      );
    } catch (e) {
      print('❌ Pick/Upload Image Error: $e');
      if (!context.mounted) return;
      ScaffoldMessenger.of(context).clearSnackBars();
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('เกิดข้อผิดพลาดในการอัปโหลด: $e'),
          backgroundColor: Colors.redAccent,
        ),
      );
    }
  }
}
