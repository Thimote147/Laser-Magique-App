import 'package:uuid/uuid.dart';

class Customer {
  final String id;
  final String firstName;
  final String lastName;
  final String phone;
  final String email;
  final DateTime? createdAt;
  final DateTime? updatedAt;

  Customer({
    String? id,
    required this.firstName,
    required this.lastName,
    required this.phone,
    required this.email,
    this.createdAt,
    this.updatedAt,
  }) : id = id ?? const Uuid().v4();

  Customer copyWith({
    String? firstName,
    String? lastName,
    String? phone,
    String? email,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return Customer(
      id: id,
      firstName: firstName ?? this.firstName,
      lastName: lastName ?? this.lastName,
      phone: phone ?? this.phone,
      email: email ?? this.email,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }

  factory Customer.fromMap(Map<String, dynamic> map) {
    return Customer(
      id: map['id'] as String,
      firstName: map['first_name'] as String,
      lastName: map['last_name'] as String,
      phone: map['phone'] as String,
      email: map['email'] as String,
      createdAt:
          map['created_at'] != null ? DateTime.parse(map['created_at']) : null,
      updatedAt:
          map['updated_at'] != null ? DateTime.parse(map['updated_at']) : null,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'first_name': firstName,
      'last_name': lastName,
      'phone': phone,
      'email': email,
      'created_at': createdAt?.toIso8601String(),
      'updated_at': updatedAt?.toIso8601String(),
    };
  }

  /// Vérifie si deux clients sont considérés comme identiques selon les règles métier
  bool isIdenticalTo(Customer other) {
    return firstName.trim().toLowerCase() ==
            other.firstName.trim().toLowerCase() &&
        (lastName.trim().toLowerCase()) ==
            (other.lastName.trim().toLowerCase()) &&
        ((email.trim().toLowerCase()) ==
                (other.email.trim().toLowerCase()) ||
            (phone.trim()) == (other.phone.trim()));
  }

  /// Retourne une clé unique pour ce client basée sur ses informations d'identité
  String get identityKey {
    final normalizedFirstName = firstName.trim().toLowerCase();
    final normalizedLastName = (lastName.trim()).toLowerCase();
    final contactInfo = email.trim().toLowerCase().isNotEmpty
        ? email.trim().toLowerCase()
        : phone.trim();

    return '$normalizedFirstName|$normalizedLastName|$contactInfo';
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is Customer && other.id == id;
  }

  @override
  int get hashCode => id.hashCode;

  @override
  String toString() {
    return 'Customer(id: $id, firstName: $firstName, lastName: $lastName, phone: $phone, email: $email)';
  }
}
