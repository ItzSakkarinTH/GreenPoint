import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import '../../core/models/shop_model.dart';
import '../../core/network/api_service.dart';

const Color primaryGreen = Color(0xFF2E7D32);
const _mapTilerKey = 'UoM6D3yOMbD8SnI8vcW9';

class MapScreen extends StatefulWidget {
  const MapScreen({super.key});

  @override
  State<MapScreen> createState() => _MapScreenState();
}

class _MapScreenState extends State<MapScreen> {
  List<Shop> _shops = [];
  bool _loading = true;
  final LatLng _center = const LatLng(13.7563, 100.5018);

  @override
  void initState() {
    super.initState();
    _loadNearbyShops();
  }

  Future<void> _loadNearbyShops() async {
    try {
      final data = await ApiService().getNearbyShops(_center.latitude, _center.longitude);
      setState(() {
        _shops = data.map((json) => Shop.fromJson(json as Map<String, dynamic>)).toList();
        _loading = false;
      });
    } catch (e) {
      setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('ร้านค้าใกล้คุณ', style: TextStyle(color: primaryGreen, fontWeight: FontWeight.bold)),
        backgroundColor: Colors.white,
        elevation: 0,
        iconTheme: const IconThemeData(color: primaryGreen),
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator(color: primaryGreen))
          : FlutterMap(
              options: MapOptions(initialCenter: _center, initialZoom: 13),
              children: [
                TileLayer(
                  urlTemplate:
                      'https://api.maptiler.com/maps/streets-v2/{z}/{x}/{y}.png?key=$_mapTilerKey',
                ),
                MarkerLayer(
                  markers: _shops
                      .where((s) => s.latitude != null && s.longitude != null)
                      .map((shop) => Marker(
                            point: LatLng(shop.latitude!, shop.longitude!),
                            width: 60,
                            height: 65,
                            child: GestureDetector(
                              onTap: () => _showShopInfo(shop),
                              child: Stack(
                                alignment: Alignment.center,
                                children: [
                                  // 1. ไอคอนพินแผนที่สีเขียวเป็นพื้นหลังด้านล่าง
                                  const Icon(
                                    Icons.location_on,
                                    size: 55,
                                    color: Color(0xFF2E7D32), // สีเขียว GreenPoint
                                  ),
                                  // 2. รูปโลโก้/โปรไฟล์ร้านวงกลมตรงกลางพิน
                                  Positioned(
                                    top: 5,
                                    child: Container(
                                      width: 28,
                                      height: 28,
                                      decoration: const BoxDecoration(
                                        shape: BoxShape.circle,
                                        color: Colors.white,
                                      ),
                                      padding: const EdgeInsets.all(1.5),
                                      child: ClipOval(
                                        child: shop.logoUrl.isNotEmpty
                                            ? Image.network(shop.logoUrl, fit: BoxFit.cover)
                                            : (shop.imageUrl.isNotEmpty
                                                ? Image.network(shop.imageUrl, fit: BoxFit.cover)
                                                : const Icon(Icons.store, size: 16, color: Colors.grey)),
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ))
                      .toList(),
                ),
              ],
            ),
    );
  }

  void _showShopInfo(Shop shop) {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
      builder: (_) => Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(shop.name, style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
            if (shop.address != null) ...[
              const SizedBox(height: 6),
              Text(shop.address!, style: const TextStyle(color: Colors.grey)),
            ],
            if (shop.phone != null) ...[
              const SizedBox(height: 4),
              Text(shop.phone!, style: const TextStyle(color: Colors.grey)),
            ],
          ],
        ),
      ),
    );
  }
}
