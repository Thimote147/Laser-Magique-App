import 'dart:async';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../models/booking_model.dart';
import '../../models/payment_model.dart';
import '../../viewmodels/booking_view_model.dart';
import '../../viewmodels/stock_view_model.dart';
import 'add_payment_dialog.dart';

extension PaymentMethodExtension on PaymentMethod {
  String get displayName {
    switch (this) {
      case PaymentMethod.card:
        return 'Carte bancaire';
      case PaymentMethod.cash:
        return 'Espèces';
      case PaymentMethod.transfer:
        return 'Virement';
    }
  }
}

extension PaymentTypeExtension on PaymentType {
  String get displayName {
    switch (this) {
      case PaymentType.deposit:
        return 'Acompte';
      case PaymentType.balance:
        return 'Solde';
    }
  }
}

// Utility method for date formatting
String _getMonthName(int month) {
  const months = [
    'janvier',
    'février',
    'mars',
    'avril',
    'mai',
    'juin',
    'juillet',
    'août',
    'septembre',
    'octobre',
    'novembre',
    'décembre',
  ];
  return months[month - 1];
}

class BookingPaymentWidget extends StatefulWidget {
  final Booking booking;

  const BookingPaymentWidget({super.key, required this.booking});

  @override
  State<BookingPaymentWidget> createState() => _BookingPaymentWidgetState();
}

class _BookingPaymentWidgetState extends State<BookingPaymentWidget> {
  late Booking _currentBooking;

  @override
  void initState() {
    super.initState();
    _currentBooking = widget.booking;
    _refreshBookingData();
  }

