import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/providers/reward_provider.dart';
import '../../core/providers/user_provider.dart';
import '../../core/providers/shop_provider.dart';
import '../../core/models/reward_model.dart';
import '../../core/utils/dialog_utils.dart';

const Color primaryGreen = Color(0xFF2E7D32);
const Color secondaryGreen = Color(0xFF4CAF50);

class ShopRewardScreen extends ConsumerStatefulWidget {
  final String shopId;
  final String shopName;

  const ShopRewardScreen({
    super.key,
    required this.shopId,
    required this.shopName,
  });

  @override
  ConsumerState<ShopRewardScreen> createState() => _ShopRewardScreenState();
}

class _ShopRewardScreenState extends ConsumerState<ShopRewardScreen> {
  int _selectedTab = 1; // 1: แลกของ
  bool _isRedeeming = false;

  @override
  Widget build(BuildContext context) {
    final pointsAsync = ref.watch(shopPointsProvider(widget.shopId));
    final rewardsAsync = ref.watch(shopRewardsProvider(widget.shopId));

    return Stack(
      children: [
        Scaffold(
          backgroundColor: Colors.white,
          appBar: AppBar(
            backgroundColor: Colors.white,
            elevation: 0,
            leading: IconButton(
              icon: const Icon(Icons.arrow_back, color: primaryGreen),
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
          ),
          body: SingleChildScrollView(
            padding: const EdgeInsets.all(20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Reward by ${widget.shopName}',
                  style: const TextStyle(
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                    color: primaryGreen,
                  ),
                ),
                const SizedBox(height: 24),
                
                // Points Display
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.symmetric(vertical: 20),
                  decoration: BoxDecoration(
                    color: primaryGreen,
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: Center(
                    child: pointsAsync.when(
                      data: (pts) => Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Text(
                            pts.toString().replaceAllMapped(RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))'), (Match m) => '${m[1]},'),
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 40,
                              fontWeight: FontWeight.w900,
                            ),
                          ),
                          const SizedBox(width: 8),
                          const Text(
                            'GP',
                            style: TextStyle(
                              color: Colors.white,
                              fontSize: 30,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ],
                      ),
                      loading: () => const CircularProgressIndicator(color: Colors.white),
                      error: (e, _) => const Text('Error', style: TextStyle(color: Colors.white)),
                    ),
                  ),
                ),
                
                const SizedBox(height: 32),
                
                // Tabs
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    _buildTabButton(0, 'คูปองส่วนลด'),
                    const SizedBox(width: 12),
                    _buildTabButton(1, 'แลกของ'),
                  ],
                ),
                
                const SizedBox(height: 24),
                
                // Rewards Grid
                if (_selectedTab == 1)
                  rewardsAsync.when(
                    data: (rewards) => GridView.builder(
                      shrinkWrap: true,
                      physics: const NeverScrollableScrollPhysics(),
                      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                        crossAxisCount: 2,
                        childAspectRatio: 0.62, 
                        crossAxisSpacing: 16,
                        mainAxisSpacing: 16,
                      ),
                      itemCount: rewards.length,
                      itemBuilder: (context, index) {
                        return _buildRewardItem(rewards[index]);
                      },
                    ),
                    loading: () => const Center(child: CircularProgressIndicator()),
                    error: (e, _) => Center(child: Text('Error: $e')),
                  )
                else
                  const Center(
                    child: Padding(
                      padding: EdgeInsets.all(40.0),
                      child: Text(
                        'ไม่มีคูปองส่วนลดในขณะนี้',
                        style: TextStyle(color: Colors.grey),
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
                    'กำลังดำเนินการ...',
                    style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
                  ),
                ],
              ),
            ),
          ),
      ],
    );
  }

  Widget _buildTabButton(int index, String label) {
    bool isSelected = _selectedTab == index;
    return GestureDetector(
      onTap: () => setState(() => _selectedTab = index),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
        decoration: BoxDecoration(
          color: isSelected ? primaryGreen : secondaryGreen.withOpacity(0.1),
          borderRadius: BorderRadius.circular(12),
        ),
        child: Text(
          label,
          style: TextStyle(
            color: isSelected ? Colors.white : primaryGreen,
            fontWeight: FontWeight.bold,
            fontSize: 16,
          ),
        ),
      ),
    );
  }

  Widget _buildImage(String? imageUrl) {
    if (imageUrl == null || imageUrl.isEmpty) {
      return const Icon(Icons.redeem, size: 60, color: Colors.grey);
    }

    if (imageUrl.startsWith('data:image')) {
      try {
        final split = imageUrl.split(',');
        if (split.length > 1) {
          return Image.memory(
            base64Decode(split[1]),
            fit: BoxFit.contain,
            errorBuilder: (context, error, stackTrace) => const Icon(Icons.broken_image, size: 60, color: Colors.grey),
          );
        }
      } catch (e) {
        return const Icon(Icons.broken_image, size: 60, color: Colors.grey);
      }
    }

    return Image.network(
      imageUrl,
      fit: BoxFit.contain,
      errorBuilder: (context, error, stackTrace) => const Icon(Icons.broken_image, size: 60, color: Colors.grey),
    );
  }

  Widget _buildRewardItem(Reward reward) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        children: [
          Expanded(
            flex: 6,
            child: Padding(
              padding: const EdgeInsets.all(12.0),
              child: _buildImage(reward.imageUrl),
            ),
          ),
          Expanded(
            flex: 5,
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 8.0),
              child: Column(
                children: [
                  Text(
                    reward.name,
                    style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                    textAlign: TextAlign.center,
                    maxLines: 1, 
                    overflow: TextOverflow.ellipsis,
                  ),
                  Text(
                    'ใช้ ${reward.pointsRequired} แต้ม',
                    style: TextStyle(color: Colors.grey.shade600, fontSize: 12),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const Spacer(),
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton(
                      onPressed: () {
                        _showRedeemDialog(reward);
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: primaryGreen,
                        foregroundColor: Colors.white,
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                        padding: const EdgeInsets.symmetric(vertical: 4),
                        elevation: 0,
                      ),
                      child: const Text('แลก', style: TextStyle(fontWeight: FontWeight.bold)),
                    ),
                  ),
                  const SizedBox(height: 8),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

// _showRedeemDialog and _showResultDialog are replaced by DialogUtils


  void _showRedeemDialog(Reward reward) {
    showDialog(
      context: context,
      builder: (context) => Dialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
        child: Padding(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(Icons.help_outline_rounded, size: 64, color: Colors.orange),
              const SizedBox(height: 16),
              const Text('ยืนยันการแลกรางวัล', style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold)),
              const SizedBox(height: 12),
              RichText(
                textAlign: TextAlign.center,
                text: TextSpan(
                  style: const TextStyle(color: Colors.black87, fontSize: 16),
                  children: [
                    const TextSpan(text: 'คุณต้องการใช้ '),
                    TextSpan(text: '${reward.pointsRequired} แต้ม', style: const TextStyle(fontWeight: FontWeight.bold, color: Colors.orange)),
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
                      onPressed: () => Navigator.pop(context),
                      style: OutlinedButton.styleFrom(
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                        padding: const EdgeInsets.symmetric(vertical: 14),
                      ),
                      child: const Text('ยกเลิก'),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: ElevatedButton(
                      onPressed: () async {
                        Navigator.pop(context); 
                        setState(() => _isRedeeming = true);
                        try {
                          final apiService = ref.read(apiServiceProvider);
                          await apiService.redeemReward(reward.id);
                          ref.invalidate(shopPointsProvider(widget.shopId));
                          if (mounted) {
                            setState(() => _isRedeeming = false);
                            DialogUtils.showSuccessDialog(
                              context: context,
                              title: 'แลกรางวัลสำเร็จ!',
                              message: 'คุณได้แลก "${reward.name}" เรียบร้อยแล้ว กรุณาติดต่อรับไอเทมที่หน้าร้าน',
                            );
                          }
                        } catch (e) {
                          if (mounted) {
                            setState(() => _isRedeeming = false);
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
                        padding: const EdgeInsets.symmetric(vertical: 14),
                      ),
                      child: const Text('ยืนยัน', style: TextStyle(color: Colors.white)),
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
}
