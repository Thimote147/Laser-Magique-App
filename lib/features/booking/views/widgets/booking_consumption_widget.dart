import 'package:flutter/material.dart';
import '../../models/booking_model.dart';
import '../../../../shared/models/consumption_model.dart';
import '../../../inventory/models/stock_item_model.dart';
import '../../controllers/booking_consumption_controller.dart';

class BookingConsumptionWidget extends StatefulWidget {
  final Booking booking;
  final VoidCallback? onBookingUpdated;

  const BookingConsumptionWidget({
    super.key,
    required this.booking,
    this.onBookingUpdated,
  });

  @override
  State<BookingConsumptionWidget> createState() => _BookingConsumptionWidgetState();
}

class _BookingConsumptionWidgetState extends State<BookingConsumptionWidget> {
  late BookingConsumptionController controller;
  bool _isInitialized = false;

  // Build count par booking ID pour debugging
  static final Map<String, int> _buildCounts = {};
  
  int get _currentBuildCount {
    final bookingId = widget.booking.id;
    _buildCounts[bookingId] = (_buildCounts[bookingId] ?? 0) + 1;
    return _buildCounts[bookingId]!;
  }

  @override
  void initState() {
    super.initState();
    
    // Pré-initialiser le service de prix IMMÉDIATEMENT pour éviter la fluctuation
    BookingConsumptionController.preInitializePriceService(context, widget.booking.id);
    
    controller = BookingConsumptionController.forBooking(widget.booking.id);
    _initializeController();
  }

  void _initializeController() async {
    if (!_isInitialized) {
      _isInitialized = true;
      if (mounted) {
        await controller.initialize(context);
        // Force sync une seule fois après l'initialisation
        if (mounted) {
          await controller.forceSyncWithPriceService(context);
        }
      }
    }
  }

