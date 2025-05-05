import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:laser_magique_app/models/food.dart';

class SupabaseService {
  // Singleton pattern
  SupabaseService._privateConstructor();
  static final SupabaseService _instance =
      SupabaseService._privateConstructor();
  static SupabaseService get instance => _instance;

  // Get the Supabase client from the global instance
  SupabaseClient get client => Supabase.instance.client;

  // Food item methods
  Future<List<FoodItem>> getFoodItems() async {
    try {
      final response = await client.from('food').select().order('name');
      return (response as List).map((item) => FoodItem.fromJson(item)).toList();
    } catch (e) {
      rethrow;
    }
  }

  Future<FoodItem> addFoodItem(FoodItem item) async {
    try {
      final response =
          await client.from('food').insert(item.toJson()).select().single();
      return FoodItem.fromJson(response);
    } catch (e) {
      rethrow;
    }
  }

  Future<FoodItem> updateFoodItem(FoodItem item) async {
    try {
      final response =
          await client
              .from('food')
              .update(item.toJson())
              .eq('food_id', item.id)
              .select()
              .single();
      return FoodItem.fromJson(response);
    } catch (e) {
      rethrow;
    }
  }

  Future<void> deleteFoodItem(String id) async {
    try {
      await client.from('food').delete().eq('food_id', id);
    } catch (e) {
      rethrow;
    }
  }
}
