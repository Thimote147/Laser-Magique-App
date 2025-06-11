import 'package:supabase_flutter/supabase_flutter.dart';
import '../models/payment_model.dart';
import '../config/supabase_config.dart';

class PaymentRepository {
  final SupabaseClient _client = SupabaseConfig.client;

  // Create a new payment
  Future<Payment> createPayment(Payment payment) async {
    final response =
        await _client
            .from('payments')
            .insert({
              'booking_id': payment.bookingId,
              'amount': payment.amount,
              'method': payment.method.toString().split('.').last,
              'type': payment.type.toString().split('.').last,
              'date': payment.date.toIso8601String(),
            })
            .select()
            .single();

    return Payment.fromJson(response);
  }

  // Get all payments for a booking
  Future<List<Payment>> getPaymentsByBooking(String bookingId) async {
    final response = await _client
        .from('payments')
        .select()
        .eq('booking_id', bookingId)
        .order('date');

    return response.map<Payment>((json) => Payment.fromJson(json)).toList();
  }

  // Delete a payment
  Future<void> deletePayment(String paymentId) async {
    await _client.from('payments').delete().eq('id', paymentId);
  }

  // Get real-time updates for payments of a booking
  Stream<List<Payment>> getPaymentsStream(String bookingId) {
    return _client
        .from('payments')
        .stream(primaryKey: ['id'])
        .eq('booking_id', bookingId)
        .order('date')
        .map(
          (response) =>
              response.map<Payment>((json) => Payment.fromJson(json)).toList(),
        );
  }
}
