import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import '../../models/booking_model.dart';
import '../../models/payment_model.dart';
import '../../viewmodels/booking_view_model.dart';

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
    final totalPayments = booking.totalPaid;
    final remaining = booking.remainingBalance;

    return Card(
      margin: EdgeInsets.zero,
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text('Prix total:'),
                Text(
                  '${booking.totalPrice.toStringAsFixed(2)}€',
                  style: const TextStyle(fontWeight: FontWeight.bold),
                ),
              ],
            ),
            const Divider(),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text('Total payé:'),
                Text(
                  '${totalPayments.toStringAsFixed(2)}€',
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    color: totalPayments > 0 ? Colors.green : null,
                  ),
                ),
              ],
            ),
            const Divider(),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text('Reste à payer:'),
                Text(
                  '${remaining.toStringAsFixed(2)}€',
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    color: remaining > 0 ? Colors.orange : Colors.green,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildPaymentCard(BuildContext context, Payment payment) {
    return Card(
      margin: const EdgeInsets.only(bottom: 8.0),
      child: ListTile(
        leading: Icon(
          payment.method == PaymentMethod.card
              ? Icons.credit_card
              : Icons.money,
          color:
              payment.method == PaymentMethod.card ? Colors.blue : Colors.green,
        ),
        title: Text(
          payment.type == PaymentType.deposit ? 'Acompte' : 'Paiement',
        ),
        subtitle: Text(
          '${payment.method == PaymentMethod.card ? 'Carte' : 'Espèces'} • ${payment.date.day}/${payment.date.month}/${payment.date.year}',
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

  void _showAddPaymentDialog(BuildContext context) {
    // Vérifier le solde avant d'ouvrir le dialogue
    final bookingViewModel = context.read<BookingViewModel>();
    final updatedBooking = bookingViewModel.bookings.firstWhere(
      (b) => b.id == booking.id,
      orElse: () => booking,
    );

    if (updatedBooking.remainingBalance <= 0) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('Le solde est déjà réglé')));
      return;
    }

    double amount = 0;
    PaymentMethod method = PaymentMethod.card;
    PaymentType type = PaymentType.balance;

    showDialog(
      context: context,
      builder: (context) {
        final bookingViewModel = context.read<BookingViewModel>();
        final updatedBooking = bookingViewModel.bookings.firstWhere(
          (b) => b.id == booking.id,
          orElse: () => booking,
        );

        return AlertDialog(
          title: Row(
            children: [
              Icon(Icons.payment, color: Theme.of(context).primaryColor),
              const SizedBox(width: 8),
              const Text('Nouveau paiement'),
            ],
          ),
          content: StatefulBuilder(
            builder:
                (context, setState) => Container(
                  width: 400,
                  padding: const EdgeInsets.symmetric(vertical: 8),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      TextFormField(
                        decoration: InputDecoration(
                          labelText: 'Montant',
                          suffixText: '€',
                          border: const OutlineInputBorder(),
                          prefixIcon: const Icon(Icons.euro),
                          filled: true,
                          fillColor: Colors.grey.shade50,
                          hintText: updatedBooking.remainingBalance
                              .toStringAsFixed(2),
                        ),
                        keyboardType: const TextInputType.numberWithOptions(
                          decimal: true,
                        ),
                        inputFormatters: [
                          FilteringTextInputFormatter.allow(
                            RegExp(r'^\d+\.?\d{0,2}'),
                          ),
                        ],
                        onChanged:
                            (value) => amount = double.tryParse(value) ?? 0,
                      ),
                      const SizedBox(height: 24),
                      const Text(
                        'Mode de paiement',
                        style: TextStyle(fontWeight: FontWeight.w500),
                      ),
                      const SizedBox(height: 8),
                      Row(
                        children: [
                          Expanded(
                            child: _PaymentMethodButton(
                              icon: Icons.credit_card,
                              label: 'Carte',
                              isSelected: method == PaymentMethod.card,
                              onTap:
                                  () => setState(
                                    () => method = PaymentMethod.card,
                                  ),
                            ),
                          ),
                          const SizedBox(width: 8),
                          Expanded(
                            child: _PaymentMethodButton(
                              icon: Icons.payments,
                              label: 'Espèces',
                              isSelected: method == PaymentMethod.cash,
                              onTap:
                                  () => setState(
                                    () => method = PaymentMethod.cash,
                                  ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 24),
                      const Text(
                        'Type de paiement',
                        style: TextStyle(fontWeight: FontWeight.w500),
                      ),
                      const SizedBox(height: 8),
                      Row(
                        children: [
                          Expanded(
                            child: _PaymentMethodButton(
                              icon: Icons.front_hand,
                              label: 'Acompte',
                              isSelected: type == PaymentType.deposit,
                              onTap:
                                  () => setState(
                                    () => type = PaymentType.deposit,
                                  ),
                            ),
                          ),
                          const SizedBox(width: 8),
                          Expanded(
                            child: _PaymentMethodButton(
                              icon: Icons.check_circle,
                              label: 'Solde',
                              isSelected: type == PaymentType.balance,
                              onTap:
                                  () => setState(
                                    () => type = PaymentType.balance,
                                  ),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Annuler'),
            ),
            FilledButton.icon(
              onPressed: () {
                if (amount <= 0) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text('Le montant doit être supérieur à 0'),
                    ),
                  );
                  return;
                }

                if (amount > updatedBooking.remainingBalance) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text(
                        'Le montant ne peut pas dépasser le solde restant',
                      ),
                    ),
                  );
                  return;
                }

                final bookingViewModel = context.read<BookingViewModel>();
                bookingViewModel.addPayment(
                  bookingId: booking.id,
                  amount: amount,
                  method: method,
                  type: type,
                );

                Navigator.pop(context);
              },
              icon: const Icon(Icons.save),
              label: const Text('Enregistrer'),
            ),
          ],
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
              TextButton(
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
                style: TextButton.styleFrom(foregroundColor: Colors.red),
                child: const Text('Supprimer'),
              ),
            ],
          ),
    );
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
    return Material(
      color:
          isSelected
              ? theme.primaryColor.withOpacity(0.1)
              : Colors.grey.shade50,
      borderRadius: BorderRadius.circular(8),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(8),
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 16),
          decoration: BoxDecoration(
            border: Border.all(
              color: isSelected ? theme.primaryColor : Colors.grey.shade300,
              width: 2,
            ),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Column(
            children: [
              Icon(
                icon,
                color: isSelected ? theme.primaryColor : Colors.grey.shade700,
                size: 28,
              ),
              const SizedBox(height: 4),
              Text(
                label,
                style: TextStyle(
                  color: isSelected ? theme.primaryColor : Colors.grey.shade700,
                  fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
