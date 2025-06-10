import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../models/booking_model.dart';
import '../../viewmodels/stock_view_model.dart';
import 'consumption_selector.dart';

class BookingConsumptionWidget extends StatelessWidget {
  final Booking booking;

  const BookingConsumptionWidget({Key? key, required this.booking})
    : super(key: key);

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

  void _showAddConsumptionDialog(BuildContext context, StockViewModel stockVM) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      useRootNavigator: true,
      backgroundColor: Colors.transparent,
      builder:
          (context) => Padding(
            padding: EdgeInsets.only(
              bottom: MediaQuery.of(context).viewInsets.bottom,
            ),
            child: ConsumptionSelector(
              stockVM: stockVM,
              onConsumptionSelected: (stockItemId, quantity) {
                stockVM.addConsumption(
                  bookingId: booking.id,
                  stockItemId: stockItemId,
                  quantity: quantity,
                );
                Navigator.pop(context);
              },
            ),
          ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<StockViewModel>(
      builder: (context, stockVM, _) {
        final consumptions = stockVM.getConsumptionsForBooking(booking.id);
        final total = consumptions.fold(0.0, (sum, c) => sum + c.totalPrice);

        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // En-tête avec badge de total
            Padding(
              padding: EdgeInsets.zero,
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text(
                    'Consommations',
                    style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                  ),
                  if (consumptions.isNotEmpty)
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 12,
                        vertical: 6,
                      ),
                      decoration: BoxDecoration(
                        color: Theme.of(context).primaryColor,
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Text(
                        'Total: ${total.toStringAsFixed(2)}€',
                        style: const TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                ],
              ),
            ),

            const SizedBox(height: 8),

            // Liste des consommations existantes
            if (consumptions.isNotEmpty) ...[
              const Padding(
                padding: EdgeInsets.fromLTRB(0, 16.0, 0, 8.0),
                child: Text(
                  'Liste des consommations',
                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.w500),
                ),
              ),
              ...consumptions.map((consumption) {
                final item = stockVM.items.firstWhere(
                  (item) => item.id == consumption.stockItemId,
                );

                return Card(
                  margin: const EdgeInsets.only(bottom: 8.0),
                  child: Padding(
                    padding: const EdgeInsets.all(12),
                    child: Row(
                      children: [
                        // Icône de la catégorie
                        Container(
                          padding: const EdgeInsets.all(8),
                          decoration: BoxDecoration(
                            color: Theme.of(
                              context,
                            ).primaryColor.withOpacity(0.1),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Icon(
                            _getItemIcon(item.category),
                            color: Theme.of(context).primaryColor,
                            size: 28,
                          ),
                        ),
                        const SizedBox(width: 12),

                        // Informations de l'article
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                item.name,
                                style: const TextStyle(
                                  fontWeight: FontWeight.bold,
                                  fontSize: 16,
                                ),
                              ),
                              Text(
                                '${item.price.toStringAsFixed(2)}€ × ${consumption.quantity}',
                                style: TextStyle(color: Colors.grey[600]),
                              ),
                            ],
                          ),
                        ),

                        // Contrôles de quantité
                        Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            IconButton(
                              icon: const Icon(Icons.remove_circle_outline),
                              onPressed:
                                  consumption.quantity > 1
                                      ? () {
                                        stockVM.updateConsumptionQuantity(
                                          consumption.id,
                                          consumption.quantity - 1,
                                        );
                                      }
                                      : null,
                            ),
                            SizedBox(
                              width: 40,
                              child: Text(
                                '${consumption.quantity}',
                                textAlign: TextAlign.center,
                                style: const TextStyle(
                                  fontSize: 16,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ),
                            IconButton(
                              icon: const Icon(Icons.add_circle_outline),
                              onPressed:
                                  item.quantity > 0
                                      ? () {
                                        stockVM.updateConsumptionQuantity(
                                          consumption.id,
                                          consumption.quantity + 1,
                                        );
                                      }
                                      : null,
                            ),
                            IconButton(
                              icon: const Icon(Icons.delete_outline),
                              color: Colors.red,
                              onPressed: () {
                                stockVM.cancelConsumption(consumption.id);
                              },
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                );
              }),
            ],

            Padding(
              padding: EdgeInsets.zero,
              child: FilledButton.tonalIcon(
                onPressed: () => _showAddConsumptionDialog(context, stockVM),
                icon: const Icon(Icons.add_circle, size: 24),
                label: const Text(
                  'Nouvelle consommation',
                  style: TextStyle(fontWeight: FontWeight.bold),
                ),
                style: FilledButton.styleFrom(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 12,
                  ),
                ),
              ),
            ),
          ],
        );
      },
    );
  }
}
