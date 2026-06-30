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
                        
                        // Steps Section
                        _buildStepCard(
                          context,
                          stepNum: '1',
                          title: 'ซื้อสินค้าที่ร้านค้าพาร์ทเนอร์',
                          description: 'เลือกซื้อสินค้าและชำระเงินตามปกติ ณ ร้านค้าสมาชิกที่เข้าร่วมรายการ',
                          illustration: _buildStep1Illustration(),
                        ),
                        _buildStepCard(
                          context,
                          stepNum: '2',
                          title: 'ชำระเงินได้ทุกช่องทาง',
                          description: 'ชำระเงินผ่านช่องทางใดก็ได้ที่คุณสะดวก ไม่ว่าจะเป็นเงินสด สแกนจ่าย หรือบัตรเครดิต',
                          illustration: _buildStep2Illustration(),
                        ),
                        _buildStepCard(
                          context,
                          stepNum: '3',
                          title: 'ร้านค้าสร้าง QR Code',
                          description: 'หลังชำระเงิน ร้านค้าจะสร้าง QR Code สำหรับรับแต้มโดยระบบคำนวณให้อัตโนมัติ (10 บาท = 1 GP)',
                          illustration: _buildStep3Illustration(),
                        ),
                        _buildStepCard(
                          context,
                          stepNum: '4',
                          title: 'สแกน QR Code',
                          description: 'เปิดแอป GreenPoint ไปที่เมนู Scan แล้วสแกน QR Code เพื่อรับแต้มเข้าบัญชีของคุณทันที',
                          illustration: _buildStep4Illustration(),
                        ),
                        const SizedBox(height: 24),
                        
                        // Mascot Alert Box
                        _buildMascotAlert(),
                        const SizedBox(height: 24),
                        
                        // FAQ Section
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
            
            // Bottom Button
            _buildBottomActionButton(context, ref, isDesktop),
          ],
        ),
      ),
    );
  }

  Widget _buildHeader(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(0xFFF9FDF9),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: const Color(0xFFE8F5E9)),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'รับ GreenPoint ได้ง่าย ๆ',
                  style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.w900,
                    color: Color(0xFF1B5E20),
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  'เพียงซื้อสินค้าที่ร้านค้าพาร์ทเนอร์ แล้วสแกน QR Code หลังชำระเงิน',
                  style: TextStyle(
                    fontSize: 12,
                    color: Colors.grey.shade600,
                    height: 1.4,
                  ),
                ),
                const SizedBox(height: 12),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                  decoration: BoxDecoration(
                    color: const Color(0xFFE8F5E9),
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: const Color(0xFFC8E6C9), width: 0.5),
                  ),
                  child: const Text(
                    '☘️ ทุกการใช้จ่าย 10 บาท = 1 GreenPoint',
                    style: TextStyle(
                      color: primaryGreen,
                      fontSize: 10,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 8),
          Image.asset(
            'assets/images/nong_thung.png',
            width: 80,
            height: 80,
            fit: BoxFit.contain,
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
    required Widget illustration,
  }) {
    return Container(
      margin: const EdgeInsets.only(bottom: 20),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    Container(
                      width: 20,
                      height: 20,
                      decoration: const BoxDecoration(
                        color: primaryGreen,
                        shape: BoxShape.circle,
                      ),
                      child: Center(
                        child: Text(
                          stepNum,
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 11,
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
                          fontSize: 14,
                          fontWeight: FontWeight.bold,
                          color: Color(0xFF333333),
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 6),
                Padding(
                  padding: const EdgeInsets.only(left: 28),
                  child: Text(
                    description,
                    style: TextStyle(
                      fontSize: 11,
                      color: Colors.grey.shade600,
                      height: 1.4,
                    ),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 16),
          illustration,
        ],
      ),
    );
  }

  Widget _buildStep1Illustration() {
    return Container(
      width: 120,
      height: 80,
      decoration: BoxDecoration(
        color: const Color(0xFFF1F8F1),
        borderRadius: BorderRadius.circular(12),
      ),
      child: const Center(
        child: Icon(Icons.storefront, size: 36, color: primaryGreen),
      ),
    );
  }

  Widget _buildStep2Illustration() {
    return Container(
      width: 120,
      height: 80,
      decoration: BoxDecoration(
        color: const Color(0xFFE3F2FD),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Stack(
        alignment: Alignment.center,
        children: [
          Positioned(
            left: 14,
            child: Icon(Icons.credit_card, size: 24, color: Colors.blue.shade300),
          ),
          Positioned(
            right: 14,
            child: Icon(Icons.qr_code, size: 24, color: Colors.blue.shade400),
          ),
          Container(
            padding: const EdgeInsets.all(4),
            decoration: const BoxDecoration(color: Colors.white, shape: BoxShape.circle),
            child: const Icon(Icons.check, size: 16, color: Colors.green),
          ),
        ],
      ),
    );
  }

  Widget _buildStep3Illustration() {
    return Container(
      width: 120,
      height: 80,
      decoration: BoxDecoration(
        color: const Color(0xFFFFF3E0),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.qr_code_2, size: 32, color: Colors.orange),
            const SizedBox(height: 4),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(4),
                border: Border.all(color: Colors.orange.shade200),
              ),
              child: const Text(
                '15 GP',
                style: TextStyle(fontSize: 8, fontWeight: FontWeight.bold, color: Colors.orange),
              ),
            )
          ],
        ),
      ),
    );
  }

  Widget _buildStep4Illustration() {
    return Container(
      width: 120,
      height: 80,
      decoration: BoxDecoration(
        color: const Color(0xFFE8F5E9),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.qr_code_scanner, size: 28, color: primaryGreen),
            const SizedBox(height: 4),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
              decoration: BoxDecoration(
                color: primaryGreen,
                borderRadius: BorderRadius.circular(6),
              ),
              child: const Text(
                '+15 GP',
                style: TextStyle(color: Colors.white, fontSize: 8, fontWeight: FontWeight.bold),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildMascotAlert() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(0xFFF1F8F1),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: const Color(0xFFC8E6C9),
          width: 1.5,
        ),
      ),
      child: Row(
        children: [
          Image.asset(
            'assets/images/nong_thung.png',
            width: 44,
            height: 44,
            fit: BoxFit.contain,
          ),
          const SizedBox(width: 12),
          const Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  '✨ รับแต้มเรียบร้อยแล้ว!',
                  style: TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.bold,
                    color: Color(0xFF1B5E20),
                  ),
                ),
                SizedBox(height: 2),
                Text(
                  'GreenPoint ได้ถูกเพิ่มเข้าบัญชีของคุณแล้ว ขอบคุณที่ร่วมเป็นส่วนหนึ่งในการรักษ์โลก 🌿',
                  style: TextStyle(
                    fontSize: 10,
                    color: Colors.grey,
                    height: 1.3,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFAQSection(bool isDesktop) {
    const questions1 = [
      {'q': 'แต้มมีอายุการใช้งานหรือไม่?', 'a': 'กรีนพอยท์ของคุณไม่มีวันหมดอายุ สามารถสะสมและเก็บไว้ใช้แลกของรางวัลที่คุณถูกใจได้ทุกเมื่อ!'},
      {'q': 'คะแนนสะสมไม่เข้า ต้องทำอย่างไร?', 'a': 'หากแต้มไม่เข้าภายใน 24 ชม. กรุณาติดต่อฝ่ายบริการลูกค้าผ่านเมนูโปรไฟล์ หรือแนบหลักฐานใบเสร็จชำระเงินเพื่อตรวจสอบ'},
      {'q': 'แต้มคำนวณอย่างไร?', 'a': 'คำนวณตามยอดใช้จ่ายจริงที่ร้านพาร์ทเนอร์ โดยทุกๆ 10 บาท จะได้รับ 1 GreenPoint (เศษของ 10 บาทจะไม่ถูกนำมาคิดคะแนน)'},
    ];
    
    const questions2 = [
      {'q': 'ร้านค้าใดเข้าร่วมโครงการบ้าง?', 'a': 'คุณสามารถตรวจสอบรายชื่อร้านค้าพาร์ทเนอร์ทั้งหมดได้ที่แท็บ "Partner Store" ในแอปพลิเคชัน'},
      {'q': 'แลกของรางวัลได้ที่ไหน?', 'a': 'สามารถแลกรับของรางวัลได้ผ่านเมนูแลกของรางวัลในหน้าแรก (Home) หรือกดดูของรางวัลทั้งหมดในหน้ารายละเอียดของแต่ละร้านค้า'},
      {'q': 'ต้องสแกนภายในระยะเวลากี่วัน?', 'a': 'แนะนำให้สแกน QR Code ทันทีหลังจากชำระเงิน หรือสแกนภายใน 3 วันนับจากวันที่ออกใบเสร็จรับเงิน'},
    ];

    if (isDesktop) {
      return Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(
            child: Column(
              children: questions1.map((item) => FAQItemWidget(question: item['q']!, answer: item['a']!)).toList(),
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              children: questions2.map((item) => FAQItemWidget(question: item['q']!, answer: item['a']!)).toList(),
            ),
          ),
        ],
      );
    }

    return Column(
      children: [
        ...questions1.map((item) => FAQItemWidget(question: item['q']!, answer: item['a']!)),
        ...questions2.map((item) => FAQItemWidget(question: item['q']!, answer: item['a']!)),
      ],
    );
  }

  Widget _buildBottomActionButton(BuildContext context, WidgetRef ref, bool isDesktop) {
    return Container(
      padding: const EdgeInsets.all(20),
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
      child: Center(
        child: Container(
          constraints: BoxConstraints(maxWidth: isDesktop ? 400 : double.infinity),
          width: double.infinity,
          height: 48,
          child: ElevatedButton.icon(
            onPressed: () {
              ref.read(activeTabProvider.notifier).state = 2;
              Navigator.pop(context);
            },
            icon: const Icon(Icons.qr_code_scanner, size: 20),
            label: const Text(
              'เริ่มสแกนรับแต้มเลย',
              style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.bold,
              ),
            ),
            style: ElevatedButton.styleFrom(
              backgroundColor: primaryGreen,
              foregroundColor: Colors.white,
              elevation: 0,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class FAQItemWidget extends StatefulWidget {
  final String question;
  final String answer;

  const FAQItemWidget({
    super.key,
    required this.question,
    required this.answer,
  });

  @override
  State<FAQItemWidget> createState() => _FAQItemWidgetState();
}

class _FAQItemWidgetState extends State<FAQItemWidget> {
  bool _isExpanded = false;

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.grey.shade200),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          InkWell(
            onTap: () {
              setState(() {
                _isExpanded = !_isExpanded;
              });
            },
            borderRadius: BorderRadius.circular(12),
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Expanded(
                    child: Text(
                      widget.question,
                      style: const TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.bold,
                        color: Color(0xFF333333),
                      ),
                    ),
                  ),
                  Icon(
                    _isExpanded ? Icons.keyboard_arrow_up : Icons.keyboard_arrow_down,
                    size: 18,
                    color: Colors.grey,
                  ),
                ],
              ),
            ),
          ),
          if (_isExpanded)
            Padding(
              padding: const EdgeInsets.only(left: 16, right: 16, bottom: 12),
              child: Text(
                widget.answer,
                style: TextStyle(
                  fontSize: 11,
                  color: Colors.grey.shade600,
                  height: 1.4,
                ),
              ),
            ),
        ],
      ),
    );
  }
}
