import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'dart:math';
import '../../models/customer_model.dart';
import '../../viewmodels/customer_view_model.dart';

class CustomerSelectionWidget extends StatefulWidget {
  final Function(Customer?) onCustomerSelected;
  final Function(bool)? onCreatingChange;
  final Customer? initialCustomer;
  final bool allowCreation;

  const CustomerSelectionWidget({
    super.key,
    required this.onCustomerSelected,
    this.onCreatingChange,
    this.initialCustomer,
    this.allowCreation = true,
  });

  @override
  State<CustomerSelectionWidget> createState() =>
      _CustomerSelectionWidgetState();
}

class _CustomerSelectionWidgetState extends State<CustomerSelectionWidget> {
  final TextEditingController _searchController = TextEditingController();
  final TextEditingController _firstNameController = TextEditingController();
  final TextEditingController _lastNameController = TextEditingController();
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _phoneController = TextEditingController();
  bool _isCreatingNew = false;

  @override
  void initState() {
    super.initState();
    if (widget.initialCustomer != null) {
      _searchController.text =
          '${widget.initialCustomer!.firstName} ${widget.initialCustomer!.lastName}';
    }
  }

  @override
  void dispose() {
    _searchController.dispose();
    _firstNameController.dispose();
    _lastNameController.dispose();
    _emailController.dispose();
    _phoneController.dispose();
    super.dispose();
  }

