import 'package:flutter/material.dart';
import '../../models/stock_item_model.dart';

class StockItemModal extends StatefulWidget {
  final StockItem? item;
  final void Function(StockItem) onSave;

  const StockItemModal({super.key, this.item, required this.onSave});

  @override
  State<StockItemModal> createState() => _StockItemModalState();

  static Future<void> show(
    BuildContext context, {
    StockItem? item,
    required void Function(StockItem) onSave,
  }) {
    return showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      useSafeArea: true,
      backgroundColor: Colors.transparent,
      isDismissible: false,
      enableDrag: false,
      useRootNavigator: true,
      builder: (context) => StockItemModal(item: item, onSave: onSave),
    );
  }
}

class _StockItemModalState extends State<StockItemModal> {
  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _nameController;
  late final TextEditingController _quantityController;
  late final TextEditingController _priceController;
  late final TextEditingController _alertThresholdController;
  String _category = 'DRINK';
  bool _isAddMode = false;

  @override
  void initState() {
    super.initState();
    final item = widget.item;
    _isAddMode = item == null;
    _nameController = TextEditingController(text: item?.name ?? '');
    _quantityController = TextEditingController(
      text: item != null ? item.quantity.toString() : '',
    );
    _priceController = TextEditingController(
      text: item != null ? item.price.toString() : '',
    );
    _alertThresholdController = TextEditingController(
      text: item != null ? item.alertThreshold.toString() : '',
    );
    if (item != null) {
      _category = item.category;
    }
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    // Suppression de toute logique de synchronisation de catégorie
  }

  @override
  void dispose() {
    _nameController.dispose();
    _quantityController.dispose();
    _priceController.dispose();
    _alertThresholdController.dispose();
    super.dispose();
  }

  void _save() {
    if (_formKey.currentState?.validate() == true) {
      final item = StockItem(
        id: widget.item?.id ?? '',
        name: _nameController.text.trim(),
        quantity: int.tryParse(_quantityController.text) ?? 0,
        price: double.tryParse(_priceController.text) ?? 0.0,
        alertThreshold: int.tryParse(_alertThresholdController.text) ?? 0,
        category: _category,
      );
      widget.onSave(item);
      Navigator.pop(context);
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
          // Header
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 8),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                IconButton(
                  icon: const Icon(Icons.close),
                  onPressed: () => Navigator.pop(context),
                ),
                Text(
                  _isAddMode ? 'Nouvel article' : 'Modifier l\'article',
                  style: theme.textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.w600,
                  ),
                ),
                TextButton(
                  onPressed: _save,
                  child: Text(
                    _isAddMode ? 'Ajouter' : 'Enregistrer',
                    style: TextStyle(
                      color: theme.colorScheme.primary,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
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
                    title: 'Informations générales',
                    icon: Icons.inventory_2_outlined,
                    children: [
                      _buildTextField(
                        controller: _nameController,
                        label: 'Nom',
                        validator:
                            (v) =>
                                v == null || v.trim().isEmpty
                                    ? 'Le nom est requis'
                                    : null,
                      ),
                      _buildTextField(
                        controller: _quantityController,
                        label: 'Quantité',
                        keyboardType: TextInputType.number,
                        validator:
                            (v) =>
                                v == null || v.trim().isEmpty
                                    ? 'Quantité requise'
                                    : null,
                      ),
                      _buildTextField(
                        controller: _priceController,
                        label: 'Prix',
                        keyboardType: TextInputType.number,
                        validator:
                            (v) =>
                                v == null || v.trim().isEmpty
                                    ? 'Prix requis'
                                    : null,
                      ),
                      _buildTextField(
                        controller: _alertThresholdController,
                        label: 'Seuil d\'alerte',
                        keyboardType: TextInputType.number,
                        validator:
                            (v) =>
                                v == null || v.trim().isEmpty
                                    ? 'Seuil requis'
                                    : null,
                      ),
                      _buildCategoryDropdown(theme),
                    ],
                  ),
                  const SizedBox(height: 32),
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
    TextInputType? keyboardType,
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
            style: theme.textTheme.titleMedium?.copyWith(
              fontWeight: FontWeight.w500,
            ),
            decoration: const InputDecoration(
              isDense: true,
              contentPadding: EdgeInsets.fromLTRB(12, 4, 12, 8),
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

  Widget _buildCategoryDropdown(ThemeData theme) {
    return Container(
      decoration: BoxDecoration(
        color: theme.colorScheme.surfaceContainerHighest.withAlpha((255 * 0.3).round()),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
        child: DropdownButtonFormField<String>(
          value: _category,
          items: const [
            DropdownMenuItem(value: 'DRINK', child: Text('Boisson')),
            DropdownMenuItem(value: 'FOOD', child: Text('Nourriture')),
            DropdownMenuItem(value: 'OTHER', child: Text('Autre')),
          ],
          onChanged: (value) {
            if (value != null) {
              setState(() => _category = value);
            }
          },
          decoration: const InputDecoration(
            labelText: 'Catégorie',
            border: InputBorder.none,
            isDense: true,
            contentPadding: EdgeInsets.zero,
          ),
        ),
      ),
    );
  }
}
