import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../models/booking_model.dart';
import '../../../../shared/models/consumption_model.dart';
import '../../../../shared/services/consumption_price_service.dart';
import '../../../inventory/models/stock_item_model.dart';
import '../../../inventory/viewmodels/stock_view_model.dart';
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
  // Map pour suivre les quantités localement (ID de consommation -> quantité)
  final Map<String, ValueNotifier<int>> _quantityNotifiers = {};

  // Service pour notifier les changements de prix des consommations
  final ConsumptionPriceService _priceService = ConsumptionPriceService();

  @override
  void initState() {
    super.initState();
    _currentBooking = widget.booking;
    _consumptionsFuture = null; // Invalider le cache au démarrage

    // Initialiser le service de prix immédiatement sans attendre le prochain frame
    try {
      final stockVM = Provider.of<StockViewModel>(context, listen: false);
      final consumptionsTotal = stockVM.getConsumptionTotal(_currentBooking.id);
      _priceService.updateConsumptionPrice(
        _currentBooking.id,
        consumptionsTotal,
      );

      // Rafraîchir les données immédiatement
      _refreshBookingData();

      // Précharger les consommations en dehors du cycle de build
      _preloadConsumptions();
    } catch (e) {
      // En cas d'erreur, programmer pour après le premier build
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) {
          _refreshBookingData();
          _preloadConsumptions();
        }
      });
    }
  }

  @override
  void didUpdateWidget(BookingConsumptionWidget oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.booking.id != widget.booking.id ||
        oldWidget.booking != widget.booking) {
      // Mise à jour immédiate dans tous les cas
      _currentBooking = widget.booking;
      _consumptionsFuture = null; // Invalider le cache

      // Rafraîchir les données immédiatement
      try {
        _refreshBookingData();
      } catch (e) {
        // Ignorer l'erreur
      }
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
        // Vérifier si la réservation a réellement changé pour éviter des mises à jour inutiles
        final hasChanged = _currentBooking != updatedBooking;

        setState(() {
          _currentBooking = updatedBooking;
          // Invalider le cache seulement si la réservation a changé
          if (hasChanged) {
            _consumptionsFuture = null;
          }
        });

        // Mettre à jour le service de prix APRÈS le setState
        if (mounted) {
          final stockVM = Provider.of<StockViewModel>(context, listen: false);
          final consumptionsTotal = stockVM.getConsumptionTotal(
            _currentBooking.id,
          );

          // Mise à jour immédiate et synchrone de tout
          _immediateUpdate(consumptionsTotal);
        }
      }
    } catch (e) {
      // Silent error handling
    }
  }

  // Pré-charge les consommations en dehors du cycle de build
  void _preloadConsumptions() {
    if (_consumptionsFuture == null && mounted) {
      final stockVM = Provider.of<StockViewModel>(context, listen: false);
      // Exécuter cela en dehors du cycle de build
      Future.microtask(() async {
        if (!mounted) return;
        try {
          final consumptions = await stockVM.getConsumptionsWithStockItems(
            _currentBooking.id,
          );
          if (!mounted) return;

          setState(() {
            _consumptionsFuture = Future.value(consumptions);
          });

          // Mettre à jour immédiatement le montant total
          final totalAmount = stockVM.calculateConsumptionTotal(consumptions);
          _immediateUpdate(totalAmount);
        } catch (e) {
          // Gérer les erreurs silencieusement
        }
      });

      // Créer une future temporaire vide pour éviter de multiples chargements
      _consumptionsFuture = Future.value([]);
    }
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
                  // Fermer le sélecteur immédiatement pour une meilleure UX
                  if (context.mounted) {
                    Navigator.pop(context);
                  }

                  // Afficher un indicateur de chargement optimiste
                  if (mounted) {
                    setState(() {
                      // Indiquer visuellement que l'opération est en cours
                    });
                  }

                  final success = await stockVM.addConsumption(
                    bookingId: _currentBooking.id,
                    stockItemId: stockItemId,
                    quantity: 1,
                  );

                  if (!mounted) return;

                  if (!success) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                        content: Text(
                          'Stock insuffisant pour cette consommation.',
                        ),
                        backgroundColor: Colors.orange,
                      ),
                    );
                    return;
                  }

                  // Obtenir le nouveau montant total immédiatement après l'ajout
                  final newConsumptions = await stockVM
                      .getConsumptionsWithStockItems(_currentBooking.id);
                  final newTotalAmount = stockVM.calculateConsumptionTotal(
                    newConsumptions,
                  );

                  // Mise à jour immédiate et synchrone de tout
                  _immediateUpdate(newTotalAmount);

                  // Invalider le cache et rafraîchir l'affichage
                  _consumptionsFuture = null;
                  _refreshData();
                } catch (e) {
                  if (!context.mounted) return;
                  Navigator.pop(context);
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text('Erreur:  ${e.toString()}'),
                      backgroundColor: Colors.red,
                    ),
                  );
                }
              },
            ),
          ),
    );
  }

  // ValueNotifier pour le montant total
  final ValueNotifier<double> _totalAmountNotifier = ValueNotifier<double>(0);

  Widget _buildConsumptionHeader(BuildContext context, double totalAmount) {
    // Mettre à jour le montant total uniquement si différent
    // Cela évite les rafraîchissements en cascade et les boucles infinies
    if (_totalAmountNotifier.value != totalAmount) {
      _totalAmountNotifier.value = totalAmount;
    }

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
                  valueListenable: _totalAmountNotifier,
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

  // Obtenir ou créer un ValueNotifier pour une consommation spécifique
  ValueNotifier<int> _getQuantityNotifier(
    String consumptionId,
    int initialQuantity,
  ) {
    if (!_quantityNotifiers.containsKey(consumptionId)) {
      _quantityNotifiers[consumptionId] = ValueNotifier<int>(initialQuantity);
    }
    return _quantityNotifiers[consumptionId]!;
  }

  // Nettoyer les notifiers inutilisés
  void _cleanupNotifiers(List<(Consumption, StockItem)> currentConsumptions) {
    final currentIds = currentConsumptions.map((pair) => pair.$1.id).toSet();
    final obsoleteIds =
        _quantityNotifiers.keys
            .where((id) => !currentIds.contains(id))
            .toList();

    for (final id in obsoleteIds) {
      _quantityNotifiers[id]?.dispose();
      _quantityNotifiers.remove(id);
    }
  }

  // Clé unique pour la réservation actuelle, mais pas pour chaque rebuild
  final ValueNotifier<int> _refreshCounter = ValueNotifier<int>(0);
  // Cache pour la future des consommations
  Future<List<(Consumption, StockItem)>>? _consumptionsFuture;

  // Force un rafraîchissement des données sans recréer toute la vue
  // Utilise un timestamp pour éviter les rafraîchissements trop fréquents
  int _lastRefreshTime = 0;
  void _refreshData({bool preserveCache = false}) {
    // Éviter les rafraîchissements trop fréquents (moins de 100ms entre chaque)
    final now = DateTime.now().millisecondsSinceEpoch;
    if (now - _lastRefreshTime < 100) {
      // Ignorer les rafraîchissements trop fréquents pour éviter les boucles
      return;
    }
    _lastRefreshTime = now;

    // Mise à jour immédiate sans microtask
    if (mounted) {
      if (!preserveCache) {
        _consumptionsFuture =
            null; // Invalider le cache seulement si nécessaire
        _preloadConsumptions(); // Précharger immédiatement
      }

      // Pour les modifications de quantité, éviter d'incrémenter le compteur
      // qui forcerait une reconstruction complète de la section
      if (!preserveCache) {
        _refreshCounter.value++;
      }
    }
  }

  // Nettoyer tous les notifiers pour éviter les fuites de mémoire
  @override
  void dispose() {
    for (final notifier in _quantityNotifiers.values) {
      notifier.dispose();
    }
    _quantityNotifiers.clear();
    _totalAmountNotifier.dispose();
    _refreshCounter.dispose();

    // Nettoyer le notifier de prix des consommations
    _priceService.cleanupNotifier(_currentBooking.id);

    super.dispose();
  }

  // Méthode pour notifier le parent des changements sans provoquer un rafraîchissement complet
  void _notifyParentWithoutRefresh() {
    // Notification immédiate sans microtask
    if (widget.onBookingUpdated != null && mounted) {
      widget.onBookingUpdated!.call();
    }
  }

  // Méthode de mise à jour immédiate et synchrone pour toutes les dépendances
  void _immediateUpdate(double totalAmount) {
    // Éviter la mise à jour si la valeur n'a pas changé pour briser la boucle infinie
    final currentValue = _totalAmountNotifier.value;
    final serviceValue =
        _priceService.getNotifierForBooking(_currentBooking.id).value;

    // Ne rien faire si les deux valeurs sont déjà à jour
    if (currentValue == totalAmount && serviceValue == totalAmount) {
      return;
    }

    // 1. Mettre à jour le notifier local
    if (currentValue != totalAmount) {
      _totalAmountNotifier.value = totalAmount;
    }

    // 2. Mettre à jour le service de prix - uniquement si nécessaire
    if (serviceValue != totalAmount) {
      _priceService.updateConsumptionPrice(_currentBooking.id, totalAmount);
    }

    // 3. Notifier le parent immédiatement si nécessaire
    if (widget.onBookingUpdated != null && mounted) {
      widget.onBookingUpdated!.call();
    }
  }

  // Helper pour obtenir la liste des consommations mise à jour avec les quantités locales
  List<(Consumption, StockItem)> _getUpdatedConsumptions(
    List<(Consumption, StockItem)> consumptions,
  ) {
    // Créer une copie pour éviter de modifier la liste originale
    final updatedConsumptions = List<(Consumption, StockItem)>.from(
      consumptions,
    );

    // Mettre à jour les quantités en fonction des notifiers locaux
    for (int i = 0; i < updatedConsumptions.length; i++) {
      final pair = updatedConsumptions[i];
      final consumption = pair.$1;
      final stockItem = pair.$2;

      // Vérifier si un notifier existe pour cette consommation
      if (_quantityNotifiers.containsKey(consumption.id)) {
        // Obtenir la quantité actuelle du notifier
        final currentQuantity = _quantityNotifiers[consumption.id]!.value;

        // Si la quantité a changé, créer une copie mise à jour de la consommation
        if (currentQuantity != consumption.quantity) {
          final updatedConsumption = Consumption(
            id: consumption.id,
            bookingId: consumption.bookingId,
            stockItemId: consumption.stockItemId,
            quantity: currentQuantity,
            unitPrice: consumption.unitPrice,
            timestamp: consumption.timestamp,
          );

          // Remplacer la paire dans la liste
          updatedConsumptions[i] = (updatedConsumption, stockItem);
        }
      }
    }

    return updatedConsumptions;
  }

  // Gestionnaire pour les changements de quantité
  void _handleQuantityChanged(
    BuildContext context,
    Consumption consumption,
    StockItem stockItem,
    int newQuantity,
    List<(Consumption, StockItem)> allConsumptions,
  ) {
    try {
      final stockVM = Provider.of<StockViewModel>(context, listen: false);

      // Obtenir le notifier pour cette consommation
      final quantityNotifier = _getQuantityNotifier(
        consumption.id,
        consumption.quantity,
      );

      // Mettre à jour l'UI immédiatement
      quantityNotifier.value = newQuantity;

      // Calculer et mettre à jour le montant total immédiatement
      final updatedConsumptions = _getUpdatedConsumptions(allConsumptions);
      final totalAmount = stockVM.calculateConsumptionTotal(
        updatedConsumptions,
      );
      _immediateUpdate(totalAmount);

      // Ne plus faire de rafraîchissement UI ici
      // La mise à jour du notifier suffira à actualiser l'interface

      // Mettre à jour en base de données en arrière-plan
      stockVM
          .updateConsumptionQuantity(
            consumption: consumption,
            newQuantity: newQuantity,
          )
          .then((_) {
            // Uniquement notifier le parent sans rafraîchir l'UI
            _notifyParentWithoutRefresh();
          })
          .catchError((e) {
            if (!mounted) return;
            // Restaurer la valeur précédente en cas d'erreur
            quantityNotifier.value = consumption.quantity;
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text(e.toString()),
                backgroundColor: Colors.orange,
              ),
            );
          });
    } catch (e) {
      if (!context.mounted) return;
      // Restaurer la valeur précédente en cas d'erreur
      final quantityNotifier = _getQuantityNotifier(
        consumption.id,
        consumption.quantity,
      );
      quantityNotifier.value = consumption.quantity;

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(e.toString()), backgroundColor: Colors.orange),
      );
    }
  }

  // Construction de la liste des consommations avec isolation pour les mises à jour individuelles
  Widget _buildConsumptionsList(
    BuildContext context,
    List<(Consumption, StockItem)> consumptions,
  ) {
    // S'assurer que les notifiers sont correctement initialisés
    for (final pair in consumptions) {
      final consumption = pair.$1;
      _getQuantityNotifier(consumption.id, consumption.quantity);
    }

    // Nettoyer les notifiers obsolètes
    _cleanupNotifiers(consumptions);

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

          // Créer ou obtenir le notifier pour cette consommation
          final quantityNotifier = _getQuantityNotifier(
            consumption.id,
            consumption.quantity,
          );

          return _ConsumptionItem(
            key: ValueKey('consumption_item_${consumption.id}'),
            consumption: consumption,
            stockItem: stockItem,
            quantityNotifier: quantityNotifier,
            getItemIcon: _getItemIcon,
            onQuantityChanged:
                (newQuantity) => _handleQuantityChanged(
                  context,
                  consumption,
                  stockItem,
                  newQuantity,
                  consumptions,
                ),
            onConsumptionDeleted:
                () => _handleConsumptionDeleted(
                  context,
                  consumption,
                  consumptions,
                ),
          );
        }).toList(),
      ],
    );
  }

  // Gestionnaire pour la suppression d'une consommation
  void _handleConsumptionDeleted(
    BuildContext context,
    Consumption consumption,
    List<(Consumption, StockItem)> allConsumptions,
  ) async {
    try {
      final stockVM = Provider.of<StockViewModel>(context, listen: false);

      // Optimistic UI update
      final updatedConsumptions = List<(Consumption, StockItem)>.from(
        allConsumptions,
      );
      updatedConsumptions.removeWhere((pair) => pair.$1.id == consumption.id);

      // Calculer et mettre à jour le montant total immédiatement
      final totalAmount = stockVM.calculateConsumptionTotal(
        updatedConsumptions,
      );
      _immediateUpdate(totalAmount);

      // Supprimer en base de données en arrière-plan
      await stockVM.deleteConsumption(consumption: consumption);

      if (!mounted) return;

      // Nettoyer le notifier
      if (_quantityNotifiers.containsKey(consumption.id)) {
        _quantityNotifiers[consumption.id]?.dispose();
        _quantityNotifiers.remove(consumption.id);
      }

      // Rafraîchir les données
      _consumptionsFuture = null;
      _refreshData();

      // Notifier le parent
      _notifyParentWithoutRefresh();
    } catch (e) {
      if (!context.mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Erreur: ${e.toString()}'),
          backgroundColor: Colors.orange,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<StockViewModel>(
      builder: (context, stockVM, _) {
        // Utiliser un ValueListenableBuilder uniquement pour forcer les rafraîchissements
        // explicites de l'ensemble du widget, mais pas pour les changements de quantité
        return ValueListenableBuilder<int>(
          valueListenable: _refreshCounter,
          builder: (context, refreshCount, _) {
            // Initialiser le future en dehors du build
            // Utiliser la méthode préchargée au lieu d'initialiser pendant le build
            if (_consumptionsFuture == null) {
              _preloadConsumptions();
            }

            return FutureBuilder<List<(Consumption, StockItem)>>(
              key: ValueKey('consumption_${_currentBooking.id}_$refreshCount'),
              future: _consumptionsFuture,
              builder: (context, snapshot) {
                // Variables pour stocker les données et le statut de chargement
                List<(Consumption, StockItem)> consumptions = [];
                bool isLoading =
                    snapshot.connectionState == ConnectionState.waiting &&
                    !snapshot.hasData;
                bool hasError = snapshot.hasError;

                // Si nous avons des données, les utiliser
                if (snapshot.hasData) {
                  consumptions = snapshot.data ?? [];
                  final totalAmount = stockVM.calculateConsumptionTotal(
                    consumptions,
                  );

                  // Mise à jour conditionnelle pour éviter les boucles infinies
                  // On ne met à jour que si les valeurs sont différentes
                  final currentNotifierValue = _totalAmountNotifier.value;
                  final currentServiceValue =
                      _priceService
                          .getNotifierForBooking(_currentBooking.id)
                          .value;

                  if (currentNotifierValue != totalAmount ||
                      currentServiceValue != totalAmount) {
                    _immediateUpdate(totalAmount);
                  }
                }

                // Construire l'interface utilisateur avec les composants qui ne doivent
                // pas être reconstruits à chaque changement de quantité
                return Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Toujours afficher l'en-tête, même pendant le chargement
                    _buildConsumptionHeader(
                      context,
                      isLoading
                          ? _priceService
                              .getNotifierForBooking(_currentBooking.id)
                              .value // Utiliser la dernière valeur connue
                          : _totalAmountNotifier.value,
                    ),
                    _buildAddConsumptionButton(context, stockVM),

                    // Afficher un indicateur de chargement si nécessaire
                    if (isLoading)
                      Container(
                        margin: const EdgeInsets.only(top: 16),
                        padding: const EdgeInsets.symmetric(vertical: 20),
                        alignment: Alignment.center,
                        child: const SizedBox(
                          width: 24,
                          height: 24,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        ),
                      )
                    // Afficher un message d'erreur si nécessaire
                    else if (hasError)
                      Container(
                        margin: const EdgeInsets.only(top: 16),
                        padding: const EdgeInsets.symmetric(vertical: 20),
                        alignment: Alignment.center,
                        child: Column(
                          children: [
                            Icon(
                              Icons.error_outline,
                              color: Theme.of(context).colorScheme.error,
                            ),
                            const SizedBox(height: 8),
                            Text(
                              'Erreur lors du chargement des consommations',
                              style: TextStyle(
                                color: Theme.of(context).colorScheme.error,
                              ),
                            ),
                            TextButton(
                              onPressed: () => _refreshData(),
                              child: const Text('Réessayer'),
                            ),
                          ],
                        ),
                      )
                    // Afficher la liste des consommations si disponible,
                    // mais en utilisant une clé qui ne dépend pas du refreshCount
                    // pour éviter de reconstruire la liste à chaque mise à jour
                    else if (consumptions.isNotEmpty)
                      RepaintBoundary(
                        child: KeyedSubtree(
                          key: ValueKey(
                            'consumption_list_${_currentBooking.id}',
                          ),
                          child: _buildConsumptionsList(context, consumptions),
                        ),
                      ),
                  ],
                );
              },
            );
          },
        );
      },
    );
  }
}

class _ConsumptionItem extends StatelessWidget {
  final Consumption consumption;
  final StockItem stockItem;
  final ValueNotifier<int> quantityNotifier;
  final IconData Function(String) getItemIcon;
  final ValueChanged<int> onQuantityChanged;
  final VoidCallback onConsumptionDeleted;

  const _ConsumptionItem({
    super.key,
    required this.consumption,
    required this.stockItem,
    required this.quantityNotifier,
    required this.getItemIcon,
    required this.onQuantityChanged,
    required this.onConsumptionDeleted,
  });

  @override
  Widget build(BuildContext context) {
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
                getItemIcon(stockItem.category),
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
                          color:
                              quantity > 1
                                  ? Theme.of(context).colorScheme.primary
                                  : Theme.of(context).colorScheme.error,
                        ),
                        onPressed: () {
                          if (quantity > 1) {
                            // Décrémenter la quantité
                            onQuantityChanged(quantity - 1);
                          } else {
                            // Supprimer la consommation
                            onConsumptionDeleted();
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
                          // Incrémenter la quantité
                          onQuantityChanged(quantity + 1);
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
