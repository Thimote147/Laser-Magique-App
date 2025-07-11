import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../models/notification_model.dart';
import 'user_service.dart';

class NotificationService extends ChangeNotifier {
  static final NotificationService _instance = NotificationService._internal();
  factory NotificationService() => _instance;
  NotificationService._internal();

  final List<AppNotification> _notifications = [];
  final StreamController<AppNotification> _notificationStream = StreamController<AppNotification>.broadcast();
  final UserService _userService = UserService();

  // Cache global pour éviter les notifications visuelles en double
  final Set<String> _recentVisualNotifications = <String>{};

  List<AppNotification> get notifications => List.unmodifiable(_notifications);
  Stream<AppNotification> get notificationStream => _notificationStream.stream;

  int get unreadCount => _notifications.where((notification) => !notification.isRead).length;

  void addNotification(AppNotification notification) {
    _notifications.insert(0, notification);
    _notificationStream.add(notification);
    notifyListeners();
    
    // Auto-remove low priority notifications after 5 minutes
    if (notification.priority == NotificationPriority.low) {
      Timer(const Duration(minutes: 5), () {
        removeNotification(notification.id);
      });
    }
  }

  void markAsRead(String notificationId) {
    final index = _notifications.indexWhere((n) => n.id == notificationId);
    if (index != -1) {
      _notifications[index] = _notifications[index].copyWith(isRead: true);
      notifyListeners();
    }
  }

  void markAsUnread(String notificationId) {
    final index = _notifications.indexWhere((n) => n.id == notificationId);
    if (index != -1) {
      _notifications[index] = _notifications[index].copyWith(isRead: false);
      notifyListeners();
    }
  }

  void markAllAsRead() {
    for (int i = 0; i < _notifications.length; i++) {
      if (!_notifications[i].isRead) {
        _notifications[i] = _notifications[i].copyWith(isRead: true);
      }
    }
    notifyListeners();
  }

  void removeNotification(String notificationId) {
    _notifications.removeWhere((n) => n.id == notificationId);
    notifyListeners();
  }

  void clearAllNotifications() {
    _notifications.clear();
    notifyListeners();
  }

  void clearReadNotifications() {
    _notifications.removeWhere((n) => n.isRead);
    notifyListeners();
  }

  List<AppNotification> getNotificationsByType(NotificationType type) {
    return _notifications.where((n) => n.type == type).toList();
  }

  List<AppNotification> getUnreadNotifications() {
    return _notifications.where((n) => !n.isRead).toList();
  }

  /// Obtient les informations du créateur de la notification
  Future<Map<String, dynamic>> _getCreatorInfo() async {
    final currentUser = Supabase.instance.client.auth.currentUser;
    if (currentUser == null) {
      return {
        'created_by': 'System',
        'creator_name': 'System',
      };
    }

    final creatorName = await _userService.getUserFullName(currentUser.id);
    return {
      'created_by': currentUser.id,
      'creator_name': creatorName,
    };
  }

  // Notification factory methods for common events
  void notifyConsumptionAdded(String bookingId, String itemName, int quantity) async {
    final creatorInfo = await _getCreatorInfo();
    final notification = AppNotification(
      id: 'consumption_${DateTime.now().millisecondsSinceEpoch}',
      title: 'Consommation ajoutée',
      message: '$quantity x $itemName ajouté(s) à la réservation',
      type: NotificationType.consumption,
      priority: NotificationPriority.low,
      timestamp: DateTime.now(),
      createdBy: creatorInfo['created_by'],
      data: {
        'booking_id': bookingId,
        'item_name': itemName,
        'quantity': quantity,
        'creator_name': creatorInfo['creator_name'],
      },
    );
    addNotification(notification);
  }

  void notifyStockUpdated(String itemName, int newQuantity, {bool isLowStock = false}) async {
    final creatorInfo = await _getCreatorInfo();
    final notification = AppNotification(
      id: 'stock_${DateTime.now().millisecondsSinceEpoch}',
      title: isLowStock ? 'Stock faible' : 'Stock mis à jour',
      message: isLowStock 
          ? '$itemName: stock faible ($newQuantity restant)'
          : '$itemName: stock mis à jour ($newQuantity)',
      type: NotificationType.stockUpdate,
      priority: isLowStock ? NotificationPriority.high : NotificationPriority.low,
      timestamp: DateTime.now(),
      createdBy: creatorInfo['created_by'],
      data: {
        'item_name': itemName,
        'quantity': newQuantity,
        'is_low_stock': isLowStock,
        'creator_name': creatorInfo['creator_name'],
      },
    );
    addNotification(notification);
  }

