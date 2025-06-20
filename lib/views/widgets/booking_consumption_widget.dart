import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../models/booking_model.dart';
import '../../models/consumption_model.dart';
import '../../models/stock_item_model.dart';
import '../../viewmodels/stock_view_model.dart';
import 'consumption_selector.dart';
import '../../viewmodels/booking_view_model.dart';

class BookingConsumptionWidget extends StatefulWidget {
  final Booking booking;
  final VoidCallback? onBookingUpdated;

  const BookingConsumptionWidget({
    super.key,
    required this.booking,
    this.onBookingUpdated,
  });

  @override
  State<BookingConsumptionWidget> createState() =>
      _BookingConsumptionWidgetState();
}

class _BookingConsumptionWidgetState extends State<BookingConsumptionWidget> {
  late Booking _currentBooking;

  @override
  void initState() {
    super.initState();
    _currentBooking = widget.booking;
    _refreshBookingData();
  }

  @override
  void didUpdateWidget(BookingConsumptionWidget oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.booking.id != widget.booking.id) {
      _currentBooking = widget.booking;
      _refreshBookingData();
    }
  }

  Future<void> _refreshBookingData() async {
    try {
      if (!mounted) return;
      final bookingViewModel = Provider.of<BookingViewModel>(
        context,
        listen: false,
      );
      final updatedBooking = await bookingViewModel.getBookingDetails(
        _currentBooking.id,
      );
      if (mounted) {
        setState(() {
          _currentBooking = updatedBooking;
        });
      }
    } catch (e) {
      // Silent error handling
    }
  }

  Future<List<(Consumption, StockItem)>> _getConsumptions() async {
    final stockVM = Provider.of<StockViewModel>(context, listen: false);

    // D'abord vérifier le cache
    final cached = stockVM.getCachedConsumptions(_currentBooking.id);
    if (cached != null) {
      return cached;
    }

    // Si pas en cache, attendre que StockViewModel soit initialisé
    while (!stockVM.isInitialized && mounted) {
      await Future.delayed(const Duration(milliseconds: 100));
    }

    return stockVM.getConsumptionsWithStockItems(_currentBooking.id);
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
              onConsumptionSelected: (stockItemId) async {
                try {
                  final success = await stockVM.addConsumption(
                    bookingId: _currentBooking.id,
                    stockItemId: stockItemId,
                    quantity: 1,
                  );

                  Navigator.pop(context);

                  if (!success) {
                    if (!context.mounted) return;
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                        content: Text(
                          'Stock insuffisant pour cette consommation.',
                        ),
                        backgroundColor: Colors.orange,
                      ),
                    );
                    return;
                  } // Force le refresh de la réservation après l'ajout d'une consommation
                  if (mounted) {
                    // Attendre 500ms pour laisser le temps à la base de données de se mettre à jour
                    await Future.delayed(const Duration(milliseconds: 500));
                    await _refreshBookingData(); // Rafraîchir les données après l'ajout
                    widget.onBookingUpdated?.call(); // Notifier le parent
                  }
                } catch (e) {
                  Navigator.pop(context);
                  if (!context.mounted) return;
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text('Erreur: ${e.toString()}'),
                      backgroundColor: Colors.red,
                    ),
                  );
                }
              },
            ),
          ),
    );
  }

  Widget _buildConsumptionHeader(BuildContext context, double totalAmount) {
    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surfaceVariant.withOpacity(0.3),
        borderRadius: BorderRadius.circular(8),
      ),
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Montant total',
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: Theme.of(context).colorScheme.onSurfaceVariant,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  '${totalAmount.toStringAsFixed(2)}€',
                  style: Theme.of(
                    context,
                  ).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.w500),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildAddConsumptionButton(
    BuildContext context,
    StockViewModel stockVM,
  ) {
    return Container(
      margin: const EdgeInsets.only(top: 12),
      child: OutlinedButton.icon(
        onPressed: () => _showAddConsumptionDialog(context, stockVM),
        icon: const Icon(Icons.add),
        label: const Text('Nouvelle consommation'),
        style: OutlinedButton.styleFrom(
          minimumSize: const Size(double.infinity, 48),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
        ),
      ),
    );
  }

  Widget _buildConsumptionsList(
    BuildContext context,
    List<(Consumption, StockItem)> consumptions,
  ) {
    if (consumptions.isEmpty) return const SizedBox.shrink();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const SizedBox(height: 16),
        Text(
          'Liste des consommations',
          style: Theme.of(context).textTheme.titleSmall?.copyWith(
            color: Theme.of(context).colorScheme.onSurfaceVariant,
            fontWeight: FontWeight.w600,
          ),
        ),
        const SizedBox(height: 8),
        ...consumptions.map((pair) {
          final consumption = pair.$1;
          final stockItem = pair.$2;

          return Container(
            margin: const EdgeInsets.only(bottom: 8),
            decoration: BoxDecoration(
              color: Theme.of(
                context,
              ).colorScheme.surfaceVariant.withOpacity(0.3),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Padding(
              padding: const EdgeInsets.all(12),
              child: Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: Theme.of(
                        context,
                      ).colorScheme.primary.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Icon(
                      _getItemIcon(stockItem.category),
                      color: Theme.of(context).colorScheme.primary,
                      size: 20,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      stockItem.name,
                      style: const TextStyle(
                        fontWeight: FontWeight.w500,
                        fontSize: 15,
                      ),
                    ),
                  ),
                  Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Material(
                        type: MaterialType.transparency,
                        child: IconButton(
                          icon: Icon(
                            consumption.quantity > 1
                                ? Icons.remove
                                : Icons.delete_outline,
                            size: 20,
                            color:
                                consumption.quantity > 1
                                    ? Theme.of(context).colorScheme.primary
                                    : Theme.of(context).colorScheme.error,
                          ),
                          onPressed: () async {
                            try {
                              final stockVM = Provider.of<StockViewModel>(
                                context,
                                listen: false,
                              );

                              if (consumption.quantity > 1) {
                                await stockVM.updateConsumptionQuantity(
                                  consumption: consumption,
                                  newQuantity: consumption.quantity - 1,
                                );
                              } else {
                                await stockVM.deleteConsumption(
                                  consumption: consumption,
                                );
                              }

                              // Notifier le parent immédiatement pour mettre à jour les totaux
                              widget.onBookingUpdated?.call();
                            } catch (e) {
                              if (!context.mounted) return;
                              ScaffoldMessenger.of(context).showSnackBar(
                                SnackBar(
                                  content: Text(e.toString()),
                                  backgroundColor: Colors.orange,
                                ),
                              );
                            }
                          },
                          padding: EdgeInsets.zero,
                          style: IconButton.styleFrom(
                            minimumSize: const Size(40, 40),
                            tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                          ),
                        ),
                      ),
                      const SizedBox(width: 4),
                      Text(
                        '${consumption.quantity}',
                        style: const TextStyle(
                          fontWeight: FontWeight.w500,
                          fontSize: 15,
                        ),
                      ),
                      const SizedBox(width: 4),
                      Material(
                        type: MaterialType.transparency,
                        child: IconButton(
                          icon: Icon(
                            Icons.add,
                            size: 20,
                            color: Theme.of(context).colorScheme.primary,
                          ),
                          onPressed: () async {
                            try {
                              final stockVM = Provider.of<StockViewModel>(
                                context,
                                listen: false,
                              );
                              await stockVM.updateConsumptionQuantity(
                                consumption: consumption,
                                newQuantity: consumption.quantity + 1,
                              );

                              // Notifier le parent immédiatement pour mettre à jour les totaux
                              widget.onBookingUpdated?.call();
                            } catch (e) {
                              if (!context.mounted) return;
                              ScaffoldMessenger.of(context).showSnackBar(
                                SnackBar(
                                  content: Text(e.toString()),
                                  backgroundColor: Colors.orange,
                                ),
                              );
                            }
                          },
                          padding: EdgeInsets.zero,
                          style: IconButton.styleFrom(
                            minimumSize: const Size(40, 40),
                            tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                          ),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Text(
                        '${(consumption.quantity * consumption.unitPrice).toStringAsFixed(2)}€',
                        style: Theme.of(context).textTheme.titleMedium
                            ?.copyWith(fontWeight: FontWeight.w500),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          );
        }).toList(),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<StockViewModel>(
      builder: (context, stockVM, _) {
        return FutureBuilder<List<(Consumption, StockItem)>>(
          future: _getConsumptions(),
          builder: (context, snapshot) {
            // Afficher un indicateur de chargement uniquement lors du premier chargement
            if (snapshot.connectionState == ConnectionState.waiting &&
                !snapshot.hasData) {
              return Container(
                decoration: BoxDecoration(
                  color: Theme.of(
                    context,
                  ).colorScheme.surfaceVariant.withOpacity(0.3),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: const Center(
                  child: Padding(
                    padding: EdgeInsets.symmetric(vertical: 20),
                    child: CircularProgressIndicator(),
                  ),
                ),
              );
            }

            final consumptions = snapshot.data ?? [];
            final totalAmount = stockVM.calculateConsumptionTotal(consumptions);

            return Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _buildConsumptionHeader(context, totalAmount),
                _buildAddConsumptionButton(context, stockVM),
                _buildConsumptionsList(context, consumptions),
              ],
            );
          },
        );
      },
    );
  }
}
