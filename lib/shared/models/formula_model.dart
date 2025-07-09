import 'activity_model.dart';

enum FormulaType {
  standard,
  socialDeal,
}

class IncludedItem {
  final String stockItemId;
  final int quantityPerPerson;
  
  const IncludedItem({
    required this.stockItemId,
    required this.quantityPerPerson,
  });

  Map<String, dynamic> toMap() {
    return {
      'stock_item_id': stockItemId,
      'quantity_per_person': quantityPerPerson,
    };
  }

  factory IncludedItem.fromMap(Map<String, dynamic> map) {
    return IncludedItem(
      stockItemId: map['stock_item_id'],
      quantityPerPerson: map['quantity_per_person'],
    );
  }
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
  final List<IncludedItem> includedItems;

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
    this.includedItems = const [],
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
    List<IncludedItem>? includedItems,
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
      includedItems: includedItems ?? this.includedItems,
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
      'included_items': includedItems.map((item) => item.toMap()).toList(),
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

    // Parse included items
    List<IncludedItem> includedItems = [];
    if (map['included_items'] != null && map['included_items'] is List) {
      includedItems = (map['included_items'] as List)
          .map((item) => IncludedItem.fromMap(item))
          .toList();
    }

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
      includedItems: includedItems,
    );
  }

  // Alias pour la compatibilité JSON
  Map<String, dynamic> toJson() => toMap();
  factory Formula.fromJson(Map<String, dynamic> json) => Formula.fromMap(json);

  @override
  String toString() {
    return 'Formula(id: $id, name: $name, description: $description, activity: $activity, price: $price, minParticipants: $minParticipants, maxParticipants: $maxParticipants, durationMinutes: $durationMinutes, minGames: $minGames, maxGames: $maxGames, type: $type, includedItems: $includedItems)';
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
        other.type == type &&
        other.includedItems.length == includedItems.length;
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
      type.hashCode ^
      includedItems.hashCode;
}
