import 'package:flutter/foundation.dart';
import 'package:uuid/uuid.dart';
import '../models/stock_item_model.dart';
import '../models/consumption_model.dart';

class StockViewModel extends ChangeNotifier {
  final List<StockItem> _items = [];
  final List<Consumption> _consumptions = [];
  String _searchQuery = '';

  // Getters
  List<StockItem> get items => List.unmodifiable(_items);
  List<Consumption> get consumptions => List.unmodifiable(_consumptions);

  // Calculate total for a booking's consumptions
  double getConsumptionsTotalForBooking(String bookingId) {
    return getConsumptionsForBooking(
      bookingId,
    ).fold(0.0, (sum, consumption) => sum + consumption.totalPrice);
  }

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

  void updateSearchQuery(String query) {
    _searchQuery = query;
    notifyListeners();
  }

  // Ajouter un nouvel article
  void addItem({
    required String name,
    required int quantity,
    required double price,
    required int alertThreshold,
    required String category,
  }) {
    final item = StockItem(
      id: const Uuid().v4(),
      name: name,
      quantity: quantity,
      price: price,
      alertThreshold: alertThreshold,
      category: category,
    );

    _items.add(item);
    notifyListeners();
  }

  // Mettre à jour un article
  void updateItem(StockItem updatedItem) {
    final index = _items.indexWhere((item) => item.id == updatedItem.id);
    if (index != -1) {
      _items[index] = updatedItem;
      notifyListeners();
    }
  }

  // Supprimer un article
  void removeItem(String itemId) {
    _items.removeWhere((item) => item.id == itemId);
    notifyListeners();
  }

  // Ajuster la quantité
  void adjustQuantity(String itemId, int adjustment) {
    final index = _items.indexWhere((item) => item.id == itemId);
    if (index != -1) {
      final item = _items[index];
      final newQuantity = item.quantity + adjustment;
      if (newQuantity >= 0) {
        _items[index] = item.copyWith(quantity: newQuantity);
        notifyListeners();
      }
    }
  }

  // Charger des données de test
  void loadDummyData() {
    _items.addAll([
      // Boissons
      StockItem(
        id: const Uuid().v4(),
        name: 'Coca-Cola',
        quantity: 50,
        price: 2.50,
        alertThreshold: 10,
        category: 'DRINK',
      ),
      StockItem(
        id: const Uuid().v4(),
        name: 'Eau minérale',
        quantity: 100,
        price: 1.50,
        alertThreshold: 20,
        category: 'DRINK',
      ),
      StockItem(
        id: const Uuid().v4(),
        name: 'Fanta Orange',
        quantity: 40,
        price: 2.50,
        alertThreshold: 10,
        category: 'DRINK',
      ),
      StockItem(
        id: const Uuid().v4(),
        name: 'Sprite',
        quantity: 35,
        price: 2.50,
        alertThreshold: 10,
        category: 'DRINK',
      ),
      StockItem(
        id: const Uuid().v4(),
        name: 'Ice Tea Pêche',
        quantity: 45,
        price: 2.50,
        alertThreshold: 15,
        category: 'DRINK',
      ),
      StockItem(
        id: const Uuid().v4(),
        name: 'Jus d\'orange',
        quantity: 30,
        price: 2.00,
        alertThreshold: 8,
        category: 'DRINK',
      ),
      StockItem(
        id: const Uuid().v4(),
        name: 'Pizza Margarita',
        quantity: 15,
        price: 12.00,
        alertThreshold: 5,
        category: 'FOOD',
      ),
      StockItem(
        id: const Uuid().v4(),
        name: 'Pizza 4 Fromages',
        quantity: 12,
        price: 13.00,
        alertThreshold: 5,
        category: 'FOOD',
      ),
      StockItem(
        id: const Uuid().v4(),
        name: 'Hot-Dog',
        quantity: 25,
        price: 4.00,
        alertThreshold: 8,
        category: 'FOOD',
      ),
      StockItem(
        id: const Uuid().v4(),
        name: 'Chips Nature',
        quantity: 30,
        price: 2.00,
        alertThreshold: 8,
        category: 'FOOD',
      ),
      StockItem(
        id: const Uuid().v4(),
        name: 'Chips Paprika',
        quantity: 25,
        price: 2.00,
        alertThreshold: 8,
        category: 'FOOD',
      ),
      StockItem(
        id: const Uuid().v4(),
        name: 'Nachos avec Sauce',
        quantity: 20,
        price: 5.00,
        alertThreshold: 6,
        category: 'FOOD',
      ),
      // Autres articles
      StockItem(
        id: const Uuid().v4(),
        name: 'Cartes de jeu',
        quantity: 20,
        price: 5.00,
        alertThreshold: 5,
        category: 'OTHER',
      ),
      StockItem(
        id: const Uuid().v4(),
        name: 'Jetons',
        quantity: 200,
        price: 1.00,
        alertThreshold: 50,
        category: 'OTHER',
      ),
      StockItem(
        id: const Uuid().v4(),
        name: 'Batteries AAA',
        quantity: 48,
        price: 1.50,
        alertThreshold: 12,
        category: 'OTHER',
      ),
      StockItem(
        id: const Uuid().v4(),
        name: 'Batteries AA',
        quantity: 48,
        price: 1.50,
        alertThreshold: 12,
        category: 'OTHER',
      ),
    ]);
    notifyListeners();
  }

