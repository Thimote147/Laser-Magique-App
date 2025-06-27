import 'package:flutter/foundation.dart';
import '../../features/booking/models/booking_model.dart';
import '../models/payment_model.dart';
import '../repositories/payment_repository.dart';

class PaymentViewModel extends ChangeNotifier {
  final PaymentRepository _repository = PaymentRepository();
  bool _isLoading = false;
  String? _error;
  final Map<String, List<Payment>> _bookingPayments = {};

  bool get isLoading => _isLoading;
  String? get error => _error;

  // Récupère les paiements d'une réservation et souscrit aux mises à jour
  void initializeForBooking(String bookingId) {
    _repository
        .getPaymentsStream(bookingId)
        .listen(
          (payments) {
            _bookingPayments[bookingId] = payments;
            notifyListeners();
          },
          onError: (error) {
            _error = error.toString();
            notifyListeners();
          },
        );
  }

  // Ajoute un nouveau paiement à une réservation
  Future<void> addPayment({
    required Booking booking,
    required double amount,
    required PaymentMethod method,
    required PaymentType type,
  }) async {
    try {
      _isLoading = true;
      _error = null;
      notifyListeners();

      final payment = Payment(
        bookingId: booking.id,
        amount: amount,
        method: method,
        type: type,
        date: DateTime.now(),
      );

      await _repository.createPayment(payment);
    } catch (e) {
      _error = e.toString();
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  // Annule un paiement
  Future<void> cancelPayment({required String paymentId}) async {
    try {
      _isLoading = true;
      _error = null;
      notifyListeners();

      await _repository.deletePayment(paymentId);
    } catch (e) {
      _error = e.toString();
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  // Calcule le total des paiements par méthode de paiement
  Map<PaymentMethod, double> getPaymentsByMethod(String bookingId) {
    final payments = _bookingPayments[bookingId] ?? [];
    final Map<PaymentMethod, double> totals = {};
    for (final payment in payments) {
      totals[payment.method] = (totals[payment.method] ?? 0) + payment.amount;
    }
    return totals;
  }

  // Vérifie si un acompte a été versé
  bool hasDeposit(String bookingId) {
    final payments = _bookingPayments[bookingId] ?? [];
    return payments.any((payment) => payment.type == PaymentType.deposit);
  }

  // Obtient le montant total de l'acompte
  double getDepositAmount(String bookingId) {
    final payments = _bookingPayments[bookingId] ?? [];
    return payments
        .where((payment) => payment.type == PaymentType.deposit)
        .fold(0, (sum, payment) => sum + payment.amount);
  }
}
