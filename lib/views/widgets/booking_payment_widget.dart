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
    Key? key,
    required this.icon,
    required this.label,
    required this.isSelected,
    required this.onTap,
  }) : super(key: key);

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

  @override
  Widget build(BuildContext context) {
    return Consumer<BookingViewModel>(
      builder: (context, bookingViewModel, child) {
        final updatedBooking = bookingViewModel.bookings.firstWhere(
          (b) => b.id == booking.id,
          orElse: () => booking,
        );

        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // En-tête avec résumé des paiements
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Padding(
                  padding: EdgeInsets.zero,
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text(
                        'Paiements',
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      FilledButton.tonalIcon(
                        onPressed:
                            updatedBooking.remainingBalance > 0
                                ? () => _showAddPaymentDialog(context)
                                : null,
                        icon: const Icon(Icons.add_circle, size: 24),
                        label: const Text(
                          'Nouveau paiement',
                          style: TextStyle(fontWeight: FontWeight.bold),
                        ),
                        style: FilledButton.styleFrom(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 16,
                            vertical: 12,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 8),
                _buildPaymentSummary(updatedBooking),
              ],
            ),

            // Liste des paiements
            if (updatedBooking.payments.isNotEmpty) ...[
              const Padding(
                padding: EdgeInsets.fromLTRB(0, 24.0, 0, 8.0),
                child: Text(
                  'Historique des paiements',
                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.w500),
                ),
              ),
              ...updatedBooking.payments.map(
                (payment) => _buildPaymentCard(context, payment),
              ),
            ],
          ],
        );
      },
    );
  }

  Widget _buildPaymentSummary(Booking booking) {
    return Builder(
      builder: (context) {
        final totalPayments = booking.totalPaid;
        final remaining = booking.remainingBalance;
        final theme = Theme.of(context);

        return Card(
          margin: EdgeInsets.zero,
          child: Padding(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'Prix total',
                          style: TextStyle(fontSize: 13, color: Colors.grey),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          '${booking.totalPrice.toStringAsFixed(2)}€',
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                            color: theme.primaryColor,
                          ),
                        ),
                      ],
                    ),
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 12,
                        vertical: 6,
                      ),
                      decoration: BoxDecoration(
                        color:
                            remaining <= 0
                                ? Colors.green.shade50
                                : Colors.orange.shade50,
                        borderRadius: BorderRadius.circular(16),
                      ),
                      child: Text(
                        remaining <= 0 ? 'PAYÉ' : 'EN ATTENTE',
                        style: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.bold,
                          color:
                              remaining <= 0
                                  ? Colors.green.shade700
                                  : Colors.orange.shade700,
                        ),
                      ),
                    ),
                  ],
                ),
                const Divider(height: 24),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'Total payé',
                          style: TextStyle(fontSize: 13, color: Colors.grey),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          '${totalPayments.toStringAsFixed(2)}€',
                          style: TextStyle(
                            fontSize: 15,
                            fontWeight: FontWeight.w500,
                            color:
                                totalPayments > 0
                                    ? Colors.green.shade700
                                    : null,
                          ),
                        ),
                      ],
                    ),
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.end,
                      children: [
                        const Text(
                          'Reste à payer',
                          style: TextStyle(fontSize: 13, color: Colors.grey),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          '${remaining.toStringAsFixed(2)}€',
                          style: TextStyle(
                            fontSize: 15,
                            fontWeight: FontWeight.w500,
                            color:
                                remaining > 0
                                    ? Colors.orange.shade700
                                    : Colors.green.shade700,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildPaymentCard(BuildContext context, Payment payment) {
    final theme = Theme.of(context);

    IconData getPaymentIcon() {
      switch (payment.method) {
        case PaymentMethod.card:
          return Icons.credit_card;
        case PaymentMethod.cash:
          return Icons.payments;
        case PaymentMethod.transfer:
          return Icons.account_balance;
      }
    }

    Color getPaymentColor() {
      switch (payment.method) {
        case PaymentMethod.card:
          return Colors.blue;
        case PaymentMethod.cash:
          return Colors.green;
        case PaymentMethod.transfer:
          return Colors.purple;
      }
    }

    return Card(
      margin: const EdgeInsets.only(bottom: 8.0),
      child: ListTile(
        leading: Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: getPaymentColor().withOpacity(0.1),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Icon(getPaymentIcon(), color: getPaymentColor(), size: 24),
        ),
        title: Row(
          children: [
            Text(
              payment.type == PaymentType.deposit ? 'Acompte' : 'Paiement',
              style: const TextStyle(fontWeight: FontWeight.bold),
            ),
            const SizedBox(width: 8),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
              decoration: BoxDecoration(
                color: theme.primaryColor.withOpacity(0.1),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Text(
                payment.method.displayName,
                style: TextStyle(fontSize: 12, color: theme.primaryColor),
              ),
            ),
          ],
        ),
        subtitle: Text(
          'Le ${payment.date.day}/${payment.date.month}/${payment.date.year}',
          style: TextStyle(color: Colors.grey[600]),
        ),
        trailing: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              '${payment.amount.toStringAsFixed(2)}€',
              style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
            ),
            IconButton(
              icon: const Icon(Icons.delete_outline),
              color: Colors.red,
              onPressed: () => _showDeletePaymentDialog(context, payment),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _showAddPaymentDialog(BuildContext context) async {
    double? amount;
    PaymentMethod selectedMethod = PaymentMethod.card;
    PaymentType selectedType = PaymentType.deposit;

    return showDialog<void>(
      context: context,
      builder: (BuildContext context) {
        return StatefulBuilder(
          builder: (context, setState) {
            return AlertDialog(
              title: const Text('Nouveau paiement'),
              content: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    TextFormField(
                      decoration: const InputDecoration(
                        labelText: 'Montant',
                        prefixText: '€',
                      ),
                      keyboardType: const TextInputType.numberWithOptions(
                        decimal: true,
                      ),
                      inputFormatters: [
                        FilteringTextInputFormatter.allow(
                          RegExp(r'^\d+[,\.]?\d{0,2}'),
                        ),
                      ],
                      onChanged: (value) {
                        setState(() {
                          // Remplace la virgule par un point pour le parsing
                          final parsableValue = value.replaceAll(',', '.');
                          amount = double.tryParse(parsableValue);
                          print('Amount parsed: $amount'); // Pour débogage
                        });
                      },
                    ),
                    const SizedBox(height: 16),
                    Column(
                      children: [
                        const Text(
                          'Méthode de paiement',
                          style: TextStyle(fontSize: 14, color: Colors.grey),
                        ),
                        const SizedBox(height: 8),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                          children: [
                            Expanded(
                              child: _PaymentMethodButton(
                                icon: Icons.credit_card,
                                label: 'CB',
                                isSelected:
                                    selectedMethod == PaymentMethod.card,
                                onTap:
                                    () => setState(() {
                                      selectedMethod = PaymentMethod.card;
                                    }),
                              ),
                            ),
                            const SizedBox(width: 8),
                            Expanded(
                              child: _PaymentMethodButton(
                                icon: Icons.payments,
                                label: 'Espèces',
                                isSelected:
                                    selectedMethod == PaymentMethod.cash,
                                onTap:
                                    () => setState(() {
                                      selectedMethod = PaymentMethod.cash;
                                    }),
                              ),
                            ),
                            const SizedBox(width: 8),
                            Expanded(
                              child: _PaymentMethodButton(
                                icon: Icons.account_balance,
                                label: 'Virement',
                                isSelected:
                                    selectedMethod == PaymentMethod.transfer,
                                onTap:
                                    () => setState(() {
                                      selectedMethod = PaymentMethod.transfer;
                                    }),
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),
                    Column(
                      children: [
                        const Text(
                          'Type de paiement',
                          style: TextStyle(fontSize: 14, color: Colors.grey),
                        ),
                        const SizedBox(height: 8),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                          children: [
                            Expanded(
                              child: _PaymentMethodButton(
                                icon: Icons.download,
                                label: 'Acompte',
                                isSelected: selectedType == PaymentType.deposit,
                                onTap:
                                    () => setState(() {
                                      selectedType = PaymentType.deposit;
                                    }),
                              ),
                            ),
                            const SizedBox(width: 8),
                            Expanded(
                              child: _PaymentMethodButton(
                                icon: Icons.check_circle,
                                label: 'Solde',
                                isSelected: selectedType == PaymentType.balance,
                                onTap:
                                    () => setState(() {
                                      selectedType = PaymentType.balance;
                                    }),
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              actions: <Widget>[
                TextButton(
                  child: const Text('Annuler'),
                  onPressed: () {
                    Navigator.of(context).pop();
                  },
                ),
                FilledButton(
                  onPressed:
                      amount != null && amount! > 0
                          ? () {
                            final bookingViewModel =
                                context.read<BookingViewModel>();
                            bookingViewModel.addPayment(
                              bookingId: booking.id,
                              amount: amount!,
                              method: selectedMethod,
                              type: selectedType,
                            );
                            Navigator.of(context).pop();
                          }
                          : null,
                  child: const Text('Ajouter'),
                ),
              ],
            );
          },
        );
      },
    );
  }

  void _showDeletePaymentDialog(BuildContext context, Payment payment) {
    showDialog(
      context: context,
      builder:
          (context) => AlertDialog(
            title: const Text('Confirmer la suppression'),
            content: Text(
              'Voulez-vous vraiment supprimer ce paiement de ${payment.amount.toStringAsFixed(2)}€ ?',
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context),
                child: const Text('Annuler'),
              ),
              FilledButton(
                onPressed: () {
                  // D'abord fermer le dialogue
                  Navigator.pop(context);

                  // Ensuite supprimer le paiement et afficher le message
                  final bookingViewModel = context.read<BookingViewModel>();
                  bookingViewModel.cancelPayment(
                    bookingId: booking.id,
                    paymentId: payment.id,
                  );

                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text('Paiement supprimé'),
                      duration: Duration(seconds: 2),
                    ),
                  );
                },
                style: FilledButton.styleFrom(foregroundColor: Colors.red),
                child: const Text('Supprimer'),
              ),
            ],
          ),
    );
  }
}
