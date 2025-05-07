import 'package:supabase_flutter/supabase_flutter.dart';
import '../models/booking_details.dart';
import '../models/food.dart';
import '../main.dart';

class BookingService {
  // Singleton pattern
  BookingService._privateConstructor();
  static final BookingService _instance = BookingService._privateConstructor();
  static BookingService get instance => _instance;

  // Get the Supabase client from the global instance
  SupabaseClient get client => supabase;

  /// Fetch booking details by booking ID
  Future<BookingDetails?> fetchBookingDetails(String bookingId) async {
    try {
      final response = await client.rpc(
        'get_booking_details',
        params: {'p_activity_booking_id': bookingId},
      );

      if (response != null && response.isNotEmpty) {
        return BookingDetails.fromJson(response[0]);
      }
      return null;
    } catch (e) {
      rethrow;
    }
  }

  /// Fetch and process consumptions for a booking
  Future<void> fetchAndProcessConsumptions(
    BookingDetails bookingDetails,
  ) async {
    try {
      final consumptionsResponse = await client.rpc(
        'get_conso',
        params: {'actual_booking_id': bookingDetails.booking.bookingId},
      );

      if (consumptionsResponse != null) {
        final consumptionsList = _parseConsumptionsList(
          consumptionsResponse as List,
        );

        bookingDetails.consumptions.clear();
        bookingDetails.consumptions.addAll(consumptionsList);

        _updateBookingWithConsumptions(bookingDetails);
      }
    } catch (e) {
      rethrow;
    }
  }

  /// Parse consumptions response into a list of FoodItem objects
  List<FoodItem> _parseConsumptionsList(List consumptionsResponse) {
    return consumptionsResponse
        .map(
          (item) => FoodItem(
            id: item['food_id'],
            name: item['name'],
            price:
                _parseDouble(item['price']) /
                _parseInt(item['quantity']), // Get unit price
            quantity: _parseInt(item['quantity']),
          ),
        )
        .toList();
  }

  /// Update booking with consumption totals
  void _updateBookingWithConsumptions(BookingDetails bookingDetails) {
    // Calculate the activity price (excluding consumptions)
    double activityPrice = calculateActivityPrice(bookingDetails);
    bookingDetails.activityPrice = activityPrice;

    // Calculate consumptions total
    double consumptionsTotal = 0;
    for (var item in bookingDetails.consumptions) {
      consumptionsTotal += item.price * item.quantity;
    }
    
    // Calculate total as activity price + consumptions
    double totalPrice = activityPrice + consumptionsTotal;
    double amountDue = totalPrice - (
      bookingDetails.booking.deposit + 
      (bookingDetails.booking.cardPayment ?? 0) + 
      (bookingDetails.booking.cashPayment ?? 0)
    );

    // Create a new booking info with updated totals
    final updatedBooking = BookingInfo(
      bookingId: bookingDetails.booking.bookingId,
      firstname: bookingDetails.booking.firstname,
      lastname: bookingDetails.booking.lastname,
      date: bookingDetails.booking.date,
      nbrPers: bookingDetails.booking.nbrPers,
      nbrParties: bookingDetails.booking.nbrParties,
      email: bookingDetails.booking.email,
      phoneNumber: bookingDetails.booking.phoneNumber,
      notes: bookingDetails.booking.notes,
      total: totalPrice,
      amount: amountDue < 0 ? 0 : amountDue,
      deposit: bookingDetails.booking.deposit,
      isCancelled: bookingDetails.booking.isCancelled,
      cardPayment: bookingDetails.booking.cardPayment,
      cashPayment: bookingDetails.booking.cashPayment,
    );

    // Update the booking details with the new booking info
    bookingDetails.booking = updatedBooking;
  }

  /// Add consumption to a booking
  Future<void> addConsumption(String bookingId, FoodItem item) async {
    try {
      await client.rpc(
        'insert_conso',
        params: {'actual_booking_id': bookingId, 'actual_food_id': item.id},
      );
    } catch (e) {
      rethrow;
    }
  }

  /// Update consumption quantity
  Future<void> updateConsumptionQuantity(
    String bookingId,
    String itemId,
    int newQuantity,
  ) async {
    try {
      if (newQuantity <= 0) {
        // If the new quantity is zero or negative, remove all instances of this item
        await removeConsumption(bookingId, itemId);
        return;
      }

      // For increasing quantity, add one more using insert_conso
      await client.rpc(
        'insert_conso',
        params: {'actual_booking_id': bookingId, 'actual_food_id': itemId},
      );
    } catch (e) {
      rethrow;
    }
  }

  /// Remove one instance of a consumption item
  Future<void> decreaseConsumptionQuantity(
    String bookingId,
    String itemId,
  ) async {
    try {
      await client.rpc(
        'delete_conso',
        params: {'actual_booking_id': bookingId, 'actual_food_id': itemId},
      );
    } catch (e) {
      rethrow;
    }
  }

