import '../models/formula_model.dart';
import '../models/consumption_model.dart';
import '../../features/inventory/models/stock_item_model.dart';

class SocialDealService {
  static final SocialDealService _instance = SocialDealService._internal();
  factory SocialDealService() => _instance;
  SocialDealService._internal();

  /// Calculates the consumption price for a Social Deal formula
  /// Returns 0.0 if the consumption is included in the formula
  double calculateConsumptionPrice({
    required Formula formula,
    required StockItem stockItem,
    required int quantity,
    required int bookingPersons,
    required List<Consumption> existingConsumptions,
  }) {
    if (formula.type != FormulaType.socialDeal) {
      return stockItem.price * quantity;
    }

    // Find if this stock item is included in the formula
    final includedItem = formula.includedItems.firstWhere(
      (item) => item.stockItemId == stockItem.id,
      orElse: () => IncludedItem(stockItemId: '', quantityPerPerson: 0),
    );

    // If not included, charge full price
    if (includedItem.stockItemId.isEmpty) {
      return stockItem.price * quantity;
    }

    // Calculate total included quantity for this stock item
    final totalIncludedQuantity = includedItem.quantityPerPerson * bookingPersons;

    // Calculate how much of this stock item has already been consumed
    final consumedQuantity = existingConsumptions
        .where((consumption) => consumption.stockItemId == stockItem.id)
        .fold(0, (sum, consumption) => sum + consumption.quantity);

    // Calculate remaining free quantity
    final remainingFreeQuantity = totalIncludedQuantity - consumedQuantity;

    if (remainingFreeQuantity <= 0) {
      // No free quantity remaining, charge full price
      return stockItem.price * quantity;
    }

    if (quantity <= remainingFreeQuantity) {
      // All requested quantity is free
      return 0.0;
    }

    // Partial free quantity, charge only for the excess
    final chargedQuantity = quantity - remainingFreeQuantity;
    return stockItem.price * chargedQuantity;
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
  }) {
    final price = calculateConsumptionPrice(
      formula: formula,
      stockItem: stockItem,
      quantity: quantity,
      bookingPersons: bookingPersons,
      existingConsumptions: existingConsumptions,
    );

    final isIncluded = formula.type == FormulaType.socialDeal &&
        formula.includedItems.any((item) => item.stockItemId == stockItem.id) &&
        price == 0.0;

    return Consumption(
      id: id,
      bookingId: bookingId,
      stockItemId: stockItemId,
      quantity: quantity,
      timestamp: timestamp,
      unitPrice: price / quantity,
      isIncluded: isIncluded,
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

    // Check if the stock item is included in the formula
    final includedItem = formula.includedItems.firstWhere(
      (item) => item.stockItemId == stockItem.id,
      orElse: () => IncludedItem(stockItemId: '', quantityPerPerson: 0),
    );

    // If not included, consumption is always allowed
    if (includedItem.stockItemId.isEmpty) {
      return true;
    }

    // Allow consumption even if it exceeds included quantity (they'll pay for excess)
    return true;
  }

  /// Gets the remaining free quantity for a stock item in a Social Deal formula
  int getRemainingFreeQuantity({
    required Formula formula,
    required String stockItemId,
    required int bookingPersons,
    required List<Consumption> existingConsumptions,
  }) {
    if (formula.type != FormulaType.socialDeal) {
      return 0;
    }

    final includedItem = formula.includedItems.firstWhere(
      (item) => item.stockItemId == stockItemId,
      orElse: () => IncludedItem(stockItemId: '', quantityPerPerson: 0),
    );

    if (includedItem.stockItemId.isEmpty) {
      return 0;
    }

    final totalIncludedQuantity = includedItem.quantityPerPerson * bookingPersons;
    final consumedQuantity = existingConsumptions
        .where((consumption) => consumption.stockItemId == stockItemId)
        .fold(0, (sum, consumption) => sum + consumption.quantity);

    return (totalIncludedQuantity - consumedQuantity).clamp(0, totalIncludedQuantity);
  }

  /// Gets information about included items for a Social Deal formula
  Map<String, int> getIncludedItemsInfo({
    required Formula formula,
    required int bookingPersons,
  }) {
    if (formula.type != FormulaType.socialDeal) {
      return {};
    }

    final result = <String, int>{};
    for (final item in formula.includedItems) {
      result[item.stockItemId] = item.quantityPerPerson * bookingPersons;
    }
    return result;
  }
}