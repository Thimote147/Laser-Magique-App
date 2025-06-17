import 'package:supabase_flutter/supabase_flutter.dart';
import '../config/supabase_config.dart';
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
    final response =
        await _client
            .from('customers')
            .insert(customer.toMap())
            .select()
            .single();

    return Customer.fromMap(response);
  }

  // Update an existing customer
  Future<Customer> updateCustomer(Customer customer) async {
    final response =
        await _client
            .from('customers')
            .update(customer.toMap())
            .eq('id', customer.id)
            .select()
            .single();

    return Customer.fromMap(response);
  }

  // Get a customer by id
  Future<Customer> getCustomerById(String id) async {
    final response =
        await _client.from('customers').select().eq('id', id).single();

    return Customer.fromMap(response);
  }
}
