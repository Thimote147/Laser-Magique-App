import 'package:flutter/foundation.dart';
import '../models/formula_model.dart';
import '../models/consumption_model.dart';
import '../../features/inventory/models/stock_item_model.dart';

class SocialDealService {
  static final SocialDealService _instance = SocialDealService._internal();
  factory SocialDealService() => _instance;
  SocialDealService._internal();

  /// Calculates the consumption pricing info for a Social Deal formula
  /// Returns a map with totalPrice, unitPrice, and isIncluded
  Map<String, dynamic> calculateConsumptionPricing({
    required Formula formula,
    required StockItem stockItem,
    required int quantity,
    required int bookingPersons,
    required List<Consumption> existingConsumptions,
    required List<StockItem> allStockItems,
  }) {
    if (formula.type != FormulaType.socialDeal) {
      final totalPrice = stockItem.price * quantity;
      return {
        'totalPrice': totalPrice,
        'unitPrice': stockItem.price,
        'isIncluded': false,
      };
    }

    // If not included in Social Deal, charge full price
    if (!stockItem.includedInSocialDeal) {
      final totalPrice = stockItem.price * quantity;
      return {
        'totalPrice': totalPrice,
        'unitPrice': stockItem.price,
        'isIncluded': false,
      };
    }

    // NEW LOGIC: Separate quotas for drinks and food
    // Each person gets 1 free drink + 1 free food item
    final freeQuantityPerPerson = 1;
    final totalFreeDrinks = freeQuantityPerPerson * bookingPersons;
    final totalFreeFood = freeQuantityPerPerson * bookingPersons;

    // Create a map of all stock items by ID for quick lookup
    final stockItemsMap = {for (var item in allStockItems) item.id: item};

    // Get existing consumptions sorted by timestamp (chronological order)
    final sortedExistingConsumptions = List<Consumption>.from(existingConsumptions)
      ..sort((a, b) => a.timestamp.compareTo(b.timestamp));

    // Count how many drinks and food items have been consumed so far
    int drinksConsumed = 0;
    int foodConsumed = 0;

    for (final consumption in sortedExistingConsumptions) {
      final consumedStockItem = stockItemsMap[consumption.stockItemId];
      if (consumedStockItem?.includedInSocialDeal == true) {
        if (consumedStockItem!.category == 'DRINK') {
          drinksConsumed += consumption.quantity;
        } else if (consumedStockItem.category == 'FOOD') {
          foodConsumed += consumption.quantity;
        }
      }
    }

    // Determine how many of the new quantity will be free vs paid
    int freeQuantity = 0;
    int paidQuantity = 0;

    if (stockItem.category == 'DRINK') {
      final remainingFreeDrinks = (totalFreeDrinks - drinksConsumed).clamp(0, totalFreeDrinks);
      freeQuantity = quantity.clamp(0, remainingFreeDrinks);
      paidQuantity = quantity - freeQuantity;
    } else if (stockItem.category == 'FOOD') {
      final remainingFreeFood = (totalFreeFood - foodConsumed).clamp(0, totalFreeFood);
      freeQuantity = quantity.clamp(0, remainingFreeFood);
      paidQuantity = quantity - freeQuantity;
    } else {
      // Not a drink or food, charge full price
      paidQuantity = quantity;
    }

    debugPrint('🍹🍟 Social Deal quota calculation:');
    debugPrint('  - Item: ${stockItem.name} (${stockItem.category})');
    debugPrint('  - Booking persons: $bookingPersons');
    debugPrint('  - Free drinks quota: $totalFreeDrinks, consumed: $drinksConsumed');
    debugPrint('  - Free food quota: $totalFreeFood, consumed: $foodConsumed');
    debugPrint('  - Adding quantity: $quantity (free: $freeQuantity, paid: $paidQuantity)');

    final totalPrice = paidQuantity * stockItem.price;
    final isIncluded = freeQuantity == quantity; // Only fully included if all items are free

    return {
      'totalPrice': totalPrice,
      'unitPrice': totalPrice, // Store total price in unit_price field for database compatibility
      'isIncluded': isIncluded,
    };
  }

  /// Legacy method for backward compatibility
  double calculateConsumptionPrice({
    required Formula formula,
    required StockItem stockItem,
    required int quantity,
    required int bookingPersons,
    required List<Consumption> existingConsumptions,
    required List<StockItem> allStockItems,
  }) {
    final pricing = calculateConsumptionPricing(
      formula: formula,
      stockItem: stockItem,
      quantity: quantity,
      bookingPersons: bookingPersons,
      existingConsumptions: existingConsumptions,
      allStockItems: allStockItems,
    );
    return pricing['totalPrice'] as double;
  }

