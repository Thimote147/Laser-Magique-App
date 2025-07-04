import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../models/stock_item_model.dart';
import '../../viewmodels/stock_view_model.dart';

class StockList extends StatefulWidget {
  final List<StockItem> items;
  final bool showActivateButton;
  final void Function(int index, int newQuantity) onQuantityChanged;

  const StockList({
    super.key,
    required this.items,
    required this.onQuantityChanged,
    this.showActivateButton = false,
  });

  @override
  State<StockList> createState() => _StockListState();
}

class _StockListState extends State<StockList> {
  bool _showLowStockOnly = false;
  int _editingQuantity = 0;
  late final TextEditingController nameController;
  late final TextEditingController priceController;
  late final TextEditingController thresholdController;
  late final StockViewModel viewModel;

  @override
  void initState() {
    super.initState();
    nameController = TextEditingController();
    priceController = TextEditingController();
    thresholdController = TextEditingController();
    viewModel = Provider.of<StockViewModel>(context, listen: false);
  }

  @override
  void dispose() {
    nameController.dispose();
    priceController.dispose();
    thresholdController.dispose();
    super.dispose();
  }

  IconData _getItemIcon(String category) {
    switch (category) {
      case 'DRINK':
        return Icons.local_bar;
      case 'FOOD':
        return Icons.restaurant;
      case 'OTHER':
        return Icons.category;
      default:
        return Icons.category;
    }
  }

  void _updateQuantity(
    int delta,
    StockItem stockItem, [
    StateSetter? updateModalState,
  ]) {
    // Calculer la nouvelle quantité
    int newQuantity = _editingQuantity + delta;
    if (newQuantity < 0) newQuantity = 0;

    // Mettre à jour directement l'élément dans widget.items pour une mise à jour immédiate de l'UI
    final index = widget.items.indexWhere((item) => item.id == stockItem.id);
    if (index != -1) {
      // Créer une version mise à jour de l'élément
      final updatedItem = stockItem.copyWith(quantity: newQuantity);

      // Mettre à jour l'état local et forcer un rebuild
      setState(() {
        _editingQuantity = newQuantity;

        // Modifier l'élément pour que l'UI soit mise à jour immédiatement
        // Cette ligne est cruciale pour que l'affichage se mette à jour sans fermer la modale
        widget.items[index] = updatedItem;
      });

      // Si on a une fonction pour mettre à jour le modal, l'appeler
      if (updateModalState != null) {
        updateModalState(() {
          _editingQuantity = newQuantity;
        });
      }

      // Notifier le parent pour qu'il mette à jour la base de données
      // On passe l'index et la nouvelle quantité, le parent créera un nouvel objet avec copyWith
      widget.onQuantityChanged(index, newQuantity);
    }
  }

