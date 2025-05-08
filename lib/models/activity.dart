class Activity {
  final String id;
  final String name;
  final String type;
  final double firstPrice;
  final double secondPrice;
  final double thirdPrice;
  final int minPlayer;
  final int maxPlayer;
  final int duration;

  Activity({
    required this.id,
    required this.name,
    required this.type,
    required this.firstPrice,
    required this.secondPrice,
    required this.thirdPrice,
    required this.minPlayer,
    required this.maxPlayer,
    required this.duration,
  });

  factory Activity.fromJson(Map<String, dynamic> json) {
    return Activity(
      id: json['activity_id'].toString(),
      name: json['name'].toString(),
      type: json['type'].toString(),
      firstPrice: _parseDouble(json['first_price']),
      secondPrice: _parseDouble(json['second_price']),
      thirdPrice: _parseDouble(json['third_price']),
      minPlayer: _parseInt(json['min_player']),
      maxPlayer: _parseInt(json['max_player']),
      duration: _parseInt(json['duration']),
    );
  }

  // Helper methods for safe parsing
  static double _parseDouble(dynamic value) {
    if (value is double) return value;
    if (value is int) return value.toDouble();
    if (value is String) {
      return double.tryParse(value) ?? 0.0;
    }
    return 0.0;
  }

  static int _parseInt(dynamic value) {
    if (value is int) return value;
    if (value is String) {
      return int.tryParse(value) ?? 0;
    }
    return 0;
  }

  // Get the appropriate price based on the number of persons
  // with fallback to next available price if a price is zero/null
  double getPriceForParty(int numberOfPersons) {
    double price = 0.0;

    // First, determine which price tier to use based on number of persons
    if (numberOfPersons <= minPlayer) {
      price = firstPrice;
    } else if (numberOfPersons <= (minPlayer + maxPlayer) ~/ 2) {
      price = secondPrice;
    } else {
      price = thirdPrice;
    }

    // If the selected price is zero, try to find a fallback
    if (price <= 0) {
      // Try each price in order: first, second, third
      if (firstPrice > 0) {
        price = firstPrice;
      } else if (secondPrice > 0) {
        price = secondPrice;
      } else if (thirdPrice > 0) {
        price = thirdPrice;
      } else {
        // If all prices are invalid, use a default value
        price = 0.0;
      }
    }

    return price;
  }
}
