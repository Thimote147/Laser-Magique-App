import 'dart:async';
import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../models/notification_model.dart';
import 'notification_service.dart';
import '../screens/notifications_screen.dart';
import '../../main.dart';

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
      debugPrint('RealtimeNotificationService: Initializing...');
      
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
      debugPrint('RealtimeNotificationService: Initialized successfully');
      
    } catch (e) {
      debugPrint('RealtimeNotificationService: Failed to initialize: $e');
      rethrow;
    }
  }

  /// S'abonner aux notifications en temps réel
  Future<void> _subscribeToNotifications() async {
    if (_isSubscribed || currentUserId == null) return;

    try {
      debugPrint('RealtimeNotificationService: Subscribing to notifications for user $currentUserId');
      
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
            callback: _handleNotificationInsert,
          )
          .onPostgresChanges(
            event: PostgresChangeEvent.update,
            schema: 'public',
            table: 'notifications',
            callback: _handleNotificationUpdate,
          )
          .onPostgresChanges(
            event: PostgresChangeEvent.delete,
            schema: 'public',
            table: 'notifications',
            callback: _handleNotificationDelete,
          );

      // S'abonner au channel
      _notificationChannel!.subscribe();
      _isSubscribed = true;
      
      debugPrint('RealtimeNotificationService: Successfully subscribed to notifications');
      
      // NOTE: Ne plus charger les notifications existantes car nous utilisons maintenant la base de données directement
      // await _loadExistingNotifications();
      
    } catch (e) {
      debugPrint('RealtimeNotificationService: Failed to subscribe: $e');
      _isSubscribed = false;
    }
  }

  /// Se désabonner des notifications
  Future<void> _unsubscribeFromNotifications() async {
    if (!_isSubscribed) return;

    try {
      debugPrint('RealtimeNotificationService: Unsubscribing from notifications');
      
      if (_notificationChannel != null) {
        await _notificationChannel!.unsubscribe();
        _notificationChannel = null;
      }
      
      _isSubscribed = false;
      debugPrint('RealtimeNotificationService: Successfully unsubscribed');
      
    } catch (e) {
      debugPrint('RealtimeNotificationService: Failed to unsubscribe: $e');
    }
  }

  /// Charger les notifications existantes depuis la base de données
  Future<void> _loadExistingNotifications() async {
    if (currentUserId == null) return;

    try {
      debugPrint('RealtimeNotificationService: Loading existing notifications');
      
      final response = await _supabase
          .from('notifications')
          .select()
          .order('created_at', ascending: false)
          .limit(50); // Limite pour éviter de surcharger

      final List<dynamic> data = response as List<dynamic>;
      
      // Convertir et ajouter chaque notification au service local
      for (final item in data) {
        try {
          final notification = _convertFromDatabase(item);
          // Ajouter sans déclencher de notification (pour éviter le spam)
          _localNotificationService.addNotification(notification);
        } catch (e) {
          debugPrint('RealtimeNotificationService: Failed to convert notification: $e');
        }
      }
      
      debugPrint('RealtimeNotificationService: Loaded ${data.length} existing notifications');
      
    } catch (e) {
      debugPrint('RealtimeNotificationService: Failed to load existing notifications: $e');
    }
  }

  /// Gérer l'insertion d'une nouvelle notification
  void _handleNotificationInsert(PostgresChangePayload payload) {
    try {
      debugPrint('RealtimeNotificationService: Received new notification: ${payload.newRecord}');
      
      final notification = _convertFromDatabase(payload.newRecord);
      
      // NOTE: Ne plus ajouter au service local car nous utilisons maintenant la base de données directement
      // _localNotificationService.addNotification(notification);
      
      debugPrint('RealtimeNotificationService: Processing notification: ${notification.title}');
      
      // Afficher seulement la notification visuelle en temps réel
      _showInAppNotification(notification);
      
    } catch (e) {
      debugPrint('RealtimeNotificationService: Failed to handle notification insert: $e');
    }
  }

  /// Gérer la mise à jour d'une notification
  void _handleNotificationUpdate(PostgresChangePayload payload) {
    try {
      debugPrint('RealtimeNotificationService: Received notification update: ${payload.newRecord}');
      
      // Mettre à jour dans le service local
      // Pour l'instant, on recharge toutes les notifications (à optimiser si nécessaire)
      _loadExistingNotifications();
      
    } catch (e) {
      debugPrint('RealtimeNotificationService: Failed to handle notification update: $e');
    }
  }

  /// Gérer la suppression d'une notification
  void _handleNotificationDelete(PostgresChangePayload payload) {
    try {
      debugPrint('RealtimeNotificationService: Received notification delete: ${payload.oldRecord}');
      
      final notificationId = payload.oldRecord['id'] as String;
      _localNotificationService.removeNotification(notificationId);
      
    } catch (e) {
      debugPrint('RealtimeNotificationService: Failed to handle notification delete: $e');
    }
  }

  /// Convertir une notification de la base de données vers le modèle local
  AppNotification _convertFromDatabase(Map<String, dynamic> data) {
    return AppNotification(
      id: data['id'] as String,
      title: data['title'] as String,
      message: data['message'] as String,
      type: NotificationType.values.firstWhere(
        (type) => type.name == data['type'],
        orElse: () => NotificationType.systemUpdate,
      ),
      priority: NotificationPriority.values.firstWhere(
        (priority) => priority.name == data['priority'],
        orElse: () => NotificationPriority.medium,
      ),
      timestamp: DateTime.parse(data['created_at'] as String),
      data: data['data'] != null ? Map<String, dynamic>.from(data['data']) : null,
      isRead: data['is_read'] as bool? ?? false,
      createdBy: data['created_by'] as String?,
    );
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
      debugPrint('RealtimeNotificationService: Sending global notification: $title');
      
      final notificationData = {
        'title': title,
        'message': message,
        'type': type.name,
        'priority': priority.name,
        'data': data ?? {},
        'created_by': currentUserId,
      };

      await _supabase.from('notifications').insert(notificationData);
      
      debugPrint('RealtimeNotificationService: Successfully sent notification');
      
    } catch (e) {
      debugPrint('RealtimeNotificationService: Failed to send notification: $e');
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
    debugPrint('RealtimeNotificationService: broadcastNotification called but disabled (using database triggers instead)');
    debugPrint('RealtimeNotificationService: Would have sent: $title - $message');
    
    // Désactivé pour éviter les notifications en double
    /*
    try {
      debugPrint('RealtimeNotificationService: Broadcasting notification: $title');
      
      // Créer une notification globale avec l'utilisateur actuel comme créateur
      final notificationData = {
        'title': title,
        'message': message,
        'type': type.name,
        'priority': priority.name,
        'user_id': null, // null = notification globale visible par tous
        'created_by': currentUserId, // Tracer qui a créé la notification
        'data': data ?? {},
        'is_read': false,
      };

      // Ajouter expiration si spécifiée
      if (expireAfter != null) {
        notificationData['expires_at'] = DateTime.now().add(expireAfter).toIso8601String();
      }

      await _supabase.from('notifications').insert(notificationData);
      
      debugPrint('RealtimeNotificationService: Successfully broadcasted notification');
      
    } catch (e) {
      debugPrint('RealtimeNotificationService: Failed to broadcast notification: $e');
      rethrow;
    }
    */
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
      debugPrint('RealtimeNotificationService: Failed to mark as read in DB: $e');
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
      debugPrint('RealtimeNotificationService: Failed to delete notification: $e');
      // Si échec, supprimer seulement localement
      _localNotificationService.removeNotification(notificationId);
    }
  }

  /// Méthodes de convenance pour les événements métier
  
  /// Notifier tous les utilisateurs qu'une nouvelle réservation a été créée
  /// NOTE: Désactivé car les notifications sont maintenant gérées par les triggers de base de données
  Future<void> notifyBookingCreated({
    required String customerName,
    required DateTime bookingDateTime,
    required String bookingId,
  }) async {
    debugPrint('RealtimeNotificationService: notifyBookingCreated called but disabled (using database triggers instead)');
    // await broadcastNotification(
    //   title: 'Nouvelle réservation',
    //   message: 'Réservation créée pour $customerName',
    //   type: NotificationType.bookingAdded,
    //   priority: NotificationPriority.medium,
    //   data: {
    //     'customer_name': customerName,
    //     'booking_date_time': bookingDateTime.toIso8601String(),
    //     'booking_id': bookingId,
    //   },
    //   expireAfter: const Duration(days: 7), // Expire après 7 jours
    // );
  }

  /// Notifier tous les utilisateurs qu'une réservation a été annulée
  /// NOTE: Désactivé car les notifications sont maintenant gérées par les triggers de base de données
  Future<void> notifyBookingCancelled({
    required String customerName,
    required DateTime bookingDateTime,
    required String bookingId,
  }) async {
    debugPrint('RealtimeNotificationService: notifyBookingCancelled called but disabled (using database triggers instead)');
    // await broadcastNotification(
    //   title: 'Réservation annulée',
    //   message: 'Réservation annulée pour $customerName',
    //   type: NotificationType.bookingCancelled,
    //   priority: NotificationPriority.medium,
    //   data: {
    //     'customer_name': customerName,
    //     'booking_date_time': bookingDateTime.toIso8601String(),
    //     'booking_id': bookingId,
    //   },
    //   expireAfter: const Duration(days: 3),
    // );
  }

  /// Notifier tous les utilisateurs qu'une réservation a été supprimée
  /// NOTE: Désactivé car les notifications sont maintenant gérées par les triggers de base de données
  Future<void> notifyBookingDeleted({
    required String customerName,
    required DateTime bookingDateTime,
    required String bookingId,
  }) async {
    debugPrint('RealtimeNotificationService: notifyBookingDeleted called but disabled (using database triggers instead)');
    // await broadcastNotification(
    //   title: 'Réservation supprimée',
    //   message: 'Réservation supprimée pour $customerName',
    //   type: NotificationType.bookingDeleted,
    //   priority: NotificationPriority.medium,
    //   data: {
    //     'customer_name': customerName,
    //     'booking_date_time': bookingDateTime.toIso8601String(),
    //     'booking_id': bookingId,
    //   },
    //   expireAfter: const Duration(days: 3),
    // );
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
    debugPrint('RealtimeNotificationService: Disposing...');
    
    _unsubscribeFromNotifications();
    _authSubscription?.cancel();
    _isInitialized = false;
    
    super.dispose();
  }

  /// Forcer une reconnexion (utile pour le debug)
  Future<void> reconnect() async {
    debugPrint('RealtimeNotificationService: Reconnecting...');
    
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

  /// Afficher une notification visuelle dans l'app
  void _showInAppNotification(AppNotification notification) {
    final context = navigatorKey.currentContext;
    if (context != null && context.mounted) {
      _showTopNotification(context, notification);
    }
  }

  /// Afficher une notification en haut de l'écran avec animation
  void _showTopNotification(BuildContext context, AppNotification notification) {
    // Créer une clé simple basée sur le titre et le type pour éviter les doublons
    final visualKey = '${notification.title}:${notification.type.name}';
    
    // Vérifier si cette notification visuelle n'a pas déjà été affichée
    if (_localNotificationService.hasRecentVisualNotification(visualKey)) {
      debugPrint('RealtimeNotificationService: Visual notification already shown: ${notification.title}');
      return;
    }
    
    _localNotificationService.markVisualNotificationShown(visualKey);

    showGeneralDialog(
      context: context,
      pageBuilder: (context, animation, secondaryAnimation) {
        return Align(
          alignment: Alignment.topCenter,
          child: Material(
            color: Colors.transparent,
            child: GestureDetector(
              onPanUpdate: (details) {
                // Détecter le glissement vers le haut
                if (details.delta.dy < -5) {
                  Navigator.of(context).pop();
                }
              },
              child: Container(
                margin: EdgeInsets.only(top: 50, left: 16, right: 16),
                padding: EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: _getNotificationColor(notification.priority),
                  borderRadius: BorderRadius.circular(16),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: 0.2),
                      blurRadius: 10,
                      offset: Offset(0, 2),
                    ),
                  ],
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(
                      _getNotificationIcon(notification.type),
                      color: Colors.white,
                      size: 20,
                    ),
                    SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Text(
                            notification.title,
                            style: TextStyle(
                              color: Colors.white,
                              fontWeight: FontWeight.bold,
                              fontSize: 14,
                            ),
                          ),
                          SizedBox(height: 4),
                          Text(
                            notification.message,
                            style: TextStyle(
                              color: Colors.white70,
                              fontSize: 12,
                            ),
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ],
                      ),
                    ),
                    SizedBox(width: 8),
                    GestureDetector(
                      onTap: () {
                        Navigator.of(context).pop();
                        Navigator.of(context).push(
                          MaterialPageRoute(
                            builder: (context) => const NotificationsScreen(),
                          ),
                        );
                      },
                      child: Container(
                        padding: EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                        decoration: BoxDecoration(
                          color: Colors.white.withValues(alpha: 0.2),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Text(
                          'Voir',
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 12,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        );
      },
      barrierDismissible: false, // Empêche la fermeture en tapant à côté
      barrierLabel: 'Fermer notification',
      barrierColor: Colors.transparent,
      transitionDuration: Duration(milliseconds: 300),
      transitionBuilder: (context, animation, secondaryAnimation, child) {
        return SlideTransition(
          position: Tween<Offset>(
            begin: Offset(0.0, -1.0),
            end: Offset(0.0, 0.0),
          ).animate(CurvedAnimation(
            parent: animation,
            curve: Curves.easeOutBack,
          )),
          child: child,
        );
      },
    );
  }

  /// Obtenir l'icône selon le type de notification
  IconData _getNotificationIcon(NotificationType type) {
    switch (type) {
      case NotificationType.bookingAdded:
        return Icons.event_available;
      case NotificationType.bookingCancelled:
        return Icons.event_busy;
      case NotificationType.bookingDeleted:
        return Icons.event_busy;
      case NotificationType.paymentReceived:
        return Icons.payment;
      case NotificationType.stockUpdate:
        return Icons.inventory;
      case NotificationType.stockAlert:
        return Icons.warning;
      case NotificationType.systemUpdate:
        return Icons.settings;
      case NotificationType.consumption:
        return Icons.local_bar;
    }
  }

  /// Obtenir la couleur selon la priorité
  Color _getNotificationColor(NotificationPriority priority) {
    switch (priority) {
      case NotificationPriority.high:
        return Colors.red[600]!;
      case NotificationPriority.medium:
        return Colors.blue[600]!;
      case NotificationPriority.low:
        return Colors.green[600]!;
      default:
        return Colors.blue[600]!;
    }
  }
}