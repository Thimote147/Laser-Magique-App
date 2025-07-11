import 'dart:async';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../../core/constants/supabase_config.dart';
import '../models/customer_model.dart';

class CustomerRepository {
  final SupabaseClient _client = SupabaseConfig.client;
  
  RealtimeChannel? _customersChannel;
  final StreamController<List<Customer>> _customersStreamController = StreamController<List<Customer>>.broadcast();
  
  Stream<List<Customer>> get customersStream => _customersStreamController.stream;
  
  CustomerRepository() {
    _initializeRealtimeSubscription();
  }

  void _initializeRealtimeSubscription() {
    _customersChannel = _client.channel('customers_channel');
    
    _customersChannel!.onPostgresChanges(
      event: PostgresChangeEvent.all,
      schema: 'public',
      table: 'customers',
      callback: (payload) {
        _refreshCustomers();
      },
    );
    
    _customersChannel!.subscribe();
    
    _refreshCustomers();
  }
  
  Future<void> _refreshCustomers() async {
    try {
      final customers = await getAllCustomers();
      _customersStreamController.add(customers);
    } catch (e) {
      _customersStreamController.addError(e);
    }
  }

  // Get all customers
  Future<List<Customer>> getAllCustomers() async {
    final response = await _client.from('customers').select();
    return (response as List).map((json) => Customer.fromMap(json)).toList();
  }

  // Search customers
  Future<List<Customer>> searchCustomers(String query) async {
    final response = await _client.rpc(
      'search_customers',
      params: {'search_query': query},
    );

    return (response as List).map((json) => Customer.fromMap(json)).toList();
  }

  // Create a new customer
  Future<Customer> createCustomer(Customer customer) async {
    try {
      final response =
          await _client
              .from('customers')
              .insert(customer.toMap())
              .select()
              .single();

      return Customer.fromMap(response);
    } on PostgrestException catch (e) {
      if (e.message.contains('customers_unique_email')) {
        throw CustomerException(
          'Un client avec le même nom et email existe déjà',
        );
      } else if (e.message.contains('customers_unique_phone')) {
        throw CustomerException(
          'Un client avec le même nom et numéro de téléphone existe déjà',
        );
      }
      rethrow;
    }
  }

  // Update an existing customer
  Future<Customer> updateCustomer(Customer customer) async {
    try {
      final response =
          await _client
              .from('customers')
              .update(customer.toMap())
              .eq('id', customer.id)
              .select()
              .single();

      return Customer.fromMap(response);
    } on PostgrestException catch (e) {
      if (e.message.contains('customers_unique_email')) {
        throw CustomerException(
          'Un client avec le même nom et email existe déjà',
        );
      } else if (e.message.contains('customers_unique_phone')) {
        throw CustomerException(
          'Un client avec le même nom et numéro de téléphone existe déjà',
        );
      }
      rethrow;
    }
  }

  // Get a customer by id
  Future<Customer> getCustomerById(String id) async {
    final response =
        await _client.from('customers').select().eq('id', id).single();

    return Customer.fromMap(response);
  }
  
  void dispose() {
    _customersChannel?.unsubscribe();
    _customersStreamController.close();
  }
}

class CustomerException implements Exception {
  final String message;

  CustomerException(this.message);

  @override
  String toString() => message;
}
