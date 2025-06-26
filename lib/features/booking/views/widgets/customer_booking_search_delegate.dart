import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../viewmodels/customer_view_model.dart';
import '../../viewmodels/booking_view_model.dart';
import '../../models/customer_model.dart';
import '../../models/booking_model.dart';

class CustomerBookingSearchDelegate extends SearchDelegate<Customer?> {
  int _selectedCategory; // 0 = Clients, 1 = Réservations
  final List<String> _categories = ['Clients', 'Réservations'];

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
          child: DefaultTabController(
            length: _categories.length,
            initialIndex: _selectedCategory,
            child: StatefulBuilder(
              builder: (context, setState) {
                final TabController tabController = DefaultTabController.of(
                  context,
                );
                tabController.addListener(() {
                  if (_selectedCategory != tabController.index) {
                    setState(() {
                      _selectedCategory = tabController.index;
                      // Instead of showSuggestions(context), just update the query to trigger a rebuild
                      query = query;
                    });
                  }
                });
                return Container(
                  margin: const EdgeInsets.symmetric(horizontal: 12),
                  decoration: BoxDecoration(
                    color: colorScheme.surfaceVariant.withOpacity(0.3),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: TabBar(
                    controller: tabController,
                    labelColor: colorScheme.primary,
                    unselectedLabelColor: colorScheme.onSurfaceVariant,
                    labelStyle: const TextStyle(fontWeight: FontWeight.w600),
                    unselectedLabelStyle: const TextStyle(
                      fontWeight: FontWeight.w500,
                    ),
                    indicator: BoxDecoration(
                      color: colorScheme.primaryContainer,
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: colorScheme.primary, width: 1),
                    ),
                    indicatorSize: TabBarIndicatorSize.tab,
                    dividerColor: Colors.transparent,
                    labelPadding: const EdgeInsets.symmetric(horizontal: 4),
                    tabs: [
                      Tab(icon: const Icon(Icons.person), text: _categories[0]),
                      Tab(icon: const Icon(Icons.event), text: _categories[1]),
                    ],
                  ),
                );
              },
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
    return Column(
      children: [
        _buildCategorySelector(context),
        Expanded(
          child:
              _selectedCategory == 0
                  ? FutureBuilder(
                    future: customerVM.searchCustomers(query),
                    builder: (context, snapshot) {
                      final customerResults = customerVM.searchResults;
                      if (customerVM.isLoading) {
                        return const Center(child: CircularProgressIndicator());
                      }
                      if (customerResults.isEmpty) {
                        return const Center(child: Text('Aucun client trouvé'));
                      }
                      return ListView(
                        children:
                            customerResults
                                .map(
                                  (customer) => ListTile(
                                    leading: const Icon(Icons.person),
                                    title: Text(
                                      '${customer.firstName} ${customer.lastName}',
                                    ),
                                    subtitle: Text(customer.email),
                                    onTap: () {
                                      showDialog(
                                        context: context,
                                        builder:
                                            (context) => CustomerBookingsDialog(
                                              customer: customer,
                                              bookings:
                                                  bookingVM.bookings
                                                      .where(
                                                        (b) =>
                                                            (b.firstName
                                                                        .toLowerCase() ==
                                                                    customer
                                                                        .firstName
                                                                        .toLowerCase() &&
                                                                (b.lastName
                                                                            ?.toLowerCase() ??
                                                                        '') ==
                                                                    customer
                                                                        .lastName
                                                                        .toLowerCase()),
                                                      )
                                                      .toList(),
                                            ),
                                      );
                                    },
                                  ),
                                )
                                .toList(),
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
    return ListView(
      children:
          bookingResults
              .map(
                (b) => ListTile(
                  leading: const Icon(Icons.event),
                  title: Text('${b.firstName} ${b.lastName ?? ''}'),
                  subtitle: Text(
                    '${b.dateTimeLocal.day}/${b.dateTimeLocal.month}/${b.dateTimeLocal.year} - ${b.formula.name}',
                  ),
                  onTap: () {
                    showDialog(
                      context: context,
                      builder:
                          (context) => AlertDialog(
                            title: Text('Détail réservation'),
                            content: Column(
                              mainAxisSize: MainAxisSize.min,
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  'Client : ${b.firstName} ${b.lastName ?? ''}',
                                ),
                                Text('Email : ${b.email ?? '-'}'),
                                Text('Date : ${b.dateTimeLocal}'),
                                Text('Activité : ${b.formula.activity.name}'),
                                Text('Formule : ${b.formula.name}'),
                                Text('Personnes : ${b.numberOfPersons}'),
                                Text('Parties : ${b.numberOfGames}'),
                              ],
                            ),
                            actions: [
                              TextButton(
                                onPressed: () => Navigator.of(context).pop(),
                                child: const Text('Fermer'),
                              ),
                            ],
                          ),
                    );
                  },
                ),
              )
              .toList(),
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
    return ListView(
      children:
          bookingResults
              .map(
                (b) => ListTile(
                  leading: const Icon(Icons.event),
                  title: Text('${b.firstName} ${b.lastName ?? ''}'),
                  subtitle: Text(
                    '${b.dateTimeLocal.day}/${b.dateTimeLocal.month}/${b.dateTimeLocal.year} - ${b.formula.name}',
                  ),
                  onTap: () {
                    showDialog(
                      context: context,
                      builder:
                          (context) => AlertDialog(
                            title: Text('Détail réservation'),
                            content: Column(
                              mainAxisSize: MainAxisSize.min,
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  'Client : ${b.firstName} ${b.lastName ?? ''}',
                                ),
                                Text('Email : ${b.email ?? '-'}'),
                                Text('Date : ${b.dateTimeLocal}'),
                                Text('Activité : ${b.formula.activity.name}'),
                                Text('Formule : ${b.formula.name}'),
                                Text('Personnes : ${b.numberOfPersons}'),
                                Text('Parties : ${b.numberOfGames}'),
                              ],
                            ),
                            actions: [
                              TextButton(
                                onPressed: () => Navigator.of(context).pop(),
                                child: const Text('Fermer'),
                              ),
                            ],
                          ),
                    );
                  },
                ),
              )
              .toList(),
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
