import 'package:flutter/foundation.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../config/supabase_config.dart';
import '../models/booking_model.dart';
import '../models/formula_model.dart';
import '../models/payment_model.dart';

class BookingRepository {
  final SupabaseClient _client = SupabaseConfig.client;

  Future<List<Booking>> getAllBookings() async {
    final response = await _client
        .from('booking_summaries')
        .select()
        .order('date_time');

    return (response as List).map((json) => Booking.fromMap(json)).toList();
  }

  Future<List<Booking>> getBookingsForDay(DateTime date) async {
    final startOfDay = DateTime(date.year, date.month, date.day);
    final endOfDay = startOfDay.add(const Duration(days: 1));

    final response = await _client
        .from('booking_summaries')
        .select()
        .gte('date_time', startOfDay.toIso8601String())
        .lt('date_time', endOfDay.toIso8601String())
        .order('date_time');

    return (response as List).map((json) => Booking.fromMap(json)).toList();
  }

  Future<Booking> createBooking({
    required String firstName,
    String? lastName,
    required DateTime dateTime,
    required int numberOfPersons,
    required int numberOfGames,
    String? email,
    String? phone,
    required Formula formula,
    double deposit = 0.0,
    PaymentMethod paymentMethod = PaymentMethod.card,
  }) async {
    final bookingId = await _client.rpc(
      'create_booking_with_payment',
      params: {
        'p_formula_id': formula.id,
        'p_first_name': firstName,
        'p_last_name': lastName,
        'p_email': email,
        'p_phone': phone,
        'p_date_time': dateTime.toIso8601String(),
        'p_number_of_persons': numberOfPersons,
        'p_number_of_games': numberOfGames,
        'p_deposit': deposit,
        'p_payment_method': paymentMethod.toString().split('.').last,
      },
    );

    final response =
        await _client
            .from('booking_summaries')
            .select()
            .eq('id', bookingId)
            .single();

    return Booking.fromMap(response);
  }

  Future<Booking> updateBooking(Booking booking) async {
    final response =
        await _client
            .from('bookings')
            .update({
              'formula_id': booking.formula.id,
              'first_name': booking.firstName,
              'last_name': booking.lastName,
              'email': booking.email,
              'phone': booking.phone,
              'date_time': booking.dateTime.toIso8601String(),
              'number_of_persons': booking.numberOfPersons,
              'number_of_games': booking.numberOfGames,
              'is_cancelled': booking.isCancelled,
              'deposit': booking.deposit,
              'payment_method':
                  booking.paymentMethod.toString().split('.').last,
            })
            .eq('id', booking.id)
            .select()
            .single();

    return Booking.fromMap(response);
  }

  Future<void> deleteBooking(String id) async {
    await _client.from('bookings').delete().eq('id', id);
  }

  Stream<List<Booking>> streamBookings() {
    const maxRetries = 3;
    var retryCount = 0;
    var retryDelay = const Duration(seconds: 1);

    return _client
        .from('booking_summaries')
        .stream(primaryKey: ['id'])
        .order('date_time')
        .handleError(
          (error) {
            debugPrint('Error in booking stream: $error');
            if (retryCount >= maxRetries) {
              debugPrint('Max retry attempts reached ($maxRetries)');
              throw Exception('Failed to reconnect after $maxRetries attempts');
            }

            retryCount++;
            debugPrint(
              'Retry attempt $retryCount/$maxRetries after ${retryDelay.inSeconds}s',
            );

            // Implémente un délai de reconnexion exponentiel
            final currentDelay = retryDelay;
            retryDelay *= 2;

            return Future.delayed(
              currentDelay,
            ).asStream().asyncExpand((_) => streamBookings());
          },
          test:
              (error) =>
                  error
                      is! FormatException, // Ne pas réessayer pour les erreurs de format
        )
        .map((response) {
          try {
            return (response as List)
                .map((json) => Booking.fromMap(json))
                .toList();
          } catch (e) {
            debugPrint('Error parsing booking data: $e');
            return <Booking>[];
          }
        });
  }

  Future<void> addPayment({
    required String bookingId,
    required double amount,
    required PaymentMethod method,
    required PaymentType type,
  }) async {
    await _client.from('payments').insert({
      'booking_id': bookingId,
      'amount': amount,
      'payment_method': method.toString().split('.').last,
      'payment_type': type.toString().split('.').last,
    });
  }

  Future<void> cancelPayment(String paymentId) async {
    await _client.from('payments').delete().eq('id', paymentId);
  }
}
