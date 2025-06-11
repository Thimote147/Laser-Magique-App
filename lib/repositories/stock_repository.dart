import 'package:supabase_flutter/supabase_flutter.dart';
import '../config/supabase_config.dart';
import '../models/stock_item_model.dart';
import '../models/consumption_model.dart';

class StockRepository {
  final SupabaseClient _client = SupabaseConfig.client;

  // Stock Items
  Future<List<StockItem>> getAllStockItems() async {
    final response = await _client.from('stock_items').select().order('name');
    return (response as List).map((json) => StockItem.fromMap(json)).toList();
  }

  Future<List<StockItem>> getLowStockItems() async {
    final response = await _client.from('low_stock_items').select();
    return (response as List).map((json) => StockItem.fromMap(json)).toList();
  }

  Stream<List<StockItem>> streamStockItems() {
    return _client
        .from('stock_items')
        .stream(primaryKey: ['id'])
        .order('name')
        .map(
          (response) =>
              (response as List)
                  .map((json) => StockItem.fromMap(json))
                  .toList(),
        );
  }

  Future<StockItem> createStockItem({
    required String name,
    required int quantity,
    required double price,
    required int alertThreshold,
    required String category,
  }) async {
    final response =
        await _client
            .from('stock_items')
            .insert({
              'name': name,
              'quantity': quantity,
              'price': price,
              'alert_threshold': alertThreshold,
              'category': category,
            })
            .select()
            .single();

    return StockItem.fromMap(response);
  }

  Future<StockItem> updateStockItem(StockItem item) async {
    try {
      // Vérifier d'abord si l'article existe
      final existingItem =
          await _client.from('stock_items').select().eq('id', item.id).single();

      if (existingItem == null) {
        throw Exception('Article non trouvé');
      }

      final response =
          await _client
              .from('stock_items')
              .update({
                'name': item.name,
                'quantity': item.quantity,
                'price': item.price,
                'alert_threshold': item.alertThreshold,
                'category': item.category,
              })
              .eq('id', item.id)
              .select()
              .single();

      return StockItem.fromMap(response);
    } catch (e) {
      if (e.toString().contains('not found')) {
        throw Exception('Article non trouvé dans la base de données');
      }
      throw Exception(
        'Erreur lors de la mise à jour du stock: ${e.toString()}',
      );
    }
  }

  Future<void> deleteStockItem(String id) async {
    await _client.from('stock_items').delete().eq('id', id);
  }

  // Consumptions
  Future<List<Consumption>> getConsumptionsForBooking(String? bookingId) async {
    final query = _client.from('consumptions').select();
    final filteredQuery =
        bookingId != null ? query.eq('booking_id', bookingId) : query;
    final finalQuery = filteredQuery.order('timestamp');

    final response = await finalQuery;
    return (response as List).map((json) => Consumption.fromMap(json)).toList();
  }

  Stream<List<Consumption>> streamConsumptions(String bookingId) {
    return _client
        .from('consumptions')
        .stream(primaryKey: ['id'])
        .eq('booking_id', bookingId)
        .order('timestamp')
        .map(
          (response) =>
              (response as List)
                  .map((json) => Consumption.fromMap(json))
                  .toList(),
        );
  }

  Future<bool> addConsumption({
    required String bookingId,
    required String stockItemId,
    required int quantity,
  }) async {
    try {
      final stockItem =
          await _client
              .from('stock_items')
              .select()
              .eq('id', stockItemId)
              .single();

      if (stockItem['quantity'] < quantity) {
        return false;
      }

      // Update the stock item quantity first
      await _client
          .from('stock_items')
          .update({'quantity': stockItem['quantity'] - quantity})
          .eq('id', stockItemId);

      // Then create the consumption record
      await _client.from('consumptions').insert({
        'booking_id': bookingId,
        'stock_item_id': stockItemId,
        'quantity': quantity,
        'unit_price': stockItem['price'],
        'timestamp': DateTime.now().toIso8601String(),
      });

      return true;
    } catch (e) {
      rethrow;
    }
  }

  Future<void> updateConsumption(Consumption consumption) async {
    // First get the current consumption to calculate stock adjustment
    final oldConsumption =
        await _client
            .from('consumptions')
            .select()
            .eq('id', consumption.id)
            .single();

    final quantityDiff = consumption.quantity - oldConsumption['quantity'];

    // Begin transaction
    try {
      // Update stock item quantity
      final stockItem =
          await _client
              .from('stock_items')
              .select()
              .eq('id', consumption.stockItemId)
              .single();

      if (stockItem['quantity'] - quantityDiff < 0) {
        throw Exception('Not enough stock available');
      }

      await _client
          .from('stock_items')
          .update({'quantity': stockItem['quantity'] - quantityDiff})
          .eq('id', consumption.stockItemId);

      // Update consumption record
      await _client
          .from('consumptions')
          .update({
            'quantity': consumption.quantity,
            'unit_price': consumption.unitPrice,
          })
          .eq('id', consumption.id);
    } catch (e) {
      rethrow;
    }
  }

  Future<void> deleteConsumption(String consumptionId) async {
    // Get consumption details before deleting
    final consumption =
        await _client
            .from('consumptions')
            .select()
            .eq('id', consumptionId)
            .single();

    // Return quantity to stock
    await _client
        .from('stock_items')
        .select()
        .eq('id', consumption['stock_item_id'])
        .single()
        .then((stockItem) async {
          await _client
              .from('stock_items')
              .update({
                'quantity': stockItem['quantity'] + consumption['quantity'],
              })
              .eq('id', consumption['stock_item_id']);
        });

    // Delete consumption record
    await _client.from('consumptions').delete().eq('id', consumptionId);
  }
}
