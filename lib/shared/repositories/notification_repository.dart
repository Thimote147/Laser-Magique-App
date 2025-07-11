import 'package:flutter/foundation.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../models/notification_model.dart';
import '../services/user_service.dart';

/// Repository pour gérer les notifications dans la base de données Supabase
/// 
/// Ce repository fournit une interface pour :
/// - Créer, lire, mettre à jour et supprimer des notifications
/// - Gérer les notifications par utilisateur avec statut de lecture individuel
/// - Gérer les notifications globales avec statut de lecture par utilisateur
/// - Nettoyer les notifications expirées
class NotificationRepository {
  final SupabaseClient _supabase = Supabase.instance.client;
  final UserService _userService = UserService();

  /// Obtenir l'ID de l'utilisateur actuellement connecté
  String? get currentUserId => _supabase.auth.currentUser?.id;

  /// Créer une nouvelle notification dans la base de données
  Future<String> createNotification({
    required String title,
    required String message,
    required NotificationType type,
    NotificationPriority priority = NotificationPriority.medium,
    Map<String, dynamic>? data,
  }) async {
    try {
      // Ajouter l'information du créateur
      final enhancedData = Map<String, dynamic>.from(data ?? {});
      
      if (currentUserId != null) {
        final creatorName = await _userService.getUserFullName(currentUserId!);
        enhancedData['creator_name'] = creatorName;
      }

      final notificationData = {
        'title': title,
        'message': message,
        'type': type.name,
        'priority': priority.name,
        'data': enhancedData,
        'created_by': currentUserId,
      };

      final response = await _supabase
          .from('notifications')
          .insert(notificationData)
          .select('id')
          .single();

      return response['id'] as String;
    } catch (e) {
      throw Exception('Failed to create notification: $e');
    }
  }

  /// Obtenir toutes les notifications pour l'utilisateur actuel
  /// Toutes les notifications sont visibles mais le statut de lecture est individuel
  Future<List<AppNotification>> getNotificationsForCurrentUser({
    int? limit,
    int? offset,
    bool? unreadOnly,
  }) async {
    if (currentUserId == null) {
      throw Exception('User not authenticated');
    }

    try {
      // Récupérer toutes les notifications (visibles par tous les utilisateurs)
      // sauf celles créées par l'utilisateur actuel
      var query = _supabase
          .from('notifications')
          .select()
          .neq('created_by', currentUserId!) // Exclure les notifications créées par l'utilisateur actuel
          .order('created_at', ascending: false);

      if (limit != null) {
        query = query.limit(limit);
      }

      if (offset != null) {
        query = query.range(offset, offset + (limit ?? 50) - 1);
      }

      final response = await query;
      final List<dynamic> notificationsData = response as List<dynamic>;

      // Récupérer les statuts de lecture pour l'utilisateur actuel
      final notificationIds = notificationsData.map((n) => n['id'] as String).toList();
      
      Map<String, bool> readStatusMap = {};
      if (notificationIds.isNotEmpty) {
        final readStatusResponse = await _supabase
            .from('notification_read_status')
            .select('notification_id, is_read')
            .eq('user_id', currentUserId!)
            .inFilter('notification_id', notificationIds);
        
        for (final status in readStatusResponse) {
          readStatusMap[status['notification_id']] = status['is_read'] ?? false;
        }
      }

      // Convertir les notifications avec le statut de lecture individuel
      List<AppNotification> notifications = [];
      for (final item in notificationsData) {
        final notification = _convertFromDatabaseWithReadStatus(item, readStatusMap);
        
        // Filtrer selon unreadOnly si nécessaire
        if (unreadOnly == true && notification.isRead) {
          continue;
        }
        
        notifications.add(notification);
      }

      return notifications;
    } catch (e) {
      throw Exception('Failed to get notifications: $e');
    }
  }


  /// Obtenir une notification par son ID
  Future<AppNotification?> getNotificationById(String notificationId) async {
    try {
      final response = await _supabase
          .from('notifications')
          .select()
          .eq('id', notificationId)
          .maybeSingle();

      if (response == null) return null;

      return _convertFromDatabase(response);
    } catch (e) {
      throw Exception('Failed to get notification: $e');
    }
  }

