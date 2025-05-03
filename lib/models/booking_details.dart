import 'dart:developer' as developer;

/// Modèle représentant les détails complets d'une réservation
/// basé sur la fonction SQL get_booking_details
class BookingDetails {
  final String activityBookingId;
  final BookingInfo booking;
  final ActivityInfo activity;
  final PricingInfo pricing;
  final DateTime createdAt;
  final DateTime updatedAt;

  BookingDetails({
    required this.activityBookingId,
    required this.booking,
    required this.activity,
    required this.pricing,
    required this.createdAt,
    required this.updatedAt,
  });

  factory BookingDetails.fromJson(Map<String, dynamic> json) {
    // Pour déboguer les données reçues
    developer.log('BookingDetails.fromJson: ${json.toString()}');

    return BookingDetails(
      activityBookingId: json['activity_booking_id']?.toString() ?? '',
      booking: BookingInfo.fromJson(json['booking'] ?? {}),
      activity: ActivityInfo.fromJson(json['activity'] ?? {}),
      pricing: PricingInfo.fromJson(json['pricing'] ?? {}),
      createdAt:
          json['created_at'] != null
              ? DateTime.parse(json['created_at'].toString())
              : DateTime.now(),
      updatedAt:
          json['updated_at'] != null
              ? DateTime.parse(json['updated_at'].toString())
              : DateTime.now(),
    );
  }
}

/// Informations sur la réservation principale
class BookingInfo {
  final String bookingId;
  final String firstname;
  final String lastname;
  final DateTime date;
  final int nbrPers;
  final int nbrParties;
  final String email;
  final String phoneNumber;
  final String notes;

  BookingInfo({
    required this.bookingId,
    required this.firstname,
    required this.lastname,
    required this.date,
    required this.nbrPers,
    required this.nbrParties,
    required this.email,
    required this.phoneNumber,
    this.notes = '',
  });

  // Getter pour obtenir le nom complet
  String get fullName => '$firstname $lastname'.trim();

  // Getter pour obtenir le prénom formaté (capitalisé)
  String get formattedFirstname => _capitalizeFirst(firstname);

  // Getter pour obtenir le nom de famille formaté (capitalisé)
  String get formattedLastname => _capitalizeFirst(lastname);

  // Méthode pour capitaliser la première lettre
  String _capitalizeFirst(String text) {
    if (text.isEmpty) return '';
    return text[0].toUpperCase() + text.substring(1).toLowerCase();
  }

  factory BookingInfo.fromJson(Map<String, dynamic> json) {
    // Pour déboguer les données de réservation
    developer.log('BookingInfo.fromJson: ${json.toString()}');

    // No need to decode json as it's already a Map<String, dynamic>
    Map<String, dynamic> dataMap = json;

    // Gérer le cas où on reçoit un nom complet au lieu de prénom/nom séparés
    String firstName = '';
    String lastName = '';

    if (dataMap.containsKey('firstname') && dataMap['firstname'] != null) {
      firstName = dataMap['firstname'].toString();
    } else if (dataMap.containsKey('first_name') &&
        dataMap['first_name'] != null) {
      firstName = dataMap['first_name'].toString();
    }

    if (dataMap.containsKey('lastname') && dataMap['lastname'] != null) {
      lastName = dataMap['lastname'].toString();
    } else if (dataMap.containsKey('last_name') &&
        dataMap['last_name'] != null) {
      lastName = dataMap['last_name'].toString();
    }

    // Si on a qu'un champ 'name' ou 'customer_name', le diviser
    if ((firstName.isEmpty || lastName.isEmpty) &&
        dataMap.containsKey('customer_name')) {
      final nameParts = _splitName(dataMap['customer_name'].toString());
      if (firstName.isEmpty) firstName = nameParts.item1;
      if (lastName.isEmpty) lastName = nameParts.item2;
    } else if ((firstName.isEmpty || lastName.isEmpty) &&
        dataMap.containsKey('name')) {
      final nameParts = _splitName(dataMap['name'].toString());
      if (firstName.isEmpty) firstName = nameParts.item1;
      if (lastName.isEmpty) lastName = nameParts.item2;
    }

    return BookingInfo(
      bookingId: dataMap['booking_id']?.toString() ?? '',
      firstname: firstName,
      lastname: lastName,
      date:
          dataMap['date'] != null
              ? DateTime.parse(dataMap['date'].toString())
              : DateTime.now(),
      nbrPers: _parseInt(dataMap['nbr_pers']),
      nbrParties: _parseInt(dataMap['nbr_parties']),
      email: dataMap['email']?.toString() ?? '',
      phoneNumber: dataMap['phone_number']?.toString() ?? '',
      notes: dataMap['notes']?.toString() ?? '',
    );
  }

