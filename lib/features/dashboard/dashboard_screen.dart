import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'dart:io';

import '../../core/providers/auth_provider.dart';
import '../../core/providers/shop_provider.dart';
import 'partner_store_tab.dart';
import 'profile_tab.dart';
import 'product_list_screen.dart';
import 'shop_detail_screen.dart';

// กำหนดโทนสีตามดีไซน์ใหม่
const Color primaryGreen = Color(0xFF2E7D32);
const Color secondaryGreen = Color(0xFF4CAF50);
const Color backgroundWhite = Colors.white;
const Color greyText = Color(0xFF757575);
const Color lightGrey = Color(0xFFF5F5F5);

class DashboardScreen extends ConsumerStatefulWidget {
  const DashboardScreen({super.key});

  @override
  ConsumerState<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends ConsumerState<DashboardScreen> {
  int _currentIndex = 0;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: backgroundWhite,
      appBar: _currentIndex == 0 ? _buildAppBar() : null,
      body: _buildBody(),
      bottomNavigationBar: _buildBottomNav(),
    );
  }

  PreferredSizeWidget _buildAppBar() {
    return AppBar(
      backgroundColor: backgroundWhite,
      elevation: 0,
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
      actions: [
        IconButton(
          onPressed: () {},
          icon: const Icon(Icons.notifications_none_rounded, color: primaryGreen, size: 28),
        ),
        const SizedBox(width: 8),
      ],
    );
  }

  Widget _buildBody() {
    switch (_currentIndex) {
      case 0:
        return const _HomeTab();
      case 1:
        return const PartnerStoreTab();
      case 3:
        return const ProfileTab();
      default:
        return const Center(child: Text('Coming Soon'));
    }
  }

  Widget _buildBottomNav() {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, -5),
          ),
        ],
      ),
      child: BottomNavigationBar(
        currentIndex: _currentIndex,
        onTap: (index) {
          setState(() {
            _currentIndex = index;
          });
        },
        type: BottomNavigationBarType.fixed,
        backgroundColor: Colors.white,
        selectedItemColor: primaryGreen,
        unselectedItemColor: Colors.grey.shade400,
        selectedLabelStyle: const TextStyle(fontWeight: FontWeight.bold, fontSize: 12),
        unselectedLabelStyle: const TextStyle(fontSize: 12),
        elevation: 0,
        items: const [
          BottomNavigationBarItem(icon: Icon(Icons.home_filled), label: 'Home'),
          BottomNavigationBarItem(icon: Icon(Icons.storefront_outlined), label: 'Partner Store'),
          BottomNavigationBarItem(icon: Icon(Icons.qr_code_scanner_rounded), label: 'Scan'),
          BottomNavigationBarItem(icon: Icon(Icons.person_outline_rounded), label: 'Profile'),
        ],
      ),
    );
  }
}

class _HomeTab extends ConsumerWidget {
  const _HomeTab();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final shopsAsync = ref.watch(shopsProvider);

    return SingleChildScrollView(
      physics: const BouncingScrollPhysics(),
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Promo Card
          _buildPromoCard(),
          const SizedBox(height: 32),

          // Progress Section
          const Text(
            'วันนี้สะสมแล้ว 20 / 100 GP',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: Colors.black87,
            ),
          ),
          const SizedBox(height: 12),
          ClipRRect(
            borderRadius: BorderRadius.circular(10),
            child: LinearProgressIndicator(
              value: 0.2,
              minHeight: 12,
              backgroundColor: Colors.grey.shade200,
              valueColor: const AlwaysStoppedAnimation<Color>(secondaryGreen),
            ),
          ),
          const SizedBox(height: 24),

          // Empty Placeholder
          Container(
            height: 80,
            decoration: BoxDecoration(
              color: const Color(0xFFF1F8F1).withOpacity(0.5),
              borderRadius: BorderRadius.circular(16),
            ),
          ),
          const SizedBox(height: 40),

          // Stores Section
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text(
                'ร้านค้าใกล้คุณ',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: primaryGreen,
                ),
              ),
              TextButton.icon(
                onPressed: () {},
                icon: const Text('ดูทั้งหมด', style: TextStyle(color: primaryGreen)),
                label: const Icon(Icons.arrow_forward_ios_rounded, size: 12, color: primaryGreen),
                style: TextButton.styleFrom(padding: EdgeInsets.zero),
              ),
            ],
          ),
          const SizedBox(height: 16),
          shopsAsync.when(
            data: (shops) => SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              physics: const BouncingScrollPhysics(),
              child: Row(
                children: shops.isEmpty 
                  ? [const Text('ยังไม่มีข้อมูลร้านค้า')]
                  : shops.map((shop) => GestureDetector(
                      onTap: () {
                        ref.read(selectedShopIdProvider.notifier).state = shop.shopId;
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (context) => ShopDetailScreen(shop: shop),
                          ),
                        );
                      },
                      child: _buildStoreCard(shop.name, shop.address ?? 'ใกล้คุณ'),
                    )).toList(),
              ),
            ),
            loading: () => const Center(child: CircularProgressIndicator(color: primaryGreen)),
            error: (err, _) => Text('Error: $err'),
          ),
        ],
      ),
    );
  }

  Widget _buildPromoCard() {
    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        color: const Color(0xFFFFF3E0), // Light orange background
        borderRadius: BorderRadius.circular(24),
      ),
      child: Column(
        children: [
          const SizedBox(height: 16),
          // เราใช้ Image.file สำหรับรูปที่เจนนี่ (ในระบบจริงจะเป็น NetworkImage หรือ Asset)
          // แต่เพื่อความสะดวกในตัวอย่างนี้ ผมจะใช้ Placeholder ที่สวยงามแทนหากหาไฟล์ไม่เจอ
          ClipRRect(
            borderRadius: BorderRadius.circular(16),
            child: SizedBox(
               height: 150,
               child: Stack(
                 alignment: Alignment.center,
                 children: [
                   const Icon(Icons.card_giftcard_rounded, size: 80, color: Color(0xFFFFB74D)),
                   // หากมีรูปที่เจนนี่มาจริง ให้ใส่ตรงนี้
                   // Image.network('...'),
                 ],
               ),
            ),
          ),
          const Padding(
            padding: EdgeInsets.symmetric(vertical: 16.0),
            child: Column(
              children: [
                Text(
                  'งานมหกรรมศรีสะเกษ',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: Color(0xFF2E7D32),
                  ),
                ),
                SizedBox(height: 4),
                Text(
                  'แต้ม X2 กับร้านที่ร่วมรายการ',
                  style: TextStyle(
                    fontSize: 14,
                    color: greyText,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStoreCard(String name, String distance) {
    return Container(
      width: 130,
      margin: const EdgeInsets.only(right: 16),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(0xFFFDFDF4),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.grey.shade100),
      ),
      child: Column(
        children: [
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: const Color(0xFFE8F5E9),
              borderRadius: BorderRadius.circular(12),
            ),
            child: const Icon(Icons.store_rounded, color: secondaryGreen, size: 32),
          ),
          const SizedBox(height: 12),
          Text(
            name,
            style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
          ),
          Text(
            distance,
            style: const TextStyle(color: greyText, fontSize: 12),
          ),
        ],
      ),
    );
  }
}
