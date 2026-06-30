import 'package:flutter/material.dart';
import 'package:flutter/gestures.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:geolocator/geolocator.dart';
import '../../core/providers/shop_provider.dart';
import '../../core/providers/user_provider.dart';
import '../../core/models/shop_model.dart';
import 'shop_detail_screen.dart';
import 'shop_map_view.dart';
import 'how_to_earn_screen.dart';
import 'dashboard_screen.dart';
import '../../core/providers/notification_provider.dart';

const Color primaryGreen = Color(0xFF2E7D32);
const Color secondaryGreen = Color(0xFF66BB6A);
const Color greyText = Color(0xFF757575);

class PartnerStoreTab extends ConsumerStatefulWidget {
  const PartnerStoreTab({super.key});

  @override
  ConsumerState<PartnerStoreTab> createState() => _PartnerStoreTabState();
}

class ShopMockupData {
  final String name;
  final String logoUrl;
  final String imageUrl;
  final double rating;
  final int reviewsCount;
  final String category;
  final String distance;
  final int defaultPoints;
  final List<String> tags;

  ShopMockupData({
    required this.name,
    required this.logoUrl,
    required this.imageUrl,
    required this.rating,
    required this.reviewsCount,
    required this.category,
    required this.distance,
    required this.defaultPoints,
    required this.tags,
  });
}

class _PartnerStoreTabState extends ConsumerState<PartnerStoreTab> {
  final TextEditingController _searchController = TextEditingController();
  String _searchQuery = '';
  int _selectedTab = 0; // 0: รายชื่อร้าน, 1: แผนที่
  int _selectedCategoryIndex = 0; // 0: ทั้งหมด, 1: คาเฟ่, 2: ร้านอาหาร, 3: ช้อปปิ้ง, 4: อื่นๆ
  String? _selectedSubCategory;

  final List<Map<String, dynamic>> _categories = [
    {'name': 'ทั้งหมด', 'icon': Icons.grid_view},
    {'name': 'คาเฟ่', 'icon': Icons.local_cafe_outlined},
    {'name': 'ร้านอาหาร', 'icon': Icons.restaurant},
    {'name': 'ช้อปปิ้ง', 'icon': Icons.shopping_bag_outlined},
    {'name': '... อื่นๆ', 'icon': Icons.more_horiz},
  ];

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  // Maps database shops to beautiful mockup assets dynamically
  ShopMockupData _getShopMockup(Shop shop, Position? userPos, int points) {
    // Inferred category
    String category = 'คาเฟ่';
    if (shop.name.contains('บัวลอย') || shop.name.contains('หวาน')) {
      category = 'ของหวาน';
    } else if (shop.name.contains('ออร์แกนิก') || shop.name.contains('อาหาร')) {
      category = 'ร้านอาหาร';
    } else if (shop.name.contains('Shop') || shop.name.contains('ช้อป') || shop.name.contains('Hug')) {
      category = 'ช้อปปิ้ง';
    } else if (shop.name.contains('Bakery') || shop.name.contains('เบเกอรี่')) {
      category = 'เบเกอรี่';
    }

    final int hashCode = shop.shopId.hashCode.abs();
    
    // Dynamic distance calculation
    String distance = '0.5 km';
    if (shop.latitude != null && shop.longitude != null && userPos != null) {
      final double distanceInMeters = Geolocator.distanceBetween(
        userPos.latitude,
        userPos.longitude,
        shop.latitude!,
        shop.longitude!,
      );
      final double distanceInKm = distanceInMeters / 1000.0;
      distance = '${distanceInKm.toStringAsFixed(1)} km';
    } else {
      final double val = 0.2 + (hashCode % 15) / 10.0;
      distance = '${val.toStringAsFixed(1)} km';
    }

    // Real logo and image from backend database
    final String logo = shop.logoUrl.isNotEmpty 
        ? shop.logoUrl 
        : (shop.imageUrl.isNotEmpty ? shop.imageUrl : 'https://via.placeholder.com/150?text=${Uri.encodeComponent(shop.name)}');
        
    final String cover = shop.imageUrl.isNotEmpty 
        ? shop.imageUrl 
        : (shop.logoUrl.isNotEmpty ? shop.logoUrl : 'https://via.placeholder.com/150?text=${Uri.encodeComponent(shop.name)}');

    final double rating = 4.2 + (hashCode % 8) / 10.0;
    final int reviewsCount = 10 + (hashCode % 190);

    final List<String> tags = ['รักษ์โลก', 'Eco-Friendly'];
    if (hashCode % 2 == 0) {
      tags.add('ไม่รับพลาสติก');
    } else {
      tags.add('แก้วพกพา');
    }

    return ShopMockupData(
      name: shop.name,
      logoUrl: logo,
      imageUrl: cover,
      rating: rating,
      reviewsCount: reviewsCount,
      category: category,
      distance: distance,
      defaultPoints: points,
      tags: tags,
    );
  }

