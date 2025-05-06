class WorkHour {
  final String hourId;
  final DateTime date;
  final String beginning;
  final String ending;
  final String nbrHours;
  final double amount;
  String userName = ''; // Added to store the user's name for admin view

  WorkHour({
    required this.hourId,
    required this.date,
    required this.beginning,
    required this.ending,
    required this.nbrHours,
    required this.amount,
    this.userName = '', // Default empty string
  });

  factory WorkHour.fromJson(Map<String, dynamic> json) {
    return WorkHour(
      hourId: json['hour_id'],
      date: DateTime.parse(json['date']),
      beginning: json['beginning'],
      ending: json['ending'],
      nbrHours: json['nbr_hours'],
      amount: json['amount'].toDouble(),
      userName:
          json['firstname'] as String? ?? '', // Include userName if available
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'hour_id': hourId,
      'date': date.toIso8601String(),
      'beginning': beginning,
      'ending': ending,
      'nbr_hours': nbrHours,
      'amount': amount,
      // userName is not included in toJson as it's only for UI display
    };
  }
}
