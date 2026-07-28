import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:greenpoint/core/providers/greenpass_provider.dart';
import 'package:greenpoint/core/models/quest_model.dart';
import 'package:greenpoint/core/models/pass_model.dart';
import 'widgets/redeem_success_dialog.dart';

class AllQuestsScreen extends ConsumerStatefulWidget {
  const AllQuestsScreen({super.key});

  @override
  ConsumerState<AllQuestsScreen> createState() => _AllQuestsScreenState();
}

class _AllQuestsScreenState extends ConsumerState<AllQuestsScreen> {
  String _selectedTab = 'ทั้งหมด'; // 'วันนี้' | 'สัปดาห์นี้' | 'ทั้งหมด'

  @override
  Widget build(BuildContext context) {
    final questsAsync = ref.watch(questsProvider);
    final passProgressAsync = ref.watch(passProgressProvider);

    const Color primaryGreen = Color(0xFF2E7D32);
    const Color secondaryGreen = Color(0xFF4CAF50);
    const Color backgroundWhite = Color(0xFFF9FBF9);

    return Scaffold(
      backgroundColor: backgroundWhite,
      appBar: AppBar(
        title: const Text(
          'ภารกิจทั้งหมด',
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
              // Calculate values
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

              return Column(
                children: [
                  // 1. Tab Pill Bar at top
                  Container(
                    color: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 12),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        _buildTabPill('วันนี้'),
                        const SizedBox(width: 12),
                        _buildTabPill('สัปดาห์นี้'),
                        const SizedBox(width: 12),
                        _buildTabPill('ทั้งหมด'),
                      ],
                    ),
                  ),

                  Expanded(
                    child: ListView(
                      padding: const EdgeInsets.all(20),
                      physics: const BouncingScrollPhysics(),
                      children: [
                        // 2. Progress Card (ทำสำเร็จ 3/10 ภารกิจ, 300/500 XP)
                        Container(
                          padding: const EdgeInsets.all(16),
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(20),
                            border: Border.all(color: Colors.grey.shade100, width: 1.5),
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                children: [
                                  Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      const Text(
                                        'ทำสำเร็จ',
                                        style: TextStyle(fontSize: 10, color: Colors.grey, fontWeight: FontWeight.bold),
                                      ),
                                      const SizedBox(height: 2),
                                      RichText(
                                        text: TextSpan(
                                          style: const TextStyle(fontSize: 15, color: Colors.black),
                                          children: [
                                            TextSpan(
                                              text: '$completedCount / $totalCount ',
                                              style: const TextStyle(fontWeight: FontWeight.w900, color: primaryGreen),
                                            ),
                                            const TextSpan(
                                              text: 'ภารกิจ',
                                              style: TextStyle(fontWeight: FontWeight.bold, color: Colors.black54),
                                            ),
                                          ],
                                        ),
                                      ),
                                    ],
                                  ),
                                  Text(
                                    '$currentXp / $nextTierXp XP',
                                    style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w900, color: primaryGreen),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 10),
                              ClipRRect(
                                borderRadius: BorderRadius.circular(10),
                                child: LinearProgressIndicator(
                                  value: xpPercent,
                                  minHeight: 6,
                                  backgroundColor: Colors.grey.shade100,
                                  valueColor: const AlwaysStoppedAnimation<Color>(secondaryGreen),
                                ),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(height: 24),

                        // 3. Conditional Quests Lists based on selected Tab
                        if (_selectedTab == 'วันนี้' || _selectedTab == 'ทั้งหมด') ...[
                          _buildSectionHeader('ภารกิจรายวัน', Icons.calendar_today_rounded),
                          const SizedBox(height: 10),
                          ...quests
                              .where((q) => q.recurrence == 'daily' && q.questType != 'eco_quiz' && !q.questType.startsWith('buy') && !q.questType.startsWith('scan_5') && !q.questType.startsWith('redeem_3'))
                              .map((q) => _buildQuestRow(q, Icons.calendar_month_rounded, primaryGreen)),
                          // Responses to Quiz
                          ...quests
                              .where((q) => q.questType == 'eco_quiz')
                              .map((q) => _buildQuestRow(q, Icons.help_outline_rounded, primaryGreen)),
                          const SizedBox(height: 20),
                        ],

                        if (_selectedTab == 'สัปดาห์นี้' || _selectedTab == 'ทั้งหมด') ...[
                          _buildSectionHeader('ภารกิจรายสัปดาห์', Icons.date_range_rounded),
                          const SizedBox(height: 10),
                          ...quests
                              .where((q) => q.recurrence == 'weekly' && q.questType != 'buy_100' && q.questType != 'scan_5' && q.questType != 'redeem_3')
                              .map((q) => _buildQuestRow(q, Icons.assignment_rounded, primaryGreen)),
                          const SizedBox(height: 20),
                        ],

                        if (_selectedTab == 'ทั้งหมด') ...[
                          _buildSectionHeader('ภารกิจพิเศษ', Icons.stars_rounded),
                          const SizedBox(height: 10),
                          ...quests
                              .where((q) => q.questType == 'buy_100' || q.questType == 'scan_5' || q.questType == 'redeem_3')
                              .map((q) => _buildSpecialQuestRow(q)),
                          const SizedBox(height: 20),
                        ],

                        // 4. Bottom Reset Notice
                        _buildResetNoticeBanner(),
                        const SizedBox(height: 20),
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
      ),
    );
  }

  Widget _buildTabPill(String label) {
    final isSelected = _selectedTab == label;
    const Color primaryGreen = Color(0xFF2E7D32);

    return GestureDetector(
      onTap: () => setState(() => _selectedTab = label),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 22, vertical: 8),
        decoration: BoxDecoration(
          color: isSelected ? primaryGreen : const Color(0xFFF0F0F0),
          borderRadius: BorderRadius.circular(20),
        ),
        child: Text(
          label,
          style: TextStyle(
            color: isSelected ? Colors.white : Colors.grey.shade600,
            fontSize: 12,
            fontWeight: FontWeight.bold,
          ),
        ),
      ),
    );
  }

  Widget _buildSectionHeader(String title, IconData icon) {
    return Row(
      children: [
        Icon(icon, size: 16, color: const Color(0xFF333333)),
        const SizedBox(width: 6),
        Text(
          title,
          style: const TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.w900,
            color: Color(0xFF333333),
          ),
        ),
      ],
    );
  }

