import 'dart:async';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../models/booking_model.dart';
import '../../../../shared/models/payment_model.dart' as payment_model;
import '../../../../shared/services/consumption_price_service.dart';
import '../../viewmodels/booking_view_model.dart';
import '../../../inventory/viewmodels/stock_view_model.dart';
import 'add_payment_dialog.dart';

extension PaymentMethodExtension on payment_model.PaymentMethod {
  String get displayName {
    switch (this) {
      case payment_model.PaymentMethod.card:
        return 'Carte bancaire';
      case payment_model.PaymentMethod.cash:
        return 'Espèces';
      case payment_model.PaymentMethod.transfer:
        return 'Virement';
    }
  }
}

extension PaymentTypeExtension on payment_model.PaymentType {
  String get displayName {
    switch (this) {
      case payment_model.PaymentType.deposit:
        return 'Acompte';
      case payment_model.PaymentType.balance:
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

  // ValueNotifiers pour conserver l'affichage pendant les mises à jour
  final ValueNotifier<double> _totalPriceNotifier = ValueNotifier<double>(0);
  final ValueNotifier<double> _consumptionsTotalNotifier =
      ValueNotifier<double>(0);
  final ValueNotifier<double> _formulaPriceNotifier = ValueNotifier<double>(0);
  final ValueNotifier<double> _remainingAmountNotifier = ValueNotifier<double>(
    0,
  );
  final ValueNotifier<bool> _showFormulaDetailsNotifier = ValueNotifier<bool>(
    false,
  );

  // Service pour recevoir les mises à jour de prix des consommations
  final ConsumptionPriceService _priceService = ConsumptionPriceService();

  // Debouncer pour stabiliser les mises à jour du montant des consommations
  Timer? _consumptionUpdateTimer;

  @override
  void initState() {
    super.initState();
    _currentBooking = widget.booking;
    // Initialiser les notifiers
    _formulaPriceNotifier.value = _currentBooking.formulaPrice;

    // Configurer l'écoute des mises à jour de prix des consommations
    _listenToConsumptionPriceUpdates();

    // Appeler _refreshBookingData après l'initialisation
    Future.microtask(() {
      if (mounted) {
        _refreshBookingData();
      }
    });
  }

  // Écouter les mises à jour de prix des consommations
  void _listenToConsumptionPriceUpdates() {
    final consumptionPriceNotifier = _priceService.getNotifierForBooking(
      _currentBooking.id,
    );

    // Initialiser avec la valeur actuelle si disponible
    // Éviter l'utilisation de microtask pour réduire les mises à jour en cascade
    if (mounted) {
      // Toujours vérifier la valeur la plus récente du StockViewModel
      final stockVM = Provider.of<StockViewModel>(context, listen: false);
      final stockConsumptionsTotal = stockVM.getConsumptionTotal(
        _currentBooking.id,
      );

      // Utiliser la valeur du service, et la synchroniser avec StockViewModel si nécessaire
      double effectiveTotal = consumptionPriceNotifier.value;
      bool needsServiceUpdate = false;

      // Si le StockViewModel a une valeur différente, vérifier quelle est la plus à jour
      if (stockConsumptionsTotal != effectiveTotal) {
        if (stockConsumptionsTotal > 0) {
          effectiveTotal = stockConsumptionsTotal;
          needsServiceUpdate = true;
        }
      }

      // N'effectuer qu'une seule mise à jour coordonnée pour éviter les rebonds
      if (effectiveTotal > 0) {
        // Mise à jour locale immédiate sans déclencher de cascades
        _updatePaymentDisplay(effectiveTotal);

        // Synchroniser le service uniquement si nécessaire
        if (needsServiceUpdate) {
          debugPrint(
            'BookingPaymentWidget: Synchronizing service with StockViewModel value: $effectiveTotal',
          );
          _priceService.updateConsumptionPriceSync(
            _currentBooking.id,
            effectiveTotal,
          );
        }
      }
    }

    // Écouter les changements futurs
    consumptionPriceNotifier.addListener(() {
      if (mounted) {
        final newValue = consumptionPriceNotifier.value;
        debugPrint(
          'BookingPaymentWidget: Consumption price changed to $newValue',
        );

        // Effectuer une seule mise à jour coordonnée
        _updatePaymentDisplay(newValue);
      }
    });
  }

  // Méthode unifiée pour mettre à jour l'affichage des paiements
  void _updatePaymentDisplay(double consumptionsTotal) {
    // Annuler le timer précédent s'il existe
    _consumptionUpdateTimer?.cancel();

    // Utiliser un debouncer pour stabiliser les mises à jour
    _consumptionUpdateTimer = Timer(const Duration(milliseconds: 150), () {
      if (mounted) {
        // Ne mettre à jour que si la valeur a changé
        if (_consumptionsTotalNotifier.value != consumptionsTotal) {
          _consumptionsTotalNotifier.value = consumptionsTotal;
          _totalPriceNotifier.value =
              _currentBooking.formulaPrice + consumptionsTotal;
          _remainingAmountNotifier.value = _getRemainingAmount(
            consumptionsTotal,
          );
          _showFormulaDetailsNotifier.value = consumptionsTotal > 0;

          debugPrint(
            'BookingPaymentWidget: Display updated (debounced) - Total: ${_totalPriceNotifier.value}, '
            'Remaining: ${_remainingAmountNotifier.value}',
          );
        }
      }
    });
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

      // Avant de mettre à jour, récupérer la valeur actuelle des consommations
      final consumptionPriceNotifier = _priceService.getNotifierForBooking(
        _currentBooking.id,
      );
      final currentConsumptionsTotal = consumptionPriceNotifier.value;

      final updatedBooking = await bookingViewModel.getBookingDetails(
        _currentBooking.id,
      );

      if (mounted) {
        setState(() {
          _currentBooking = updatedBooking;
        });

        // Mettre à jour les notifiers relatifs à la formule et au statut de paiement
        _formulaPriceNotifier.value = _currentBooking.formulaPrice;

        // Calculer le prix total en utilisant la valeur actuelle des consommations
        _totalPriceNotifier.value =
            _currentBooking.formulaPrice + currentConsumptionsTotal;
        _remainingAmountNotifier.value = _getRemainingAmount(
          currentConsumptionsTotal,
        );
        _showFormulaDetailsNotifier.value = currentConsumptionsTotal > 0;
      }
    } catch (e) {
      // Silent error handling
    }
  }

  double get _totalPaid {
    // Déduplication des paiements par ID pour le calcul
    final uniquePayments = <String, payment_model.Payment>{};
    for (final payment in _currentBooking.payments) {
      uniquePayments[payment.id] = payment;
    }

    // Calculer le total uniquement sur les paiements uniques
    return uniquePayments.values.fold(
      0.0,
      (sum, payment) => sum + payment.amount,
    );
  }

  double _getRemainingAmount(double consumptionsTotal) {
    final totalPrice = _currentBooking.formulaPrice + consumptionsTotal;
    return totalPrice - _totalPaid;
  }

  Widget _buildPaymentHeader(BuildContext context) {
    return Consumer<StockViewModel>(
      builder: (context, stockVM, _) {
        // Calculer les valeurs pour les notifiers
        final consumptionsTotal = stockVM.getConsumptionTotal(
          _currentBooking.id,
        );

        // S'assurer que le service de prix est à jour avec la dernière valeur
        final currentServiceValue =
            _priceService.getNotifierForBooking(_currentBooking.id).value;

        // Si le service n'est pas à jour avec la valeur stockVM, le mettre à jour
        if (consumptionsTotal > 0 && currentServiceValue != consumptionsTotal) {
          Future.microtask(() {
            _priceService.updateConsumptionPrice(
              _currentBooking.id,
              consumptionsTotal,
            );
          });
        }

        // Utiliser la valeur la plus récente pour le calcul
        final effectiveConsumptionsTotal =
            consumptionsTotal > 0 ? consumptionsTotal : currentServiceValue;

        // Utiliser le système de debouncing pour éviter le flickering
        _updatePaymentDisplay(effectiveConsumptionsTotal);

        return Container(
          width: double.infinity,
          decoration: BoxDecoration(
            color: Theme.of(context).colorScheme.surfaceContainerHighest
                .withAlpha((255 * 0.3).round()),
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
                    ValueListenableBuilder<double>(
                      valueListenable: _totalPriceNotifier,
                      builder: (context, totalPrice, _) {
                        return Text(
                          '${totalPrice.toStringAsFixed(2)}€',
                          style: Theme.of(context).textTheme.titleLarge
                              ?.copyWith(fontWeight: FontWeight.w500),
                        );
                      },
                    ),
                    const SizedBox(height: 4),
                    ValueListenableBuilder<bool>(
                      valueListenable: _showFormulaDetailsNotifier,
                      builder: (context, showDetails, _) {
                        if (!showDetails) return const SizedBox.shrink();

                        return ValueListenableBuilder<double>(
                          valueListenable: _formulaPriceNotifier,
                          builder: (context, formulaPrice, _) {
                            return ValueListenableBuilder<double>(
                              valueListenable: _consumptionsTotalNotifier,
                              builder: (context, consumptionsTotal, _) {
                                return Text(
                                  'Formule: ${formulaPrice.toStringAsFixed(2)}€ + Consommations: ${consumptionsTotal.toStringAsFixed(2)}€',
                                  style: Theme.of(
                                    context,
                                  ).textTheme.bodySmall?.copyWith(
                                    color:
                                        Theme.of(
                                          context,
                                        ).colorScheme.onSurfaceVariant,
                                  ),
                                );
                              },
                            );
                          },
                        );
                      },
                    ),
                  ],
                ),
              ),
              ValueListenableBuilder<double>(
                valueListenable: _remainingAmountNotifier,
                builder: (context, remainingAmount, _) {
                  return Container(
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
                  );
                },
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
            color: Theme.of(context).colorScheme.surfaceContainerHighest
                .withAlpha((255 * 0.3).round()),
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

    // Filtrer les paiements pour éviter les doublons en se basant sur l'ID
    final uniquePayments = <String, payment_model.Payment>{};
    for (final payment in _currentBooking.payments) {
      uniquePayments[payment.id] = payment;
    }

    final payments = uniquePayments.values.toList();

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
        ...payments.map(
          (payment) => Container(
            margin: const EdgeInsets.only(bottom: 8),
            decoration: BoxDecoration(
              color: Theme.of(
                context,
              ).colorScheme.surface.withAlpha((255 * 0.7).round()),
              borderRadius: BorderRadius.circular(8),
            ),
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
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
                                  style: Theme.of(context).textTheme.titleMedium
                                      ?.copyWith(fontWeight: FontWeight.w500),
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
                                  style: Theme.of(context).textTheme.titleMedium
                                      ?.copyWith(fontWeight: FontWeight.w500),
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
        ),
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

    final originalPayment = payment_model.Payment(
      bookingId: _currentBooking.id,
      amount: remainingAmount,
      method: payment_model.PaymentMethod.card,
      type: payment_model.PaymentType.balance,
      date: DateTime.now(),
    );

    final payment = await showModalBottomSheet<payment_model.Payment>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      isDismissible: true,
      enableDrag: true,
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
    payment_model.Payment payment,
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

  @override
  void dispose() {
    // Nettoyer les notifiers pour éviter les fuites de mémoire
    _totalPriceNotifier.dispose();
    _consumptionsTotalNotifier.dispose();
    _formulaPriceNotifier.dispose();
    _remainingAmountNotifier.dispose();
    _showFormulaDetailsNotifier.dispose();

    // Nettoyer le timer de debouncing
    _consumptionUpdateTimer?.cancel();

    // Nettoyer le notifier de prix des consommations
    _priceService.cleanupNotifier(_currentBooking.id);

    super.dispose();
  }
}
