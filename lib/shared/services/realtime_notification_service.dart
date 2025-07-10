import 'dart:async';
import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../models/notification_model.dart';
import 'notification_service.dart';

/// Service pour gérer les notifications en temps réel via Supabase
/// 
/// Ce service :
/// - S'abonne aux changements de la table notifications via Realtime
/// - Synchronise les notifications locales avec la base de données
/// - Gère les notifications entre appareils multiples
class RealtimeNotificationService extends ChangeNotifier {
  static final RealtimeNotificationService _instance = RealtimeNotificationService._internal();
  factory RealtimeNotificationService() => _instance;
  RealtimeNotificationService._internal();

  final SupabaseClient _supabase = Supabase.instance.client;
  final NotificationService _localNotificationService = NotificationService();
  
  RealtimeChannel? _notificationChannel;
  StreamSubscription? _authSubscription;
  bool _isInitialized = false;
  bool _isSubscribed = false;


  /// Getters
  bool get isInitialized => _isInitialized;
  bool get isSubscribed => _isSubscribed;
  String? get currentUserId => _supabase.auth.currentUser?.id;
  List<AppNotification> get notifications => _localNotificationService.notifications;
  NotificationService get localService => _localNotificationService;

  /// Initialiser le service de notifications temps réel
  Future<void> initialize() async {
    if (_isInitialized) return;

    try {
      // Écouter les changements d'authentification
      _authSubscription = _supabase.auth.onAuthStateChange.listen((data) {
        final session = data.session;
        if (session != null) {
          _subscribeToNotifications();
        } else {
          _unsubscribeFromNotifications();
        }
      });

      // Si déjà connecté, s'abonner immédiatement
      if (_supabase.auth.currentUser != null) {
        await _subscribeToNotifications();
      }

      _isInitialized = true;
      
    } catch (e) {
      rethrow;
    }
  }

  /// S'abonner aux notifications en temps réel
  Future<void> _subscribeToNotifications() async {
    if (_isSubscribed || currentUserId == null) return;

    try {
      // Se désabonner d'abord si déjà abonné
      await _unsubscribeFromNotifications();

      // Créer un nouveau channel pour toutes les notifications
      _notificationChannel = _supabase
          .channel('notifications_all')
          // Toutes les notifications (visibles par tous)
          .onPostgresChanges(
            event: PostgresChangeEvent.insert,
            schema: 'public',
            table: 'notifications',
            callback: (payload) {
              _handleNotificationInsert(payload);
            },
          )
          .onPostgresChanges(
            event: PostgresChangeEvent.update,
            schema: 'public',
            table: 'notifications',
            callback: (payload) {
              _handleNotificationUpdate(payload);
            },
          )
          .onPostgresChanges(
            event: PostgresChangeEvent.delete,
            schema: 'public',
            table: 'notifications',
            callback: (payload) {
              _handleNotificationDelete(payload);
            },
          )
          // Écouter aussi les changements de statuts de lecture pour les badges
          .onPostgresChanges(
            event: PostgresChangeEvent.all,
            schema: 'public',
            table: 'notification_read_status',
            callback: (payload) {
              _handleNotificationReadStatusChange(payload);
            },
          );

      // S'abonner au channel
      _notificationChannel!.subscribe();
      _isSubscribed = true;
      
    } catch (e) {
      _isSubscribed = false;
    }
  }

  /// Se désabonner des notifications
  Future<void> _unsubscribeFromNotifications() async {
    if (!_isSubscribed) return;

    try {
      if (_notificationChannel != null) {
        await _notificationChannel!.unsubscribe();
        _notificationChannel = null;
      }
      
      _isSubscribed = false;
      
    } catch (e) {
      // Ignorer les erreurs de désouscription
    }
  }


  /// Gérer l'insertion d'une nouvelle notification
  void _handleNotificationInsert(PostgresChangePayload payload) {
    try {
      // Notifier les listeners pour mettre à jour les badges et la page des notifications
      notifyListeners();
    } catch (e) {
      // Ignorer les erreurs de traitement
    }
  }

  /// Gérer la mise à jour d'une notification
  void _handleNotificationUpdate(PostgresChangePayload payload) {
    try {
      // Notifier les listeners pour mettre à jour les badges et la page des notifications
      notifyListeners();
    } catch (e) {
      // Ignorer les erreurs de traitement
    }
  }

  /// Gérer la suppression d'une notification
  void _handleNotificationDelete(PostgresChangePayload payload) {
    try {
      // Notifier les listeners pour mettre à jour les badges et la page des notifications
      notifyListeners();
    } catch (e) {
      // Ignorer les erreurs de traitement
    }
  }
  
  /// Gérer les changements de statut de lecture
  void _handleNotificationReadStatusChange(PostgresChangePayload payload) {
    try {
      // Notifier immédiatement les listeners pour mettre à jour les badges
      notifyListeners();
    } catch (e) {
      // Ignorer les erreurs de traitement
    }
  }



