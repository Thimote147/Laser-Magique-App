import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../viewmodels/stock_view_model.dart';
import '../../models/stock_item_model.dart';

class StockQuantityAdjuster extends StatelessWidget {
  final StockItem item;

  const StockQuantityAdjuster({super.key, required this.item});

  Future<void> _confirmDelete(BuildContext context) async {
    return showDialog(
      context: context,
      builder: (BuildContext dialogContext) {
        return AlertDialog(
          title: const Text('Supprimer l\'article'),
          content: Text('Voulez-vous vraiment supprimer "${item.name}" ?'),
          actions: [
            TextButton(
              child: const Text('Annuler'),
              onPressed: () {
                Navigator.of(dialogContext).pop();
              },
            ),
            TextButton(
              child: const Text(
                'Supprimer',
                style: TextStyle(color: Colors.red),
              ),
              onPressed: () {
                Navigator.of(dialogContext).pop();
                context.read<StockViewModel>().deleteItem(item.id).catchError((
                  error,
                ) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text('Erreur: $error'),
                      backgroundColor: Colors.red,
                    ),
                  );
                });
              },
            ),
          ],
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        IconButton(
          icon: Icon(
            item.quantity == 0 ? Icons.delete_outline : Icons.remove,
            color: item.quantity == 0 ? Colors.red : null,
          ),
          onPressed: () {
            if (item.quantity == 0) {
              _confirmDelete(context);
            } else {
              context
                  .read<StockViewModel>()
                  .adjustQuantity(item.id, -1)
                  .catchError((error) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Text('Erreur: $error'),
                        backgroundColor: Colors.red,
                      ),
                    );
                  });
            }
          },
        ),
        Text('${item.quantity}', style: const TextStyle(fontSize: 16)),
        IconButton(
          icon: const Icon(Icons.add),
          onPressed: () {
            context
                .read<StockViewModel>()
                .adjustQuantity(item.id, 1)
                .catchError((error) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text('Erreur: $error'),
                      backgroundColor: Colors.red,
                    ),
                  );
                });
          },
        ),
      ],
    );
  }
}
