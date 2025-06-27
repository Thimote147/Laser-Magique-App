import 'package:supabase_flutter/supabase_flutter.dart';
import '../../../core/constants/supabase_config.dart';
import '../models/stock_item_model.dart';
import '../../../shared/models/consumption_model.dart';

class StockRepository {
  final SupabaseClient _client = SupabaseConfig.client;

  // Stock Items
  Future<List<StockItem>> getAllStockItems({
    bool includeInactive = false,
  }) async {
    final query = _client.from('stock_items').select();

    if (!includeInactive) {
      query.eq('is_active', true);
    }

    final response = await query.order('name');
    final items =
        (response as List).map((json) => StockItem.fromMap(json)).toList();
    // Tri des items par nom pour assurer la cohérence de l'affichage
    items.sort((a, b) => a.name.compareTo(b.name));
    return items;
  }

  Future<List<StockItem>> getLowStockItems({
    bool includeInactive = false,
  }) async {
    var query = _client.from('low_stock_items').select();

    if (!includeInactive) {
      query = query.eq('is_active', true);
    }

    final response = await query;
    final items =
        (response as List).map((json) => StockItem.fromMap(json)).toList();
    items.sort((a, b) => a.name.compareTo(b.name));
    return items;
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
              'is_active': true,
            })
            .select()
            .single();

    return StockItem.fromMap(response);
  }

  Future<StockItem> updateStockItem(StockItem item) async {
    try {
      await _client.from('stock_items').select().eq('id', item.id).single();

      final response =
          await _client
              .from('stock_items')
              .update({
                'name': item.name,
                'quantity': item.quantity,
                'price': item.price,
                'alert_threshold': item.alertThreshold,
                'category': item.category,
                'is_active': item.isActive,
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

  Future<void> setItemActive(String id, bool active) async {
    await _client
        .from('stock_items')
        .update({'is_active': active})
        .eq('id', id);
  }

  // Consumptions
  Future<List<Consumption>> getConsumptionsForBooking(String bookingId) async {
    final response = await _client
        .from('consumptions')
        .select('*, stock_items(*)')
        .eq('booking_id', bookingId)
        .order('timestamp');

    return (response as List).map((json) => Consumption.fromMap(json)).toList();
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
              .eq('is_active', true)
              .single();

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

        // Mettre à jour uniquement la consommation existante
        // Le trigger SQL s'occupera de la mise à jour du stock
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
        // Pour une nouvelle consommation
        final response =
            await _client
                .from('consumptions')
                .insert({
                  'booking_id': bookingId,
                  'stock_item_id': stockItemId,
                  'quantity': quantity,
                  'unit_price': stockItem['price'],
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

  Future<void> updateConsumption(Consumption consumption) async {
    await _client
        .from('consumptions')
        .update({
          'quantity': consumption.quantity,
          'timestamp': DateTime.now().toIso8601String(),
        })
        .eq('id', consumption.id);
  }

  Future<void> deleteConsumption(String id) async {
    await _client.from('consumptions').delete().eq('id', id);
  }
}
