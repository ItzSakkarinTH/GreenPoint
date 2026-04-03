import 'package:flutter/material.dart';

import 'package:share_plus/share_plus.dart';

const Color primaryGreen = Color(0xFF2E7D32);
const Color backgroundLightGreen = Color(0xFFDCEDC8);

class StreakScreen extends StatelessWidget {
  final int plasticCount;
  final int streakCount;
  const StreakScreen({super.key, required this.plasticCount, this.streakCount = 0});

  void _shareToFacebook() {
    Share.share(
      'รักษ์โลกกับ GreenPoint! ฉันสแกนลดพลาสติกสะสมได้ $plasticCount ชิ้น และรักษา Streak ได้ต่อเนื่อง $streakCount วันแล้ว! 🔥✨ #GreenPoint #EcoFriendly',
      subject: 'GreenPoint Streak Share',
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.black87),
          onPressed: () => Navigator.pop(context),
        ),
        backgroundColor: Colors.white,
        elevation: 0,
        title: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(4),
              decoration: const BoxDecoration(
                color: primaryGreen,
                shape: BoxShape.circle,
              ),
              child: const Icon(Icons.eco, color: Colors.white, size: 16),
            ),
            const SizedBox(width: 8),
            const Text(
              'GreenPoint',
              style: TextStyle(
                color: primaryGreen,
                fontWeight: FontWeight.w900,
                fontSize: 18,
              ),
            ),
          ],
        ),
      ),
      body: SingleChildScrollView(
        child: Container(
          width: double.infinity,
          margin: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            color: const Color(0xFFD4E7C5), // Light mint green from design
            borderRadius: BorderRadius.circular(30),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.1),
                blurRadius: 10,
                offset: const Offset(0, 5),
              ),
            ],
          ),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            mainAxisSize: MainAxisSize.min,
            children: [
              const SizedBox(height: 40),
              // Daily Streak Section
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(Icons.fireplace, color: Colors.orange, size: 40),
                  const SizedBox(width: 8),
                  Text(
                    'Daily Streak: $streakCount วัน',
                    style: const TextStyle(
                      fontSize: 22,
                      fontWeight: FontWeight.w900,
                      color: Color(0xFFE65100),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 20),
              const Text(
                'สะสมลดพลาสติกมาแล้ว',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: Colors.black87,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                '$plasticCount',
                style: const TextStyle(
                  fontSize: 70,
                  fontWeight: FontWeight.w900,
                  color: Colors.black87,
                ),
              ),
              const SizedBox(height: 30),
              // Mascot
              Image.asset(
                'assets/images/nong_thung.png',
                height: 180,
                fit: BoxFit.contain,
                errorBuilder: (context, error, stackTrace) => const Icon(Icons.eco, size: 150, color: primaryGreen),
              ),
              const SizedBox(height: 20),
              const Padding(
                padding: EdgeInsets.symmetric(horizontal: 30),
                child: Text(
                  'มาช่วยโลกกันเถอะ! สแกนรับ GP รักษา Streak ทุกวันนะ',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: Colors.black54,
                  ),
                ),
              ),
              const SizedBox(height: 50),
              ElevatedButton.icon(
                onPressed: _shareToFacebook,
                icon: const Text('แชร์ไปยังเฟซบุ๊ค', style: TextStyle(fontWeight: FontWeight.bold)),
                label: const Icon(Icons.facebook, size: 30),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.white,
                  foregroundColor: Colors.blue[800],
                  elevation: 5,
                  padding: const EdgeInsets.symmetric(horizontal: 40, vertical: 15),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(15),
                  ),
                ),
              ),
              const SizedBox(height: 40),
            ],
          ),
        ),
      ),
    );
  }
}
