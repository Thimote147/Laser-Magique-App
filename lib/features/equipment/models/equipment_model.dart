class Equipment {
  final String id;
  final String name;
  final bool isFunctional;
  final String? description;
  final DateTime createdAt;
  final DateTime updatedAt;

  Equipment({
    required this.id,
    required this.name,
    required this.isFunctional,
    this.description,
    required this.createdAt,
    required this.updatedAt,
  });

  factory Equipment.fromJson(Map<String, dynamic> json) {
    return Equipment(
      id: json['id'] as String,
      name: json['name'] as String,
      isFunctional: json['is_functional'] as bool,
      description: json['description'] as String?,
      createdAt: DateTime.parse(json['created_at'] as String),
      updatedAt: DateTime.parse(json['updated_at'] as String),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'is_functional': isFunctional,
      'description': description,
      'created_at': createdAt.toIso8601String(),
      'updated_at': updatedAt.toIso8601String(),
    };
  }

  Equipment copyWith({
    String? id,
    String? name,
    bool? isFunctional,
    String? description,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return Equipment(
      id: id ?? this.id,
      name: name ?? this.name,
      isFunctional: isFunctional ?? this.isFunctional,
      description: description ?? this.description,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is Equipment && other.id == id;
  }

  @override
  int get hashCode => id.hashCode;
}
