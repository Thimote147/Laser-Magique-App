import 'activity_model.dart';

class Formula {
  final String id;
  final String name;
  final String? description;
  final Activity activity; // L'activité associée à cette formule
  final double price; // Prix de la formule
  final int? minParticipants; // Nombre minimum de participants requis
  final int? maxParticipants; // Nombre maximum de participants
  final int? defaultGameCount; // Nombre de parties par défaut
  final int? minGameCount; // Nombre minimum de parties
  final int? maxGameCount; // Nombre maximum de parties
  final bool?
  fixedGameCount; // Si le nombre de parties est fixe (non modifiable)

  Formula({
    required this.id,
    required this.name,
    this.description,
    required this.activity,
    required this.price,
    this.minParticipants,
    this.maxParticipants,
    this.defaultGameCount,
    this.minGameCount,
    this.maxGameCount,
    this.fixedGameCount,
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
    int? minGameCount,
    int? maxGameCount,
    bool? fixedGameCount,
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
      minGameCount: minGameCount ?? this.minGameCount,
      maxGameCount: maxGameCount ?? this.maxGameCount,
      fixedGameCount: fixedGameCount ?? this.fixedGameCount,
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
      'minParticipants': minParticipants,
      'maxParticipants': maxParticipants,
      'defaultGameCount': defaultGameCount,
      'minGameCount': minGameCount,
      'maxGameCount': maxGameCount,
      'fixedGameCount': fixedGameCount,
    };
  }

  // Méthode pour créer un objet Formula à partir d'un Map
  factory Formula.fromMap(Map<String, dynamic> map) {
    return Formula(
      id: map['id'],
      name: map['name'],
      description: map['description'],
      activity: Activity.fromMap(map['activity']),
      price: map['price'],
      minParticipants: map['minParticipants'],
      maxParticipants: map['maxParticipants'],
      defaultGameCount: map['defaultGameCount'],
      minGameCount: map['minGameCount'],
      maxGameCount: map['maxGameCount'],
      fixedGameCount: map['fixedGameCount'],
    );
  }

  @override
  String toString() {
    return 'Formula(id: $id, name: $name, description: $description, activity: $activity, price: $price, minParticipants: $minParticipants, maxParticipants: $maxParticipants, defaultGameCount: $defaultGameCount, minGameCount: $minGameCount, maxGameCount: $maxGameCount, fixedGameCount: $fixedGameCount)';
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
        other.minGameCount == minGameCount &&
        other.maxGameCount == maxGameCount &&
        other.fixedGameCount == fixedGameCount;
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
        minGameCount.hashCode ^
        maxGameCount.hashCode ^
        fixedGameCount.hashCode;
  }
}