  void _handleError(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: Theme.of(context).colorScheme.error,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<CustomerViewModel>(
      builder: (context, viewModel, child) {
        return Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            if (!_isCreatingNew) ...[
              Row(
                children: [
                  Expanded(
                    child: TextField(
                      controller: _searchController,
                      decoration: InputDecoration(
                        hintText: 'Rechercher un client',
                        hintStyle: TextStyle(
                          color: Theme.of(context).colorScheme.outline,
                        ),
                        prefixIcon: Icon(
                          Icons.search_rounded,
                          size: 20,
                          color: Theme.of(context).colorScheme.outline,
                        ),
                        filled: true,
                        fillColor: Theme.of(
                          context,
                        ).colorScheme.surfaceVariant.withOpacity(0.3),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                          borderSide: BorderSide.none,
                        ),
                        focusedBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                          borderSide: BorderSide(
                            color: Theme.of(context).colorScheme.primary,
                            width: 1.5,
                          ),
                        ),
                        contentPadding: const EdgeInsets.symmetric(
                          horizontal: 16,
                          vertical: 12,
                        ),
                      ),
                      style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                        color: Theme.of(context).colorScheme.onSurface,
                      ),
                      cursorColor: Theme.of(context).colorScheme.primary,
                      onChanged: (value) => viewModel.searchCustomers(value),
                    ),
                  ),
                  if (widget.allowCreation) ...[
                    const SizedBox(width: 8),
                    IconButton.filled(
                      onPressed:
                          () => setState(() {
                            _isCreatingNew = true;
                            widget.onCreatingChange?.call(_isCreatingNew);
                          }),
                      icon: const Icon(Icons.add_rounded, size: 20),
                      tooltip: 'Créer un nouveau client',
                      style: IconButton.styleFrom(
                        backgroundColor: Theme.of(context).colorScheme.primary,
                        foregroundColor:
                            Theme.of(context).colorScheme.onPrimary,
                        padding: const EdgeInsets.all(12),
                      ),
                    ),
                  ],
                ],
              ),
              const SizedBox(height: 12),
              _buildSearchResults(viewModel),
            ] else
              Padding(
                padding: const EdgeInsets.all(16),
                child: _buildNewCustomerForm(viewModel),
              ),
          ],
        );
      },
    );
  }

  Widget _buildSearchResults(CustomerViewModel viewModel) {
    if (viewModel.isLoading) {
      return const Center(child: CircularProgressIndicator());
    }

    if (viewModel.searchQuery.isNotEmpty && viewModel.searchResults.isEmpty) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 8),
          child: Text(
            'Aucun client trouvé',
            style: TextStyle(color: Theme.of(context).colorScheme.outline),
          ),
        ),
      );
    }

    if (viewModel.searchQuery.isNotEmpty) {
      const itemBaseHeight = 52.0; // Hauteur réduite pour un ListTile
      const maxVisibleItems = 3.0;
      const verticalPadding = 2.0; // Padding vertical réduit

      final totalHeight =
          (itemBaseHeight + (verticalPadding * 2)) *
          min(maxVisibleItems, viewModel.searchResults.length.toDouble());

      return Container(
        height: totalHeight,
        decoration: BoxDecoration(
          color: Theme.of(context).colorScheme.surfaceVariant.withOpacity(0.3),
          borderRadius: BorderRadius.circular(12),
        ),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(12),
          child: ListView.builder(
            padding: EdgeInsets.zero,
            itemCount: viewModel.searchResults.length,
            itemBuilder: (context, index) {
              final customer = viewModel.searchResults[index];
              return Padding(
                padding: const EdgeInsets.symmetric(vertical: verticalPadding),
                child: ListTile(
                  dense: true,
                  visualDensity: VisualDensity.compact,
                  minVerticalPadding: 0,
                  leading: Container(
                    padding: const EdgeInsets.all(6),
                    decoration: BoxDecoration(
                      color: Theme.of(
                        context,
                      ).colorScheme.primary.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(6),
                    ),
                    child: Icon(
                      Icons.person_rounded,
                      size: 16,
                      color: Theme.of(context).colorScheme.primary,
                    ),
                  ),
                  title: Text(
                    '${customer.firstName} ${customer.lastName}'.trim(),
                    style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                  subtitle: Text(
                    [customer.email, customer.phone].join(' • '),
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      color: Theme.of(context).colorScheme.onSurfaceVariant,
                      fontSize: 11,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  onTap: () {
                    widget.onCustomerSelected(customer);
                    _searchController.text =
                        '${customer.firstName} ${customer.lastName}'.trim();
                    FocusScope.of(context).unfocus();
                  },
                ),
              );
            },
          ),
        ),
      );
    }

    return const SizedBox.shrink();
  }

  Widget _buildNewCustomerForm(CustomerViewModel viewModel) {
    final formKey = GlobalKey<FormState>();

    return Form(
      key: formKey,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Champs du formulaire
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: TextFormField(
                  controller: _firstNameController,
                  decoration: InputDecoration(
                    isDense: true,
                    labelText: 'Prénom *',
                    hintText: 'Prénom',
                    filled: true,
                    fillColor: Theme.of(
                      context,
                    ).colorScheme.surfaceVariant.withOpacity(0.3),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(8),
                      borderSide: BorderSide.none,
                    ),
                    focusedBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(8),
                      borderSide: BorderSide(
                        color: Theme.of(context).colorScheme.primary,
                        width: 1.5,
                      ),
                    ),
                    errorBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(8),
                      borderSide: BorderSide(
                        color: Theme.of(context).colorScheme.error,
                      ),
                    ),
                    focusedErrorBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(8),
                      borderSide: BorderSide(
                        color: Theme.of(context).colorScheme.error,
                        width: 1.5,
                      ),
                    ),
                  ),
                  validator: (value) {
                    if (value == null || value.isEmpty) {
                      return 'Requis';
                    }
                    return null;
                  },
                  onSaved: (value) => _firstNameController.text = value!,
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: TextFormField(
                  controller: _lastNameController,
                  decoration: InputDecoration(
                    isDense: true,
                    labelText: 'Nom',
                    hintText: 'Nom',
                    filled: true,
                    fillColor: Theme.of(
                      context,
                    ).colorScheme.surfaceVariant.withOpacity(0.3),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(8),
                      borderSide: BorderSide.none,
                    ),
                    focusedBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(8),
                      borderSide: BorderSide(
                        color: Theme.of(context).colorScheme.primary,
                        width: 1.5,
                      ),
                    ),
                  ),
                  onSaved: (value) => _lastNameController.text = value ?? '',
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          TextFormField(
            controller: _emailController,
            decoration: InputDecoration(
              isDense: true,
              labelText: 'Email',
              hintText: 'email@exemple.com',
              filled: true,
              fillColor: Theme.of(
                context,
              ).colorScheme.surfaceVariant.withOpacity(0.3),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(8),
                borderSide: BorderSide.none,
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(8),
                borderSide: BorderSide(
                  color: Theme.of(context).colorScheme.primary,
                  width: 1.5,
                ),
              ),
              prefixIcon: Icon(
                Icons.email_rounded,
                size: 18,
                color: Theme.of(context).colorScheme.outline,
              ),
            ),
            keyboardType: TextInputType.emailAddress,
            onSaved: (value) => _emailController.text = value!,
          ),
          const SizedBox(height: 12),
          TextFormField(
            controller: _phoneController,
            decoration: InputDecoration(
              isDense: true,
              labelText: 'Téléphone',
              hintText: '06 12 34 56 78',
              filled: true,
              fillColor: Theme.of(
                context,
              ).colorScheme.surfaceVariant.withOpacity(0.3),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(8),
                borderSide: BorderSide.none,
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(8),
                borderSide: BorderSide(
                  color: Theme.of(context).colorScheme.primary,
                  width: 1.5,
                ),
              ),
              prefixIcon: Icon(
                Icons.phone_rounded,
                size: 18,
                color: Theme.of(context).colorScheme.outline,
              ),
            ),
            keyboardType: TextInputType.phone,
            onSaved: (value) => _phoneController.text = value!,
          ),
          const SizedBox(height: 16),
          Row(
            mainAxisAlignment: MainAxisAlignment.end,
            children: [
              TextButton(
                onPressed: () {
                  setState(() => _isCreatingNew = false);
                  if (widget.onCreatingChange != null) {
                    widget.onCreatingChange!(false);
                  }
                },
                child: const Text('Annuler'),
              ),
              const SizedBox(width: 8),
              FilledButton.icon(
                onPressed: () async {
                  if (_firstNameController.text.isEmpty ||
                      _lastNameController.text.isEmpty ||
                      _emailController.text.isEmpty ||
                      _phoneController.text.isEmpty) {
                    _handleError('Tous les champs sont obligatoires');
                    return;
                  }

                  final customer = Customer(
                    firstName: _firstNameController.text,
                    lastName: _lastNameController.text,
                    email: _emailController.text,
                    phone: _phoneController.text,
                  );

                  try {
                    final newCustomer = await viewModel.createCustomer(
                      customer,
                    );
                    widget.onCustomerSelected(newCustomer);
                    setState(() => _isCreatingNew = false);
                  } catch (e) {
                    _handleError(e.toString());
                  }
                },
                icon: const Icon(Icons.check_rounded, size: 20),
                label: const Text('Créer le client'),
                style: FilledButton.styleFrom(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 24,
                    vertical: 12,
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
