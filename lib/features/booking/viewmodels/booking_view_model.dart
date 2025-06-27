import 'dart:async';
import 'package:flutter/foundation.dart';
import '../models/booking_model.dart';
import '../../../shared/models/formula_model.dart';
import '../../../shared/models/payment_model.dart' as payment_model;
import '../repositories/booking_repository.dart';
import '../../../shared/viewmodels/activity_formula_view_model.dart';

/// Manages the state and business logic for bookings.
///
/// Important timezone handling notes:
/// - All dates are stored in UTC in the database and model
/// - UI components receive and display dates in local timezone
/// - Date comparisons in [getBookingsForDay] handle timezone conversion internally
///
/// Example calendar date handling:
/// ```dart
/// // UI passes local date
/// final localDate = DateTime.now();
/// // ViewModel converts to UTC internally for filtering
/// final bookings = viewModel.getBookingsForDay(localDate);
/// // Results automatically convert back to local for display
/// print(bookings.first.dateTimeLocal);
/// ```
class BookingViewModel extends ChangeNotifier {
  final BookingRepository _repository = BookingRepository();
  ActivityFormulaViewModel _activityFormulaViewModel;
  Timer? _refreshTimer;
  Timer? _debounceTimer;
  DateTime? _lastManualRefresh;

  List<Booking> _bookings = [];
  final Map<String, Booking> _bookingCache = {};
  bool _isLoading = true;
  String? _error;

  BookingViewModel(this._activityFormulaViewModel) {
    _initializeData();
    _setupPeriodicRefresh();
  }

