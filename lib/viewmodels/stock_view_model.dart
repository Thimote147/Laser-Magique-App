// filepath: /Users/thimotefetu/Sites/Laser-Magique-App/lib/viewmodels/stock_view_model.dart
import 'package:flutter/foundation.dart';
import '../models/stock_item_model.dart';
import '../models/consumption_model.dart';
import '../repositories/stock_repository.dart';

class StockViewModel extends ChangeNotifier {
  final StockRepository _repository = StockRepository();
  List<StockItem> _items = [];
  Map<String, List<Consumption>> _consumptionsPerBooking = {};
  String _searchQuery = '';
  bool _isLoading = true;
  String? _error;
  bool _initialized = false;

  StockViewModel() {
    _initializeData();
  }

  // Getters
  List<StockItem> get items => List.unmodifiable(_items);
  bool get isLoading => _isLoading;
  String? get error => _error;

  // Initialize data
  Future<void> _initializeData() async {
    if (_initialized) return;

    try {
      _isLoading = true;
      _error = null;
      notifyListeners();

      _items = await _repository.getAllStockItems();

      // Setup real-time subscription for stock items
      _repository.streamStockItems().listen(
        (items) {
          _items = items;
          notifyListeners();
        },
        onError: (e) {
          _error = 'Subscription error: $e';
          notifyListeners();
        },
      );

      _isLoading = false;
      _initialized = true;
      notifyListeners();
    } catch (e) {
      _error = 'Error loading data: $e';
      _isLoading = false;
      notifyListeners();
    }
  }

  // Filtered getters
  List<StockItem> get filteredItems =>
      _searchQuery.isEmpty
          ? _items
          : _items
              .where(
                (item) => item.name.toLowerCase().contains(
                  _searchQuery.toLowerCase(),
                ),
              )
              .toList();

  List<StockItem> get drinks =>
      filteredItems.where((item) => item.category == 'DRINK').toList();

  List<StockItem> get food =>
      filteredItems.where((item) => item.category == 'FOOD').toList();

  List<StockItem> get others =>
      filteredItems.where((item) => item.category == 'OTHER').toList();

  List<StockItem> get lowStockItems =>
      filteredItems.where((item) => item.isLowStock).toList();

  void subscribeToBookingConsumptions(String bookingId) {
    if (_consumptionsPerBooking.containsKey(bookingId)) return;

    _repository
        .streamConsumptions(bookingId)
        .listen(
          (consumptions) {
            _consumptionsPerBooking[bookingId] = consumptions;
            notifyListeners();
          },
          onError: (e) {
            _error = 'Error streaming consumptions: $e';
            notifyListeners();
          },
        );
  }

  Future<List<(Consumption, StockItem)>> getConsumptionsWithStockItems(
    String bookingId,
  ) async {
    if (!_initialized) {
      await _initializeData();
    }

    try {
      if (!_consumptionsPerBooking.containsKey(bookingId)) {
        final consumptions = await _repository.getConsumptionsForBooking(
          bookingId,
        );
        _consumptionsPerBooking[bookingId] = consumptions;
        // Subscribe for future updates
        subscribeToBookingConsumptions(bookingId);
      }

      final consumptions = _consumptionsPerBooking[bookingId] ?? [];

      return consumptions.map((consumption) {
        final stockItem = _items.firstWhere(
          (item) => item.id == consumption.stockItemId,
          orElse: () => throw Exception('Article introuvable'),
        );
        return (consumption, stockItem);
      }).toList();
    } catch (e) {
      _error = 'Erreur lors de la récupération des consommations: $e';
      notifyListeners();
      return [];
    }
  }

  // Search functionality
  void updateSearchQuery(String query) {
    _searchQuery = query;
    notifyListeners();
  }

  Future<bool> addConsumption({
    required String bookingId,
    required String stockItemId,
    required int quantity,
  }) async {
    try {
      final consumption = await _repository.addConsumption(
        bookingId: bookingId,
        stockItemId: stockItemId,
        quantity: quantity,
      );

      // Mettre à jour la liste des consommations si une nouvelle consommation a été créée
      // Ajouter la nouvelle consommation à la liste existante ou créer une nouvelle liste
      _consumptionsPerBooking[bookingId] = [
        ...(_consumptionsPerBooking[bookingId] ?? []),
        consumption,
      ];
      notifyListeners();
      return true;
    } catch (e) {
      _error = 'Error adding consumption: $e';
      notifyListeners();
      return false;
    }
  }

  // Stock Items Management
  Future<void> deleteItem(String itemId) async {
    try {
      await _repository.deleteStockItem(itemId);
      _items.removeWhere((item) => item.id == itemId);
      notifyListeners();
    } catch (e) {
      _error = 'Erreur lors de la suppression : ${e.toString()}';
      notifyListeners();
      rethrow;
    }
  }

