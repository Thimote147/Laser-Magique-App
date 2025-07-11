import 'dart:async';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../models/payment_model.dart';
import '../../core/constants/supabase_config.dart';

class PaymentRepository {
  final SupabaseClient _client = SupabaseConfig.client;
  
  RealtimeChannel? _paymentsChannel;
  final StreamController<List<Payment>> _paymentsStreamController = StreamController<List<Payment>>.broadcast();
  
  Stream<List<Payment>> get paymentsStream => _paymentsStreamController.stream;
  
  PaymentRepository() {
    _initializeRealtimeSubscription();
  }
  
  void _initializeRealtimeSubscription() {
    _paymentsChannel = _client.channel('payments_channel');
    
    _paymentsChannel!.onPostgresChanges(
      event: PostgresChangeEvent.all,
      schema: 'public',
      table: 'payments',
      callback: (payload) {
        _refreshPayments();
      },
    );
    
    _paymentsChannel!.subscribe();
  }
  
  Future<void> _refreshPayments() async {
    try {
      final response = await _client.from('payments').select().order('payment_date');
      final payments = response.map<Payment>((json) => Payment.fromJson(json)).toList();
      _paymentsStreamController.add(payments);
    } catch (e) {
      _paymentsStreamController.addError(e);
    }
  }

  // Create a new payment
  Future<Payment> createPayment(Payment payment) async {
    final paymentData = {
      'booking_id': payment.bookingId,
      'amount': payment.amount,
      'payment_method': payment.method.toString().split('.').last,
      'payment_type': payment.type.toString().split('.').last,
      'payment_date': payment.date.toIso8601String(),
    };

    try {
      final response =
          await _client.from('payments').insert(paymentData).select().single();

      return Payment.fromJson(response);
    } catch (e) {
      rethrow;
    }
  } // Get all payments for a booking

  Future<List<Payment>> getPaymentsByBooking(String bookingId) async {
    try {
      final response = await _client
          .from('payments')
          .select()
          .eq('booking_id', bookingId)
          .order('payment_date');

      return response.map<Payment>((json) => Payment.fromJson(json)).toList();
    } catch (e) {
      rethrow;
    }
  } // Delete a payment

  Future<void> deletePayment(String paymentId) async {
    await _client.from('payments').delete().eq('id', paymentId);
  }

  // Get real-time updates for payments of a booking
  Stream<List<Payment>> getPaymentsStream(String bookingId) {
    return paymentsStream.map((allPayments) => 
      allPayments.where((payment) => payment.bookingId == bookingId).toList()
    );
  }
  
  void dispose() {
    _paymentsChannel?.unsubscribe();
    _paymentsStreamController.close();
  }
}
