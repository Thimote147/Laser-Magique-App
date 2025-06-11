import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../../models/formula_model.dart';
import '../../../models/payment_model.dart';

class DepositSection extends StatelessWidget {
  final Formula? selectedFormula;
  final int numberOfPersons;
  final int numberOfGames;
  final double depositAmount;
  final PaymentMethod paymentMethod;
  final Function(double) onDepositChanged;
  final Function(PaymentMethod) onPaymentMethodChanged;

  const DepositSection({
    super.key,
    required this.selectedFormula,
    required this.numberOfPersons,
    required this.numberOfGames,
    required this.depositAmount,
    required this.paymentMethod,
    required this.onDepositChanged,
    required this.onPaymentMethodChanged,
  });

  double get maxAmount =>
      (selectedFormula?.price ?? 0.0) * numberOfPersons * numberOfGames;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                const Text(
                  'Acompte',
                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                ),
                const SizedBox(width: 8),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 8,
                    vertical: 4,
                  ),
                  decoration: BoxDecoration(
                    color: Colors.grey.shade100,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Text(
                    'Max: ${maxAmount.toStringAsFixed(2)}€',
                    style: TextStyle(fontSize: 12, color: Colors.grey.shade700),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            TextFormField(
              initialValue: depositAmount.toString(),
              decoration: InputDecoration(
                labelText: 'Montant de l\'acompte',
                hintText: '0,00',
                prefixIcon: Icon(Icons.euro, color: theme.primaryColor),
                border: const OutlineInputBorder(),
                suffixText: '€',
                filled: true,
                fillColor: theme.primaryColor.withOpacity(0.05),
              ),
              keyboardType: const TextInputType.numberWithOptions(
                decimal: true,
              ),
              inputFormatters: [
                FilteringTextInputFormatter.allow(RegExp(r'^\d+[,\.]?\d{0,2}')),
              ],
              onChanged: (value) {
                final amount =
                    double.tryParse(value.replaceAll(',', '.')) ?? 0.0;
                onDepositChanged(amount);
              },
              validator: (value) {
                if (value == null || value.isEmpty) return null;
                final amount = double.tryParse(value.replaceAll(',', '.'));
                if (amount == null) return 'Montant invalide';
                if (amount > maxAmount) {
                  return 'L\'acompte ne peut pas dépasser le montant total';
                }
                return null;
              },
            ),
            const SizedBox(height: 24),
            const Text(
              'Mode de paiement',
              style: TextStyle(fontSize: 14, fontWeight: FontWeight.w500),
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(
                  child: _buildPaymentMethodTile(
                    context,
                    'Carte bancaire',
                    Icons.credit_card,
                    'Payez par carte bancaire',
                    PaymentMethod.card,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: _buildPaymentMethodTile(
                    context,
                    'Espèces',
                    Icons.payments,
                    'Payez en espèces',
                    PaymentMethod.cash,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: _buildPaymentMethodTile(
                    context,
                    'Virement',
                    Icons.account_balance,
                    'Payez par virement bancaire',
                    PaymentMethod.transfer,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildPaymentMethodTile(
    BuildContext context,
    String title,
    IconData icon,
    String tooltip,
    PaymentMethod method,
  ) {
    final theme = Theme.of(context);
    final isSelected = paymentMethod == method;

    return Tooltip(
      message: tooltip,
      child: InkWell(
        onTap: () => onPaymentMethodChanged(method),
        borderRadius: BorderRadius.circular(8),
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 8),
          decoration: BoxDecoration(
            color:
                isSelected
                    ? theme.colorScheme.primary.withOpacity(0.1)
                    : Colors.transparent,
            border: Border.all(
              color:
                  isSelected
                      ? theme.colorScheme.primary
                      : theme.colorScheme.outline,
              width: 1,
            ),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                icon,
                color:
                    isSelected
                        ? theme.colorScheme.primary
                        : theme.colorScheme.onSurface,
                size: 24,
              ),
              const SizedBox(height: 8),
              Text(
                title,
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: isSelected ? FontWeight.w500 : FontWeight.normal,
                  color:
                      isSelected
                          ? theme.colorScheme.primary
                          : theme.colorScheme.onSurface,
                ),
                textAlign: TextAlign.center,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
