import 'dart:async';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'shop_provider.dart'; // To get apiServiceProvider

class NotificationItem {
  final String id;
  final String title;
  final String message;
  final String createdAt;
  final bool isRead;

  NotificationItem({
    required this.id,
    required this.title,
    required this.message,
    required this.createdAt,
    this.isRead = false,
  });

  NotificationItem copyWith({bool? isRead}) {
    return NotificationItem(
      id: id,
      title: title,
      message: message,
      createdAt: createdAt,
      isRead: isRead ?? this.isRead,
    );
  }

  factory NotificationItem.fromJson(Map<String, dynamic> json) {
    return NotificationItem(
      id: json['id']?.toString() ?? json['_id']?.toString() ?? '',
      title: json['title'] ?? '',
      message: json['message'] ?? '',
      createdAt: json['createdAt'] ?? '',
      isRead: json['isRead'] ?? false,
    );
  }
}

final notificationsProvider = NotifierProvider<NotificationsNotifier, List<NotificationItem>>(() {
  return NotificationsNotifier();
});

class NotificationsNotifier extends Notifier<List<NotificationItem>> {
  Timer? _timer;
  bool _isFetching = false;

  @override
  List<NotificationItem> build() {
    loadNotifications();
    
    // Poll for new notifications in real-time every 8 seconds
    _timer = Timer.periodic(const Duration(seconds: 8), (_) {
      if (!_isFetching) {
        loadNotifications();
      }
    });

    // Cancel timer when the provider is disposed
    ref.onDispose(() {
      _timer?.cancel();
    });

    return [];
  }

  Future<void> loadNotifications() async {
    _isFetching = true;
    try {
      final apiService = ref.read(apiServiceProvider);
      final rawList = await apiService.getNotifications();
      state = rawList.map((e) => NotificationItem.fromJson(e)).toList();
    } catch (_) {
      // Ignore background network errors
    } finally {
      _isFetching = false;
    }
  }

  void markAllAsRead() {
    state = state.map((n) => n.copyWith(isRead: true)).toList();
    try {
      final apiService = ref.read(apiServiceProvider);
      apiService.markNotificationsAsRead();
    } catch (_) {}
  }

  void markAsRead(String id) {
    state = state.map((n) => n.id == id ? n.copyWith(isRead: true) : n).toList();
    try {
      final apiService = ref.read(apiServiceProvider);
      apiService.markSingleNotificationAsRead(id);
    } catch (_) {}
  }
}