  Widget _buildFilterBar(BuildContext context) {
    final theme = Theme.of(context);
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 0),
      child: Material(
        color: theme.colorScheme.errorContainer.withOpacity(0.1),
        borderRadius: BorderRadius.circular(12),
        child: InkWell(
          onTap: () => setState(() => _showLowStockOnly = !_showLowStockOnly),
          borderRadius: BorderRadius.circular(12),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            child: Row(
              children: [
                Icon(
                  Icons.warning_amber_rounded,
                  color: theme.colorScheme.error,
                  size: 24,
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Articles en alerte de stock',
                        style: theme.textTheme.titleMedium?.copyWith(
                          color: theme.colorScheme.error,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        _showLowStockOnly
                            ? 'Afficher tous les articles'
                            : 'Filtrer les articles dont le stock est bas',
                        style: theme.textTheme.bodySmall?.copyWith(
                          color: theme.colorScheme.error.withOpacity(0.8),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 8),
                Switch(
                  value: _showLowStockOnly,
                  onChanged:
                      (value) => setState(() => _showLowStockOnly = value),
                  activeColor: theme.colorScheme.error,
                  activeTrackColor: theme.colorScheme.errorContainer,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  // Méthode pour construire les boutons de quantité
  Widget _buildQuantityButtons(
    BuildContext context,
    StockItem stockItem, [
    StateSetter? setModalState,
  ]) {
    final theme = Theme.of(context);
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        // Bouton -1
        Material(
          color: theme.colorScheme.errorContainer.withOpacity(0.3),
          borderRadius: BorderRadius.circular(16),
          child: InkWell(
            borderRadius: BorderRadius.circular(16),
            onTap: () => _updateQuantity(-1, stockItem, setModalState),
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(Icons.remove, size: 22, color: theme.colorScheme.error),
                  Text(
                    '1',
                    style: theme.textTheme.titleMedium?.copyWith(
                      color: theme.colorScheme.error,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),

        // Affichage quantité actuelle
        Container(
          margin: const EdgeInsets.symmetric(horizontal: 12),
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(16),
            color: theme.colorScheme.primaryContainer.withOpacity(0.3),
          ),
          child: Text(
            '$_editingQuantity',
            style: theme.textTheme.titleLarge?.copyWith(
              fontWeight: FontWeight.bold,
              color: theme.colorScheme.primary,
            ),
          ),
        ),

        // Bouton +1
        Material(
          color: theme.colorScheme.primary.withOpacity(0.1),
          borderRadius: BorderRadius.circular(16),
          child: InkWell(
            borderRadius: BorderRadius.circular(16),
            onTap: () => _updateQuantity(1, stockItem, setModalState),
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(Icons.add, size: 22, color: theme.colorScheme.primary),
                  Text(
                    '1',
                    style: theme.textTheme.titleMedium?.copyWith(
                      color: theme.colorScheme.primary,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),

        const SizedBox(width: 8),

        // Bouton +24
        Material(
          color: theme.colorScheme.primary.withOpacity(0.15),
          borderRadius: BorderRadius.circular(16),
          child: InkWell(
            borderRadius: BorderRadius.circular(16),
            onTap: () => _updateQuantity(24, stockItem, setModalState),
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(Icons.add, size: 22, color: theme.colorScheme.primary),
                  Text(
                    '24',
                    style: theme.textTheme.titleMedium?.copyWith(
                      color: theme.colorScheme.primary,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ],
    );
  }

  void _showEditModal(StockItem stockItem) {
    _editingQuantity = stockItem.quantity;

    // Initialiser les contrôleurs avec les valeurs actuelles
    nameController.text = stockItem.name;
    priceController.text = stockItem.price.toStringAsFixed(2);
    thresholdController.text = stockItem.alertThreshold.toString();

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) {
        // Utiliser StatefulBuilder pour permettre la mise à jour de l'interface dans le modal
        return StatefulBuilder(
          builder: (context, setModalState) {
            final theme = Theme.of(context);
            return Container(
              decoration: BoxDecoration(
                color: theme.colorScheme.surface,
                borderRadius: const BorderRadius.only(
                  topLeft: Radius.circular(24),
                  topRight: Radius.circular(24),
                ),
              ),
              child: SafeArea(
                child: Padding(
                  padding: EdgeInsets.only(
                    bottom: MediaQuery.of(context).viewInsets.bottom + 16,
                    top: 16,
                    left: 16,
                    right: 16,
                  ),
                  child: SingleChildScrollView(
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        // Header with handle
                        Center(
                          child: Container(
                            width: 36,
                            height: 4,
                            decoration: BoxDecoration(
                              color: theme.colorScheme.onSurface.withOpacity(
                                0.2,
                              ),
                              borderRadius: BorderRadius.circular(2),
                            ),
                          ),
                        ),
                        const SizedBox(height: 16),

                        // Title bar
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Expanded(
                              child: Row(
                                children: [
                                  Icon(
                                    _getItemIcon(stockItem.category),
                                    size: 24,
                                    color: theme.colorScheme.primary,
                                  ),
                                  const SizedBox(width: 12),
                                  Expanded(
                                    child: Text(
                                      stockItem.name,
                                      style: theme.textTheme.titleLarge
                                          ?.copyWith(
                                            fontWeight: FontWeight.bold,
                                          ),
                                      overflow: TextOverflow.ellipsis,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            IconButton(
                              icon: Icon(
                                Icons.close,
                                color: theme.colorScheme.onSurface.withOpacity(
                                  0.7,
                                ),
                              ),
                              onPressed: () => Navigator.pop(context),
                            ),
                          ],
                        ),
                        const SizedBox(height: 8),

                        // Item details
                        Padding(
                          padding: const EdgeInsets.only(left: 4),
                          child: Text(
                            'Modification article',
                            style: theme.textTheme.bodyMedium?.copyWith(
                              color: theme.colorScheme.outline,
                            ),
                          ),
                        ),
                        const SizedBox(height: 24),

                        // Section Informations Article
                        Padding(
                          padding: const EdgeInsets.only(left: 4, bottom: 8),
                          child: Row(
                            children: [
                              Icon(
                                Icons.info_outline_rounded,
                                size: 20,
                                color: theme.colorScheme.primary,
                              ),
                              const SizedBox(width: 8),
                              Text(
                                'Informations article',
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
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                            side: BorderSide(
                              color: theme.colorScheme.outline.withOpacity(0.2),
                            ),
                          ),
                          child: Container(
                            width: double.infinity,
                            padding: const EdgeInsets.all(12),
                            child: Column(
                              children: [
                                // Nom de l'article
                                Container(
                                  width: double.infinity,
                                  decoration: BoxDecoration(
                                    color: theme.colorScheme.surfaceVariant
                                        .withOpacity(0.3),
                                    borderRadius: BorderRadius.circular(8),
                                  ),
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 16,
                                    vertical: 12,
                                  ),
                                  child: Row(
                                    children: [
                                      Icon(
                                        Icons.label_outlined,
                                        size: 20,
                                        color: theme.colorScheme.primary,
                                      ),
                                      const SizedBox(width: 12),
                                      Expanded(
                                        child: Column(
                                          crossAxisAlignment:
                                              CrossAxisAlignment.start,
                                          children: [
                                            Text(
                                              'Nom de l\'article',
                                              style: theme.textTheme.bodySmall
                                                  ?.copyWith(
                                                    color:
                                                        theme
                                                            .colorScheme
                                                            .onSurfaceVariant,
                                                  ),
                                            ),
                                            TextFormField(
                                              controller: nameController,
                                              style: theme.textTheme.titleMedium
                                                  ?.copyWith(
                                                    fontWeight: FontWeight.w500,
                                                  ),
                                              decoration: InputDecoration(
                                                isDense: true,
                                                contentPadding:
                                                    const EdgeInsets.symmetric(
                                                      vertical: 4,
                                                    ),
                                                border: InputBorder.none,
                                                focusedBorder: InputBorder.none,
                                                enabledBorder: InputBorder.none,
                                                errorBorder: InputBorder.none,
                                                disabledBorder:
                                                    InputBorder.none,
                                              ),
                                            ),
                                          ],
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                                const SizedBox(height: 8),
                                // Prix unitaire
                                Container(
                                  width: double.infinity,
                                  decoration: BoxDecoration(
                                    color: theme.colorScheme.surfaceVariant
                                        .withOpacity(0.3),
                                    borderRadius: BorderRadius.circular(8),
                                  ),
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 16,
                                    vertical: 12,
                                  ),
                                  child: Row(
                                    children: [
                                      Icon(
                                        Icons.euro_rounded,
                                        size: 20,
                                        color: theme.colorScheme.primary,
                                      ),
                                      const SizedBox(width: 12),
                                      Expanded(
                                        child: Column(
                                          crossAxisAlignment:
                                              CrossAxisAlignment.start,
                                          children: [
                                            Text(
                                              'Prix unitaire',
                                              style: theme.textTheme.bodySmall
                                                  ?.copyWith(
                                                    color:
                                                        theme
                                                            .colorScheme
                                                            .onSurfaceVariant,
                                                  ),
                                            ),
                                            TextFormField(
                                              controller: priceController,
                                              style: theme.textTheme.titleMedium
                                                  ?.copyWith(
                                                    fontWeight: FontWeight.w500,
                                                  ),
                                              decoration: InputDecoration(
                                                isDense: true,
                                                contentPadding:
                                                    const EdgeInsets.symmetric(
                                                      vertical: 4,
                                                    ),
                                                suffixText: '€ ',
                                                suffixStyle: theme
                                                    .textTheme
                                                    .titleMedium
                                                    ?.copyWith(
                                                      fontWeight:
                                                          FontWeight.w500,
                                                    ),
                                                border: InputBorder.none,
                                                focusedBorder: InputBorder.none,
                                                enabledBorder: InputBorder.none,
                                                errorBorder: InputBorder.none,
                                                disabledBorder:
                                                    InputBorder.none,
                                              ),
                                              keyboardType:
                                                  const TextInputType.numberWithOptions(
                                                    decimal: true,
                                                  ),
                                            ),
                                          ],
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                        const SizedBox(height: 16),

                        // Section Gestion du Stock
                        Padding(
                          padding: const EdgeInsets.only(left: 4, bottom: 8),
                          child: Row(
                            children: [
                              Icon(
                                Icons.inventory_2_outlined,
                                size: 20,
                                color: theme.colorScheme.primary,
                              ),
                              const SizedBox(width: 8),
                              Text(
                                'Gestion du stock',
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
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                            side: BorderSide(
                              color: theme.colorScheme.outline.withOpacity(0.2),
                            ),
                          ),
                          child: Container(
                            width: double.infinity,
                            padding: const EdgeInsets.all(12),
                            child: Column(
                              children: [
                                // Seuil d'alerte
                                Container(
                                  width: double.infinity,
                                  decoration: BoxDecoration(
                                    color: theme.colorScheme.surfaceVariant
                                        .withOpacity(0.3),
                                    borderRadius: BorderRadius.circular(8),
                                  ),
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 16,
                                    vertical: 12,
                                  ),
                                  child: Row(
                                    children: [
                                      Icon(
                                        Icons.notifications_outlined,
                                        size: 20,
                                        color: theme.colorScheme.primary,
                                      ),
                                      const SizedBox(width: 12),
                                      Expanded(
                                        child: Column(
                                          crossAxisAlignment:
                                              CrossAxisAlignment.start,
                                          children: [
                                            Text(
                                              'Seuil d\'alerte',
                                              style: theme.textTheme.bodySmall
                                                  ?.copyWith(
                                                    color:
                                                        theme
                                                            .colorScheme
                                                            .onSurfaceVariant,
                                                  ),
                                            ),
                                            TextFormField(
                                              controller: thresholdController,
                                              style: theme.textTheme.titleMedium
                                                  ?.copyWith(
                                                    fontWeight: FontWeight.w500,
                                                  ),
                                              decoration: InputDecoration(
                                                isDense: true,
                                                contentPadding:
                                                    const EdgeInsets.symmetric(
                                                      vertical: 4,
                                                    ),
                                                border: InputBorder.none,
                                                focusedBorder: InputBorder.none,
                                                enabledBorder: InputBorder.none,
                                                errorBorder: InputBorder.none,
                                                disabledBorder:
                                                    InputBorder.none,
                                              ),
                                              keyboardType:
                                                  TextInputType.number,
                                            ),
                                          ],
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                                const SizedBox(height: 8),
                                // Boutons de modification
                                Container(
                                  width: double.infinity,
                                  decoration: BoxDecoration(
                                    color: theme.colorScheme.surfaceVariant
                                        .withOpacity(0.3),
                                    borderRadius: BorderRadius.circular(8),
                                  ),
                                  padding: const EdgeInsets.all(16),
                                  child: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        'Modifier la quantité',
                                        style: theme.textTheme.bodySmall
                                            ?.copyWith(
                                              color:
                                                  theme
                                                      .colorScheme
                                                      .onSurfaceVariant,
                                            ),
                                      ),
                                      const SizedBox(height: 12),
                                      _buildQuantityButtons(
                                        context,
                                        stockItem,
                                        setModalState,
                                      ),
                                    ],
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),

                        const SizedBox(height: 24),

                        // Save Button
                        FilledButton(
                          style: FilledButton.styleFrom(
                            padding: const EdgeInsets.symmetric(vertical: 16),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                          ),
                          onPressed: () {
                            // Mettre à jour le stock avec les nouvelles valeurs
                            final stockVM = Provider.of<StockViewModel>(
                              context,
                              listen: false,
                            );
                            final updatedItem = stockItem.copyWith(
                              name: nameController.text,
                              price:
                                  double.tryParse(priceController.text) ??
                                  stockItem.price,
                              alertThreshold:
                                  int.tryParse(thresholdController.text) ??
                                  stockItem.alertThreshold,
                              quantity:
                                  _editingQuantity, // Utiliser la quantité mise à jour
                            );

                            stockVM.updateItem(updatedItem);
                            Navigator.pop(context);
                          },
                          child: Text(
                            'Enregistrer',
                            style: theme.textTheme.labelLarge?.copyWith(
                              fontWeight: FontWeight.bold,
                              color: theme.colorScheme.onPrimary,
                            ),
                          ),
                        ),
                        const SizedBox(height: 8),
                      ],
                    ),
                  ),
                ),
              ),
            );
          },
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final filteredItems =
        _showLowStockOnly
            ? widget.items.where((item) => item.isLowStock).toList()
            : widget.items;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        _buildFilterBar(context),
        Expanded(
          child: RefreshIndicator(
            onRefresh: () async {
              // Utiliser le ViewModel pour rafraîchir les données
              await viewModel.refreshStock();
              await viewModel.refreshAllStock();
            },
            child: ListView.builder(
              padding: const EdgeInsets.only(top: 8),
              itemCount: filteredItems.length,
              itemBuilder: (context, index) {
                final item = filteredItems[index];
                final isLowStock = item.quantity <= item.alertThreshold;
                return Padding(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 4,
                  ),
                  child: Card(
                    elevation: 0,
                    margin: EdgeInsets.zero,
                    clipBehavior: Clip.antiAlias,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                      side: BorderSide(
                        color: theme.colorScheme.outlineVariant.withAlpha(51),
                        width: 1,
                      ),
                    ),
                    child: Material(
                      color: (isLowStock
                              ? theme.colorScheme.errorContainer
                              : theme.colorScheme.surface)
                          .withAlpha(isLowStock ? 51 : 0),
                      child: ListTile(
                        onTap: () => _showEditModal(item),
                        minLeadingWidth: 24,
                        leading: Icon(
                          _getItemIcon(item.category),
                          size: 20,
                          color:
                              isLowStock
                                  ? theme.colorScheme.error
                                  : theme.colorScheme.primary,
                        ),
                        title: Text(
                          item.name,
                          style: theme.textTheme.titleMedium?.copyWith(
                            fontSize: 14,
                            color:
                                isLowStock
                                    ? theme.colorScheme.error
                                    : theme.colorScheme.onSurface,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        subtitle: Row(
                          children: [
                            if (isLowStock) ...[
                              Icon(
                                Icons.warning_amber_rounded,
                                size: 14,
                                color: theme.colorScheme.error,
                              ),
                              const SizedBox(width: 4),
                            ],
                            Text(
                              '${item.quantity} ',
                              style: theme.textTheme.bodyMedium?.copyWith(
                                color:
                                    isLowStock
                                        ? theme.colorScheme.error
                                        : theme.colorScheme.primary,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                            Text(
                              'articles • ${item.price.toStringAsFixed(2)}€',
                              style: theme.textTheme.bodyMedium?.copyWith(
                                color: theme.colorScheme.outline,
                              ),
                            ),
                          ],
                        ),
                        trailing: Icon(
                          Icons.chevron_right_rounded,
                          color: theme.colorScheme.outline,
                          size: 20,
                        ),
                        contentPadding: const EdgeInsets.symmetric(
                          horizontal: 16,
                          vertical: 8,
                        ),
                        visualDensity: VisualDensity.compact,
                      ),
                    ),
                  ),
                );
              },
            ),
          ),
        ),
      ],
    );
  }
}