  // Méthode statique pour diviser un nom complet
  static ({String item1, String item2}) _splitName(String fullName) {
    if (fullName.isEmpty) return (item1: '', item2: '');

    final parts = fullName.trim().split(' ');
    if (parts.length == 1) {
      return (item1: parts[0], item2: '');
    }

    final firstName = parts[0];
    final lastName = parts.sublist(1).join(' ');

    return (item1: firstName, item2: lastName);
  }
}

/// Informations sur l'activité
class ActivityInfo {
  final String activityId;
  final String name;

  ActivityInfo({required this.activityId, required this.name});

  factory ActivityInfo.fromJson(Map<String, dynamic> json) {
    // For debugging
    developer.log('ActivityInfo.fromJson: ${json.toString()}');

    // No need to decode json as it's already a Map<String, dynamic>
    Map<String, dynamic> dataMap = json;

    return ActivityInfo(
      activityId: dataMap['activity_id']?.toString() ?? '',
      name: dataMap['name']?.toString() ?? '',
    );
  }
}

/// Informations sur la tarification
class PricingInfo {
  final String type;
  final int minPlayer;
  final int maxPlayer;
  final double firstPrice;
  final double secondPrice;
  final double thirdPrice;
  final int duration;

  PricingInfo({
    required this.type,
    required this.minPlayer,
    required this.maxPlayer,
    required this.firstPrice,
    required this.secondPrice,
    required this.thirdPrice,
    required this.duration,
  });

  factory PricingInfo.fromJson(Map<String, dynamic> json) {
    // For debugging
    developer.log('PricingInfo.fromJson: ${json.toString()}');

    // No need to decode json as it's already a Map<String, dynamic>
    Map<String, dynamic> dataMap = json;

    return PricingInfo(
      type: dataMap['type']?.toString() ?? '',
      minPlayer: _parseInt(dataMap['min_player']),
      maxPlayer: _parseInt(dataMap['max_player']),
      firstPrice: _parseDouble(dataMap['first_price']),
      secondPrice: _parseDouble(dataMap['second_price']),
      thirdPrice: _parseDouble(dataMap['third_price']),
      duration: _parseInt(dataMap['duration']),
    );
  }

  // Renvoie le prix applicable selon le nombre de personnes
  double getPriceForPlayers(int playerCount) {
    if (playerCount <= 0) return firstPrice;

    if (playerCount <= minPlayer) {
      return firstPrice;
    } else if (playerCount <= (minPlayer + maxPlayer) / 2) {
      return secondPrice;
    } else {
      return thirdPrice;
    }
  }
}

// Fonctions utilitaires pour convertir divers types
int _parseInt(dynamic value) {
  if (value == null) return 0;
  if (value is int) return value;
  if (value is String) return int.tryParse(value) ?? 0;
  if (value is double) return value.toInt();
  return 0;
}

double _parseDouble(dynamic value) {
  if (value == null) return 0.0;
  if (value is double) return value;
  if (value is int) return value.toDouble();
  if (value is String) return double.tryParse(value) ?? 0.0;
  return 0.0;
}