  @override
  void didUpdateWidget(BookingPaymentWidget oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.booking.id != widget.booking.id) {
      _currentBooking = widget.booking;
      _refreshBookingData();
    }
  }

  Future<void> _refreshBookingData() async {
    try {
      if (!mounted) return;
      final bookingViewModel = Provider.of<BookingViewModel>(
        context,
        listen: false,
      );
      final updatedBooking = await bookingViewModel.getBookingDetails(
        _currentBooking.id,
      );
      if (mounted) {
        setState(() {
          _currentBooking = updatedBooking;
        });
      }
    } catch (e) {
      // Silent error handling
    }
  }

  double get _totalPaid => _currentBooking.payments.fold(
    0.0,
    (sum, payment) => sum + payment.amount,
  );

  double _getRemainingAmount(double consumptionsTotal) {
    final totalPrice = _currentBooking.formulaPrice + consumptionsTotal;
    return totalPrice - _totalPaid;
  }

  Widget _buildPaymentHeader(BuildContext context) {
    return Consumer<StockViewModel>(
      builder: (context, stockVM, _) {
        final consumptionsTotal = stockVM.getConsumptionTotal(
          _currentBooking.id,
        );
        final totalPrice = _currentBooking.formulaPrice + consumptionsTotal;
        final remainingAmount = _getRemainingAmount(consumptionsTotal);

        return Container(
          width: double.infinity,
          decoration: BoxDecoration(
            color: Theme.of(
              context,
            ).colorScheme.surfaceVariant.withOpacity(0.3),
            borderRadius: BorderRadius.circular(8),
          ),
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          child: Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Montant total',
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        color: Theme.of(context).colorScheme.onSurfaceVariant,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      '${totalPrice.toStringAsFixed(2)}€',
                      style: Theme.of(context).textTheme.titleLarge?.copyWith(
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                    const SizedBox(height: 4),
                    if (consumptionsTotal > 0)
                      Text(
                        'Formule: ${_currentBooking.formulaPrice.toStringAsFixed(2)}€ + Consommations: ${consumptionsTotal.toStringAsFixed(2)}€',
                        style: Theme.of(context).textTheme.bodySmall?.copyWith(
                          color: Theme.of(context).colorScheme.onSurfaceVariant,
                        ),
                      ),
                  ],
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 12,
                  vertical: 6,
                ),
                decoration: BoxDecoration(
                  color:
                      remainingAmount > 0
                          ? Theme.of(context).colorScheme.errorContainer
                          : Theme.of(context).colorScheme.primaryContainer,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  remainingAmount > 0 ? 'EN ATTENTE' : 'PAYÉ',
                  style: Theme.of(context).textTheme.labelMedium?.copyWith(
                    color:
                        remainingAmount > 0
                            ? Theme.of(context).colorScheme.error
                            : Theme.of(context).colorScheme.primary,
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildPaymentDetails(BuildContext context) {
    return Consumer<StockViewModel>(
      builder: (context, stockVM, _) {
        final consumptionsTotal = stockVM.getConsumptionTotal(
          _currentBooking.id,
        );
        final remainingAmount = _getRemainingAmount(consumptionsTotal);

        return Container(
          width: double.infinity,
          margin: const EdgeInsets.only(top: 8),
          decoration: BoxDecoration(
            color: Theme.of(
              context,
            ).colorScheme.surfaceVariant.withOpacity(0.3),
            borderRadius: BorderRadius.circular(8),
          ),
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          child: Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Total payé',
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        color: Theme.of(context).colorScheme.onSurfaceVariant,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      '${_totalPaid.toStringAsFixed(2)}€',
                      style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.w500,
                        color:
                            _totalPaid > 0
                                ? Theme.of(context).colorScheme.primary
                                : null,
                      ),
                    ),
                  ],
                ),
              ),
              const VerticalDivider(width: 32),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Reste à payer',
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        color: Theme.of(context).colorScheme.onSurfaceVariant,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      '${remainingAmount.toStringAsFixed(2)}€',
                      style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.w500,
                        color:
                            remainingAmount > 0
                                ? Theme.of(context).colorScheme.error
                                : Theme.of(context).colorScheme.primary,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildPaymentHistory(BuildContext context) {
    if (_currentBooking.payments.isEmpty) {
      return const SizedBox.shrink();
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const SizedBox(height: 16),
        Text(
          'Historique des paiements',
          style: Theme.of(context).textTheme.titleSmall?.copyWith(
            color: Theme.of(context).colorScheme.onSurfaceVariant,
            fontWeight: FontWeight.w600,
          ),
        ),
        const SizedBox(height: 8),
        ..._currentBooking.payments
            .map(
              (payment) => Container(
                margin: const EdgeInsets.only(bottom: 8),
                decoration: BoxDecoration(
                  color: Theme.of(context).colorScheme.surface.withOpacity(0.7),
                  borderRadius: BorderRadius.circular(8),
                ),
                padding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 12,
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Expanded(
                          child: Row(
                            children: [
                              Expanded(
                                flex: 2,
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      payment.type.displayName,
                                      style: Theme.of(
                                        context,
                                      ).textTheme.bodySmall?.copyWith(
                                        color:
                                            Theme.of(
                                              context,
                                            ).colorScheme.onSurfaceVariant,
                                      ),
                                    ),
                                    const SizedBox(height: 4),
                                    Text(
                                      '${payment.amount.toStringAsFixed(2)}€',
                                      style: Theme.of(
                                        context,
                                      ).textTheme.titleMedium?.copyWith(
                                        fontWeight: FontWeight.w500,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                              const VerticalDivider(width: 32),
                              Expanded(
                                flex: 2,
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      'Moyen de paiement',
                                      style: Theme.of(
                                        context,
                                      ).textTheme.bodySmall?.copyWith(
                                        color:
                                            Theme.of(
                                              context,
                                            ).colorScheme.onSurfaceVariant,
                                      ),
                                    ),
                                    const SizedBox(height: 4),
                                    Text(
                                      payment.method.displayName,
                                      style: Theme.of(
                                        context,
                                      ).textTheme.titleMedium?.copyWith(
                                        fontWeight: FontWeight.w500,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ),
                        ),
                        IconButton(
                          icon: const Icon(Icons.delete_outline, size: 20),
                          onPressed:
                              () => _showDeletePaymentDialog(context, payment),
                          color: Theme.of(context).colorScheme.error,
                          tooltip: 'Supprimer le paiement',
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'Le ${payment.date.day} ${_getMonthName(payment.date.month)} ${payment.date.year}',
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        color: Theme.of(context).colorScheme.onSurfaceVariant,
                      ),
                    ),
                  ],
                ),
              ),
            )
            .toList(),
      ],
    );
  }

  Widget _buildAddPaymentButton(BuildContext context) {
    return Consumer<StockViewModel>(
      builder: (context, stockVM, _) {
        final consumptionsTotal = stockVM.getConsumptionTotal(
          _currentBooking.id,
        );
        final remainingAmount = _getRemainingAmount(consumptionsTotal);

        if (remainingAmount <= 0) {
          return const SizedBox.shrink();
        }

        return Container(
          margin: const EdgeInsets.only(top: 12),
          child: OutlinedButton.icon(
            onPressed: () => _showAddPaymentDialog(context),
            icon: const Icon(Icons.add),
            label: const Text('Nouveau paiement'),
            style: OutlinedButton.styleFrom(
              minimumSize: const Size(double.infinity, 48),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(8),
              ),
            ),
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildPaymentHeader(context),
        _buildPaymentDetails(context),
        _buildAddPaymentButton(context),
        _buildPaymentHistory(context),
      ],
    );
  }

  Future<void> _showAddPaymentDialog(BuildContext context) async {
    final stockVM = Provider.of<StockViewModel>(context, listen: false);
    final consumptionsTotal = stockVM.getConsumptionTotal(_currentBooking.id);
    final remainingAmount = _getRemainingAmount(consumptionsTotal);

    final originalPayment = Payment(
      bookingId: _currentBooking.id,
      amount: remainingAmount,
      method: PaymentMethod.card,
      type: PaymentType.balance,
      date: DateTime.now(),
    );

    final payment = await showModalBottomSheet<Payment>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder:
          (context) => AddPaymentDialog(
            booking: _currentBooking,
            initialPayment: originalPayment,
          ),
    );

    if (payment != null && context.mounted) {
      await Provider.of<BookingViewModel>(context, listen: false).addPayment(
        bookingId: payment.bookingId,
        amount: payment.amount,
        method: payment.method,
        type: payment.type,
        date: payment.date,
      );
      await _refreshBookingData();
    }
  }

  Future<void> _showDeletePaymentDialog(
    BuildContext context,
    Payment payment,
  ) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder:
          (context) => AlertDialog(
            title: const Text('Supprimer le paiement ?'),
            content: Text(
              'Voulez-vous vraiment supprimer ce paiement de ${payment.amount.toStringAsFixed(2)}€ ?',
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.of(context).pop(false),
                child: const Text('Annuler'),
              ),
              TextButton(
                onPressed: () => Navigator.of(context).pop(true),
                child: Text(
                  'Supprimer',
                  style: TextStyle(color: Theme.of(context).colorScheme.error),
                ),
              ),
            ],
          ),
    );

    if (confirmed == true && context.mounted) {
      await Provider.of<BookingViewModel>(
        context,
        listen: false,
      ).cancelPayment(payment.id);
      await _refreshBookingData();
    }
  }
}
