// Model class for bookings based on database schema
import 'package:intl/intl.dart';

enum ActivityType { standard, vip, customized, group, private }

class Booking {
  final String id; // UUID
  final String firstName;
  final String lastName;
  final DateTime date;
  final ActivityType groupType; // activity_type
  final int nbrPers;
  final int duration;
  final int nbrParties;

  Booking({
    required this.id,
    required this.firstName,
    required this.lastName,
    required this.date,
    required this.groupType,
    required this.nbrPers,
    required this.duration,
    required this.nbrParties,
  });

  // Computed property to get full name
  String get customerName => '$firstName $lastName';

  // Computed property to get end time based on duration
  DateTime get endTime => date.add(Duration(minutes: duration));

  // Formatted time string
  String formattedTimeRange() {
    final formatter = DateFormat('HH:mm');
    return '${formatter.format(date)} - ${formatter.format(endTime)}';
  }

  factory Booking.fromJson(Map<String, dynamic> json) {
    return Booking(
      id: json['id']?.toString() ?? '',
      firstName: json['firstname']?.toString() ?? '',
      lastName: json['lastname']?.toString() ?? '',
      date: _parseDateTime(json['date']),
      groupType: _parseActivityType(json['group_type']),
      nbrPers: _parseInt(json['nbr_pers']),
      duration: _parseInt(json['duration']),
      nbrParties: _parseInt(json['nbr_parties']),
    );
  }

  // Helper methods for safe parsing
  static int _parseInt(dynamic value) {
    if (value is int) return value;
    if (value is String) {
      return int.tryParse(value) ?? 0;
    }
    return 0;
  }

  static DateTime _parseDateTime(dynamic value) {
    if (value is String) {
      try {
        return DateTime.parse(value);
      } catch (e) {
        return DateTime.now();
      }
    }
    return DateTime.now();
  }

  static ActivityType _parseActivityType(dynamic value) {
    if (value is String) {
      try {
        return ActivityType.values.firstWhere(
          (type) =>
              type.toString().split('.').last.toLowerCase() ==
              value.toString().toLowerCase(),
          orElse: () => ActivityType.standard,
        );
      } catch (e) {
        return ActivityType.standard;
      }
    }
    return ActivityType.standard;
  }
}
