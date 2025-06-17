import 'activity_model.dart';

class Formula {
  final String id;
  final String name;
  final String? description;
  final Activity activity;
  final double price;
  final int? minParticipants;
  final int? maxParticipants;
  final int? defaultGameCount;
  final int? minGames;
  final int? maxGames;
  final bool? isGameCountFixed;

  Formula({
    required this.id,
    required this.name,
    this.description,
    required this.activity,
    required this.price,
    this.minParticipants,
    this.maxParticipants,
    this.defaultGameCount,
    this.minGames,
    this.maxGames,
    this.isGameCountFixed,
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
    int? defaultGameCount,
    int? minGames,
    int? maxGames,
    bool? isGameCountFixed,
  }) {
    return Formula(
      id: id ?? this.id,
      name: name ?? this.name,
      description: description ?? this.description,
      activity: activity ?? this.activity,
      price: price ?? this.price,
      minParticipants: minParticipants ?? this.minParticipants,
      maxParticipants: maxParticipants ?? this.maxParticipants,
      defaultGameCount: defaultGameCount ?? this.defaultGameCount,
      minGames: minGames ?? this.minGames,
      maxGames: maxGames ?? this.maxGames,
      isGameCountFixed: isGameCountFixed ?? this.isGameCountFixed,
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
      'default_game_count': defaultGameCount,
      'min_games': minGames,
      'max_games': maxGames,
      'is_game_count_fixed': isGameCountFixed,
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
      minParticipants: map['min_persons'],
      maxParticipants: map['max_persons'],
      defaultGameCount: map['default_game_count'],
      minGames: map['min_games'],
      maxGames: map['max_games'],
      isGameCountFixed: map['is_game_count_fixed'],
    );
  }

  // Alias pour la compatibilité JSON
  Map<String, dynamic> toJson() => toMap();
  factory Formula.fromJson(Map<String, dynamic> json) => Formula.fromMap(json);

  @override
  String toString() {
    return 'Formula(id: $id, name: $name, description: $description, activity: $activity, price: $price, minParticipants: $minParticipants, maxParticipants: $maxParticipants, defaultGameCount: $defaultGameCount, minGames: $minGames, maxGames: $maxGames, isGameCountFixed: $isGameCountFixed)';
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
        other.defaultGameCount == defaultGameCount &&
        other.minGames == minGames &&
        other.maxGames == maxGames &&
        other.isGameCountFixed == isGameCountFixed;
  }

  @override
  int get hashCode {
    return id.hashCode ^
        name.hashCode ^
        description.hashCode ^
        activity.hashCode ^
        price.hashCode ^
        minParticipants.hashCode ^
        maxParticipants.hashCode ^
        defaultGameCount.hashCode ^
        minGames.hashCode ^
        maxGames.hashCode ^
        isGameCountFixed.hashCode;
  }
}
