import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../repositories/notification_repository.dart';
import '../models/notification_model.dart';
import '../services/realtime_notification_service.dart';
import '../widgets/custom_dialog.dart';

class NotificationsScreen extends StatefulWidget {
  const NotificationsScreen({super.key});

  @override
  State<NotificationsScreen> createState() => _NotificationsScreenState();
}

class _NotificationsScreenState extends State<NotificationsScreen> {
  final NotificationRepository _notificationRepository = NotificationRepository();
  final SupabaseClient _supabase = Supabase.instance.client;
  List<AppNotification> _notifications = [];
  bool _isLoading = true;
  bool _showUnreadOnly = true;
  String? _error;
  
  // Cache pour les noms d'utilisateurs
  final Map<String, String> _userNamesCache = {};
  
  // Listener Realtime
  RealtimeNotificationService? _realtimeService;

  @override
  void initState() {
    super.initState();
    _loadNotifications();
    
    // Écouter les changements du service Realtime (exactement comme le badge)
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _realtimeService = Provider.of<RealtimeNotificationService>(context, listen: false);
      _realtimeService?.addListener(_onRealtimeNotification);
    });
  }
  
  void _onRealtimeNotification() {
    if (mounted) {
      _loadNotifications(showLoading: false); // Pas de spinner pour les mises à jour Realtime
    }
  }
  
  @override
  void dispose() {
    _realtimeService?.removeListener(_onRealtimeNotification);
    super.dispose();
  }

  Future<void> _loadNotifications({bool showLoading = true}) async {
    if (!mounted) return;
    
    try {
      if (showLoading && mounted) {
        setState(() {
          _isLoading = true;
          _error = null;
        });
      }
      
      // Charger directement depuis la base de données avec Realtime
      final dbNotifications = await _notificationRepository.getNotificationsForCurrentUser(
        limit: 100,
      );
      
      if (!mounted) return;
      
      // Filtrer selon le toggle
      List<AppNotification> filteredNotifications;
      if (_showUnreadOnly) {
        // Afficher seulement les non-lues
        filteredNotifications = dbNotifications.where((n) => !n.isRead).toList();
      } else {
        // Afficher seulement les lues
        filteredNotifications = dbNotifications.where((n) => n.isRead).toList();
      }
      
      if (mounted) {
        setState(() {
          _notifications = filteredNotifications;
          if (showLoading) {
            _isLoading = false;
          }
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _error = e.toString();
          if (showLoading) {
            _isLoading = false;
          }
        });
      }
    }
  }

  Future<void> _toggleReadFilter() async {
    if (mounted) {
      setState(() {
        _showUnreadOnly = !_showUnreadOnly;
      });
    }
    await _loadNotifications();
  }

  Future<void> _markAllAsRead() async {
    try {
      await _notificationRepository.markAllAsReadForCurrentUser();
      await _loadNotifications();
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Toutes les notifications marquées comme lues')),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Erreur: $e')),
        );
      }
    }
  }

  Future<void> _markAsRead(String notificationId) async {
    try {
      await _notificationRepository.markAsRead(notificationId);
      await _loadNotifications();
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Erreur: $e')),
        );
      }
    }
  }

  Future<void> _markAsUnread(String notificationId) async {
    try {
      await _notificationRepository.markAsUnread(notificationId);
      await _loadNotifications();
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Notification marquée comme non lue')),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Erreur: $e')),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
          appBar: AppBar(
            title: const Text('Notifications'),
            actions: [
              IconButton(
                icon: Icon(
                  _showUnreadOnly ? Icons.mark_email_unread : Icons.mark_email_read,
                ),
                onPressed: _toggleReadFilter,
                tooltip: _showUnreadOnly ? 'Afficher les notifications lues' : 'Afficher les notifications non-lues',
              ),
              IconButton(
                icon: const Icon(Icons.done_all),
                onPressed: _markAllAsRead,
                tooltip: 'Marquer tout comme lu',
              ),
            ],
          ),
          body: Column(
            children: [
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Theme.of(context).colorScheme.primaryContainer.withAlpha((255 * 0.3).round()),
                  border: Border(
                    bottom: BorderSide(
                      color: Theme.of(context).colorScheme.outline.withAlpha((255 * 0.2).round()),
                    ),
                  ),
                ),
                child: Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(6),
                      decoration: BoxDecoration(
                        color: Theme.of(context).colorScheme.primary.withAlpha((255 * 0.1).round()),
                        borderRadius: BorderRadius.circular(6),
                      ),
                      child: Icon(
                        _showUnreadOnly ? Icons.mark_email_unread : Icons.mark_email_read,
                        size: 16,
                        color: Theme.of(context).colorScheme.primary,
                      ),
                    ),
                    const SizedBox(width: 12),
                    Text(
                      _showUnreadOnly ? 'Affichage: Non-lues uniquement' : 'Affichage: Lues uniquement',
                      style: TextStyle(
                        color: Theme.of(context).colorScheme.primary,
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
              ),
              Expanded(
                child: _buildNotificationsList(),
              ),
            ],
          ),
        );
  }

  Widget _buildNotificationsList() {
    if (_isLoading) {
      return const Center(
        child: CircularProgressIndicator(),
      );
    }

    if (_error != null) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.error_outline,
              size: 64,
              color: Theme.of(context).colorScheme.error,
            ),
            const SizedBox(height: 16),
            Text(
              'Erreur de chargement',
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                color: Theme.of(context).colorScheme.error,
                fontWeight: FontWeight.w500,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              _error!,
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                color: Theme.of(context).colorScheme.onSurfaceVariant,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 16),
            ElevatedButton(
              onPressed: _loadNotifications,
              child: const Text('Réessayer'),
            ),
          ],
        ),
      );
    }

    if (_notifications.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              _showUnreadOnly ? Icons.mark_email_read : Icons.mark_email_unread,
              size: 64,
              color: Theme.of(context).colorScheme.onSurfaceVariant,
            ),
            const SizedBox(height: 16),
            Text(
              _showUnreadOnly 
                  ? 'Aucune notification non-lue' 
                  : 'Aucune notification lue',
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                color: Theme.of(context).colorScheme.onSurfaceVariant,
                fontWeight: FontWeight.w500,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              _showUnreadOnly
                  ? 'Toutes vos notifications sont à jour'
                  : 'Les notifications lues apparaîtront ici',
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                color: Theme.of(context).colorScheme.onSurfaceVariant,
              ),
            ),
          ],
        ),
      );
    }

    return RefreshIndicator(
      onRefresh: _loadNotifications,
      child: ListView.separated(
        padding: const EdgeInsets.all(16),
        itemCount: _notifications.length,
        separatorBuilder: (context, index) => const SizedBox(height: 8),
        itemBuilder: (context, index) {
          final notification = _notifications[index];
          return NotificationCard(
            notification: notification,
            onTap: () => _handleNotificationTap(context, notification),
            onMarkAsRead: () => _markAsRead(notification.id),
            onMarkAsUnread: () => _markAsUnread(notification.id),
          );
        },
      ),
    );
  }

  void _handleNotificationTap(BuildContext context, AppNotification notification) {
    // Ne plus marquer automatiquement comme lu à l'ouverture
    // L'utilisateur peut maintenant choisir manuellement

    // Naviguer selon le type de notification
    switch (notification.type) {
      case NotificationType.bookingAdded:
      case NotificationType.bookingCancelled:
      case NotificationType.bookingDeleted:
        // Naviguer vers l'écran des réservations si disponible
        _navigateToBookings(context, notification);
        break;
      case NotificationType.stockAlert:
      case NotificationType.stockUpdate:
        // Naviguer vers l'écran de stock si disponible
        _navigateToStock(context, notification);
        break;
      default:
        // Afficher les détails dans un dialog
        _showNotificationDetails(context, notification);
        break;
    }
  }

  void _navigateToBookings(BuildContext context, AppNotification notification) {
    // Tenter de naviguer vers l'écran des réservations
    try {
      Navigator.of(context).pushNamed('/bookings');
    } catch (e) {
      // Si la route n'existe pas, afficher les détails
      _showNotificationDetails(context, notification);
    }
  }

  void _navigateToStock(BuildContext context, AppNotification notification) {
    // Tenter de naviguer vers l'écran de stock
    try {
      Navigator.of(context).pushNamed('/stock');
    } catch (e) {
      // Si la route n'existe pas, afficher les détails
      _showNotificationDetails(context, notification);
    }
  }

  void _showNotificationDetails(BuildContext context, AppNotification notification) {
    final theme = Theme.of(context);
    
    showDialog(
      context: context,
      builder: (context) => CustomDialog(
        title: notification.title,
        titleIcon: Icon(
          _getNotificationIcon(notification.type),
          color: _getNotificationColor(notification.type),
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Message principal
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: theme.colorScheme.primaryContainer.withAlpha((255 * 0.1).round()),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(
                  color: theme.colorScheme.primary.withAlpha((255 * 0.2).round()),
                ),
              ),
              child: Text(
                notification.message,
                style: theme.textTheme.bodyLarge?.copyWith(
                  color: theme.colorScheme.onSurface,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ),
            const SizedBox(height: 20),
            
            // Informations essentielles
            _buildDetailRow(
              icon: Icons.person,
              label: 'Client',
              value: _getClientName(notification),
              theme: theme,
            ),
            const SizedBox(height: 16),
            
            _buildDetailRow(
              icon: Icons.account_circle,
              label: 'Action de',
              value: _getCreatorName(notification),
              theme: theme,
            ),
            const SizedBox(height: 16),
            
            _buildDetailRow(
              icon: Icons.calendar_today,
              label: 'Date et heure',
              value: _formatDetailedDateTime(notification.timestamp),
              theme: theme,
            ),
            const SizedBox(height: 16),
            
            _buildDetailRow(
              icon: _getPriorityIcon(notification.priority),
              label: 'Priorité',
              value: _getPriorityDisplayName(notification.priority),
              theme: theme,
              valueColor: _getPriorityColor(notification.priority),
            ),
            const SizedBox(height: 16),
            
            _buildDetailRow(
              icon: Icons.schedule,
              label: 'Il y a',
              value: _formatTimeAgo(notification.timestamp),
              theme: theme,
            ),
          ],
        ),
        actions: [
          if (!notification.isRead)
            TextButton.icon(
              onPressed: () {
                _markAsRead(notification.id);
                Navigator.of(context).pop();
              },
              icon: Icon(Icons.mark_email_read, size: 16),
              label: const Text('Marquer comme lu'),
            ),
          if (notification.isRead)
            TextButton.icon(
              onPressed: () {
                _markAsUnread(notification.id);
                Navigator.of(context).pop();
              },
              icon: Icon(Icons.mark_email_unread, size: 16),
              label: const Text('Marquer comme non lu'),
              style: TextButton.styleFrom(
                foregroundColor: Theme.of(context).colorScheme.primary,
              ),
            ),
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Fermer'),
          ),
        ],
      ),
    );
  }

  Widget _buildDetailRow({
    required IconData icon,
    required String label,
    required String value,
    required ThemeData theme,
    Color? valueColor,
  }) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: theme.colorScheme.primary.withAlpha((255 * 0.1).round()),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Icon(
            icon,
            size: 20,
            color: theme.colorScheme.primary,
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                label,
                style: theme.textTheme.bodySmall?.copyWith(
                  color: theme.colorScheme.onSurfaceVariant,
                  fontWeight: FontWeight.w500,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                value,
                style: theme.textTheme.bodyLarge?.copyWith(
                  color: valueColor ?? theme.colorScheme.onSurface,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  String _getClientName(AppNotification notification) {
    if (notification.data != null) {
      return notification.data!['customer_name'] ??       // Clé principale utilisée
             'Client non spécifié';
    }
    return 'Client non spécifié';
  }

  String _getCreatorName(AppNotification notification) {
    // Le champ createdBy contient l'ID utilisateur, pas le nom
    final userId = notification.createdBy;
    if (userId == null) return 'Utilisateur inconnu';
    
    // Si les données de la notification contiennent déjà le nom, l'utiliser
    if (notification.data != null) {
      final creatorName = notification.data!['creator_name'] ?? 
                         notification.data!['employee_name'] ?? 
                         notification.data!['user_name'];
      if (creatorName != null) return creatorName;
    }
    
    // Vérifier le cache
    if (_userNamesCache.containsKey(userId)) {
      return _userNamesCache[userId]!;
    }
    
    // Lancer la requête asynchrone et stocker en cache
    _fetchUserName(userId);
    
    // Fallback : afficher l'ID en attendant la résolution
    return 'Utilisateur ($userId)';
  }

  Future<void> _fetchUserName(String userId) async {
    try {
      // Éviter les requêtes multiples pour le même utilisateur
      if (_userNamesCache.containsKey(userId)) return;
      
      // Requête simple pour récupérer le nom
      final response = await _supabase
          .from('user_settings')
          .select('first_name, last_name')
          .eq('user_id', userId)
          .maybeSingle();
      
      if (response != null) {
        final firstName = response['first_name'] ?? '';
        final lastName = response['last_name'] ?? '';
        final fullName = '$firstName $lastName'.trim();
        
        // Stocker en cache
        _userNamesCache[userId] = fullName.isNotEmpty ? fullName : 'Utilisateur inconnu';
      } else {
        // Utilisateur non trouvé
        _userNamesCache[userId] = 'Utilisateur inconnu';
      }
      
      // Mettre à jour l'UI
      if (mounted) {
        setState(() {});
      }
    } catch (e) {
      // En cas d'erreur, utiliser un nom par défaut
      _userNamesCache[userId] = 'Utilisateur inconnu';
    }
  }

  String _formatDetailedDateTime(DateTime dateTime) {
    final weekdays = ['Lundi', 'Mardi', 'Mercredi', 'Jeudi', 'Vendredi', 'Samedi', 'Dimanche'];
    final months = ['Jan', 'Fév', 'Mar', 'Avr', 'Mai', 'Jun', 'Jul', 'Aoû', 'Sep', 'Oct', 'Nov', 'Déc'];
    
    final weekday = weekdays[dateTime.weekday - 1];
    final day = dateTime.day;
    final month = months[dateTime.month - 1];
    final year = dateTime.year;
    final hour = dateTime.hour.toString().padLeft(2, '0');
    final minute = dateTime.minute.toString().padLeft(2, '0');
    
    return '$weekday $day $month $year à ${hour}h$minute';
  }

  String _formatTimeAgo(DateTime dateTime) {
    final now = DateTime.now();
    final difference = now.difference(dateTime);

    if (difference.inSeconds < 60) {
      return 'quelques secondes';
    } else if (difference.inMinutes < 60) {
      final minutes = difference.inMinutes;
      return '$minutes minute${minutes > 1 ? 's' : ''}';
    } else if (difference.inHours < 24) {
      final hours = difference.inHours;
      return '$hours heure${hours > 1 ? 's' : ''}';
    } else if (difference.inDays < 30) {
      final days = difference.inDays;
      return '$days jour${days > 1 ? 's' : ''}';
    } else if (difference.inDays < 365) {
      final months = (difference.inDays / 30).floor();
      return '$months mois';
    } else {
      final years = (difference.inDays / 365).floor();
      return '$years an${years > 1 ? 's' : ''}';
    }
  }

  String _getPriorityDisplayName(NotificationPriority priority) {
    switch (priority) {
      case NotificationPriority.low:
        return 'Faible';
      case NotificationPriority.medium:
        return 'Moyenne';
      case NotificationPriority.high:
        return 'Élevée';
      case NotificationPriority.urgent:
        return 'Urgente';
    }
  }

  // Helper methods for the main screen
  IconData _getNotificationIcon(NotificationType type) {
    switch (type) {
      case NotificationType.consumption:
        return Icons.local_drink;
      case NotificationType.stockUpdate:
        return Icons.inventory;
      case NotificationType.bookingAdded:
        return Icons.event_available;
      case NotificationType.bookingCancelled:
        return Icons.event_busy;
      case NotificationType.bookingDeleted:
        return Icons.delete_outline;
      case NotificationType.paymentReceived:
        return Icons.payment;
      case NotificationType.stockAlert:
        return Icons.warning;
      case NotificationType.systemUpdate:
        return Icons.system_update;
    }
  }

  Color _getNotificationColor(NotificationType type) {
    final theme = Theme.of(context);
    switch (type) {
      case NotificationType.consumption:
        return theme.colorScheme.primary;
      case NotificationType.stockUpdate:
        return Colors.green.shade600;
      case NotificationType.bookingAdded:
        return Colors.green.shade600;
      case NotificationType.bookingCancelled:
        return Colors.orange.shade600;
      case NotificationType.bookingDeleted:
        return theme.colorScheme.error;
      case NotificationType.paymentReceived:
        return Colors.teal.shade600;
      case NotificationType.stockAlert:
        return theme.colorScheme.error;
      case NotificationType.systemUpdate:
        return Colors.purple.shade600;
    }
  }

  IconData _getPriorityIcon(NotificationPriority priority) {
    switch (priority) {
      case NotificationPriority.low:
        return Icons.keyboard_arrow_down;
      case NotificationPriority.medium:
        return Icons.remove;
      case NotificationPriority.high:
        return Icons.keyboard_arrow_up;
      case NotificationPriority.urgent:
        return Icons.priority_high;
    }
  }

  Color _getPriorityColor(NotificationPriority priority) {
    final theme = Theme.of(context);
    switch (priority) {
      case NotificationPriority.low:
        return theme.colorScheme.onSurfaceVariant;
      case NotificationPriority.medium:
        return theme.colorScheme.primary;
      case NotificationPriority.high:
        return Colors.orange.shade600;
      case NotificationPriority.urgent:
        return theme.colorScheme.error;
    }
  }
}

class NotificationCard extends StatelessWidget {
  final AppNotification notification;
  final VoidCallback? onTap;
  final VoidCallback? onMarkAsRead;
  final VoidCallback? onMarkAsUnread;

  const NotificationCard({
    super.key,
    required this.notification,
    this.onTap,
    this.onMarkAsRead,
    this.onMarkAsUnread,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    
    return Container(
      decoration: BoxDecoration(
        color: theme.colorScheme.surface,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: notification.isRead 
              ? theme.colorScheme.outline.withAlpha((255 * 0.15).round())
              : theme.colorScheme.primary.withAlpha((255 * 0.4).round()),
          width: notification.isRead ? 1 : 1.5,
        ),
        boxShadow: [
          BoxShadow(
            color: theme.colorScheme.shadow.withAlpha((255 * 0.05).round()),
            blurRadius: notification.isRead ? 1 : 2,
            offset: const Offset(0, 1),
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(12),
          child: Container(
            padding: const EdgeInsets.all(12),
            child: Row(
              children: [
                // Icône compacte
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: _getTypeColor().withAlpha((255 * 0.12).round()),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Icon(
                    _getTypeIcon(),
                    color: _getTypeColor(),
                    size: 18,
                  ),
                ),
                const SizedBox(width: 12),
                // Contenu principal
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Titre avec indicateur de lecture
                      Row(
                        children: [
                          Expanded(
                            child: Text(
                              notification.title,
                              style: theme.textTheme.titleSmall?.copyWith(
                                fontWeight: notification.isRead ? FontWeight.w500 : FontWeight.w600,
                                color: notification.isRead 
                                    ? theme.colorScheme.onSurface
                                    : theme.colorScheme.primary,
                              ),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                          if (!notification.isRead)
                            Container(
                              width: 8,
                              height: 8,
                              margin: const EdgeInsets.only(left: 8),
                              decoration: BoxDecoration(
                                color: theme.colorScheme.primary,
                                borderRadius: BorderRadius.circular(4),
                              ),
                            ),
                        ],
                      ),
                      const SizedBox(height: 6),
                      // Message complet
                      Text(
                        notification.message,
                        style: theme.textTheme.bodyMedium?.copyWith(
                          color: theme.colorScheme.onSurfaceVariant,
                        ),
                      ),
                      const SizedBox(height: 6),
                      // Informations compactes sur une ligne
                      Row(
                        children: [
                          // Chip de priorité plus petit
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                            decoration: BoxDecoration(
                              color: _getPriorityColor().withAlpha((255 * 0.12).round()),
                              borderRadius: BorderRadius.circular(6),
                            ),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Icon(
                                  _getPriorityIcon(),
                                  size: 10,
                                  color: _getPriorityColor(),
                                ),
                                const SizedBox(width: 3),
                                Text(
                                  _getPriorityDisplayName(notification.priority),
                                  style: theme.textTheme.bodySmall?.copyWith(
                                    color: _getPriorityColor(),
                                    fontSize: 10,
                                    fontWeight: FontWeight.w500,
                                  ),
                                ),
                              ],
                            ),
                          ),
                          const SizedBox(width: 8),
                          // Timestamp
                          Text(
                            _formatTime(notification.timestamp),
                            style: theme.textTheme.bodySmall?.copyWith(
                              color: theme.colorScheme.onSurfaceVariant,
                              fontSize: 11,
                            ),
                          ),
                          const Spacer(),
                          // Action compacte
                          if (!notification.isRead)
                            GestureDetector(
                              onTap: onMarkAsRead,
                              child: Container(
                                padding: const EdgeInsets.all(4),
                                decoration: BoxDecoration(
                                  color: theme.colorScheme.primary.withAlpha((255 * 0.1).round()),
                                  borderRadius: BorderRadius.circular(4),
                                ),
                                child: Icon(
                                  Icons.mark_email_read,
                                  size: 16,
                                  color: theme.colorScheme.primary,
                                ),
                              ),
                            ),
                          if (notification.isRead)
                            GestureDetector(
                              onTap: onMarkAsUnread,
                              child: Container(
                                padding: const EdgeInsets.all(4),
                                decoration: BoxDecoration(
                                  color: theme.colorScheme.secondary.withAlpha((255 * 0.1).round()),
                                  borderRadius: BorderRadius.circular(4),
                                ),
                                child: Icon(
                                  Icons.mark_email_unread,
                                  size: 16,
                                  color: theme.colorScheme.secondary,
                                ),
                              ),
                            ),
                        ],
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  IconData _getTypeIcon() {
    switch (notification.type) {
      case NotificationType.consumption:
        return Icons.local_drink;
      case NotificationType.stockUpdate:
        return Icons.inventory;
      case NotificationType.bookingAdded:
        return Icons.event_available;
      case NotificationType.bookingCancelled:
        return Icons.event_busy;
      case NotificationType.bookingDeleted:
        return Icons.delete_outline;
      case NotificationType.paymentReceived:
        return Icons.payment;
      case NotificationType.stockAlert:
        return Icons.warning;
      case NotificationType.systemUpdate:
        return Icons.system_update;
    }
  }

  Color _getTypeColor() {
    switch (notification.type) {
      case NotificationType.consumption:
        return Colors.blue.shade600;
      case NotificationType.stockUpdate:
        return Colors.green.shade600;
      case NotificationType.bookingAdded:
        return Colors.green.shade600;
      case NotificationType.bookingCancelled:
        return Colors.orange.shade600;
      case NotificationType.bookingDeleted:
        return Colors.red.shade600;
      case NotificationType.paymentReceived:
        return Colors.teal.shade600;
      case NotificationType.stockAlert:
        return Colors.red.shade600;
      case NotificationType.systemUpdate:
        return Colors.purple.shade600;
    }
  }

  IconData _getPriorityIcon() {
    switch (notification.priority) {
      case NotificationPriority.low:
        return Icons.keyboard_arrow_down;
      case NotificationPriority.medium:
        return Icons.remove;
      case NotificationPriority.high:
        return Icons.keyboard_arrow_up;
      case NotificationPriority.urgent:
        return Icons.priority_high;
    }
  }

  Color _getPriorityColor() {
    switch (notification.priority) {
      case NotificationPriority.low:
        return Colors.grey.shade600;
      case NotificationPriority.medium:
        return Colors.blue.shade600;
      case NotificationPriority.high:
        return Colors.orange.shade600;
      case NotificationPriority.urgent:
        return Colors.red.shade600;
    }
  }

  String _formatTime(DateTime dateTime) {
    final now = DateTime.now();
    final difference = now.difference(dateTime);

    if (difference.inMinutes < 1) {
      return 'maintenant';
    } else if (difference.inHours < 1) {
      return '${difference.inMinutes}min';
    } else if (difference.inDays < 1) {
      return '${difference.inHours}h';
    } else {
      return '${dateTime.day}/${dateTime.month}';
    }
  }

  String _getPriorityDisplayName(NotificationPriority priority) {
    switch (priority) {
      case NotificationPriority.low:
        return 'Faible';
      case NotificationPriority.medium:
        return 'Moyenne';
      case NotificationPriority.high:
        return 'Élevée';
      case NotificationPriority.urgent:
        return 'Urgente';
    }
  }
}