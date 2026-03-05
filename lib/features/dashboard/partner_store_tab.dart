import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/providers/shop_provider.dart';
import '../../core/models/shop_model.dart';
import 'product_list_screen.dart';

const Color primaryGreen = Color(0xFF2E7D32);
const Color secondaryGreen = Color(0xFF4CAF50);
const Color greyText = Color(0xFF757575);

class PartnerStoreTab extends ConsumerWidget {
  const PartnerStoreTab({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final shopsAsync = ref.watch(shopsProvider);

    return Scaffold(
      backgroundColor: const Color(0xFFF8FAF8),
      appBar: PreferredSize(
        preferredSize: const Size.fromHeight(180),
        child: Column(
          children: [
            // GreenPoint Branding
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 10, 20, 0),
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
                      fontSize: 22,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 10),
            // Search Bar Area
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              child: Container(
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(30),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.05),
                      blurRadius: 10,
                      offset: const Offset(0, 2),
                    ),
                  ],
                ),
                child: TextField(
                  decoration: InputDecoration(
                    hintText: 'ค้นหาร้านค้า...',
                    hintStyle: TextStyle(color: Colors.grey.shade400),
                    prefixIcon: const Icon(Icons.search, color: primaryGreen),
                    suffixIcon: const Icon(Icons.tune_rounded, color: greyText),
                    border: InputBorder.none,
                    contentPadding: const EdgeInsets.symmetric(vertical: 15),
                  ),
                ),
              ),
            ),
            const SizedBox(height: 20),
            // Custom Tabs
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
                          fontSize: 18,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Container(height: 3, color: primaryGreen),
                    ],
                  ),
                ),
                Expanded(
                  child: Column(
                    children: [
                      Text(
                        'แผนที่',
                        style: TextStyle(
                          color: Colors.grey.shade400,
                          fontWeight: FontWeight.bold,
                          fontSize: 18,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Container(height: 1, color: Colors.grey.shade200),
                    ],
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
      body: shopsAsync.when(
        data: (shops) => shops.isEmpty 
          ? const Center(child: Text('ไม่พบร้านค้า'))
          : ListView.separated(
              padding: const EdgeInsets.all(20),
              itemCount: shops.length,
              separatorBuilder: (context, index) => const SizedBox(height: 20),
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
    return GestureDetector(
      onTap: () {
        // บันทึกร้านค้าที่เลือก
        ref.read(selectedShopIdProvider.notifier).state = shop.shopId;
        // นำทางไปหน้าสินค้า
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => ProductListScreen(shopId: shop.shopId),
          ),
        );
      },
      child: Container(
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(20),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.03),
              blurRadius: 15,
              offset: const Offset(0, 5),
            ),
          ],
        ),
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.all(16),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Store Avatar
                  CircleAvatar(
                    radius: 35,
                    backgroundColor: secondaryGreen.withOpacity(0.1),
                    backgroundImage: shop.imageUrl != null ? NetworkImage(shop.imageUrl!) : null,
                    child: shop.imageUrl == null 
                      ? const Icon(Icons.store, color: primaryGreen, size: 30) 
                      : null,
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          shop.name,
                          style: const TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                            color: Colors.black87,
                          ),
                        ),
                        const SizedBox(height: 4),
                        if (shop.description != null)
                          Text(
                            shop.description!,
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                            style: TextStyle(
                              fontSize: 13,
                              color: Colors.grey.shade600,
                            ),
                          ),
                        const SizedBox(height: 8),
                        Row(
                          children: [
                            const Icon(Icons.location_on_outlined, size: 14, color: secondaryGreen),
                            const SizedBox(width: 4),
                            Expanded(
                              child: Text(
                                shop.address ?? 'ไม่มีข้อมูลที่อยู่',
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                style: const TextStyle(fontSize: 12, color: greyText),
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              decoration: BoxDecoration(
                color: secondaryGreen.withOpacity(0.05),
                borderRadius: const BorderRadius.vertical(bottom: Radius.circular(20)),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Row(
                    children: [
                      Icon(Icons.verified, size: 16, color: secondaryGreen),
                      SizedBox(width: 4),
                      Text(
                        'พันธมิตร GreenPoint',
                        style: TextStyle(
                          color: secondaryGreen,
                          fontSize: 12,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                  Text(
                    'เข้าดูสินค้า >',
                    style: TextStyle(
                      color: primaryGreen.withOpacity(0.8),
                      fontSize: 12,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
