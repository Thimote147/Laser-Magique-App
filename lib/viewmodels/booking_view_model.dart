import 'package:flutter/foundation.dart';
import 'package:uuid/uuid.dart';
import '../models/booking_model.dart';
import '../models/formula_model.dart';
import '../models/payment_model.dart' as payment_model;
import 'activity_formula_view_model.dart';
import 'stock_view_model.dart';

class BookingViewModel extends ChangeNotifier {
  // Liste des réservations
  final List<Booking> _bookings = [];

  // Référence au ViewModel des activités et formules
  final ActivityFormulaViewModel _activityFormulaViewModel;
  final StockViewModel _stockViewModel;

  // Constructeur
  BookingViewModel(this._activityFormulaViewModel, this._stockViewModel) {
    // Listen to changes in consumptions
    _stockViewModel.addListener(_onConsumptionsChanged);
  }

  @override
  void dispose() {
    _stockViewModel.removeListener(_onConsumptionsChanged);
    super.dispose();
  }

  // Called when consumptions change in StockViewModel
  void _onConsumptionsChanged() {
    notifyListeners(); // This will trigger a rebuild of all booking widgets
  }

  // Calculer le total des consommations pour une réservation
  double _getConsumptionsTotal(String bookingId) {
    return _stockViewModel.getConsumptionsTotalForBooking(bookingId);
  }

  // Getter pour accéder aux réservations avec les consommations à jour
  List<Booking> get bookings => List.unmodifiable(
    _bookings.map(
      (booking) => booking.copyWith(
        consumptionsTotal: _getConsumptionsTotal(booking.id),
      ),
    ),
  );

  // Méthode pour ajouter une réservation
  void addBooking({
    required String firstName,
    String? lastName,
    required DateTime dateTime,
    int numberOfPersons = 1,
    int numberOfGames = 1,
    String? email,
    String? phone,
    required Formula formula,
    double deposit = 0.0,
    payment_model.PaymentMethod? paymentMethod,
    List<payment_model.Payment>? payments,
  }) {
    final String bookingId = const Uuid().v4(); // Génère un ID unique

    // Créer une liste de paiements, y compris l'acompte si présent
    List<payment_model.Payment> allPayments = payments?.toList() ?? [];

    // Si un acompte est spécifié, créer un paiement correspondant
    if (deposit > 0) {
      final depositPayment = payment_model.Payment(
        bookingId: bookingId,
        amount: deposit,
        method: paymentMethod ?? payment_model.PaymentMethod.card,
        type: payment_model.PaymentType.deposit,
        date: DateTime.now(),
      );
      allPayments.add(depositPayment);
    }

    final booking = Booking(
      id: bookingId,
      firstName: firstName,
      lastName: lastName,
      dateTime: dateTime,
      numberOfPersons: numberOfPersons,
      numberOfGames: numberOfGames,
      email: email,
      phone: phone,
      formula: formula,
      deposit: deposit,
      paymentMethod: paymentMethod ?? payment_model.PaymentMethod.card,
      payments: allPayments,
    );

    _bookings.add(booking);
    notifyListeners();
  }

  // Méthode pour ajouter un paiement à une réservation
  void addPayment({
    required String bookingId,
    required double amount,
    required payment_model.PaymentMethod method,
    required payment_model.PaymentType type,
  }) {
    final index = _bookings.indexWhere((b) => b.id == bookingId);
    if (index == -1) return;

    final payment = payment_model.Payment(
      bookingId: bookingId,
      amount: amount,
      method: method,
      type: type,
      date: DateTime.now(),
    );

    final booking = _bookings[index];
    final updatedPayments = [...booking.payments, payment];
    _bookings[index] = booking.copyWith(payments: updatedPayments);

    notifyListeners();
  }

  // Méthode pour annuler un paiement
  void cancelPayment({required String bookingId, required String paymentId}) {
    final index = _bookings.indexWhere((b) => b.id == bookingId);
    if (index == -1) return;

    final booking = _bookings[index];
    final updatedPayments =
        booking.payments.where((p) => p.id != paymentId).toList();
    _bookings[index] = booking.copyWith(payments: updatedPayments);

    notifyListeners();
  }

