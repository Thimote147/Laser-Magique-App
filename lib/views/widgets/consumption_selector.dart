import 'package:flutter/material.dart';
import '../../models/stock_item_model.dart';
import '../../viewmodels/stock_view_model.dart';

class ConsumptionSelector extends StatefulWidget {
  final StockViewModel stockVM;
  final Function(String stockItemId) onConsumptionSelected;

  const ConsumptionSelector({
    super.key,
    required this.stockVM,
    required this.onConsumptionSelected,
  });

  @override
  ConsumptionSelectorState createState() => ConsumptionSelectorState();
}

class ConsumptionSelectorState extends State<ConsumptionSelector>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  String? selectedItemId;
  bool _isTabControllerInitialized = false;
  String _searchQuery = '';
  final TextEditingController _searchController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _tabController = TabController(
      length: 3,
      vsync: this,
    ); // 3 onglets: Boissons, Nourriture, Autres

    // Sélectionner l'onglet "Boissons" par défaut (index 0)
    _tabController.index = 0;

    // Ajouter un listener pour détecter les changements d'onglet
    _tabController.addListener(() {
      if (_tabController.indexIsChanging) {
        setState(() {}); // Rafraîchir l'UI lors du changement d'onglet
      }
    });

    // Ajouter un listener pour le champ de recherche
    _searchController.addListener(() {
      setState(() {
        _searchQuery = _searchController.text;
        // Pas besoin de changer d'onglet lors d'une recherche
      });
    });

    // Marquer comme initialisé
    _isTabControllerInitialized = true;
  }

  @override
  void dispose() {
    _tabController.dispose();
    _searchController.dispose();
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

  Widget _buildItemList(List<StockItem> items) {
    if (items.isEmpty) {
      return const Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.sentiment_dissatisfied, size: 48, color: Colors.grey),
            SizedBox(height: 16),
            Text(
              'Aucun article disponible dans cette catégorie',
              style: TextStyle(
                fontSize: 16,
                fontStyle: FontStyle.italic,
                color: Colors.grey,
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      );
    }

    // Filtrer les articles en fonction de la recherche
    final filteredItems =
        _searchQuery.isEmpty
            ? items
            : items
                .where(
                  (item) => item.name.toLowerCase().contains(
                    _searchQuery.toLowerCase(),
                  ),
                )
                .toList();

    // Si la recherche ne donne aucun résultat
    if (filteredItems.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.search_off, size: 48, color: Colors.grey),
            const SizedBox(height: 16),
            Text(
              'Aucun résultat pour "$_searchQuery"',
              style: const TextStyle(
                fontSize: 16,
                fontStyle: FontStyle.italic,
                color: Colors.grey,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 8),
            ElevatedButton.icon(
              onPressed: () => _searchController.clear(),
              icon: const Icon(Icons.clear),
              label: const Text('Effacer la recherche'),
            ),
          ],
        ),
      );
    }

    // Séparer les articles en stock et hors stock
    final inStockItems =
        filteredItems.where((item) => item.quantity > 0).toList();
    final outOfStockItems =
        filteredItems.where((item) => item.quantity <= 0).toList();
    final allSortedItems = [...inStockItems, ...outOfStockItems];

    return GridView.builder(
      padding: const EdgeInsets.all(12),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 2,
        childAspectRatio: 4,
        crossAxisSpacing: 12,
        mainAxisSpacing: 12,
      ),
      itemCount: allSortedItems.length,
      itemBuilder: (context, index) {
        final item = allSortedItems[index];
        final theme = Theme.of(context);
        final isSelected = selectedItemId == item.id;
        final hasStock = item.quantity > 0;

        return InkWell(
          onTap:
              hasStock
                  ? () {
                    setState(() => selectedItemId = item.id);
                    widget.onConsumptionSelected(item.id);
                  }
                  : null,
          borderRadius: BorderRadius.circular(12),
          child: Container(
            decoration: BoxDecoration(
              color:
                  !hasStock
                      ? Colors.grey.shade100
                      : isSelected
                      ? theme.primaryColor.withOpacity(0.15)
                      : Colors.white,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(
                color:
                    !hasStock
                        ? Colors.grey.shade300
                        : isSelected
                        ? theme.primaryColor
                        : Colors.grey.shade200,
                width: isSelected ? 2 : 1,
              ),
            ),
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            child: Row(
              children: [
                Icon(
                  _getItemIcon(item.category),
                  size: 20,
                  color: hasStock ? theme.primaryColor : Colors.grey.shade400,
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        item.name,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w500,
                          color:
                              hasStock ? Colors.black87 : Colors.grey.shade500,
                          decoration:
                              hasStock ? null : TextDecoration.lineThrough,
                          decorationColor: Colors.grey.shade400,
                        ),
                      ),
                    ],
                  ),
                ),
                Text(
                  '${item.price.toStringAsFixed(2)}€',
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w500,
                    color: hasStock ? theme.primaryColor : Colors.grey.shade400,
                  ),
                ),
                if (!hasStock)
                  Container(
                    margin: const EdgeInsets.only(left: 4),
                    padding: const EdgeInsets.symmetric(
                      horizontal: 4,
                      vertical: 2,
                    ),
                    decoration: BoxDecoration(
                      color: Colors.red.shade100,
                      borderRadius: BorderRadius.circular(4),
                    ),
                    child: Text(
                      'Épuisé',
                      style: TextStyle(
                        fontSize: 10,
                        fontWeight: FontWeight.bold,
                        color: Colors.red.shade800,
                      ),
                    ),
                  ),
              ],
            ),
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    // Vérifier si des articles sont disponibles
    final hasDrinks = widget.stockVM.drinks.isNotEmpty;
    final hasFood = widget.stockVM.food.isNotEmpty;
    final hasOthers = widget.stockVM.others.isNotEmpty;
    final hasAny = hasDrinks || hasFood || hasOthers;

    // Déterminer l'onglet initial si aucun article n'est disponible dans l'onglet actuel
    if (!hasAny) {
      // Aucun article disponible dans aucune catégorie
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(
              Icons.inventory_2_outlined,
              size: 64,
              color: Colors.grey,
            ),
            const SizedBox(height: 16),
            const Text(
              'Aucun article disponible',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: Colors.grey,
              ),
            ),
            const SizedBox(height: 8),
            ElevatedButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Fermer'),
            ),
          ],
        ),
      );
    }

    // Sélectionner automatiquement le premier onglet avec des articles si l'onglet actuel est vide
    if (_isTabControllerInitialized) {
      // Vérifier les onglets spécifiques
      if (!hasDrinks && _tabController.index == 0) {
        if (hasFood) {
          _tabController.index = 1;
        } else if (hasOthers) {
          _tabController.index = 2;
        }
      } else if (!hasFood && _tabController.index == 1) {
        if (hasDrinks) {
          _tabController.index = 0;
        } else if (hasOthers) {
          _tabController.index = 2;
        }
      } else if (!hasOthers && _tabController.index == 2) {
        if (hasDrinks) {
          _tabController.index = 0;
        } else if (hasFood) {
          _tabController.index = 1;
        }
      }
    }
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
                Container(
                  margin: const EdgeInsets.only(top: 8),
                  width: 40,
                  height: 4,
                  decoration: BoxDecoration(
                    color: Colors.grey.shade300,
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
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
                // Champ de recherche
                Padding(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 8,
                  ),
                  child: TextField(
                    controller: _searchController,
                    decoration: InputDecoration(
                      hintText: 'Rechercher dans toutes les catégories...',
                      prefixIcon: Icon(
                        Icons.search,
                        color: Theme.of(context).primaryColor,
                      ),
                      suffixIcon:
                          _searchQuery.isNotEmpty
                              ? IconButton(
                                icon: Icon(
                                  Icons.clear,
                                  color: Theme.of(context).primaryColor,
                                ),
                                onPressed: () {
                                  _searchController.clear();
                                  setState(() {
                                    _searchQuery = '';
                                  });
                                },
                              )
                              : null,
                      filled: true,
                      fillColor: Colors.grey.shade50,
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: BorderSide(color: Colors.grey.shade300),
                      ),
                      focusedBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: BorderSide(
                          color: Theme.of(context).primaryColor,
                          width: 2,
                        ),
                      ),
                      contentPadding: const EdgeInsets.symmetric(
                        vertical: 14,
                        horizontal: 16,
                      ),
                    ),
                    textInputAction: TextInputAction.search,
                    onChanged: (value) {
                      setState(() {
                        _searchQuery = value;
                      });
                    },
                  ),
                ),
                TabBar(
                  controller: _tabController,
                  labelColor: Theme.of(context).primaryColor,
                  unselectedLabelColor: Colors.grey.shade700,
                  indicatorColor: Theme.of(context).primaryColor,
                  indicatorWeight: 3,
                  isScrollable: true, // Permettre le défilement si nécessaire
                  onTap: (index) {
                    setState(() {}); // Forcer la mise à jour de l'UI
                  },
                  tabs: [
                    Tab(
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          const Text('Boissons'),
                          const SizedBox(width: 4),
                          if (hasDrinks)
                            Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 6,
                                vertical: 2,
                              ),
                              decoration: BoxDecoration(
                                color:
                                    _tabController.index == 0
                                        ? Theme.of(context).primaryColor
                                        : Colors.grey.shade300,
                                borderRadius: BorderRadius.circular(10),
                              ),
                              child: Text(
                                _searchQuery.isEmpty
                                    ? '${widget.stockVM.drinks.length}'
                                    : '${widget.stockVM.drinks.where((item) => item.name.toLowerCase().contains(_searchQuery.toLowerCase())).length}',
                                style: TextStyle(
                                  color:
                                      _tabController.index == 0
                                          ? Colors.white
                                          : Colors.grey.shade700,
                                  fontSize: 10,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            )
                          else
                            const Icon(
                              Icons.warning,
                              size: 14,
                              color: Colors.orange,
                            ),
                        ],
                      ),
                    ),
                    Tab(
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          const Text('Nourriture'),
                          const SizedBox(width: 4),
                          if (hasFood)
                            Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 6,
                                vertical: 2,
                              ),
                              decoration: BoxDecoration(
                                color:
                                    _tabController.index == 1
                                        ? Theme.of(context).primaryColor
                                        : Colors.grey.shade300,
                                borderRadius: BorderRadius.circular(10),
                              ),
                              child: Text(
                                _searchQuery.isEmpty
                                    ? '${widget.stockVM.food.length}'
                                    : '${widget.stockVM.food.where((item) => item.name.toLowerCase().contains(_searchQuery.toLowerCase())).length}',
                                style: TextStyle(
                                  color:
                                      _tabController.index == 1
                                          ? Colors.white
                                          : Colors.grey.shade700,
                                  fontSize: 10,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            )
                          else
                            const Icon(
                              Icons.warning,
                              size: 14,
                              color: Colors.orange,
                            ),
                        ],
                      ),
                    ),
                    Tab(
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          const Text('Autres'),
                          const SizedBox(width: 4),
                          if (hasOthers)
                            Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 6,
                                vertical: 2,
                              ),
                              decoration: BoxDecoration(
                                color:
                                    _tabController.index == 2
                                        ? Theme.of(context).primaryColor
                                        : Colors.grey.shade300,
                                borderRadius: BorderRadius.circular(10),
                              ),
                              child: Text(
                                _searchQuery.isEmpty
                                    ? '${widget.stockVM.others.length}'
                                    : '${widget.stockVM.others.where((item) => item.name.toLowerCase().contains(_searchQuery.toLowerCase())).length}',
                                style: TextStyle(
                                  color:
                                      _tabController.index == 2
                                          ? Colors.white
                                          : Colors.grey.shade700,
                                  fontSize: 10,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            )
                          else
                            const Icon(
                              Icons.warning,
                              size: 14,
                              color: Colors.orange,
                            ),
                        ],
                      ),
                    ),
                  ],
                ),
                Expanded(
                  child: TabBarView(
                    controller: _tabController,
                    children: [
                      // Onglet Boissons
                      Builder(
                        builder: (context) {
                          final drinks = widget.stockVM.drinks;
                          return _buildItemList(drinks);
                        },
                      ),
                      // Onglet Nourriture
                      Builder(
                        builder: (context) {
                          final food = widget.stockVM.food;
                          return _buildItemList(food);
                        },
                      ),
                      // Onglet Autres
                      Builder(
                        builder: (context) {
                          final others = widget.stockVM.others;
                          return _buildItemList(others);
                        },
                      ),
                    ],
                  ),
                ),
                // Afficher des instructions ou des informations supplémentaires
                Padding(
                  padding: const EdgeInsets.all(8.0),
                  child: Text(
                    'Sélectionnez un article pour l\'ajouter à la réservation',
                    style: TextStyle(color: Colors.grey.shade600, fontSize: 12),
                    textAlign: TextAlign.center,
                  ),
                ),
              ],
            ),
          ),
    );
  }
}
