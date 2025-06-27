import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'dart:async';
import '../../../inventory/models/stock_item_model.dart';
import '../../../inventory/viewmodels/stock_view_model.dart';

/// Widget de sélection des consommations avec une interface utilisateur moderne et interactive
///
/// Affiche une liste d'articles avec des onglets pour les différentes catégories,
/// une barre de recherche avec debounce, des animations fluides et un feedback tactile.
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

/// État du widget ConsumptionSelector
class ConsumptionSelectorState extends State<ConsumptionSelector>
    with TickerProviderStateMixin {
  /// Contrôleur pour les onglets
  late TabController _tabController;

  /// ID de l'article sélectionné
  String? selectedItemId;

  /// Texte de recherche courant
  String _searchQuery = '';

  /// Contrôleur pour le champ de recherche
  final TextEditingController _searchController = TextEditingController();

  /// Horodatage de la dernière recherche pour le debounce
  DateTime? _lastSearchTime;

  /// Position du glissement pour la fermeture du modal
  double _dragOffset = 0.0;

  /// Contrôleur pour les animations d'entrée
  late AnimationController _animationController;

  /// Animation d'échelle
  late Animation<double> _scaleAnimation;

  /// Animation d'opacité
  late Animation<double> _opacityAnimation;

  /// Clé pour le champ de recherche (accessibilité)
  final GlobalKey _searchFieldKey = GlobalKey(debugLabel: 'searchField');

  /// Clé pour la barre d'onglets (accessibilité)
  final GlobalKey _tabBarKey = GlobalKey(debugLabel: 'tabBar');

  /// Seuil de glissement pour fermer le modal
  static const double _dragThreshold = 100.0;

  @override
  void initState() {
    super.initState();
    _initializeTabController();
    _initializeAnimations();
    _searchController.addListener(_onSearchChanged);
  }

  void _initializeAnimations() {
    _animationController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 200),
    );

    _scaleAnimation = Tween<double>(begin: 0.95, end: 1.0).animate(
      CurvedAnimation(parent: _animationController, curve: Curves.easeOut),
    );

    _opacityAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _animationController, curve: Curves.easeOut),
    );

    _animationController.forward();
  }

  void _initializeTabController() {
    int tabCount = 0;
    if (widget.stockVM.drinks.isNotEmpty) tabCount++;
    if (widget.stockVM.food.isNotEmpty) tabCount++;
    if (widget.stockVM.others.isNotEmpty) tabCount++;

    tabCount = tabCount.clamp(1, 3);

    _tabController = TabController(length: tabCount, vsync: this);

    _tabController.addListener(() {
      if (_tabController.indexIsChanging) {
        setState(() {});
      }
    });
  }

  void _onSearchChanged() {
    final now = DateTime.now();
    _lastSearchTime = now;

    Future.delayed(const Duration(milliseconds: 300), () {
      if (_lastSearchTime == now) {
        setState(() {
          _searchQuery = _searchController.text;
        });
      }
    });
  }

  @override
  void didUpdateWidget(ConsumptionSelector oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.stockVM != widget.stockVM) {
      _tabController.dispose();
      _initializeTabController();
    }
  }

  @override
  void dispose() {
    _animationController.dispose();
    _tabController.dispose();
    _searchController.dispose();
    super.dispose();
  }

  IconData _getItemIcon(String category) {
    switch (category) {
      case 'DRINK':
        return Icons.local_bar_rounded;
      case 'FOOD':
        return Icons.restaurant_rounded;
      case 'OTHER':
        return Icons.category_rounded;
      default:
        return Icons.inventory_2_rounded;
    }
  }

  Widget _buildDragHandle(BuildContext context) {
    final progress = (_dragOffset / _dragThreshold).clamp(0.0, 1.0);

    return GestureDetector(
      onVerticalDragUpdate: (details) {
        setState(() {
          _dragOffset += details.primaryDelta!;
          if (_dragOffset > _dragThreshold) {
            Navigator.pop(context);
          }
        });
      },
      onVerticalDragEnd: (_) {
        if (_dragOffset <= _dragThreshold) {
          setState(() => _dragOffset = 0.0);
        }
      },
      child: Container(
        margin: const EdgeInsets.symmetric(vertical: 8),
        width: 40 + (progress * 20),
        height: 4,
        decoration: BoxDecoration(
          color: Theme.of(
            context,
          ).colorScheme.outlineVariant.withAlpha((255 * (1.0 - progress * 0.3)).round()),
          borderRadius: BorderRadius.circular(2),
        ),
      ),
    );
  }

  Widget _buildSearchField(BuildContext context) {
    return Semantics(
      textField: true,
      label: 'Rechercher un article',
      hint: 'Double-tapez pour rechercher un article',
      child: TextField(
        key: _searchFieldKey,
        controller: _searchController,
        decoration: InputDecoration(
          hintText: 'Rechercher un article...',
          hintStyle: TextStyle(color: Theme.of(context).colorScheme.outline),
          prefixIcon: Icon(
            Icons.search_rounded,
            color: Theme.of(context).colorScheme.outline,
          ),
          suffixIcon:
              _searchQuery.isNotEmpty
                  ? IconButton(
                    tooltip: 'Effacer la recherche',
                    icon: const Icon(Icons.clear_rounded),
                    onPressed: () {
                      _searchController.clear();
                      setState(() => _searchQuery = '');
                    },
                  )
                  : null,
          filled: true,
          fillColor: Theme.of(
            context,
          ).colorScheme.surfaceContainerHighest.withAlpha((255 * 0.3).round()),
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: BorderSide.none,
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: BorderSide(
              color: Theme.of(context).colorScheme.primary,
              width: 2,
            ),
          ),
          contentPadding: const EdgeInsets.symmetric(
            horizontal: 16,
            vertical: 14,
          ),
        ),
        textInputAction: TextInputAction.search,
        onChanged: (value) => setState(() => _searchQuery = value),
      ),
    );
  }

  Widget _buildItemList(List<StockItem> items) {
    final filteredItems =
        items
            .where(
              (item) =>
                  item.name.toLowerCase().contains(_searchQuery.toLowerCase()),
            )
            .toList()
          ..sort((a, b) => a.name.compareTo(b.name));

    if (filteredItems.isEmpty) {
      return AnimatedOpacity(
        duration: const Duration(milliseconds: 300),
        opacity: _searchQuery.isEmpty ? 1.0 : 0.8,
        child: Center(
          child: Padding(
            padding: const EdgeInsets.all(24.0),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(
                  _searchQuery.isEmpty
                      ? Icons.inventory_2_outlined
                      : Icons.search_off_rounded,
                  size: 48,
                  color: Theme.of(context).colorScheme.outline,
                ),
                const SizedBox(height: 16),
                Text(
                  _searchQuery.isEmpty
                      ? 'Aucun article disponible dans cette catégorie'
                      : 'Aucun résultat trouvé pour "$_searchQuery"',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontSize: 16,
                    color: Theme.of(context).colorScheme.onSurfaceVariant,
                  ),
                ),
                if (_searchQuery.isNotEmpty) ...[
                  const SizedBox(height: 8),
                  Text(
                    'Essayez avec un autre terme',
                    style: TextStyle(
                      fontSize: 14,
                      color: Theme.of(context).colorScheme.outline,
                    ),
                  ),
                ],
              ],
            ),
          ),
        ),
      );
    }

    return ListView.builder(
      physics: const BouncingScrollPhysics(),
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
      itemCount: filteredItems.length,
      itemBuilder: (context, index) {
        final item = filteredItems[index];
        final isSelected = selectedItemId == item.id;
        final hasStock = item.quantity > 0;
        // Permet la sélection si l'article a du stock ou s'il est déjà sélectionné (pour permettre la désélection)
        final canInteract = hasStock || isSelected;

        return Padding(
          padding: const EdgeInsets.only(bottom: 8),
          child: Material(
            color: Colors.transparent,
            child: InkWell(
              onTap:
                  canInteract
                      ? () {
                        // Si l'article est déjà sélectionné, on le désélectionne
                        if (isSelected) {
                          setState(() => selectedItemId = null);
                          widget.onConsumptionSelected(
                            '',
                          ); // On envoie une chaîne vide pour indiquer la désélection
                        } else {
                          setState(() => selectedItemId = item.id);
                          widget.onConsumptionSelected(item.id);
                        }
                        HapticFeedback.selectionClick();
                      }
                      : null,
              borderRadius: BorderRadius.circular(12),
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 200),
                decoration: BoxDecoration(
                  color:
                      !hasStock
                          ? Theme.of(
                            context,
                          ).colorScheme.surfaceContainerHighest.withAlpha((255 * 0.3).round())
                          : isSelected
                          ? Theme.of(context).colorScheme.primaryContainer
                          : Theme.of(context).colorScheme.surface,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(
                    color:
                        !hasStock
                            ? Theme.of(
                              context,
                            ).colorScheme.outlineVariant.withAlpha((255 * 0.3).round())
                            : isSelected
                            ? Theme.of(context).colorScheme.primary
                            : Theme.of(
                              context,
                            ).colorScheme.outlineVariant.withAlpha((255 * 0.3).round()),
                    width: isSelected ? 2 : 1,
                  ),
                  boxShadow:
                      isSelected
                          ? [
                            BoxShadow(
                              color: Theme.of(
                                context,
                              ).colorScheme.primary.withAlpha((255 * 0.1).round()),
                              blurRadius: 8,
                              spreadRadius: 0,
                            ),
                          ]
                          : null,
                ),
                padding: const EdgeInsets.all(12),
                child: Row(
                  children: [
                    Stack(
                      clipBehavior: Clip.none,
                      children: [
                        Container(
                          padding: const EdgeInsets.all(8),
                          decoration: BoxDecoration(
                            color:
                                hasStock
                                    ? Theme.of(
                                      context,
                                    ).colorScheme.primary.withAlpha((255 * 0.1).round())
                                    : Theme.of(
                                      context,
                                    ).colorScheme.surfaceContainerHighest,
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Icon(
                            _getItemIcon(item.category),
                            size: 20,
                            color:
                                hasStock
                                    ? Theme.of(context).colorScheme.primary
                                    : Theme.of(context).colorScheme.outline,
                          ),
                        ),
                        if (hasStock && item.quantity <= item.alertThreshold)
                          Positioned(
                            top: -4,
                            right: -4,
                            child: Container(
                              padding: const EdgeInsets.all(4),
                              decoration: BoxDecoration(
                                color:
                                    Theme.of(
                                      context,
                                    ).colorScheme.errorContainer,
                                shape: BoxShape.circle,
                                border: Border.all(
                                  color: Theme.of(context).colorScheme.surface,
                                  width: 1.5,
                                ),
                              ),
                              child: Icon(
                                Icons.warning_rounded,
                                size: 10,
                                color: Theme.of(context).colorScheme.error,
                              ),
                            ),
                          ),
                      ],
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            item.name,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.w500,
                              color:
                                  hasStock
                                      ? Theme.of(context).colorScheme.onSurface
                                      : Theme.of(context).colorScheme.outline,
                              decoration:
                                  hasStock ? null : TextDecoration.lineThrough,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Row(
                            children: [
                              if (hasStock)
                                Container(
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 6,
                                    vertical: 2,
                                  ),
                                  decoration: BoxDecoration(
                                    color:
                                        item.quantity <= item.alertThreshold
                                            ? Theme.of(
                                              context,
                                            ).colorScheme.errorContainer
                                            : Theme.of(
                                              context,
                                            ).colorScheme.tertiaryContainer,
                                    borderRadius: BorderRadius.circular(4),
                                  ),
                                  child: Text(
                                    'Stock : ${item.quantity}',
                                    style: TextStyle(
                                      fontSize: 12,
                                      fontWeight: FontWeight.w500,
                                      color:
                                          item.quantity <= item.alertThreshold
                                              ? Theme.of(
                                                context,
                                              ).colorScheme.error
                                              : Theme.of(
                                                context,
                                              ).colorScheme.onTertiaryContainer,
                                    ),
                                  ),
                                )
                              else
                                Container(
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 6,
                                    vertical: 2,
                                  ),
                                  decoration: BoxDecoration(
                                    color:
                                        Theme.of(
                                          context,
                                        ).colorScheme.errorContainer,
                                    borderRadius: BorderRadius.circular(4),
                                  ),
                                  child: Text(
                                    'Épuisé',
                                    style: TextStyle(
                                      fontSize: 12,
                                      fontWeight: FontWeight.w500,
                                      color:
                                          Theme.of(context).colorScheme.error,
                                    ),
                                  ),
                                ),
                            ],
                          ),
                        ],
                      ),
                    ),
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 10,
                        vertical: 4,
                      ),
                      decoration: BoxDecoration(
                        color: Theme.of(
                          context,
                        ).colorScheme.secondaryContainer.withAlpha((255 * 0.5).round()),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Text(
                        '${item.price.toStringAsFixed(2)}€',
                        style: TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w600,
                          color:
                              Theme.of(
                                context,
                              ).colorScheme.onSecondaryContainer,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _buildTab(
    String label,
    IconData icon,
    int index,
    int count,
    BuildContext context,
  ) {
    final isSelected = _tabController.index == index;
    return Tab(
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 8),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: 18),
            const SizedBox(width: 6),
            Flexible(child: Text(label, overflow: TextOverflow.ellipsis)),
            if (count > 0) ...[
              const SizedBox(width: 4),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                decoration: BoxDecoration(
                  color:
                      isSelected
                          ? Theme.of(
                            context,
                          ).colorScheme.primary.withAlpha((255 * 0.15).round())
                          : Theme.of(context).colorScheme.surfaceContainerHighest,
                  borderRadius: BorderRadius.circular(10),
                  border:
                      isSelected
                          ? Border.all(
                            color: Theme.of(
                              context,
                            ).colorScheme.primary.withAlpha((255 * 0.3).round()),
                            width: 1,
                          )
                          : null,
                ),
                child: Text(
                  _searchQuery.isEmpty
                      ? '$count'
                      : '${_getFilteredCount(index)}',
                  style: TextStyle(
                    color:
                        isSelected
                            ? Theme.of(context).colorScheme.onPrimary
                            : Theme.of(context).colorScheme.onSurfaceVariant,
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  int _getFilteredCount(int tabIndex) {
    final query = _searchQuery.toLowerCase();
    switch (tabIndex) {
      case 0:
        return widget.stockVM.drinks
            .where((item) => item.name.toLowerCase().contains(query))
            .length;
      case 1:
        return widget.stockVM.food
            .where((item) => item.name.toLowerCase().contains(query))
            .length;
      case 2:
        return widget.stockVM.others
            .where((item) => item.name.toLowerCase().contains(query))
            .length;
      default:
        return 0;
    }
  }

  @override
  Widget build(BuildContext context) {
    final hasDrinks = widget.stockVM.drinks.isNotEmpty;
    final hasFood = widget.stockVM.food.isNotEmpty;
    final hasOthers = widget.stockVM.others.isNotEmpty;
    final hasAny = hasDrinks || hasFood || hasOthers;

    if (!hasAny) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.inventory_2_outlined,
              size: 64,
              color: Theme.of(context).colorScheme.outline,
            ),
            const SizedBox(height: 16),
            Text(
              'Aucun article disponible',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w600,
                color: Theme.of(context).colorScheme.outline,
              ),
            ),
            const SizedBox(height: 8),
            FilledButton.icon(
              onPressed: () => Navigator.pop(context),
              icon: const Icon(Icons.close),
              label: const Text('Fermer'),
            ),
          ],
        ),
      );
    }

    final List<Widget> tabs = [];
    final List<Widget> tabViews = [];

    if (hasDrinks) {
      tabs.add(
        _buildTab(
          'Boissons',
          Icons.local_bar_rounded,
          tabs.length,
          widget.stockVM.drinks.length,
          context,
        ),
      );
      tabViews.add(
        Builder(builder: (context) => _buildItemList(widget.stockVM.drinks)),
      );
    }

    if (hasFood) {
      tabs.add(
        _buildTab(
          'Nourriture',
          Icons.restaurant_rounded,
          tabs.length,
          widget.stockVM.food.length,
          context,
        ),
      );
      tabViews.add(
        Builder(builder: (context) => _buildItemList(widget.stockVM.food)),
      );
    }

    if (hasOthers) {
      tabs.add(
        _buildTab(
          'Autres',
          Icons.category_rounded,
          tabs.length,
          widget.stockVM.others.length,
          context,
        ),
      );
      tabViews.add(
        Builder(builder: (context) => _buildItemList(widget.stockVM.others)),
      );
    }

    if (tabs.isEmpty) {
      tabs.add(const Tab(text: 'Aucun article'));
      tabViews.add(const Center(child: Text('Aucun article disponible')));
    }

    return AnimatedBuilder(
      animation: _animationController,
      builder:
          (context, child) => Transform.scale(
            scale: _scaleAnimation.value,
            child: Opacity(
              opacity: _opacityAnimation.value,
              child: Semantics(
                container: true,
                label: 'Sélecteur de consommation',
                hint: 'Faites glisser vers le bas pour fermer',
                child: DraggableScrollableSheet(
                  initialChildSize: 0.7,
                  minChildSize: 0.5,
                  maxChildSize: 0.95,
                  snap: true,
                  snapSizes: const [0.7, 0.95],
                  builder:
                      (_, scrollController) => Container(
                        decoration: BoxDecoration(
                          color: Theme.of(context).colorScheme.surface,
                          borderRadius: const BorderRadius.vertical(
                            top: Radius.circular(20),
                          ),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withAlpha((255 * 0.1).round()),
                              blurRadius: 10,
                              spreadRadius: 0,
                              offset: const Offset(0, -2),
                            ),
                          ],
                        ),
                        child: Column(
                          children: [
                            _buildDragHandle(context),

                            // En-tête avec titre et bouton de fermeture
                            Padding(
                              padding: const EdgeInsets.fromLTRB(24, 8, 16, 16),
                              child: Row(
                                children: [
                                  Icon(
                                    Icons.local_bar_rounded,
                                    size: 24,
                                    color:
                                        Theme.of(context).colorScheme.primary,
                                  ),
                                  const SizedBox(width: 12),
                                  Expanded(
                                    child: Text(
                                      'Ajouter une consommation',
                                      style: Theme.of(
                                        context,
                                      ).textTheme.titleLarge?.copyWith(
                                        fontWeight: FontWeight.w600,
                                      ),
                                    ),
                                  ),
                                  IconButton.filledTonal(
                                    icon: const Icon(Icons.close),
                                    onPressed: () => Navigator.pop(context),
                                    style: IconButton.styleFrom(
                                      backgroundColor:
                                          Theme.of(
                                            context,
                                          ).colorScheme.surfaceContainerHighest,
                                      foregroundColor:
                                          Theme.of(
                                            context,
                                          ).colorScheme.onSurfaceVariant,
                                    ),
                                  ),
                                ],
                              ),
                            ),

                            // Champ de recherche optimisé
                            Padding(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 16,
                              ),
                              child: _buildSearchField(context),
                            ),

                            const SizedBox(height: 8),

                            // TabBar avec sémantique et animations
                            Container(
                              height: 48,
                              margin: const EdgeInsets.symmetric(
                                horizontal: 12,
                              ),
                              decoration: BoxDecoration(
                                color: Theme.of(
                                  context,
                                ).colorScheme.surfaceContainerHighest.withAlpha((255 * 0.3).round()),
                                borderRadius: BorderRadius.circular(12),
                              ),
                              child: Semantics(
                                container: true,
                                label: 'Catégories de consommations',
                                child: TabBar(
                                  key: _tabBarKey,
                                  controller: _tabController,
                                  labelColor:
                                      Theme.of(context).colorScheme.primary,
                                  unselectedLabelColor:
                                      Theme.of(
                                        context,
                                      ).colorScheme.onSurfaceVariant,
                                  labelStyle: const TextStyle(
                                    fontWeight: FontWeight.w600,
                                  ),
                                  unselectedLabelStyle: const TextStyle(
                                    fontWeight: FontWeight.w500,
                                  ),
                                  indicator: BoxDecoration(
                                    color:
                                        Theme.of(
                                          context,
                                        ).colorScheme.primaryContainer,
                                    borderRadius: BorderRadius.circular(12),
                                    border: Border.all(
                                      color:
                                          Theme.of(context).colorScheme.primary,
                                      width: 1,
                                    ),
                                  ),
                                  indicatorSize: TabBarIndicatorSize.tab,
                                  dividerColor: Colors.transparent,
                                  labelPadding: const EdgeInsets.symmetric(
                                    horizontal: 4,
                                  ),
                                  tabs: tabs,
                                ),
                              ),
                            ),

                            const SizedBox(height: 8),

                            // TabBarView avec animation de transition
                            Expanded(
                              child: TabBarView(
                                controller: _tabController,
                                physics: const BouncingScrollPhysics(),
                                children: List.generate(
                                  tabViews.length,
                                  (index) => TweenAnimationBuilder<double>(
                                    key: ValueKey('tab_$index'),
                                    duration: const Duration(milliseconds: 300),
                                    tween: Tween<double>(
                                      begin: 0.0,
                                      end:
                                          _tabController.index == index
                                              ? 1.0
                                              : 0.0,
                                    ),
                                    builder:
                                        (context, value, child) => Opacity(
                                          opacity: value,
                                          child: Transform.translate(
                                            offset: Offset(0, 20 * (1 - value)),
                                            child: child,
                                          ),
                                        ),
                                    child: tabViews[index],
                                  ),
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                ),
              ),
            ),
          ),
    );
  }
}
