import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:table_calendar/table_calendar.dart';

import '../../viewmodels/booking_view_model.dart';
import '../../models/booking_model.dart';
import '../screens/booking_details_screen.dart';
import '../screens/booking_edit_screen.dart';
import 'booking_list_item.dart';

class BookingCalendarWidget extends StatefulWidget {
  const BookingCalendarWidget({super.key});

  @override
  State<BookingCalendarWidget> createState() => _BookingCalendarWidgetState();
}

class _BookingCalendarWidgetState extends State<BookingCalendarWidget> {
  late DateTime _focusedDay;
  late DateTime _selectedDay;
  late CalendarFormat _calendarFormat;
  final _scrollController = ScrollController();

  @override
  void initState() {
    super.initState();
    // Initialize with local time
    final now = DateTime.now();
    _focusedDay = now;
    _selectedDay = now;
    _calendarFormat = CalendarFormat.month;
  }

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<BookingViewModel>(
      builder: (context, bookingViewModel, child) {
        return RefreshIndicator(
          onRefresh: () async {
            await bookingViewModel.loadBookings();
          },
          child: SingleChildScrollView(
            physics: const AlwaysScrollableScrollPhysics(),
            controller: _scrollController,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TableCalendar(
                  locale: 'fr_FR',
                  firstDay: DateTime(2020, 1, 1), // Using local time
                  lastDay: DateTime(2030, 12, 31), // Using local time
                  focusedDay: _focusedDay,
                  calendarFormat: _calendarFormat,
                  startingDayOfWeek: StartingDayOfWeek.monday,
                  availableGestures: AvailableGestures.all,
                  availableCalendarFormats: const {
                    CalendarFormat.month: 'Mois',
                    CalendarFormat.week: 'Semaine',
                  },
                  selectedDayPredicate: (day) => isSameDay(_selectedDay, day),
                  eventLoader: (day) => bookingViewModel.getBookingsForDay(day),
                  onDaySelected: (selectedD, focusedD) {
                    setState(() {
                      _selectedDay = selectedD;
                      _focusedDay = focusedD;
                    });
                  },
                  onFormatChanged: (format) {
                    setState(() {
                      _calendarFormat = format;
                    });
                  },
                  onPageChanged: (focusedD) {
                    setState(() {
                      _focusedDay = focusedD;
                    });
                  },
                  calendarStyle: CalendarStyle(
                    markersMaxCount: 1,
                    markersAnchor: 0.7,
                    markerDecoration: BoxDecoration(
                      color:
                          Theme.of(context).brightness == Brightness.dark
                              ? Colors.indigo.shade200
                              : Colors.indigo,
                      shape: BoxShape.circle,
                    ),
                    todayDecoration: BoxDecoration(
                      color: Theme.of(
                        context,
                      ).colorScheme.primary.withOpacity(0.5),
                      shape: BoxShape.circle,
                    ),
                    selectedDecoration: BoxDecoration(
                      color: Theme.of(context).colorScheme.primary,
                      shape: BoxShape.circle,
                    ),
                    // Amélioration du contraste pour le mode sombre
                    outsideTextStyle: TextStyle(
                      color:
                          Theme.of(context).brightness == Brightness.dark
                              ? Colors.grey.shade400
                              : Colors.grey.shade500,
                    ),
                    weekendTextStyle: TextStyle(
                      color:
                          Theme.of(context).brightness == Brightness.dark
                              ? Colors.red.shade200
                              : Colors.red.shade700,
                    ),
                  ),
                  calendarBuilders: CalendarBuilders(
                    markerBuilder: (context, date, events) {
                      if (events.isEmpty) return null;

                      return Positioned(
                        bottom: 1,
                        child: Container(
                          width: 8,
                          height: 8,
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            color: Colors.indigo,
                          ),
                        ),
                      );
                    },
                  ),
                  headerStyle: HeaderStyle(
                    titleCentered: true,
                    formatButtonDecoration: BoxDecoration(
                      color: Theme.of(context).colorScheme.primary,
                      borderRadius: BorderRadius.circular(20.0),
                    ),
                    formatButtonTextStyle: TextStyle(
                      color: Theme.of(context).colorScheme.onPrimary,
                      fontWeight: FontWeight.bold,
                    ),
                    titleTextStyle: TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 17,
                      color:
                          Theme.of(context).brightness == Brightness.dark
                              ? Colors.white
                              : null,
                    ),
                    decoration: BoxDecoration(
                      color:
                          Theme.of(context).brightness == Brightness.dark
                              ? const Color(0xFF2A2A2A)
                              : null,
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                ),
                const SizedBox(height: 12),
                SizedBox(
                  height:
                      MediaQuery.of(context).size.height *
                      0.5, // This gives the list a fixed height that's half the screen height
                  child: _buildBookingList(
                    context,
                    bookingViewModel.getBookingsForDay(_selectedDay),
                    bookingViewModel,
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  bool isSameDay(DateTime? a, DateTime? b) {
    if (a == null || b == null) {
      return false;
    }
    return a.year == b.year && a.month == b.month && a.day == b.day;
  }

  Widget _buildBookingList(
    BuildContext context,
    List<Booking> bookings,
    BookingViewModel viewModel,
  ) {
    if (bookings.isEmpty) {
      return const Center(
        child: Text(
          'Aucune réservation pour cette date',
          style: TextStyle(fontSize: 16, fontStyle: FontStyle.italic),
        ),
      );
    }
    return ListView.builder(
      itemCount: bookings.length,
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      itemBuilder: (context, index) {
        final booking = bookings[index];
        return BookingListItem(
          booking: booking,
          onTap:
              () => Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => BookingDetailsScreen(booking: booking),
                ),
              ),
          onMoreTap: () => _showBookingActions(context, booking, viewModel),
        );
      },
    );
  }

  void _showBookingActions(
    BuildContext context,
    Booking booking,
    BookingViewModel viewModel,
  ) {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
      builder: (context) {
        return SafeArea(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              ListTile(
                leading: const Icon(Icons.edit, color: Colors.blue),
                title: const Text('Modifier la réservation'),
                onTap: () {
                  Navigator.pop(context);
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => BookingEditScreen(booking: booking),
                    ),
                  );
                },
              ),
              ListTile(
                leading: Icon(
                  booking.isCancelled ? Icons.restore : Icons.cancel,
                  color: booking.isCancelled ? Colors.green : Colors.orange,
                ),
                title: Text(
                  booking.isCancelled
                      ? 'Restaurer la réservation'
                      : 'Marquer comme annulée',
                  style: TextStyle(
                    color: booking.isCancelled ? Colors.green : Colors.orange,
                  ),
                ),
                subtitle: null,
                onTap: () {
                  Navigator.pop(context);
                  viewModel.toggleCancellationStatus(booking.id);
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text(
                        booking.isCancelled
                            ? 'La réservation a été restaurée'
                            : 'La réservation a été marquée comme annulée',
                      ),
                      duration: const Duration(seconds: 2),
                    ),
                  );
                },
              ),
              ListTile(
                leading: const Icon(Icons.delete, color: Colors.red),
                title: const Text('Supprimer la réservation'),
                onTap: () {
                  Navigator.pop(context);
                  _confirmDelete(context, booking, viewModel);
                },
              ),
            ],
          ),
        );
      },
    );
  }

  void _confirmDelete(
    BuildContext context,
    Booking booking,
    BookingViewModel viewModel,
  ) {
    showDialog(
      context: context,
      builder:
          (context) => AlertDialog(
            title: const Text('Confirmer la suppression'),
            content: Text(
              'Êtes-vous sûr de vouloir supprimer la réservation de ${booking.firstName} ${booking.lastName ?? ""} ?',
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context),
                child: const Text('Annuler'),
              ),
              TextButton(
                onPressed: () {
                  viewModel.removeBooking(booking.id);
                  Navigator.pop(context);
                },
                child: const Text(
                  'Supprimer',
                  style: TextStyle(color: Colors.red),
                ),
              ),
            ],
          ),
    );
  }
}
