import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../viewmodels/customer_view_model.dart';
import '../../viewmodels/booking_view_model.dart';
import '../../models/customer_model.dart';
import '../../models/booking_model.dart';
import '../screens/booking_details_screen.dart';
import '../screens/customer_details_screen.dart';

class CustomerBookingSearchDelegate extends SearchDelegate<Customer?> {
  int _selectedCategory; // 0 = Clients, 1 = Réservations
  final List<String> _categories = ['Clients', 'Réservations'];
  String _lastQuery = '';
  Future<void>? _searchFuture;

  CustomerBookingSearchDelegate({int selectedCategory = 0})
    : _selectedCategory = selectedCategory;

  @override
  String get searchFieldLabel {
    if (_selectedCategory == 0) {
      return 'Rechercher un client';
    } else {
      return 'Rechercher une réservation';
    }
  }

  @override
  List<Widget> buildActions(BuildContext context) {
    return [
      IconButton(
        icon: const Icon(Icons.clear),
        onPressed: () {
          query = '';
          showSuggestions(context);
        },
      ),
    ];
  }

  @override
  Widget buildLeading(BuildContext context) {
    return IconButton(
      icon: const Icon(Icons.arrow_back),
      onPressed: () => close(context, null),
    );
  }

  Widget _buildCategorySelector(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Center(
        child: SizedBox(
          height: 48,
          child: Container(
            margin: const EdgeInsets.symmetric(horizontal: 12),
            decoration: BoxDecoration(
              color: colorScheme.surfaceContainerHighest.withAlpha(
                (255 * 0.3).round(),
              ),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                for (int i = 0; i < _categories.length; i++)
                  Flexible(
                    child: GestureDetector(
                      onTap: () {
                        if (_selectedCategory != i) {
                          _selectedCategory = i;
                          // Force un rebuild sans utiliser setState
                          this.showSuggestions(context);
                        }
                      },
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 16,
                          vertical: 8,
                        ),
                        decoration: BoxDecoration(
                          color:
                              _selectedCategory == i
                                  ? colorScheme.primaryContainer
                                  : Colors.transparent,
                          borderRadius: BorderRadius.circular(12),
                          border:
                              _selectedCategory == i
                                  ? Border.all(
                                    color: colorScheme.primary,
                                    width: 1,
                                  )
                                  : null,
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(
                              i == 0 ? Icons.person : Icons.event,
                              color:
                                  _selectedCategory == i
                                      ? colorScheme.primary
                                      : colorScheme.onSurfaceVariant,
                            ),
                            const SizedBox(width: 8),
                            Text(
                              _categories[i],
                              style: TextStyle(
                                color:
                                    _selectedCategory == i
                                        ? colorScheme.primary
                                        : colorScheme.onSurfaceVariant,
                                fontWeight:
                                    _selectedCategory == i
                                        ? FontWeight.w600
                                        : FontWeight.w500,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  @override
  Widget buildResults(BuildContext context) {
    final customerVM = Provider.of<CustomerViewModel>(context, listen: false);
    final bookingVM = Provider.of<BookingViewModel>(context, listen: false);

    if (_lastQuery != query) {
      _lastQuery = query;
      if (_selectedCategory == 0) {
        _searchFuture = customerVM.searchCustomers(query);
      }
    }

    return Column(
      children: [
        _buildCategorySelector(context),
        Expanded(
          child:
              _selectedCategory == 0
                  ? FutureBuilder(
                    future: _searchFuture,
                    builder: (context, snapshot) {
                      if (snapshot.connectionState == ConnectionState.waiting) {
                        return const Center(child: CircularProgressIndicator());
                      }

                      final customerResults = customerVM.searchResults;
                      if (customerResults.isEmpty) {
                        return const Center(child: Text('Aucun client trouvé'));
                      }

                      return ListView.builder(
                        itemCount: customerResults.length,
                        itemBuilder: (context, index) {
                          final customer = customerResults[index];
                          return ListTile(
                            leading: const Icon(Icons.person),
                            title: Text(
                              '${customer.firstName} ${customer.lastName}',
                            ),
                            subtitle: Text(customer.email),
                            onTap: () {
                              final customerBookings =
                                  bookingVM.bookings
                                      .where(
                                        (b) =>
                                            (b.firstName.toLowerCase() ==
                                                    customer.firstName
                                                        .toLowerCase() &&
                                                (b.lastName?.toLowerCase() ??
                                                        '') ==
                                                    customer.lastName
                                                        .toLowerCase()),
                                      )
                                      .toList();

                              Navigator.pop(context); // Fermer la recherche
                              Navigator.push(
                                context,
                                MaterialPageRoute(
                                  builder:
                                      (context) => CustomerDetailsScreen(
                                        customer: customer,
                                        bookings: customerBookings,
                                      ),
                                ),
                              );
                            },
                          );
                        },
                      );
                    },
                  )
                  : _buildBookingResults(context, bookingVM),
        ),
      ],
    );
  }

  Widget _buildBookingResults(
    BuildContext context,
    BookingViewModel bookingVM,
  ) {
    final bookingResults =
        bookingVM.bookings.where((b) {
          final q = query.toLowerCase();
          final dateStr =
              '${b.dateTimeLocal.day.toString().padLeft(2, '0')}/${b.dateTimeLocal.month.toString().padLeft(2, '0')}/${b.dateTimeLocal.year} ${b.dateTimeLocal.hour.toString().padLeft(2, '0')}:${b.dateTimeLocal.minute.toString().padLeft(2, '0')}'
                  .toLowerCase();
          return b.firstName.toLowerCase().contains(q) ||
              (b.lastName?.toLowerCase() ?? '').contains(q) ||
              (b.email?.toLowerCase() ?? '').contains(q) ||
              (b.phone?.toLowerCase() ?? '').contains(q) ||
              b.formula.name.toLowerCase().contains(q) ||
              b.formula.activity.name.toLowerCase().contains(q) ||
              b.dateTimeLocal.toString().contains(q) ||
              dateStr.contains(q);
        }).toList();
    if (bookingResults.isEmpty) {
      return const Center(child: Text('Aucune réservation trouvée'));
    }
    return ListView.builder(
      itemCount: bookingResults.length,
      itemBuilder: (context, index) {
        final booking = bookingResults[index];
        return ListTile(
          leading: const Icon(Icons.event),
          title: Text('${booking.firstName} ${booking.lastName ?? ''}'),
          subtitle: Text(
            '${booking.dateTimeLocal.day}/${booking.dateTimeLocal.month}/${booking.dateTimeLocal.year} - ${booking.formula.name}',
          ),
          onTap: () {
            Navigator.pop(context); // Fermer la recherche
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (context) => BookingDetailsScreen(booking: booking),
              ),
            );
          },
        );
      },
    );
  }

  @override
  Widget buildSuggestions(BuildContext context) {
    return Column(
      children: [
        _buildCategorySelector(context),
        Expanded(
          child:
              _selectedCategory == 0
                  ? _buildClientSuggestions(context)
                  : _buildBookingSuggestions(context),
        ),
      ],
    );
  }

  Widget _buildClientSuggestions(BuildContext context) {
    final customerVM = Provider.of<CustomerViewModel>(context);
    final customerResults =
        customerVM.customers
            .where(
              (c) =>
                  c.firstName.toLowerCase().contains(query.toLowerCase()) ||
                  c.lastName.toLowerCase().contains(query.toLowerCase()) ||
                  c.email.toLowerCase().contains(query.toLowerCase()) ||
                  c.phone.toLowerCase().contains(query.toLowerCase()),
            )
            .toList();
    if (customerResults.isEmpty) {
      return const Center(child: Text('Aucun client trouvé'));
    }
    return ListView(
      children:
          customerResults
              .map(
                (customer) => ListTile(
                  leading: const Icon(Icons.person),
                  title: Text('${customer.firstName} ${customer.lastName}'),
                  subtitle: Text(customer.email),
                  onTap: () {
                    query = customer.lastName;
                    showResults(context);
                  },
                ),
              )
              .toList(),
    );
  }

  Widget _buildBookingSuggestions(BuildContext context) {
    final bookingVM = Provider.of<BookingViewModel>(context);
    final bookingResults =
        bookingVM.bookings.where((b) {
          final q = query.toLowerCase();
          final dateStr =
              '${b.dateTimeLocal.day.toString().padLeft(2, '0')}/${b.dateTimeLocal.month.toString().padLeft(2, '0')}/${b.dateTimeLocal.year} ${b.dateTimeLocal.hour.toString().padLeft(2, '0')}:${b.dateTimeLocal.minute.toString().padLeft(2, '0')}'
                  .toLowerCase();
          return b.firstName.toLowerCase().contains(q) ||
              (b.lastName?.toLowerCase() ?? '').contains(q) ||
              (b.email?.toLowerCase() ?? '').contains(q) ||
              (b.phone?.toLowerCase() ?? '').contains(q) ||
              b.formula.name.toLowerCase().contains(q) ||
              b.formula.activity.name.toLowerCase().contains(q) ||
              b.dateTimeLocal.toString().contains(q) ||
              dateStr.contains(q);
        }).toList();
    if (bookingResults.isEmpty) {
      return const Center(child: Text('Aucune réservation trouvée'));
    }
    return ListView.builder(
      itemCount: bookingResults.length,
      itemBuilder: (context, index) {
        final booking = bookingResults[index];
        return ListTile(
          leading: const Icon(Icons.event),
          title: Text('${booking.firstName} ${booking.lastName ?? ''}'),
          subtitle: Text(
            '${booking.dateTimeLocal.day}/${booking.dateTimeLocal.month}/${booking.dateTimeLocal.year} - ${booking.formula.name}',
          ),
          onTap: () {
            Navigator.pop(context); // Fermer la recherche
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (context) => BookingDetailsScreen(booking: booking),
              ),
            );
          },
        );
      },
    );
  }
}

class CustomerBookingsDialog extends StatelessWidget {
  final Customer customer;
  final List<Booking> bookings;
  const CustomerBookingsDialog({
    super.key,
    required this.customer,
    required this.bookings,
  });

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: Text('Réservations de ${customer.firstName} ${customer.lastName}'),
      content:
          bookings.isEmpty
              ? const Text('Aucune réservation trouvée pour ce client.')
              : SizedBox(
                width: 350,
                child: ListView.separated(
                  shrinkWrap: true,
                  itemCount: bookings.length,
                  separatorBuilder: (context, i) => const Divider(),
                  itemBuilder: (context, i) {
                    final b = bookings[i];
                    return ListTile(
                      title: Text(
                        '${b.dateTimeLocal.day}/${b.dateTimeLocal.month}/${b.dateTimeLocal.year} - ${b.formula.name}',
                      ),
                      subtitle: Text(
                        '${b.numberOfPersons} pers. - ${b.numberOfGames} parties',
                      ),
                    );
                  },
                ),
              ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: const Text('Fermer'),
        ),
      ],
    );
  }
}
