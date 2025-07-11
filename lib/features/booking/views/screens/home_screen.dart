import 'package:flutter/material.dart';
import '../widgets/booking_calendar_widget.dart';
import 'booking_edit_screen.dart';
import '../widgets/customer_booking_search_delegate.dart';
import '../../../../shared/widgets/notification_badge_widget.dart';
import '../../../../shared/screens/notifications_screen.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  int selectedCategory = 0; // 0 = Clients, 1 = Réservations
  DateTime? _selectedDate;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Laser Magique'),
        actions: [
          NotificationBadge(
            onTap: () {
              Navigator.of(context).push(
                MaterialPageRoute(
                  builder: (context) => const NotificationsScreen(),
                ),
              );
            },
          ),
          IconButton(
            icon: const Icon(Icons.search),
            tooltip: 'Rechercher un client',
            onPressed: () async {
              // Ouvre le SearchDelegate personnalisé
              showSearch(
                context: context,
                delegate: CustomerBookingSearchDelegate(
                  selectedCategory: selectedCategory,
                ),
              );
            },
          ),
        ],
      ),
      body: BookingCalendarWidget(
        onDateSelected: (date) {
          setState(() {
            _selectedDate = date;
          });
        },
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () {
          Navigator.of(context).push(
            MaterialPageRoute(
              builder: (context) => BookingEditScreen(
                initialDate: _selectedDate,
              ),
            ),
          );
        },
        tooltip: 'Ajouter une réservation',
        child: const Icon(Icons.add),
      ),
    );
  }
}
