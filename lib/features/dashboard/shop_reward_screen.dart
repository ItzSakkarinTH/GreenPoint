import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/providers/reward_provider.dart';
import '../../core/providers/user_provider.dart';
import '../../core/providers/shop_provider.dart';
import '../../core/models/reward_model.dart';

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
  int _selectedTab = 1; // 0: คูปองส่วนลด, 1: แลกของ

  @override
  Widget build(BuildContext context) {
    final pointsAsync = ref.watch(shopPointsProvider(widget.shopId));
    final rewardsAsync = ref.watch(shopRewardsProvider(widget.shopId));

    return Scaffold(
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
                    childAspectRatio: 0.62, // ปรับให้ Card มีความสูงเพิ่มขึ้นเพื่อป้องกัน Overflow
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
              child: reward.imageUrl != null 
                ? Image.network(reward.imageUrl!, fit: BoxFit.contain)
                : const Icon(Icons.redeem, size: 60, color: Colors.grey),
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
                    maxLines: 1, // ป้องกันชื่อสินค้ายาวเกินไปดันปุ่มหลุดขอบ
                    overflow: TextOverflow.ellipsis,
                  ),
                  Text(
                    'ใช้ ${reward.pointsRequired} แต้ม',
                    style: TextStyle(color: Colors.grey.shade600, fontSize: 12),
                  ),
                  const Spacer(),
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton(
                      onPressed: () {
                        // Handle redemption logic
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

  void _showRedeemDialog(Reward reward) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: const Text('ยืนยันการแลกรางวัล'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('คุณต้องการใช้ ${reward.pointsRequired} แต้ม'),
            Text('เพื่อแลก "${reward.name}" ใช่หรือไม่?'),
            const SizedBox(height: 16),
            const Text(
              'สามารถติดต่อรับไอเทมตัวจริงได้ที่หน้าร้าน',
              style: TextStyle(color: Colors.grey, fontSize: 13),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('ยกเลิก', style: TextStyle(color: Colors.grey)),
          ),
          ElevatedButton(
            onPressed: () async {
              Navigator.pop(context); // ปิด Dialog ทันที
              
              // แสดง Loading Overlay หรือ SnackBar
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('กำลังดำเนินการแลกรางวัล...')),
              );

              try {
                final apiService = ref.read(apiServiceProvider);
                await apiService.redeemReward(reward.id);
                
                // สั่งรีเฟรชข้อมูลคะแนนใหม่หลังจากแลกเสร็จ
                ref.invalidate(shopPointsProvider(widget.shopId));
                
                if (mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text('แลกรางวัลสำเร็จ! กรุณานับไอเทมที่หน้าร้าน'),
                      backgroundColor: primaryGreen,
                    ),
                  );
                }
              } catch (e) {
                if (mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text('เกิดข้อผิดพลาด: $e'),
                      backgroundColor: Colors.red,
                    ),
                  );
                }
              }
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: primaryGreen,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            ),
            child: const Text('ยืนยัน', style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );
  }
}
