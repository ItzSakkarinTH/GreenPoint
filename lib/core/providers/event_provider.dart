import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:greenpoint/core/providers/shop_provider.dart';
import '../models/event_model.dart';

final eventsProvider = FutureProvider.autoDispose<List<EventModel>>((ref) async {
  final apiService = ref.watch(apiServiceProvider);
  final data = await apiService.getEvents();
  
  if (data is List) {
    return data.map((json) => EventModel.fromJson(json)).toList();
  } else if (data is Map && data.containsKey('events') && data['events'] is List) {
    return (data['events'] as List).map((json) => EventModel.fromJson(json)).toList();
  } else if (data is Map && data.containsKey('data') && data['data'] is List) {
    return (data['data'] as List).map((json) => EventModel.fromJson(json)).toList();
  }
  return [];
});