  /// Creates a consumption with appropriate pricing based on Social Deal formula
  Consumption createConsumption({
    required String id,
    required String bookingId,
    required String stockItemId,
    required int quantity,
    required DateTime timestamp,
    required Formula formula,
    required StockItem stockItem,
    required int bookingPersons,
    required List<Consumption> existingConsumptions,
    required List<StockItem> allStockItems,
  }) {
    final pricing = calculateConsumptionPricing(
      formula: formula,
      stockItem: stockItem,
      quantity: quantity,
      bookingPersons: bookingPersons,
      existingConsumptions: existingConsumptions,
      allStockItems: allStockItems,
    );

    final unitPrice = pricing['unitPrice'] as double;
    final isIncluded = pricing['isIncluded'] as bool;

    debugPrint('🔨 Creating consumption: unitPrice=$unitPrice, isIncluded=$isIncluded');

    return Consumption(
      id: id,
      bookingId: bookingId,
      stockItemId: stockItemId,
      quantity: quantity,
      timestamp: timestamp,
      unitPrice: unitPrice,
      isIncluded: isIncluded,
      // totalPrice is calculated dynamically based on unitPrice and isIncluded
    );
  }

  /// Validates if a consumption can be added based on Social Deal rules
  bool canAddConsumption({
    required Formula formula,
    required StockItem stockItem,
    required int quantity,
    required int bookingPersons,
    required List<Consumption> existingConsumptions,
  }) {
    if (formula.type != FormulaType.socialDeal) {
      return true;
    }

    // Allow consumption even if it exceeds included quantity (they'll pay for excess)
    return true;
  }

  /// Gets the remaining free quantity for a stock item in a Social Deal formula
  int getRemainingFreeQuantity({
    required Formula formula,
    required StockItem stockItem,
    required int bookingPersons,
    required List<Consumption> existingConsumptions,
    required List<StockItem> allStockItems,
  }) {
    if (formula.type != FormulaType.socialDeal) {
      return 0;
    }

    if (!stockItem.includedInSocialDeal) {
      return 0;
    }

    // NEW LOGIC: Separate quotas for drinks and food
    const freeQuantityPerPerson = 1;
    final totalFreeDrinks = freeQuantityPerPerson * bookingPersons;
    final totalFreeFood = freeQuantityPerPerson * bookingPersons;

    // Create a map of all stock items by ID for quick lookup
    final stockItemsMap = {for (var item in allStockItems) item.id: item};

    // Get existing consumptions sorted by timestamp (chronological order)
    final sortedExistingConsumptions = List<Consumption>.from(existingConsumptions)
      ..sort((a, b) => a.timestamp.compareTo(b.timestamp));

    // Count how many drinks and food items have been consumed so far
    int drinksConsumed = 0;
    int foodConsumed = 0;

    for (final consumption in sortedExistingConsumptions) {
      final consumedStockItem = stockItemsMap[consumption.stockItemId];
      if (consumedStockItem?.includedInSocialDeal == true) {
        if (consumedStockItem!.category == 'DRINK') {
          drinksConsumed += consumption.quantity;
        } else if (consumedStockItem.category == 'FOOD') {
          foodConsumed += consumption.quantity;
        }
      }
    }

    // Return remaining free quantity based on category
    if (stockItem.category == 'DRINK') {
      return (totalFreeDrinks - drinksConsumed).clamp(0, totalFreeDrinks);
    } else if (stockItem.category == 'FOOD') {
      return (totalFreeFood - foodConsumed).clamp(0, totalFreeFood);
    } else {
      // Not a drink or food, no free quota
      return 0;
    }
  }

  /// Gets information about included items for a Social Deal formula
  Map<String, int> getIncludedItemsInfo({
    required Formula formula,
    required int bookingPersons,
    required List<StockItem> stockItems,
  }) {
    if (formula.type != FormulaType.socialDeal) {
      return {};
    }

    final result = <String, int>{};
    for (final stockItem in stockItems) {
      if (stockItem.includedInSocialDeal) {
        result[stockItem.id] = 1 * bookingPersons; // 1 per person
      }
    }
    return result;
  }
}