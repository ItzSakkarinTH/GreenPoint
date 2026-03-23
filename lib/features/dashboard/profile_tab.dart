import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/providers/user_provider.dart';
import '../../core/providers/auth_provider.dart';
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
          IconButton(
            icon: const Icon(Icons.logout, color: Colors.red),
            onPressed: () => ref.read(authProvider.notifier).logout(),
          ),
        ],
      ),
      body: profileAsync.when(
        data: (profile) => SingleChildScrollView(
          padding: const EdgeInsets.all(20),
          child: Column(
            children: [
              // User Info
              const CircleAvatar(
                radius: 55,
                backgroundColor: Color(0xFFE8F5E9),
                child: Icon(Icons.person, size: 70, color: primaryGreen),
              ),
              const SizedBox(height: 16),
              Text(
                profile.name.isEmpty ? 'สมาชิก GreenPoint' : profile.name,
                style: const TextStyle(
                  fontSize: 26, 
                  fontWeight: FontWeight.w900, 
                  color: primaryGreen,
                ),
              ),
              const SizedBox(height: 4),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                decoration: BoxDecoration(
                  color: secondaryGreen.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Text(
                  'LV.${profile.level} Green Ambassador',
                  style: const TextStyle(
                    color: secondaryGreen,
                    fontWeight: FontWeight.bold,
                    fontSize: 14,
                  ),
                ),
              ),
              const SizedBox(height: 12),
              
              // XP Progress Bar
              ClipRRect(
                borderRadius: BorderRadius.circular(10),
                child: LinearProgressIndicator(
                  value: profile.currentXp / profile.maxXp,
                  minHeight: 12,
                  backgroundColor: Colors.grey.shade200,
                  valueColor: const AlwaysStoppedAnimation<Color>(secondaryGreen),
                ),
              ),
              const SizedBox(height: 4),
              Text('${profile.currentXp} / ${profile.maxXp}', style: const TextStyle(color: Colors.grey)),
              
              const SizedBox(height: 32),
              
              // Mascot & Speech Bubble
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Column(
                    children: [
                      Image.asset(
                        'assets/images/nong_thung.png',
                        height: 100,
                        fit: BoxFit.contain,
                      ),
                      TextButton.icon(
                        onPressed: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(builder: (context) => StreakScreen(plasticCount: profile.plasticReduced)),
                          );
                        },
                        icon: const Icon(Icons.auto_graph, size: 16, color: primaryGreen),
                        label: const Text('ดู streak', style: TextStyle(color: primaryGreen, fontWeight: FontWeight.bold)),
                      ),
                    ],
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: secondaryGreen,
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: const Text(
                        'น้องถุงรอคุณไปรักษ์โลกนะ ไปซื้อของโดยไม่รับถุงกันเถอะ!',
                        style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
                      ),
                    ),
                  ),
                ],
              ),
              
              const SizedBox(height: 24),
              
              // Achievements
              const Align(
                alignment: Alignment.centerLeft,
                child: Text('Achievements', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
              ),
              const SizedBox(height: 12),
              Row(
                children: [
                  _buildBadge(Icons.eco, true),
                  _buildBadge(Icons.psychology, true),
                  _buildBadge(Icons.public, false),
                ],
              ),
              
              const SizedBox(height: 32),
              
              // History
              const Align(
                alignment: Alignment.centerLeft,
                child: Text('History', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
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
                      padding: const EdgeInsets.only(bottom: 20),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(tx.date, style: const TextStyle(color: Colors.grey, fontSize: 12)),
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Expanded(
                                child: Text(
                                  tx.title, 
                                  style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ),
                              Text(
                                '${tx.isNegative ? '-' : '+'}${tx.points} GP',
                                style: TextStyle(
                                  color: tx.isNegative ? Colors.red : primaryGreen,
                                  fontWeight: FontWeight.bold,
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
                loading: () => const Center(child: CircularProgressIndicator()),
                error: (e, _) => Text('Error: $e'),
              ),
            ],
          ),
        ),
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => Center(child: Text('Error loading profile: $e')),
      ),
    );
  }

  Widget _buildBadge(IconData icon, bool unlocked) {
    return Container(
      margin: const EdgeInsets.only(right: 16),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: unlocked ? primaryGreen.withOpacity(0.1) : Colors.grey.shade100,
        shape: BoxShape.circle,
        border: Border.all(color: unlocked ? primaryGreen : Colors.grey.shade300, width: 2),
      ),
      child: Icon(icon, color: unlocked ? primaryGreen : Colors.grey.shade400, size: 30),
    );
  }
}
