import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../../models/booking_model.dart';
import '../../models/payment_model.dart';

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

class _PaymentTypeButton extends StatelessWidget {
  final PaymentType type;
  final bool isSelected;
  final VoidCallback onTap;

  const _PaymentTypeButton({
    required this.type,
    required this.isSelected,
    required this.onTap,
  });

  String get _label {
    switch (type) {
      case PaymentType.deposit:
        return 'Acompte';
      case PaymentType.balance:
        return 'Solde';
    }
  }

  IconData get _icon {
    switch (type) {
      case PaymentType.deposit:
        return Icons.percent;
      case PaymentType.balance:
        return Icons.paid;
    }
  }

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
              _icon,
              color: isSelected ? theme.primaryColor : Colors.grey.shade700,
              size: 24,
            ),
            const SizedBox(height: 4),
            Text(
              _label,
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

class AddPaymentDialog extends StatefulWidget {
  final Booking booking;
  final Payment initialPayment;

  const AddPaymentDialog({
    super.key,
    required this.booking,
    required this.initialPayment,
  });

  @override
  State<AddPaymentDialog> createState() => _AddPaymentDialogState();
}

class _AddPaymentDialogState extends State<AddPaymentDialog> {
  late Payment _payment;
  final _dateFormatter = DateFormat('dd/MM/yyyy');

  @override
  void initState() {
    super.initState();
    _payment = widget.initialPayment;
  }

  Future<void> _selectDate(BuildContext context) async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: _payment.date,
      firstDate: DateTime(2020),
      lastDate: DateTime(2030),
      locale: const Locale('fr', 'FR'),
    );

    if (picked != null && picked != _payment.date && mounted) {
      setState(() {
        _payment = _payment.copyWith(date: picked);
      });
    }
  }

  Widget _buildDatePicker(BuildContext context) {
    if (_payment.type != PaymentType.deposit) {
      return const SizedBox.shrink();
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const SizedBox(height: 24),
        Text(
          'Date du paiement',
          style: Theme.of(context).textTheme.titleMedium,
        ),
        const SizedBox(height: 8),
        InkWell(
          onTap: () => _selectDate(context),
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 16),
            decoration: BoxDecoration(
              border: Border.all(color: Theme.of(context).colorScheme.outline),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Row(
              children: [
                Icon(
                  Icons.calendar_today,
                  size: 20,
                  color: Theme.of(context).colorScheme.onSurfaceVariant,
                ),
                const SizedBox(width: 8),
                Text(
                  _dateFormatter.format(_payment.date),
                  style: Theme.of(context).textTheme.bodyLarge,
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.only(
        top: 16,
        left: 16,
        right: 16,
        bottom: MediaQuery.of(context).viewInsets.bottom + 32,
      ),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surface,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(16)),
      ),
      child: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'Nouveau paiement',
                  style: Theme.of(context).textTheme.titleLarge,
                ),
                IconButton(
                  icon: const Icon(Icons.close),
                  onPressed: () => Navigator.of(context).pop(),
                ),
              ],
            ),
            const SizedBox(height: 24),
            Row(
              children: [
                Expanded(
                  child: _PaymentTypeButton(
                    type: PaymentType.deposit,
                    isSelected: _payment.type == PaymentType.deposit,
                    onTap: () {
                      setState(() {
                        _payment = _payment.copyWith(type: PaymentType.deposit);
                      });
                    },
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: _PaymentTypeButton(
                    type: PaymentType.balance,
                    isSelected: _payment.type == PaymentType.balance,
                    onTap: () {
                      setState(() {
                        _payment = _payment.copyWith(
                          type: PaymentType.balance,
                          date: DateTime.now(),
                        );
                      });
                    },
                  ),
                ),
              ],
            ),
            const SizedBox(height: 24),
            TextFormField(
              initialValue: _payment.amount.toStringAsFixed(2),
              decoration: InputDecoration(
                labelText: 'Montant',
                suffixText: '€',
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
              ),
              keyboardType: const TextInputType.numberWithOptions(
                decimal: true,
              ),
              onChanged: (value) {
                setState(() {
                  _payment = _payment.copyWith(
                    amount: double.tryParse(value) ?? _payment.amount,
                  );
                });
              },
            ),
            _buildDatePicker(context),
            const SizedBox(height: 24),
            Text(
              'Moyen de paiement',
              style: Theme.of(context).textTheme.titleMedium,
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(
                  child: _PaymentMethodButton(
                    icon: Icons.credit_card,
                    label: 'CB',
                    isSelected: _payment.method == PaymentMethod.card,
                    onTap: () {
                      setState(() {
                        _payment = _payment.copyWith(
                          method: PaymentMethod.card,
                        );
                      });
                    },
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: _PaymentMethodButton(
                    icon: Icons.euro,
                    label: 'Espèces',
                    isSelected: _payment.method == PaymentMethod.cash,
                    onTap: () {
                      setState(() {
                        _payment = _payment.copyWith(
                          method: PaymentMethod.cash,
                        );
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
            const SizedBox(height: 32),
            OutlinedButton.icon(
              onPressed: () => Navigator.of(context).pop(_payment),
              icon: const Icon(Icons.check),
              label: const Text('Ajouter le paiement'),
              style: OutlinedButton.styleFrom(
                minimumSize: const Size(double.infinity, 48),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
