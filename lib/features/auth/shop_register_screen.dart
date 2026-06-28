import 'dart:convert';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import 'package:geolocator/geolocator.dart';
import 'package:image_picker/image_picker.dart';
import 'package:http/http.dart' as http;

class ShopRegisterScreen extends StatefulWidget {
  final String apiBaseUrl; // URL ของ Backend เช่น 'https://your-api.vercel.app'

  const ShopRegisterScreen({super.key, required this.apiBaseUrl});

  @override
  State<ShopRegisterScreen> createState() => _ShopRegisterScreenState();
}

class _ShopRegisterScreenState extends State<ShopRegisterScreen> {
  final _formKey = GlobalKey<FormState>();
  final MapController _mapController = MapController();

  // ตัวควบคุมช่องกรอกข้อมูล (Text Field Controllers)
  final TextEditingController _usernameController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();
  final TextEditingController _shopNameController = TextEditingController();
  final TextEditingController _phoneController = TextEditingController();
  final TextEditingController _descController = TextEditingController();
  final TextEditingController _addressController = TextEditingController();

  // ข้อมูลของภาพถ่ายและโปรเจกต์รักษ์โลก
  File? _imageFile;
  File? _logoFile; // 🏪 รูปโปรไฟล์ร้านค้า
  bool _noPlasticBag = false; // ♻️ เข้าร่วมโครงการไม่รับถุงพลาสติก
  int _rewardPoints = 10;    // แต้มที่ลูกค้าจะได้รับต่อครั้ง (5, 10, 20 แต้ม)

  // พิกัดร้านค้าสำหรับแสดงแผนที่ (ส่งแบบซ่อนไว้หลังบ้าน)
  LatLng _selectedLatLng = const LatLng(13.7563, 100.5018); // พิกัดเริ่มต้น (กรุงเทพฯ)
  bool _isMapLoading = false;
  bool _isSubmitting = false;

  // MapTiler API Key ที่ใช้อ้างอิงแผนที่
  final String mapTilerKey = 'UoM6D3yOMbD8SnI8vcW9';

  @override
  void dispose() {
    _usernameController.dispose();
    _passwordController.dispose();
    _shopNameController.dispose();
    _phoneController.dispose();
    _descController.dispose();
    _addressController.dispose();
    super.dispose();
  }

  // --- ฟังก์ชันเลือกรูปภาพจากแกลเลอรี ---
  Future<void> _pickImage() async {
    final ImagePicker picker = ImagePicker();
    final XFile? image = await picker.pickImage(
      source: ImageSource.gallery,
      maxWidth: 800,
      maxHeight: 800,
      imageQuality: 85,
    );

    if (image != null) {
      setState(() {
        _imageFile = File(image.path);
      });
    }
  }

  // --- ฟังก์ชันเลือกรูปภาพโปรไฟล์ (Logo) จากแกลเลอรี ---
  Future<void> _pickLogo() async {
    final ImagePicker picker = ImagePicker();
    final XFile? image = await picker.pickImage(
      source: ImageSource.gallery,
      maxWidth: 400,
      maxHeight: 400,
      imageQuality: 85,
    );

    if (image != null) {
      setState(() {
        _logoFile = File(image.path);
      });
    }
  }

  // --- ฟังก์ชันอัปโหลดรูปภาพไปยัง API และรับ URL กลับมา ---
  Future<String?> _uploadImage(File file) async {
    try {
      final bytes = await file.readAsBytes();
      final base64Image = base64Encode(bytes);
      final extension = file.path.split('.').last.toLowerCase();
      final dataUri = 'data:image/$extension;base64,$base64Image';

      final response = await http.post(
        Uri.parse('${widget.apiBaseUrl}/api/upload'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({'file': dataUri}),
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        return data['url'];
      }
      return null;
    } catch (e) {
      debugPrint('Error uploading image: $e');
      return null;
    }
  }

  // --- ฟังก์ชันดึงพิกัดปัจจุบัน (GPS) ---
  Future<void> _useCurrentLocation() async {
    setState(() => _isMapLoading = true);
    try {
      LocationPermission permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
        if (permission == LocationPermission.denied) {
          _showSnackBar('กรุณาอนุญาตการเข้าถึงพิกัดของคุณ');
          return;
        }
      }

      if (permission == LocationPermission.deniedForever) {
        _showSnackBar('การตั้งค่าพิกัดถูกปฏิเสธถาวร กรุณาแก้ไขในการตั้งค่าเครื่อง');
        return;
      }

      Position position = await Geolocator.getCurrentPosition(
        locationSettings: const LocationSettings(
          accuracy: LocationAccuracy.high,
        ),
      );

      setState(() {
        _selectedLatLng = LatLng(position.latitude, position.longitude);
      });

      _mapController.move(_selectedLatLng, 15.0);
    } catch (e) {
      _showSnackBar('ไม่สามารถดึงตำแหน่งปัจจุบันได้: $e');
    } finally {
      setState(() => _isMapLoading = false);
    }
  }