  @override
  void didUpdateWidget(BookingConsumptionWidget oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.booking.id != widget.booking.id) {
      controller = BookingConsumptionController.forBooking(widget.booking.id);
      _isInitialized = false;
      _initializeController();
    }
  }

  @override
  Widget build(BuildContext context) {
    final buildCount = _currentBuildCount;
    
    // Log si rebuilds multiples détectés
    if (buildCount > 1) {
      debugPrint('BookingConsumptionWidget (${widget.booking.id}): Rebuild #$buildCount');
    }
    
    return _buildContent(context, controller);
  }

  @override
  void dispose() {
    // Note: On ne dispose pas le controller ici car il est géré globalement
    // Le controller se nettoie automatiquement quand plus personne ne l'utilise
    super.dispose();
  }
  
  Widget _buildContent(BuildContext context, BookingConsumptionController controller) {
    return RepaintBoundary(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // En-tête avec montant total
          RepaintBoundary(
            child: _buildConsumptionHeader(context, controller),
          ),
          
          // Bouton d'ajout
          RepaintBoundary(
            child: _buildAddConsumptionButton(context),
          ),
          
          // Contenu principal avec gestion d'état
          RepaintBoundary(
            child: ValueListenableBuilder<bool>(
              valueListenable: controller.isLoadingNotifier,
              builder: (context, isLoading, _) {
                if (isLoading) {
                  return Container(
                    margin: const EdgeInsets.only(top: 16),
                    padding: const EdgeInsets.symmetric(vertical: 20),
                    alignment: Alignment.center,
                    child: const SizedBox(
                      width: 24,
                      height: 24,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    ),
                  );
                }
                
                return ValueListenableBuilder<List<(Consumption, StockItem)>?>(
                  valueListenable: controller.consumptionsNotifier,
                  builder: (context, consumptions, _) {
                    if (consumptions == null || consumptions.isEmpty) {
                      return const SizedBox.shrink();
                    }
                    
                    return _buildConsumptionsList(context, consumptions, controller);
                  },
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildConsumptionHeader(BuildContext context, BookingConsumptionController controller) {
    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        color: Theme.of(context)
            .colorScheme
            .surfaceContainerHighest
            .withValues(alpha: 0.3),
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
                ValueListenableBuilder<double>(
                  valueListenable: controller.totalAmountNotifier,
                  builder: (context, amount, _) {
                    return Text(
                      '${amount.toStringAsFixed(2)}€',
                      style: Theme.of(context).textTheme.titleLarge?.copyWith(
                        fontWeight: FontWeight.w500,
                      ),
                    );
                  },
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildAddConsumptionButton(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(top: 12),
      child: OutlinedButton.icon(
        onPressed: () {
          // Logique d'ajout simplifié
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Fonctionnalité d\'ajout en cours de développement')),
          );
        },
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
    BookingConsumptionController controller,
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

          return _ConsumptionItemStateless(
            key: ValueKey('consumption_item_${consumption.id}'),
            consumption: consumption,
            stockItem: stockItem,
            controller: controller,
          );
        }),
      ],
    );
  }
}

// Widget d'item de consommation stateless
class _ConsumptionItemStateless extends StatelessWidget {
  final Consumption consumption;
  final StockItem stockItem;
  final BookingConsumptionController controller;

  const _ConsumptionItemStateless({
    super.key,
    required this.consumption,
    required this.stockItem,
    required this.controller,
  });

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
    final quantityNotifier = controller.getQuantityNotifier(
      consumption.id, 
      consumption.quantity,
    );

    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      decoration: BoxDecoration(
        color: Theme.of(context)
            .colorScheme
            .surfaceContainerHighest
            .withValues(alpha: 0.3),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: Theme.of(context)
                    .colorScheme
                    .primary
                    .withValues(alpha: 0.1),
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
                ValueListenableBuilder<int>(
                  valueListenable: quantityNotifier,
                  builder: (context, quantity, _) {
                    return Material(
                      type: MaterialType.transparency,
                      child: IconButton(
                        icon: Icon(
                          quantity > 1 ? Icons.remove : Icons.delete_outline,
                          size: 20,
                          color: quantity > 1
                              ? Theme.of(context).colorScheme.primary
                              : Theme.of(context).colorScheme.error,
                        ),
                        onPressed: () async {
                          if (quantity > 1) {
                            controller.updateConsumptionQuantity(
                              context,
                              consumption.id,
                              quantity - 1,
                            );
                          } else {
                            // Demander confirmation avant suppression
                            final confirmed = await showDialog<bool>(
                              context: context,
                              builder: (context) => AlertDialog(
                                title: const Text('Supprimer la consommation ?'),
                                content: Text(
                                  'Voulez-vous vraiment supprimer "${stockItem.name}" de cette réservation ?',
                                ),
                                actions: [
                                  TextButton(
                                    onPressed: () => Navigator.of(context).pop(false),
                                    child: const Text('Annuler'),
                                  ),
                                  TextButton(
                                    onPressed: () => Navigator.of(context).pop(true),
                                    style: TextButton.styleFrom(
                                      foregroundColor: Theme.of(context).colorScheme.error,
                                    ),
                                    child: const Text('Supprimer'),
                                  ),
                                ],
                              ),
                            );
                            
                            if (confirmed == true && context.mounted) {
                              // Supprimer la consommation
                              try {
                                await controller.deleteConsumption(
                                  context,
                                  consumption.id,
                                );
                                
                                // Afficher un message de succès
                                if (context.mounted) {
                                  ScaffoldMessenger.of(context).showSnackBar(
                                    SnackBar(
                                      content: Text('${stockItem.name} supprimé'),
                                      backgroundColor: Theme.of(context).colorScheme.primary,
                                      duration: const Duration(seconds: 2),
                                    ),
                                  );
                                }
                              } catch (e) {
                                // Afficher un message d'erreur
                                if (context.mounted) {
                                  ScaffoldMessenger.of(context).showSnackBar(
                                    SnackBar(
                                      content: Text('Erreur lors de la suppression: $e'),
                                      backgroundColor: Theme.of(context).colorScheme.error,
                                      duration: const Duration(seconds: 3),
                                    ),
                                  );
                                }
                              }
                            }
                          }
                        },
                        padding: EdgeInsets.zero,
                        style: IconButton.styleFrom(
                          minimumSize: const Size(32, 32),
                          tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                        ),
                      ),
                    );
                  },
                ),
                const SizedBox(width: 4),
                ValueListenableBuilder<int>(
                  valueListenable: quantityNotifier,
                  builder: (context, quantity, _) {
                    return Text(
                      '$quantity',
                      style: const TextStyle(
                        fontWeight: FontWeight.w500,
                        fontSize: 15,
                      ),
                    );
                  },
                ),
                const SizedBox(width: 4),
                ValueListenableBuilder<int>(
                  valueListenable: quantityNotifier,
                  builder: (context, quantity, _) {
                    return Material(
                      type: MaterialType.transparency,
                      child: IconButton(
                        icon: Icon(
                          Icons.add,
                          size: 20,
                          color: Theme.of(context).colorScheme.primary,
                        ),
                        onPressed: () {
                          controller.updateConsumptionQuantity(
                            context,
                            consumption.id,
                            quantity + 1,
                          );
                        },
                        padding: EdgeInsets.zero,
                        style: IconButton.styleFrom(
                          minimumSize: const Size(32, 32),
                          tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                        ),
                      ),
                    );
                  },
                ),
                const SizedBox(width: 12),
                ValueListenableBuilder<int>(
                  valueListenable: quantityNotifier,
                  builder: (context, quantity, _) {
                    return Text(
                      '${(quantity * consumption.unitPrice).toStringAsFixed(2)}€',
                      style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.w500,
                      ),
                    );
                  },
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}