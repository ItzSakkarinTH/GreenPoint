import 'package:flutter/material.dart' hide Badge;
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/models/user_model.dart';
import '../../core/models/badge_model.dart';
import '../../core/providers/user_provider.dart';

const Color primaryGreen = Color(0xFF2E7D32);

class AchievementsScreen extends ConsumerWidget {
  final UserProfile profile;
  const AchievementsScreen({super.key, required this.profile});

  String _getRequirementText(String criteriaType, int criteriaValue) {
    if (criteriaType == 'level') {
      return 'เลเวล $criteriaValue ขึ้นไป';
    } else if (criteriaType == 'total_points') {
      return 'สะสม $criteriaValue GP';
    } else if (criteriaType == 'plastic_reduced') {
      return 'ลดขยะ $criteriaValue ชิ้น';
    }
    return '';
  }

  String _rarityToName(String rarity) {
    switch (rarity.toLowerCase()) {
      case 'legendary': return 'Platinum (ระดับแพลทินัม)';
      case 'epic': return 'Gold (ระดับโกลด์)';
      case 'rare': return 'Silver (ระดับซิลเวอร์)';
      case 'common': return 'Bronze (ระดับบรอนซ์)';
      default: return 'Bronze (ระดับบรอนซ์)';
    }
  }

  Color _rarityToColor(String rarity) {
    switch (rarity.toLowerCase()) {
      case 'legendary': return const Color(0xFFB2DFDB); // Platinum
      case 'epic': return const Color(0xFFFFE082); // Gold
      case 'rare': return const Color(0xFFEEEEEE); // Silver
      case 'common': return const Color(0xFFFFCC80); // Bronze
      default: return const Color(0xFFFFCC80);
    }
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final allBadgesAsync = ref.watch(allBadgesProvider);

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
      body: allBadgesAsync.when(
        data: (allBadges) {
          if (allBadges.isEmpty) {
            return const Center(
              child: Text(
                'ไม่พบเกียรติประวัติในขณะนี้',
                style: TextStyle(color: Colors.grey),
              ),
            );
          }

          // Group badges by rarity: legendary, epic, rare, common
          final Map<String, List<Badge>> groupedByRarity = {
            'legendary': [],
            'epic': [],
            'rare': [],
            'common': [],
          };

          for (var badge in allBadges) {
            final key = badge.rarity.toLowerCase();
            if (groupedByRarity.containsKey(key)) {
              groupedByRarity[key]!.add(badge);
            } else {
              groupedByRarity['common']!.add(badge);
            }
          }

          // Remove empty tiers
          final activeRarities = groupedByRarity.keys
              .where((key) => groupedByRarity[key]!.isNotEmpty)
              .toList();

          return ListView.builder(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
            physics: const BouncingScrollPhysics(),
            itemCount: activeRarities.length,
            itemBuilder: (context, index) {
              final rarityKey = activeRarities[index];
              final badgesList = groupedByRarity[rarityKey]!;
              final String tierName = _rarityToName(rarityKey);
              final Color tierColor = _rarityToColor(rarityKey);

              return Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Tier Header
                  Container(
                    margin: const EdgeInsets.only(bottom: 12, top: 8),
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                    decoration: BoxDecoration(
                      color: tierColor.withOpacity(0.3),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Text(
                      tierName,
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.bold,
                        color: Colors.grey.shade800,
                      ),
                    ),
                  ),

                  // Achievements Grid
                  GridView.builder(
                    shrinkWrap: true,
                    physics: const NeverScrollableScrollPhysics(),
                    gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                      crossAxisCount: 3,
                      crossAxisSpacing: 12,
                      mainAxisSpacing: 12,
                      childAspectRatio: 0.82,
                    ),
                    itemCount: badgesList.length,
                    itemBuilder: (context, badgeIndex) {
                      final badge = badgesList[badgeIndex];
                      final bool unlocked = profile.badges.any((b) => b.id == badge.id);
                      final String reqText = _getRequirementText(badge.criteriaType, badge.criteriaValue);

                      // Fallback icons
                      IconData fallbackIcon = Icons.spa;
                      Color fallbackColor = Colors.green;
                      if (badge.criteriaType == 'total_points') {
                        fallbackIcon = Icons.emoji_events_rounded;
                        fallbackColor = Colors.amber;
                      } else if (badge.criteriaType == 'plastic_reduced') {
                        fallbackIcon = Icons.eco_rounded;
                        fallbackColor = Colors.teal;
                      } else if (badge.criteriaType == 'level') {
                        fallbackIcon = Icons.military_tech_rounded;
                        fallbackColor = Colors.blueAccent;
                      }

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
                            // Badge Icon / Image
                            Container(
                              width: 52,
                              height: 52,
                              decoration: const BoxDecoration(shape: BoxShape.circle),
                              child: ClipOval(
                                child: unlocked
                                    ? (badge.iconUrl.startsWith('http')
                                        ? Image.network(
                                            badge.iconUrl,
                                            fit: BoxFit.cover,
                                            errorBuilder: (context, error, stackTrace) => Container(
                                              color: fallbackColor,
                                              child: Center(
                                                child: Icon(fallbackIcon, color: Colors.white, size: 22),
                                              ),
                                            ),
                                          )
                                        : Container(
                                            color: fallbackColor,
                                            child: Center(
                                              child: Icon(fallbackIcon, color: Colors.white, size: 22),
                                            ),
                                          ))
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
                              badge.name.replaceAll(RegExp(r'\s*\(.*\)'), '').trim(),
                              style: TextStyle(
                                fontSize: 10,
                                fontWeight: FontWeight.bold,
                                color: unlocked ? const Color(0xFF333333) : Colors.grey,
                              ),
                              textAlign: TextAlign.center,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
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
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
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
          );
        },
        loading: () => const Center(
          child: CircularProgressIndicator(color: primaryGreen),
        ),
        error: (err, _) => Center(
          child: Text('เกิดข้อผิดพลาดในการโหลดเกียรติประวัติ: $err'),
        ),
      ),
    );
  }
}