  // Obtenir les consommations pour une réservation spécifique
  List<Consumption> getConsumptionsForBooking(String bookingId) {
    return _consumptions.where((c) => c.bookingId == bookingId).toList();
  }

  // Ajouter une consommation et mettre à jour le stock
  bool addConsumption({
    required String bookingId,
    required String stockItemId,
    required int quantity,
  }) {
    // Validation des entrées
    if (bookingId.isEmpty || stockItemId.isEmpty || quantity <= 0) {
      print('Erreur de validation: paramètres invalides');
      return false;
    }

    // Vérifier si l'article existe et a assez de stock
    final itemIndex = _items.indexWhere((item) => item.id == stockItemId);
    if (itemIndex == -1) {
      print('Erreur: article non trouvé avec ID $stockItemId');
      return false;
    }

    final item = _items[itemIndex];
    if (item.quantity < quantity) {
      print(
        'Erreur: stock insuffisant pour ${item.name} (Disponible: ${item.quantity}, Demandé: $quantity)',
      );
      return false;
    }

    // Créer la consommation
    final consumption = Consumption(
      id: const Uuid().v4(),
      bookingId: bookingId,
      stockItemId: stockItemId,
      quantity: quantity,
      timestamp: DateTime.now(),
      unitPrice: item.price,
    );

    // Ajouter la consommation
    _consumptions.add(consumption);

    // Mettre à jour le stock
    _items[itemIndex] = item.copyWith(quantity: item.quantity - quantity);

    print(
      'Consommation ajoutée: ${item.name} x$quantity pour la réservation $bookingId',
    );
    notifyListeners();
    return true;
  }

  // Annuler une consommation
  void cancelConsumption(String consumptionId) {
    final consumptionIndex = _consumptions.indexWhere(
      (c) => c.id == consumptionId,
    );
    if (consumptionIndex == -1) return;

    final consumption = _consumptions[consumptionIndex];

    // Remettre la quantité en stock
    final itemIndex = _items.indexWhere(
      (item) => item.id == consumption.stockItemId,
    );
    if (itemIndex != -1) {
      final item = _items[itemIndex];
      _items[itemIndex] = item.copyWith(
        quantity: item.quantity + consumption.quantity,
      );
    }

    // Supprimer la consommation
    _consumptions.removeAt(consumptionIndex);

    notifyListeners();
  }

  // Mettre à jour la quantité d'une consommation existante
  void updateConsumptionQuantity(String consumptionId, int newQuantity) {
    final consumptionIndex = _consumptions.indexWhere(
      (c) => c.id == consumptionId,
    );
    if (consumptionIndex == -1 || newQuantity < 0) return;

    final consumption = _consumptions[consumptionIndex];
    final itemIndex = _items.indexWhere(
      (item) => item.id == consumption.stockItemId,
    );
    if (itemIndex == -1) return;

    final item = _items[itemIndex];
    final quantityDiff = newQuantity - consumption.quantity;

    // Vérifier si on a assez de stock pour l'augmentation
    if (quantityDiff > 0 && item.quantity < quantityDiff) return;

    // Mettre à jour le stock
    _items[itemIndex] = item.copyWith(quantity: item.quantity - quantityDiff);

    // Mettre à jour la consommation
    _consumptions[consumptionIndex] = consumption.copyWith(
      quantity: newQuantity,
    );

    notifyListeners();
  }
}
