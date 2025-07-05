import '../../../core/constants/supabase_config.dart';
import '../models/equipment_model.dart';

class EquipmentRepository {
  static const String _tableName = 'equipment';

  Future<List<Equipment>> getAllEquipment() async {
    try {
      final response = await SupabaseConfig.client
          .from(_tableName)
          .select()
          .order('name', ascending: true);

      return response
          .map<Equipment>((json) => Equipment.fromJson(json))
          .toList();
    } catch (e) {
      throw Exception('Erreur lors de la récupération des équipements: $e');
    }
  }

  Future<Equipment> getEquipmentById(String id) async {
    try {
      final response = await SupabaseConfig.client
          .from(_tableName)
          .select()
          .eq('id', id)
          .single();

      return Equipment.fromJson(response);
    } catch (e) {
      throw Exception('Erreur lors de la récupération de l\'équipement: $e');
    }
  }

  Future<Equipment> createEquipment(Equipment equipment) async {
    try {
      final now = DateTime.now();
      final equipmentData = {
        'name': equipment.name,
        'is_functional': equipment.isFunctional,
        'description': equipment.description,
        'created_at': now.toIso8601String(),
        'updated_at': now.toIso8601String(),
      };

      final response = await SupabaseConfig.client
          .from(_tableName)
          .insert(equipmentData)
          .select()
          .single();

      return Equipment.fromJson(response);
    } catch (e) {
      throw Exception('Erreur lors de la création de l\'équipement: $e');
    }
  }

  Future<Equipment> updateEquipment(Equipment equipment) async {
    try {
      final equipmentData = {
        'name': equipment.name,
        'is_functional': equipment.isFunctional,
        'description': equipment.description,
        'updated_at': DateTime.now().toIso8601String(),
      };

      final response = await SupabaseConfig.client
          .from(_tableName)
          .update(equipmentData)
          .eq('id', equipment.id)
          .select()
          .single();

      return Equipment.fromJson(response);
    } catch (e) {
      throw Exception('Erreur lors de la mise à jour de l\'équipement: $e');
    }
  }

  Future<void> deleteEquipment(String id) async {
    try {
      await SupabaseConfig.client
          .from(_tableName)
          .delete()
          .eq('id', id);
    } catch (e) {
      throw Exception('Erreur lors de la suppression de l\'équipement: $e');
    }
  }

  Future<List<Equipment>> getFunctionalEquipment() async {
    try {
      final response = await SupabaseConfig.client
          .from(_tableName)
          .select()
          .eq('is_functional', true)
          .order('name');

      return response
          .map<Equipment>((json) => Equipment.fromJson(json))
          .toList();
    } catch (e) {
      throw Exception('Erreur lors de la récupération des équipements fonctionnels: $e');
    }
  }

  Future<List<Equipment>> getNonFunctionalEquipment() async {
    try {
      final response = await SupabaseConfig.client
          .from(_tableName)
          .select()
          .eq('is_functional', false)
          .order('updated_at', ascending: false);

      return response
          .map<Equipment>((json) => Equipment.fromJson(json))
          .toList();
    } catch (e) {
      throw Exception('Erreur lors de la récupération des équipements en panne: $e');
    }
  }
}