import 'package:flutter/material.dart';
import 'package:flutter/gestures.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:geolocator/geolocator.dart';
import 'package:latlong2/latlong.dart';
import 'package:greenpoint/core/providers/shop_provider.dart';
import 'package:greenpoint/core/providers/user_provider.dart';
import 'package:greenpoint/core/models/shop_model.dart';
import 'shop_detail_screen.dart';

const Color primaryGreen = Color(0xFF2E7D32);

class ShopMapView extends ConsumerStatefulWidget {
  final VoidCallback? onViewAll;
  const ShopMapView({super.key, this.onViewAll});

  @override
  ConsumerState<ShopMapView> createState() => _ShopMapViewState();
}

class MapShopMockupData {
  final String name;
  final String logoUrl;
  final String imageUrl;
  final double rating;
  final String category;
  final String distance;
  final int points;

  MapShopMockupData({
    required this.name,
    required this.logoUrl,
    required this.imageUrl,
    required this.rating,
    required this.category,
    required this.distance,
    required this.points,
  });
}

class _ShopMapViewState extends ConsumerState<ShopMapView> {
  final MapController _mapController = MapController();
  Shop? _selectedShop;

  // Default Location (Siam Square, Bangkok)
  final LatLng _defaultLocation = const LatLng(13.7469, 100.5393);

  MapShopMockupData _getShopMockup(Shop shop, Position? userPos, int points) {
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

    // Dynamic distance calculation using Geolocator
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

    // Use REAL logoUrl and imageUrl from database with placeholders
    final String logo = shop.logoUrl.isNotEmpty 
        ? shop.logoUrl 
        : (shop.imageUrl.isNotEmpty ? shop.imageUrl : 'https://via.placeholder.com/150?text=${Uri.encodeComponent(shop.name)}');
        
    final String cover = shop.imageUrl.isNotEmpty 
        ? shop.imageUrl 
        : (shop.logoUrl.isNotEmpty ? shop.logoUrl : 'https://via.placeholder.com/150?text=${Uri.encodeComponent(shop.name)}');

    final double rating = 4.2 + (hashCode % 8) / 10.0;

    return MapShopMockupData(
      name: shop.name,
      logoUrl: logo,
      imageUrl: cover,
      rating: rating,
      category: category,
      distance: distance,
      points: points,
    );
  }

