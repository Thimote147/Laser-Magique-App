class GameSession {
  final String id;
  final String bookingId;
  final int gameNumber;
  final int participatingPersons;
  final DateTime? startTime;
  final bool isCompleted;
  final double adjustedPrice;
  final DateTime createdAt;
  final DateTime? completedAt;

  GameSession({
    required this.id,
    required this.bookingId,
    required this.gameNumber,
    required this.participatingPersons,
    this.startTime,
    this.isCompleted = false,
    required this.adjustedPrice,
    required this.createdAt,
    this.completedAt,
  });

  GameSession copyWith({
    String? id,
    String? bookingId,
    int? gameNumber,
    int? participatingPersons,
    DateTime? startTime,
    bool? isCompleted,
    double? adjustedPrice,
    DateTime? createdAt,
    DateTime? completedAt,
  }) {
    return GameSession(
      id: id ?? this.id,
      bookingId: bookingId ?? this.bookingId,
      gameNumber: gameNumber ?? this.gameNumber,
      participatingPersons: participatingPersons ?? this.participatingPersons,
      startTime: startTime ?? this.startTime,
      isCompleted: isCompleted ?? this.isCompleted,
      adjustedPrice: adjustedPrice ?? this.adjustedPrice,
      createdAt: createdAt ?? this.createdAt,
      completedAt: completedAt ?? this.completedAt,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'booking_id': bookingId,
      'game_number': gameNumber,
      'participating_persons': participatingPersons,
      'start_time': startTime?.toUtc().toIso8601String(),
      'is_completed': isCompleted,
      'adjusted_price': adjustedPrice,
      'created_at': createdAt.toUtc().toIso8601String(),
      'completed_at': completedAt?.toUtc().toIso8601String(),
    };
  }

  factory GameSession.fromMap(Map<String, dynamic> map) {
    return GameSession(
      id: map['id'],
      bookingId: map['booking_id'],
      gameNumber: map['game_number'],
      participatingPersons: map['participating_persons'],
      startTime: map['start_time'] != null 
          ? DateTime.parse(map['start_time']).toUtc()
          : null,
      isCompleted: map['is_completed'] ?? false,
      adjustedPrice: (map['adjusted_price'] ?? 0.0).toDouble(),
      createdAt: DateTime.parse(map['created_at']).toUtc(),
      completedAt: map['completed_at'] != null 
          ? DateTime.parse(map['completed_at']).toUtc()
          : null,
    );
  }

  @override
  String toString() {
    return 'GameSession(id: $id, bookingId: $bookingId, gameNumber: $gameNumber, participatingPersons: $participatingPersons, startTime: $startTime, isCompleted: $isCompleted, adjustedPrice: $adjustedPrice, createdAt: $createdAt, completedAt: $completedAt)';
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is GameSession &&
        other.id == id &&
        other.bookingId == bookingId &&
        other.gameNumber == gameNumber &&
        other.participatingPersons == participatingPersons &&
        other.startTime == startTime &&
        other.isCompleted == isCompleted &&
        other.adjustedPrice == adjustedPrice &&
        other.createdAt == createdAt &&
        other.completedAt == completedAt;
  }

  @override
  int get hashCode {
    return id.hashCode ^
        bookingId.hashCode ^
        gameNumber.hashCode ^
        participatingPersons.hashCode ^
        startTime.hashCode ^
        isCompleted.hashCode ^
        adjustedPrice.hashCode ^
        createdAt.hashCode ^
        completedAt.hashCode;
  }
}