import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../models/notification_model.dart';
import '../services/notification_service.dart';

class NotificationIcon extends StatelessWidget {
  const NotificationIcon({super.key});

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider.value(
      value: NotificationService(),
      child: Consumer<NotificationService>(
        builder: (context, notificationService, child) {
          final unreadCount = notificationService.unreadCount;
          
          return Stack(
            children: [
              IconButton(
                icon: const Icon(Icons.notifications),
                onPressed: () {
                  showDialog(
                    context: context,
                    builder: (context) => NotificationDialog(),
                  );
                },
              ),
              if (unreadCount > 0)
                Positioned(
                  right: 8,
                  top: 8,
                  child: Container(
                    padding: const EdgeInsets.all(2),
                    decoration: BoxDecoration(
                      color: Colors.red,
                      borderRadius: BorderRadius.circular(10),
                    ),
                    constraints: const BoxConstraints(
                      minWidth: 16,
                      minHeight: 16,
                    ),
                    child: Text(
                      unreadCount > 99 ? '99+' : unreadCount.toString(),
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 10,
                        fontWeight: FontWeight.bold,
                      ),
                      textAlign: TextAlign.center,
                    ),
                  ),
                ),
            ],
          );
        },
      ),
    );
  }
}

class NotificationDialog extends StatelessWidget {
  const NotificationDialog({super.key});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    
    return Dialog(
      child: Container(
        width: MediaQuery.of(context).size.width * 0.9,
        height: MediaQuery.of(context).size.height * 0.7,
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'Notifications',
                  style: theme.textTheme.headlineSmall?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),
                Row(
                  children: [
                    TextButton(
                      onPressed: () {
                        NotificationService().markAllAsRead();
                      },
                      child: const Text('Tout marquer lu'),
                    ),
                    TextButton(
                      onPressed: () {
                        NotificationService().clearReadNotifications();
                      },
                      child: const Text('Effacer lues'),
                    ),
                    IconButton(
                      icon: const Icon(Icons.close),
                      onPressed: () => Navigator.of(context).pop(),
                    ),
                  ],
                ),
              ],
            ),
            const Divider(),
            Expanded(
              child: Consumer<NotificationService>(
                builder: (context, notificationService, child) {
                  final notifications = notificationService.notifications;
                  
                  if (notifications.isEmpty) {
                    return const Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(
                            Icons.notifications_none,
                            size: 64,
                            color: Colors.grey,
                          ),
                          SizedBox(height: 16),
                          Text(
                            'Aucune notification',
                            style: TextStyle(
                              fontSize: 18,
                              color: Colors.grey,
                            ),
                          ),
                        ],
                      ),
                    );
                  }
                  
                  return ListView.builder(
                    itemCount: notifications.length,
                    itemBuilder: (context, index) {
                      final notification = notifications[index];
                      return NotificationTile(notification: notification);
                    },
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class NotificationTile extends StatelessWidget {
  final AppNotification notification;
  
  const NotificationTile({
    super.key,
    required this.notification,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    
    return Card(
      margin: const EdgeInsets.symmetric(vertical: 4),
      color: notification.isRead 
          ? theme.cardColor 
          : theme.colorScheme.primaryContainer.withValues(alpha: 0.1),
      child: ListTile(
        leading: CircleAvatar(
          backgroundColor: _getPriorityColor(notification.priority),
          child: Icon(
            _getNotificationIcon(notification.type),
            color: Colors.white,
            size: 20,
          ),
        ),
        title: Text(
          notification.title,
          style: TextStyle(
            fontWeight: notification.isRead ? FontWeight.normal : FontWeight.bold,
          ),
        ),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(notification.message),
            const SizedBox(height: 4),
            Text(
              _formatTimestamp(notification.timestamp),
              style: theme.textTheme.bodySmall?.copyWith(
                color: Colors.grey,
              ),
            ),
          ],
        ),
        trailing: PopupMenuButton(
          itemBuilder: (context) => [
            PopupMenuItem(
              value: 'mark_read',
              child: Text(notification.isRead ? 'Marquer non lu' : 'Marquer lu'),
            ),
            const PopupMenuItem(
              value: 'delete',
              child: Text('Supprimer'),
            ),
          ],
          onSelected: (value) {
            switch (value) {
              case 'mark_read':
                if (!notification.isRead) {
                  NotificationService().markAsRead(notification.id);
                }
                break;
              case 'delete':
                NotificationService().removeNotification(notification.id);
                break;
            }
          },
        ),
        onTap: () {
          if (!notification.isRead) {
            NotificationService().markAsRead(notification.id);
          }
        },
      ),
    );
  }

  Color _getPriorityColor(NotificationPriority priority) {
    switch (priority) {
      case NotificationPriority.low:
        return Colors.grey;
      case NotificationPriority.medium:
        return Colors.blue;
      case NotificationPriority.high:
        return Colors.orange;
      case NotificationPriority.urgent:
        return Colors.red;
    }
  }

  IconData _getNotificationIcon(NotificationType type) {
    switch (type) {
      case NotificationType.consumption:
        return Icons.restaurant;
      case NotificationType.stockUpdate:
        return Icons.inventory;
      case NotificationType.bookingAdded:
        return Icons.event_note;
      case NotificationType.bookingCancelled:
        return Icons.event_busy;
      case NotificationType.bookingDeleted:
        return Icons.delete;
      case NotificationType.paymentReceived:
        return Icons.payment;
      case NotificationType.stockAlert:
        return Icons.warning;
      case NotificationType.systemUpdate:
        return Icons.system_update;
    }
  }

  String _formatTimestamp(DateTime timestamp) {
    final now = DateTime.now();
    final difference = now.difference(timestamp);
    
    if (difference.inMinutes < 1) {
      return 'À l\'instant';
    } else if (difference.inMinutes < 60) {
      return 'Il y a ${difference.inMinutes} min';
    } else if (difference.inHours < 24) {
      return 'Il y a ${difference.inHours}h';
    } else {
      return 'Il y a ${difference.inDays} jour(s)';
    }
  }
}