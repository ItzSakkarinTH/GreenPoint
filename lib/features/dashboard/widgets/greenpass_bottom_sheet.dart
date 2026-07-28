import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:greenpoint/core/providers/greenpass_provider.dart';
import 'package:greenpoint/core/models/pass_model.dart';
import 'package:greenpoint/core/models/quest_model.dart';
import 'redeem_success_dialog.dart';

class GreenPassBottomSheet extends ConsumerWidget {
  const GreenPassBottomSheet({super.key});

  static void show(BuildContext context) {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.only(
          topLeft: Radius.circular(28),
          topRight: Radius.circular(28),
        ),
      ),
      isScrollControlled: true,
      backgroundColor: Colors.white,
      builder: (context) => const GreenPassBottomSheet(),
    );
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final questsAsync = ref.watch(questsProvider);
    final passProgressAsync = ref.watch(passProgressProvider);

    const Color primaryGreen = Color(0xFF2E7D32);
    const Color secondaryGreen = Color(0xFF4CAF50);

    return DraggableScrollableSheet(
      initialChildSize: 0.85,
      maxChildSize: 0.95,
      minChildSize: 0.5,
      expand: false,
      builder: (context, scrollController) {
        return questsAsync.when(
          data: (quests) {
            return passProgressAsync.when(
              data: (progress) {
                return Column(
                  children: [
                    // Sheet Handle Indicator
                    const SizedBox(height: 12),
                    Container(
                      width: 44,
                      height: 5,
                      decoration: BoxDecoration(
                        color: Colors.grey.shade300,
                        borderRadius: BorderRadius.circular(10),
                      ),
                    ),
                    const SizedBox(height: 16),
                    
                    // Title Header
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const SizedBox(width: 56), // spacer to center title
                        const Text(
                          'Green Pass & ภารกิจทั้งหมด',
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.w900,
                            color: Color(0xFF2E7D32),
                          ),
                        ),
                        IconButton(
                          icon: const Icon(Icons.close_rounded, color: Colors.grey),
                          onPressed: () => Navigator.pop(context),
                        ),
                      ],
                    ),
                    const Divider(height: 1),
                    
                    // Main Scrollable Area
                    Expanded(
                      child: ListView(
                        controller: scrollController,
                        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
                        children: [
                          // 1. Current Pass Stats Card
                          _buildStatsCard(progress),
                          const SizedBox(height: 24),

                          // 2. Pass Tiers Horizontal Carousel
                          const Text(
                            'ของรางวัลระดับขั้น (Green Pass Tiers)',
                            style: TextStyle(
                              fontSize: 14,
                              fontWeight: FontWeight.bold,
                              color: Color(0xFF333333),
                            ),
                          ),
                          const SizedBox(height: 12),
                          SizedBox(
                            height: 145,
                            child: ListView.builder(
                              scrollDirection: Axis.horizontal,
                              physics: const BouncingScrollPhysics(),
                              itemCount: progress.tiers.length,
                              itemBuilder: (context, index) {
                                final tier = progress.tiers[index];
                                final isUnlocked = progress.passXp >= tier.requiredXp;
                                final isClaimed = progress.claimedTiers.contains(tier.tier);
                                
                                return _buildTierCard(context, ref, tier, isUnlocked, isClaimed, progress.passXp);
                              },
                            ),
                          ),
                          const SizedBox(height: 28),

                          // 3. Quests Detailed List
                          const Text(
                            'รายละเอียดภารกิจทั้งหมด',
                            style: TextStyle(
                              fontSize: 14,
                              fontWeight: FontWeight.bold,
                              color: Color(0xFF333333),
                            ),
                          ),
                          const SizedBox(height: 12),
                          
                          // Daily Header
                          _buildSectionHeader('ภารกิจรายวัน (Daily Quests)', Icons.today_rounded),
                          const SizedBox(height: 8),
                          ...quests.where((q) => q.recurrence == 'daily').map(
                            (q) => _buildDetailedQuestRow(context, ref, q),
                          ),
                          const SizedBox(height: 20),

                          // Weekly Header
                          _buildSectionHeader('ภารกิจรายสัปดาห์ (Weekly Quests)', Icons.date_range_rounded),
                          const SizedBox(height: 8),
                          ...quests.where((q) => q.recurrence == 'weekly').map(
                            (q) => _buildDetailedQuestRow(context, ref, q),
                          ),
                          const SizedBox(height: 24),
                        ],
                      ),
                    ),
                  ],
                );
              },
              loading: () => _buildLoadingCenter(),
              error: (err, _) => _buildErrorCenter('เกิดข้อผิดพลาด: $err'),
            );
          },
          loading: () => _buildLoadingCenter(),
          error: (err, _) => _buildErrorCenter('เกิดข้อผิดพลาด: $err'),
        );
      },
    );
  }

  // Quick stats card showing current XP and status
  Widget _buildStatsCard(UserPassProgress progress) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [Color(0xFF2E7D32), Color(0xFF4CAF50)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF2E7D32).withOpacity(0.2),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.2),
              shape: BoxShape.circle,
            ),
            child: const Icon(Icons.stars_rounded, color: Colors.white, size: 28),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'ระดับผู้ใช้ Green Pass',
                  style: TextStyle(color: Colors.white70, fontSize: 11, fontWeight: FontWeight.bold),
                ),
                Text(
                  'ผ่านเกณฑ์มาแล้ว ${progress.currentTier} ระดับขั้น',
                  style: const TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.w900),
                ),
                const SizedBox(height: 4),
                Text(
                  'สะสมทั้งหมด: ${progress.passXp} Pass XP 🍃',
                  style: const TextStyle(color: Colors.white90, fontSize: 12, fontWeight: FontWeight.w500),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // Pass Tier card displayed in horizontal list
  Widget _buildTierCard(BuildContext context, WidgetRef ref, PassTier tier, bool isUnlocked, bool isClaimed, int userXp) {
    const Color primaryGreen = Color(0xFF2E7D32);
    
    // Status colors and contents
    Color cardBg = Colors.white;
    Color borderCol = Colors.grey.shade200;
    Widget actionWidget;

    if (isClaimed) {
      cardBg = const Color(0xFFF9FBF9);
      borderCol = const Color(0xFFC8E6C9);
      actionWidget = Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
        decoration: BoxDecoration(
          color: Colors.grey.shade200,
          borderRadius: BorderRadius.circular(10),
        ),
        child: Text(
          'รับแล้ว',
          style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: Colors.grey.shade500),
        ),
      );
    } else if (isUnlocked) {
      // Unlocked but unclaimed
      cardBg = const Color(0xFFF1FDF5);
      borderCol = primaryGreen.withOpacity(0.3);
      actionWidget = ElevatedButton(
        onPressed: () => _claimTierReward(context, ref, tier),
        style: ElevatedButton.styleFrom(
          backgroundColor: primaryGreen,
          foregroundColor: Colors.white,
          elevation: 2,
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
          minimumSize: Size.zero,
          tapTargetSize: MaterialTapTargetSize.shrinkWrap,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
        ),
        child: const Text('รับรางวัล', style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold)),
      );
    } else {
      // Locked
      actionWidget = Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(Icons.lock_outline_rounded, size: 10, color: Colors.grey.shade400),
          const SizedBox(width: 4),
          Text(
            'ต้องการ ${tier.requiredXp} XP',
            style: TextStyle(fontSize: 9, fontWeight: FontWeight.bold, color: Colors.grey.shade500),
          ),
        ],
      );
    }

    return Container(
      width: 140,
      margin: const EdgeInsets.only(right: 12, bottom: 4),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: cardBg,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: borderCol, width: 1.5),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.01),
            blurRadius: 6,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                decoration: BoxDecoration(
                  color: isUnlocked ? const Color(0xFFE8F5E9) : Colors.grey.shade100,
                  borderRadius: BorderRadius.circular(6),
                ),
                child: Text(
                  'ระดับ ${tier.tier}',
                  style: TextStyle(
                    fontSize: 9, 
                    fontWeight: FontWeight.bold, 
                    color: isUnlocked ? primaryGreen : Colors.grey.shade600,
                  ),
                ),
              ),
              if (isUnlocked)
                const Icon(Icons.circle_notifications_rounded, color: primaryGreen, size: 16)
              else
                Icon(Icons.lock_rounded, color: Colors.grey.shade300, size: 12),
            ],
          ),
          
          Expanded(
            child: Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(
                    tier.rewardTitle,
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w900,
                      color: isClaimed ? Colors.grey.shade500 : const Color(0xFF333333),
                    ),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
              ),
            ),
          ),

          Center(child: actionWidget),
        ],
      ),
    );
  }

  // Row showing quest details, progress metrics, and action buttons
  Widget _buildDetailedQuestRow(BuildContext context, WidgetRef ref, Quest quest) {
    const Color primaryGreen = Color(0xFF2E7D32);
    
    Widget statusAction;
    bool isCompletedAndUnclaimed = quest.isCompleted && !quest.isClaimed;

    if (quest.isClaimed) {
      statusAction = Container(
        padding: const EdgeInsets.all(4),
        decoration: BoxDecoration(
          color: Colors.grey.shade100,
          shape: BoxShape.circle,
        ),
        child: Icon(Icons.check, size: 14, color: Colors.grey.shade400),
      );
    } else if (isCompletedAndUnclaimed) {
      statusAction = ElevatedButton(
        onPressed: () => _claimQuestReward(context, ref, quest),
        style: ElevatedButton.styleFrom(
          backgroundColor: Colors.orange,
          foregroundColor: Colors.white,
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
          minimumSize: Size.zero,
          tapTargetSize: MaterialTapTargetSize.shrinkWrap,
          elevation: 2,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
        ),
        child: const Text('กดรับ', style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold)),
      );
    } else {
      // Progress indicator e.g. 0/3
      statusAction = Text(
        '${quest.currentValue}/${quest.targetValue}',
        style: TextStyle(
          fontSize: 10,
          fontWeight: FontWeight.bold,
          color: Colors.grey.shade600,
        ),
      );
    }

    return Container(
      margin: const EdgeInsets.symmetric(vertical: 6),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: quest.isClaimed ? const Color(0xFFFCFCFC) : Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: isCompletedAndUnclaimed ? Colors.orange.withOpacity(0.3) : Colors.grey.shade100, 
          width: 1.5,
        ),
      ),
      child: Row(
        children: [
          // Icon Left
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: quest.isClaimed ? Colors.grey.shade100 : const Color(0xFFE8F5E9),
              shape: BoxShape.circle,
            ),
            child: Icon(
              quest.recurrence == 'daily' ? Icons.today_rounded : Icons.date_range_rounded, 
              color: quest.isClaimed ? Colors.grey.shade400 : primaryGreen, 
              size: 16,
            ),
          ),
          const SizedBox(width: 12),
          
          // Quest details
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  quest.title,
                  style: TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.bold,
                    decoration: quest.isClaimed ? TextDecoration.lineThrough : null,
                    color: quest.isClaimed ? Colors.grey.shade400 : const Color(0xFF333333),
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  quest.description,
                  style: TextStyle(
                    fontSize: 10,
                    color: quest.isClaimed ? Colors.grey.shade400 : Colors.grey.shade500,
                  ),
                ),
                const SizedBox(height: 4),
                // Reward badges
                Row(
                  children: [
                    _buildRewardBadge('+${quest.rewardPassXp} Pass XP', const Color(0xFFE8F5E9), primaryGreen, quest.isClaimed),
                    if (quest.rewardPoints > 0) ...[
                      const SizedBox(width: 6),
                      _buildRewardBadge('+${quest.rewardPoints} GP', Colors.orange.shade50, Colors.orange.shade800, quest.isClaimed),
                    ],
                  ],
                ),
              ],
            ),
          ),
          const SizedBox(width: 12),

          // Action Status right
          statusAction,
        ],
      ),
    );
  }

  Widget _buildRewardBadge(String label, Color bg, Color textCol, bool isGreyed) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
      decoration: BoxDecoration(
        color: isGreyed ? Colors.grey.shade100 : bg,
        borderRadius: BorderRadius.circular(6),
      ),
      child: Text(
        label,
        style: TextStyle(fontSize: 8, fontWeight: FontWeight.bold, color: isGreyed ? Colors.grey.shade400 : textCol),
      ),
    );
  }

  Widget _buildSectionHeader(String label, IconData icon) {
    return Row(
      children: [
        Icon(icon, size: 14, color: Colors.grey.shade600),
        const SizedBox(width: 6),
        Text(
          label,
          style: TextStyle(
            fontSize: 11,
            fontWeight: FontWeight.bold,
            color: Colors.grey.shade600,
          ),
        ),
      ],
    );
  }

  // Trigger claim quest reward
  void _claimQuestReward(BuildContext context, WidgetRef ref, Quest quest) async {
    try {
      final actions = ref.read(greenPassActionsProvider);
      await actions.claimQuestReward(quest.id);

      // Play custom success leaf burst animation
      if (context.mounted) {
        RedeemSuccessDialog.show(
          context: context,
          title: 'รับรางวัลสำเร็จ! 🎯',
          message: 'คุณได้รับ +${quest.rewardPassXp} Pass XP\nและ +${quest.rewardPoints} GP เข้าบัญชีเรียบร้อยแล้ว!',
        );
      }
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('เกิดข้อผิดพลาด: $e'), backgroundColor: Colors.red),
        );
      }
    }
  }

  // Trigger claim tier reward
  void _claimTierReward(BuildContext context, WidgetRef ref, PassTier tier) async {
    try {
      final actions = ref.read(greenPassActionsProvider);
      await actions.claimPassTierReward(tier.tier);

      // Play custom success leaf burst animation
      if (context.mounted) {
        RedeemSuccessDialog.show(
          context: context,
          title: 'รับรางวัลระดับขั้นสำเร็จ! 🎁',
          message: 'คุณได้ปลดล็อกของรางวัลระดับขั้น ${tier.tier}:\n"${tier.rewardTitle}" สำเร็จเรียบร้อยแล้ว!',
        );
      }
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('ไม่สามารถรับของรางวัลได้: $e'), backgroundColor: Colors.red),
        );
      }
    }
  }

  Widget _buildLoadingCenter() {
    return const SizedBox(
      height: 250,
      child: Center(
        child: CircularProgressIndicator(color: Color(0xFF2E7D32)),
      ),
    );
  }

  Widget _buildErrorCenter(String error) {
    return SizedBox(
      height: 250,
      child: Center(
        child: Padding(
          padding: const EdgeInsets.all(24.0),
          child: Text(error, style: const TextStyle(color: Colors.red, fontWeight: FontWeight.bold)),
        ),
      ),
    );
  }
}
