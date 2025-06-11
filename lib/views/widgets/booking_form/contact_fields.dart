import 'package:flutter/material.dart';

class ContactFields extends StatelessWidget {
  final String firstName;
  final String lastName;
  final String email;
  final String phone;
  final void Function(String) onFirstNameChanged;
  final void Function(String) onLastNameChanged;
  final void Function(String) onEmailChanged;
  final void Function(String) onPhoneChanged;

  const ContactFields({
    super.key,
    required this.firstName,
    required this.lastName,
    required this.email,
    required this.phone,
    required this.onFirstNameChanged,
    required this.onLastNameChanged,
    required this.onEmailChanged,
    required this.onPhoneChanged,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            TextFormField(
              initialValue: firstName,
              onChanged: onFirstNameChanged,
              decoration: const InputDecoration(
                labelText: 'Prénom *',
                hintText: 'Entrez le prénom',
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 16),
            TextFormField(
              initialValue: lastName,
              onChanged: onLastNameChanged,
              decoration: const InputDecoration(
                labelText: 'Nom',
                hintText: 'Entrez le nom',
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 16),
            TextFormField(
              initialValue: email,
              onChanged: onEmailChanged,
              decoration: const InputDecoration(
                labelText: 'Email',
                hintText: 'Entrez l\'email',
                border: OutlineInputBorder(),
              ),
              keyboardType: TextInputType.emailAddress,
            ),
            const SizedBox(height: 16),
            TextFormField(
              initialValue: phone,
              onChanged: onPhoneChanged,
              decoration: const InputDecoration(
                labelText: 'Téléphone',
                hintText: 'Entrez le numéro de téléphone',
                border: OutlineInputBorder(),
              ),
              keyboardType: TextInputType.phone,
            ),
          ],
        ),
      ),
    );
  }
}
