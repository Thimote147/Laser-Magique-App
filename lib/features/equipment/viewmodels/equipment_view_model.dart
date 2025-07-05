import 'package:flutter/foundation.dart';
import '../models/equipment_model.dart';
import '../repositories/equipment_repository.dart';

enum EquipmentFilter { all, functional, nonFunctional }

class EquipmentViewModel extends ChangeNotifier {
  final EquipmentRepository _repository = EquipmentRepository();
  
  List<Equipment> _equipment = [];
  bool _isLoading = false;
  String? _error;
  EquipmentFilter _currentFilter = EquipmentFilter.all;

  List<Equipment> get equipment => _getFilteredEquipment();
  bool get isLoading => _isLoading;
  String? get error => _error;
  EquipmentFilter get currentFilter => _currentFilter;

  // Statistiques (toujours basées sur la liste complète)
  int get totalCount => _equipment.length;
  int get functionalCount => _equipment.where((e) => e.isFunctional).length;
  int get nonFunctionalCount => _equipment.where((e) => !e.isFunctional).length;

  List<Equipment> get functionalEquipment => 
      _equipment.where((e) => e.isFunctional).toList();
  
  List<Equipment> get nonFunctionalEquipment => 
      _equipment.where((e) => !e.isFunctional).toList();

  // Filtrage
  List<Equipment> _getFilteredEquipment() {
    switch (_currentFilter) {
      case EquipmentFilter.functional:
        return functionalEquipment;
      case EquipmentFilter.nonFunctional:
        return nonFunctionalEquipment;
      case EquipmentFilter.all:
        return _equipment;
    }
  }

  void setFilter(EquipmentFilter filter) {
    if (_currentFilter != filter) {
      _currentFilter = filter;
      notifyListeners();
    }
  }

  void clearFilter() {
    setFilter(EquipmentFilter.all);
  }

  Future<void> loadEquipment() async {
    _setLoading(true);
    _clearError();
    
    try {
      _equipment = await _repository.getAllEquipment();
      // La liste est déjà triée côté base de données, mais on s'assure du tri local aussi
      _sortEquipmentByName();
      notifyListeners();
    } catch (e) {
      _setError('Erreur lors du chargement des équipements: $e');
    } finally {
      _setLoading(false);
    }
  }

  Future<void> addEquipment({
    required String name,
    required bool isFunctional,
    String? description,
  }) async {
    _clearError();
    
    try {
      final now = DateTime.now();
      final newEquipment = Equipment(
        id: '', // L'ID sera généré par Supabase
        name: name,
        isFunctional: isFunctional,
        description: description,
        createdAt: now,
        updatedAt: now,
      );

      final createdEquipment = await _repository.createEquipment(newEquipment);
      _equipment.add(createdEquipment);
      _sortEquipmentByName(); // Trier après ajout
      notifyListeners();
    } catch (e) {
      _setError('Erreur lors de l\'ajout de l\'équipement: $e');
      rethrow;
    }
  }

  Future<void> updateEquipment(Equipment equipment) async {
    _clearError();
    
    try {
      final updatedEquipment = await _repository.updateEquipment(equipment);
      final index = _equipment.indexWhere((e) => e.id == equipment.id);
      
      if (index != -1) {
        _equipment[index] = updatedEquipment;
        _sortEquipmentByName(); // Retrier en cas de changement de nom
        notifyListeners();
      }
    } catch (e) {
      _setError('Erreur lors de la mise à jour de l\'équipement: $e');
      rethrow;
    }
  }

  Future<void> deleteEquipment(String id) async {
    _clearError();
    
    try {
      await _repository.deleteEquipment(id);
      _equipment.removeWhere((e) => e.id == id);
      notifyListeners();
    } catch (e) {
      _setError('Erreur lors de la suppression de l\'équipement: $e');
      rethrow;
    }
  }

  Future<void> toggleEquipmentStatus(Equipment equipment, {String? description}) async {
    final updatedEquipment = equipment.copyWith(
      isFunctional: !equipment.isFunctional,
      description: !equipment.isFunctional ? null : description,
      updatedAt: DateTime.now(),
    );
    
    await updateEquipment(updatedEquipment);
  }

  Equipment? getEquipmentById(String id) {
    try {
      return _equipment.firstWhere((e) => e.id == id);
    } catch (e) {
      return null;
    }
  }

  void _setLoading(bool loading) {
    _isLoading = loading;
    notifyListeners();
  }

  void _setError(String error) {
    _error = error;
    notifyListeners();
  }

  void _clearError() {
    if (_error != null) {
      _error = null;
      notifyListeners();
    }
  }

  void clearError() => _clearError();

  void _sortEquipmentByName() {
    _equipment.sort((a, b) => a.name.toLowerCase().compareTo(b.name.toLowerCase()));
  }
}