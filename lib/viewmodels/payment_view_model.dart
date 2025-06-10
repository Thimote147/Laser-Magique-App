import 'package:flutter/foundation.dart';
import '../models/booking_model.dart';
import '../models/payment_model.dart';

class PaymentViewModel extends ChangeNotifier {
  // Ajoute un nouveau paiement à une réservation
  void addPayment({
    required Booking booking,
    required double amount,
    required PaymentMethod method,
    required PaymentType type,
  }) {
    final payment = Payment(
      bookingId: booking.id,
      amount: amount,
      method: method,
      type: type,
      date: DateTime.now(),
    );

    final updatedPayments = [...booking.payments, payment];
    final updatedBooking = booking.copyWith(payments: updatedPayments);

    // On devrait mettre à jour la réservation dans le BookingViewModel
    // TODO: Implémenter la mise à jour dans le BookingViewModel
  }

  // Annule un paiement
  void cancelPayment({required Booking booking, required String paymentId}) {
    final updatedPayments =
        booking.payments.where((payment) => payment.id != paymentId).toList();
    final updatedBooking = booking.copyWith(payments: updatedPayments);

    // TODO: Implémenter la mise à jour dans le BookingViewModel
  }

  // Calcule le total des paiements par méthode de paiement
  Map<PaymentMethod, double> getPaymentsByMethod(Booking booking) {
    final Map<PaymentMethod, double> totals = {};
    for (final payment in booking.payments) {
      totals[payment.method] = (totals[payment.method] ?? 0) + payment.amount;
    }
    return totals;
  }

  // Vérifie si un acompte a été versé
  bool hasDeposit(Booking booking) {
    return booking.payments.any(
      (payment) => payment.type == PaymentType.deposit,
    );
  }

  // Obtient le montant total de l'acompte
  double getDepositAmount(Booking booking) {
    return booking.payments
        .where((payment) => payment.type == PaymentType.deposit)
        .fold(0, (sum, payment) => sum + payment.amount);
  }
}
