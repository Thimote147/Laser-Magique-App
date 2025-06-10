import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../viewmodels/stock_view_model.dart';
import '../../models/stock_item_model.dart';
import '../widgets/stock_list_widget.dart';
import '../widgets/stock_item_dialog_widget.dart';
import '../widgets/stock_search_delegate.dart';

class StockScreen extends StatelessWidget {
  const StockScreen({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    // Initialiser les données de test au chargement de la page
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final stockViewModel = Provider.of<StockViewModel>(
        context,
        listen: false,
      );
      if (stockViewModel.items.isEmpty) {
        stockViewModel.loadDummyData();
      }
    });

    return DefaultTabController(
      length: 3,
      child: Scaffold(
        appBar: AppBar(
          title: const Text('Gestion des stocks'),
          actions: [
            IconButton(
              icon: const Icon(Icons.search),
              onPressed: () {
                showSearch(
                  context: context,
                  delegate: StockSearchDelegate(context.read<StockViewModel>()),
                );
              },
            ),
          ],
          bottom: const TabBar(
            tabs: [
              Tab(text: 'Boissons'),
              Tab(text: 'Nourriture'),
              Tab(text: 'Autres'),
            ],
          ),
        ),
        body: Consumer<StockViewModel>(
          builder: (context, stockVM, child) {
            final lowStockItems = stockVM.lowStockItems;

            return Column(
              children: [
                if (lowStockItems.isNotEmpty)
                  Container(
                    color: Colors.red[100],
                    padding: const EdgeInsets.all(8.0),
                    child: Row(
                      children: [
                        const Icon(Icons.warning, color: Colors.red),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            'Articles en stock bas : ${lowStockItems.map((e) => e.name).join(", ")}',
                            style: const TextStyle(color: Colors.red),
                          ),
                        ),
                      ],
                    ),
                  ),
                Expanded(
                  child: TabBarView(
                    children: [
                      StockList(items: stockVM.drinks),
                      StockList(items: stockVM.food),
                      StockList(items: stockVM.others),
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
    );
  }

  void _showAddEditDialog(BuildContext context, [StockItem? item]) {
    showDialog(
      context: context,
      builder: (context) => StockItemDialog(item: item),
    );
  }
}
