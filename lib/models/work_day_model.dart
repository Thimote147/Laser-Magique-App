class WorkDay {
  final String id;
  final DateTime date;
  final DateTime startTime;
  final DateTime endTime;
  final double? hoursWorked;
  final double? totalAmount;

  WorkDay({
    this.id = '', // ID vide par défaut, sera généré par Supabase
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

  // Créer une instance à partir d'un JSON
  factory WorkDay.fromJson(Map<String, dynamic> json) {
    return WorkDay(
      id: json['id'],
      date: DateTime.parse(json['date']),
      startTime: DateTime.parse(json['start_time']),
      endTime: DateTime.parse(json['end_time']),
      hoursWorked: json['hours']?.toDouble(),
      totalAmount: json['total_amount']?.toDouble(),
    );
  }

  // Convertir l'instance en JSON
  Map<String, dynamic> toJson() {
    final Map<String, dynamic> json = {
      'date': date.toIso8601String(),
      'start_time': startTime.toIso8601String(),
      'end_time': endTime.toIso8601String(),
      'hours': hoursWorked,
      'total_amount': totalAmount,
    };

    if (id.isNotEmpty) {
      json['id'] = id;
    }

    return json;
  }
}
