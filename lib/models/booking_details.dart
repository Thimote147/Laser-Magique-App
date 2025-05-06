import 'package:intl/intl.dart';
import 'food.dart'; // Import the food model

/// Modèle représentant les détails complets d'une réservation
/// basé sur la fonction SQL get_booking_details
class BookingDetails {
  final String activityBookingId;
  BookingInfo booking; // Removed final to allow updates
  final ActivityInfo activity;
  final PricingInfo pricing;
  final DateTime createdAt;
  final DateTime updatedAt;
  final List<FoodItem> consumptions; // Add consumptions field

  // Nouvelle propriété pour stocker le prix de l'activité séparément des consommations
  double activityPrice = 0;

  BookingDetails({
    required this.activityBookingId,
    required this.booking,
    required this.activity,
    required this.pricing,
    required this.createdAt,
    required this.updatedAt,
    this.consumptions = const [], // Default to empty list
    this.activityPrice = 0, // Default to zero
  });

  factory BookingDetails.fromJson(Map<String, dynamic> json) {
    List<FoodItem> consumptionsList = [];

    // Parse consumptions if they exist
    if (json['consumptions'] != null) {
      if (json['consumptions'] is List) {
        consumptionsList =
            (json['consumptions'] as List)
                .map((item) => FoodItem.fromJson(item))
                .toList();
      }
    }

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
      consumptions: consumptionsList,
    );
  }

  // Add method to calculate total consumption amount
  double get consumptionsTotal {
    double total = 0;
    for (var item in consumptions) {
      total += item.price * item.quantity;
    }
    return total;
  }

  // Add method to add a new food item to consumptions
  void addConsumption(FoodItem item) {
    // Check if item already exists
    final existingItemIndex = consumptions.indexWhere(
      (element) => element.id == item.id,
    );
    if (existingItemIndex != -1) {
      // Update quantity if item exists
      final updatedItem = consumptions[existingItemIndex].copyWith(
        quantity: consumptions[existingItemIndex].quantity + item.quantity,
      );
      consumptions[existingItemIndex] = updatedItem;
    } else {
      // Add new item
      consumptions.add(item);
    }
  }

  // Add method to update a food item in consumptions
  void updateConsumption(String itemId, int quantity) {
    final index = consumptions.indexWhere((element) => element.id == itemId);
    if (index != -1) {
      if (quantity <= 0) {
        // Remove item if quantity is 0 or less
        consumptions.removeAt(index);
      } else {
        // Update quantity
        final updatedItem = consumptions[index].copyWith(quantity: quantity);
        consumptions[index] = updatedItem;
      }
    }
  }

  // Add method to remove a food item from consumptions
  void removeConsumption(String itemId) {
    consumptions.removeWhere((item) => item.id == itemId);
  }

  // Get a consumption item by ID
  FoodItem? getConsumptionById(String id) {
    try {
      return consumptions.firstWhere((item) => item.id == id);
    } catch (e) {
      return null;
    }
  }

  /// Returns a formatted string representation of the date and time
  String get formattedDate {
    final DateFormat dateFormat = DateFormat('dd/MM/yyyy à HH:mm');
    return dateFormat.format(booking.date);
  }

  /// Returns a formatted duration string
  String get formattedDuration => '${pricing.duration} minutes';

  /// Returns a summary of the booking info
  String get summaryInfo {
    return 'Réservation de ${booking.nbrPers} personne(s) pour ${activity.name}'
        ' le $formattedDate ($formattedDuration)';
  }

  /// Returns a complete representation of the booking details
  @override
  String toString() {
    final DateFormat dateFormat = DateFormat('dd/MM/yyyy à HH:mm');
    final currencyFormat = NumberFormat.currency(
      locale: 'fr_FR',
      symbol: '€',
      decimalDigits: 2,
    );

    return '''
DÉTAILS DE LA RÉSERVATION
-------------------------
ID: $activityBookingId
Activité: ${activity.name} (${pricing.type})
Date: ${dateFormat.format(booking.date)}
Durée: ${pricing.duration} minutes

CLIENT
------
Nom: ${booking.formattedFirstname} ${booking.formattedLastname}
Email: ${booking.email.isEmpty ? 'Non renseigné' : booking.email}
Téléphone: ${booking.phoneNumber.isEmpty ? 'Non renseigné' : booking.phoneNumber}
Commentaire: ${booking.notes.isEmpty ? 'Aucun' : booking.notes}

PARTICIPANTS
-----------
Nombre de personnes: ${booking.nbrPers}
Nombre de parties: ${booking.nbrParties}

TARIFICATION
-----------
Type: ${pricing.type}
Prix: ${currencyFormat.format(booking.amount)}
Acompte: ${currencyFormat.format(booking.deposit)}
Total: ${currencyFormat.format(booking.total)}

PAIEMENT
-------
Carte: ${booking.cardPayment != null ? currencyFormat.format(booking.cardPayment!) : 'Non'}
Espèces: ${booking.cashPayment != null ? currencyFormat.format(booking.cashPayment!) : 'Non'}
Annulé: ${booking.isCancelled ? 'Oui' : 'Non'}

CONSOMMATIONS
------------
Total des consommations: ${currencyFormat.format(consumptionsTotal)}

CRÉATION
-------
Créé le: ${dateFormat.format(createdAt)}
Mis à jour: ${dateFormat.format(updatedAt)}
''';
  }

  /// Returns a map of formatted key-value pairs for displaying in a UI
  Map<String, String> toDisplayMap() {
    final DateFormat dateFormat = DateFormat('dd/MM/yyyy à HH:mm');
    final currencyFormat = NumberFormat.currency(
      locale: 'fr_FR',
      symbol: '€',
      decimalDigits: 2,
    );

    return {
      'ID': activityBookingId,
      'Activité': activity.name,
      'Type': pricing.type,
      'Date': dateFormat.format(booking.date),
      'Durée': _formatDuration,
      'Client': booking.fullName,
      'Email': booking.email.isEmpty ? 'Non renseigné' : booking.email,
      'Téléphone':
          booking.phoneNumber.isEmpty ? 'Non renseigné' : booking.phoneNumber,
      'Commentaire': booking.notes.isEmpty ? 'Aucun' : booking.notes,
      'Participants': '${booking.nbrPers} personne(s)',
      'Parties': '${booking.nbrParties} partie(s)',
      'Prix': currencyFormat.format(booking.amount),
      'Acompte': currencyFormat.format(booking.deposit),
      'Total': currencyFormat.format(booking.total),
      'Total des consommations': currencyFormat.format(consumptionsTotal),
      'Paiement Carte':
          booking.cardPayment != null
              ? currencyFormat.format(booking.cardPayment!)
              : 'Non',
      'Paiement Espèces':
          booking.cashPayment != null
              ? currencyFormat.format(booking.cashPayment!)
              : 'Non',
      'Annulé': booking.isCancelled ? 'Oui' : 'Non',
      'Créé le': dateFormat.format(createdAt),
      'Mis à jour le': dateFormat.format(updatedAt),
    };
  }

  String get _formatDuration {
    if (pricing.duration < 60) {
      return '${pricing.duration} minutes';
    } else {
      final hours = pricing.duration ~/ 60;
      final minutes = pricing.duration % 60;
      if (minutes == 0) {
        return '$hours heure${hours > 1 ? 's' : ''}';
      } else {
        return '$hours heure${hours > 1 ? 's' : ''} $minutes minute${minutes > 1 ? 's' : ''}';
      }
    }
  }
}