  /// Remove a consumption completely (all instances)
  Future<void> removeConsumption(String bookingId, String itemId) async {
    try {
      // First get the current quantity
      final consumptionsResponse = await client.rpc(
        'get_conso',
        params: {'actual_booking_id': bookingId},
      );

      if (consumptionsResponse != null) {
        final item = (consumptionsResponse as List).firstWhere(
          (item) => item['food_id'] == itemId,
          orElse: () => null,
        );

        if (item != null) {
          final quantity = _parseInt(item['quantity']);
          // Delete each instance
          for (int i = 0; i < quantity; i++) {
            await client.rpc(
              'delete_conso',
              params: {
                'actual_booking_id': bookingId,
                'actual_food_id': itemId,
              },
            );
          }
        }
      }
    } catch (e) {
      rethrow;
    }
  }

  /// Update booking total in the database
  Future<void> updateBookingTotalInDatabase(
    String bookingId,
    double activityPrice,
    double consumptionsTotal,
    double deposit,
    double? cardPayment,
    double? cashPayment,
  ) async {
    try {
      // Calculate new total and amount - this is the key formula
      double newTotal = activityPrice + consumptionsTotal;
      double newAmount =
          newTotal - (deposit + (cardPayment ?? 0) + (cashPayment ?? 0));

      // Ensure amount is not negative
      if (newAmount < 0) newAmount = 0;

      // Update in database
      await client
          .from('bookings')
          .update({'total': newTotal, 'amount': newAmount})
          .eq('booking_id', bookingId);
    } catch (e) {
      rethrow;
    }
  }

  /// Cancel a booking
  Future<void> cancelBooking(String bookingId) async {
    try {
      await client
          .from('bookings')
          .update({'is_cancelled': true})
          .eq('booking_id', bookingId);
    } catch (e) {
      rethrow;
    }
  }

  /// Reinstate a cancelled booking
  Future<void> reinstateBooking(String bookingId) async {
    try {
      await client
          .from('bookings')
          .update({'is_cancelled': false})
          .eq('booking_id', bookingId);
    } catch (e) {
      rethrow;
    }
  }

  /// Delete a booking
  Future<void> deleteBooking(String activityBookingId) async {
    try {
      await client.rpc(
        'delete_booking',
        params: {'p_activity_booking_id': activityBookingId},
      );
    } catch (e) {
      rethrow;
    }
  }

  /// Fetch all food items
  Future<List<FoodItem>> getFoodItems() async {
    try {
      final response = await client.from('food').select().order('name');
      final foodItems =
          (response as List)
              .map(
                (item) => FoodItem(
                  id: item['food_id'],
                  name: item['name'],
                  price:
                      (item['price'] is int)
                          ? (item['price'] as int).toDouble()
                          : item['price'],
                  quantity: 0, // Initialize with zero quantity for UI
                ),
              )
              .toList();

      // Ensure items are sorted alphabetically by name (client-side sorting)
      foodItems.sort(
        (a, b) => a.name.toLowerCase().compareTo(b.name.toLowerCase()),
      );
      return foodItems;
    } catch (e) {
      rethrow;
    }
  }

  /// Calculate activity price based on pricing model
  double calculateActivityPrice(BookingDetails bookingDetails) {
    final nbrPers = bookingDetails.booking.nbrPers;
    final nbrParties = bookingDetails.booking.nbrParties;

    // Get price per person based on number of parties
    double pricePerPerson;

    // Base price depends on the number of parties (1,2,3)
    if (nbrParties == 1) {
      pricePerPerson = bookingDetails.pricing.firstPrice;
    } else if (nbrParties == 2) {
      pricePerPerson = bookingDetails.pricing.secondPrice;
    } else if (nbrParties == 3) {
      pricePerPerson = bookingDetails.pricing.thirdPrice;
    } else {
      // For parties > 3, calculate based on pattern
      int remainingParties = nbrParties - 3;
      int fullCycles =
          remainingParties ~/ 3; // Number of complete 3-party cycles
      int remainder =
          remainingParties % 3; // Remaining parties after full cycles

      double additionalPrice = 0;
      // Add price for full cycles
      if (fullCycles > 0) {
        additionalPrice += fullCycles * bookingDetails.pricing.thirdPrice;
      }

      // Add price for remainder
      if (remainder == 1) {
        additionalPrice += bookingDetails.pricing.firstPrice;
      } else if (remainder == 2) {
        additionalPrice += bookingDetails.pricing.secondPrice;
      }

      pricePerPerson = bookingDetails.pricing.thirdPrice + additionalPrice;
    }

    // Calculate total activity price: price per person * number of persons
    return pricePerPerson * nbrPers;
  }

  // Helper methods for parsing values
  double _parseDouble(dynamic value) {
    if (value == null) return 0.0;
    if (value is double) return value;
    if (value is int) return value.toDouble();
    if (value is String) return double.tryParse(value) ?? 0.0;
    return 0.0;
  }

  int _parseInt(dynamic value) {
    if (value == null) return 0;
    if (value is int) return value;
    if (value is String) return int.tryParse(value) ?? 0;
    if (value is double) return value.toInt();
    return 0;
  }
}
