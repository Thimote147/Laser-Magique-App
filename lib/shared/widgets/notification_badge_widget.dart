import 'package:flutter/material.dart';
import '../repositories/notification_repository.dart';

class NotificationBadge extends StatefulWidget {
  final VoidCallback? onTap;
  final Color? iconColor;
  final double iconSize;

  const NotificationBadge({
    super.key,
    this.onTap,
    this.iconColor,
    this.iconSize = 24,
  });

  @override
  State<NotificationBadge> createState() => _NotificationBadgeState();
}

class _NotificationBadgeState extends State<NotificationBadge> {
  final NotificationRepository _notificationRepository = NotificationRepository();
  int _unreadCount = 0;
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadUnreadCount();
    // Actualiser le compte toutes les 30 secondes
    _startPeriodicRefresh();
  }

  void _startPeriodicRefresh() {
    Future.delayed(const Duration(seconds: 30), () {
      if (mounted) {
        _loadUnreadCount();
        _startPeriodicRefresh();
      }
    });
  }

  Future<void> _loadUnreadCount() async {
    try {
      final count = await _notificationRepository.getUnreadCountForCurrentUser();
      if (mounted) {
        setState(() {
          _unreadCount = count;
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _unreadCount = 0;
          _isLoading = false;
        });
      }
    }
  }

  void _navigateToNotifications(BuildContext context) async {
    await Navigator.of(context).pushNamed('/notifications');
    // Rafraîchir le compte après retour de l'écran des notifications
    if (mounted) {
      _loadUnreadCount();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        IconButton(
          icon: Icon(
            Icons.notifications,
            color: widget.iconColor,
            size: widget.iconSize,
          ),
          onPressed: widget.onTap ?? () => _navigateToNotifications(context),
          tooltip: 'Notifications',
        ),
        if (!_isLoading && _unreadCount > 0)
          Positioned(
            right: 8,
            top: 8,
            child: Container(
              padding: const EdgeInsets.all(2),
              decoration: BoxDecoration(
                color: Colors.red,
                borderRadius: BorderRadius.circular(10),
                border: Border.all(color: Colors.white, width: 1),
              ),
              constraints: const BoxConstraints(
                minWidth: 16,
                minHeight: 16,
              ),
              child: Text(
                _unreadCount > 99 ? '99+' : _unreadCount.toString(),
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
  }
}

/// Widget simple pour afficher juste l'icône avec badge sans bouton
class NotificationBadgeIcon extends StatefulWidget {
  final Color? iconColor;
  final double iconSize;

  const NotificationBadgeIcon({
    super.key,
    this.iconColor,
    this.iconSize = 24,
  });

  @override
  State<NotificationBadgeIcon> createState() => _NotificationBadgeIconState();
}

class _NotificationBadgeIconState extends State<NotificationBadgeIcon> {
  final NotificationRepository _notificationRepository = NotificationRepository();
  int _unreadCount = 0;
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadUnreadCount();
    // Actualiser le compte toutes les 30 secondes
    _startPeriodicRefresh();
  }

  void _startPeriodicRefresh() {
    Future.delayed(const Duration(seconds: 30), () {
      if (mounted) {
        _loadUnreadCount();
        _startPeriodicRefresh();
      }
    });
  }

  Future<void> _loadUnreadCount() async {
    try {
      final count = await _notificationRepository.getUnreadCountForCurrentUser();
      if (mounted) {
        setState(() {
          _unreadCount = count;
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _unreadCount = 0;
          _isLoading = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        Icon(
          Icons.notifications,
          color: widget.iconColor ?? Theme.of(context).iconTheme.color,
          size: widget.iconSize,
        ),
        if (!_isLoading && _unreadCount > 0)
          Positioned(
            right: 0,
            top: 0,
            child: Container(
              padding: const EdgeInsets.all(2),
              decoration: BoxDecoration(
                color: Colors.red,
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: Colors.white, width: 1),
              ),
              constraints: const BoxConstraints(
                minWidth: 14,
                minHeight: 14,
              ),
              child: Text(
                _unreadCount > 99 ? '99+' : _unreadCount.toString(),
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 9,
                  fontWeight: FontWeight.bold,
                ),
                textAlign: TextAlign.center,
              ),
            ),
          ),
      ],
    );
  }
}