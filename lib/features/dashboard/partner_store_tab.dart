import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/providers/shop_provider.dart';
import '../../core/models/shop_model.dart';
import 'shop_detail_screen.dart';

const Color primaryGreen = Color(0xFF2E7D32);
const Color secondaryGreen = Color(0xFF66BB6A); // Lighter green for avatars/badges
const Color greyText = Color(0xFF757575);

class PartnerStoreTab extends ConsumerWidget {
  const PartnerStoreTab({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final shopsAsync = ref.watch(shopsProvider);

    return Scaffold(
      backgroundColor: Colors.white,
      appBar: PreferredSize(
        preferredSize: const Size.fromHeight(155), // Reducer height for sleeker look
        child: SafeArea(
          child: Column(
            children: [
              // Logo & Title
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
                child: Row(
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
                        fontSize: 20, // Slightly smaller
                      ),
                    ),
                  ],
                ),
              ),
              // Search Bar
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 20),
                child: Container(
                  height: 40, // Reduced height
                  decoration: BoxDecoration(
                    color: const Color(0xFFF1F8E9),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: TextField(
                    decoration: InputDecoration(
                      hintText: 'ค้นหาร้านค้า...',
                      hintStyle: TextStyle(color: Colors.grey.shade500, fontSize: 14),
                      prefixIcon: const Icon(Icons.search, color: Colors.grey, size: 20),
                      suffixIcon: const Icon(Icons.tune_rounded, color: Colors.black87, size: 20),
                      border: InputBorder.none,
                      contentPadding: const EdgeInsets.symmetric(vertical: 8),
                    ),
                  ),
                ),
              ),
              const Spacer(),
              // Tabs
              Row(
                children: [
                  Expanded(
                    child: Column(
                      children: [
                        const Text(
                          'รายชื่อร้าน',
                          style: TextStyle(
                            color: primaryGreen,
                            fontWeight: FontWeight.bold,
                            fontSize: 16, // Adjusted
                          ),
                        ),
                        const SizedBox(height: 6),
                        Container(height: 2.5, color: primaryGreen),
                      ],
                    ),
                  ),
                  Expanded(
                    child: Column(
                      children: [
                        const Text(
                          'แผนที่',
                          style: TextStyle(
                            color: Colors.grey,
                            fontWeight: FontWeight.bold,
                            fontSize: 16,
                          ),
                        ),
                        const SizedBox(height: 6),
                        Container(height: 1, color: Colors.grey.shade200),
                      ],
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
      body: shopsAsync.when(
        data: (shops) => shops.isEmpty 
          ? const Center(child: Text('ไม่พบร้านค้า'))
          : ListView.builder(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 20),
              itemCount: shops.length,
              itemBuilder: (context, index) {
                return _buildStoreItem(context, ref, shops[index]);
              },
            ),
        loading: () => const Center(child: CircularProgressIndicator(color: primaryGreen)),
        error: (err, stack) => Center(child: Text('เกิดข้อผิดพลาด: $err')),
      ),
    );
  }

  Widget _buildStoreItem(BuildContext context, WidgetRef ref, Shop shop) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 24), // Reduced spacing
      child: Stack(
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.center, // Center aligned
            children: [
              // Store Avatar
              CircleAvatar(
                radius: 38, // Reduced from 45
                backgroundColor: secondaryGreen.withOpacity(0.6),
                backgroundImage: shop.imageUrl != null ? NetworkImage(shop.imageUrl!) : null,
                child: shop.imageUrl == null 
                  ? const Icon(Icons.store, color: Colors.white, size: 32) 
                  : null,
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      shop.name,
                      style: const TextStyle(
                        fontSize: 17, // Reduced from 20
                        fontWeight: FontWeight.bold,
                        color: Color(0xFF1B5E20), // Darker green
                      ),
                    ),
                    const SizedBox(height: 6),
                    // Badge - More compact
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                      decoration: BoxDecoration(
                        color: secondaryGreen.withOpacity(0.15),
                        borderRadius: BorderRadius.circular(6),
                        border: Border.all(color: secondaryGreen.withOpacity(0.3), width: 0.5),
                      ),
                      child: const Text(
                        'GreenPoint Partner',
                        style: TextStyle(
                          color: Color(0xFF2E7D32),
                          fontSize: 11,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          // Detail Button - More minimalist
          Positioned(
            right: 0,
            bottom: 4,
            child: TextButton(
              onPressed: () {
                ref.read(selectedShopIdProvider.notifier).state = shop.shopId;
                 Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => ShopDetailScreen(shop: shop),
                  ),
                );
              },
              style: TextButton.styleFrom(
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8),
                  side: const BorderSide(color: Color(0xFF81C784), width: 1),
                ),
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 0),
                minimumSize: const Size(0, 32),
                tapTargetSize: MaterialTapTargetSize.shrinkWrap,
              ),
              child: const Text(
                'ดูรายละเอียด',
                style: TextStyle(
                  color: primaryGreen,
                  fontSize: 13,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