  /// Marquer une notification comme lue pour l'utilisateur actuel
  /// Utilise la table notification_read_status pour le statut individuel
  Future<void> markAsRead(String notificationId) async {
    if (currentUserId == null) {
      throw Exception('User not authenticated');
    }

    try {
      // Vérifier si un enregistrement existe déjà
      final existingRecord = await _supabase
          .from('notification_read_status')
          .select('id')
          .eq('notification_id', notificationId)
          .eq('user_id', currentUserId!)
          .maybeSingle();

      if (existingRecord != null) {
        // Mettre à jour l'enregistrement existant
        await _supabase
            .from('notification_read_status')
            .update({
              'is_read': true,
              'read_at': DateTime.now().toIso8601String(),
            })
            .eq('notification_id', notificationId)
            .eq('user_id', currentUserId!);
      } else {
        // Créer un nouvel enregistrement
        await _supabase
            .from('notification_read_status')
            .insert({
              'notification_id': notificationId,
              'user_id': currentUserId!,
              'is_read': true,
              'read_at': DateTime.now().toIso8601String(),
            });
      }
    } catch (e) {
      throw Exception('Failed to mark notification as read: $e');
    }
  }

  /// Marquer une notification comme non lue pour l'utilisateur actuel
  /// Utilise la table notification_read_status pour le statut individuel
  Future<void> markAsUnread(String notificationId) async {
    if (currentUserId == null) {
      throw Exception('User not authenticated');
    }

    try {
      // Vérifier si un enregistrement existe déjà
      final existingRecord = await _supabase
          .from('notification_read_status')
          .select('id')
          .eq('notification_id', notificationId)
          .eq('user_id', currentUserId!)
          .maybeSingle();

      if (existingRecord != null) {
        // Mettre à jour l'enregistrement existant
        await _supabase
            .from('notification_read_status')
            .update({
              'is_read': false,
              'read_at': null, // Pas de date de lecture puisque non lu
            })
            .eq('notification_id', notificationId)
            .eq('user_id', currentUserId!);
      } else {
        // Créer un nouvel enregistrement
        await _supabase
            .from('notification_read_status')
            .insert({
              'notification_id': notificationId,
              'user_id': currentUserId!,
              'is_read': false,
              'read_at': null,
            });
      }
    } catch (e) {
      throw Exception('Failed to mark notification as unread: $e');
    }
  }

  /// Marquer toutes les notifications comme lues pour l'utilisateur actuel
  /// Utilise la table notification_read_status pour le statut individuel
  Future<void> markAllAsReadForCurrentUser() async {
    if (currentUserId == null) {
      throw Exception('User not authenticated');
    }

    try {
      // Récupérer toutes les notifications
      final allNotifications = await _supabase
          .from('notifications')
          .select('id');

      // Récupérer les statuts de lecture existants pour cet utilisateur
      final notificationIds = (allNotifications as List).map((n) => n['id'] as String).toList();
      
      final existingStatuses = await _supabase
          .from('notification_read_status')
          .select('notification_id')
          .eq('user_id', currentUserId!)
          .inFilter('notification_id', notificationIds);
      
      final existingNotificationIds = (existingStatuses as List)
          .map((status) => status['notification_id'] as String)
          .toSet();

      final readTime = DateTime.now().toIso8601String();
      
      // Mettre à jour les enregistrements existants
      if (existingNotificationIds.isNotEmpty) {
        await _supabase
            .from('notification_read_status')
            .update({
              'is_read': true,
              'read_at': readTime,
            })
            .eq('user_id', currentUserId!)
            .inFilter('notification_id', existingNotificationIds.toList());
      }
      
      // Insérer les nouveaux enregistrements
      final newNotificationIds = notificationIds.where(
        (id) => !existingNotificationIds.contains(id)
      ).toList();
      
      if (newNotificationIds.isNotEmpty) {
        final List<Map<String, dynamic>> newInserts = [];
        for (final notificationId in newNotificationIds) {
          newInserts.add({
            'notification_id': notificationId,
            'user_id': currentUserId!,
            'is_read': true,
            'read_at': readTime,
          });
        }
        
        await _supabase
            .from('notification_read_status')
            .insert(newInserts);
      }
    } catch (e) {
      throw Exception('Failed to mark all notifications as read: $e');
    }
  }

  /// Supprimer une notification
  Future<void> deleteNotification(String notificationId) async {
    if (currentUserId == null) {
      throw Exception('User not authenticated');
    }

    try {
      await _supabase
          .from('notifications')
          .delete()
          .eq('id', notificationId);
    } catch (e) {
      throw Exception('Failed to delete notification: $e');
    }
  }



  /// Compter les notifications non-lues pour l'utilisateur actuel
  /// Utilise la table notification_read_status pour le statut individuel
  Future<int> getUnreadCountForCurrentUser() async {
    if (currentUserId == null) {
      return 0;
    }

    try {
      // Compter toutes les notifications sauf celles créées par l'utilisateur actuel
      final allNotifications = await _supabase
          .from('notifications')
          .select('id')
          .neq('created_by', currentUserId!);

      // Compter celles qui sont marquées comme lues par cet utilisateur
      final readNotifications = await _supabase
          .from('notification_read_status')
          .select('notification_id')
          .eq('user_id', currentUserId!)
          .eq('is_read', true);

      final totalCount = (allNotifications as List).length;
      final readCount = (readNotifications as List).length;
      
      return totalCount - readCount;
    } catch (e) {
      throw Exception('Failed to get unread count: $e');
    }
  }