  @override
  Widget build(BuildContext context) {
    final shopsAsync = ref.watch(shopsProvider);
    final loyaltyPointsAsync = ref.watch(userLoyaltyPointsProvider);
    final locationAsync = ref.watch(userLocationProvider);
    final double screenWidth = MediaQuery.of(context).size.width;
    final bool isDesktop = screenWidth > 600;

    final Position? userPos = locationAsync.asData?.value;

    // Build loyalty points mapping
    Map<String, int> shopPointsMap = {};
    loyaltyPointsAsync.whenData((records) {
      for (final rec in records) {
        if (rec is Map) {
          final sId = rec['shopId']?.toString();
          final pts = (rec['points'] as num?)?.toInt() ?? 0;
          if (sId != null) {
            shopPointsMap[sId] = pts;
          }
        }
      }
    });

    // Compute highest point shop
    Shop? displayLoyaltyShop;
    int displayPoints = 0;
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

    if (displayLoyaltyShop == null) {
      shopsAsync.whenData((shops) {
        if (shops.isNotEmpty) {
          displayLoyaltyShop = shops.first;
        }
      });
    }

    return Scaffold(
      backgroundColor: Colors.white,
      appBar: PreferredSize(
        preferredSize: const Size.fromHeight(200),
        child: SafeArea(
          child: Column(
            children: [
              // Logo & Notification
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Row(
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
                            fontSize: 20,
                          ),
                        ),
                      ],
                    ),
                    Consumer(
                      builder: (context, ref, child) {
                        final notifications = ref.watch(notificationsProvider);
                        final unreadCount = notifications.where((n) => !n.isRead).length;
                        return GestureDetector(
                          onTap: () => NotificationBottomSheet.show(context),
                          child: Stack(
                            children: [
                              const Icon(
                                Icons.notifications_none_outlined,
                                size: 26,
                                color: Colors.grey,
                              ),
                              if (unreadCount > 0)
                                Positioned(
                                  right: 0,
                                  top: 0,
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
                          ),
                        );
                      },
                    ),
                  ],
                ),
              ),
              // Search Bar
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 6),
                child: Container(
                  height: 44,
                  decoration: BoxDecoration(
                    color: const Color(0xFFF5F5F5),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Row(
                    children: [
                      const Padding(
                        padding: EdgeInsets.symmetric(horizontal: 12),
                        child: Icon(Icons.search, color: Colors.grey, size: 20),
                      ),
                      Expanded(
                        child: TextField(
                          controller: _searchController,
                          onChanged: (value) {
                            setState(() {
                              _searchQuery = value;
                            });
                          },
                          decoration: InputDecoration(
                            hintText: 'ค้นหาร้านค้า, ประเภท, สถานที่...',
                            hintStyle: TextStyle(color: Colors.grey.shade500, fontSize: 13),
                            border: InputBorder.none,
                            isDense: true,
                            contentPadding: const EdgeInsets.symmetric(vertical: 8),
                          ),
                        ),
                      ),
                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 12),
                        child: Icon(Icons.tune, color: Colors.grey.shade600, size: 20),
                      ),
                    ],
                  ),
                ),
              ),
              // Categories tabs
              _buildCategoryTabs(),
              const Spacer(),
              // Tabs Selector
              Row(
                children: [
                  Expanded(
                    child: GestureDetector(
                      onTap: () {
                        setState(() {
                          _selectedTab = 0;
                        });
                      },
                      child: Column(
                        children: [
                          Text(
                            'รายชื่อร้าน',
                            style: TextStyle(
                              color: _selectedTab == 0 ? primaryGreen : Colors.grey,
                              fontWeight: FontWeight.bold,
                              fontSize: 15,
                            ),
                          ),
                          const SizedBox(height: 6),
                          Container(
                            height: 2.5,
                            color: _selectedTab == 0 ? primaryGreen : Colors.transparent,
                          ),
                        ],
                      ),
                    ),
                  ),
                  Expanded(
                    child: GestureDetector(
                      onTap: () {
                        setState(() {
                          _selectedTab = 1;
                        });
                      },
                      child: Column(
                        children: [
                          Text(
                            'แผนที่',
                            style: TextStyle(
                              color: _selectedTab == 1 ? primaryGreen : Colors.grey,
                              fontWeight: FontWeight.bold,
                              fontSize: 15,
                            ),
                          ),
                          const SizedBox(height: 6),
                          Container(
                            height: 2.5,
                            color: _selectedTab == 1 ? primaryGreen : Colors.transparent,
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
      body: _selectedTab == 1
          ? ShopMapView(onViewAll: () => setState(() => _selectedTab = 0))
          : shopsAsync.when(
              data: (shops) {
                final String selectedCatName = _categories[_selectedCategoryIndex]['name'] as String;

                final filteredShops = shops.where((shop) {
                  final points = shopPointsMap[shop.shopId] ?? 0;
                  final mockup = _getShopMockup(shop, userPos, points);
                  final matchesSearch = shop.name.toLowerCase().contains(_searchQuery.toLowerCase()) ||
                      (shop.address?.toLowerCase().contains(_searchQuery.toLowerCase()) ?? false);
                  
                  final matchesCategory = selectedCatName == 'ทั้งหมด' ||
                      (selectedCatName == '... อื่นๆ' && mockup.category != 'คาเฟ่' && mockup.category != 'ร้านอาหาร' && mockup.category != 'ช้อปปิ้ง') ||
                      mockup.category == selectedCatName;
                  return matchesSearch && matchesCategory;
                }).toList();

                bool showHighlight = false;
                if (displayLoyaltyShop != null) {
                  final points = shopPointsMap[displayLoyaltyShop!.shopId] ?? 0;
                  final mockup = _getShopMockup(displayLoyaltyShop!, userPos, points);
                  final matchesSearch = displayLoyaltyShop!.name.toLowerCase().contains(_searchQuery.toLowerCase()) ||
                      (displayLoyaltyShop!.address?.toLowerCase().contains(_searchQuery.toLowerCase()) ?? false);
                  final matchesCategory = selectedCatName == 'ทั้งหมด' ||
                      (selectedCatName == '... อื่นๆ' && mockup.category != 'คาเฟ่' && mockup.category != 'ร้านอาหาร' && mockup.category != 'ช้อปปิ้ง') ||
                      mockup.category == selectedCatName;
                  showHighlight = matchesSearch && matchesCategory;
                }

                final partnerShops = filteredShops.where((s) => s.shopId != displayLoyaltyShop?.shopId).toList();

                return filteredShops.isEmpty
                    ? const Center(child: Text('ไม่พบร้านค้า'))
                    : ScrollConfiguration(
                        behavior: ScrollConfiguration.of(context).copyWith(
                          dragDevices: {
                            PointerDeviceKind.touch,
                            PointerDeviceKind.mouse,
                            PointerDeviceKind.trackpad,
                          },
                        ),
                        child: SingleChildScrollView(
                          physics: const BouncingScrollPhysics(),
                          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 20),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              // 1. Highlight Shop
                              if (displayLoyaltyShop != null && showHighlight) ...[
                                _buildHighlightShopCard(
                                  context, 
                                  displayLoyaltyShop!, 
                                  _getShopMockup(
                                    displayLoyaltyShop!, 
                                    userPos, 
                                    shopPointsMap[displayLoyaltyShop!.shopId] ?? 0
                                  ), 
                                  displayPoints
                                ),
                              ],
                              
                              // 2. Title header
                              Row(
                                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                children: [
                                  Row(
                                    children: [
                                      const Icon(Icons.people_outline, size: 18, color: primaryGreen),
                                      const SizedBox(width: 6),
                                      Text(
                                        'ร้านค้าที่ร่วมโครงการ GreenPoint',
                                        style: TextStyle(
                                          fontSize: isDesktop ? 16 : 14,
                                          fontWeight: FontWeight.bold,
                                          color: const Color(0xFF1B5E20),
                                        ),
                                      ),
                                    ],
                                  ),
                                  Row(
                                    children: [
                                      Text(
                                        'เรียงตาม: ใกล้สุด',
                                        style: TextStyle(fontSize: 11, color: Colors.grey.shade600),
                                      ),
                                      Icon(Icons.keyboard_arrow_down, size: 14, color: Colors.grey.shade600),
                                    ],
                                  ),
                                ],
                              ),
                              const SizedBox(height: 16),

                              // 3. Store List
                              if (partnerShops.isEmpty)
                                const Padding(
                                  padding: EdgeInsets.symmetric(vertical: 24),
                                  child: Center(child: Text('ไม่พบร้านค้าในหมวดหมู่นี้')),
                                )
                              else
                                ...partnerShops.map((shop) {
                                  final points = shopPointsMap[shop.shopId] ?? 0;
                                  final mockup = _getShopMockup(shop, userPos, points);
                                  return _buildStoreItem(context, ref, shop, mockup, points);
                                }),

                              // 4. PR Banner
                              _buildPromoBanner(context),
                            ],
                          ),
                        ),
                      );
              },
              loading: () => const Center(child: CircularProgressIndicator(color: primaryGreen)),
              error: (err, stack) => Center(child: Text('เกิดข้อผิดพลาด: $err')),
            ),
    );
  }

  Widget _buildCategoryTabs() {
    return ScrollConfiguration(
      behavior: ScrollConfiguration.of(context).copyWith(
        dragDevices: {
          PointerDeviceKind.touch,
          PointerDeviceKind.mouse,
          PointerDeviceKind.trackpad,
        },
      ),
      child: SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
        physics: const BouncingScrollPhysics(),
        child: Row(
          children: List.generate(_categories.length, (index) {
            final cat = _categories[index];
            final isSelected = _selectedCategoryIndex == index;
            
            String displayName = cat['name'] as String;
            if (index == 4 && _selectedSubCategory != null) {
              displayName = 'อื่นๆ: $_selectedSubCategory';
            }
            
            return Builder(
              builder: (context) => GestureDetector(
                onTap: () async {
                  if (index == 4) {
                    // Show popup menu for subcategories
                    final RenderBox button = context.findRenderObject() as RenderBox;
                    final RenderBox overlay = Navigator.of(context).overlay!.context.findRenderObject() as RenderBox;
                    final RelativeRect position = RelativeRect.fromRect(
                      Rect.fromPoints(
                        button.localToGlobal(Offset.zero, ancestor: overlay),
                        button.localToGlobal(button.size.bottomRight(Offset.zero), ancestor: overlay),
                      ),
                      Offset.zero & overlay.size,
                    );
  
                    final selected = await showMenu<String>(
                      context: context,
                      position: position,
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                      items: [
                        const PopupMenuItem<String>(
                          value: 'เบเกอรี่',
                          child: Text('เบเกอรี่', style: TextStyle(fontSize: 13)),
                        ),
                        const PopupMenuItem<String>(
                          value: 'ร้านสะดวกซื้อ',
                          child: Text('ร้านสะดวกซื้อ', style: TextStyle(fontSize: 13)),
                        ),
                        const PopupMenuItem<String>(
                          value: 'ซูเปอร์มาร์เก็ต',
                          child: Text('ซูเปอร์มาร์เก็ต', style: TextStyle(fontSize: 13)),
                        ),
                      ],
                    );
  
                    if (selected != null) {
                      setState(() {
                        _selectedCategoryIndex = index;
                        _selectedSubCategory = selected;
                      });
                    }
                  } else {
                    setState(() {
                      _selectedCategoryIndex = index;
                      _selectedSubCategory = null; // Reset subcategory when switching main categories
                    });
                  }
                },
                child: Container(
                  margin: const EdgeInsets.only(right: 12),
                  padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                  decoration: BoxDecoration(
                    color: isSelected ? primaryGreen : Colors.white,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(
                      color: isSelected ? primaryGreen : Colors.grey.shade200,
                      width: 1,
                    ),
                  ),
                  child: Row(
                    children: [
                      Icon(
                        cat['icon'] as IconData,
                        size: 16,
                        color: isSelected ? Colors.white : Colors.grey.shade700,
                      ),
                      const SizedBox(width: 6),
                      Text(
                        displayName,
                        style: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.bold,
                          color: isSelected ? Colors.white : Colors.grey.shade700,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            );
          }),
        ),
      ),
    );
  }

  Widget _buildHighlightShopCard(BuildContext context, Shop shop, ShopMockupData mockup, int points) {
    return Container(
      width: double.infinity,
      margin: const EdgeInsets.only(bottom: 24),
      decoration: BoxDecoration(
        color: const Color(0xFFF1F8F1),
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: const Color(0xFFC8E6C9), width: 0.5),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Tag "ร้านที่คุณสนับสนุนมากที่สุด"
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: const Color(0xFFC8E6C9), width: 0.5),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Icon(Icons.eco, size: 12, color: primaryGreen),
                  const SizedBox(width: 4),
                  const Text(
                    'ร้านที่คุณสนับสนุนมากที่สุด',
                    style: TextStyle(
                      color: primaryGreen,
                      fontSize: 10,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 12),
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Text(
                            mockup.name,
                            style: const TextStyle(
                              fontSize: 17,
                              fontWeight: FontWeight.w900,
                              color: Color(0xFF1B5E20),
                            ),
                          ),
                          const SizedBox(width: 4),
                          const Icon(Icons.check_circle, size: 14, color: primaryGreen),
                        ],
                      ),
                      const SizedBox(height: 4),
                      Row(
                        children: [
                          const Icon(Icons.star, size: 13, color: Colors.orange),
                          const SizedBox(width: 2),
                          Text(
                            '${mockup.rating} | ${mockup.category} | ${mockup.distance}',
                            style: TextStyle(
                              fontSize: 11,
                              color: Colors.grey.shade700,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 12),
                      // Points Banner
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                        decoration: BoxDecoration(
                          color: Colors.white.withOpacity(0.9),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Row(
                          children: [
                            Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                const Text(
                                  'แต้มสะสมจากร้านนี้',
                                  style: TextStyle(fontSize: 9, color: Colors.grey),
                                ),
                                const SizedBox(height: 2),
                                Row(
                                  children: [
                                    Text(
                                      '$points GP',
                                      style: const TextStyle(
                                        fontSize: 13,
                                        fontWeight: FontWeight.w900,
                                        color: primaryGreen,
                                      ),
                                    ),
                                    const SizedBox(width: 4),
                                    const Text(
                                      'จาก 8 รายการ',
                                      style: TextStyle(fontSize: 9, color: Colors.grey),
                                    ),
                                  ],
                                ),
                              ],
                            ),
                            const Spacer(),
                            const Icon(Icons.chevron_right, size: 16, color: Colors.grey),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 12),
                Stack(
                  children: [
                    Container(
                      width: 110,
                      height: 110,
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(16),
                        color: Colors.grey.shade200,
                      ),
                      child: ClipRRect(
                        borderRadius: BorderRadius.circular(16),
                        child: Image.network(mockup.imageUrl, fit: BoxFit.cover),
                      ),
                    ),
                    Positioned(
                      top: 8,
                      right: 8,
                      child: Container(
                        padding: const EdgeInsets.all(4),
                        decoration: const BoxDecoration(
                          color: Colors.white,
                          shape: BoxShape.circle,
                        ),
                        child: const Icon(
                          Icons.favorite_border,
                          size: 14,
                          color: Colors.red,
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
            const SizedBox(height: 12),
            Align(
              alignment: Alignment.bottomRight,
              child: ElevatedButton(
                onPressed: () {
                  ref.read(selectedShopIdProvider.notifier).state = shop.shopId;
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => ShopDetailScreen(shop: shop),
                    ),
                  );
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: primaryGreen,
                  foregroundColor: Colors.white,
                  elevation: 0,
                  padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                child: const Text(
                  'ดูรายละเอียด',
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStoreItem(BuildContext context, WidgetRef ref, Shop shop, ShopMockupData mockup, int points) {
    return Container(
      width: double.infinity,
      margin: const EdgeInsets.only(bottom: 16),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.grey.shade200),
      ),
      child: Stack(
        children: [
          Row(
            children: [
              Container(
                width: 60,
                height: 60,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: Colors.grey.shade100,
                  border: Border.all(color: Colors.grey.shade200, width: 1),
                ),
                child: ClipOval(
                  child: Image.network(mockup.logoUrl, fit: BoxFit.cover),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Text(
                          mockup.name,
                          style: const TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.bold,
                            color: Color(0xFF1B5E20),
                          ),
                        ),
                        const SizedBox(width: 3),
                        const Icon(Icons.check_circle, size: 12, color: primaryGreen),
                      ],
                    ),
                    const SizedBox(height: 4),
                    Row(
                      children: [
                        const Icon(Icons.star, size: 12, color: Colors.orange),
                        const SizedBox(width: 2),
                        Text(
                          '${mockup.rating} (${mockup.reviewsCount} รีวิว) | ${mockup.category} | ${mockup.distance}',
                          style: TextStyle(
                            fontSize: 10,
                            color: Colors.grey.shade600,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    Row(
                      children: mockup.tags.map((t) => Container(
                        margin: const EdgeInsets.only(right: 6),
                        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 3),
                        decoration: BoxDecoration(
                          color: const Color(0xFFF1F8F1),
                          borderRadius: BorderRadius.circular(6),
                        ),
                        child: Text(
                          t,
                          style: const TextStyle(
                            color: primaryGreen,
                            fontSize: 9,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      )).toList(),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 8),
              Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      const Text(
                        'แต้มจากร้านนี้',
                        style: TextStyle(fontSize: 8, color: Colors.grey),
                      ),
                      Text(
                        '$points GP',
                        style: const TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.bold,
                          color: primaryGreen,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  TextButton(
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
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 0),
                      minimumSize: const Size(0, 28),
                      tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                    ),
                    child: const Text(
                      'ดูรายละเอียด',
                      style: TextStyle(
                        color: primaryGreen,
                        fontSize: 11,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
          Positioned(
            top: 0,
            right: 0,
            child: Icon(
              Icons.favorite_border,
              size: 16,
              color: Colors.grey.shade400,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPromoBanner(BuildContext context) {
    return Container(
      width: double.infinity,
      margin: const EdgeInsets.only(top: 16, bottom: 20),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(0xFFE8F5E9),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: const BoxDecoration(
              color: Colors.white,
              shape: BoxShape.circle,
            ),
            child: const Icon(Icons.public, size: 36, color: primaryGreen),
          ),
          const SizedBox(width: 12),
          const Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'สนับสนุนร้านค้า รักษ์โลกไปด้วยกัน',
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.bold,
                    color: Color(0xFF1B5E20),
                  ),
                ),
                SizedBox(height: 2),
                Text(
                  'ทุกการใช้จ่ายของคุณ ช่วยสร้างโลกที่เขียวขึ้น',
                  style: TextStyle(
                    fontSize: 9,
                    color: Colors.grey,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 8),
          ElevatedButton(
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => const HowToEarnScreen(),
                ),
              );
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: primaryGreen,
              foregroundColor: Colors.white,
              elevation: 0,
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(10),
              ),
            ),
            child: const Text(
              'ดูวิธีการสะสม',
              style: TextStyle(
                fontSize: 10,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
