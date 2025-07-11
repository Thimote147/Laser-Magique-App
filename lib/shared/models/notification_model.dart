enum NotificationType {
  consumption,
  stockUpdate,
  bookingAdded,
  bookingCancelled,
  bookingDeleted,
  paymentReceived,
  stockAlert,
  systemUpdate,
}

enum NotificationPriority {
  low,
  medium,
  high,
  urgent,
}

class AppNotification {
  final String id;
  final String title;
  final String message;
  final NotificationType type;
  final NotificationPriority priority;
  final DateTime timestamp;
  final Map<String, dynamic>? data;
  final bool isRead;
  final String? createdBy;

  const AppNotification({
    required this.id,
    required this.title,
    required this.message,
    required this.type,
    this.priority = NotificationPriority.medium,
    required this.timestamp,
    this.data,
    this.isRead = false,
    this.createdBy,
  });

  AppNotification copyWith({
    String? id,
    String? title,
    String? message,
    NotificationType? type,
    NotificationPriority? priority,
    DateTime? timestamp,
    Map<String, dynamic>? data,
    bool? isRead,
    String? createdBy,
  }) {
    return AppNotification(
      id: id ?? this.id,
      title: title ?? this.title,
      message: message ?? this.message,
      type: type ?? this.type,
      priority: priority ?? this.priority,
      timestamp: timestamp ?? this.timestamp,
      data: data ?? this.data,
      isRead: isRead ?? this.isRead,
      createdBy: createdBy ?? this.createdBy,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'title': title,
      'message': message,
      'type': type.name,
      'priority': priority.name,
      'timestamp': timestamp.toIso8601String(),
      'data': data,
      'is_read': isRead,
      'created_by': createdBy,
    };
  }

  factory AppNotification.fromMap(Map<String, dynamic> map) {
    return AppNotification(
      id: map['id'] ?? '',
      title: map['title'] ?? '',
      message: map['message'] ?? '',
      type: NotificationType.values.firstWhere(
        (type) => type.name == map['type'],
        orElse: () => NotificationType.systemUpdate,
      ),
      priority: NotificationPriority.values.firstWhere(
        (priority) => priority.name == map['priority'],
        orElse: () => NotificationPriority.medium,
      ),
      timestamp: map['timestamp'] is String
          ? DateTime.parse(map['timestamp'])
          : map['timestamp'] ?? DateTime.now(),
      data: map['data'],
      isRead: map['is_read'] ?? false,
      createdBy: map['created_by'],
    );
  }

  @override
  String toString() {
    return 'AppNotification(id: $id, title: $title, type: $type, priority: $priority, timestamp: $timestamp, isRead: $isRead)';
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is AppNotification && other.id == id;
  }

  @override
  int get hashCode => id.hashCode;
}