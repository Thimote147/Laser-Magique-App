import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../models/stock_item_model.dart';
import '../../viewmodels/stock_view_model.dart';
import 'quantity_controls.dart';

class StockList extends StatelessWidget {
  final List<StockItem> items;

  const StockList({Key? key, required this.items}) : super(key: key);

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
    if (items.isEmpty) {
      return const Center(child: Text('Aucun article dans cette catégorie'));
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
        final isLowStock = item.isLowStock;

        return Material(
          color: isLowStock ? Colors.red.shade50 : Colors.grey.shade50,
          borderRadius: BorderRadius.circular(8),
          child: Container(
            padding: const EdgeInsets.all(6),
            decoration: BoxDecoration(
              border: Border.all(
                color: isLowStock ? Colors.red.shade300 : Colors.grey.shade300,
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
                      isLowStock ? Colors.red.shade700 : Colors.grey.shade700,
                ),
                const SizedBox(height: 4),
                Text(
                  item.name,
                  textAlign: TextAlign.center,
                  overflow: TextOverflow.ellipsis,
                  maxLines: 2,
                  style: TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.bold,
                    color: isLowStock ? Colors.red.shade700 : Colors.black,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  '${item.price.toStringAsFixed(2)}€',
                  style: TextStyle(fontSize: 12, color: Colors.grey.shade700),
                ),
                const SizedBox(height: 2),
                SizedBox(
                  height: 36,
                  child: QuantityControls(
                    quantity: item.quantity,
                    minQuantity: 0,
                    onChanged:
                        (value) => context
                            .read<StockViewModel>()
                            .adjustQuantity(item.id, value - item.quantity),
                    iconSize: 22,
                    fontSize: 14,
                    containerWidth: 32,
                    padding: const EdgeInsets.all(6),
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}