  // Getters
  List<Formula> get availableFormulas => _activityFormulaViewModel.formulas;
  List<Booking> get bookings => List.unmodifiable(
    _bookings.map(
      (booking) => booking.copyWith(
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
    // Rafraîchit toutes les 30 secondes si aucune action utilisateur récente
    _refreshTimer = Timer.periodic(const Duration(seconds: 30), (_) {
      final now = DateTime.now();
      // Ne rafraîchit que si aucun refresh manuel n'a été fait dans les 30 dernières secondes
      if (_lastManualRefresh == null ||
          now.difference(_lastManualRefresh!) > const Duration(seconds: 30)) {
        loadBookings();
      }
    });
  }

  @override
  void dispose() {
    _refreshTimer?.cancel();
    _debounceTimer?.cancel();
    super.dispose();
  }

  /// Déclenche un refresh immédiat avec debounce
  Future<void> _triggerImmediateRefresh() async {
    _lastManualRefresh = DateTime.now();
    _debounceTimer?.cancel();
    _debounceTimer = Timer(const Duration(milliseconds: 500), () async {
      await loadBookings();
    });
  }

  /// Rafraîchit la liste des réservations
  Future<void> loadBookings() async {
    try {
      _isLoading = true;
      _error = null;
      notifyListeners();

      final bookings = await _repository.getAllBookings();
      for (var booking in bookings) {
        _bookingCache[booking.id] = booking;
      }

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
    payment_model.PaymentMethod paymentMethod =
        payment_model.PaymentMethod.card,
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

      final newBooking = await _repository.createBooking(
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

      // Mise à jour optimiste du cache
      _bookingCache[newBooking.id] = newBooking;
      _bookings = [..._bookings, newBooking]
        ..sort((a, b) => a.dateTimeLocal.compareTo(b.dateTimeLocal));
      notifyListeners();

      // Refresh différé pour s'assurer que les données sont à jour
      await _triggerImmediateRefresh();
    } catch (e) {
      _error = 'Error creating booking: $e';
      notifyListeners();
      rethrow;
    }
  }

  Future<void> updateBooking(Booking booking) async {
    try {
      // Mise à jour optimiste du cache
      _bookingCache[booking.id] = booking;
      final index = _bookings.indexWhere((b) => b.id == booking.id);
      if (index != -1) {
        _bookings[index] = booking;
        notifyListeners();
      }

      // Envoyer la mise à jour au serveur
      await _repository.updateBooking(booking);

      // Refresh différé pour s'assurer que les données sont à jour
      await _triggerImmediateRefresh();
    } catch (e) {
      _error = 'Error updating booking: $e';
      notifyListeners();
      rethrow;
    }
  }

  Future<void> deleteBooking(String id) async {
    try {
      // Suppression optimiste du cache
      _bookingCache.remove(id);
      _bookings.removeWhere((b) => b.id == id);
      notifyListeners();

      // Supprimer du serveur
      await _repository.deleteBooking(id);

      // Refresh différé pour s'assurer que les données sont à jour
      await _triggerImmediateRefresh();
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
    required payment_model.PaymentMethod method,
    required payment_model.PaymentType type,
    DateTime? date,
  }) async {
    try {
      await _repository.addPayment(
        bookingId: bookingId,
        amount: amount,
        method: method,
        type: type,
        date: date,
      );

      // Mise à jour optimiste du solde
      final booking = _bookingCache[bookingId];
      if (booking != null) {
        final newPayment = payment_model.Payment(
          id: 'temp_${DateTime.now().millisecondsSinceEpoch}',
          bookingId: bookingId,
          amount: amount,
          method: method,
          type: type,
          date: date ?? DateTime.now(),
        );
        final updatedBooking = booking.copyWith(
          payments: [...booking.payments, newPayment],
        );
        _bookingCache[bookingId] = updatedBooking;
        final index = _bookings.indexWhere((b) => b.id == bookingId);
        if (index != -1) {
          _bookings[index] = updatedBooking;
          notifyListeners();
        }
      }

      // Refresh différé pour s'assurer que les données sont à jour
      await _triggerImmediateRefresh();
    } catch (e) {
      _error = 'Error adding payment: $e';
      notifyListeners();
      rethrow;
    }
  }

  Future<void> cancelPayment(String paymentId) async {
    try {
      await _repository.cancelPayment(paymentId);
      // Refresh différé pour s'assurer que les données sont à jour
      await _triggerImmediateRefresh();
    } catch (e) {
      _error = 'Error canceling payment: $e';
      notifyListeners();
      rethrow;
    }
  }

  // Booking queries
  List<Booking> getBookingsForDay(DateTime localDate) {
    // Convert local date to UTC range for comparison
    final startOfDayUTC = DateTime.utc(
      localDate.year,
      localDate.month,
      localDate.day,
    );
    final endOfDayUTC = DateTime.utc(
      localDate.year,
      localDate.month,
      localDate.day,
      23,
      59,
      59,
    );

    return bookings
        .where(
          (booking) =>
              booking.dateTimeUTC.isAfter(startOfDayUTC) &&
              booking.dateTimeUTC.isBefore(endOfDayUTC),
        )
        .toList()
      ..sort((a, b) => a.dateTimeLocal.compareTo(b.dateTimeLocal));
  }

  Future<void> toggleCancellationStatus(String bookingId) async {
    try {
      final booking = _bookings.firstWhere((b) => b.id == bookingId);
      final updatedBooking = booking.copyWith(
        isCancelled: !booking.isCancelled,
      );

      // Mise à jour optimiste
      _bookingCache[bookingId] = updatedBooking;
      final index = _bookings.indexWhere((b) => b.id == bookingId);
      if (index != -1) {
        _bookings[index] = updatedBooking;
        notifyListeners();
      }

      // Envoyer au serveur
      await updateBooking(updatedBooking);

      // Refresh différé
      await _triggerImmediateRefresh();
    } catch (e) {
      _error = 'Error updating booking status: $e';
      notifyListeners();
      rethrow;
    }
  }

  // Refresh data
  Future<void> refresh() async {
    await _triggerImmediateRefresh();
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
  void updateDependencies(ActivityFormulaViewModel activityFormulaViewModel) {
    _activityFormulaViewModel = activityFormulaViewModel;
    notifyListeners(); // Notifier en cas de changements dans les dépendances
  }

  // Récupère une réservation spécifique avec ses données à jour
  Future<Booking> getBooking(String bookingId) async {
    try {
      // Attendre un peu pour laisser le temps à la base de calculer les nouveaux totaux
      await Future.delayed(const Duration(milliseconds: 500));

      final booking = await _repository.getBooking(bookingId);

      // Mettre à jour la réservation dans la liste locale si elle existe
      final index = _bookings.indexWhere((b) => b.id == bookingId);
      if (index != -1) {
        _bookings[index] = booking;
        notifyListeners();
      }

      return booking;
    } catch (e) {
      _error = 'Error fetching booking: $e';
      notifyListeners();
      rethrow;
    }
  }

  // Mise à jour optimiste du cache pour une réservation
  void updateBookingInCache(
    String bookingId, {
    double? newTotalPrice,
    double? newConsumptionsTotal,
  }) {
    if (_bookingCache.containsKey(bookingId)) {
      final booking = _bookingCache[bookingId]!;
      _bookingCache[bookingId] = booking.copyWith(
        totalPrice: newTotalPrice ?? booking.totalPrice,
        consumptionsTotal: newConsumptionsTotal ?? booking.consumptionsTotal,
      );
      notifyListeners();
    }
  }

  // Récupère une réservation depuis le cache ou la base
  Booking? getCachedBooking(String bookingId) {
    return _bookingCache[bookingId];
  }

  // Calcule le nouveau total pour une réservation après modification des consommations
  Future<void> updateBookingTotals(
    String bookingId,
    double consumptionsTotal,
  ) async {
    try {
      final booking = _bookingCache[bookingId];
      if (booking != null) {
        // Mise à jour optimiste du cache
        final newTotalPrice = booking.formulaPrice + consumptionsTotal;
        final updatedBooking = booking.copyWith(
          consumptionsTotal: consumptionsTotal,
          totalPrice: newTotalPrice,
        );
        _bookingCache[bookingId] = updatedBooking;
        final index = _bookings.indexWhere((b) => b.id == bookingId);
        if (index != -1) {
          _bookings[index] = updatedBooking;
          notifyListeners();
        }

        // Synchronisation avec la base
        await _repository.updateBookingTotals(
          bookingId: bookingId,
          consumptionsTotal: consumptionsTotal,
        );

        // Refresh différé
        await _triggerImmediateRefresh();
      }
    } catch (e) {
      _error = 'Error updating booking totals: $e';
      notifyListeners();
      // En cas d'erreur, recharger les données depuis la base
      await getBookingDetails(bookingId);
    }
  }

  // Récupère les données à jour d'une réservation
  Future<Booking> getBookingDetails(String bookingId) async {
    try {
      final booking = await _repository.getBookingDetails(bookingId);

      // Mettre à jour le cache local
      _bookingCache[bookingId] = booking;

      // Mettre à jour la réservation dans la liste locale
      final index = _bookings.indexWhere((b) => b.id == bookingId);
      if (index != -1) {
        _bookings[index] = booking;
      }

      notifyListeners();
      return booking;
    } catch (e) {
      _error = 'Error fetching booking: $e';
      notifyListeners();
      rethrow;
    }
  }
}
