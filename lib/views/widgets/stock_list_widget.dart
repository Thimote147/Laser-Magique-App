import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../models/stock_item_model.dart';
import '../../viewmodels/stock_view_model.dart';

class StockList extends StatelessWidget {
  final List<StockItem> items;

  const StockList({Key? key, required this.items}) : super(key: key);

  Future<void> _confirmDelete(BuildContext context, StockItem item) async {
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
      padding: const EdgeInsets.all(12),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 2,
        childAspectRatio: 2.4,
        crossAxisSpacing: 12,
        mainAxisSpacing: 12,
      ),
      itemCount: items.length,
      itemBuilder: (context, index) {
        final item = items[index];
        final isLowStock = item.isLowStock;
        final theme = Theme.of(context);

        return Container(
          decoration: BoxDecoration(
            color:
                Theme.of(context).brightness == Brightness.dark
                    ? Colors.grey.shade900
                    : Colors.white,
            borderRadius: BorderRadius.circular(12),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(
                  Theme.of(context).brightness == Brightness.dark ? 0.3 : 0.04,
                ),
                blurRadius: 8,
                offset: const Offset(0, 2),
              ),
            ],
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                height: 36,
                padding: const EdgeInsets.symmetric(
                  horizontal: 10,
                  vertical: 6,
                ),
                decoration: BoxDecoration(
                  color:
                      isLowStock
                          ? (Theme.of(context).brightness == Brightness.dark
                              ? Colors.red.shade900.withOpacity(0.3)
                              : Colors.red.shade50)
                          : (Theme.of(context).brightness == Brightness.dark
                              ? theme.primaryColor.withOpacity(0.15)
                              : theme.primaryColor.withOpacity(0.08)),
                  borderRadius: const BorderRadius.vertical(
                    top: Radius.circular(12),
                  ),
                ),
                child: Row(
                  children: [
                    Icon(
                      _getItemIcon(item.category),
                      size: 16,
                      color:
                          isLowStock
                              ? (Theme.of(context).brightness == Brightness.dark
                                  ? Colors.red.shade300
                                  : Colors.red.shade700)
                              : theme.colorScheme.primary,
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        item.name,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w600,
                          color:
                              isLowStock
                                  ? (Theme.of(context).brightness ==
                                          Brightness.dark
                                      ? Colors.red.shade300
                                      : Colors.red.shade700)
                                  : Theme.of(context).colorScheme.onSurface,
                        ),
                      ),
                    ),
                    Text(
                      '${item.price.toStringAsFixed(2)}€',
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w500,
                        color: Theme.of(context).colorScheme.primary,
                      ),
                    ),
                  ],
                ),
              ),
              Container(
                height: 48,
                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 4),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    _StockButton(
                      icon:
                          item.quantity == 0
                              ? Icons.delete_outline
                              : Icons.remove_rounded,
                      onTap: () {
                        if (item.quantity == 0) {
                          _confirmDelete(context, item);
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
                      color:
                          item.quantity == 0
                              ? Colors.red
                              : (Theme.of(context).brightness == Brightness.dark
                                  ? Colors.red.shade300
                                  : Colors.red.shade400),
                    ),
                    Container(
                      width: 40,
                      height: 40,
                      alignment: Alignment.center,
                      decoration: BoxDecoration(
                        color:
                            isLowStock
                                ? (Theme.of(context).brightness ==
                                        Brightness.dark
                                    ? Colors.red.shade900.withOpacity(0.3)
                                    : Colors.red.shade50.withOpacity(0.6))
                                : Theme.of(context).brightness ==
                                    Brightness.dark
                                ? theme.primaryColor.withOpacity(0.15)
                                : theme.primaryColor.withOpacity(0.08),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Text(
                        '${item.quantity}',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w500,
                          color:
                              isLowStock
                                  ? (Theme.of(context).brightness ==
                                          Brightness.dark
                                      ? Colors.red.shade300
                                      : Colors.red.shade700)
                                  : Theme.of(context).colorScheme.primary,
                        ),
                      ),
                    ),
                    Row(
                      children: [
                        _StockButton(
                          icon: Icons.add_rounded,
                          onTap: () {
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
                          color: Colors.green.shade400,
                        ),
                        const SizedBox(width: 4),
                        _StockButton(
                          icon: Icons.add_rounded,
                          label: "24",
                          onTap: () {
                            context
                                .read<StockViewModel>()
                                .adjustQuantity(item.id, 24)
                                .catchError((error) {
                                  ScaffoldMessenger.of(context).showSnackBar(
                                    SnackBar(
                                      content: Text('Erreur: $error'),
                                      backgroundColor: Colors.red,
                                    ),
                                  );
                                });
                          },
                          color: Colors.green.shade600,
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}

class _StockButton extends StatelessWidget {
  final IconData icon;
  final VoidCallback onTap;
  final Color color;
  final String? label;

  const _StockButton({
    required this.icon,
    required this.onTap,
    required this.color,
    this.label,
  });

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(8),
        child: Container(
          width: label != null ? 52 : 40,
          height: 40,
          decoration: BoxDecoration(
            color: color.withOpacity(0.1),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Stack(
            alignment: Alignment.center,
            children: [
              Icon(icon, color: color, size: 20),
              if (label != null)
                Positioned(
                  right: 2,
                  bottom: 2,
                  child: Text(
                    label!,
                    style: TextStyle(
                      color: color,
                      fontSize: 10,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }
}