  void notifyBookingAdded(String customerName, DateTime bookingDateTime) async {
    final creatorInfo = await _getCreatorInfo();
    final notification = AppNotification(
      id: 'booking_added_${DateTime.now().millisecondsSinceEpoch}',
      title: 'Nouvelle réservation',
      message: 'Réservation ajoutée pour $customerName',
      type: NotificationType.bookingAdded,
      priority: NotificationPriority.medium,
      timestamp: DateTime.now(),
      createdBy: creatorInfo['created_by'],
      data: {
        'customer_name': customerName,
        'booking_date_time': bookingDateTime.toIso8601String(),
        'creator_name': creatorInfo['creator_name'],
      },
    );
    addNotification(notification);
  }

  void notifyBookingCancelled(String customerName, DateTime bookingDateTime) async {
    final creatorInfo = await _getCreatorInfo();
    final notification = AppNotification(
      id: 'booking_cancelled_${DateTime.now().millisecondsSinceEpoch}',
      title: 'Réservation annulée',
      message: 'Réservation annulée pour $customerName',
      type: NotificationType.bookingCancelled,
      priority: NotificationPriority.medium,
      timestamp: DateTime.now(),
      createdBy: creatorInfo['created_by'],
      data: {
        'customer_name': customerName,
        'booking_date_time': bookingDateTime.toIso8601String(),
        'creator_name': creatorInfo['creator_name'],
      },
    );
    addNotification(notification);
  }

  void notifyBookingDeleted(String customerName, DateTime bookingDateTime) async {
    final creatorInfo = await _getCreatorInfo();
    final notification = AppNotification(
      id: 'booking_deleted_${DateTime.now().millisecondsSinceEpoch}',
      title: 'Réservation supprimée',
      message: 'Réservation supprimée pour $customerName',
      type: NotificationType.bookingDeleted,
      priority: NotificationPriority.medium,
      timestamp: DateTime.now(),
      createdBy: creatorInfo['created_by'],
      data: {
        'customer_name': customerName,
        'booking_date_time': bookingDateTime.toIso8601String(),
        'creator_name': creatorInfo['creator_name'],
      },
    );
    addNotification(notification);
  }

  void notifyPaymentReceived(String customerName, double amount, String method) async {
    final creatorInfo = await _getCreatorInfo();
    final notification = AppNotification(
      id: 'payment_${DateTime.now().millisecondsSinceEpoch}',
      title: 'Paiement reçu',
      message: 'Paiement de ${amount.toStringAsFixed(2)}€ ($method) reçu de $customerName',
      type: NotificationType.paymentReceived,
      priority: NotificationPriority.medium,
      timestamp: DateTime.now(),
      createdBy: creatorInfo['created_by'],
      data: {
        'customer_name': customerName,
        'amount': amount,
        'method': method,
        'creator_name': creatorInfo['creator_name'],
      },
    );
    addNotification(notification);
  }

  void notifyStockAlert(String itemName, int currentQuantity, int alertThreshold) async {
    final creatorInfo = await _getCreatorInfo();
    final notification = AppNotification(
      id: 'stock_alert_${DateTime.now().millisecondsSinceEpoch}',
      title: 'Alerte stock',
      message: '$itemName: stock critique ($currentQuantity/$alertThreshold)',
      type: NotificationType.stockAlert,
      priority: NotificationPriority.urgent,
      timestamp: DateTime.now(),
      createdBy: creatorInfo['created_by'],
      data: {
        'item_name': itemName,
        'current_quantity': currentQuantity,
        'alert_threshold': alertThreshold,
        'creator_name': creatorInfo['creator_name'],
      },
    );
    addNotification(notification);
  }

  void notifySystemUpdate(String version, String description) async {
    final creatorInfo = await _getCreatorInfo();
    final notification = AppNotification(
      id: 'system_update_${DateTime.now().millisecondsSinceEpoch}',
      title: 'Mise à jour disponible',
      message: 'Version $version disponible: $description',
      type: NotificationType.systemUpdate,
      priority: NotificationPriority.high,
      timestamp: DateTime.now(),
      createdBy: creatorInfo['created_by'],
      data: {
        'version': version,
        'description': description,
        'creator_name': creatorInfo['creator_name'],
      },
    );
    addNotification(notification);
  }

  /// Vérifier si une notification visuelle a déjà été affichée récemment
  bool hasRecentVisualNotification(String key) {
    return _recentVisualNotifications.contains(key);
  }

  /// Marquer une notification comme récemment affichée visuellement
  void markVisualNotificationShown(String key) {
    _recentVisualNotifications.add(key);
    
    // Nettoyer après 2 minutes pour éviter les doublons
    Timer(Duration(minutes: 2), () {
      _recentVisualNotifications.remove(key);
    });
  }

  @override
  void dispose() {
    _notificationStream.close();
    super.dispose();
  }
}