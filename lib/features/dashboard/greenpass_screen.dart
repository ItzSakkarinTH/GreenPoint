import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:greenpoint/core/providers/greenpass_provider.dart';
import 'package:greenpoint/core/models/quest_model.dart';
import 'package:greenpoint/core/models/pass_model.dart';
import 'all_quests_screen.dart';
import 'widgets/redeem_success_dialog.dart';

class GreenPassScreen extends ConsumerWidget {
  const GreenPassScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final questsAsync = ref.watch(questsProvider);
    final passProgressAsync = ref.watch(passProgressProvider);

    const Color primaryGreen = Color(0xFF2E7D32);
    const Color secondaryGreen = Color(0xFF4CAF50);
    const Color backgroundWhite = Color(0xFFF9FBF9);

    return Scaffold(
      backgroundColor: backgroundWhite,
      appBar: AppBar(
        title: const Text(
          'Green Pass',
          style: TextStyle(color: Color(0xFF333333), fontWeight: FontWeight.w900, fontSize: 18),
        ),
        backgroundColor: Colors.white,
        elevation: 0.5,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new_rounded, color: Colors.grey, size: 20),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: questsAsync.when(
        data: (quests) {
          return passProgressAsync.when(
            data: (progress) {
              // Calculate days remaining in the month
              final now = DateTime.now();
              final lastDay = DateTime(now.year, now.month + 1, 0);
              final daysRemaining = lastDay.difference(now).inDays;

              final completedCount = quests.where((q) => q.isCompleted).length;
              final totalCount = quests.length;
              final currentXp = progress.passXp;

              // Find next tier XP requirement
              int nextTierXp = 500; // default max
              for (var tier in progress.tiers) {
                if (tier.requiredXp > currentXp) {
                  nextTierXp = tier.requiredXp;
                  break;
                }
              }
              if (progress.tiers.isNotEmpty && currentXp >= progress.tiers.last.requiredXp) {
                nextTierXp = progress.tiers.last.requiredXp;
              }

              final xpPercent = nextTierXp > 0 ? (currentXp / nextTierXp).clamp(0.0, 1.0) : 0.0;
              final dailyQuests = quests.where((q) => q.recurrence == 'daily' && q.questType != 'buy_100' && q.questType != 'scan_5' && q.questType != 'redeem_3').toList();
              final weeklyQuests = quests.where((q) => q.recurrence == 'weekly' && q.questType != 'buy_100' && q.questType != 'scan_5' && q.questType != 'redeem_3').toList();

              return ListView(
                padding: const EdgeInsets.all(20),
                physics: const BouncingScrollPhysics(),
                children: [
                  // 1. Eco Journey Pass Header Card
                  Container(
                    padding: const EdgeInsets.all(20),
                    decoration: BoxDecoration(
                      color: const Color(0xFFE2F0E6), // Soft green background
                      borderRadius: BorderRadius.circular(24),
                      border: Border.all(color: const Color(0xFFD0E6D6), width: 1),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Icon(
                              Icons.flag_rounded,
                              color: primaryGreen,
                              size: 40,
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    DateFormat('MMMM yyyy').format(DateTime.now()),
                                    style: TextStyle(
                                      fontSize: 10,
                                      fontWeight: FontWeight.bold,
                                      color: Colors.grey.shade600,
                                    ),
                                  ),
                                  const SizedBox(height: 2),
                                  const Text(
                                    'Eco Journey Pass',
                                    style: TextStyle(
                                      fontSize: 18,
                                      fontWeight: FontWeight.w900,
                                      color: primaryGreen,
                                    ),
                                  ),
                                  const SizedBox(height: 2),
                                  const Text(
                                    'ทำภารกิจ เพื่อโลกที่ดีขึ้นไปด้วยกัน',
                                    style: TextStyle(
                                      fontSize: 11,
                                      color: Color(0xFF558B2F),
                                      fontWeight: FontWeight.w500,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            // Days remaining badge
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                              decoration: BoxDecoration(
                                color: Colors.white.withOpacity(0.6),
                                borderRadius: BorderRadius.circular(10),
                              ),
                              child: Text(
                                'เหลืออีก $daysRemaining วัน',
                                style: const TextStyle(
                                  fontSize: 9,
                                  fontWeight: FontWeight.bold,
                                  color: primaryGreen,
                                ),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 20),

                        // Progress Bar & Stats
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text(
                              '$completedCount / $totalCount ภารกิจสำเร็จ',
                              style: const TextStyle(
                                fontSize: 12,
                                fontWeight: FontWeight.w900,
                                color: primaryGreen,
                              ),
                            ),
                            Text(
                              '$currentXp / $nextTierXp XP',
                              style: const TextStyle(
                                fontSize: 11,
                                fontWeight: FontWeight.w900,
                                color: primaryGreen,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 8),
                        ClipRRect(
                          borderRadius: BorderRadius.circular(8),
                          child: LinearProgressIndicator(
                            value: xpPercent,
                            minHeight: 6,
                            backgroundColor: Colors.white.withOpacity(0.4),
                            valueColor: const AlwaysStoppedAnimation<Color>(secondaryGreen),
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 24),

                  // 2. รางวัลระดับถัดไป (Next Rewards Row)
                  const Text(
                    'รางวัลระดับถัดไป',
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w900,
                      color: Color(0xFF333333),
                    ),
                  ),
                  const SizedBox(height: 12),
                  _buildNextRewardsRow(context, ref, progress),
                  const SizedBox(height: 24),

                  // 3. ภารกิจวันนี้ (Daily Missions)
                  const Text(
                    'ภารกิจวันนี้',
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w900,
                      color: Color(0xFF333333),
                    ),
                  ),
                  const SizedBox(height: 10),
                  ...dailyQuests.map((q) => _buildQuestCheckRow(context, ref, q)),
                  const SizedBox(height: 20),

                  // 4. ภารกิจสัปดาห์นี้ (Weekly Missions)
                  const Text(
                    'ภารกิจสัปดาห์นี้',
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w900,
                      color: Color(0xFF333333),
                    ),
                  ),
                  const SizedBox(height: 10),
                  ...weeklyQuests.map((q) => _buildQuestCheckRow(context, ref, q)),
                  const SizedBox(height: 20),

                  // 5. Bottom Link "ดูภารกิจทั้งหมด >"
                  Center(
                    child: TextButton(
                      onPressed: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(builder: (context) => const AllQuestsScreen()),
                        );
                      },
                      style: TextButton.styleFrom(
                        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
                      ),
                      child: const Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Text(
                            'ดูภารกิจทั้งหมด',
                            style: TextStyle(
                              color: primaryGreen,
                              fontSize: 12,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          SizedBox(width: 4),
                          Icon(Icons.arrow_forward_ios_rounded, size: 12, color: primaryGreen),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 20),
                ],
              );
            },
            loading: () => _buildLoadingCenter(),
            error: (err, _) => _buildErrorCenter('เกิดข้อผิดพลาด: $err'),
          );
        },
        loading: () => _buildLoadingCenter(),
        error: (err, _) => _buildErrorCenter('เกิดข้อผิดพลาด: $err'),
      ),
    );
  }

  // Next Rewards display row
  Widget _buildNextRewardsRow(BuildContext context, WidgetRef ref, UserPassProgress progress) {
    const Color primaryGreen = Color(0xFF2E7D32);
    
    // Find next tiers
    final nextTiers = progress.tiers.where((t) => t.requiredXp > progress.passXp || !progress.claimedTiers.contains(t.tier)).toList();
    if (nextTiers.isEmpty) {
      return Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: Colors.grey.shade50,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: Colors.grey.shade200),
        ),
        child: const Center(
          child: Text('คุณได้รับของรางวัลระดับขั้นทั้งหมดแล้ว! 🎉', style: TextStyle(fontSize: 12, color: Colors.grey)),
        ),
      );
    }

    // Take next 2 tiers
    final displayTiers = nextTiers.take(2).toList();

    return Row(
      children: displayTiers.map((tier) {
        final isUnlocked = progress.passXp >= tier.requiredXp;
        final isClaimed = progress.claimedTiers.contains(tier.tier);

        return Expanded(
          child: GestureDetector(
            onTap: isUnlocked && !isClaimed ? () => _claimPassTier(context, ref, tier) : null,
            child: Container(
              margin: const EdgeInsets.symmetric(horizontal: 4),
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: isUnlocked && !isClaimed 
                    ? const Color(0xFFE8F5E9) 
                    : (isClaimed ? const Color(0xFFF9FBF9) : const Color(0xFFF0F0F0)),
                borderRadius: BorderRadius.circular(18),
                border: Border.all(
                  color: isUnlocked && !isClaimed 
                      ? primaryGreen.withOpacity(0.3) 
                      : (isClaimed ? const Color(0xFFC8E6C9) : Colors.grey.shade300),
                  width: 1.5,
                ),
              ),
              child: Row(
                children: [
                  // Icon
                  Container(
                    padding: const EdgeInsets.all(6),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      shape: BoxShape.circle,
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withOpacity(0.03),
                          blurRadius: 4,
                        ),
                      ],
                    ),
                    child: Icon(
                      isUnlocked && !isClaimed
                          ? Icons.card_giftcard_rounded
                          : (isClaimed ? Icons.check_circle_rounded : Icons.lock_rounded),
                      color: isUnlocked && !isClaimed 
                          ? Colors.orange 
                          : (isClaimed ? primaryGreen : Colors.grey.shade400),
                      size: 20,
                    ),
                  ),
                  const SizedBox(width: 8),

                  // Texts
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Level ${tier.tier}',
                          style: TextStyle(
                            fontSize: 10,
                            fontWeight: FontWeight.bold,
                            color: isClaimed ? Colors.grey.shade500 : Colors.black87,
                          ),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          isClaimed ? 'รับรางวัลแล้ว' : tier.rewardTitle,
                          style: TextStyle(
                            fontSize: 9,
                            fontWeight: FontWeight.w900,
                            color: isClaimed 
                                ? Colors.grey.shade500 
                                : (isUnlocked ? primaryGreen : Colors.grey.shade600),
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
        );
      }).toList(),
    );
  }

  // Row showing Quest check bubble, title, details, and rewards
  Widget _buildQuestCheckRow(BuildContext context, WidgetRef ref, Quest quest) {
    const Color primaryGreen = Color(0xFF2E7D32);
    final isCompletedAndUnclaimed = quest.isCompleted && !quest.isClaimed;

    Widget checkIndicator;
    bool isClickable = false;

    if (quest.isClaimed) {
      checkIndicator = const Icon(Icons.check_circle_rounded, color: primaryGreen, size: 24);
    } else if (isCompletedAndUnclaimed) {
      isClickable = true;
      checkIndicator = ElevatedButton(
        onPressed: () => _claimQuest(context, ref, quest),
        style: ElevatedButton.styleFrom(
          backgroundColor: primaryGreen,
          foregroundColor: Colors.white,
          padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 10),
          minimumSize: Size.zero,
          tapTargetSize: MaterialTapTargetSize.shrinkWrap,
          elevation: 2,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
        ),
        child: const Text('กดรับ', style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold)),
      );
    } else {
      checkIndicator = Icon(Icons.circle_outlined, color: Colors.grey.shade300, size: 24);
    }

    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTap: isClickable ? () => _claimQuest(context, ref, quest) : null,
      child: Container(
        margin: const EdgeInsets.symmetric(vertical: 6),
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(18),
          border: Border.all(
            color: isCompletedAndUnclaimed ? Colors.orange.withOpacity(0.3) : Colors.grey.shade100, 
            width: 1.5,
          ),
        ),
        child: Row(
          children: [
            // Quest Icon Left
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: quest.isClaimed ? Colors.grey.shade50 : const Color(0xFFF1FDF6),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(
                quest.questType == 'daily_login'
                    ? Icons.login_rounded
                    : (quest.questType == 'scan_points' 
                        ? Icons.qr_code_scanner_rounded 
                        : (quest.questType == 'eco_quiz' 
                            ? Icons.help_outline_rounded 
                            : Icons.assignment_rounded)),
                color: quest.isClaimed ? Colors.grey.shade400 : primaryGreen,
                size: 20,
              ),
            ),
            const SizedBox(width: 12),

            // Quest info
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    quest.title,
                    style: TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w900,
                      decoration: quest.isClaimed ? TextDecoration.lineThrough : null,
                      color: quest.isClaimed ? Colors.grey.shade400 : const Color(0xFF333333),
                    ),
                  ),
                  const SizedBox(height: 2),
                  Row(
                    children: [
                      if (quest.recurrence == 'weekly' && !quest.isCompleted) ...[
                        Text(
                          '${quest.currentValue}/${quest.targetValue}  •  ',
                          style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: Colors.grey.shade500),
                        ),
                      ],
                      Text(
                        '+${quest.rewardPassXp} XP',
                        style: TextStyle(
                          fontSize: 10,
                          fontWeight: FontWeight.w900,
                          color: quest.isClaimed ? Colors.grey.shade400 : primaryGreen,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            const SizedBox(width: 8),

            // Check Indicator Right
            checkIndicator,
          ],
        ),
      ),
    );
  }

  void _claimQuest(BuildContext context, WidgetRef ref, Quest quest) async {
    try {
      final actions = ref.read(greenPassActionsProvider);
      await actions.claimQuestReward(quest.id);

      if (context.mounted) {
        RedeemSuccessDialog.show(
          context: context,
          title: 'รับรางวัลภารกิจสำเร็จ! 🎯',
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

  void _claimPassTier(BuildContext context, WidgetRef ref, PassTier tier) async {
    try {
      final actions = ref.read(greenPassActionsProvider);
      await actions.claimPassTierReward(tier.tier);

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
    return const Center(
      child: CircularProgressIndicator(color: Color(0xFF2E7D32)),
    );
  }

  Widget _buildErrorCenter(String err) {
    return Center(
      child: Text(err, style: const TextStyle(color: Colors.red, fontWeight: FontWeight.bold)),
    );
  }
}
