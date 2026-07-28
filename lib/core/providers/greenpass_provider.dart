import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:greenpoint/core/providers/shop_provider.dart';
import 'package:greenpoint/core/providers/user_provider.dart';
import '../models/quest_model.dart';
import '../models/pass_model.dart';
import '../network/api_service.dart';

// Provider for fetching Green Pass Quests (missions)
final questsProvider = FutureProvider.autoDispose<List<Quest>>((ref) async {
  final apiService = ref.watch(apiServiceProvider);
  final responseData = await apiService.getQuests();
  
  final questsList = responseData['quests'] as List? ?? [];
  return questsList.map((q) => Quest.fromJson(q)).toList();
});

// Provider for fetching User's overall Green Pass progression and tiers
final passProgressProvider = FutureProvider.autoDispose<UserPassProgress>((ref) async {
  final apiService = ref.watch(apiServiceProvider);
  final responseData = await apiService.getPassProgress();
  
  return UserPassProgress.fromJson(responseData);
});

// Actions class to handle claiming Quest and Pass Tier rewards
final greenPassActionsProvider = Provider((ref) {
  final apiService = ref.watch(apiServiceProvider);
  return GreenPassActions(ref, apiService);
});

class GreenPassActions {
  final Ref ref;
  final ApiService apiService;

  GreenPassActions(this.ref, this.apiService);

  // Claim quest reward
  Future<void> claimQuestReward(String questId) async {
    await apiService.claimQuest(questId);
    
    // Invalidate providers to force refresh and fetch updated data
    ref.invalidate(questsProvider);
    ref.invalidate(passProgressProvider);
    ref.invalidate(userProfileProvider); // Updates user overall level, xp, and points
    ref.invalidate(historyProvider);      // Updates transaction history log
  }

  // Claim tier reward
  Future<void> claimPassTierReward(int tierNumber) async {
    await apiService.claimPassTier(tierNumber);
    
    // Invalidate providers to force refresh and fetch updated data
    ref.invalidate(passProgressProvider);
    ref.invalidate(userProfileProvider); // Updates user overall level, xp, and badges
    ref.invalidate(historyProvider);      // Updates transaction history log
  }
}
