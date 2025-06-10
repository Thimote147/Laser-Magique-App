import 'package:flutter/material.dart';
import '../../models/stock_item_model.dart';
import '../../viewmodels/stock_view_model.dart';
import 'quantity_controls.dart';

class ConsumptionSelector extends StatefulWidget {
  final StockViewModel stockVM;
  final Function(String stockItemId, int quantity) onConsumptionSelected;

  const ConsumptionSelector({
    Key? key,
    required this.stockVM,
    required this.onConsumptionSelected,
  }) : super(key: key);

  @override
  ConsumptionSelectorState createState() => ConsumptionSelectorState();
}

class ConsumptionSelectorState extends State<ConsumptionSelector>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  String? selectedItemId;
  int quantity = 1;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
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
        return Icons.inventory;
    }
  }

  @override
  Widget build(BuildContext context) {
    return DraggableScrollableSheet(
      initialChildSize: 0.7,
      minChildSize: 0.5,
      maxChildSize: 0.95,
      builder:
          (_, scrollController) => Container(
            decoration: const BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
            ),
            child: Column(
              children: [
                // Poignée de glissement
                Container(
                  margin: const EdgeInsets.only(top: 8),
                  width: 40,
                  height: 4,
                  decoration: BoxDecoration(
                    color: Colors.grey.shade300,
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),

                // En-tête
                Padding(
                  padding: const EdgeInsets.all(16),
                  child: Row(
                    children: [
                      Text(
                        'Ajouter une consommation',
                        style: Theme.of(context).textTheme.titleLarge,
                      ),
                      const Spacer(),
                      IconButton(
                        icon: const Icon(Icons.close),
                        onPressed: () => Navigator.pop(context),
                      ),
                    ],
                  ),
                ),

                // TabBar
                TabBar(
                  controller: _tabController,
                  labelColor: Theme.of(context).primaryColor,
                  tabs: [
                    Tab(
                      icon: const Icon(Icons.local_bar),
                      text: 'Boissons (${widget.stockVM.drinks.length})',
                    ),
                    Tab(
                      icon: const Icon(Icons.restaurant),
                      text: 'Nourriture (${widget.stockVM.food.length})',
                    ),
                    Tab(
                      icon: const Icon(Icons.category),
                      text: 'Autres (${widget.stockVM.others.length})',
                    ),
                  ],
                ),

                // TabBarView
                Expanded(
                  child: TabBarView(
                    controller: _tabController,
                    children: [
                      _buildProductGrid(widget.stockVM.drinks),
                      _buildProductGrid(widget.stockVM.food),
                      _buildProductGrid(widget.stockVM.others),
                    ],
                  ),
                ),

                // Barre d'actions avec la sélection de quantité
                if (selectedItemId != null)
                  Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withOpacity(0.1),
                          blurRadius: 8,
                          offset: const Offset(0, -2),
                        ),
                      ],
                    ),
                    child: Row(
                      children: [
                        // Contrôles de quantité
                        QuantityControls(
                          quantity: quantity,
                          onChanged:
                              (value) => setState(() => quantity = value),
                          usePrimaryColor: true,
                          iconSize: 28,
                          fontSize: 20,
                          containerWidth: 48,
                          padding: const EdgeInsets.all(8),
                        ),
                        const Spacer(),
                        // Bouton d'ajout
                        FilledButton.icon(
                          onPressed: () {
                            widget.onConsumptionSelected(
                              selectedItemId!,
                              quantity,
                            );
                            Navigator.pop(context);
                          },
                          icon: const Icon(Icons.check),
                          label: const Text('Ajouter'),
                        ),
                      ],
                    ),
                  ),
              ],
            ),
          ),
    );
  }

  Widget _buildProductGrid(List<StockItem> items) {
    if (items.isEmpty) {
      return const Center(
        child: Text(
          'Aucun produit disponible',
          style: TextStyle(fontStyle: FontStyle.italic),
        ),
      );
    }

    return GridView.builder(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 4,
        childAspectRatio: 0.75,
        crossAxisSpacing: 6,
        mainAxisSpacing: 6,
      ),
      itemCount: items.length,
      itemBuilder: (context, index) {
        final item = items[index];
        final isSelected = item.id == selectedItemId;

        return Material(
          color:
              isSelected
                  ? Theme.of(context).primaryColor.withOpacity(0.1)
                  : Colors.grey.shade50,
          borderRadius: BorderRadius.circular(8),
          child: InkWell(
            onTap:
                item.quantity > 0
                    ? () => setState(() {
                      selectedItemId = item.id;
                      quantity = 1;
                    })
                    : null,
            borderRadius: BorderRadius.circular(8),
            child: Container(
              padding: const EdgeInsets.all(6),
              decoration: BoxDecoration(
                border: Border.all(
                  color:
                      isSelected
                          ? Theme.of(context).primaryColor
                          : Colors.grey.shade300,
                  width: 1.5,
                ),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    _getItemIcon(item.category),
                    size: 24,
                    color:
                        isSelected
                            ? Theme.of(context).primaryColor
                            : Colors.grey.shade700,
                  ),
                  const SizedBox(height: 4),
                  Text(
                    item.name,
                    textAlign: TextAlign.center,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      fontSize: 13,
                      fontWeight:
                          isSelected ? FontWeight.bold : FontWeight.normal,
                      color:
                          isSelected
                              ? Theme.of(context).primaryColor
                              : Colors.black,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    '${item.price.toStringAsFixed(2)}€',
                    style: TextStyle(
                      fontSize: 12,
                      color:
                          isSelected
                              ? Theme.of(context).primaryColor
                              : Colors.grey.shade700,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    'Stock: ${item.quantity}',
                    style: TextStyle(
                      fontSize: 11,
                      color:
                          item.quantity > 0
                              ? (isSelected
                                  ? Theme.of(context).primaryColor
                                  : Colors.grey.shade700)
                              : Colors.red,
                    ),
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }
}
