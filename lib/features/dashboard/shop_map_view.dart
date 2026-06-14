import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:latlong2/latlong.dart';
import 'package:greenpoint/core/providers/shop_provider.dart';
import 'package:greenpoint/core/models/shop_model.dart';
import 'shop_detail_screen.dart';

class ShopMapView extends ConsumerStatefulWidget {
  const ShopMapView({super.key});

  @override
  ConsumerState<ShopMapView> createState() => _ShopMapViewState();
}

class _ShopMapViewState extends ConsumerState<ShopMapView> {
  final MapController _mapController = MapController();
  Shop? _selectedShop;

  // พิกัดเริ่มต้น (Siam Square, Bangkok) หากไม่สามารถดึงค่า GPS ได้
  final LatLng _defaultLocation = const LatLng(13.7469, 100.5393);

  @override
  Widget build(BuildContext context) {
    final locationAsync = ref.watch(userLocationProvider);
    final shopsAsync = ref.watch(nearbyShopsProvider(5000.0)); // ดึงร้านค้าในระยะ 5 กิโลเมตร

    final LatLng userCenter = locationAsync.when(
      data: (pos) => pos != null ? LatLng(pos.latitude, pos.longitude) : _defaultLocation,
      loading: () => _defaultLocation,
      error: (_, __) => _defaultLocation,
    );

    return Scaffold(
      body: Stack(
        children: [
          // 1. ตัวควบคุมและแผนที่หลัก FlutterMap
          FlutterMap(
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
              // เชื่อมโยงแผนที่จาก MapTiler Tile Service
              TileLayer(
                urlTemplate: 'https://api.maptiler.com/maps/streets-v2/256/{z}/{x}/{y}.png?key=vfKDiBWtQ8VIWq7E97HB',
                userAgentPackageName: 'com.itzsakkarinth.greenpoint',
              ),
              
              // Marker หมุดตำแหน่งผู้ใช้ และร้านค้า
              MarkerLayer(
                markers: [
                  // หมุดตำแหน่งปัจจุบันของผู้ใช้ (จุดวงกลมสีฟ้ากะพริบ/เปล่งรัศมี)
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
                            width: 16,
                            height: 16,
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

                  // หมุดร้านค้าสีเขียว
                  ...shopsAsync.when(
                    data: (shops) => shops
                        .where((s) => s.latitude != null && s.longitude != null)
                        .map((shop) {
                      final isSelected = _selectedShop?.shopId == shop.shopId;
                      return Marker(
                        point: LatLng(shop.latitude!, shop.longitude!),
                        width: 50,
                        height: 50,
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
                          child: AnimatedContainer(
                            duration: const Duration(milliseconds: 200),
                            padding: const EdgeInsets.all(6),
                            decoration: BoxDecoration(
                              color: isSelected ? const Color(0xFF1B5E20) : const Color(0xFF2E7D32),
                              shape: BoxShape.circle,
                              border: Border.all(color: Colors.white, width: 2),
                              boxShadow: const [
                                BoxShadow(
                                  color: Colors.black26,
                                  blurRadius: 6,
                                  offset: Offset(0, 3),
                                ),
                              ],
                            ),
                            child: const Icon(
                              Icons.store_rounded,
                              color: Colors.white,
                              size: 20,
                            ),
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

          // 2. ปุ่มลอยมุมบนขวาสำหรับล้างพิกัด และโหลดข้อมูลใหม่
          Positioned(
            right: 16,
            top: 16,
            child: Column(
              children: [
                // ปุ่มโฟกัสตำแหน่งปัจจุบัน
                FloatingActionButton.small(
                  heroTag: 'gps_btn',
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
                  foregroundColor: const Color(0xFF2E7D32),
                  child: const Icon(Icons.my_location),
                ),
                const SizedBox(height: 8),
                // ปุ่มโหลดพิกัดร้านใหม่
                FloatingActionButton.small(
                  heroTag: 'refresh_btn',
                  onPressed: () {
                    ref.invalidate(nearbyShopsProvider);
                  },
                  backgroundColor: Colors.white,
                  foregroundColor: const Color(0xFF2E7D32),
                  child: const Icon(Icons.refresh),
                ),
              ],
            ),
          ),

          // 3. ป๊อปอัพหน้าต่างข้อมูลร้านค้าเมื่อแตะเลือกหมุด
          if (_selectedShop != null)
            Positioned(
              left: 16,
              right: 16,
              bottom: 16,
              child: Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(20),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.1),
                      blurRadius: 15,
                      offset: const Offset(0, 5),
                    ),
                  ],
                ),
                child: Row(
                  children: [
                    // รูปภาพร้านค้า
                    ClipRRect(
                      borderRadius: BorderRadius.circular(12),
                      child: _selectedShop!.imageUrl != null && _selectedShop!.imageUrl!.isNotEmpty
                          ? Image.network(
                              _selectedShop!.imageUrl!,
                              width: 80,
                              height: 80,
                              fit: BoxFit.cover,
                              errorBuilder: (context, error, stackTrace) => Container(
                                width: 80,
                                height: 80,
                                color: Colors.grey.shade100,
                                child: const Icon(Icons.store_rounded, size: 40, color: Colors.grey),
                              ),
                            )
                          : Container(
                              width: 80,
                              height: 80,
                              color: Colors.grey.shade100,
                              child: const Icon(Icons.store_rounded, size: 40, color: Colors.grey),
                            ),
                    ),
                    const SizedBox(width: 16),
                    // ข้อมูลเนื้อหาแบบย่อ
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Text(
                            _selectedShop!.name,
                            style: const TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                              color: Color(0xFF1B5E20),
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            _selectedShop!.address ?? 'ไม่มีที่อยู่ระบุ',
                            style: TextStyle(
                              fontSize: 13,
                              color: Colors.grey.shade600,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                          const SizedBox(height: 8),
                          // ลิงก์ย้ายไปหน้ารายละเอียดร้านแบบเต็ม
                          GestureDetector(
                            onTap: () {
                              ref.read(selectedShopIdProvider.notifier).state = _selectedShop!.shopId;
                              Navigator.push(
                                context,
                                MaterialPageRoute(
                                  builder: (context) => ShopDetailScreen(shop: _selectedShop!),
                                ),
                              );
                            },
                            child: const Row(
                              children: [
                                Text(
                                  'ดูรายละเอียดร้านค้า',
                                  style: TextStyle(
                                    fontSize: 14,
                                    color: Color(0xFF2E7D32),
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                                SizedBox(width: 4),
                                Icon(
                                  Icons.arrow_forward_ios_rounded,
                                  size: 12,
                                  color: Color(0xFF2E7D32),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
        ],
      ),
    );
  }
}