  /// Envoyer une notification globale
  Future<void> sendGlobalNotification({
    required String title,
    required String message,
    required NotificationType type,
    NotificationPriority priority = NotificationPriority.medium,
    Map<String, dynamic>? data,
  }) async {
    try {
      final notificationData = {
        'title': title,
        'message': message,
        'type': type.name,
        'priority': priority.name,
        'data': data ?? {},
        'created_by': currentUserId,
      };

      await _supabase.from('notifications').insert(notificationData);
      
    } catch (e) {
      rethrow;
    }
  }

  /// Envoyer une notification à tous les utilisateurs (broadcast)
  /// NOTE: Désactivé car les notifications sont maintenant gérées par les triggers de base de données
  Future<void> broadcastNotification({
    required String title,
    required String message,
    required NotificationType type,
    NotificationPriority priority = NotificationPriority.medium,
    Map<String, dynamic>? data,
    Duration? expireAfter,
  }) async {
    // Désactivé pour éviter les notifications en double
  }

  /// Marquer une notification comme lue
  Future<void> markAsRead(String notificationId) async {
    try {
      // Utiliser la table notification_read_status pour marquer comme lu
      await _supabase
          .from('notification_read_status')
          .upsert({
            'notification_id': notificationId,
            'user_id': currentUserId!,
            'is_read': true,
            'read_at': DateTime.now().toIso8601String(),
          });
      
      // Aussi mettre à jour localement
      _localNotificationService.markAsRead(notificationId);
      
    } catch (e) {
      // Si échec, marquer seulement localement
      _localNotificationService.markAsRead(notificationId);
    }
  }

  /// Supprimer une notification
  Future<void> deleteNotification(String notificationId) async {
    try {
      // Supprimer la notification globale
      await _supabase
          .from('notifications')
          .delete()
          .eq('id', notificationId);
      
      // La suppression locale sera gérée par le callback Realtime
      
    } catch (e) {
      // Si échec, supprimer seulement localement
      _localNotificationService.removeNotification(notificationId);
    }
  }

  /// Méthodes de convenance pour les événements métier
  
  /// Méthode de test pour les notifications visuelles
  Future<void> testNotification() async {
    try {
      await sendGlobalNotification(
        title: 'Test notification ${DateTime.now().millisecondsSinceEpoch}',
        message: 'Ceci est une notification de test',
        type: NotificationType.systemUpdate,
        priority: NotificationPriority.medium,
      );
      
      // Attendre un peu pour laisser le temps au Realtime de réagir
      await Future.delayed(const Duration(seconds: 2));
      
    } catch (e) {
      // Ignorer les erreurs de test
    }
  }
  
  
  /// Diagnostiquer l'état du service Realtime
  void debugRealtimeStatus() {
    // Debug supprimé pour une console propre
  }
  
  /// Notifier tous les utilisateurs qu'une nouvelle réservation a été créée
  /// NOTE: Désactivé car les notifications sont maintenant gérées par les triggers de base de données
  Future<void> notifyBookingCreated({
    required String customerName,
    required DateTime bookingDateTime,
    required String bookingId,
  }) async {
    // Désactivé - géré par les triggers de base de données
  }

  /// Notifier tous les utilisateurs qu'une réservation a été annulée
  /// NOTE: Désactivé car les notifications sont maintenant gérées par les triggers de base de données
  Future<void> notifyBookingCancelled({
    required String customerName,
    required DateTime bookingDateTime,
    required String bookingId,
  }) async {
    // Désactivé - géré par les triggers de base de données
  }

  /// Notifier tous les utilisateurs qu'une réservation a été supprimée
  /// NOTE: Désactivé car les notifications sont maintenant gérées par les triggers de base de données
  Future<void> notifyBookingDeleted({
    required String customerName,
    required DateTime bookingDateTime,
    required String bookingId,
  }) async {
    // Désactivé - géré par les triggers de base de données
  }

  /// Notifier les alertes de stock à tous les utilisateurs
  Future<void> notifyStockAlert({
    required String itemName,
    required int currentQuantity,
    required int alertThreshold,
  }) async {
    await broadcastNotification(
      title: 'Alerte stock critique',
      message: '$itemName: stock critique ($currentQuantity/$alertThreshold)',
      type: NotificationType.stockAlert,
      priority: NotificationPriority.urgent,
      data: {
        'item_name': itemName,
        'current_quantity': currentQuantity,
        'alert_threshold': alertThreshold,
      },
      expireAfter: const Duration(hours: 24),
    );
  }

  /// Nettoyer et fermer le service
  @override
  void dispose() {
    _unsubscribeFromNotifications();
    _authSubscription?.cancel();
    _isInitialized = false;
    
    super.dispose();
  }

  /// Forcer une reconnexion (utile pour le debug)
  Future<void> reconnect() async {
    await _unsubscribeFromNotifications();
    await _subscribeToNotifications();
  }

  /// Obtenir des statistiques de debug
  Map<String, dynamic> getDebugInfo() {
    return {
      'isInitialized': _isInitialized,
      'isSubscribed': _isSubscribed,
      'currentUserId': currentUserId,
      'hasChannel': _notificationChannel != null,
      'localNotificationsCount': _localNotificationService.notifications.length,
    };
  }

}