/// Informations sur la réservation principale
class BookingInfo {
  final String bookingId;
  final String firstname;
  final String? lastname; // Made lastname nullable
  final DateTime date;
  final int nbrPers;
  final int nbrParties;
  final String email;
  final String phoneNumber;
  final String notes;
  final double total;
  final double amount;
  final double deposit;
  final bool isCancelled;
  final double? cardPayment;
  final double? cashPayment;

  BookingInfo({
    required this.bookingId,
    required this.firstname,
    this.lastname, // Made optional
    required this.date,
    required this.nbrPers,
    required this.nbrParties,
    required this.email,
    required this.phoneNumber,
    this.notes = '',
    this.total = 0.0,
    this.amount = 0.0,
    this.deposit = 0.0,
    this.isCancelled = false,
    this.cardPayment,
    this.cashPayment,
  });

  // Getter pour obtenir le nom complet
  String get fullName => '$firstname ${lastname ?? ''}'.trim();

  // Getter pour obtenir le prénom formaté (capitalisé)
  String get formattedFirstname => _capitalizeFirst(firstname);

  // Getter pour obtenir le nom de famille formaté (capitalisé)
  String get formattedLastname =>
      lastname != null && lastname!.isNotEmpty
          ? _capitalizeFirst(lastname!)
          : '';

  // Méthode pour capitaliser la première lettre
  String _capitalizeFirst(String text) {
    if (text.isEmpty) return '';
    return text[0].toUpperCase() + text.substring(1).toLowerCase();
  }

  factory BookingInfo.fromJson(Map<String, dynamic> json) {
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
      phoneNumber:
          dataMap['phone']?.toString() ??
          '', // Using 'phone' instead of 'phone_number'
      notes:
          dataMap['comment']?.toString() ??
          '', // Using 'comment' instead of 'notes'
      total: _parseDouble(dataMap['total']),
      amount: _parseDouble(dataMap['amount']),
      deposit: _parseDouble(dataMap['deposit']),
      isCancelled: dataMap['is_cancelled'] == true,
      cardPayment:
          dataMap['card_payment'] != null
              ? _parseDouble(dataMap['card_payment'])
              : null,
      cashPayment:
          dataMap['cash_payment'] != null
              ? _parseDouble(dataMap['cash_payment'])
              : null,
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
  final String id;
  final String type;
  final int minPlayer;
  final int maxPlayer;
  final double firstPrice;
  final double secondPrice;
  final double thirdPrice;
  final int duration;

  PricingInfo({
    required this.id,
    required this.type,
    required this.minPlayer,
    required this.maxPlayer,
    required this.firstPrice,
    required this.secondPrice,
    required this.thirdPrice,
    required this.duration,
  });

  factory PricingInfo.fromJson(Map<String, dynamic> json) {
    // No need to decode json as it's already a Map<String, dynamic>
    Map<String, dynamic> dataMap = json;

    return PricingInfo(
      id: dataMap['id']?.toString() ?? '',
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