  // Méthode pour mettre à jour une réservation
  void updateBooking(Booking updatedBooking) {
    final index = _bookings.indexWhere(
      (booking) => booking.id == updatedBooking.id,
    );
    if (index != -1) {
      _bookings[index] = updatedBooking;
      notifyListeners();
    }
  }

  // Méthode pour supprimer une réservation
  void removeBooking(String bookingId) {
    _bookings.removeWhere((booking) => booking.id == bookingId);
    notifyListeners();
  }

  // Méthode pour basculer l'état d'annulation d'une réservation
  void toggleCancellationStatus(String bookingId) {
    final index = _bookings.indexWhere((booking) => booking.id == bookingId);
    if (index != -1) {
      final booking = _bookings[index];
      _bookings[index] = booking.copyWith(isCancelled: !booking.isCancelled);
      notifyListeners();
    }
  }

  // Méthode pour récupérer les réservations d'une journée spécifique
  List<Booking> getBookingsForDay(DateTime day) {
    final bookings =
        _bookings
            .where(
              (booking) =>
                  booking.dateTime.year == day.year &&
                  booking.dateTime.month == day.month &&
                  booking.dateTime.day == day.day,
            )
            .toList();

    // Trier les réservations par heure uniquement
    bookings.sort((a, b) => a.dateTime.compareTo(b.dateTime));

    return bookings;
  }

  // Méthode pour charger des réservations de test (pour démo)
  void loadDummyBookings() {
    // S'assurer que les activités et formules sont chargées
    if (_activityFormulaViewModel.formulas.isEmpty) {
      _activityFormulaViewModel.loadDummyData();
    }

    // Récupérer quelques formules pour les exemples
    final formulas = _activityFormulaViewModel.formulas;
    if (formulas.isEmpty) return;

    // Formule par défaut pour les exemples
    final defaultFormula = formulas.first;

    // Récupérer des formules spécifiques si disponibles
    final laserFormula =
        _activityFormulaViewModel.getFormulaById('2') ??
        defaultFormula; // Anniversaire Laser Game
    final arcadeFormula =
        _activityFormulaViewModel.getFormulaById('4') ??
        defaultFormula; // Découverte Arcade
    final vrFormula =
        _activityFormulaViewModel.getFormulaById('6') ??
        defaultFormula; // Découverte VR

    final now = DateTime.now();

    // Exemple avec paiement complet en carte
    _bookings.add(
      Booking(
        id: '1',
        firstName: 'Jean',
        lastName: 'Dupont',
        dateTime: DateTime(now.year, now.month, now.day, 10, 0),
        numberOfPersons: 4,
        numberOfGames: 2,
        email: 'jean.dupont@example.com',
        phone: '06 12 34 56 78',
        formula: laserFormula,
        payments: [
          payment_model.Payment(
            bookingId: '1',
            amount: 120.0,
            method: payment_model.PaymentMethod.card,
            type: payment_model.PaymentType.balance,
            date: DateTime.now().subtract(const Duration(days: 1)),
          ),
        ],
      ),
    );

    // Exemple avec acompte en espèces
    _bookings.add(
      Booking(
        id: '2',
        firstName: 'Marie',
        lastName: 'Martin',
        dateTime: DateTime(now.year, now.month, now.day, 14, 30),
        numberOfPersons: 6,
        numberOfGames: 3,
        email: 'marie.martin@example.com',
        phone: '07 65 43 21 09',
        formula: arcadeFormula,
        isCancelled: true,
        payments: [
          payment_model.Payment(
            bookingId: '2',
            amount: 50.0,
            method: payment_model.PaymentMethod.cash,
            type: payment_model.PaymentType.deposit,
            date: DateTime.now().subtract(const Duration(days: 7)),
          ),
        ],
      ),
    );

    // Exemple sans paiement
    _bookings.add(
      Booking(
        id: '3',
        firstName: 'Sophie',
        lastName: 'Lefebvre',
        dateTime: DateTime(now.year, now.month, now.day + 1, 11, 0),
        numberOfPersons: 2,
        numberOfGames: 1,
        email: 'sophie.lefebvre@example.com',
        phone: '06 98 76 54 32',
        formula: vrFormula,
        payments: [],
      ),
    );

    notifyListeners();
  }
}
