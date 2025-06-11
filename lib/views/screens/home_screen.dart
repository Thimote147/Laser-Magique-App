import 'package:flutter/material.dart';
import '../widgets/booking_calendar_widget.dart';
import 'booking_edit_screen.dart';

class HomeScreen extends StatelessWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Laser Magique')),
      body: const BookingCalendarWidget(),
      floatingActionButton: FloatingActionButton(
        onPressed: () {
          Navigator.of(context).push(
            MaterialPageRoute(builder: (context) => const BookingEditScreen()),
          );
        },
        tooltip: 'Ajouter une réservation',
        child: const Icon(Icons.add),
      ),
    );
  }
}