  /// Obtenir les notifications par type
  Future<List<AppNotification>> getNotificationsByType({
    required NotificationType type,
    int? limit,
  }) async {
    if (currentUserId == null) {
      throw Exception('User not authenticated');
    }

    try {
      var query = _supabase
          .from('notifications')
          .select()
          .eq('type', type.name)
          .order('created_at', ascending: false);

      if (limit != null) {
        query = query.limit(limit);
      }

      final response = await query;
      final List<dynamic> data = response as List<dynamic>;

      // Convertir avec statut de lecture individuel
      final notificationIds = data.map((n) => n['id'] as String).toList();
      Map<String, bool> readStatusMap = {};
      if (notificationIds.isNotEmpty) {
        final readStatusResponse = await _supabase
            .from('notification_read_status')
            .select('notification_id, is_read')
            .eq('user_id', currentUserId!)
            .inFilter('notification_id', notificationIds);
        
        for (final status in readStatusResponse) {
          readStatusMap[status['notification_id']] = status['is_read'] ?? false;
        }
      }

      return data.map((item) => _convertFromDatabaseWithReadStatus(item, readStatusMap)).toList();
    } catch (e) {
      throw Exception('Failed to get notifications by type: $e');
    }
  }

  /// Nettoyer les notifications expirées (appelé automatiquement par le serveur)
  Future<void> cleanExpiredNotifications() async {
    try {
      await _supabase.rpc('clean_expired_notifications');
    } catch (e) {
      // Cette fonction peut échouer si elle n'existe pas côté serveur
      // On ignore l'erreur pour éviter de casser l'application
      debugPrint('Warning: Failed to clean expired notifications: $e');
    }
  }

  /// Obtenir des statistiques sur les notifications
  Future<Map<String, dynamic>> getNotificationStats() async {
    if (currentUserId == null) {
      return {};
    }

    try {
      // Compter par type
      final typeStats = <String, int>{};
      for (final type in NotificationType.values) {
        final response = await _supabase
            .from('notifications')
            .select('id')
            .eq('type', type.name);
        
        final List<dynamic> data = response as List<dynamic>;
        typeStats[type.name] = data.length;
      }

      // Compter total
      final totalResponse = await _supabase
          .from('notifications')
          .select('id');

      final List<dynamic> totalData = totalResponse as List<dynamic>;
      final unreadCount = await getUnreadCountForCurrentUser();

      return {
        'total': totalData.length,
        'unread': unreadCount,
        'by_type': typeStats,
      };
    } catch (e) {
      throw Exception('Failed to get notification stats: $e');
    }
  }

  /// Méthodes de convenance pour créer des notifications spécifiques

  /// Créer une notification de réservation
  Future<String> createBookingNotification({
    required String title,
    required String message,
    required NotificationType type, // bookingAdded, bookingCancelled, etc.
    required String bookingId,
    required String customerName,
    required DateTime bookingDateTime,
  }) async {
    return createNotification(
      title: title,
      message: message,
      type: type,
      priority: NotificationPriority.medium,
      data: {
        'booking_id': bookingId,
        'customer_name': customerName,
        'booking_date_time': bookingDateTime.toIso8601String(),
      },
    );
  }

  /// Créer une notification d'alerte de stock
  Future<String> createStockAlertNotification({
    required String itemName,
    required int currentQuantity,
    required int alertThreshold,
  }) async {
    return createNotification(
      title: 'Alerte stock critique',
      message: '$itemName: stock critique ($currentQuantity/$alertThreshold)',
      type: NotificationType.stockAlert,
      priority: NotificationPriority.urgent,
      data: {
        'item_name': itemName,
        'current_quantity': currentQuantity,
        'alert_threshold': alertThreshold,
      },
    );
  }

  /// Créer une notification de mise à jour système
  Future<String> createSystemUpdateNotification({
    required String version,
    required String description,
  }) async {
    return createNotification(
      title: 'Mise à jour disponible',
      message: 'Version $version disponible: $description',
      type: NotificationType.systemUpdate,
      priority: NotificationPriority.high,
      data: {
        'version': version,
        'description': description,
      },
    );
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

  /// Convertir une notification avec statut de lecture individuel
  AppNotification _convertFromDatabaseWithReadStatus(Map<String, dynamic> data, Map<String, bool> readStatusMap) {
    final notificationId = data['id'] as String;
    final isRead = readStatusMap[notificationId] ?? false; // Pas de statut = non lu

    return AppNotification(
      id: notificationId,
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
      isRead: isRead, // Statut de lecture individuel
      createdBy: data['created_by'] as String?,
    );
  }

}