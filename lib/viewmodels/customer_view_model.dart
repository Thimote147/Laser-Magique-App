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

  List<Customer> get customers => _customers;
  List<Customer> get searchResults => _searchResults;
  bool get isLoading => _isLoading;
  String? get error => _error;
  String get searchQuery => _searchQuery;

  CustomerViewModel() {
    loadCustomers();
  }

  Future<void> loadCustomers() async {
    try {
      _isLoading = true;
      _error = null;
      notifyListeners();

      _customers = await _repository.getAllCustomers();
    } catch (e) {
      _error = 'Error loading customers: $e';
    } finally {
      _isLoading = false;
      notifyListeners();
    }
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
      _error = 'Error searching customers: $e';
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
      _customers.add(newCustomer);
      return newCustomer;
    } catch (e) {
      _error = 'Error creating customer: $e';
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

      final updatedCustomer = await _repository.updateCustomer(customer);
      final index = _customers.indexWhere((c) => c.id == customer.id);
      if (index != -1) {
        _customers[index] = updatedCustomer;
      }
    } catch (e) {
      _error = 'Error updating customer: $e';
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
      _error = 'Error getting customer: $e';
      return null;
    }
  }

  void clearError() {
    _error = null;
    notifyListeners();
  }

  // Vider la liste des résultats de recherche
  void clearSearchResults() {
    _searchResults = [];
    _searchQuery = '';
    notifyListeners();
  }
}