  Future<void> adjustQuantity(String itemId, int adjustment) async {
    try {
      final item = _items.firstWhere(
        (item) => item.id == itemId,
        orElse: () => throw Exception('Article non trouvé'),
      );

      // Vérifier que la nouvelle quantité ne sera pas négative
      final newQuantity = item.quantity + adjustment;
      if (newQuantity < 0) {
        throw Exception('La quantité ne peut pas être négative');
      }

      // Mettre à jour l'article dans la base de données
      final updatedItem = await _repository.updateStockItem(
        item.copyWith(quantity: newQuantity),
      );

      // Mettre à jour l'article dans la liste locale
      final index = _items.indexWhere((i) => i.id == itemId);
      if (index != -1) {
        _items[index] = updatedItem;
        notifyListeners();
      }
    } catch (e) {
      _error =
          e.toString().contains('Exception:')
              ? e.toString().replaceAll('Exception:', '').trim()
              : 'Erreur lors de l\'ajustement de la quantité: $e';
      notifyListeners();
      rethrow;
    }
  }

  Future<void> addItem({
    required String name,
    required int quantity,
    required double price,
    required int alertThreshold,
    required String category,
  }) async {
    try {
      final item = await _repository.createStockItem(
        name: name,
        quantity: quantity,
        price: price,
        alertThreshold: alertThreshold,
        category: category,
      );
      _items.add(item);
      notifyListeners();
    } catch (e) {
      _error = 'Error adding item: $e';
      notifyListeners();
      rethrow;
    }
  }

  Future<void> updateItem(StockItem item) async {
    try {
      final updatedItem = await _repository.updateStockItem(item);
      final index = _items.indexWhere((i) => i.id == item.id);
      if (index != -1) {
        _items[index] = updatedItem;
        notifyListeners();
      }
    } catch (e) {
      _error = 'Error updating item: $e';
      notifyListeners();
      rethrow;
    }
  }

  // Get total consumption cost for a booking
  double getConsumptionsTotalForBooking(String bookingId) {
    final consumptions = _consumptionsPerBooking[bookingId] ?? [];
    return consumptions.fold(0.0, (sum, c) => sum + (c.quantity * c.unitPrice));
  }

  // Clear error
  void clearError() {
    _error = null;
    notifyListeners();
  }

  Future<void> updateConsumptionQuantity({
    required Consumption consumption,
    required int newQuantity,
  }) async {
    if (newQuantity < 1) {
      throw Exception('La quantité ne peut pas être inférieure à 1');
    }

    try {
      // Optimistic update - mettre à jour l'UI immédiatement
      final bookingConsumptions =
          _consumptionsPerBooking[consumption.bookingId];
      if (bookingConsumptions != null) {
        final index = bookingConsumptions.indexWhere(
          (c) => c.id == consumption.id,
        );
        if (index != -1) {
          final updatedConsumption = consumption.copyWith(
            quantity: newQuantity,
          );
          bookingConsumptions[index] = updatedConsumption;
          notifyListeners();
        }
      }

      // Mettre à jour dans la base de données
      final updatedConsumption = await _repository.updateConsumption(
        consumption.copyWith(quantity: newQuantity),
      );

      // En cas de succès, mettre à jour avec les données exactes de la base
      if (bookingConsumptions != null) {
        final index = bookingConsumptions.indexWhere(
          (c) => c.id == consumption.id,
        );
        if (index != -1) {
          bookingConsumptions[index] = updatedConsumption;
          notifyListeners();
        }
      }
    } catch (e) {
      // En cas d'erreur, restaurer l'état précédent
      final bookingConsumptions =
          _consumptionsPerBooking[consumption.bookingId];
      if (bookingConsumptions != null) {
        final index = bookingConsumptions.indexWhere(
          (c) => c.id == consumption.id,
        );
        if (index != -1) {
          bookingConsumptions[index] = consumption;
          notifyListeners();
        }
      }

      _error = e.toString();
      notifyListeners();
      rethrow;
    }
  }

  Future<void> deleteConsumption({required Consumption consumption}) async {
    try {
      await _repository.deleteConsumption(consumption.id);

      // Mettre à jour la liste locale des consommations
      final bookingConsumptions =
          _consumptionsPerBooking[consumption.bookingId];
      if (bookingConsumptions != null) {
        bookingConsumptions.removeWhere((c) => c.id == consumption.id);
        notifyListeners();
      }
    } catch (e) {
      _error = 'Error deleting consumption: $e';
      notifyListeners();
      rethrow;
    }
  }

  double calculateConsumptionTotal(
    List<(Consumption, StockItem)> consumptions,
  ) {
    return consumptions.fold(
      0,
      (total, pair) => total + (pair.$1.quantity * pair.$1.unitPrice),
    );
  }
}
