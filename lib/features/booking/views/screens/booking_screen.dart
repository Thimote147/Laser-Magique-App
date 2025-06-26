import 'package:flutter/material.dart';
import '../widgets/booking_calendar_widget.dart';
import '../widgets/booking_dialogs.dart';

class BookingScreen extends StatelessWidget {
  const BookingScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Réservations')),
      body: const BookingCalendarWidget(),
      floatingActionButton: FloatingActionButton(
        onPressed: () => AddBookingDialog.show(context),
        tooltip: 'Ajouter une réservation',
        child: const Icon(Icons.add),
      ),
    );
  }
}