  // Row Item for general Quests
  Widget _buildQuestRow(Quest quest, IconData leadingIcon, Color themeColor) {
    final isCompletedAndUnclaimed = quest.isCompleted && !quest.isClaimed;
    const Color primaryGreen = Color(0xFF2E7D32);

    return GestureDetector(
      onTap: isCompletedAndUnclaimed ? () => _claimQuestReward(quest) : null,
      child: Container(
        margin: const EdgeInsets.symmetric(vertical: 6),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
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
            // Icon Left
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: quest.isClaimed ? Colors.grey.shade100 : const Color(0xFFE8F5E9),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(
                leadingIcon, 
                color: quest.isClaimed ? Colors.grey.shade400 : themeColor, 
                size: 20,
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
                      fontWeight: FontWeight.w900,
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
                ],
              ),
            ),
            const SizedBox(width: 8),

            // Reward text & Claim action
            if (quest.isClaimed) ...[
              Icon(Icons.check_circle_rounded, color: themeColor, size: 20)
            ] else if (isCompletedAndUnclaimed) ...[
              ElevatedButton(
                onPressed: () => _claimQuestReward(quest),
                style: ElevatedButton.styleFrom(
                  backgroundColor: primaryGreen,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 10),
                  minimumSize: Size.zero,
                  tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                ),
                child: const Text('กดรับ', style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold)),
              )
            ] else ...[
              // In progress progress details
              Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  if (quest.recurrence == 'weekly') ...[
                    Text(
                      '${quest.currentValue}/${quest.targetValue} ',
                      style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: Colors.grey.shade600),
                    ),
                  ],
                  Text(
                    '+${quest.rewardPassXp} XP',
                    style: TextStyle(fontSize: 11, fontWeight: FontWeight.w900, color: themeColor),
                  ),
                ],
              ),
              const SizedBox(width: 4),
              const Icon(Icons.arrow_forward_ios_rounded, size: 10, color: Colors.grey),
            ],
          ],
        ),
      ),
    );
  }

  // Row item for mock/special locked quests
  Widget _buildSpecialQuestRow(Quest quest) {
    final isCompletedAndUnclaimed = quest.isCompleted && !quest.isClaimed;
    final isLocked = !quest.isCompleted && !quest.isClaimed;
    const Color primaryGreen = Color(0xFF2E7D32);

    return GestureDetector(
      onTap: isCompletedAndUnclaimed ? () => _claimQuestReward(quest) : null,
      child: Container(
        margin: const EdgeInsets.symmetric(vertical: 6),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        decoration: BoxDecoration(
          color: isLocked ? const Color(0xFFFDFBF7) : Colors.white, 
          borderRadius: BorderRadius.circular(18),
          border: Border.all(
            color: isLocked ? const Color(0xFFF7ECDF) : (isCompletedAndUnclaimed ? Colors.orange.withOpacity(0.3) : Colors.grey.shade100), 
            width: 1.5,
          ),
        ),
        child: Row(
        children: [
          // Icon Left
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: isLocked ? const Color(0xFFF9EFE5) : const Color(0xFFE8F5E9),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(
              isLocked ? Icons.lock_outline_rounded : Icons.lock_open_rounded, 
              color: isLocked ? Colors.grey.shade500 : const Color(0xFF2E7D32), 
              size: 20,
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
                    fontWeight: FontWeight.w900,
                    color: quest.isClaimed ? Colors.grey.shade400 : (isLocked ? Colors.grey.shade600 : const Color(0xFF333333)),
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  quest.description,
                  style: TextStyle(
                    fontSize: 10,
                    color: Colors.grey.shade500,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 8),

          // Action Status
          if (quest.isClaimed) ...[
            const Icon(Icons.check_circle_rounded, color: Color(0xFF2E7D32), size: 20)
          ] else if (isCompletedAndUnclaimed) ...[
            ElevatedButton(
              onPressed: () => _claimQuestReward(quest),
              style: ElevatedButton.styleFrom(
                backgroundColor: primaryGreen,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 10),
                minimumSize: Size.zero,
                tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
              ),
              child: const Text('กดรับ', style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold)),
            )
          ] else ...[
            Text(
              '+${quest.rewardPassXp} XP',
              style: TextStyle(
                fontSize: 11,
                fontWeight: FontWeight.w900,
                color: isLocked ? Colors.grey.shade500 : const Color(0xFF2E7D32),
              ),
            ),
            const SizedBox(width: 8),
            Icon(Icons.lock_rounded, size: 14, color: Colors.grey.shade300),
          ],
        ],
      ),
    ),);
  }

  Widget _buildResetNoticeBanner() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(vertical: 12),
      decoration: BoxDecoration(
        color: const Color(0xFFE8F5E9),
        borderRadius: BorderRadius.circular(14),
      ),
      child: const Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.check_circle_rounded, color: Color(0xFF2E7D32), size: 14),
          SizedBox(width: 6),
          Text(
            'ภารกิจจะรีเซ็ตใหม่ในวันที่ 1 ของเดือน',
            style: TextStyle(
              color: Color(0xFF2E7D32),
              fontSize: 11,
              fontWeight: FontWeight.bold,
            ),
          ),
        ],
      ),
    );
  }

  void _claimQuestReward(Quest quest) async {
    try {
      final actions = ref.read(greenPassActionsProvider);
      await actions.claimQuestReward(quest.id);

      if (mounted) {
        RedeemSuccessDialog.show(
          context: context,
          title: 'รับรางวัลภารกิจสำเร็จ! 🎯',
          message: 'คุณได้รับ +${quest.rewardPassXp} Pass XP\nและ +${quest.rewardPoints} GP เข้าบัญชีเรียบร้อยแล้ว!',
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('เกิดข้อผิดพลาด: $e'), backgroundColor: Colors.red),
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
