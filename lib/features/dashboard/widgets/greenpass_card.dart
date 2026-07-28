import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:greenpoint/core/providers/greenpass_provider.dart';
import 'package:greenpoint/core/models/quest_model.dart';
import 'package:greenpoint/core/models/pass_model.dart';
import '../greenpass_screen.dart';
import 'redeem_success_dialog.dart';

class GreenPassCard extends ConsumerWidget {
  const GreenPassCard({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final questsAsync = ref.watch(questsProvider);
    final passProgressAsync = ref.watch(passProgressProvider);

    const Color primaryGreen = Color(0xFF2E7D32);
    const Color secondaryGreen = Color(0xFF4CAF50);

    return questsAsync.when(
      data: (quests) {
        return passProgressAsync.when(
          data: (progress) {
            // Calculate variables
            final completedCount = quests.where((q) => q.isCompleted).length;
            final totalCount = quests.length;
            final currentXp = progress.passXp;

            // Find next tier XP requirement
            int nextTierXp = 150; // Default fallback
            for (var tier in progress.tiers) {
              if (tier.requiredXp > currentXp) {
                nextTierXp = tier.requiredXp;
                break;
              }
            }
            // If all tiers are completed, set to last tier
            if (progress.tiers.isNotEmpty && currentXp >= progress.tiers.last.requiredXp) {
              nextTierXp = progress.tiers.last.requiredXp;
            }

            final xpProgressPercent = nextTierXp > 0 ? (currentXp / nextTierXp).clamp(0.0, 1.0) : 0.0;

            // Filter daily and weekly quests
            final dailyQuests = quests.where((q) => q.recurrence == 'daily').toList();
            final weeklyQuests = quests.where((q) => q.recurrence == 'weekly').toList();

            final currentMonthName = DateFormat('MMMM yyyy').format(DateTime.now());

            return GestureDetector(
              onTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (context) => const GreenPassScreen()),
                );
              },
              child: Container(
                width: double.infinity,
              padding: const EdgeInsets.all(18),
              decoration: BoxDecoration(
                color: const Color(0xFFF4FAF6), // Elegant premium soft green-white
                borderRadius: BorderRadius.circular(24),
                border: Border.all(color: const Color(0xFFE3F2E9), width: 1.5),
                boxShadow: [
                  BoxShadow(
                    color: primaryGreen.withOpacity(0.04),
                    blurRadius: 16,
                    offset: const Offset(0, 6),
                  ),
                ],
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // 1. Header Section
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Container(
                        padding: const EdgeInsets.all(8),
                        decoration: BoxDecoration(
                          color: const Color(0xFFE8F5E9),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: const Icon(
                          Icons.flag_rounded,
                          color: primaryGreen,
                          size: 26,
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text(
                              'Green Pass',
                              style: TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.w900,
                                color: primaryGreen,
                              ),
                            ),
                            Text(
                              currentMonthName,
                              style: TextStyle(
                                fontSize: 11,
                                color: Colors.grey.shade600,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            const SizedBox(height: 2),
                            Text(
                              'ทำภารกิจให้ครบ รับ XP และปลดล็อกของรางวัล!',
                              style: TextStyle(
                                fontSize: 10,
                                color: Colors.grey.shade500,
                              ),
                            ),
                          ],
                        ),
                      ),
                      // Top Right Completed indicator
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.end,
                        children: [
                          RichText(
                            text: TextSpan(
                              style: const TextStyle(fontSize: 12, color: Colors.black54),
                              children: [
                                TextSpan(
                                  text: '$completedCount / $totalCount ',
                                  style: const TextStyle(fontWeight: FontWeight.bold, color: primaryGreen),
                                ),
                                const TextSpan(text: 'ภารกิจ'),
                              ],
                            ),
                          ),
                          const SizedBox(height: 4),
                          SizedBox(
                            width: 60,
                            child: ClipRRect(
                              borderRadius: BorderRadius.circular(4),
                              child: LinearProgressIndicator(
                                value: totalCount > 0 ? completedCount / totalCount : 0.0,
                                minHeight: 4,
                                backgroundColor: Colors.grey.shade200,
                                valueColor: const AlwaysStoppedAnimation<Color>(secondaryGreen),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),

                  // 2. XP Progress Indicator Bar
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Row(
                        children: [
                          const Icon(Icons.eco_outlined, size: 12, color: primaryGreen),
                          const SizedBox(width: 4),
                          Text(
                            'XP ที่ได้รับ',
                            style: TextStyle(
                              fontSize: 10,
                              color: Colors.grey.shade600,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ],
                      ),
                      Text(
                        '$currentXp / $nextTierXp 🍃',
                        style: const TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.bold,
                          color: primaryGreen,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 6),
                  ClipRRect(
                    borderRadius: BorderRadius.circular(8),
                    child: LinearProgressIndicator(
                      value: xpProgressPercent,
                      minHeight: 6,
                      backgroundColor: Colors.grey.shade200,
                      valueColor: const AlwaysStoppedAnimation<Color>(secondaryGreen),
                    ),
                  ),
                  const SizedBox(height: 20),

                  // 3. Grid Row (Daily & Weekly Quests)
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // LEFT COLUMN: Daily Quests
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text(
                              'ภารกิจวันนี้',
                              style: TextStyle(
                                fontSize: 12,
                                fontWeight: FontWeight.bold,
                                color: Color(0xFF333333),
                              ),
                            ),
                            const SizedBox(height: 8),
                            ...dailyQuests.map((q) => _buildDailyQuestItem(context, ref, q)),
                            if (dailyQuests.isEmpty)
                              Padding(
                                padding: const EdgeInsets.only(top: 8.0),
                                child: Text(
                                  'ไม่มีภารกิจวันนี้',
                                  style: TextStyle(fontSize: 10, color: Colors.grey.shade400),
                                ),
                              ),
                          ],
                        ),
                      ),
                      const SizedBox(width: 16),
                      // RIGHT COLUMN: Weekly Quests
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text(
                              'ภารกิจสัปดาห์นี้',
                              style: TextStyle(
                                fontSize: 12,
                                fontWeight: FontWeight.bold,
                                color: Color(0xFF333333),
                              ),
                            ),
                            const SizedBox(height: 8),
                            ...weeklyQuests.map((q) => _buildWeeklyQuestItem(context, ref, q)),
                            if (weeklyQuests.isEmpty)
                              Padding(
                                padding: const EdgeInsets.only(top: 8.0),
                                child: Text(
                                  'ไม่มีภารกิจสัปดาห์นี้',
                                  style: TextStyle(fontSize: 10, color: Colors.grey.shade400),
                                ),
                              ),
                          ],
                        ),
                      ),
                    ],
                  ),
                  
                  // 4. View All Quests Link
                  const SizedBox(height: 12),
                  const Divider(color: Color(0xFFE0EFE6), height: 1),
                  const SizedBox(height: 10),
                  Center(
                    child: TextButton(
                      onPressed: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(builder: (context) => const GreenPassScreen()),
                        );
                      },
                      style: TextButton.styleFrom(
                        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
                        minimumSize: Size.zero,
                        tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                      ),
                      child: const Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Text(
                            'ดูภารกิจทั้งหมด',
                            style: TextStyle(
                              color: primaryGreen,
                              fontSize: 11,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          SizedBox(width: 4),
                          Icon(Icons.arrow_forward_ios_rounded, size: 10, color: primaryGreen),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),);
          },
          loading: () => _buildShimmerLoading(),
          error: (err, _) => _buildErrorCard('เกิดข้อผิดพลาด: $err'),
        );
      },
      loading: () => _buildShimmerLoading(),
      error: (err, _) => _buildErrorCard('เกิดข้อผิดพลาด: $err'),
    );
  }

  // Daily quest item UI with interactive Claim behavior
  Widget _buildDailyQuestItem(BuildContext context, WidgetRef ref, Quest quest) {
    const Color primaryGreen = Color(0xFF2E7D32);
    
    Widget checkWidget;
    bool isClickable = false;

    if (quest.isClaimed) {
      checkWidget = const Icon(Icons.check_circle, size: 18, color: primaryGreen);
    } else if (quest.isCompleted) {
      // Completed but unclaimed: show glowing claim badge
      isClickable = true;
      checkWidget = Container(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
        decoration: BoxDecoration(
          color: const Color(0xFFE8F5E9),
          borderRadius: BorderRadius.circular(6),
          border: Border.all(color: primaryGreen, width: 1),
        ),
        child: const Text(
          'กดรับ',
          style: TextStyle(fontSize: 8, fontWeight: FontWeight.bold, color: primaryGreen),
        ),
      );
    } else {
      // Not completed
      checkWidget = Icon(Icons.check_box_outline_blank_rounded, size: 18, color: Colors.grey.shade400);
    }

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6.0),
      child: GestureDetector(
        onTap: isClickable ? () => _claimQuestReward(context, ref, quest) : null,
        child: Row(
          children: [
            checkWidget,
            const SizedBox(width: 6),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    quest.title,
                    style: TextStyle(
                      fontSize: 11,
                      fontWeight: quest.isCompleted && !quest.isClaimed ? FontWeight.bold : FontWeight.normal,
                      decoration: quest.isClaimed ? TextDecoration.lineThrough : null,
                      color: quest.isClaimed ? Colors.grey.shade400 : Colors.black87,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
              ),
            ),
            const SizedBox(width: 4),
            Text(
              '+${quest.rewardPassXp} XP',
              style: TextStyle(
                fontSize: 9,
                fontWeight: FontWeight.bold,
                color: quest.isClaimed ? Colors.grey.shade400 : primaryGreen,
              ),
            ),
          ],
        ),
      ),
    );
  }

  // Weekly quest item UI with progress indicators
  Widget _buildWeeklyQuestItem(BuildContext context, WidgetRef ref, Quest quest) {
    const Color primaryGreen = Color(0xFF2E7D32);
    
    Widget statusWidget;
    bool isClickable = false;

    if (quest.isClaimed) {
      statusWidget = const Icon(Icons.check_circle, size: 16, color: primaryGreen);
    } else if (quest.isCompleted) {
      isClickable = true;
      statusWidget = Container(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
        decoration: BoxDecoration(
          color: const Color(0xFFE8F5E9),
          borderRadius: BorderRadius.circular(6),
          border: Border.all(color: primaryGreen, width: 1),
        ),
        child: const Text(
          'กดรับ',
          style: TextStyle(fontSize: 8, fontWeight: FontWeight.bold, color: primaryGreen),
        ),
      );
    } else {
      statusWidget = Text(
        '${quest.currentValue}/${quest.targetValue}',
        style: TextStyle(
          fontSize: 9,
          fontWeight: FontWeight.bold,
          color: Colors.grey.shade600,
        ),
      );
    }

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6.0),
      child: GestureDetector(
        onTap: isClickable ? () => _claimQuestReward(context, ref, quest) : null,
        child: Row(
          children: [
            Icon(Icons.assignment_turned_in_outlined, size: 14, color: quest.isClaimed ? Colors.grey.shade400 : Colors.grey.shade600),
            const SizedBox(width: 6),
            Expanded(
              child: Text(
                quest.title,
                style: TextStyle(
                  fontSize: 11,
                  fontWeight: quest.isCompleted && !quest.isClaimed ? FontWeight.bold : FontWeight.normal,
                  decoration: quest.isClaimed ? TextDecoration.lineThrough : null,
                  color: quest.isClaimed ? Colors.grey.shade400 : Colors.black87,
                ),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            ),
            const SizedBox(width: 4),
            statusWidget,
            const SizedBox(width: 4),
            Text(
              '+${quest.rewardPassXp} XP',
              style: TextStyle(
                fontSize: 9,
                fontWeight: FontWeight.bold,
                color: quest.isClaimed ? Colors.grey.shade400 : primaryGreen,
              ),
            ),
          ],
        ),
      ),
    );
  }

  // Trigger claim quest reward api call
  void _claimQuestReward(BuildContext context, WidgetRef ref, Quest quest) async {
    try {
      // Show simple loading feedback
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('กำลังดำเนินการรับรางวัล: ${quest.title}...'), duration: const Duration(seconds: 1)),
      );

      final actions = ref.read(greenPassActionsProvider);
      await actions.claimQuestReward(quest.id);

      // Play beautiful custom success leaf particle animation
      if (context.mounted) {
        RedeemSuccessDialog.show(
          context: context,
          title: 'รับรางวัลภารกิจสำเร็จ! 🎉',
          message: 'คุณได้รับ +${quest.rewardPassXp} Pass XP\nและ +${quest.rewardPoints} GreenPoints 🍃 เข้าบัญชีเรียบร้อยแล้ว!',
        );
      }
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('ไม่สามารถรับรางวัลได้: $e'), backgroundColor: Colors.red),
        );
      }
    }
  }

  // Shimmer skeleton loading effect
  Widget _buildShimmerLoading() {
    return Container(
      width: double.infinity,
      height: 180,
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: Colors.grey.shade100,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: Colors.grey.shade200, width: 1.5),
      ),
      child: const Center(
        child: CircularProgressIndicator(color: Color(0xFF2E7D32)),
      ),
    );
  }

  Widget _buildErrorCard(String errorMsg) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: Colors.red.shade50,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: Colors.red.shade100, width: 1.5),
      ),
      child: Center(
        child: Text(
          errorMsg,
          style: TextStyle(color: Colors.red.shade800, fontSize: 12, fontWeight: FontWeight.bold),
        ),
      ),
    );
  }
}
