import 'package:flutter/foundation.dart';
import 'package:table_calendar/table_calendar.dart';

class CalendarViewModel extends ChangeNotifier {
  DateTime _focusedDay = DateTime.now();
  DateTime _selectedDay = DateTime.now();
  CalendarFormat _calendarFormat = CalendarFormat.month;

  // Map pour stocker les événements par jour
  final Map<DateTime, List<dynamic>> _events = {};

  // Getters
  DateTime get focusedDay => _focusedDay;
  DateTime get selectedDay => _selectedDay;
  CalendarFormat get calendarFormat => _calendarFormat;

  // Événements par jour
  List<dynamic> getEventsForDay(DateTime day) {
    return _events.entries
        .where((entry) => isSameDay(entry.key, day))
        .map((entry) => entry.value)
        .expand((e) => e)
        .toList();
  }

  // Setters avec notification des changements
  void setFocusedDay(DateTime date) {
    _focusedDay = date;
    notifyListeners();
  }

  void setSelectedDay(DateTime date) {
    _selectedDay = date;
    _focusedDay = date; // Pour s'assurer que le jour sélectionné est visible
    notifyListeners();
  }

  void setCalendarFormat(CalendarFormat format) {
    _calendarFormat = format;
    notifyListeners();
  }

  // Callbacks pour le TableCalendar
  void onDaySelected(DateTime selectedDay, DateTime focusedDay) {
    if (!isSameDay(_selectedDay, selectedDay)) {
      _selectedDay = selectedDay;
      _focusedDay = focusedDay;
      notifyListeners();
    }
  }

  void onFormatChanged(CalendarFormat format) {
    _calendarFormat = format;
    notifyListeners();
  }

  void onPageChanged(DateTime focusedDay) {
    _focusedDay = focusedDay;
    notifyListeners();
  }

  // Pour savoir si un jour est sélectionné
  bool isDaySelected(DateTime day) {
    return isSameDay(_selectedDay, day);
  }

  // Pour vérifier si deux dates sont le même jour
  bool isSameDay(DateTime? a, DateTime? b) {
    if (a == null || b == null) {
      return false;
    }
    return a.year == b.year && a.month == b.month && a.day == b.day;
  }
}
