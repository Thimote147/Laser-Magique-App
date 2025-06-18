import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import '../../models/booking_model.dart';
import '../../models/payment_model.dart';
import '../../viewmodels/booking_view_model.dart';

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

class _PaymentMethodButton extends StatelessWidget {
  final IconData icon;
  final String label;
  final bool isSelected;
  final VoidCallback onTap;

  const _PaymentMethodButton({
    required this.icon,
    required this.label,
    required this.isSelected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color:
              isSelected
                  ? theme.primaryColor.withOpacity(0.1)
                  : Colors.grey.shade100,
          borderRadius: BorderRadius.circular(8),
          border: Border.all(
            color: isSelected ? theme.primaryColor : Colors.grey.shade300,
            width: 1,
          ),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              icon,
              color: isSelected ? theme.primaryColor : Colors.grey.shade700,
              size: 24,
            ),
            const SizedBox(height: 4),
            Text(
              label,
              style: TextStyle(
                color: isSelected ? theme.primaryColor : Colors.grey.shade700,
                fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                fontSize: 12,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class BookingPaymentWidget extends StatelessWidget {
  final Booking booking;

  const BookingPaymentWidget({super.key, required this.booking});

  double get _totalPaid =>
      booking.payments.fold(0.0, (sum, payment) => sum + payment.amount);
  double get _remainingAmount => booking.formula.price - _totalPaid;

  Widget _buildPaymentHeader(BuildContext context) {
    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surfaceVariant.withOpacity(0.3),
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
                  '${booking.formula.price.toStringAsFixed(2)}€',
                  style: Theme.of(
                    context,
                  ).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.w500),
                ),
              ],
            ),
          ),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
            decoration: BoxDecoration(
              color:
                  _remainingAmount > 0
                      ? Theme.of(context).colorScheme.errorContainer
                      : Theme.of(context).colorScheme.primaryContainer,
              borderRadius: BorderRadius.circular(8),
            ),
            child: Text(
              _remainingAmount > 0 ? 'EN ATTENTE' : 'PAYÉ',
              style: Theme.of(context).textTheme.labelMedium?.copyWith(
                color:
                    _remainingAmount > 0
                        ? Theme.of(context).colorScheme.error
                        : Theme.of(context).colorScheme.primary,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPaymentDetails(BuildContext context) {
    return Container(
      width: double.infinity,
      margin: const EdgeInsets.only(top: 8),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surfaceVariant.withOpacity(0.3),
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
                  '${_remainingAmount.toStringAsFixed(2)}€',
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.w500,
                    color:
                        _remainingAmount > 0
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
  }

  Widget _buildPaymentHistory(BuildContext context) {
    if (booking.payments.isEmpty) {
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
        ...booking.payments
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
    if (_remainingAmount <= 0) {
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
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildPaymentHeader(context),
        _buildPaymentDetails(context),
        const SizedBox(height: 12),
        _buildAddPaymentButton(context),
        _buildPaymentHistory(context),
      ],
    );
  }

  Future<void> _showAddPaymentDialog(BuildContext context) async {
    final originalPayment = Payment(
      bookingId: booking.id,
      amount: _remainingAmount,
      method: PaymentMethod.card,
      type:
          booking.payments.isEmpty ? PaymentType.deposit : PaymentType.balance,
      date: DateTime.now(),
    );

    final payment = await showDialog<Payment>(
      context: context,
      builder:
          (context) => _AddPaymentDialog(
            booking: booking,
            initialPayment: originalPayment,
          ),
    );

    if (payment != null && context.mounted) {
      await Provider.of<BookingViewModel>(context, listen: false).addPayment(
        bookingId: payment.bookingId,
        amount: payment.amount,
        method: payment.method,
        type: payment.type,
      );
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
    }
  }

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
}

class _AddPaymentDialog extends StatefulWidget {
  final Booking booking;
  final Payment initialPayment;

  const _AddPaymentDialog({
    required this.booking,
    required this.initialPayment,
  });

  @override
  _AddPaymentDialogState createState() => _AddPaymentDialogState();
}

class _AddPaymentDialogState extends State<_AddPaymentDialog> {
  late Payment _payment;

  @override
  void initState() {
    super.initState();
    _payment = widget.initialPayment;
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('Nouveau paiement'),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          TextFormField(
            initialValue: _payment.amount.toStringAsFixed(2),
            decoration: InputDecoration(
              labelText: 'Montant',
              suffixText: '€',
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(8),
              ),
            ),
            keyboardType: TextInputType.numberWithOptions(decimal: true),
            onChanged: (value) {
              setState(() {
                _payment = _payment.copyWith(
                  amount: double.tryParse(value) ?? _payment.amount,
                );
              });
            },
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              Expanded(
                child: _PaymentMethodButton(
                  icon: Icons.credit_card,
                  label: 'CB',
                  isSelected: _payment.method == PaymentMethod.card,
                  onTap: () {
                    setState(() {
                      _payment = _payment.copyWith(method: PaymentMethod.card);
                    });
                  },
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: _PaymentMethodButton(
                  icon: Icons.euro_rounded,
                  label: 'Espèces',
                  isSelected: _payment.method == PaymentMethod.cash,
                  onTap: () {
                    setState(() {
                      _payment = _payment.copyWith(method: PaymentMethod.cash);
                    });
                  },
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: _PaymentMethodButton(
                  icon: Icons.account_balance,
                  label: 'Virement',
                  isSelected: _payment.method == PaymentMethod.transfer,
                  onTap: () {
                    setState(() {
                      _payment = _payment.copyWith(
                        method: PaymentMethod.transfer,
                      );
                    });
                  },
                ),
              ),
            ],
          ),
        ],
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: const Text('Annuler'),
        ),
        TextButton(
          onPressed: () => Navigator.of(context).pop(_payment),
          child: const Text('Ajouter'),
        ),
      ],
    );
  }
}
