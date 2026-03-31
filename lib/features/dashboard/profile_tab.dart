import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/providers/user_provider.dart';
import '../../core/providers/auth_provider.dart';
import '../../core/models/user_model.dart';
import 'streak_screen.dart';

const Color primaryGreen = Color(0xFF2E7D32);
const Color secondaryGreen = Color(0xFF4CAF50);

class ProfileTab extends ConsumerWidget {
  const ProfileTab({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final profileAsync = ref.watch(userProfileProvider);
    final historyAsync = ref.watch(historyProvider);

    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        centerTitle: false,
        title: Row(
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
                fontSize: 22,
              ),
            ),
          ],
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.settings, color: primaryGreen),
            onPressed: () {},
          ),
        ],
      ),
      body: profileAsync.when(
        data: (profile) => SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 24),
          child: Column(
            children: [
              const SizedBox(height: 20),
              // User Info
              const CircleAvatar(
                radius: 55,
                backgroundColor: Color(0xFFF1F1F1),
                child: Icon(Icons.person, size: 70, color: Colors.grey),
              ),
              const SizedBox(height: 12),
              Text(
                profile.name.isEmpty ? 'Mr. G' : profile.name,
                style: const TextStyle(
                  fontSize: 24, 
                  fontWeight: FontWeight.bold,
                  color: Colors.black87,
                ),
              ),
              Text(
                'Level ${profile.level}',
                style: const TextStyle(
                  color: Colors.grey,
                  fontWeight: FontWeight.bold,
                  fontSize: 16,
                ),
              ),
              const SizedBox(height: 12),
              
              // XP Progress Bar
              SizedBox(
                width: 220,
                child: Column(
                  children: [
                    ClipRRect(
                      borderRadius: BorderRadius.circular(10),
                      child: LinearProgressIndicator(
                        value: profile.maxXp > 0 ? profile.currentXp / profile.maxXp : 0.7,
                        minHeight: 12,
                        backgroundColor: const Color(0xFFE0E0E0),
                        valueColor: const AlwaysStoppedAnimation<Color>(secondaryGreen),
                      ),
                    ),
                    const SizedBox(height: 6),
                    Text(
                      '${profile.currentXp} / ${profile.maxXp}', 
                      style: const TextStyle(color: Colors.grey, fontWeight: FontWeight.bold, fontSize: 14)
                    ),
                  ],
                ),
              ),
              
              const SizedBox(height: 32),
              
              // Mascot & Speech Bubble
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Column(
                    children: [
                      Image.asset(
                        'assets/images/nong_thung.png',
                        height: 90,
                        fit: BoxFit.contain,
                        errorBuilder: (context, error, stackTrace) => 
                          const Icon(Icons.eco, size: 80, color: secondaryGreen),
                      ),
                      const SizedBox(height: 4),
                      GestureDetector(
                        onTap: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(builder: (context) => StreakScreen(plasticCount: profile.plasticReduced)),
                          );
                        },
                        child: const Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(Icons.open_in_new, size: 16, color: secondaryGreen),
                            SizedBox(width: 4),
                            Text(
                              'ดู streak', 
                              style: TextStyle(color: secondaryGreen, fontWeight: FontWeight.bold, fontSize: 16)
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Container(
                      margin: const EdgeInsets.only(top: 10),
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: secondaryGreen,
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: const Text(
                        'น้องถุงรอคุณไปรักษ์โลกนะ ไปซื้อของโดยไม่รับถุงกันเถอะ!',
                        style: TextStyle(
                          color: Colors.white, 
                          fontWeight: FontWeight.bold, 
                          fontSize: 15,
                          height: 1.4,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
              
              const SizedBox(height: 32),
              
              // Achievements
              const Text(
                'Achievements', 
                style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: Colors.black54)
              ),
              const SizedBox(height: 12),
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  _buildBadge(Icons.eco),
                  const SizedBox(width: 16),
                  _buildBadge(Icons.psychology),
                  const SizedBox(width: 16),
                  _buildBadge(Icons.public, isUnlocked: false),
                ],
              ),
              
              const SizedBox(height: 40),
              
              // History Section
              const Align(
                alignment: Alignment.centerLeft,
                child: Text('History', style: TextStyle(fontSize: 18, fontWeight: FontWeight.w900)),
              ),
              const SizedBox(height: 16),
              historyAsync.when(
                data: (transactions) => ListView.builder(
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  itemCount: transactions.length,
                  itemBuilder: (context, index) {
                    final tx = transactions[index];
                    return Padding(
                      padding: const EdgeInsets.only(bottom: 24),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(tx.date, style: const TextStyle(color: Colors.grey, fontSize: 13, fontWeight: FontWeight.w500)),
                          const SizedBox(height: 2),
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Expanded(
                                child: Text(
                                  tx.title, 
                                  style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16, color: Colors.black87),
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ),
                              Text(
                                '${tx.isNegative ? '-' : '+'}${tx.points} GP',
                                style: TextStyle(
                                  color: tx.isNegative ? Colors.red : primaryGreen,
                                  fontWeight: FontWeight.w900,
                                  fontSize: 16,
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    );
                  },
                ),
                loading: () => const Center(child: CircularProgressIndicator(color: primaryGreen)),
                error: (e, _) => Center(child: Text('Error: $e')),
              ),
              const SizedBox(height: 20),
            ],
          ),
        ),
        loading: () => const Center(child: CircularProgressIndicator(color: primaryGreen)),
        error: (e, _) => Center(child: Text('Error: $e')),
      ),
    );
  }

  Widget _buildBadge(IconData icon, {bool isUnlocked = true}) {
    return Container(
      padding: const EdgeInsets.all(10),
      decoration: BoxDecoration(
        color: isUnlocked ? secondaryGreen : const Color(0xFFE0E0E0),
        shape: BoxShape.circle,
        border: Border.all(color: Colors.white, width: 2),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 4,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Icon(
        icon, 
        color: isUnlocked ? Colors.white : Colors.grey, 
        size: 28
      ),
    );
  }
}