  // --- ฟังก์ชันค้นหาพิกัดจากข้อความที่อยู่ผ่าน MapTiler ---
  Future<void> _searchAddress() async {
    final query = _addressController.text.trim();
    if (query.isEmpty) {
      _showSnackBar('กรุณากรอกที่อยู่เพื่อค้นหา');
      return;
    }

    setState(() => _isMapLoading = true);
    try {
      final response = await http.get(
        Uri.parse('${widget.apiBaseUrl}/api/maptiler/geocode?address=${Uri.encodeComponent(query)}'),
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        if (data['success'] == true) {
          final double lat = data['latitude'];
          final double lng = data['longitude'];

          setState(() {
            _selectedLatLng = LatLng(lat, lng);
          });
          _mapController.move(_selectedLatLng, 15.0);
          _showSnackBar('ค้นหาพิกัดสำเร็จ!');
        } else {
          _showSnackBar('ไม่พบพิกัดสำหรับที่อยู่นี้');
        }
      } else {
        _showSnackBar('เกิดข้อผิดพลาดในการเชื่อมต่อเซิร์ฟเวอร์ค้นหา');
      }
    } catch (e) {
      _showSnackBar('เกิดข้อผิดพลาด: $e');
    } finally {
      setState(() => _isMapLoading = false);
    }
  }

