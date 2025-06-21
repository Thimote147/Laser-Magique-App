class WorkDay {
  final String id;
  final DateTime date;
  final DateTime startTime;
  final DateTime endTime;
  final double hours;
  final double earnings;
  final double? hourlyRate;

  const WorkDay({
    required this.id,
    required this.date,
    required this.startTime,
    required this.endTime,
    this.hours = 0,
    this.earnings = 0,
    this.hourlyRate,
  });

  WorkDay copyWith({
    String? id,
    DateTime? date,
    DateTime? startTime,
    DateTime? endTime,
    double? hours,
    double? earnings,
    double? hourlyRate,
  }) {
    return WorkDay(
      id: id ?? this.id,
      date: date ?? this.date,
      startTime: startTime ?? this.startTime,
      endTime: endTime ?? this.endTime,
      hours: hours ?? this.hours,
      earnings: earnings ?? this.earnings,
      hourlyRate: hourlyRate ?? this.hourlyRate,
    );
  }
}
