import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../models/cash_movement_model.dart';

class CashMovementDialog extends StatefulWidget {
  final Function(CashMovement) onSubmit;

  const CashMovementDialog({
    super.key,
    required this.onSubmit,
  });

  @override
  State<CashMovementDialog> createState() => _CashMovementDialogState();

  static Future<void> show(
    BuildContext context, {
    required Function(CashMovement) onSubmit,
  }) {
    return showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      useSafeArea: true,
      backgroundColor: Colors.transparent,
      isDismissible: true,
      enableDrag: true,
      useRootNavigator: true,
      builder: (context) => CashMovementDialog(onSubmit: onSubmit),
    );
  }
}

class _CashMovementDialogState extends State<CashMovementDialog> {
  final _formKey = GlobalKey<FormState>();
  final _amountController = TextEditingController();
  final _justificationController = TextEditingController();
  final _detailsController = TextEditingController();

  CashMovementType _selectedType = CashMovementType.entry;

  @override
  void dispose() {
    _amountController.dispose();
    _justificationController.dispose();
    _detailsController.dispose();
    super.dispose();
  }

  void _submitMovement() {
    if (_formKey.currentState!.validate()) {
      final amount = double.tryParse(_amountController.text.replaceAll(',', '.')) ?? 0.0;
      
      final movement = CashMovement(
        id: DateTime.now().millisecondsSinceEpoch.toString(),
        date: DateTime.now(),
        type: _selectedType,
        amount: amount,
        justification: _justificationController.text.trim(),
        details: _detailsController.text.trim().isEmpty ? null : _detailsController.text.trim(),
        createdAt: DateTime.now(),
        createdBy: 'current_user', // Sera remplacé par l'ID utilisateur réel dans le repository
      );

      widget.onSubmit(movement);
      Navigator.of(context).pop();
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Container(
      decoration: BoxDecoration(
        color: theme.colorScheme.surface,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(28)),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Drag handle
          Container(
            margin: const EdgeInsets.symmetric(vertical: 8),
            width: 40,
            height: 4,
            decoration: BoxDecoration(
              color: theme.colorScheme.onSurfaceVariant.withValues(alpha: 0.4),
              borderRadius: BorderRadius.circular(2),
            ),
          ),
          // Header
          Container(
            width: double.infinity,
            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'Mouvement de caisse',
                  style: theme.textTheme.titleLarge?.copyWith(
                    fontWeight: FontWeight.w600,
                  ),
                ),
                IconButton(
                  icon: const Icon(Icons.close),
                  onPressed: () => Navigator.of(context).pop(),
                  tooltip: 'Fermer',
                ),
              ],
            ),
          ),
          // Form content
          SingleChildScrollView(
            padding: EdgeInsets.fromLTRB(
              16,
              0,
              16,
              MediaQuery.of(context).viewInsets.bottom + 16,
            ),
            child: Form(
              key: _formKey,
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const SizedBox(height: 8),
                  _buildSection(
                    title: 'Type de mouvement',
                    icon: Icons.compare_arrows,
                    children: [
                      _buildMovementTypeSelector(theme),
                    ],
                  ),
                  const SizedBox(height: 24),
                  _buildSection(
                    title: 'Informations',
                    icon: Icons.receipt_long,
                    children: [
                      _buildTextField(
                        controller: _amountController,
                        label: 'Montant *',
                        suffix: '€',
                        keyboardType: const TextInputType.numberWithOptions(decimal: true),
                        inputFormatters: [
                          FilteringTextInputFormatter.allow(RegExp(r'^\d*[,.]?\d{0,2}')),
                        ],
                        validator: (value) {
                          if (value == null || value.isEmpty) {
                            return 'Le montant est requis';
                          }
                          final amount = double.tryParse(value.replaceAll(',', '.'));
                          if (amount == null || amount <= 0) {
                            return 'Le montant doit être supérieur à 0';
                          }
                          return null;
                        },
                      ),
                      _buildTextField(
                        controller: _justificationController,
                        label: 'Justification *',
                        helperText: 'Ex: Achat fournitures, Réparation matériel...',
                        maxLines: 2,
                        validator: (value) {
                          if (value == null || value.trim().isEmpty) {
                            return 'La justification est requise';
                          }
                          if (value.trim().length < 5) {
                            return 'La justification doit contenir au moins 5 caractères';
                          }
                          return null;
                        },
                      ),
                      _buildTextField(
                        controller: _detailsController,
                        label: 'Détails supplémentaires (optionnel)',
                        helperText: 'Informations complémentaires...',
                        maxLines: 3,
                      ),
                    ],
                  ),
                  const SizedBox(height: 32),
                  // Bouton d'action
                  FilledButton.icon(
                    onPressed: _submitMovement,
                    icon: const Icon(Icons.check),
                    label: const Text('Enregistrer'),
                    style: FilledButton.styleFrom(
                      minimumSize: const Size(double.infinity, 48),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSection({
    required String title,
    required IconData icon,
    required List<Widget> children,
  }) {
    final theme = Theme.of(context);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.only(left: 4, bottom: 8),
          child: Row(
            children: [
              Icon(icon, size: 20, color: theme.colorScheme.primary),
              const SizedBox(width: 8),
              Text(
                title,
                style: theme.textTheme.titleMedium?.copyWith(
                  color: theme.colorScheme.onSurface,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
        ),
        Card(
          elevation: 0,
          margin: EdgeInsets.zero,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
            side: BorderSide(color: theme.colorScheme.outline.withAlpha((255 * 0.25).round())),
          ),
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                ...children
                    .expand(
                      (child) => [
                        child,
                        if (child != children.last) const SizedBox(height: 12),
                      ],
                    ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildTextField({
    required TextEditingController controller,
    required String label,
    String? suffix,
    String? helperText,
    TextInputType? keyboardType,
    List<TextInputFormatter>? inputFormatters,
    int maxLines = 1,
    String? Function(String?)? validator,
  }) {
    final theme = Theme.of(context);
    return Container(
      decoration: BoxDecoration(
        color: theme.colorScheme.surfaceContainerHighest.withAlpha((255 * 0.3).round()),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          Padding(
            padding: const EdgeInsets.only(left: 12, right: 12, top: 8),
            child: Text(
              label,
              style: theme.textTheme.bodySmall?.copyWith(
                color: theme.colorScheme.onSurfaceVariant,
              ),
            ),
          ),
          TextFormField(
            controller: controller,
            keyboardType: keyboardType,
            inputFormatters: inputFormatters,
            maxLines: maxLines,
            style: theme.textTheme.titleMedium?.copyWith(
              fontWeight: FontWeight.w500,
            ),
            decoration: InputDecoration(
              isDense: true,
              contentPadding: const EdgeInsets.fromLTRB(12, 4, 12, 8),
              suffixText: suffix,
              helperText: helperText,
              helperStyle: theme.textTheme.bodySmall?.copyWith(
                color: theme.colorScheme.onSurfaceVariant,
              ),
              helperMaxLines: 2,
              border: InputBorder.none,
              focusedBorder: InputBorder.none,
              enabledBorder: InputBorder.none,
              errorBorder: InputBorder.none,
              disabledBorder: InputBorder.none,
            ),
            validator: validator,
          ),
        ],
      ),
    );
  }

  Widget _buildMovementTypeSelector(ThemeData theme) {
    return Container(
      decoration: BoxDecoration(
        color: theme.colorScheme.surfaceContainerHighest.withAlpha((255 * 0.3).round()),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.only(left: 12, right: 12, top: 8),
            child: Text(
              'Type',
              style: theme.textTheme.bodySmall?.copyWith(
                color: theme.colorScheme.onSurfaceVariant,
              ),
            ),
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(8, 0, 8, 8),
            child: Row(
              children: [
                Expanded(
                  child: _buildTypeOption(
                    theme,
                    icon: Icons.arrow_upward,
                    label: 'Entrée',
                    isSelected: _selectedType == CashMovementType.entry,
                    color: Colors.green,
                    onTap: () => setState(() => _selectedType = CashMovementType.entry),
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: _buildTypeOption(
                    theme,
                    icon: Icons.arrow_downward,
                    label: 'Sortie',
                    isSelected: _selectedType == CashMovementType.exit,
                    color: Colors.red,
                    onTap: () => setState(() => _selectedType = CashMovementType.exit),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTypeOption(
    ThemeData theme, {
    required IconData icon,
    required String label,
    required bool isSelected,
    required Color color,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 16),
        decoration: BoxDecoration(
          color: isSelected ? color.withAlpha((255 * 0.1).round()) : Colors.transparent,
          borderRadius: BorderRadius.circular(8),
          border: Border.all(
            color: isSelected ? color : theme.colorScheme.outline.withAlpha((255 * 0.3).round()),
            width: isSelected ? 2 : 1,
          ),
        ),
        child: Column(
          children: [
            Icon(
              icon,
              color: isSelected ? color : theme.colorScheme.onSurfaceVariant,
              size: 24,
            ),
            const SizedBox(height: 4),
            Text(
              label,
              style: theme.textTheme.bodySmall?.copyWith(
                color: isSelected ? color : theme.colorScheme.onSurfaceVariant,
                fontWeight: isSelected ? FontWeight.w600 : FontWeight.w500,
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }
}