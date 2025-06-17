import 'package:uuid/uuid.dart';

class Customer {
  final String id;
  final String firstName;
  final String? lastName;
  final String? phone;
  final String? email;

  Customer({
    String? id,
    required this.firstName,
    this.lastName,
    this.phone,
    this.email,
  }) : id = id ?? const Uuid().v4();

  Customer copyWith({
    String? firstName,
    String? lastName,
    String? phone,
    String? email,
  }) {
    return Customer(
      id: id,
      firstName: firstName ?? this.firstName,
      lastName: lastName ?? this.lastName,
      phone: phone ?? this.phone,
      email: email ?? this.email,
    );
  }

  factory Customer.fromMap(Map<String, dynamic> map) {
    return Customer(
      id: map['id'] as String,
      firstName: map['first_name'] as String,
      lastName: map['last_name'] as String?,
      phone: map['phone'] as String?,
      email: map['email'] as String?,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'first_name': firstName,
      'last_name': lastName,
      'phone': phone,
      'email': email,
    };
  }
}
