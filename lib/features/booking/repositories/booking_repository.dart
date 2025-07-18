import 'dart:async';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../../core/constants/supabase_config.dart';
import '../models/booking_model.dart';
import '../../../shared/models/formula_model.dart';
import '../../../shared/models/payment_model.dart';

class BookingRepository {
  final SupabaseClient _client = SupabaseConfig.client;

  // Realtime subscriptions
  RealtimeChannel? _bookingsChannel;

  // Stream controllers for real-time updates
  final StreamController<List<Booking>> _bookingsController =
      StreamController<List<Booking>>.broadcast();

  // Stream getters
  Stream<List<Booking>> get bookingsStream => _bookingsController.stream;

  // Initialize realtime subscriptions
  void initializeRealtimeSubscriptions() {
    _subscribeToBookings();
  }

  // Subscribe to bookings table changes
  void _subscribeToBookings() {
    _bookingsChannel = _client.channel('bookings_channel');

    _bookingsChannel!
        .onPostgresChanges(
          event: PostgresChangeEvent.all,
          schema: 'public',
          table: 'bookings',
          callback: (payload) {
            _handleBookingsChange(payload);
          },
        )
        .subscribe();
  }

  // Handle bookings changes
  void _handleBookingsChange(PostgresChangePayload payload) {
    switch (payload.eventType) {
      case PostgresChangeEvent.insert:
        _refreshBookingsData();
        break;
      case PostgresChangeEvent.update:
        _refreshBookingsData();
        break;
      case PostgresChangeEvent.delete:
        _refreshBookingsData();
        break;
      case PostgresChangeEvent.all:
        // Handle all event type if needed
        break;
    }
  }

  // Refresh bookings data from database
  void _refreshBookingsData() async {
    try {
      final bookings = await getAllBookings();
      _bookingsController.add(bookings);
    } catch (e) {
      // Log error silently or use proper logging framework
    }
  }

  // Get stream of bookings for a specific day
  Stream<List<Booking>> getBookingsStreamForDay(DateTime date) {
    return _bookingsController.stream.map((bookings) {
      final startOfDay = DateTime(date.year, date.month, date.day).toUtc();
      final endOfDay = startOfDay.add(const Duration(days: 1));

      return bookings.where((booking) {
        return booking.dateTime.isAfter(startOfDay) &&
            booking.dateTime.isBefore(endOfDay);
      }).toList();
    });
  }

  // Dispose method to clean up subscriptions
  void dispose() {
    _bookingsChannel?.unsubscribe();
    _bookingsController.close();
  }

  // Récupère la liste des réservations
  Future<List<Booking>> getAllBookings() async {
    try {
      final response = await _client
          .from('booking_summaries')
          .select()
          .order('date_time');

      final bookings =
          (response as List).map((json) => Booking.fromMap(json)).toList();

      return bookings;
    } catch (e) {
      rethrow;
    }
  }

  Future<List<Booking>> getBookingsForDay(DateTime date) async {
    // On s'assure que les dates de début et fin de journée sont en UTC
    final startOfDay = DateTime(date.year, date.month, date.day).toUtc();
    final endOfDay = startOfDay.add(const Duration(days: 1));

    final response = await _client
        .from('booking_summaries')
        .select()
        .gte('date_time', startOfDay.toIso8601String())
        .lt('date_time', endOfDay.toIso8601String())
        .order('date_time');

    final bookings =
        (response as List).map((json) => Booking.fromMap(json)).toList();

    return bookings;
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
    // On s'assure que la date est en UTC avant de l'envoyer à la base de données
    final dateTimeUTC = dateTime.toUtc();
    final bookingId = await _client.rpc(
      'create_booking_with_payment',
      params: {
        'p_formula_id': formula.id,
        'p_first_name': firstName,
        'p_last_name': lastName,
        'p_email': email,
        'p_phone': phone,
        'p_date_time': dateTimeUTC.toIso8601String(),
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
    final response = await _client.rpc(
      'update_booking_with_customer',
      params: {
        'p_booking_id': booking.id,
        'p_formula_id': booking.formula.id,
        'p_first_name': booking.firstName,
        'p_last_name': booking.lastName,
        'p_email': booking.email,
        'p_phone': booking.phone,
        'p_date_time': booking.dateTime.toIso8601String(),
        'p_number_of_persons': booking.numberOfPersons,
        'p_number_of_games': booking.numberOfGames,
        'p_is_cancelled': booking.isCancelled,
        'p_deposit': booking.deposit,
        'p_payment_method': booking.paymentMethod.toString().split('.').last,
      },
    );

    if (response == null) {
      throw Exception('Failed to update booking');
    }

    return Booking.fromMap(response);
  }

  Future<void> deleteBooking(String id) async {
    await _client.from('bookings').delete().eq('id', id);
  }

  Future<void> addPayment({
    required String bookingId,
    required double amount,
    required PaymentMethod method,
    required PaymentType type,
    DateTime? date,
  }) async {
    final paymentData = {
      'booking_id': bookingId,
      'amount': amount,
      'payment_method': method.toString().split('.').last,
      'payment_type': type.toString().split('.').last,
      'payment_date':
          date?.toIso8601String() ?? DateTime.now().toIso8601String(),
    };

    try {
      await _client.from('payments').insert(paymentData).select();
    } catch (e) {
      rethrow;
    }
  }

  Future<void> cancelPayment(String paymentId) async {
    await _client.from('payments').delete().eq('id', paymentId);
  }

  Future<Booking> cancelBooking(String bookingId) async {
    try {
      final response = await _client.rpc(
        'cancel_booking',
        params: {'p_booking_id': bookingId},
      );

      if (response == null) {
        throw Exception('Échec de l\'annulation de la réservation');
      }

      return Booking.fromMap(response);
    } catch (e) {
      if (e is PostgrestException) {
        throw Exception(e.message);
      }
      rethrow;
    }
  }

  // Récupère une réservation spécifique avec toutes ses données à jour
  Future<Booking> getBooking(String bookingId) async {
    try {
      // Ajout d'un petit délai pour laisser le temps à la vue SQL de se mettre à jour
      await Future.delayed(const Duration(milliseconds: 100));

      final data =
          await _client
              .from('booking_summaries')
              .select()
              .eq('id', bookingId)
              .single();

      return Booking.fromMap(data);
    } catch (e) {
      rethrow;
    }
  }

  // Récupère les détails complets d'une réservation, y compris les montants à jour
  Future<Booking> getBookingDetails(String bookingId) async {
    try {
      // Récupère les données depuis la vue SANS la jointure problématique
      final data =
          await _client
              .from('booking_summaries')
              .select() // Sélectionne tout sans jointure
              .eq('id', bookingId)
              .single();

      return Booking.fromMap(data);
    } catch (e) {
      rethrow;
    }
  }

  // Mise à jour des totaux d'une réservation
  Future<void> updateBookingTotals({
    required String bookingId,
    required double consumptionsTotal,
  }) async {
    try {
      await _client
          .from('bookings')
          .update({'consumptions_total': consumptionsTotal})
          .eq('id', bookingId);
    } catch (e) {
      throw Exception('Erreur lors de la mise à jour des totaux: $e');
    }
  }
}
