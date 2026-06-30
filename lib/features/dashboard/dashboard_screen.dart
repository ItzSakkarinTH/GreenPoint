import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'dart:async';
import 'package:flutter/gestures.dart';

import '../../core/providers/shop_provider.dart';
import 'partner_store_tab.dart';
import 'profile_tab.dart';
import 'shop_detail_screen.dart';
import 'scan_screen.dart';
import '../../core/providers/user_provider.dart';
import '../../core/providers/event_provider.dart';
import '../../core/models/event_model.dart';
import '../../core/models/shop_model.dart';
import '../../core/providers/reward_provider.dart';
import '../../core/models/reward_model.dart';
import 'shop_reward_screen.dart';
import '../../core/providers/notification_provider.dart';

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

  @override
  Widget build(BuildContext context) {
    final currentIndex = ref.watch(activeTabProvider);
    return Scaffold(
      backgroundColor: backgroundWhite,
      appBar: currentIndex == 0 ? _buildAppBar() : null,
      body: _buildBody(currentIndex),
      bottomNavigationBar: _buildBottomNav(currentIndex),
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
        Consumer(
          builder: (context, ref, child) {
            final notifications = ref.watch(notificationsProvider);
            final unreadCount = notifications.where((n) => !n.isRead).length;
            return Stack(
              alignment: Alignment.center,
              children: [
                IconButton(
                  onPressed: () => NotificationBottomSheet.show(context),
                  icon: const Icon(Icons.notifications_none_rounded, color: primaryGreen, size: 28),
                ),
                if (unreadCount > 0)
                  Positioned(
                    right: 8,
                    top: 8,
                    child: Container(
                      padding: const EdgeInsets.all(2),
                      decoration: const BoxDecoration(
                        color: Colors.red,
                        shape: BoxShape.circle,
                      ),
                      constraints: const BoxConstraints(
                        minWidth: 14,
                        minHeight: 14,
                      ),
                      child: Text(
                        '$unreadCount',
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 8,
                          fontWeight: FontWeight.bold,
                        ),
                        textAlign: TextAlign.center,
                      ),
                    ),
                  ),
              ],
            );
          },
        ),
        const SizedBox(width: 8),
      ],
    );
  }

  Widget _buildBody(int currentIndex) {
    switch (currentIndex) {
      case 0:
        return const _HomeTab();
      case 1:
        return const PartnerStoreTab();
      case 2:
        return const ScanScreen();
      case 3:
        return const ProfileTab();
      default:
        return const Center(child: Text('Coming Soon'));
    }
  }

  Widget _buildBottomNav(int currentIndex) {
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
        currentIndex: currentIndex,
        onTap: (index) {
          ref.read(activeTabProvider.notifier).state = index;
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

class _HomeTab extends ConsumerStatefulWidget {
  const _HomeTab();

  @override
  ConsumerState<_HomeTab> createState() => _HomeTabState();
}

class _HomeTabState extends ConsumerState<_HomeTab> {
  final PageController _pageController = PageController(viewportFraction: 0.9);
  int _currentPage = 0;
  Timer? _timer;

  @override
  void initState() {
    super.initState();
    _startAutoScroll();
  }

  void _startAutoScroll() {
    _timer = Timer.periodic(const Duration(seconds: 4), (timer) {
      if (_pageController.hasClients) {
        final eventsAsync = ref.read(eventsProvider);
        eventsAsync.whenData((events) {
          if (events.length > 1) {
            final nextPage = (_currentPage + 1) % events.length;
            _pageController.animateToPage(
              nextPage,
              duration: const Duration(milliseconds: 600),
              curve: Curves.easeInOutCubic,
            );
          }
        });
      }
    });
  }

  @override
  void dispose() {
    _timer?.cancel();
    _pageController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final shopsAsync = ref.watch(shopsProvider);
    final eventsAsync = ref.watch(eventsProvider);
    final loyaltyPointsAsync = ref.watch(userLoyaltyPointsProvider);

    final double screenWidth = MediaQuery.of(context).size.width;
    final bool isLargeDesktop = screenWidth >= 1024;

    // Compute highest point shop
    Shop? displayLoyaltyShop;
    int displayPoints = 0; // Backend default for new users
    
    // Find the record with the highest points
    Map<String, dynamic>? highestShopRecord;
    int maxPoints = -1;
    
    loyaltyPointsAsync.whenData((records) {
      for (final rec in records) {
        if (rec is Map) {
          final pts = (rec['points'] as num?)?.toInt() ?? 0;
          if (pts > maxPoints) {
            maxPoints = pts;
            highestShopRecord = Map<String, dynamic>.from(rec);
          }
        }
      }
    });

    if (highestShopRecord != null) {
      final String targetShopId = highestShopRecord!['shopId']?.toString() ?? '';
      shopsAsync.whenData((shops) {
        for (final s in shops) {
          if (s.shopId == targetShopId) {
            displayLoyaltyShop = s;
            displayPoints = maxPoints;
            break;
          }
        }
      });
    }

    // Fallback if no points record exists yet to match mockup
    if (displayLoyaltyShop == null) {
      shopsAsync.whenData((shops) {
        if (shops.isNotEmpty) {
          displayLoyaltyShop = shops.first;
        }
      });
    }

    return ScrollConfiguration(
      behavior: ScrollConfiguration.of(context).copyWith(
        dragDevices: {
          PointerDeviceKind.touch,
          PointerDeviceKind.mouse,
          PointerDeviceKind.trackpad,
        },
      ),
      child: SingleChildScrollView(
        physics: const BouncingScrollPhysics(),
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // 1. Promo Carousel / Event Banner
            eventsAsync.when(
              data: (events) {
                if (events.isEmpty) return _buildDefaultPromoCard(isLargeDesktop);
                
                return Column(
                  children: [
                    SizedBox(
                      height: isLargeDesktop ? 280 : 220, // Scale height to 280 on large desktop, keep 220 on mobile
                      child: PageView.builder(
                        controller: _pageController,
                        onPageChanged: (index) {
                          setState(() {
                            _currentPage = index;
                          });
                        },
                        itemCount: events.length,
                        itemBuilder: (context, index) {
                          return Padding(
                            padding: const EdgeInsets.symmetric(horizontal: 4.0),
                            child: _buildPromoCard(events[index], isLargeDesktop),
                          );
                        },
                      ),
                    ),
                    if (events.length > 1) ...[
                      const SizedBox(height: 12),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: List.generate(
                          events.length,
                          (index) => AnimatedContainer(
                            duration: const Duration(milliseconds: 300),
                            margin: const EdgeInsets.only(right: 6),
                            height: 8,
                            width: _currentPage == index ? 24 : 8,
                            decoration: BoxDecoration(
                              color: _currentPage == index ? primaryGreen : Colors.grey.shade300,
                              borderRadius: BorderRadius.circular(4),
                            ),
                          ),
                        ),
                      ),
                    ],
                  ],
                );
              },
              loading: () => _buildLoadingPromoCard(isLargeDesktop),
              error: (err, _) => _buildDefaultPromoCard(isLargeDesktop),
            ),
            const SizedBox(height: 32),

            // 2. แต้มสะสมจากร้านค้า Section
            if (displayLoyaltyShop != null) ...[
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text(
                    'แต้มสะสมจากร้านค้า',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: primaryGreen,
                    ),
                  ),
                  TextButton(
                    onPressed: () {},
                    child: const Text('ดูประวัติทั้งหมด >', style: TextStyle(color: Colors.grey, fontSize: 13)),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              _buildHighestPointsCard(displayLoyaltyShop!, displayPoints),
              const SizedBox(height: 32),
              
              // 4. แลกของรางวัล Rewards Section
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text(
                    'แลกของรางวัล Rewards',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: primaryGreen,
                    ),
                  ),
                  TextButton(
                    onPressed: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => ShopRewardScreen(
                            shopId: displayLoyaltyShop!.shopId,
                            shopName: displayLoyaltyShop!.name,
                          ),
                        ),
                      );
                    },
                    child: const Text('ดูทั้งหมด >', style: TextStyle(color: Colors.grey, fontSize: 13)),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              ref.watch(shopRewardsProvider(displayLoyaltyShop!.shopId)).when(
                data: (rewards) {
                  if (rewards.isEmpty) return const Text('ไม่มีของรางวัลสะสมในขณะนี้');
                  return _buildRewardListSection(rewards, displayLoyaltyShop!);
                },
                loading: () => const SizedBox(height: 220, child: Center(child: CircularProgressIndicator(color: primaryGreen))),
                error: (err, _) => const Text('Error loading rewards'),
              ),
              const SizedBox(height: 16),
              _buildPromoGiftBanner(displayLoyaltyShop!),
              const SizedBox(height: 32),
            ],

            // 5. ร้านค้าใกล้คุณ Section
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
                TextButton(
                  onPressed: () {
                    ref.read(activeTabProvider.notifier).state = 1;
                  },
                  child: const Text('ดูทั้งหมด >', style: TextStyle(color: Colors.grey, fontSize: 13)),
                ),
              ],
            ),
            const SizedBox(height: 12),
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
                        child: _buildStoreCard(shop),
                      )).toList(),
                ),
              ),
              loading: () => const Center(child: CircularProgressIndicator(color: primaryGreen)),
              error: (err, _) => Text('Error: $err'),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildPromoCard(EventModel event, bool isLargeDesktop) {
    return GestureDetector(
      onTap: () => _showEventDetailDialog(context, event),
      child: Center(
        child: Container(
          width: double.infinity, // Expand to match parent width container
          height: double.infinity,
          decoration: BoxDecoration(
            color: const Color(0xFFF1F8F1), // Light green background
            borderRadius: BorderRadius.circular(24),
            border: Border.all(color: const Color(0xFFC8E6C9), width: 0.5),
          ),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(24),
            child: event.imageUrl != null && event.imageUrl!.isNotEmpty
                ? Image.network(
                    event.imageUrl!,
                    fit: BoxFit.cover, // Cover the entire container card fully on both mobile and desktop
                    width: double.infinity,
                    height: double.infinity,
                    errorBuilder: (context, error, stackTrace) => _buildMockEventIllustration(),
                  )
                : _buildMockEventIllustration(),
          ),
        ),
      ),
    );
  }

  Widget _buildMockEventIllustration() {
    return Stack(
      alignment: Alignment.center,
      children: [
        // Shopping bag
        const Icon(Icons.shopping_bag_outlined, size: 64, color: Color(0xFF81C784)),
        Positioned(
          bottom: 24,
          child: Container(
            padding: const EdgeInsets.all(2),
            decoration: const BoxDecoration(
              color: Color(0xFF2E7D32),
              shape: BoxShape.circle,
            ),
            child: const Icon(Icons.eco, size: 12, color: Colors.white),
          ),
        ),
        // X2 badge
        Positioned(
          right: 8,
          bottom: 16,
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 4),
            decoration: BoxDecoration(
              color: const Color(0xFFFFB74D),
              shape: BoxShape.circle,
              border: Border.all(color: Colors.white, width: 1.5),
            ),
            child: const Text(
              'X2',
              style: TextStyle(
                fontSize: 10,
                fontWeight: FontWeight.bold,
                color: Colors.white,
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildDefaultPromoCard(bool isLargeDesktop) {
    return Center(
      child: Container(
        height: isLargeDesktop ? 280 : 220,
        width: double.infinity,
        decoration: BoxDecoration(
          color: const Color(0xFFF1F8F1),
          borderRadius: BorderRadius.circular(24),
          border: Border.all(color: const Color(0xFFC8E6C9), width: 0.5),
        ),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(24),
          child: _buildMockEventIllustration(),
        ),
      ),
    );
  }



  Widget _buildLoadingPromoCard(bool isLargeDesktop) {
    return Center(
      child: Container(
        height: isLargeDesktop ? 280 : 220,
        width: double.infinity,
        decoration: BoxDecoration(
          color: const Color(0xFFF1F8F1),
          borderRadius: BorderRadius.circular(24),
        ),
        child: const Center(
          child: CircularProgressIndicator(color: primaryGreen),
        ),
      ),
    );
  }

  void _showEventDetailDialog(BuildContext context, EventModel event) {
    showDialog(
      context: context,
      builder: (context) => Dialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        child: Container(
          padding: const EdgeInsets.all(16),
          constraints: const BoxConstraints(maxWidth: 340), // Compact size
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Event image (compact)
              if (event.imageUrl != null && event.imageUrl!.isNotEmpty)
                ClipRRect(
                  borderRadius: BorderRadius.circular(12),
                  child: Image.network(
                    event.imageUrl!,
                    height: 130,
                    width: double.infinity,
                    fit: BoxFit.cover,
                    errorBuilder: (context, error, stackTrace) => Container(
                      height: 130,
                      color: const Color(0xFFE8F5E9),
                      child: const Icon(Icons.eco, size: 48, color: primaryGreen),
                    ),
                  ),
                )
              else
                Container(
                  height: 130,
                  decoration: BoxDecoration(
                    color: const Color(0xFFE8F5E9),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: const Center(
                    child: Icon(Icons.eco, size: 48, color: primaryGreen),
                  ),
                ),
              const SizedBox(height: 12),
              // Tag
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                decoration: BoxDecoration(
                  color: const Color(0xFFE8F5E9),
                  borderRadius: BorderRadius.circular(6),
                ),
                child: const Text(
                  'กิจกรรมพิเศษ',
                  style: TextStyle(
                    color: Color(0xFF2E7D32),
                    fontSize: 10,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
              const SizedBox(height: 8),
              // Title
              Text(
                event.title,
                style: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: Color(0xFF1B5E20),
                ),
              ),
              const SizedBox(height: 6),
              // Description
              Text(
                event.description,
                style: TextStyle(
                  fontSize: 12,
                  color: Colors.grey.shade700,
                  height: 1.3,
                ),
              ),
              const SizedBox(height: 16),
              // Close button
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: () => Navigator.pop(context),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF2E7D32),
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 10),
                    elevation: 0,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(10),
                    ),
                  ),
                  child: const Text(
                    'ตกลง',
                    style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildHighestPointsCard(Shop shop, int points) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: Colors.grey.shade200),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.02),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Row(
        children: [
          // Logo with medal badge
          Stack(
            clipBehavior: Clip.none,
            children: [
              Container(
                width: 64,
                height: 64,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: Colors.grey.shade100,
                  border: Border.all(color: Colors.grey.shade200, width: 1.5),
                ),
                child: ClipOval(
                  child: shop.logoUrl.isNotEmpty
                      ? Image.network(shop.logoUrl, fit: BoxFit.cover)
                      : (shop.imageUrl.isNotEmpty
                          ? Image.network(shop.imageUrl, fit: BoxFit.cover)
                          : const Icon(Icons.store, color: Colors.grey, size: 28)),
                ),
              ),
              Positioned(
                bottom: -4,
                right: -4,
                child: Container(
                  padding: const EdgeInsets.all(3),
                  decoration: const BoxDecoration(
                    color: Color(0xFFFFC107), // Gold/Amber color
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(Icons.workspace_premium, size: 14, color: Colors.white),
                ),
              ),
            ],
          ),
          const SizedBox(width: 16),
          // Middle texts
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                  decoration: BoxDecoration(
                    color: const Color(0xFFE8F5E9),
                    borderRadius: BorderRadius.circular(6),
                  ),
                  child: const Text(
                    'ร้านที่สะสมแต้มมากที่สุด',
                    style: TextStyle(
                      color: Color(0xFF2E7D32),
                      fontSize: 9,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
                const SizedBox(height: 6),
                Text(
                  shop.name,
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: Colors.black87,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  shop.description != null && shop.description!.isNotEmpty
                      ? shop.description!
                      : 'เดินทางสีเขียวไปด้วยกัน 🌱',
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    fontSize: 11,
                    color: Colors.grey.shade500,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 8),
          // Right points & action
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              RichText(
                text: TextSpan(
                  children: [
                    TextSpan(
                      text: '$points ',
                      style: const TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.w900,
                        color: Color(0xFF2E7D32),
                      ),
                    ),
                    const TextSpan(
                      text: 'GP',
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.bold,
                        color: Color(0xFF2E7D32),
                      ),
                    ),
                  ],
                ),
              ),
              const Text(
                'จาก 8 รายการ',
                style: TextStyle(fontSize: 9, color: Colors.grey),
              ),
              const SizedBox(height: 8),
              GestureDetector(
                onTap: () {
                  ref.read(selectedShopIdProvider.notifier).state = shop.shopId;
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => ShopDetailScreen(shop: shop),
                    ),
                  );
                },
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                  decoration: BoxDecoration(
                    color: const Color(0xFF2E7D32),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: const Text(
                    'ไปที่ร้าน',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 11,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildRewardListSection(List<Reward> rewards, Shop shop) {
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      physics: const BouncingScrollPhysics(),
      child: Row(
        children: rewards.map((reward) {
          return Container(
            width: 140,
            margin: const EdgeInsets.only(right: 16),
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: Colors.grey.shade200),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Reward Image
                Container(
                  height: 100,
                  width: double.infinity,
                  decoration: BoxDecoration(
                    color: Colors.grey.shade100,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(12),
                    child: reward.imageUrl != null && reward.imageUrl!.isNotEmpty
                        ? Image.network(reward.imageUrl!, fit: BoxFit.cover)
                        : const Icon(Icons.redeem, size: 40, color: Colors.grey),
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  reward.name,
                  style: const TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 13,
                    color: Colors.black87,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 2),
                Text(
                  '${reward.pointsRequired} แต้ม',
                  style: const TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.bold,
                    color: Color(0xFFE65100),
                  ),
                ),
                const SizedBox(height: 8),
                GestureDetector(
                  onTap: () {
                    ref.read(selectedShopIdProvider.notifier).state = shop.shopId;
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => ShopRewardScreen(shopId: shop.shopId, shopName: shop.name),
                      ),
                    );
                  },
                  child: Container(
                    width: double.infinity,
                    padding: const EdgeInsets.symmetric(vertical: 6),
                    decoration: BoxDecoration(
                      color: const Color(0xFF2E7D32),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: const Center(
                      child: Text(
                        'แลกของ',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 11,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          );
        }).toList(),
      ),
    );
  }

  Widget _buildPromoGiftBanner(Shop shop) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: const Color(0xFF1B5E20), // Dark green background
        borderRadius: BorderRadius.circular(16),
      ),
      child: Row(
        children: [
          const Icon(Icons.card_giftcard_rounded, color: Colors.white, size: 24),
          const SizedBox(width: 12),
          const Expanded(
            child: Text(
              'ใช้แต้มแลกของรางวัลหรือคูปองส่วนลด\nของรางวัลจัดส่งทั่วโลก และส่วนลดจากร้านค้าที่คุณรัก!',
              style: TextStyle(
                color: Colors.white70,
                fontSize: 10,
                height: 1.3,
              ),
            ),
          ),
          const SizedBox(width: 8),
          ElevatedButton(
            onPressed: () {
              ref.read(selectedShopIdProvider.notifier).state = shop.shopId;
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => ShopRewardScreen(shopId: shop.shopId, shopName: shop.name),
                ),
              );
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF2E7D32),
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
              elevation: 0,
            ),
            child: const Text(
              'ไปหน้า Rewards',
              style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStoreCard(Shop shop) {
    // Generate mock distances, ratings and tags based on shop names for accuracy
    String distance = '0.5 km';
    double rating = 4.7;
    String tag = 'คาเฟ่รักษ์โลก';
    if (shop.name.contains('Thong Lo')) {
      distance = '0.3 km';
      rating = 4.8;
      tag = 'กาแฟ & เบเกอรี่';
    } else if (shop.name.contains('Sukhumvit')) {
      distance = '0.6 km';
      rating = 4.6;
      tag = 'คาเฟ่เพื่อสิ่งแวดล้อม';
    } else if (shop.name.contains('Ari')) {
      distance = '0.8 km';
      rating = 4.7;
      tag = 'สินค้าเพื่อโลก';
    } else if (shop.name.contains('ตึก33')) {
      distance = '0.1 km';
      rating = 4.9;
      tag = 'คัดสรรธรรมชาติ';
    }
    
    return Container(
      width: 140,
      margin: const EdgeInsets.only(right: 16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.grey.shade200),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.01),
            blurRadius: 8,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Cover Image with distance badge
          Stack(
            children: [
              Container(
                height: 100,
                width: double.infinity,
                decoration: BoxDecoration(
                  color: Colors.grey.shade100,
                  borderRadius: BorderRadius.circular(16),
                ),
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(16),
                  child: shop.imageUrl.isNotEmpty
                      ? Image.network(shop.imageUrl, fit: BoxFit.cover)
                      : const Icon(Icons.store, size: 40, color: Colors.grey),
                ),
              ),
              Positioned(
                bottom: 8,
                left: 8,
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 3),
                  decoration: BoxDecoration(
                    color: Colors.black.withOpacity(0.6),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Text(
                    distance,
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 9,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ),
            ],
          ),
          Padding(
            padding: const EdgeInsets.all(8.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  shop.name,
                  style: const TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 13,
                    color: Colors.black87,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 2),
                Text(
                  tag,
                  style: TextStyle(
                    fontSize: 10,
                    color: Colors.grey.shade500,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 6),
                Row(
                  children: [
                    const Icon(Icons.star_rounded, color: Color(0xFFFFC107), size: 14),
                    const SizedBox(width: 2),
                    Text(
                      rating.toString(),
                      style: const TextStyle(
                        fontSize: 10,
                        fontWeight: FontWeight.bold,
                        color: Colors.black87,
                      ),
                    ),
                    const Spacer(),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                      decoration: BoxDecoration(
                        color: const Color(0xFFFFF3E0),
                        borderRadius: BorderRadius.circular(4),
                      ),
                      child: const Text(
                        'มีโปรโมชั่น',
                        style: TextStyle(
                          color: Color(0xFFE65100),
                          fontSize: 8,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

// =========================================================================
// 🔔 Notification Bottom Sheet Dialog
// =========================================================================
class NotificationBottomSheet extends ConsumerWidget {
  const NotificationBottomSheet({super.key});

  static void show(BuildContext context) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (context) => const NotificationBottomSheet(),
    );
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final notifications = ref.watch(notificationsProvider);
    final unreadCount = notifications.where((n) => !n.isRead).length;

    return Container(
      height: MediaQuery.of(context).size.height * 0.65,
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.only(
          topLeft: Radius.circular(28),
          topRight: Radius.circular(28),
        ),
      ),
      child: Column(
        children: [
          // Drag handle
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
          
          // Header Row
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Row(
                  children: [
                    const Text(
                      'การแจ้งเตือน',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: Color(0xFF333333),
                      ),
                    ),
                    if (unreadCount > 0) ...[
                      const SizedBox(width: 8),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                        decoration: BoxDecoration(
                          color: Colors.redAccent,
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Text(
                          '$unreadCount ใหม่',
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 10,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ],
                  ],
                ),
                if (unreadCount > 0)
                  TextButton(
                    onPressed: () {
                      ref.read(notificationsProvider.notifier).markAllAsRead();
                    },
                    child: const Text(
                      'อ่านทั้งหมด',
                      style: TextStyle(
                        color: primaryGreen,
                        fontSize: 12,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
              ],
            ),
          ),
          const SizedBox(height: 8),
          const Divider(height: 1),
          
          // Notifications List
          Expanded(
            child: notifications.isEmpty
                ? Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.notifications_none_rounded, size: 64, color: Colors.grey.shade300),
                        const SizedBox(height: 12),
                        Text(
                          'ไม่มีการแจ้งเตือนในขณะนี้',
                          style: TextStyle(color: Colors.grey.shade500, fontSize: 13),
                        ),
                      ],
                    ),
                  )
                : ListView.builder(
                    padding: const EdgeInsets.symmetric(vertical: 8),
                    physics: const BouncingScrollPhysics(),
                    itemCount: notifications.length,
                    itemBuilder: (context, index) {
                      final n = notifications[index];
                      
                      // Choose icon dynamically
                      IconData iconData = Icons.notifications;
                      Color iconColor = primaryGreen;
                      if (n.title.contains('ยินดีต้อนรับ') || n.title.contains('🎉')) {
                        iconData = Icons.celebration;
                        iconColor = Colors.orange;
                      } else if (n.title.contains('GP') || n.title.contains('แต้ม')) {
                        iconData = Icons.eco;
                        iconColor = Colors.green;
                      } else if (n.title.contains('คูปอง') || n.title.contains('แลก')) {
                        iconData = Icons.confirmation_number_outlined;
                        iconColor = Colors.blue;
                      }

                      return InkWell(
                        onTap: () {
                          ref.read(notificationsProvider.notifier).markAsRead(n.id);
                        },
                        child: Container(
                          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
                          color: n.isRead ? Colors.transparent : const Color(0xFFF1F8F1),
                          child: Row(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              // Icon
                              Container(
                                padding: const EdgeInsets.all(10),
                                decoration: BoxDecoration(
                                  color: iconColor.withOpacity(0.1),
                                  shape: BoxShape.circle,
                                ),
                                child: Icon(iconData, color: iconColor, size: 20),
                              ),
                              const SizedBox(width: 14),
                              
                              // Content
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      n.title,
                                      style: TextStyle(
                                        fontSize: 13,
                                        fontWeight: n.isRead ? FontWeight.normal : FontWeight.bold,
                                        color: const Color(0xFF333333),
                                      ),
                                    ),
                                    const SizedBox(height: 4),
                                    Text(
                                      n.message,
                                      style: TextStyle(
                                        fontSize: 11,
                                        color: Colors.grey.shade600,
                                        height: 1.4,
                                      ),
                                    ),
                                    const SizedBox(height: 6),
                                    Text(
                                      _formatTime(n.createdAt),
                                      style: TextStyle(
                                        fontSize: 9,
                                        color: Colors.grey.shade400,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                              
                              // Unread dot indicator
                              if (!n.isRead) ...[
                                const SizedBox(width: 8),
                                Container(
                                  width: 8,
                                  height: 8,
                                  margin: const EdgeInsets.only(top: 6),
                                  decoration: const BoxDecoration(
                                    color: primaryGreen,
                                    shape: BoxShape.circle,
                                  ),
                                ),
                              ],
                            ],
                          ),
                        ),
                      );
                    },
                  ),
          ),
        ],
      ),
    );
  }

  String _formatTime(String dateStr) {
    try {
      DateTime dt = DateTime.parse(dateStr).toLocal();
      Duration diff = DateTime.now().difference(dt);
      
      if (diff.inMinutes < 60) {
        return '${diff.inMinutes} นาทีที่แล้ว';
      } else if (diff.inHours < 24) {
        return '${diff.inHours} ชั่วโมงที่แล้ว';
      } else {
        return '${diff.inDays} วันที่แล้ว';
      }
    } catch (_) {
      return dateStr;
    }
  }
}
