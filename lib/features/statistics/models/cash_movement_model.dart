enum CashMovementType {
  entry,
  exit,
}

class CashMovement {
  final String id;
  final DateTime date;
  final CashMovementType type;
  final double amount;
  final String justification;
  final String? details;
  final DateTime createdAt;
  final String? createdBy;

  const CashMovement({
    required this.id,
    required this.date,
    required this.type,
    required this.amount,
    required this.justification,
    this.details,
    required this.createdAt,
    this.createdBy,
  });

  factory CashMovement.fromJson(Map<String, dynamic> json) {
    return CashMovement(
      id: json['id']?.toString() ?? '',
      date: DateTime.parse(json['date'] ?? DateTime.now().toIso8601String()),
      type: json['type'] == 'entry' ? CashMovementType.entry : CashMovementType.exit,
      amount: (json['amount'] as num?)?.toDouble() ?? 0.0,
      justification: json['justification']?.toString() ?? '',
      details: json['details']?.toString(),
      createdAt: DateTime.parse(json['created_at'] ?? DateTime.now().toIso8601String()),
      createdBy: json['created_by']?.toString(),
    );
  }

  Map<String, dynamic> toJson({bool includeId = false}) {
    final json = {
      'date': date.toIso8601String(),
      'type': type == CashMovementType.entry ? 'entry' : 'exit',
      'amount': amount,
      'justification': justification,
      'details': details,
      'created_at': createdAt.toIso8601String(),
      'created_by': createdBy,
    };
    
    if (includeId) {
      json['id'] = id;
    }
    
    return json;
  }

  CashMovement copyWith({
    String? id,
    DateTime? date,
    CashMovementType? type,
    double? amount,
    String? justification,
    String? details,
    DateTime? createdAt,
    String? createdBy,
  }) {
    return CashMovement(
      id: id ?? this.id,
      date: date ?? this.date,
      type: type ?? this.type,
      amount: amount ?? this.amount,
      justification: justification ?? this.justification,
      details: details ?? this.details,
      createdAt: createdAt ?? this.createdAt,
      createdBy: createdBy ?? this.createdBy,
    );
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is CashMovement &&
        other.id == id &&
        other.date == date &&
        other.type == type &&
        other.amount == amount &&
        other.justification == justification &&
        other.details == details &&
        other.createdAt == createdAt &&
        other.createdBy == createdBy;
  }

  @override
  int get hashCode => Object.hash(
        id,
        date,
        type,
        amount,
        justification,
        details,
        createdAt,
        createdBy,
      );
}