  // --- ฟังก์ชันบันทึกข้อมูลสมัครสมาชิกร้านค้า ---
  Future<void> _registerShop() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isSubmitting = true);

    try {
      // 1. อัปโหลดรูปภาพโปรไฟล์ (Logo) ก่อน (หากเลือกไว้)
      String finalLogoUrl = '';
      if (_logoFile != null) {
        _showSnackBar('กำลังอัปโหลดรูปโปรไฟล์ร้านค้า...');
        final url = await _uploadImage(_logoFile!);
        if (url != null) {
          finalLogoUrl = url;
        }
      }

      // 2. อัปโหลดรูปภาพปกหน้าร้าน (Cover)
      String finalImageUrl = '';
      if (_imageFile != null) {
        _showSnackBar('กำลังอัปโหลดรูปปกร้านค้า...');
        final url = await _uploadImage(_imageFile!);
        if (url != null) {
          finalImageUrl = url;
        } else {
          _showSnackBar('ไม่สามารถอัปโหลดรูปภาพปกได้ จะดำเนินการต่อโดยไม่มีรูปภาพปก');
        }
      }

      // 3. ส่งข้อมูลสมัครสมาชิกไปยัง Backend API
      final payload = {
        'username': _usernameController.text.trim(),
        'password': _passwordController.text.trim(),
        'name': _shopNameController.text.trim(),
        'imageUrl': finalImageUrl,
        'logoUrl': finalLogoUrl,
        'phone': _phoneController.text.trim(),
        'description': _descController.text.trim(),
        'address': _addressController.text.trim(),
        'latitude': _selectedLatLng.latitude,   // พิกัด Lat ซ่อนไว้หลังบ้าน
        'longitude': _selectedLatLng.longitude, // พิกัด Lng ซ่อนไว้หลังบ้าน
        'noPlasticBag': _noPlasticBag,
        'rewardPoints': _rewardPoints,
      };

      _showSnackBar('กำลังสร้างบัญชีร้านค้า...');
      final response = await http.post(
        Uri.parse('${widget.apiBaseUrl}/api/shops/register'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode(payload),
      );

      final result = jsonDecode(response.body);

      if (response.statusCode == 201 && result['success'] == true) {
        _showSuccessDialog(result['message'] ?? 'สมัครสมาชิกสำเร็จ!');
      } else {
        _showSnackBar(result['error'] ?? 'เกิดข้อผิดพลาดในการสมัครสมาชิก');
      }
    } catch (e) {
      _showSnackBar('ไม่สามารถเชื่อมต่อเซิร์ฟเวอร์ได้: $e');
    } finally {
      setState(() => _isSubmitting = false);
    }
  }

  void _showSnackBar(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message), duration: const Duration(seconds: 3)),
    );
  }

  void _showSuccessDialog(String message) {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
        title: const Row(
          children: [
            Icon(Icons.check_circle, color: Colors.green, size: 28),
            SizedBox(width: 10),
            Text('สำเร็จ'),
          ],
        ),
        content: Text(message),
        actions: [
          TextButton(
            onPressed: () {
              Navigator.of(ctx).pop();
              Navigator.of(context).pop(); // ย้อนกลับไปหน้าก่อนหน้า (เช่น หน้า Login)
            },
            child: const Text('ตกลง', style: TextStyle(color: Colors.green, fontWeight: FontWeight.bold)),
          )
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    const primaryColor = Color(0xFF2E7D32); // สีเขียวรักษ์โลกหลัก
    const accentColor = Color(0xFF81C784);  // สีเขียวอ่อน

    return Scaffold(
      appBar: AppBar(
        title: const Text('ลงทะเบียนร้านค้าใหม่'),
        backgroundColor: primaryColor,
        foregroundColor: Colors.white,
      ),
      body: Stack(
        children: [
          SingleChildScrollView(
            padding: const EdgeInsets.all(16.0),
            child: Form(
              key: _formKey,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // --- ส่วนที่ 1: ข้อมูลบัญชีผู้ใช้ ---
                  _buildSectionTitle('🔐 ข้อมูลบัญชีผู้ใช้'),
                  const SizedBox(height: 8),
                  TextFormField(
                    controller: _usernameController,
                    decoration: const InputDecoration(
                      labelText: 'Username (บัญชีร้านค้า)',
                      border: OutlineInputBorder(),
                      prefixIcon: Icon(Icons.person),
                    ),
                    validator: (val) => (val == null || val.length < 4) ? 'Username ต้องมีอย่างน้อย 4 ตัวอักษร' : null,
                  ),
                  const SizedBox(height: 12),
                  TextFormField(
                    controller: _passwordController,
                    obscureText: true,
                    decoration: const InputDecoration(
                      labelText: 'Password',
                      border: OutlineInputBorder(),
                      prefixIcon: Icon(Icons.lock),
                    ),
                    validator: (val) => (val == null || val.length < 6) ? 'Password ต้องมีอย่างน้อย 6 ตัวอักษร' : null,
                  ),
                  const SizedBox(height: 24),

                  // --- ส่วนที่ 2: โปรไฟล์ร้านค้า ---
                  _buildSectionTitle('🏪 ข้อมูลร้านค้า'),
                  const SizedBox(height: 12),
                  
                  // พื้นที่เลือกรูปภาพโปรไฟล์ร้านค้า (Logo) และรูปหน้าปก (Cover) จัดวางแบบมืออาชีพ
                  Center(
                    child: Column(
                      children: [
                        // 1. ปุ่มเลือกรูปโปรไฟล์ร้านค้า (วงกลม)
                        GestureDetector(
                          onTap: _pickLogo,
                          child: Stack(
                            children: [
                              Container(
                                width: 100,
                                height: 100,
                                decoration: BoxDecoration(
                                  color: Colors.grey[200],
                                  shape: BoxShape.circle,
                                  border: Border.all(color: primaryColor, width: 2),
                                  boxShadow: const [
                                    BoxShadow(
                                      color: Colors.black12,
                                      blurRadius: 6,
                                      offset: Offset(0, 3),
                                    )
                                  ]
                                ),
                                child: _logoFile != null
                                    ? ClipOval(
                                        child: Image.file(_logoFile!, fit: BoxFit.cover),
                                      )
                                    : const Column(
                                        mainAxisAlignment: MainAxisAlignment.center,
                                        children: [
                                          Icon(Icons.store, size: 36, color: primaryColor),
                                          SizedBox(height: 2),
                                          Text(
                                            'รูปโปรไฟล์',
                                            style: TextStyle(color: primaryColor, fontSize: 10, fontWeight: FontWeight.bold),
                                          ),
                                        ],
                                      ),
                              ),
                              Positioned(
                                bottom: 0,
                                right: 0,
                                child: Container(
                                  padding: const EdgeInsets.all(4),
                                  decoration: const BoxDecoration(
                                    color: primaryColor,
                                    shape: BoxShape.circle,
                                  ),
                                  child: const Icon(Icons.camera_alt, color: Colors.white, size: 16),
                                ),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(height: 8),
                        const Text(
                          'รูปโปรไฟล์ร้านค้า (แสดงบนแผนที่และหน้ารายชื่อ)',
                          style: TextStyle(color: Colors.grey, fontSize: 12, fontWeight: FontWeight.bold),
                        ),
                        const SizedBox(height: 20),

                        // 2. ปุ่มเลือกรูปปกหน้าร้านค้า (สี่เหลี่ยม)
                        GestureDetector(
                          onTap: _pickImage,
                          child: Container(
                            width: double.infinity,
                            height: 150,
                            decoration: BoxDecoration(
                              color: Colors.grey[200],
                              borderRadius: BorderRadius.circular(12),
                              border: Border.all(color: Colors.grey[400]!),
                            ),
                            child: _imageFile != null
                                ? ClipRRect(
                                    borderRadius: BorderRadius.circular(12),
                                    child: Image.file(_imageFile!, fit: BoxFit.cover),
                                  )
                                : const Column(
                                    mainAxisAlignment: MainAxisAlignment.center,
                                    children: [
                                      Icon(Icons.add_a_photo, size: 32, color: primaryColor),
                                      SizedBox(height: 6),
                                      Text(
                                        'คลิกเพื่อเลือกรูปหน้าปก/รูปภาพหน้าร้าน',
                                        style: TextStyle(color: Colors.grey, fontSize: 13),
                                      ),
                                    ],
                                  ),
                          ),
                        ),
                        const SizedBox(height: 6),
                        const Text(
                          'รูปปกหน้าร้านค้า (แสดงในหน้ารายละเอียดร้าน)',
                          style: TextStyle(color: Colors.grey, fontSize: 12),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 20),
                  
                  TextFormField(
                    controller: _shopNameController,
                    decoration: const InputDecoration(
                      labelText: 'Shop Name (ชื่อร้านค้า)',
                      border: OutlineInputBorder(),
                      prefixIcon: Icon(Icons.store),
                    ),
                    validator: (val) => (val == null || val.isEmpty) ? 'กรุณากรอกชื่อร้านค้า' : null,
                  ),
                  const SizedBox(height: 12),
                  TextFormField(
                    controller: _phoneController,
                    keyboardType: TextInputType.phone,
                    decoration: const InputDecoration(
                      labelText: 'Phone (เบอร์โทรศัพท์)',
                      border: OutlineInputBorder(),
                      prefixIcon: Icon(Icons.phone),
                    ),
                    validator: (val) => (val == null || val.isEmpty) ? 'กรุณากรอกเบอร์โทรศัพท์' : null,
                  ),
                  const SizedBox(height: 12),
                  TextFormField(
                    controller: _descController,
                    maxLines: 2,
                    decoration: const InputDecoration(
                      labelText: 'Description (คำอธิบายร้านค้า - ไม่บังคับ)',
                      border: OutlineInputBorder(),
                      alignLabelWithHint: true,
                      prefixIcon: Icon(Icons.description),
                    ),
                  ),
                  const SizedBox(height: 24),

                  // --- ส่วนที่ 3: แผนที่และที่อยู่ร้านค้า ---
                  _buildSectionTitle('📍 ตำแหน่งร้านค้า'),
                  const SizedBox(height: 8),
                  TextFormField(
                    controller: _addressController,
                    decoration: const InputDecoration(
                      labelText: 'Address (ที่อยู่ร้าน)',
                      border: OutlineInputBorder(),
                      prefixIcon: Icon(Icons.location_on),
                    ),
                    validator: (val) => (val == null || val.isEmpty) ? 'กรุณากรอกที่อยู่ร้านค้า' : null,
                  ),
                  const SizedBox(height: 12),
                  
                  // ปุ่มพิกัด GPS ปัจจุบัน & ปุ่มค้นหาที่อยู่
                  Row(
                    children: [
                      Expanded(
                        child: ElevatedButton.icon(
                          onPressed: _useCurrentLocation,
                          icon: const Icon(Icons.my_location, size: 18),
                          label: const Text('ใช้ตำแหน่งปัจจุบัน', style: TextStyle(fontSize: 12)),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.blue[700],
                            foregroundColor: Colors.white,
                            padding: const EdgeInsets.symmetric(vertical: 12),
                          ),
                        ),
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: ElevatedButton.icon(
                          onPressed: _searchAddress,
                          icon: const Icon(Icons.search, size: 18),
                          label: const Text('ค้นหาที่อยู่', style: TextStyle(fontSize: 12)),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.orange[700],
                            foregroundColor: Colors.white,
                            padding: const EdgeInsets.symmetric(vertical: 12),
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),

                  // แผนที่แสดงและลากพิกัดร้านค้า (หมุดปักอยู่ตรงกลาง ย้ายโดยการเลื่อนแผนที่)
                  Container(
                    height: 250,
                    decoration: BoxDecoration(
                      border: Border.all(color: Colors.grey),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    clipBehavior: Clip.antiAlias,
                    child: Stack(
                      children: [
                        FlutterMap(
                          mapController: _mapController,
                          options: MapOptions(
                            initialCenter: _selectedLatLng,
                            initialZoom: 15.0,
                            onPositionChanged: (position, hasGesture) {
                              if (hasGesture) {
                                // เมื่อเลื่อนแผนที่ จะอัปเดตตัวแปรพิกัดอัตโนมัติ (ซ่อนหลังบ้าน)
                                setState(() {
                                  _selectedLatLng = position.center;
                                });
                              }
                            },
                          ),
                          children: [
                            TileLayer(
                              urlTemplate: 'https://api.maptiler.com/maps/basic-v2/{z}/{x}/{y}.png?key=$mapTilerKey',
                              userAgentPackageName: 'com.itzsakkarinth.greenpoint',
                            ),
                          ],
                        ),
                        
                        // หมุดปักสีแดงตรึงอยู่กึ่งกลางหน้าจอแผนที่
                        Center(
                          child: Container(
                            margin: const EdgeInsets.only(bottom: 35),
                            child: const Icon(
                              Icons.location_pin,
                              color: Colors.red,
                              size: 45,
                            ),
                          ),
                        ),

                        // แสดง Loading หมุนตอนโหลดแผนที่
                        if (_isMapLoading)
                          Container(
                            color: Colors.black26,
                            child: const Center(child: CircularProgressIndicator()),
                          ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 6),
                  const Center(
                    child: Text(
                      'ลาก/เลื่อนแผนที่เพื่อปรับแต่งตำแหน่งพิกัดร้านค้า',
                      style: TextStyle(color: Colors.grey, fontSize: 12, fontStyle: FontStyle.italic),
                    ),
                  ),
                  const SizedBox(height: 24),

                  // --- ส่วนที่ 4: ตัวเลือกด้านรักษ์โลก ---
                  _buildSectionTitle('♻️ โครงการรักษ์โลก'),
                  const SizedBox(height: 8),
                  
                  // ปุ่มเช็คบ็อกซ์โครงการไม่รับถุงพลาสติก
                  Card(
                    color: Colors.green[50],
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                    child: CheckboxListTile(
                      activeColor: primaryColor,
                      title: const Text(
                        'เข้าร่วมโครงการไม่รับถุงพลาสติก',
                        style: TextStyle(fontWeight: FontWeight.bold, color: primaryColor),
                      ),
                      subtitle: const Text('ลูกค้าจะไม่ได้รับถุงพลาสติกจากร้านค้านี้'),
                      value: _noPlasticBag,
                      onChanged: (val) {
                        setState(() {
                          _noPlasticBag = val ?? false;
                        });
                      },
                    ),
                  ),
                  const SizedBox(height: 16),

                  // ส่วนการให้คะแนนลูกค้า (5, 10, 20 แต้ม)
                  const Text(
                    'จำนวนแต้มที่ลูกค้าจะได้รับต่อการซื้อสินค้า',
                    style: TextStyle(fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 8),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceAround,
                    children: [5, 10, 20].map((points) {
                      final isSelected = _rewardPoints == points;
                      return ChoiceChip(
                        selectedColor: accentColor,
                        label: Text(
                          '$points แต้ม',
                          style: TextStyle(
                            color: isSelected ? Colors.black : Colors.black87,
                            fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                          ),
                        ),
                        selected: isSelected,
                        onSelected: (selected) {
                          if (selected) {
                            setState(() {
                              _rewardPoints = points;
                            });
                          }
                        },
                      );
                    }).toList(),
                  ),
                  const SizedBox(height: 32),

                  // --- ปุ่มส่งข้อมูลสมัครร้านค้า ---
                  SizedBox(
                    width: double.infinity,
                    height: 50,
                    child: ElevatedButton(
                      onPressed: _isSubmitting ? null : _registerShop,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: primaryColor,
                        foregroundColor: Colors.white,
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                      ),
                      child: _isSubmitting
                          ? const CircularProgressIndicator(color: Colors.white)
                          : const Text(
                              'สร้างบัญชีร้านค้า (Create Shop Account)',
                              style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                            ),
                    ),
                  ),
                  const SizedBox(height: 20),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSectionTitle(String title) {
    return Text(
      title,
      style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.black87),
    );
  }
}
