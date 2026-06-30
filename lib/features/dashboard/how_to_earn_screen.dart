import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/providers/user_provider.dart';

const Color primaryGreen = Color(0xFF2E7D32);

class HowToEarnScreen extends ConsumerWidget {
  const HowToEarnScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final double screenWidth = MediaQuery.of(context).size.width;
    final bool isDesktop = screenWidth > 600;

    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new, color: Colors.black87, size: 20),
          onPressed: () => Navigator.pop(context),
        ),
        title: const Text(
          'วิธีรับ GreenPoint',
          style: TextStyle(
            color: Colors.black87,
            fontWeight: FontWeight.bold,
            fontSize: 16,
          ),
        ),
        centerTitle: true,
      ),
      body: SafeArea(
        child: Column(
          children: [
            Expanded(
              child: SingleChildScrollView(
                physics: const BouncingScrollPhysics(),
                padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
                child: Center(
                  child: Container(
                    constraints: BoxConstraints(maxWidth: isDesktop ? 600 : double.infinity),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // Header Section with Mascot
                        _buildHeader(context),
                        const SizedBox(height: 24),
                        
                        // Steps Section using the real asset images
                        _buildStepCard(
                          context,
                          stepNum: '1',
                          title: 'ซื้อสินค้าที่ร้านพาร์ทเนอร์',
                          description: 'เลือกซื้อสินค้าและชำระเงินตามปกติ',
                          imageAsset: 'assets/images/earn_points/ซื้อสินค้าที่ร้านพาร์ทเนอร์.jpg',
                        ),
                        _buildStepCard(
                          context,
                          stepNum: '2',
                          title: 'ชำระเงินได้ทุกช่องทาง',
                          description: 'ชำระเงินผ่านช่องทางที่คุณสะดวกได้เลย',
                          imageAsset: 'assets/images/earn_points/ชำระเงินได้ทุกช่องทาง.jpg',
                          extraContent: _buildStep2Extra(),
                        ),
                        _buildStepCard(
                          context,
                          stepNum: '3',
                          title: 'ร้านค้าสร้าง QR Code',
                          description: 'หลังชำระเงิน ร้านค้าจะสร้าง QR Code สำหรับรับแต้มโดยระบบคำนวณแต้มให้อัตโนมัติ (10 บาท = 1 GreenPoint)',
                          imageAsset: 'assets/images/earn_points/ร้านค้าสร้าง QR Code.jpg',
                        ),
                        _buildStepCard(
                          context,
                          stepNum: '4',
                          title: 'สแกน QR Code',
                          description: 'เปิดแอป GreenPoint ไปที่เมนู Scan แล้วสแกน QR Code เพื่อรับแต้มเข้าบัญชีทันที',
                          imageAsset: 'assets/images/earn_points/สแกน QR Code.jpg',
                        ),
                        const SizedBox(height: 24),
                        
                        // Bottom Celebration Banner Card
                        _buildMascotAlert(),
                        const SizedBox(height: 24),
                        
                        // FAQ Header
                        const Row(
                          children: [
                            Icon(Icons.help_outline, color: primaryGreen, size: 20),
                            SizedBox(width: 8),
                            Text(
                              'คำถามที่พบบ่อย',
                              style: TextStyle(
                                fontSize: 15,
                                fontWeight: FontWeight.bold,
                                color: Color(0xFF1B5E20),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 16),
                        _buildFAQSection(isDesktop),
                        const SizedBox(height: 20),
                      ],
                    ),
                  ),
                ),
              ),
            ),
            
            // Bottom Action Button
            _buildBottomActionButton(context, ref, isDesktop),
          ],
        ),
      ),
    );
  }

  Widget _buildHeader(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(0xFFF1F8F1),
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: const Color(0xFFC8E6C9), width: 0.5),
      ),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'รับ GreenPoint ได้ง่าย ๆ',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w900,
                    color: Color(0xFF1B5E20),
                  ),
                ),
                const SizedBox(height: 8),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(color: const Color(0xFFC8E6C9), width: 0.5),
                  ),
                  child: const Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(Icons.eco, size: 12, color: primaryGreen),
                      SizedBox(width: 4),
                      Text(
                        'ทุกการใช้จ่าย 10 บาท = 1 GreenPoint',
                        style: TextStyle(
                          color: primaryGreen,
                          fontSize: 10,
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
          Image.asset(
            'assets/images/nong_thung.png',
            width: 72,
            height: 72,
            fit: BoxFit.contain,
            errorBuilder: (context, error, stackTrace) => const Icon(
              Icons.spa_outlined,
              size: 50,
              color: primaryGreen,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStepCard(
    BuildContext context, {
    required String stepNum,
    required String title,
    required String description,
    required String imageAsset,
    Widget? extraContent,
  }) {
    return Container(
      width: double.infinity,
      margin: const EdgeInsets.only(bottom: 16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: Colors.grey.shade200, width: 1),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.02),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(20),
        child: Row(
          children: [
            // Left content side
            Expanded(
              flex: 11,
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.center,
                      children: [
                        Container(
                          width: 24,
                          height: 24,
                          decoration: const BoxDecoration(
                            color: primaryGreen,
                            shape: BoxShape.circle,
                          ),
                          child: Center(
                            child: Text(
                              stepNum,
                              style: const TextStyle(
                                color: Colors.white,
                                fontSize: 12,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            title,
                            style: const TextStyle(
                              color: primaryGreen,
                              fontSize: 13,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    Text(
                      description,
                      style: TextStyle(
                        color: Colors.grey.shade600,
                        fontSize: 10,
                        height: 1.4,
                      ),
                    ),
                    if (extraContent != null) ...[
                      const SizedBox(height: 10),
                      extraContent,
                    ],
                  ],
                ),
              ),
            ),
            
            // Right image illustration side
            Expanded(
              flex: 9,
              child: Container(
                height: 140,
                decoration: BoxDecoration(
                  color: Colors.grey.shade50,
                ),
                child: Image.asset(
                  imageAsset,
                  fit: BoxFit.cover,
                  errorBuilder: (context, error, stackTrace) => Container(
                    color: Colors.grey.shade100,
                    child: const Center(
                      child: Icon(Icons.image_outlined, color: Colors.grey, size: 24),
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStep2Extra() {
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: Row(
        children: [
          _buildPaymentChannelCard(Icons.payments_outlined, 'เงินสด'),
          const SizedBox(width: 6),
          _buildPaymentChannelCard(Icons.qr_code_scanner_outlined, 'พร้อมเพย์'),
          const SizedBox(width: 6),
          _buildPaymentChannelCard(Icons.credit_card_outlined, 'บัตรเครดิต/เดบิต'),
        ],
      ),
    );
  }

  Widget _buildPaymentChannelCard(IconData icon, String label) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 4),
      decoration: BoxDecoration(
        color: const Color(0xFFF5F5F5),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: Colors.grey.shade200, width: 0.5),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 10, color: primaryGreen),
          const SizedBox(width: 3),
          Text(
            label,
            style: const TextStyle(fontSize: 8, color: Color(0xFF333333)),
          ),
        ],
      ),
    );
  }

  Widget _buildMascotAlert() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(0xFFE8F5E9),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: const Color(0xFFC8E6C9), width: 0.5),
      ),
      child: Row(
        children: [
          // Mascot with celebration icon
          Image.asset(
            'assets/images/nong_thung.png',
            height: 60,
            fit: BoxFit.contain,
            errorBuilder: (context, error, stackTrace) => const Icon(
              Icons.party_mode_outlined,
              size: 50,
              color: primaryGreen,
            ),
          ),
          const SizedBox(width: 14),
          const Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Text(
                      '🎉 รับแต้มเรียบร้อยแล้ว!',
                      style: TextStyle(
                        color: Color(0xFF1B5E20),
                        fontSize: 13,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
                SizedBox(height: 4),
                Text(
                  'GreenPoint ได้ถูกเพิ่มเข้าบัญชีของคุณแล้ว\nขอบคุณที่ร่วมเป็นส่วนหนึ่งในการรักษ์โลก ☘️',
                  style: TextStyle(
                    color: Color(0xFF2E7D32),
                    fontSize: 10,
                    height: 1.4,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 8),
          // Globe Icon
          const Icon(
            Icons.public,
            size: 40,
            color: Color(0xFF81C784),
          ),
        ],
      ),
    );
  }

  Widget _buildFAQSection(bool isDesktop) {
    final List<Map<String, String>> faqs = [
      {
        'q': 'สแกน QR Code แล้วแต้มไม่เข้าทำอย่างไร?',
        'a': 'กรุณาตรวจสอบการเชื่อมต่ออินเทอร์เน็ต และลองสแกนใหม่อีกครั้ง หากยังไม่เข้า สามารถแจ้งเลขออเดอร์หรือใบเสร็จได้ที่เมนู "ติดต่อเรา" ในหน้าโปรไฟล์เพื่อดำเนินการตรวจสอบโดยทีมงานฝ่ายสนับสนุนครับ'
      },
      {
        'q': 'GreenPoint มีวันหมดอายุหรือไม่?',
        'a': 'แต้มสะสม GreenPoint จะไม่มีวันหมดอายุตราบใดที่คุณยังล็อกอินเข้าใช้บริการอย่างน้อยปีละ 1 ครั้ง ทำให้คุณสามารถสะสมระยะยาวเพื่อแลกรางวัลพรีเมียมได้อย่างสบายใจครับ'
      },
      {
        'q': 'สามารถนำแต้มไปให้ผู้อื่นได้หรือไม่?',
        'a': 'แต้มสะสมมีผลเฉพาะบัญชีผู้ใช้ส่วนบุคคลเท่านั้น ปัจจุบันระบบยังไม่รองรับการโอนแต้มข้ามบัญชีเพื่อความปลอดภัยในการแลกของรางวัลครับ'
      },
      {
        'q': 'คำนวณแต้มสะสมอย่างไร?',
        'a': 'ระบบจะคำนวณคะแนนให้อัตโนมัติในอัตราส่วน "ยอดใช้จ่ายทุก ๆ 10 บาทหลังหักส่วนลด = 1 GreenPoint" เศษที่ต่ำกว่า 10 บาทจะไม่ถูกนำมาคิดแต้ม'
      },
      {
        'q': 'ใช้ได้กับทุกสินค้าในร้านสมาชิกหรือไม่?',
        'a': 'แต้มสะสมจะได้จากสินค้าทั่วไปและโปรโมชั่นส่วนใหญ่ อย่างไรก็ตาม ผลิตภัณฑ์บางประเภท เช่น เครื่องดื่มแอลกอฮอล์หรือยาสูบ อาจไม่ร่วมรายการสะสมแต้มตามข้อกำหนดกฎหมาย'
      },
      {
        'q': 'แลกรางวัลแล้วจะได้รับของเมื่อไหร่?',
        'a': 'สำหรับการแลกคูปองดิจิทัล คุณจะได้รับโค้ดผ่านแอปทันที แต่หากเป็นรางวัลที่เป็นสิ่งของรักษ์โลก สินค้าจะถูกจัดส่งไปตามที่อยู่ที่ระบุภายใน 3-7 วันทำการครับ'
      },
    ];

    return ListView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      itemCount: faqs.length,
      itemBuilder: (context, index) {
        return _FAQItem(
          question: faqs[index]['q']!,
          answer: faqs[index]['a']!,
        );
      },
    );
  }

  Widget _buildBottomActionButton(BuildContext context, WidgetRef ref, bool isDesktop) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
      decoration: BoxDecoration(
        color: Colors.white,
        border: Border(top: BorderSide(color: Colors.grey.shade100, width: 1)),
      ),
      child: Center(
        child: Container(
          constraints: BoxConstraints(maxWidth: isDesktop ? 600 : double.infinity),
          width: double.infinity,
          height: 48,
          child: ElevatedButton.icon(
            onPressed: () {
              // Set dashboard tab index to 2 (Scan Screen)
              ref.read(activeTabProvider.notifier).state = 2;
              Navigator.pop(context); // Go back to dashboard
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: primaryGreen,
              foregroundColor: Colors.white,
              elevation: 0,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(16),
              ),
            ),
            icon: const Icon(Icons.qr_code_scanner, size: 20),
            label: const Text(
              'เริ่มสแกนรับแต้มเลย',
              style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold),
            ),
          ),
        ),
      ),
    );
  }
}

class _FAQItem extends StatefulWidget {
  final String question;
  final String answer;

  const _FAQItem({required this.question, required this.answer});

  @override
  State<_FAQItem> createState() => _FAQItemState();
}

class _FAQItemState extends State<_FAQItem> {
  bool _isExpanded = false;

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: _isExpanded ? const Color(0xFFC8E6C9) : Colors.grey.shade200,
          width: 1,
        ),
      ),
      child: Theme(
        data: Theme.of(context).copyWith(dividerColor: Colors.transparent),
        child: ExpansionTile(
          title: Text(
            widget.question,
            style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.bold,
              color: _isExpanded ? primaryGreen : const Color(0xFF333333),
            ),
          ),
          onExpansionChanged: (expanded) {
            setState(() {
              _isExpanded = expanded;
            });
          },
          trailing: Icon(
            _isExpanded ? Icons.keyboard_arrow_up : Icons.keyboard_arrow_down,
            color: _isExpanded ? primaryGreen : Colors.grey.shade600,
            size: 20,
          ),
          children: [
            Padding(
              padding: const EdgeInsets.only(left: 16, right: 16, bottom: 16),
              child: Align(
                alignment: Alignment.centerLeft,
                child: Text(
                  widget.answer,
                  style: TextStyle(
                    fontSize: 10,
                    color: Colors.grey.shade600,
                    height: 1.5,
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
