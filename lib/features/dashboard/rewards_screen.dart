import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/providers/reward_provider.dart';
import '../../core/providers/user_provider.dart';
import '../../core/providers/shop_provider.dart';
import '../../core/models/reward_model.dart';
import '../../core/models/shop_model.dart';
import '../../core/utils/dialog_utils.dart';
import 'widgets/redeem_success_dialog.dart';

const Color primaryGreen = Color(0xFF2E7D32);
const Color secondaryGreen = Color(0xFF4CAF50);
const Color backgroundWhite = Color(0xFFFAFAFA);

class RewardsScreen extends ConsumerStatefulWidget {
  const RewardsScreen({super.key});

  @override
  ConsumerState<RewardsScreen> createState() => _RewardsScreenState();
}

class _RewardsScreenState extends ConsumerState<RewardsScreen> {
  bool _isRedeeming = false;

  @override
  Widget build(BuildContext context) {
    final shopsAsync = ref.watch(shopsProvider);

    return Stack(
      children: [
        Scaffold(
          backgroundColor: backgroundWhite,
          appBar: AppBar(
            backgroundColor: Colors.white,
            elevation: 0,
            leading: IconButton(
              icon: const Icon(Icons.arrow_back_ios_new_rounded, color: primaryGreen, size: 22),
              onPressed: () => Navigator.pop(context),
            ),
            title: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(4),
                  decoration: const BoxDecoration(
                    color: primaryGreen,
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(Icons.eco, color: Colors.white, size: 18),
                ),
                const SizedBox(width: 8),
                const Text(
                  'GreenPoint',
                  style: TextStyle(
                    color: primaryGreen,
                    fontWeight: FontWeight.w900,
                    fontSize: 20,
                  ),
                ),
              ],
            ),
            actions: [
              TextButton.icon(
                onPressed: () => _showRedemptionHistorySheet(context),
                icon: const Icon(Icons.history_rounded, color: primaryGreen, size: 20),
                label: const Text(
                  'ประวัติการแลก',
                  style: TextStyle(
                    color: primaryGreen,
                    fontWeight: FontWeight.bold,
                    fontSize: 13,
                  ),
                ),
              ),
              const SizedBox(width: 8),
            ],
          ),
          body: SingleChildScrollView(
            physics: const BouncingScrollPhysics(),
            padding: const EdgeInsets.all(20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Title
                Row(
                  children: [
                    const Icon(Icons.card_giftcard_rounded, color: primaryGreen, size: 28),
                    const SizedBox(width: 8),
                    const Text(
                      'Rewards',
                      style: TextStyle(
                        fontSize: 26,
                        fontWeight: FontWeight.bold,
                        color: Color(0xFF333333),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 4),
                const Text(
                  'แลกของรางวัลด้วย GreenPoint ของคุณ',
                  style: TextStyle(
                    fontSize: 13,
                    color: Colors.grey,
                  ),
                ),
                const SizedBox(height: 24),

                // Shops List with Rewards
                shopsAsync.when(
                  data: (shops) {
                    if (shops.isEmpty) {
                      return const Center(
                        child: Padding(
                          padding: EdgeInsets.symmetric(vertical: 40),
                          child: Text('ไม่พบข้อมูลร้านค้าพาร์ทเนอร์'),
                        ),
                      );
                    }
                    return ListView.separated(
                      shrinkWrap: true,
                      physics: const NeverScrollableScrollPhysics(),
                      itemCount: shops.length,
                      separatorBuilder: (context, index) => const SizedBox(height: 24),
                      itemBuilder: (context, index) {
                        final shop = shops[index];
                        return _buildShopRewardsSection(context, shop);
                      },
                    );
                  },
                  loading: () => const Center(
                    child: Padding(
                      padding: EdgeInsets.symmetric(vertical: 40),
                      child: CircularProgressIndicator(color: primaryGreen),
                    ),
                  ),
                  error: (e, _) => Center(
                    child: Padding(
                      padding: const EdgeInsets.symmetric(vertical: 40),
                      child: Text('เกิดข้อผิดพลาดในการโหลดข้อมูล: $e'),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
        if (_isRedeeming)
          Container(
            color: Colors.black.withOpacity(0.5),
            child: const Center(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  CircularProgressIndicator(color: Colors.white),
                  SizedBox(height: 16),
                  Text(
                    'กำลังดำเนินการแลกรางวัล...',
                    style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
                  ),
                ],
              ),
            ),
          ),
      ],
    );
  }

  Widget _buildShopRewardsSection(BuildContext context, Shop shop) {
    final pointsAsync = ref.watch(shopPointsProvider(shop.shopId));
    final rewardsAsync = ref.watch(shopRewardsProvider(shop.shopId));

    // Resolve shop icon/logo url
    final String logoUrl = shop.logoUrl.isNotEmpty 
        ? shop.logoUrl 
        : (shop.imageUrl.isNotEmpty ? shop.imageUrl : 'https://via.placeholder.com/150?text=${Uri.encodeComponent(shop.name)}');

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.02),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Shop Header Row
          Row(
            children: [
              // Logo
              Container(
                width: 48,
                height: 48,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: Colors.grey.shade100,
                  image: DecorationImage(
                    image: NetworkImage(logoUrl),
                    fit: BoxFit.cover,
                  ),
                ),
              ),
              const SizedBox(width: 12),
              
              // Name & Subtitle
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      shop.name,
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        color: Color(0xFF333333),
                      ),
                    ),
                    const SizedBox(height: 2),
                    const Text(
                      'แลกรางวัลพิเศษจากร้านที่คุณชื่นชอบ',
                      style: TextStyle(
                        fontSize: 11,
                        color: Colors.grey,
                      ),
                    ),
                  ],
                ),
              ),
              
              // User Points at this shop
              Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  const Text(
                    'แต้มของคุณ',
                    style: TextStyle(
                      fontSize: 10,
                      color: Colors.grey,
                    ),
                  ),
                  const SizedBox(height: 2),
                  pointsAsync.when(
                    data: (pts) => Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(
                          '$pts',
                          style: const TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                            color: primaryGreen,
                          ),
                        ),
                        const SizedBox(width: 4),
                        const Text(
                          'GP',
                          style: TextStyle(
                            fontSize: 10,
                            fontWeight: FontWeight.bold,
                            color: Colors.grey,
                          ),
                        ),
                      ],
                    ),
                    loading: () => const SizedBox(
                      width: 14,
                      height: 14,
                      child: CircularProgressIndicator(strokeWidth: 2, color: primaryGreen),
                    ),
                    error: (_, __) => const Text('0 GP', style: TextStyle(color: Colors.redAccent)),
                  ),
                ],
              ),
            ],
          ),
          const SizedBox(height: 16),
          const Divider(height: 1),
          const SizedBox(height: 16),

          // Rewards horizontal scroll
          rewardsAsync.when(
            data: (rewards) {
              if (rewards.isEmpty) {
                return const Padding(
                  padding: EdgeInsets.symmetric(vertical: 20),
                  child: Center(
                    child: Text(
                      'ไม่มีของรางวัลสะสมในขณะนี้',
                      style: TextStyle(color: Colors.grey, fontSize: 13),
                    ),
                  ),
                );
              }
              return SizedBox(
                height: 230,
                child: ListView.separated(
                  scrollDirection: Axis.horizontal,
                  physics: const BouncingScrollPhysics(),
                  itemCount: rewards.length,
                  separatorBuilder: (context, index) => const SizedBox(width: 12),
                  itemBuilder: (context, index) {
                    final reward = rewards[index];
                    return _buildRewardCard(context, shop, reward);
                  },
                ),
              );
            },
            loading: () => const SizedBox(
              height: 200,
              child: Center(child: CircularProgressIndicator(color: primaryGreen)),
            ),
            error: (err, _) => Padding(
              padding: const EdgeInsets.symmetric(vertical: 20),
              child: Center(child: Text('โหลดของรางวัลล้มเหลว: $err', style: const TextStyle(color: Colors.redAccent))),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildRewardCard(BuildContext context, Shop shop, Reward reward) {
    // Determine remaining units / limits
    String stockText = 'เหลือ ${reward.stock} ชิ้น';
    if (reward.name.contains('ส่วนลด') || reward.name.contains('คูปอง') || reward.name.contains('ฟรี')) {
      stockText = 'เหลือ ${reward.stock} สิทธิ์';
    }

    return Container(
      width: 150,
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.grey.shade100),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Image
          Expanded(
            child: Center(
              child: _buildImage(reward.imageUrl),
            ),
          ),
          const SizedBox(height: 8),

          // Title
          Text(
            reward.name,
            style: const TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.bold,
              color: Color(0xFF333333),
            ),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
          const SizedBox(height: 4),

          // Point Cost
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(2),
                decoration: const BoxDecoration(
                  color: primaryGreen,
                  shape: BoxShape.circle,
                ),
                child: const Icon(Icons.eco, color: Colors.white, size: 10),
              ),
              const SizedBox(width: 4),
              Text(
                '${reward.pointsRequired} แต้ม',
                style: const TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.bold,
                  color: primaryGreen,
                ),
              ),
            ],
          ),
          const SizedBox(height: 4),

          // Stock Text
          Text(
            stockText,
            style: TextStyle(
              fontSize: 10,
              color: Colors.grey.shade500,
            ),
          ),
          const SizedBox(height: 8),

          // Button
          SizedBox(
            width: double.infinity,
            height: 32,
            child: ElevatedButton(
              onPressed: () => _showRedeemConfirmation(context, shop, reward),
              style: ElevatedButton.styleFrom(
                backgroundColor: primaryGreen,
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                elevation: 0,
                padding: EdgeInsets.zero,
              ),
              child: const Text(
                'แลกเลย',
                style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildImage(String? imageUrl) {
    if (imageUrl == null || imageUrl.isEmpty) {
      return const Icon(Icons.redeem_rounded, size: 48, color: Colors.grey);
    }

    if (imageUrl.startsWith('data:image')) {
      try {
        final split = imageUrl.split(',');
        if (split.length > 1) {
          return Image.memory(
            base64Decode(split[1]),
            fit: BoxFit.contain,
            errorBuilder: (context, error, stackTrace) => const Icon(Icons.broken_image, size: 48, color: Colors.grey),
          );
        }
      } catch (e) {
        return const Icon(Icons.broken_image, size: 48, color: Colors.grey);
      }
    }

    return Image.network(
      imageUrl,
      fit: BoxFit.contain,
      errorBuilder: (context, error, stackTrace) => const Icon(Icons.broken_image, size: 48, color: Colors.grey),
    );
  }

  void _showRedeemConfirmation(BuildContext context, Shop shop, Reward reward) {
    showDialog(
      context: context,
      builder: (dialogContext) => Dialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
        child: Padding(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(Icons.help_outline_rounded, size: 64, color: Colors.orange),
              const SizedBox(height: 16),
              const Text('ยืนยันการแลกรางวัล', style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
              const SizedBox(height: 12),
              RichText(
                textAlign: TextAlign.center,
                text: TextSpan(
                  style: const TextStyle(color: Colors.black87, fontSize: 14, height: 1.4),
                  children: [
                    const TextSpan(text: 'คุณต้องการใช้ '),
                    TextSpan(text: '${reward.pointsRequired} แต้ม', style: const TextStyle(fontWeight: FontWeight.bold, color: Colors.orange)),
                    const TextSpan(text: ' ของร้าน '),
                    TextSpan(text: '"${shop.name}"', style: const TextStyle(fontWeight: FontWeight.bold, color: primaryGreen)),
                    const TextSpan(text: ' เพื่อแลก '),
                    TextSpan(text: '"${reward.name}"', style: const TextStyle(fontWeight: FontWeight.bold, color: primaryGreen)),
                    const TextSpan(text: ' ใช่หรือไม่?'),
                  ],
                ),
              ),
              const SizedBox(height: 24),
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton(
                      onPressed: () => Navigator.pop(dialogContext),
                      style: OutlinedButton.styleFrom(
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                        padding: const EdgeInsets.symmetric(vertical: 12),
                      ),
                      child: const Text('ยกเลิก'),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: ElevatedButton(
                      onPressed: () async {
                        Navigator.pop(dialogContext); 
                        setState(() => _isRedeeming = true);
                        try {
                          final apiService = ref.read(apiServiceProvider);
                          await apiService.redeemReward(reward.id);
                          
                          // Invalidate/Refresh points and rewards
                          ref.invalidate(shopPointsProvider(shop.shopId));
                          ref.invalidate(shopRewardsProvider(shop.shopId));
                          ref.invalidate(historyProvider); // Refresh redemption history
                          
                          setState(() => _isRedeeming = false);
                          if (context.mounted) {
                            RedeemSuccessDialog.show(
                              context: context,
                              title: 'แลกรางวัลสำเร็จ!',
                              message: 'คุณได้แลก "${reward.name}" เรียบร้อยแล้ว กรุณาติดต่อรับที่ร้านค้า ${shop.name}',
                            );
                          }
                        } catch (e) {
                          setState(() => _isRedeeming = false);
                          if (context.mounted) {
                            DialogUtils.showErrorDialog(
                              context: context,
                              title: 'เกิดข้อผิดพลาด',
                              message: e.toString(),
                            );
                          }
                        }
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: primaryGreen,
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                        padding: const EdgeInsets.symmetric(vertical: 12),
                      ),
                      child: const Text('ยืนยัน', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _showRedemptionHistorySheet(BuildContext context) {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.only(
          topLeft: Radius.circular(24),
          topRight: Radius.circular(24),
        ),
      ),
      isScrollControlled: true,
      backgroundColor: Colors.white,
      builder: (context) {
        return DraggableScrollableSheet(
          initialChildSize: 0.65,
          maxChildSize: 0.85,
          minChildSize: 0.5,
          expand: false,
          builder: (context, scrollController) {
            return Consumer(
              builder: (context, ref, child) {
                final historyAsync = ref.watch(historyProvider);
                
                return Column(
                  children: [
                    const SizedBox(height: 12),
                    Container(
                      width: 40,
                      height: 5,
                      decoration: BoxDecoration(
                        color: Colors.grey.shade300,
                        borderRadius: BorderRadius.circular(10),
                      ),
                    ),
                    const SizedBox(height: 16),
                    const Text(
                      'ประวัติการแลกของรางวัล',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: Color(0xFF333333),
                      ),
                    ),
                    const SizedBox(height: 12),
                    const Divider(height: 1),
                    Expanded(
                      child: historyAsync.when(
                        data: (transactions) {
                          // Filter negative points transactions (which represent redemptions)
                          final redemptions = transactions.where((tx) => tx.isNegative).toList();
                          
                          if (redemptions.isEmpty) {
                            return Center(
                              child: Column(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  Icon(Icons.history_rounded, size: 64, color: Colors.grey.shade300),
                                  const SizedBox(height: 12),
                                  Text(
                                    'ยังไม่มีประวัติการแลกของรางวัล',
                                    style: TextStyle(color: Colors.grey.shade500, fontSize: 13),
                                  ),
                                ],
                              ),
                            );
                          }
                          
                          return ListView.separated(
                            controller: scrollController,
                            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
                            itemCount: redemptions.length,
                            separatorBuilder: (context, index) => const Divider(),
                            itemBuilder: (context, index) {
                              final tx = redemptions[index];
                              return Padding(
                                padding: const EdgeInsets.symmetric(vertical: 6),
                                child: Row(
                                  children: [
                                    Container(
                                      padding: const EdgeInsets.all(8),
                                      decoration: BoxDecoration(
                                        color: Colors.red.shade50,
                                        shape: BoxShape.circle,
                                      ),
                                      child: Icon(Icons.remove_circle_outline_rounded, color: Colors.red.shade700, size: 20),
                                    ),
                                    const SizedBox(width: 12),
                                    Expanded(
                                      child: Column(
                                        crossAxisAlignment: CrossAxisAlignment.start,
                                        children: [
                                          Text(
                                            tx.title,
                                            style: const TextStyle(
                                              fontWeight: FontWeight.bold,
                                              fontSize: 14,
                                              color: Color(0xFF333333),
                                            ),
                                          ),
                                          const SizedBox(height: 4),
                                          Text(
                                            tx.date,
                                            style: TextStyle(
                                              color: Colors.grey.shade500,
                                              fontSize: 11,
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),
                                    Text(
                                      '-${tx.points} GP',
                                      style: TextStyle(
                                        color: Colors.red.shade700,
                                        fontWeight: FontWeight.bold,
                                        fontSize: 14,
                                      ),
                                    ),
                                  ],
                                ),
                              );
                            },
                          );
                        },
                        loading: () => const Center(child: CircularProgressIndicator(color: primaryGreen)),
                        error: (err, _) => Center(child: Text('เกิดข้อผิดพลาด: $err')),
                      ),
                    ),
                  ],
                );
              },
            );
          },
        );
      },
    );
  }
}
