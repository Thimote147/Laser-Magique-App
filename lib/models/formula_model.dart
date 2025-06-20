import 'activity_model.dart';

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
    };
  }

  // Méthode pour créer un objet Formula à partir d'un Map
  factory Formula.fromMap(Map<String, dynamic> map) {
    return Formula(
      id: map['id'],
      name: map['name'],
      description: map['description'],
      activity: Activity.fromMap(map['activity']),
      price: map['price']?.toDouble() ?? 0.0,
      minParticipants: map['min_persons'] ?? 1,
      maxParticipants: map['max_persons'],
      durationMinutes: map['duration_minutes'] ?? 15,
      minGames: map['min_games'] ?? 1,
      maxGames: map['max_games'],
    );
  }

  // Alias pour la compatibilité JSON
  Map<String, dynamic> toJson() => toMap();
  factory Formula.fromJson(Map<String, dynamic> json) => Formula.fromMap(json);

  @override
  String toString() {
    return 'Formula(id: $id, name: $name, description: $description, activity: $activity, price: $price, minParticipants: $minParticipants, maxParticipants: $maxParticipants, durationMinutes: $durationMinutes, minGames: $minGames, maxGames: $maxGames)';
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
        other.maxGames == maxGames;
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
      maxGames.hashCode;
}
