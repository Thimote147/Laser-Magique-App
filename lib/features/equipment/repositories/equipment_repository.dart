import 'dart:async';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../../core/constants/supabase_config.dart';
import '../models/equipment_model.dart';

class EquipmentRepository {
  static const String _tableName = 'equipment';
  final SupabaseClient _client = SupabaseConfig.client;
  
  RealtimeChannel? _equipmentChannel;
  final StreamController<List<Equipment>> _equipmentStreamController = StreamController<List<Equipment>>.broadcast();
  
  Stream<List<Equipment>> get equipmentStream => _equipmentStreamController.stream;
  
  EquipmentRepository() {
    _initializeRealtimeSubscription();
  }
  
  void _initializeRealtimeSubscription() {
    _equipmentChannel = _client.channel('equipment_channel');
    
    _equipmentChannel!.onPostgresChanges(
      event: PostgresChangeEvent.all,
      schema: 'public',
      table: 'equipment',
      callback: (payload) {
        _refreshEquipment();
      },
    );
    
    _equipmentChannel!.subscribe();
    
    _refreshEquipment();
  }
  
  Future<void> _refreshEquipment() async {
    try {
      final equipment = await getAllEquipment();
      _equipmentStreamController.add(equipment);
    } catch (e) {
      _equipmentStreamController.addError(e);
    }
  }

  Future<List<Equipment>> getAllEquipment() async {
    try {
      final response = await _client
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
      final response = await _client
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

      final response = await _client
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

      final response = await _client
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
      await _client
          .from(_tableName)
          .delete()
          .eq('id', id);
    } catch (e) {
      throw Exception('Erreur lors de la suppression de l\'équipement: $e');
    }
  }

  Future<List<Equipment>> getFunctionalEquipment() async {
    try {
      final response = await _client
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
      final response = await _client
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
  
  void dispose() {
    _equipmentChannel?.unsubscribe();
    _equipmentStreamController.close();
  }
}