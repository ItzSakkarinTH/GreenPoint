import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import '../../core/models/shop_model.dart';
import '../../core/network/api_service.dart';

const Color primaryGreen = Color(0xFF2E7D32);
const _mapTilerKey = 'vfKDiBWtQ8VIWq7E97HB';

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
                      'https://api.maptiler.com/maps/streets-v2/256/{z}/{x}/{y}.png?key=$_mapTilerKey',
                ),
                MarkerLayer(
                  markers: _shops
                      .where((s) => s.latitude != null && s.longitude != null)
                      .map((shop) => Marker(
                            point: LatLng(shop.latitude!, shop.longitude!),
                            width: 40,
                            height: 40,
                            child: GestureDetector(
                              onTap: () => _showShopInfo(shop),
                              child: const Icon(Icons.store_rounded, color: primaryGreen, size: 36),
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
