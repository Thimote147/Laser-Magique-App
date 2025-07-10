import 'activity_model.dart';

enum FormulaType {
  standard,
  socialDeal,
}

class Formula {
  final String id;
  final String name;
  final String? description;
  final Activity activity;
  final double price;
  final int minParticipants;
  final int? maxParticipants;
  final int durationMinutes;
  final int minGames;
  final int? maxGames;
  final FormulaType type;

  Formula({
    required this.id,
    required this.name,
    this.description,
    required this.activity,
    required this.price,
    required this.minParticipants,
    this.maxParticipants,
    required this.durationMinutes,
    required this.minGames,
    this.maxGames,
    this.type = FormulaType.standard,
  });

  // Méthode pour créer une copie de Formula avec des champs modifiés
  Formula copyWith({
    String? id,
    String? name,
    String? description,
    Activity? activity,
    double? price,
    int? minParticipants,
    int? maxParticipants,
    int? durationMinutes,
    int? minGames,
    int? maxGames,
    FormulaType? type,
  }) {
    return Formula(
      id: id ?? this.id,
      name: name ?? this.name,
      description: description ?? this.description,
      activity: activity ?? this.activity,
      price: price ?? this.price,
      minParticipants: minParticipants ?? this.minParticipants,
      maxParticipants: maxParticipants ?? this.maxParticipants,
      durationMinutes: durationMinutes ?? this.durationMinutes,
      minGames: minGames ?? this.minGames,
      maxGames: maxGames ?? this.maxGames,
      type: type ?? this.type,
    );
  }

  // Méthode pour convertir en Map pour la persistance
  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'name': name,
      'description': description,
      'activity': activity.toMap(),
      'price': price,
      'min_persons': minParticipants,
      'max_persons': maxParticipants,
      'duration_minutes': durationMinutes,
      'min_games': minGames,
      'max_games': maxGames,
      'type': type.name,
    };
  }

  // Méthode pour créer un objet Formula à partir d'un Map
  factory Formula.fromMap(Map<String, dynamic> map) {
    // Extraire les valeurs avec des logs
    final minPersons = map['min_persons'] ?? 1;
    final minGames = map['min_games'] ?? 1;

    // Parse formula type
    FormulaType formulaType = FormulaType.standard;
    if (map['type'] != null) {
      try {
        formulaType = FormulaType.values.firstWhere(
          (type) => type.name == map['type'],
          orElse: () => FormulaType.standard,
        );
      } catch (e) {
        formulaType = FormulaType.standard;
      }
    }

    // Note: includedItems logic moved to stock_items.included_in_social_deal

    return Formula(
      id: map['id'],
      name: map['name'],
      description: map['description'],
      activity:
          map['activity'] is Map
              ? Activity.fromMap(map['activity'])
              : Activity(
                id: map['activity_id'] ?? '',
                name: map['activity_name'] ?? 'Unknown Activity',
                description: map['activity_description'],
              ),
      price:
          (map['price'] is String)
              ? double.tryParse(map['price']) ?? 0.0
              : (map['price']?.toDouble() ?? 0.0),
      minParticipants:
          minPersons is int
              ? minPersons
              : int.tryParse(minPersons.toString()) ?? 1,
      maxParticipants:
          map['max_persons'] is int
              ? map['max_persons']
              : int.tryParse(map['max_persons']?.toString() ?? ''),
      durationMinutes: map['duration_minutes'] ?? 15,
      minGames:
          minGames is int ? minGames : int.tryParse(minGames.toString()) ?? 1,
      maxGames:
          map['max_games'] is int
              ? map['max_games']
              : int.tryParse(map['max_games']?.toString() ?? ''),
      type: formulaType,
    );
  }

  // Alias pour la compatibilité JSON
  Map<String, dynamic> toJson() => toMap();
  factory Formula.fromJson(Map<String, dynamic> json) => Formula.fromMap(json);

  @override
  String toString() {
    return 'Formula(id: $id, name: $name, description: $description, activity: $activity, price: $price, minParticipants: $minParticipants, maxParticipants: $maxParticipants, durationMinutes: $durationMinutes, minGames: $minGames, maxGames: $maxGames, type: $type)';
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;

    return other is Formula &&
        other.id == id &&
        other.name == name &&
        other.description == description &&
        other.activity == activity &&
        other.price == price &&
        other.minParticipants == minParticipants &&
        other.maxParticipants == maxParticipants &&
        other.durationMinutes == durationMinutes &&
        other.minGames == minGames &&
        other.maxGames == maxGames &&
        other.type == type;
  }

  @override
  int get hashCode =>
      id.hashCode ^
      name.hashCode ^
      description.hashCode ^
      activity.hashCode ^
      price.hashCode ^
      minParticipants.hashCode ^
      maxParticipants.hashCode ^
      durationMinutes.hashCode ^
      minGames.hashCode ^
      maxGames.hashCode ^
      type.hashCode;
}
