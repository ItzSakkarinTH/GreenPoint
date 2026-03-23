import 'package:flutter/material.dart';

const Color primaryGreen = Color(0xFF2E7D32);
const Color backgroundLightGreen = Color(0xFFDCEDC8);

class StreakScreen extends StatelessWidget {
  final int plasticCount;
  const StreakScreen({super.key, required this.plasticCount});

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
          ),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            mainAxisSize: MainAxisSize.min, // Use min to avoid stretching in SingleChildScrollView
            children: [
              const SizedBox(height: 40),
              const Text(
                'ลดพลาสติกมาแล้ว',
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
                  fontSize: 80,
                  fontWeight: FontWeight.w900,
                  color: Colors.black87,
                ),
              ),
              const SizedBox(height: 40),
              // Mascot
              Image.asset(
                'assets/images/nong_thung.png',
                height: 200,
                fit: BoxFit.contain,
              ),
              const SizedBox(height: 40),
              const Text(
                'น้องถุงสุดน่ารัก',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: Colors.black87,
                ),
              ),
              const SizedBox(height: 60),
              ElevatedButton.icon(
                onPressed: () {},
                icon: const Text('แชร์ยังเฟซบุ๊ค', style: TextStyle(fontWeight: FontWeight.bold)),
                label: const Icon(Icons.facebook, size: 30),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.white,
                  foregroundColor: Colors.black,
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
