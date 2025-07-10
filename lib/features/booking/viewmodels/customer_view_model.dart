import 'dart:async';
import 'package:flutter/foundation.dart';
import '../models/customer_model.dart';
import '../repositories/customer_repository.dart';

class CustomerViewModel extends ChangeNotifier {
  final CustomerRepository _repository = CustomerRepository();
  List<Customer> _customers = [];
  List<Customer> _searchResults = [];
  bool _isLoading = false;
  String? _error;
  String _searchQuery = '';
  StreamSubscription? _customersSubscription;

  List<Customer> get customers => _customers;
  List<Customer> get searchResults => _searchResults;
  bool get isLoading => _isLoading;
  String? get error => _error;
  String get searchQuery => _searchQuery;

  CustomerViewModel() {
    _initializeRealtimeSubscription();
  }
  
  void _initializeRealtimeSubscription() {
    _customersSubscription = _repository.customersStream.listen(
      (customers) {
        _customers = customers;
        _isLoading = false;
        _error = null;
        notifyListeners();
      },
      onError: (error) {
        _error = 'Erreur lors du chargement des clients: $error';
        _isLoading = false;
        notifyListeners();
      },
    );
  }
  
  @override
  void dispose() {
    _customersSubscription?.cancel();
    _repository.dispose();
    super.dispose();
  }

  Future<void> loadCustomers() async {
    // Cette méthode est maintenant gérée par le stream Realtime
    // Elle est conservée pour compatibilité mais ne fait plus rien
  }

  Future<void> searchCustomers(String query) async {
    try {
      _searchQuery = query;
      _isLoading = true;
      _error = null;
      notifyListeners();

      if (query.isEmpty) {
        _searchResults = [];
      } else {
        _searchResults = await _repository.searchCustomers(query);
      }
    } catch (e) {
      _error = 'Erreur lors de la recherche: $e';
      _searchResults = [];
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<Customer> createCustomer(Customer customer) async {
    try {
      _isLoading = true;
      _error = null;
      notifyListeners();

      final newCustomer = await _repository.createCustomer(customer);
      // Le stream Realtime se chargera automatiquement de mettre à jour _customers
      return newCustomer;
    } on CustomerException catch (e) {
      _error = e.toString();
      notifyListeners();
      rethrow;
    } catch (e) {
      _error = 'Erreur lors de la création du client: $e';
      notifyListeners();
      rethrow;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<void> updateCustomer(Customer customer) async {
    try {
      _isLoading = true;
      _error = null;
      notifyListeners();

      await _repository.updateCustomer(customer);
      // Le stream Realtime se chargera automatiquement de mettre à jour _customers
    } on CustomerException catch (e) {
      _error = e.toString();
      notifyListeners();
      rethrow;
    } catch (e) {
      _error = 'Erreur lors de la mise à jour du client: $e';
      notifyListeners();
      rethrow;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<Customer?> getCustomerById(String id) async {
    try {
      return await _repository.getCustomerById(id);
    } catch (e) {
      _error = 'Erreur lors de la récupération du client: $e';
      return null;
    }
  }

  void clearError() {
    _error = null;
    notifyListeners();
  }

  void clearSearchResults() {
    _searchResults = [];
    _searchQuery = '';
    notifyListeners();
  }
}
