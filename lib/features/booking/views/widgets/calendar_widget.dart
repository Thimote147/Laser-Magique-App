import 'package:flutter/material.dart';
import 'package:table_calendar/table_calendar.dart';

import '../../viewmodels/calendar_view_model.dart';

class CalendarWidget extends StatelessWidget {
  final CalendarViewModel viewModel;

  const CalendarWidget({super.key, required this.viewModel});

  @override
  Widget build(BuildContext context) {
    return TableCalendar(
      firstDay: DateTime.utc(2020, 1, 1),
      lastDay: DateTime.utc(2030, 12, 31),
      focusedDay: viewModel.focusedDay,
      calendarFormat: viewModel.calendarFormat,
      availableCalendarFormats: const {
        CalendarFormat.month: 'Mois',
        CalendarFormat.week: 'Semaine',
      },
      selectedDayPredicate: (day) => isSameDay(viewModel.selectedDay, day),
      eventLoader: (day) => viewModel.getEventsForDay(day),
      onDaySelected: viewModel.onDaySelected,
      onFormatChanged: viewModel.onFormatChanged,
      onPageChanged: viewModel.onPageChanged,
      startingDayOfWeek: StartingDayOfWeek.monday,
      calendarStyle: const CalendarStyle(
        markersMaxCount: 1,
        markerSize: 8,
        markerDecoration: BoxDecoration(
          color: Colors.blue,
          shape: BoxShape.circle,
        ),
      ),
      headerStyle: HeaderStyle(
        formatButtonTextStyle: const TextStyle(fontSize: 14.0),
        formatButtonDecoration: BoxDecoration(
          color: Theme.of(context).colorScheme.primary,
          borderRadius: BorderRadius.circular(16.0),
        ),
        formatButtonShowsNext: false,
        formatButtonVisible: true,
        titleTextStyle: TextStyle(
          fontSize: 18.0,
          fontWeight: FontWeight.bold,
          color: Theme.of(context).brightness == Brightness.dark
              ? Colors.white
              : null,
        ),
        headerPadding: const EdgeInsets.symmetric(vertical: 8.0),
        leftChevronIcon: Icon(
          Icons.chevron_left,
          color: Theme.of(context).colorScheme.primary,
        ),
        rightChevronIcon: Icon(
          Icons.chevron_right,
          color: Theme.of(context).colorScheme.primary,
        ),
        decoration: BoxDecoration(
          color: Theme.of(context).brightness == Brightness.dark
              ? Theme.of(context).colorScheme.surface
              : null,
          borderRadius: BorderRadius.circular(12),
        ),
      ),
    );
  }
}
