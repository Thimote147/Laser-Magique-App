import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../viewmodels/stock_view_model.dart';
import '../../models/stock_item_model.dart';
import '../widgets/stock_list_widget.dart';
import '../widgets/stock_search_delegate.dart';
import '../widgets/stock_item_modal_widget.dart';

class StockScreen extends StatefulWidget {
  const StockScreen({super.key});

  @override
  State<StockScreen> createState() => _StockScreenState();
}

class _StockScreenState extends State<StockScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) {
        context.read<StockViewModel>().initialize();
      }
    });
  }

  Widget _buildTab(
    BuildContext context,
    String text,
    IconData icon, {
    bool isInactive = false,
  }) {
    return Tab(
      height: 36,
      child: LayoutBuilder(
        builder: (context, constraints) {
          return Row(
            mainAxisAlignment: MainAxisAlignment.center,
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(icon, size: 18),
              const SizedBox(width: 6),
              Flexible(
                child: Text(
                  text,
                  overflow: TextOverflow.ellipsis,
                  style: DefaultTextStyle.of(context).style,
                ),
              ),
            ],
          );
        },
      ),
    );
  }

  void _showAddEditDialog(BuildContext context, [StockItem? item]) {
    StockItemModal.show(
      context,
      item: item,
      onSave: (stockItem) {
        final stockVM = context.read<StockViewModel>();
        if (item == null) {
          stockVM.addItem(
            name: stockItem.name,
            quantity: stockItem.quantity,
            price: stockItem.price,
            alertThreshold: stockItem.alertThreshold,
            category: stockItem.category,
          );
        } else {
          stockVM.updateItem(stockItem);
        }
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final hasInactiveItems = context.select(
      (StockViewModel vm) => vm.inactiveItems.isNotEmpty,
    );
    return DefaultTabController(
      length: hasInactiveItems ? 4 : 3,
      child: Theme(
        data: Theme.of(context).copyWith(
          tabBarTheme: TabBarTheme(
            labelColor: Theme.of(context).colorScheme.primary,
            unselectedLabelColor: Theme.of(context).colorScheme.onSurface,
          ),
        ),
        child: Scaffold(
          appBar: AppBar(
            title: const Text('Gestion des stocks'),
            actions: [
              IconButton(
                icon: const Icon(Icons.search),
                onPressed: () {
                  showSearch(
                    context: context,
                    delegate: StockSearchDelegate(
                      context.read<StockViewModel>(),
                    ),
                  );
                },
              ),
            ],
            bottom: PreferredSize(
              preferredSize: const Size.fromHeight(56),
              child: Padding(
                padding: const EdgeInsets.fromLTRB(16, 0, 16, 12),
                child: Container(
                  height: 44,
                  decoration: BoxDecoration(
                    color: Theme.of(context).colorScheme.surfaceContainerHighest
                        .withAlpha((255 * 0.3).round()),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: TabBar(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 4,
                      vertical: 2,
                    ),
                    indicator: BoxDecoration(
                      color: Theme.of(context).colorScheme.primaryContainer,
                      borderRadius: BorderRadius.circular(10),
                      border: Border.all(
                        color: Theme.of(context).colorScheme.primary,
                        width: 1,
                      ),
                    ),
                    indicatorSize: TabBarIndicatorSize.tab,
                    dividerColor: Colors.transparent,
                    labelColor: Theme.of(context).colorScheme.primary,
                    unselectedLabelColor:
                        Theme.of(context).colorScheme.onSurfaceVariant,
                    labelStyle: const TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                    ),
                    unselectedLabelStyle: const TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w500,
                    ),
                    overlayColor: WidgetStateProperty.all(Colors.transparent),
                    tabs: [
                      _buildTab(context, 'Boissons', Icons.local_bar_rounded),
                      _buildTab(
                        context,
                        'Nourriture',
                        Icons.restaurant_rounded,
                      ),
                      _buildTab(context, 'Autres', Icons.category_rounded),
                      if (context.select(
                        (StockViewModel vm) => vm.inactiveItems.isNotEmpty,
                      ))
                        _buildTab(
                          context,
                          'Inactifs',
                          Icons.visibility_off_rounded,
                          isInactive: true,
                        ),
                    ],
                    isScrollable: false,
                  ),
                ),
              ),
            ),
          ),
          body: Consumer<StockViewModel>(
            builder: (context, stockVM, child) {
              return Column(
                children: [
                  Expanded(
                    child: TabBarView(
                      children: [
                        StockList(
                          items: stockVM.drinks,
                          onQuantityChanged: (index, newQuantity) {
                            final item = stockVM.drinks[index];
                            // Créer un nouvel objet avec la nouvelle quantité
                            final updatedItem = item.copyWith(
                              quantity: newQuantity,
                            );
                            stockVM.updateItem(updatedItem);
                          },
                        ),
                        StockList(
                          items: stockVM.food,
                          onQuantityChanged: (index, newQuantity) {
                            final item = stockVM.food[index];
                            // Créer un nouvel objet avec la nouvelle quantité
                            final updatedItem = item.copyWith(
                              quantity: newQuantity,
                            );
                            stockVM.updateItem(updatedItem);
                          },
                        ),
                        StockList(
                          items: stockVM.others,
                          onQuantityChanged: (index, newQuantity) {
                            final item = stockVM.others[index];
                            // Créer un nouvel objet avec la nouvelle quantité
                            final updatedItem = item.copyWith(
                              quantity: newQuantity,
                            );
                            stockVM.updateItem(updatedItem);
                          },
                        ),
                        if (stockVM.inactiveItems.isNotEmpty)
                          StockList(
                            items: stockVM.inactiveItems,
                            showActivateButton: true,
                            onQuantityChanged: (index, newQuantity) {
                              final item = stockVM.inactiveItems[index];
                              // Créer un nouvel objet avec la nouvelle quantité
                              final updatedItem = item.copyWith(
                                quantity: newQuantity,
                              );
                              stockVM.updateItem(updatedItem);
                            },
                          ),
                      ],
                    ),
                  ),
                ],
              );
            },
          ),
          floatingActionButton: FloatingActionButton(
            onPressed: () => _showAddEditDialog(context),
            child: const Icon(Icons.add),
          ),
        ),
      ),
    );
  }
}
