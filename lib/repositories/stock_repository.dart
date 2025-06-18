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
    final query = _client
        .from('consumptions')
        .select('*, stock_items(*)'); // Inclure les données des items associés

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

  Future<Consumption> addConsumption({
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

      final unitPrice = (stockItem['price'] as num).toDouble();
      final currentStock = stockItem['quantity'] as int;

      // Vérifier si nous avons assez de stock
      if (currentStock < quantity) {
        throw Exception('Quantité insuffisante en stock');
      }

      // Rechercher une consommation existante
      final existingConsumptions = await _client
          .from('consumptions')
          .select()
          .eq('booking_id', bookingId)
          .eq('stock_item_id', stockItemId);

      if (existingConsumptions.isNotEmpty) {
        // Si une consommation existe déjà, mettre à jour la quantité
        final existingConsumption = existingConsumptions[0];
        final currentQuantity = existingConsumption['quantity'] as int;
        final newQuantity = currentQuantity + quantity;

        // Mettre à jour le stock
        await _client
            .from('stock_items')
            .update({'quantity': currentStock - quantity})
            .eq('id', stockItemId);

        // Mettre à jour la consommation existante
        final response =
            await _client
                .from('consumptions')
                .update({
                  'quantity': newQuantity,
                  'timestamp': DateTime.now().toIso8601String(),
                })
                .eq('id', existingConsumption['id'])
                .select('*, stock_items(*)')
                .single();

        return Consumption.fromMap(response);
      } else {
        // Vérifier si nous avons assez de stock pour la nouvelle consommation
        if (currentStock < quantity) {
          throw Exception('Quantité insuffisante en stock');
        }

        // Mettre à jour le stock
        await _client
            .from('stock_items')
            .update({'quantity': currentStock - quantity})
            .eq('id', stockItemId);

        // Créer une nouvelle consommation
        final response =
            await _client
                .from('consumptions')
                .insert({
                  'booking_id': bookingId,
                  'stock_item_id': stockItemId,
                  'quantity': quantity,
                  'unit_price': unitPrice,
                  'timestamp': DateTime.now().toIso8601String(),
                })
                .select('*, stock_items(*)')
                .single();

        return Consumption.fromMap(response);
      }
    } catch (e) {
      throw Exception(
        'Erreur lors de l\'ajout de la consommation: ${e.toString()}',
      );
    }
  }

  Future<Consumption> updateConsumption(Consumption consumption) async {
    try {
      // Utiliser une procédure stockée pour effectuer la mise à jour en une seule transaction
      final response =
          await _client
              .rpc(
                'update_consumption',
                params: {
                  'p_consumption_id': consumption.id,
                  'p_new_quantity': consumption.quantity,
                },
              )
              .select('*, stock_items(*)')
              .single();

      return Consumption.fromMap(response);
    } catch (e) {
      final message = e.toString().toLowerCase();
      if (message.contains('stock insuffisant')) {
        throw Exception('Stock insuffisant pour cette modification');
      }
      throw Exception(
        'Erreur lors de la mise à jour de la consommation: ${e.toString()}',
      );
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
