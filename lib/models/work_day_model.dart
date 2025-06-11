class WorkDay {
  final String id;
  final DateTime date;
  final DateTime startTime;
  final DateTime endTime;
  final double? hoursWorked;
  final double? totalAmount;

  WorkDay({
    required this.id,
    required this.date,
    required this.startTime,
    required this.endTime,
    this.hoursWorked,
    this.totalAmount,
  });

  // Calculer le nombre d'heures travaillées
  double get hours {
    if (hoursWorked != null) return hoursWorked!;
    final difference = endTime.difference(startTime);
    return difference.inMinutes / 60.0;
  }

  // Calculer le montant total basé sur le taux horaire et les heures
  double calculateAmount(double hourlyRate) {
    return hours * hourlyRate;
  }
}
