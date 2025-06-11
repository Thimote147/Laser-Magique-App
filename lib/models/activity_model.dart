class Activity {
  final String id;
  final String name;
  final String? description;
  final double?
  pricePerPerson; // Prix de base par personne, peut être null si le prix est déterminé uniquement par la formule

  Activity({
    required this.id,
    required this.name,
    this.description,
    this.pricePerPerson,
  });

  // Méthode pour créer une copie de Activity avec des champs modifiés
  Activity copyWith({
    String? id,
    String? name,
    String? description,
    double? pricePerPerson,
  }) {
    return Activity(
      id: id ?? this.id,
      name: name ?? this.name,
      description: description ?? this.description,
      pricePerPerson: pricePerPerson ?? this.pricePerPerson,
    );
  }

  // Méthode pour convertir en Map pour la persistance
  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'name': name,
      'description': description,
      'pricePerPerson': pricePerPerson,
    };
  }

  // Méthode pour créer un objet Activity à partir d'un Map
  factory Activity.fromMap(Map<String, dynamic> map) {
    return Activity(
      id: map['id'] ?? '',
      name: map['name'] ?? map['activity_name'] ?? 'Activité inconnue',
      description: map['description'] ?? map['activity_description'],
      pricePerPerson: map['price_per_person']?.toDouble(),
    );
  }

  @override
  String toString() {
    return 'Activity(id: $id, name: $name, description: $description, pricePerPerson: $pricePerPerson)';
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is Activity &&
        other.id == id &&
        other.name == name &&
        other.description == description &&
        other.pricePerPerson == pricePerPerson;
  }

  @override
  int get hashCode {
    return id.hashCode ^
        name.hashCode ^
        description.hashCode ^
        pricePerPerson.hashCode;
  }
}
