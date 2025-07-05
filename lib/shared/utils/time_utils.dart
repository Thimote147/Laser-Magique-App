// Convertir les heures décimales en format heures et minutes (08:01)
String formatHoursToHourMinutes(double hours) {
  int fullHours = hours.floor();
  int minutes = ((hours - fullHours) * 60).round();
  return '${fullHours.toString().padLeft(2, '0')}:${minutes.toString().padLeft(2, '0')}';
}

// Convertir une durée en format heures:minutes
String formatDuration(Duration duration) {
  final hours = duration.inHours;
  final minutes = duration.inMinutes.remainder(60);
  return '${hours.toString().padLeft(2, '0')}h${minutes.toString().padLeft(2, '0')}';
}
