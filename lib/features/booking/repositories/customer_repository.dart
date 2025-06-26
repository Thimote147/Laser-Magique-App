import 'package:supabase_flutter/supabase_flutter.dart';
import '../../../core/constants/supabase_config.dart';
import '../models/customer_model.dart';

class CustomerRepository {
  final SupabaseClient _client = SupabaseConfig.client;

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
}

class CustomerException implements Exception {
  final String message;

  CustomerException(this.message);

  @override
  String toString() => message;
}
