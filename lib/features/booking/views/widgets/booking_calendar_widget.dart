import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:table_calendar/table_calendar.dart';

import '../../viewmodels/booking_view_model.dart';
import '../../models/booking_model.dart';
import '../screens/booking_details_screen.dart';
import '../screens/booking_edit_screen.dart';
import 'booking_list_item.dart';
import '../../../../shared/user_provider.dart';

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
    // No need to get userProvider here, handled in _showBookingActions
    return Consumer<BookingViewModel>(
      builder: (context, bookingViewModel, child) {
        return RefreshIndicator(
          onRefresh: () async {
            await bookingViewModel.loadBookings();
          },
          child: Column(
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
                  // Scroll automatique si on est en Day View
                  if (_calendarFormat == CalendarFormat.week) {
                    WidgetsBinding.instance.addPostFrameCallback((_) {
                      _scrollToFirstBooking(
                        bookingViewModel.getBookingsForDay(selectedD),
                      );
                    });
                  }
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
                    ).colorScheme.primary.withAlpha((255 * 0.5).round()),
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

                    return Container(
                      margin: const EdgeInsets.only(top: 20),
                      width: 8,
                      height: 8,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: Theme.of(context).colorScheme.primary,
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
                            ? Theme.of(context).colorScheme.surface
                            : null,
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
              ),
              if (_calendarFormat == CalendarFormat.month)
                _buildBookingList(
                  context,
                  bookingViewModel.getBookingsForDay(_selectedDay),
                  bookingViewModel,
                )
              else
                _buildDayView(
                  context,
                  bookingViewModel.getBookingsForDay(_selectedDay),
                  bookingViewModel,
                ),
            ],
          ),
        );
      },
    );
  }

  void _scrollToFirstBooking(List<Booking> bookings) {
    if (bookings.isEmpty) return;
    // On prend la première réservation (déjà triée par heure dans la Day View)
    final first = bookings.reduce(
      (a, b) => a.dateTimeLocal.isBefore(b.dateTimeLocal) ? a : b,
    );
    final double hourHeight = 60.0;
    final double offset =
        first.dateTimeLocal.hour * hourHeight +
        (first.dateTimeLocal.minute / 60.0) * hourHeight;
    // On scroll avec une petite marge en haut
    _scrollController.animateTo(
      offset - 16,
      duration: const Duration(milliseconds: 400),
      curve: Curves.easeInOut,
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
      return Expanded(
        child: Center(
          child: Text(
            'Aucune réservation pour cette date',
            style: TextStyle(fontSize: 16, fontStyle: FontStyle.italic),
          ),
        ),
      );
    }
    return Expanded(
      child: ListView.builder(
        physics: const AlwaysScrollableScrollPhysics(),
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
                    builder:
                        (context) => BookingDetailsScreen(booking: booking),
                  ),
                ),
            onMoreTap: () => _showBookingActions(context, booking, viewModel),
          );
        },
      ),
    );
  }

  void _showBookingActions(
    BuildContext context,
    Booking booking,
    BookingViewModel viewModel,
  ) {
    final userProvider = Provider.of<UserProvider>(context, listen: false);
    final user = userProvider.user;
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
              if (user != null && user.settings?.role == 'admin') ...[
                ListTile(
                  leading: const Icon(Icons.delete, color: Colors.red),
                  title: const Text('Supprimer la réservation'),
                  onTap: () {
                    Navigator.pop(context);
                    _confirmDelete(context, booking, viewModel);
                  },
                ),
              ],
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

  Widget _buildDayView(
    BuildContext context,
    List<Booking> bookings,
    BookingViewModel viewModel,
  ) {
    const double hourHeight = 60.0;
    final hoursInDay = List.generate(24, (index) => index);

    return Expanded(
      child: SingleChildScrollView(
        controller: _scrollController,
        physics: const AlwaysScrollableScrollPhysics(),
        child: Container(
          height: 24 * hourHeight,
          margin: const EdgeInsets.only(top: 8),
          child: Stack(
            children: [
              // Lignes des heures
              ...hoursInDay.map(
                (hour) => Positioned(
                  top: hour * hourHeight,
                  left: 60,
                  right: 0,
                  child: Container(
                    height: 1,
                    color: Theme.of(
                      context,
                    ).dividerColor.withAlpha((255 * 0.3).round()),
                  ),
                ),
              ),
              // Heures
              ...hoursInDay.map(
                (hour) => Positioned(
                  top: hour * hourHeight - 10,
                  left: 16,
                  child: Container(
                    width: 50,
                    height: 20,
                    alignment: Alignment.centerRight,
                    padding: const EdgeInsets.only(right: 8),
                    child: Text(
                      '$hour:00',
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        color: Theme.of(context).colorScheme.onSurfaceVariant,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ),
                ),
              ),
              // Réservations
              ..._groupOverlappingBookings(
                bookings,
              ).expand((group) => _buildOverlappingBookings(group, viewModel)),
            ],
          ),
        ),
      ),
    );
  }

  List<List<Booking>> _groupOverlappingBookings(List<Booking> bookings) {
    if (bookings.isEmpty) return [];

    // Trier les réservations par heure de début
    final sortedBookings = List<Booking>.from(bookings)
      ..sort((a, b) => a.dateTimeLocal.compareTo(b.dateTimeLocal));

    List<List<Booking>> groups = [];
    List<Booking> currentGroup = [sortedBookings.first];

    for (var i = 1; i < sortedBookings.length; i++) {
      final booking = sortedBookings[i];
      final previousBooking = sortedBookings[i - 1];

      // Considérer un chevauchement si la réservation commence dans l'heure de la précédente
      if (booking.dateTimeLocal
              .difference(previousBooking.dateTimeLocal)
              .inHours <
          1) {
        currentGroup.add(booking);
      } else {
        if (currentGroup.isNotEmpty) {
          groups.add(List<Booking>.from(currentGroup));
        }
        currentGroup = [booking];
      }
    }

    if (currentGroup.isNotEmpty) {
      groups.add(currentGroup);
    }

    return groups;
  }

  List<Widget> _buildOverlappingBookings(
    List<Booking> group,
    BookingViewModel viewModel,
  ) {
    final double baseWidth =
        MediaQuery.of(context).size.width -
        68; // Largeur totale moins la colonne des heures
    const double hourHeight = 60.0;
    final int count = group.length;
    final double width =
        (baseWidth / count) - 4; // 4 pixels de marge entre les réservations

    return List.generate(count, (index) {
      final booking = group[index];
      return DayViewBooking(
        booking: booking,
        hourHeight: hourHeight,
        left:
            60 +
            (index * (width + 4)), // 60 est la largeur de la colonne des heures
        width: width,
        onTap:
            () => Navigator.push(
              context,
              MaterialPageRoute(
                builder: (context) => BookingDetailsScreen(booking: booking),
              ),
            ),
        onMoreTap: () => _showBookingActions(context, booking, viewModel),
      );
    });
  }
}

class DayViewBooking extends StatelessWidget {
  final Booking booking;
  final VoidCallback onTap;
  final VoidCallback onMoreTap;
  final double hourHeight;
  final double left;
  final double width;

  const DayViewBooking({
    super.key,
    required this.booking,
    required this.onTap,
    required this.onMoreTap,
    required this.left,
    required this.width,
    this.hourHeight = 60.0,
  });

  @override
  Widget build(BuildContext context) {
    final startTime = booking.dateTimeLocal;
    final duration = const Duration(hours: 1);
    final top =
        startTime.hour * hourHeight + (startTime.minute / 60.0) * hourHeight;

    final backgroundColor =
        booking.isCancelled
            ? Theme.of(
              context,
            ).colorScheme.errorContainer.withAlpha((255 * 0.3).round())
            : Theme.of(
              context,
            ).colorScheme.primaryContainer.withAlpha((255 * 0.3).round());
    final borderColor =
        booking.isCancelled
            ? Theme.of(context).colorScheme.error.withAlpha((255 * 0.5).round())
            : Theme.of(
              context,
            ).colorScheme.primary.withAlpha((255 * 0.5).round());

    return Positioned(
      top: top,
      left: left,
      width: width,
      child: Card(
        margin: EdgeInsets.zero,
        elevation: 0,
        color: backgroundColor,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(8),
          side: BorderSide(color: borderColor),
        ),
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(8),
          child: Container(
            height: duration.inHours * hourHeight,
            padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 1),
            child: LayoutBuilder(
              builder: (context, constraints) {
                final isVeryTight = constraints.maxHeight < 35;
                final isTight = constraints.maxHeight < 45;
                final double nameSize = isVeryTight ? 10 : 11;
                final double iconSize = isVeryTight ? 10 : 12;
                final double textSize = isVeryTight ? 9 : 10;

                return Column(
                  mainAxisSize: MainAxisSize.min,
                  mainAxisAlignment: MainAxisAlignment.start,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        if (booking.isCancelled) ...[
                          Icon(
                            Icons.cancel,
                            size: iconSize,
                            color: Theme.of(context).colorScheme.error,
                          ),
                          const SizedBox(width: 2),
                        ],
                        Expanded(
                          child: Text(
                            '${booking.firstName} ${booking.lastName ?? ""}',
                            style: Theme.of(
                              context,
                            ).textTheme.bodyMedium?.copyWith(
                              fontWeight: FontWeight.bold,
                              fontSize: nameSize,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                        if (!isVeryTight)
                          SizedBox(
                            width: 16,
                            height: 16,
                            child: IconButton(
                              icon: Icon(Icons.more_vert, size: iconSize),
                              onPressed: onMoreTap,
                              padding: EdgeInsets.zero,
                              visualDensity: VisualDensity.compact,
                              style: IconButton.styleFrom(
                                tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                              ),
                            ),
                          ),
                      ],
                    ),
                    if (!isVeryTight) ...[
                      Row(
                        children: [
                          Icon(
                            Icons.group,
                            size: iconSize,
                            color: Theme.of(context).colorScheme.primary,
                          ),
                          Text(
                            ' ${booking.numberOfPersons}',
                            style: Theme.of(
                              context,
                            ).textTheme.bodySmall?.copyWith(
                              fontSize: textSize,
                              color: Theme.of(context).colorScheme.primary,
                            ),
                          ),
                          const SizedBox(width: 4),
                          Icon(
                            Icons.sports_esports,
                            size: iconSize,
                            color: Theme.of(context).colorScheme.secondary,
                          ),
                          Text(
                            ' ${booking.numberOfGames}',
                            style: Theme.of(
                              context,
                            ).textTheme.bodySmall?.copyWith(
                              fontSize: textSize,
                              color: Theme.of(context).colorScheme.secondary,
                            ),
                          ),
                        ],
                      ),
                      if (!isTight) ...[
                        Text(
                          booking.formula.name,
                          style: Theme.of(
                            context,
                          ).textTheme.bodySmall?.copyWith(
                            fontSize: textSize,
                            fontWeight: FontWeight.w500,
                            color: Theme.of(context).colorScheme.tertiary,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                        if (!booking.isCancelled)
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 3,
                              vertical: 0,
                            ),
                            decoration: BoxDecoration(
                              color:
                                  booking.remainingBalance > 0
                                      ? Theme.of(context).colorScheme.secondary
                                          .withAlpha((255 * 0.1).round())
                                      : Theme.of(
                                        context,
                                      ).colorScheme.primaryContainer,
                              borderRadius: BorderRadius.circular(2),
                            ),
                            child: Text(
                              booking.remainingBalance > 0
                                  ? 'Reste ${booking.remainingBalance.toStringAsFixed(2)}€'
                                  : 'Payée',
                              style: Theme.of(
                                context,
                              ).textTheme.bodySmall?.copyWith(
                                fontSize: textSize - 1,
                                color:
                                    booking.remainingBalance > 0
                                        ? Theme.of(
                                          context,
                                        ).colorScheme.secondary
                                        : Theme.of(context).colorScheme.primary,
                              ),
                            ),
                          ),
                      ],
                    ],
                  ],
                );
              },
            ),
          ),
        ),
      ),
    );
  }
}
