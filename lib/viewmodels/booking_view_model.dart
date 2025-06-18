import 'dart:async';
import 'package:flutter/foundation.dart';
import '../models/booking_model.dart';
import '../models/formula_model.dart';
import '../models/payment_model.dart';
import '../repositories/booking_repository.dart';
import 'activity_formula_view_model.dart';
import 'stock_view_model.dart';

class BookingViewModel extends ChangeNotifier {
  final BookingRepository _repository = BookingRepository();
  ActivityFormulaViewModel _activityFormulaViewModel;
  StockViewModel _stockViewModel;
  Timer? _refreshTimer;

  List<Booking> _bookings = [];
  bool _isLoading = true;
  String? _error;

  BookingViewModel(this._activityFormulaViewModel, this._stockViewModel) {
    _initializeData();
    _setupPeriodicRefresh();
  }

  // Getters
  List<Formula> get availableFormulas => _activityFormulaViewModel.formulas;
  List<Booking> get bookings => List.unmodifiable(
    _bookings.map(
      (booking) => booking.copyWith(
        consumptionsTotal: _stockViewModel.getConsumptionsTotalForBooking(
          booking.id,
        ),
        formula:
            _activityFormulaViewModel.getFormulaById(booking.formula.id) ??
            booking.formula,
      ),
    ),
  );
  bool get isLoading => _isLoading;
  String? get error => _error;

  // Initialise les données
  Future<void> _initializeData() async {
    await loadBookings();
  }

  // Configure le rafraîchissement périodique
  void _setupPeriodicRefresh() {
    // Rafraîchit toutes les 30 secondes
    _refreshTimer = Timer.periodic(const Duration(seconds: 30), (_) {
      loadBookings();
    });
  }

  @override
  void dispose() {
    _refreshTimer?.cancel();
    super.dispose();
  }

  /// Rafraîchit la liste des réservations
  Future<void> loadBookings() async {
    try {
      _isLoading = true;
      _error = null;
      notifyListeners();

      final bookings = await _repository.getAllBookings();

      // Compare les anciennes et nouvelles réservations
      bool hasChanges = _bookings.length != bookings.length;
      if (!hasChanges) {
        for (int i = 0; i < _bookings.length; i++) {
          if (_bookings[i].id != bookings[i].id ||
              _bookings[i].dateTime != bookings[i].dateTime ||
              _bookings[i].firstName != bookings[i].firstName ||
              _bookings[i].isCancelled != bookings[i].isCancelled ||
              _bookings[i].remainingBalance != bookings[i].remainingBalance) {
            hasChanges = true;
            break;
          }
        }
      }

      if (hasChanges) {
        _bookings = bookings;
        notifyListeners();
      }

      _isLoading = false;
      notifyListeners();
    } catch (e) {
      _error = 'Error loading bookings: $e';
      _isLoading = false;
      notifyListeners();
    }
  }

  // Booking management
  Future<void> addBooking({
    required String firstName,
    String? lastName,
    required DateTime dateTime,
    int numberOfPersons = 1,
    int numberOfGames = 1,
    String? email,
    String? phone,
    required Formula formula,
    double deposit = 0.0,
    PaymentMethod paymentMethod = PaymentMethod.card,
  }) async {
    try {
      // Validate that the formula exists and is up to date
      final currentFormula = _activityFormulaViewModel.getFormulaById(
        formula.id,
      );
      if (currentFormula == null) {
        throw Exception(
          'Invalid formula. The selected formula no longer exists.',
        );
      }

      await _repository.createBooking(
        firstName: firstName,
        lastName: lastName,
        dateTime: dateTime,
        numberOfPersons: numberOfPersons,
        numberOfGames: numberOfGames,
        email: email,
        phone: phone,
        formula: currentFormula,
        deposit: deposit,
        paymentMethod: paymentMethod,
      );
    } catch (e) {
      _error = 'Error creating booking: $e';
      notifyListeners();
      rethrow;
    }
  }

  Future<void> updateBooking(Booking booking) async {
    try {
      await _repository.updateBooking(booking);
    } catch (e) {
      _error = 'Error updating booking: $e';
      notifyListeners();
      rethrow;
    }
  }

  Future<void> deleteBooking(String id) async {
    try {
      await _repository.deleteBooking(id);
    } catch (e) {
      _error = 'Error deleting booking: $e';
      notifyListeners();
      rethrow;
    }
  }

  // Payment management
  Future<void> addPayment({
    required String bookingId,
    required double amount,
    required PaymentMethod method,
    required PaymentType type,
  }) async {
    try {
      await _repository.addPayment(
        bookingId: bookingId,
        amount: amount,
        method: method,
        type: type,
      );
    } catch (e) {
      _error = 'Error adding payment: $e';
      notifyListeners();
      rethrow;
    }
  }

  Future<void> cancelPayment(String paymentId) async {
    try {
      await _repository.cancelPayment(paymentId);
    } catch (e) {
      _error = 'Error canceling payment: $e';
      notifyListeners();
      rethrow;
    }
  }

  // Booking queries
  List<Booking> getBookingsForDay(DateTime date) {
    final startOfDay = DateTime(date.year, date.month, date.day);
    final endOfDay = startOfDay.add(const Duration(days: 1));

    return bookings
        .where(
          (booking) =>
              booking.dateTime.isAfter(startOfDay) &&
              booking.dateTime.isBefore(endOfDay),
        )
        .toList()
      ..sort((a, b) => a.dateTime.compareTo(b.dateTime));
  }

  Future<void> toggleCancellationStatus(String bookingId) async {
    try {
      final booking = _bookings.firstWhere((b) => b.id == bookingId);
      await updateBooking(booking.copyWith(isCancelled: !booking.isCancelled));
    } catch (e) {
      _error = 'Error updating booking status: $e';
      notifyListeners();
      rethrow;
    }
  }

  // Refresh data
  Future<void> refresh() async {
    await _initializeData();
  }

  // Clear error
  void clearError() {
    _error = null;
    notifyListeners();
  }

  // Delete a booking (alias for deleteBooking for consistency with UI code)
  Future<void> removeBooking(String id) async {
    await deleteBooking(id);
  }

  // Méthode pour mettre à jour les dépendances
  void updateDependencies(
    ActivityFormulaViewModel activityFormulaViewModel,
    StockViewModel stockViewModel,
  ) {
    _activityFormulaViewModel = activityFormulaViewModel;
    _stockViewModel = stockViewModel;
    notifyListeners(); // Notifier en cas de changements dans les dépendances
  }
}
