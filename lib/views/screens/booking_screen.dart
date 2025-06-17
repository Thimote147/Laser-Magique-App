import 'package:flutter/material.dart';
import '../widgets/booking_calendar_widget.dart';
import '../widgets/booking_form_widget.dart';

class BookingScreen extends StatelessWidget {
  const BookingScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Réservations')),
      body: const BookingCalendarWidget(),
      floatingActionButton: FloatingActionButton(
        onPressed: () => _showAddBookingDialog(context),
        tooltip: 'Ajouter une réservation',
        child: const Icon(Icons.add),
      ),
    );
  }

  void _showAddBookingDialog(BuildContext context) {
    showDialog(
      context: context,
      builder:
          (context) => Dialog(
            child: Padding(
              padding: const EdgeInsets.all(16.0),
              child: BookingFormWidget(
                onSubmit: () => Navigator.of(context).pop(),
              ),
            ),
          ),
    );
  }
}