  @override
  Widget build(BuildContext context) {
    final locationAsync = ref.watch(userLocationProvider);
    final shopsAsync = ref.watch(nearbyShopsProvider(5000.0));
    final loyaltyPointsAsync = ref.watch(userLoyaltyPointsProvider);

    final LatLng userCenter = locationAsync.when(
      data: (pos) => pos != null ? LatLng(pos.latitude, pos.longitude) : _defaultLocation,
      loading: () => _defaultLocation,
      error: (_, __) => _defaultLocation,
    );

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

    return Scaffold(
      backgroundColor: Colors.white,
      body: Stack(
        children: [
          // 1. Map Area (Occupies full screen behind bottom sheet)
          Positioned.fill(
            child: Stack(
              children: [
                ScrollConfiguration(
                  behavior: ScrollConfiguration.of(context).copyWith(
                    dragDevices: {
                      PointerDeviceKind.touch,
                      PointerDeviceKind.mouse,
                      PointerDeviceKind.trackpad,
                    },
                  ),
                  child: FlutterMap(
                    mapController: _mapController,
                    options: MapOptions(
                      initialCenter: userCenter,
                      initialZoom: 15.0,
                      onTap: (_, __) {
                        setState(() {
                          _selectedShop = null;
                        });
                      },
                    ),
                    children: [
                      TileLayer(
                        urlTemplate: 'https://api.maptiler.com/maps/streets-v2/{z}/{x}/{y}.png?key=UoM6D3yOMbD8SnI8vcW9',
                        userAgentPackageName: 'com.itzsakkarinth.greenpoint',
                      ),
                      MarkerLayer(
                        markers: [
                          // User Location Marker
                          if (locationAsync.asData?.value != null)
                            Marker(
                              point: LatLng(
                                locationAsync.asData!.value!.latitude,
                                locationAsync.asData!.value!.longitude,
                              ),
                              width: 40,
                              height: 40,
                              child: Container(
                                decoration: BoxDecoration(
                                  color: Colors.blue.withOpacity(0.25),
                                  shape: BoxShape.circle,
                                ),
                                child: Center(
                                  child: Container(
                                    width: 14,
                                    height: 14,
                                    decoration: const BoxDecoration(
                                      color: Colors.blue,
                                      shape: BoxShape.circle,
                                      boxShadow: [
                                        BoxShadow(
                                          color: Colors.black26,
                                          blurRadius: 4,
                                          offset: Offset(0, 2),
                                        ),
                                      ],
                                    ),
                                  ),
                                ),
                              ),
                            ),
                          
                          // Shop Markers
                          ...shopsAsync.when(
                            data: (shops) => shops
                                .where((s) => s.latitude != null && s.longitude != null)
                                .map((shop) {
                              final isSelected = _selectedShop?.shopId == shop.shopId;
                              final points = shopPointsMap[shop.shopId] ?? 0;
                              final mockup = _getShopMockup(shop, userPos, points);
                              return Marker(
                                point: LatLng(shop.latitude!, shop.longitude!),
                                width: 50,
                                height: 55,
                                child: GestureDetector(
                                  onTap: () {
                                    setState(() {
                                      _selectedShop = shop;
                                    });
                                    _mapController.move(
                                      LatLng(shop.latitude!, shop.longitude!),
                                      15.5,
                                    );
                                  },
                                  child: Stack(
                                    alignment: Alignment.center,
                                    children: [
                                      Icon(
                                        Icons.location_on,
                                        size: isSelected ? 50 : 45,
                                        color: isSelected ? const Color(0xFF1B5E20) : const Color(0xFF2E7D32),
                                      ),
                                      Positioned(
                                        top: isSelected ? 5 : 4,
                                        child: Container(
                                          width: isSelected ? 24 : 20,
                                          height: isSelected ? 24 : 20,
                                          decoration: BoxDecoration(
                                            shape: BoxShape.circle,
                                            color: Colors.white,
                                            border: isSelected ? Border.all(color: const Color(0xFFFFC107), width: 1) : null,
                                          ),
                                          padding: const EdgeInsets.all(1),
                                          child: ClipOval(
                                            child: Image.network(mockup.logoUrl, fit: BoxFit.cover),
                                          ),
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              );
                            }).toList(),
                            loading: () => [],
                            error: (_, __) => [],
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
                
                // My Location Pill Overlay (Top Left)
                Positioned(
                  left: 16,
                  top: 16,
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(20),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withOpacity(0.05),
                          blurRadius: 6,
                          offset: const Offset(0, 2),
                        ),
                      ],
                    ),
                    child: const Row(
                      children: [
                        Icon(Icons.my_location, size: 12, color: primaryGreen),
                        SizedBox(width: 4),
                        Text(
                          'ตำแหน่งของฉัน',
                          style: TextStyle(
                            fontSize: 10,
                            fontWeight: FontWeight.bold,
                            color: primaryGreen,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                
                // Reset GPS Location Button Overlay (Top Right)
                Positioned(
                  right: 16,
                  top: 16,
                  child: FloatingActionButton.small(
                    heroTag: 'gps_map_btn',
                    onPressed: () {
                      ref.invalidate(userLocationProvider);
                      final pos = ref.read(userLocationProvider).asData?.value;
                      if (pos != null) {
                        _mapController.move(LatLng(pos.latitude, pos.longitude), 15.0);
                      } else {
                        _mapController.move(_defaultLocation, 15.0);
                      }
                    },
                    backgroundColor: Colors.white,
                    foregroundColor: primaryGreen,
                    elevation: 3,
                    child: const Icon(Icons.my_location, size: 18),
                  ),
                ),
                
                // Selected Shop Highlight Popup Card Overlay (Fitted above the sheet view)
                if (_selectedShop != null)
                  Positioned(
                    left: 20,
                    right: 20,
                    bottom: 350, // Float above bottom sheet standard height
                    child: Center(
                      child: _buildMapHighlightCard(
                        _selectedShop!, 
                        _getShopMockup(
                          _selectedShop!, 
                          userPos, 
                          shopPointsMap[_selectedShop!.shopId] ?? 0
                        )
                      ),
                    ),
                  ),
              ],
            ),
          ),
          
          // 2. Draggable Bottom Sheet Section
          DraggableScrollableSheet(
            initialChildSize: 0.40,
            minChildSize: 0.15,
            maxChildSize: 0.85,
            builder: (BuildContext context, ScrollController scrollController) {
              return Container(
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: const BorderRadius.only(
                    topLeft: Radius.circular(24),
                    topRight: Radius.circular(24),
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.08),
                      blurRadius: 10,
                      offset: const Offset(0, -3),
                    ),
                  ],
                ),
                child: shopsAsync.when(
                  data: (shops) {
                    // Index 0: Header & Drag handle
                    // Index 1..N: Shop items
                    // Index N+1: Show All button
                    final int listCount = shops.isEmpty ? 1 : shops.length;
                    final int itemCount = listCount + 2; // +1 for header, +1 for show all button
                    
                    return ScrollConfiguration(
                      behavior: ScrollConfiguration.of(context).copyWith(
                        dragDevices: {
                          PointerDeviceKind.touch,
                          PointerDeviceKind.mouse,
                          PointerDeviceKind.trackpad,
                        },
                      ),
                      child: ListView.builder(
                        controller: scrollController, // Bind to sheet's controller for sliding behavior!
                        physics: const BouncingScrollPhysics(),
                        padding: EdgeInsets.zero,
                        itemCount: itemCount,
                        itemBuilder: (context, index) {
                          if (index == 0) {
                            // Header & Drag handle
                            return Column(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                const SizedBox(height: 8),
                                // Drag handle bar (ขีดขาว/เทาด้านบนสำหรับการเลื่อน)
                                Container(
                                  width: 36,
                                  height: 4,
                                  decoration: BoxDecoration(
                                    color: Colors.grey.shade300,
                                    borderRadius: BorderRadius.circular(2),
                                  ),
                                ),
                                // Bottom sheet header
                                Padding(
                                  padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                                  child: Row(
                                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                    children: [
                                      const Row(
                                        children: [
                                          Icon(Icons.storefront_outlined, size: 18, color: primaryGreen),
                                          SizedBox(width: 6),
                                          Text(
                                            'ร้านค้าใกล้คุณ',
                                            style: TextStyle(
                                              fontSize: 14,
                                              fontWeight: FontWeight.bold,
                                              color: Color(0xFF1B5E20),
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
                                ),
                              ],
                            );
                          } else if (index == itemCount - 1) {
                            // Show All button
                            if (widget.onViewAll == null) return const SizedBox.shrink();
                            return Padding(
                              padding: const EdgeInsets.only(left: 20.0, right: 20.0, bottom: 20.0, top: 4.0),
                              child: Container(
                                width: double.infinity,
                                height: 40,
                                decoration: BoxDecoration(
                                  color: const Color(0xFFF1F8F1),
                                  borderRadius: BorderRadius.circular(12),
                                  border: Border.all(color: const Color(0xFFC8E6C9), width: 0.5),
                                ),
                                child: InkWell(
                                  onTap: widget.onViewAll,
                                  borderRadius: BorderRadius.circular(12),
                                  child: const Row(
                                    mainAxisAlignment: MainAxisAlignment.center,
                                    children: [
                                      Text(
                                        'แสดงรายการทั้งหมด',
                                        style: TextStyle(
                                          color: primaryGreen,
                                          fontSize: 12,
                                          fontWeight: FontWeight.bold,
                                        ),
                                      ),
                                      SizedBox(width: 4),
                                      Icon(Icons.chevron_right, size: 16, color: primaryGreen),
                                    ],
                                  ),
                                ),
                              ),
                            );
                          } else {
                            if (shops.isEmpty) {
                              return const Padding(
                                padding: EdgeInsets.symmetric(vertical: 24),
                                child: Center(child: Text('ไม่พบร้านค้าใกล้เคียง')),
                              );
                            }
                            final shopIndex = index - 1;
                            final shop = shops[shopIndex];
                            final points = shopPointsMap[shop.shopId] ?? 0;
                            final mockup = _getShopMockup(shop, userPos, points);
                            return Padding(
                              padding: const EdgeInsets.symmetric(horizontal: 20),
                              child: _buildBottomSheetItem(shop, mockup),
                            );
                          }
                        },
                      ),
                    );
                  },
                  loading: () => const Center(child: CircularProgressIndicator(color: primaryGreen)),
                  error: (err, _) => Center(child: Text('เกิดข้อผิดพลาด: $err')),
                ),
              );
            },
          ),
        ],
      ),
    );
  }

  Widget _buildMapHighlightCard(Shop shop, MapShopMockupData mockup) {
    return Container(
      width: 220,
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.08),
            blurRadius: 10,
            offset: const Offset(0, 4),
          )
        ],
        border: Border.all(color: Colors.grey.shade200, width: 0.5),
      ),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  mockup.name,
                  style: const TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.bold,
                    color: Color(0xFF333333),
                  ),
                ),
                const SizedBox(height: 2),
                Row(
                  children: [
                    Text(
                      '${mockup.points} pts',
                      style: const TextStyle(
                        fontSize: 10,
                        fontWeight: FontWeight.bold,
                        color: primaryGreen,
                      ),
                    ),
                    Text(
                      ' • ${mockup.distance}',
                      style: TextStyle(
                        fontSize: 10,
                        color: Colors.grey.shade600,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 4),
                Row(
                  children: [
                    Text(
                      'ร้านค้าร่วมโครงการ GreenPoint',
                      style: TextStyle(
                        fontSize: 8,
                        color: Colors.grey.shade500,
                      ),
                    ),
                    const SizedBox(width: 2),
                    const Icon(Icons.eco, size: 8, color: primaryGreen),
                  ],
                ),
              ],
            ),
          ),
          const SizedBox(width: 8),
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
              padding: const EdgeInsets.all(6),
              decoration: const BoxDecoration(
                color: primaryGreen,
                shape: BoxShape.circle,
              ),
              child: const Icon(
                Icons.arrow_forward,
                color: Colors.white,
                size: 14,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildBottomSheetItem(Shop shop, MapShopMockupData mockup) {
    final bool isSelected = _selectedShop?.shopId == shop.shopId;
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(10),
      decoration: BoxDecoration(
        color: isSelected ? const Color(0xFFF1F8F1) : Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: isSelected ? const Color(0xFFC8E6C9) : Colors.grey.shade100,
          width: 1,
        ),
      ),
      child: Row(
        children: [
          // Logo Circular Avatar
          Container(
            width: 44,
            height: 44,
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
          // Middle Info
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  mockup.name,
                  style: const TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.bold,
                    color: Color(0xFF333333),
                  ),
                ),
                const SizedBox(height: 2),
                Row(
                  children: [
                    Text(
                      '${mockup.points} pts',
                      style: const TextStyle(
                        fontSize: 10,
                        fontWeight: FontWeight.bold,
                        color: primaryGreen,
                      ),
                    ),
                    Text(
                      ' • ${mockup.distance}',
                      style: TextStyle(
                        fontSize: 10,
                        color: Colors.grey.shade600,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 4),
                // Category Pill
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                  decoration: BoxDecoration(
                    color: const Color(0xFFF1F8F1),
                    borderRadius: BorderRadius.circular(4),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Icon(Icons.eco, size: 8, color: primaryGreen),
                      const SizedBox(width: 3),
                      Text(
                        mockup.category,
                        style: const TextStyle(
                          color: primaryGreen,
                          fontSize: 8,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 8),
          IconButton(
            icon: Icon(
              Icons.favorite_border,
              size: 18,
              color: Colors.grey.shade400,
            ),
            onPressed: () {},
            padding: EdgeInsets.zero,
            constraints: const BoxConstraints(),
          ),
          const SizedBox(width: 8),
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
