import 'package:flutter/material.dart';
import '../../models/stock_item_model.dart';
import '../../viewmodels/stock_view_model.dart';
import 'stock_list_widget.dart';

class StockSearchDelegate extends SearchDelegate<StockItem?> {
  final StockViewModel stockViewModel;
  String _lastQuery = '';

  StockSearchDelegate(this.stockViewModel);

  @override
  List<Widget> buildActions(BuildContext context) {
    return [
      IconButton(
        icon: const Icon(Icons.clear),
        onPressed: () {
          query = '';
          _lastQuery = '';
          stockViewModel.updateSearchQuery('');
          showSuggestions(context);
        },
      ),
    ];
  }

  @override
  Widget buildLeading(BuildContext context) {
    return IconButton(
      icon: const Icon(Icons.arrow_back),
      onPressed: () {
        stockViewModel.updateSearchQuery('');
        close(context, null);
      },
    );
  }

  @override
  Widget buildResults(BuildContext context) {
    _updateSearchIfNeeded();
    return ListenableBuilder(
      listenable: stockViewModel,
      builder: (context, _) {
        final results = stockViewModel.filteredItems;
        return results.isEmpty
            ? const Center(child: Text('Aucun article trouvé'))
            : StockList(
              items: results,
              onQuantityChanged: (index, newQuantity) {
                final item = results[index];
                stockViewModel.updateItem(item.copyWith(quantity: newQuantity));
              },
            );
      },
    );
  }

  @override
  Widget buildSuggestions(BuildContext context) {
    if (query.isEmpty) {
      return const Center(child: Text('Commencez à taper pour rechercher...'));
    }

    _updateSearchIfNeeded();
    return ListenableBuilder(
      listenable: stockViewModel,
      builder: (context, _) {
        final suggestions = stockViewModel.filteredItems;
        return suggestions.isEmpty
            ? const Center(child: Text('Aucune suggestion...'))
            : StockList(
              items: suggestions,
              onQuantityChanged: (index, newQuantity) {
                final item = suggestions[index];
                stockViewModel.updateItem(item.copyWith(quantity: newQuantity));
              },
            );
      },
    );
  }

  void _updateSearchIfNeeded() {
    if (_lastQuery != query) {
      _lastQuery = query;
      // Use Future.microtask to avoid updating state during build
      Future.microtask(() => stockViewModel.updateSearchQuery(query));
    }
  }
}
