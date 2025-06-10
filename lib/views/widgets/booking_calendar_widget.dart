import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:table_calendar/table_calendar.dart';

import '../../viewmodels/booking_view_model.dart';
import '../../models/booking_model.dart';
import '../screens/booking_details_screen.dart';
import '../screens/booking_edit_screen.dart';
import 'booking_list_item.dart';
import 'booking_calendar_marker.dart';

class BookingCalendarWidget extends StatelessWidget {
  const BookingCalendarWidget({super.key});

  static final ValueNotifier<DateTime> focusedDay = ValueNotifier(DateTime.now());
  static final ValueNotifier<DateTime> selectedDay = ValueNotifier(DateTime.now());
  static final ValueNotifier<CalendarFormat> calendarFormat = ValueNotifier(CalendarFormat.month);

  @override
  Widget build(BuildContext context) {
    return Consumer<BookingViewModel>(
      builder: (context, bookingViewModel, child) {
        return Column(
          children: [
            TableCalendar(
              firstDay: DateTime.utc(2020, 1, 1),
              lastDay: DateTime.utc(2030, 12, 31),
              focusedDay: focusedDay.value,
              calendarFormat: calendarFormat.value,
              locale: 'fr_FR',
              availableCalendarFormats: const {
                CalendarFormat.month: 'Mois',
                CalendarFormat.week: 'Semaine',
              },
              selectedDayPredicate: (day) => isSameDay(selectedDay.value, day),
              eventLoader: (day) => bookingViewModel.getBookingsForDay(day),
              onDaySelected: (selectedD, focusedD) {
                selectedDay.value = selectedD;
                focusedDay.value = focusedD;
              },
              onFormatChanged: (format) {
                if (calendarFormat.value != format &&
                    (format == CalendarFormat.month ||
                        format == CalendarFormat.week)) {
                  calendarFormat.value = format;
                }
              },
              onPageChanged: (focusedD) {
                focusedDay.value = focusedD;
              },
              calendarStyle: CalendarStyle(
                markersMaxCount: 3,
                markersAnchor: 0.7,
                markerDecoration: const BoxDecoration(
                  color: Colors.indigo,
                  shape: BoxShape.circle,
                ),
                todayDecoration: BoxDecoration(
                  color: Theme.of(context).colorScheme.primary.withOpacity(0.5),
                  shape: BoxShape.circle,
                ),
                selectedDecoration: BoxDecoration(
                  color: Theme.of(context).colorScheme.primary,
                  shape: BoxShape.circle,
                ),
              ),
              calendarBuilders: CalendarBuilders(
                markerBuilder: (context, date, events) {
                  if (events.isEmpty) return null;

                  return Positioned(
                    bottom: 1,
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: events.take(3).map((event) {
                        final booking = event as Booking;
                        return BookingCalendarMarker(booking: booking);
                      }).toList(),
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
                ),
              ),
            ),
            const SizedBox(height: 12),
            Expanded(
              child: _buildBookingList(
                context,
                bookingViewModel.getBookingsForDay(selectedDay.value),
                bookingViewModel,
              ),
            ),
          ],
        );
      },
    );
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
          onTap: () => Navigator.push(
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
      builder: (context) => AlertDialog(
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
