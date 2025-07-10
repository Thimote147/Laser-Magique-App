import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../models/booking_model.dart';
import '../../../../shared/models/consumption_model.dart';
import '../../../inventory/models/stock_item_model.dart';
import '../../../inventory/viewmodels/stock_view_model.dart';
import '../../controllers/booking_consumption_controller.dart';
import 'consumption_selector.dart';
import '../../../../shared/widgets/custom_dialog.dart';

// Fonction utilitaire pour vérifier si une réservation est passée
bool _isBookingPast(Booking booking) {
  final now = DateTime.now();
  final bookingDate = booking.dateTimeLocal;
  return bookingDate.isBefore(DateTime(now.year, now.month, now.day));
}

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
    BookingConsumptionController.preInitializePriceService(
      context,
      widget.booking.id,
    );

    controller = BookingConsumptionController.forBooking(widget.booking.id);
    _initializeController();
  }

  void _initializeController() async {
    debugPrint('_initializeController appelé - isInitialized: $_isInitialized');
    if (!_isInitialized) {
      _isInitialized = true;
      if (mounted) {
        debugPrint('Appel de controller.reset');
        await controller.reset(context);

        // Forcer un rebuild après l'initialisation pour s'assurer que les données sont affichées
        if (mounted) {
          setState(() {
            debugPrint('setState appelé dans _initializeController');
          });
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
      debugPrint(
        'BookingConsumptionWidget (${widget.booking.id}): Rebuild #$buildCount',
      );
    }

    return _buildContent(context, controller);
  }

  @override
  void dispose() {
    // Note: On ne dispose pas le controller ici car il est géré globalement
    // Le controller se nettoie automatiquement quand plus personne ne l'utilise
    super.dispose();
  }

  Widget _buildContent(
    BuildContext context,
    BookingConsumptionController controller,
  ) {
    return RepaintBoundary(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // En-tête avec montant total
          RepaintBoundary(child: _buildConsumptionHeader(context, controller)),

          // Bouton d'ajout
          RepaintBoundary(child: _buildAddConsumptionButton(context)),

          // Contenu principal avec gestion d'état
          RepaintBoundary(
            child: ValueListenableBuilder<bool>(
              valueListenable: controller.isLoadingNotifier,
              builder: (context, isLoading, _) {
                debugPrint(
                  'isLoading: $isLoading pour booking ${widget.booking.id}',
                );
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
                    debugPrint(
                      'Consommations notifier: ${consumptions?.length ?? 0} items pour booking ${widget.booking.id}',
                    );
                    if (consumptions == null || consumptions.isEmpty) {
                      return const SizedBox.shrink();
                    } 

                    return _buildConsumptionsList(
                      context,
                      consumptions,
                      controller,
                    );
                  },
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildConsumptionHeader(
    BuildContext context,
    BookingConsumptionController controller,
  ) {
    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        color: Theme.of(
          context,
        ).colorScheme.surfaceContainerHighest.withValues(alpha: 0.3),
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
    if (_isBookingPast(widget.booking)) {
      return const SizedBox.shrink();
    }

    return Container(
      margin: const EdgeInsets.only(top: 12),
      child: OutlinedButton.icon(
        onPressed: () => _showConsumptionSelector(context),
        icon: const Icon(Icons.add),
        label: const Text('Nouvelle consommation'),
        style: OutlinedButton.styleFrom(
          minimumSize: const Size(double.infinity, 48),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
        ),
      ),
    );
  }

  void _showConsumptionSelector(BuildContext context) async {
    try {
      final stockVM = Provider.of<StockViewModel>(context, listen: false);

      // Forcer l'initialisation et le refresh du stock
      if (!stockVM.isInitialized) {
        await stockVM.initialize();
      } else {
        // Même si initialisé, rafraîchir le stock pour s'assurer d'avoir les dernières données
        await stockVM.refreshStock(silent: true);
      }

      // Vérifier qu'on a bien des articles
      debugPrint('StockViewModel - drinks: ${stockVM.drinks.length}, food: ${stockVM.food.length}, others: ${stockVM.others.length}');

      // Afficher le sélecteur de consommation
      if (context.mounted) {
        showModalBottomSheet(
          context: context,
        isScrollControlled: true,
        backgroundColor: Colors.transparent,
        builder: (buildContext) {
          return ConsumptionSelector(
            // Force cast to ensure the type is consistent
            stockVM: stockVM as dynamic,
            onConsumptionSelected: (stockItemId) async {
              if (stockItemId.isNotEmpty) {
                Navigator.of(buildContext).pop();
                // Utiliser le contexte principal au lieu du contexte du bottom sheet
                if (context.mounted) {
                  await _addConsumption(context, stockItemId);
                }
              }
            },
          );
        },
      );
      }
    } catch (e) {
      if (context.mounted) {
        showDialog(
          context: context,
          builder: (context) => CustomErrorDialog(
            title: 'Erreur',
            content: 'Erreur lors du chargement des articles: $e',
          ),
        );
      }
    }
  }

  Future<void> _addConsumption(BuildContext context, String stockItemId) async {
    try {
      final stockVM = Provider.of<StockViewModel>(context, listen: false);

      // Trouver l'article sélectionné avec la méthode dédiée
      final stockItem = stockVM.findStockItemById(stockItemId);

      if (stockItem == null) {
        throw Exception('Article non trouvé (ID: $stockItemId)');
      }

      debugPrint('Ajout de consommation: ${stockItem.name} (ID: $stockItemId)');

      // Ajouter la consommation via le ViewModel
      final success = await stockVM.addConsumption(
        bookingId: widget.booking.id,
        stockItemId: stockItemId,
        quantity: 1,
      );

      debugPrint('Résultat de l\'ajout: ${success ? "Succès" : "Échec"}');

      if (success && context.mounted) {
        debugPrint('Réinitialisation complète du controller après ajout');

        // Réinitialiser complètement le controller avec la nouvelle méthode
        await controller.reset(context);

        // Forcer un rebuild après la réinitialisation
        if (mounted) {
          setState(() {
            debugPrint('setState appelé après réinitialisation du controller');
          });
        }

        // Notifier le parent que la réservation a été mise à jour
        widget.onBookingUpdated?.call();
      } else if (!success && context.mounted) {
        showDialog(
          context: context,
          builder: (context) => CustomErrorDialog(
            title: 'Erreur',
            content: 'Erreur lors de l\'ajout de la consommation',
          ),
        );
      }
    } catch (e) {
      debugPrint('Erreur lors de l\'ajout: $e');
      if (context.mounted) {
        showDialog(
          context: context,
          builder: (context) => CustomErrorDialog(
            title: 'Erreur',
            content: 'Erreur lors de l\'ajout: $e',
          ),
        );
      }
    }
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
            booking: widget.booking,
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
  final Booking booking;

  const _ConsumptionItemStateless({
    super.key,
    required this.consumption,
    required this.stockItem,
    required this.controller,
    required this.booking,
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
        color: Theme.of(
          context,
        ).colorScheme.surfaceContainerHighest.withValues(alpha: 0.3),
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
                ).colorScheme.primary.withValues(alpha: 0.1),
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
            _isBookingPast(booking) 
                ? Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      ValueListenableBuilder<int>(
                        valueListenable: quantityNotifier,
                        builder: (context, quantity, _) {
                          return Container(
                            constraints: const BoxConstraints(minWidth: 32),
                            alignment: Alignment.center,
                            child: Text(
                              '$quantity',
                              style: const TextStyle(
                                fontWeight: FontWeight.w600,
                                fontSize: 18,
                              ),
                            ),
                          );
                        },
                      ),
                      const SizedBox(width: 60),
                      ValueListenableBuilder<int>(
                        valueListenable: quantityNotifier,
                        builder: (context, quantity, _) {
                          return Text(
                            '${consumption.copyWith(quantity: quantity).totalPrice.toStringAsFixed(2)}€',
                            style: Theme.of(context).textTheme.titleMedium?.copyWith(
                              fontWeight: FontWeight.w500,
                            ),
                          );
                        },
                      ),
                    ],
                  )
                : Row(
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
                                size: 24,
                                color:
                                    quantity > 1
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
                                    builder:
                                        (context) => CustomConfirmDialog(
                                          title: 'Supprimer la consommation ?',
                                          content: 'Voulez-vous vraiment supprimer "${stockItem.name}" de cette réservation ?',
                                          confirmText: 'SUPPRIMER',
                                          cancelText: 'ANNULER',
                                          icon: Icons.delete_forever,
                                          iconColor: Colors.red,
                                          confirmColor: Colors.red,
                                          onConfirm: () => Navigator.of(context).pop(true),
                                          onCancel: () => Navigator.of(context).pop(false),
                                        ),
                                  );

                                  if (confirmed == true && context.mounted) {
                                    // Supprimer la consommation
                                    try {
                                      await controller.deleteConsumption(
                                        context,
                                        consumption.id,
                                      );

                                      // Forcer un refresh complet après la suppression
                                      if (context.mounted) {
                                        await controller.reset(context);
                                      }

                                      // Afficher le dialog de succès
                                      if (context.mounted) {
                                        await showDialog(
                                          context: context,
                                          barrierDismissible: true,
                                          builder: (context) => CustomSuccessDialog(
                                            title: 'Suppression réussie',
                                            content: '${stockItem.name} a été supprimé de la réservation',
                                            autoClose: true,
                                            autoCloseDuration: const Duration(seconds: 2),
                                          ),
                                        );
                                      }
                                    } catch (e) {
                                      // Afficher un dialog d'erreur
                                      if (context.mounted) {
                                        await showDialog(
                                          context: context,
                                          builder: (context) => CustomErrorDialog(
                                            title: 'Erreur de suppression',
                                            content: 'Erreur lors de la suppression: $e',
                                          ),
                                        );
                                      }
                                    }
                                  }
                                }
                              },
                              padding: EdgeInsets.zero,
                              style: IconButton.styleFrom(
                                minimumSize: const Size(40, 40),
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
                          return Container(
                            constraints: const BoxConstraints(minWidth: 32),
                            alignment: Alignment.center,
                            child: Text(
                              '$quantity',
                              style: const TextStyle(
                                fontWeight: FontWeight.w600,
                                fontSize: 18,
                              ),
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
                                size: 24,
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
                                minimumSize: const Size(40, 40),
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
                            '${consumption.copyWith(quantity: quantity).totalPrice.toStringAsFixed(2)}€',
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
