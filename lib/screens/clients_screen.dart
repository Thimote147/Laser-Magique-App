import 'package:flutter/material.dart';
import 'package:flutter/cupertino.dart';
import '../main.dart'; // For supabase client

class Client {
  final int id;
  final String name;
  final String email;
  final String phone;
  final String notes;
  final int totalBookings;
  final DateTime createdAt;
  final String profileImageUrl;

  Client({
    required this.id,
    required this.name,
    required this.email,
    required this.phone,
    required this.notes,
    required this.totalBookings,
    required this.createdAt,
    required this.profileImageUrl,
  });

  factory Client.fromJson(Map<String, dynamic> json) {
    return Client(
      id: json['id'] ?? 0,
      name: json['name'] ?? '',
      email: json['email'] ?? '',
      phone: json['phone'] ?? '',
      notes: json['notes'] ?? '',
      totalBookings: json['total_bookings'] ?? 0,
      createdAt:
          json['created_at'] != null
              ? DateTime.parse(json['created_at'])
              : DateTime.now(),
      profileImageUrl: json['profile_image_url'] ?? '',
    );
  }
}

class ClientsScreen extends StatefulWidget {
  const ClientsScreen({Key? key}) : super(key: key);

  @override
  ClientsScreenState createState() => ClientsScreenState();
}

class ClientsScreenState extends State<ClientsScreen> {
  bool _isLoading = false;
  List<Client> _clients = [];
  String _searchQuery = '';
  final TextEditingController _searchController = TextEditingController();
  bool _showSearch = false;
  List<Client> _filteredClients = [];

  @override
  void initState() {
    super.initState();
    _fetchClients();
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _fetchClients() async {
    setState(() {
      _isLoading = true;
    });

    try {
      // In a real app, you'd replace this with your actual Supabase query
      final response = await supabase
          .from('clients')
          .select('*, bookings:bookings(count)')
          .order('name');

      setState(() {
        _clients =
            (response as List).map((json) => Client.fromJson(json)).toList();
        _filteredClients = _clients;
        _isLoading = false;
      });
    } catch (e) {
      print('Error fetching clients: $e');

      // For demo purposes, add sample clients if the table doesn't exist
      setState(() {
        _clients = _getSampleClients();
        _filteredClients = _clients;
        _isLoading = false;
      });
    }
  }

  // Sample data for demonstration
  List<Client> _getSampleClients() {
    return [
      Client(
        id: 1,
        name: 'Sophie Martin',
        email: 'sophie.martin@example.com',
        phone: '+33 6 12 34 56 78',
        notes: 'Prefers appointments in the afternoon',
        totalBookings: 5,
        createdAt: DateTime.now().subtract(const Duration(days: 60)),
        profileImageUrl: '',
      ),
      Client(
        id: 2,
        name: 'Emma Bernard',
        email: 'emma.bernard@example.com',
        phone: '+33 6 23 45 67 89',
        notes: 'Allergic to some products, check notes before treatment',
        totalBookings: 8,
        createdAt: DateTime.now().subtract(const Duration(days: 120)),
        profileImageUrl: '',
      ),
      Client(
        id: 3,
        name: 'Liam Dubois',
        email: 'liam.dubois@example.com',
        phone: '+33 6 34 56 78 90',
        notes: 'VIP client, offers special discounts',
        totalBookings: 12,
        createdAt: DateTime.now().subtract(const Duration(days: 90)),
        profileImageUrl: '',
      ),
      Client(
        id: 4,
        name: 'Olivia Petit',
        email: 'olivia.petit@example.com',
        phone: '+33 6 45 67 89 01',
        notes: 'Sensitive skin, use gentle settings',
        totalBookings: 3,
        createdAt: DateTime.now().subtract(const Duration(days: 30)),
        profileImageUrl: '',
      ),
      Client(
        id: 5,
        name: 'Noah Moreau',
        email: 'noah.moreau@example.com',
        phone: '+33 6 56 78 90 12',
        notes: '',
        totalBookings: 1,
        createdAt: DateTime.now().subtract(const Duration(days: 10)),
        profileImageUrl: '',
      ),
    ];
  }

  List<Client> _getFilteredClients() {
    if (_searchQuery.isEmpty) {
      return _clients;
    }

    final query = _searchQuery.toLowerCase();
    return _clients.where((client) {
      return client.name.toLowerCase().contains(query) ||
          client.email.toLowerCase().contains(query) ||
          client.phone.contains(query);
    }).toList();
  }

  void _filterClients(String query) {
    setState(() {
      _searchQuery = query;
      _filteredClients = _getFilteredClients();
    });
  }

  @override
  Widget build(BuildContext context) {
    return CupertinoPageScaffold(
      backgroundColor: CupertinoColors.systemGroupedBackground,
      navigationBar: CupertinoNavigationBar(
        padding: EdgeInsetsDirectional.only(start: 16, end: 8),
        middle: null,
        backgroundColor: CupertinoColors.systemGroupedBackground,
        border: null,
        leading: const Text(
          'Clients',
          style: TextStyle(
            fontWeight: FontWeight.bold,
            fontSize: 25,
            color: CupertinoColors.black,
            fontFamily: '.SF Pro Display',
          ),
        ),
        trailing: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            CupertinoButton(
              padding: EdgeInsets.zero,
              child: const Icon(CupertinoIcons.search),
              onPressed: () {
                // Show search
                setState(() {
                  _showSearch = !_showSearch;
                });
              },
            ),
            const SizedBox(width: 8),
            CupertinoButton(
              padding: EdgeInsets.zero,
              child: const Icon(CupertinoIcons.person_add, size: 28),
              onPressed: () {
                _showAddClientDialog();
              },
            ),
          ],
        ),
      ),
      child: SafeArea(
        child:
            _isLoading
                ? const Center(child: CupertinoActivityIndicator())
                : Column(
                  children: [
                    if (_showSearch)
                      Padding(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 16.0,
                          vertical: 8.0,
                        ),
                        child: CupertinoSearchTextField(
                          controller: _searchController,
                          placeholder: 'Search clients...',
                          onChanged: _filterClients,
                          backgroundColor: CupertinoColors.white,
                          borderRadius: BorderRadius.circular(10),
                        ),
                      ),
                    Expanded(
                      child:
                          _filteredClients.isEmpty
                              ? _buildEmptyState()
                              : ListView.builder(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 16.0,
                                ),
                                physics: const AlwaysScrollableScrollPhysics(
                                  parent: BouncingScrollPhysics(),
                                ),
                                itemCount: _filteredClients.length,
                                itemBuilder: (context, index) {
                                  final client = _filteredClients[index];
                                  return _buildClientCard(context, client);
                                },
                              ),
                    ),
                  ],
                ),
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Icon(CupertinoIcons.person_2_alt, size: 50, color: Colors.grey),
          const SizedBox(height: 16),
          Text(
            _searchQuery.isEmpty
                ? 'No clients yet'
                : 'No clients match your search',
            style: const TextStyle(fontSize: 16, color: Colors.grey),
          ),
          if (_searchQuery.isNotEmpty)
            TextButton(
              onPressed: () {
                _searchController.clear();
                setState(() {
                  _searchQuery = '';
                  _filteredClients = _clients;
                });
              },
              child: const Text('Clear search'),
            ),
        ],
      ),
    );
  }

  Widget _buildClientCard(BuildContext context, Client client) {
    return Container(
      margin: const EdgeInsets.symmetric(vertical: 6, horizontal: 4),
      decoration: BoxDecoration(
        color: CupertinoColors.white,
        borderRadius: BorderRadius.circular(15),
        boxShadow: [
          BoxShadow(
            color: CupertinoColors.systemGrey5.withOpacity(0.5),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: CupertinoButton(
        padding: EdgeInsets.zero,
        onPressed: () {
          _navigateToClientDetails(client);
        },
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Row(
            children: [
              _buildClientAvatar(client),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      client.name,
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                        color: CupertinoColors.black,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Row(
                      children: [
                        const Icon(
                          CupertinoIcons.phone,
                          size: 14,
                          color: CupertinoColors.systemGrey,
                        ),
                        const SizedBox(width: 4),
                        Text(
                          client.phone,
                          style: const TextStyle(
                            fontSize: 14,
                            color: CupertinoColors.systemGrey,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 2),
                    Row(
                      children: [
                        const Icon(
                          CupertinoIcons.mail,
                          size: 14,
                          color: CupertinoColors.systemGrey,
                        ),
                        const SizedBox(width: 4),
                        Expanded(
                          child: Text(
                            client.email,
                            style: const TextStyle(
                              fontSize: 14,
                              color: CupertinoColors.systemGrey,
                            ),
                            overflow: TextOverflow.ellipsis,
                            maxLines: 1,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 10,
                      vertical: 4,
                    ),
                    decoration: BoxDecoration(
                      color: CupertinoTheme.of(
                        context,
                      ).primaryColor.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Text(
                      '${client.totalBookings} bookings',
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                        color: CupertinoTheme.of(context).primaryColor,
                      ),
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Client since ${_formatDate(client.createdAt)}',
                    style: const TextStyle(
                      fontSize: 12,
                      color: CupertinoColors.systemGrey,
                    ),
                  ),
                  const SizedBox(height: 4),
                  const Icon(
                    CupertinoIcons.chevron_right,
                    color: CupertinoColors.systemGrey3,
                    size: 16,
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildClientAvatar(Client client) {
    final initials =
        client.name.isNotEmpty
            ? client.name
                .split(' ')
                .map((word) => word[0])
                .take(2)
                .join()
                .toUpperCase()
            : '?';

    return CircleAvatar(
      radius: 26,
      backgroundColor: Theme.of(context).primaryColor,
      child:
          client.profileImageUrl.isNotEmpty
              ? ClipRRect(
                borderRadius: BorderRadius.circular(26),
                child: Image.network(
                  client.profileImageUrl,
                  fit: BoxFit.cover,
                  width: 52,
                  height: 52,
                  errorBuilder: (context, error, stackTrace) {
                    return Text(
                      initials,
                      style: const TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                        fontSize: 18,
                      ),
                    );
                  },
                ),
              )
              : Text(
                initials,
                style: const TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                  fontSize: 18,
                ),
              ),
    );
  }

  String _formatDate(DateTime date) {
    final now = DateTime.now();
    final difference = now.difference(date);

    if (difference.inDays < 30) {
      return '${difference.inDays} days ago';
    } else if (difference.inDays < 365) {
      final months = (difference.inDays / 30).floor();
      return '$months ${months == 1 ? 'month' : 'months'} ago';
    } else {
      final years = (difference.inDays / 365).floor();
      return '$years ${years == 1 ? 'year' : 'years'} ago';
    }
  }

  void _navigateToClientDetails(Client client) {
    // Present client details in a sheet with iOS-like appearance
    showCupertinoModalPopup(
      context: context,
      builder:
          (context) => CupertinoPageScaffold(
            backgroundColor: CupertinoColors.systemGroupedBackground,
            navigationBar: CupertinoNavigationBar(
              middle: Text(client.name),
              backgroundColor: CupertinoColors.systemGroupedBackground,
              border: null,
              trailing: CupertinoButton(
                padding: EdgeInsets.zero,
                child: const Icon(CupertinoIcons.ellipsis_circle, size: 24),
                onPressed: () {
                  _showClientActions(context, client);
                },
              ),
            ),
            child: SafeArea(
              bottom: false,
              child: ClientDetailView(client: client),
            ),
          ),
    );
  }

  void _showClientActions(BuildContext context, Client client) {
    showCupertinoModalPopup<void>(
      context: context,
      builder:
          (BuildContext context) => CupertinoActionSheet(
            title: const Text('Client Actions'),
            actions: <CupertinoActionSheetAction>[
              CupertinoActionSheetAction(
                onPressed: () {
                  Navigator.pop(context);
                  // Navigate to edit client screen
                },
                child: const Text('Edit Client'),
              ),
              CupertinoActionSheetAction(
                onPressed: () {
                  Navigator.pop(context);
                  // Create new booking for this client
                },
                child: const Text('Create Booking'),
              ),
              CupertinoActionSheetAction(
                onPressed: () {
                  Navigator.pop(context);
                  // Send message functionality
                },
                child: const Text('Send Message'),
              ),
            ],
            cancelButton: CupertinoActionSheetAction(
              isDefaultAction: true,
              onPressed: () {
                Navigator.pop(context);
              },
              child: const Text('Cancel'),
            ),
          ),
    );
  }

  void _showAddClientDialog() {
    final nameController = TextEditingController();
    final emailController = TextEditingController();
    final phoneController = TextEditingController();
    final notesController = TextEditingController();

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder:
          (context) => Padding(
            padding: EdgeInsets.only(
              bottom: MediaQuery.of(context).viewInsets.bottom,
              top: 16,
              left: 16,
              right: 16,
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                const Row(
                  children: [
                    Icon(CupertinoIcons.person_add, size: 28),
                    SizedBox(width: 8),
                    Text(
                      'Add New Client',
                      style: TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                TextField(
                  controller: nameController,
                  decoration: const InputDecoration(labelText: 'Full Name'),
                ),
                const SizedBox(height: 16),
                TextField(
                  controller: emailController,
                  decoration: const InputDecoration(labelText: 'Email'),
                  keyboardType: TextInputType.emailAddress,
                ),
                const SizedBox(height: 16),
                TextField(
                  controller: phoneController,
                  decoration: const InputDecoration(labelText: 'Phone Number'),
                  keyboardType: TextInputType.phone,
                ),
                const SizedBox(height: 16),
                TextField(
                  controller: notesController,
                  decoration: const InputDecoration(labelText: 'Notes'),
                  maxLines: 3,
                ),
                const SizedBox(height: 24),
                SizedBox(
                  width: double.infinity,
                  child: CupertinoButton(
                    color: Theme.of(context).primaryColor,
                    onPressed: () {
                      // In a real app, you'd save to Supabase here
                      final newClient = Client(
                        id: _clients.length + 1,
                        name: nameController.text,
                        email: emailController.text,
                        phone: phoneController.text,
                        notes: notesController.text,
                        totalBookings: 0,
                        createdAt: DateTime.now(),
                        profileImageUrl: '',
                      );

                      setState(() {
                        _clients.add(newClient);
                        _filteredClients = _clients;
                      });

                      Navigator.pop(context);

                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                          content: Text('Client added successfully'),
                          backgroundColor: Colors.green,
                        ),
                      );
                    },
                    child: const Text('Save Client'),
                  ),
                ),
                const SizedBox(height: 24),
              ],
            ),
          ),
    );
  }
}

class ClientDetailView extends StatelessWidget {
  final Client client;

  const ClientDetailView({Key? key, required this.client}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(16.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              CircleAvatar(
                radius: 35,
                backgroundColor: Theme.of(context).primaryColor,
                child: Text(
                  client.name.isNotEmpty
                      ? client.name
                          .split(' ')
                          .map((word) => word[0])
                          .take(2)
                          .join()
                          .toUpperCase()
                      : '?',
                  style: const TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                    fontSize: 24,
                  ),
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      client.name,
                      style: const TextStyle(
                        fontSize: 22,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 8,
                            vertical: 3,
                          ),
                          decoration: BoxDecoration(
                            color: Theme.of(
                              context,
                            ).primaryColor.withOpacity(0.1),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Text(
                            '${client.totalBookings} bookings',
                            style: TextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.w500,
                              color: Theme.of(context).primaryColor,
                            ),
                          ),
                        ),
                        const SizedBox(width: 8),
                        Text(
                          'Client since ${_formatDate(client.createdAt)}',
                          style: const TextStyle(
                            fontSize: 12,
                            color: Colors.grey,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 24),
          _buildContactSection(context),
          const SizedBox(height: 16),
          _buildNotesSection(context),
          const SizedBox(height: 16),
          _buildBookingHistory(context),
          const SizedBox(height: 24),
          Row(
            children: [
              Expanded(
                child: CupertinoButton(
                  padding: EdgeInsets.zero,
                  onPressed: () {
                    // Navigate to new booking screen with pre-filled client
                  },
                  child: Container(
                    padding: const EdgeInsets.symmetric(vertical: 12),
                    decoration: BoxDecoration(
                      color: Theme.of(context).primaryColor,
                      borderRadius: BorderRadius.circular(8),
                    ),
                    alignment: Alignment.center,
                    child: const Text(
                      'Create Booking',
                      style: TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 16),
              CupertinoButton(
                padding: EdgeInsets.zero,
                onPressed: () {
                  // Edit client
                },
                child: Container(
                  padding: const EdgeInsets.symmetric(
                    vertical: 12,
                    horizontal: 16,
                  ),
                  decoration: BoxDecoration(
                    color: Colors.grey[200],
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: const Icon(
                    CupertinoIcons.pencil,
                    color: Colors.black87,
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildContactSection(BuildContext context) {
    return Card(
      elevation: 0.5,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Contact Information',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 16),
            _buildContactItem(
              context,
              CupertinoIcons.phone,
              'Phone',
              client.phone,
              () {
                // Launch phone
              },
            ),
            const Divider(height: 24),
            _buildContactItem(
              context,
              CupertinoIcons.mail,
              'Email',
              client.email,
              () {
                // Launch email
              },
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildContactItem(
    BuildContext context,
    IconData icon,
    String label,
    String value,
    VoidCallback onPressed,
  ) {
    return Row(
      children: [
        Container(
          padding: const EdgeInsets.all(10),
          decoration: BoxDecoration(
            color: Theme.of(context).primaryColor.withOpacity(0.1),
            borderRadius: BorderRadius.circular(10),
          ),
          child: Icon(icon, color: Theme.of(context).primaryColor, size: 20),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                label,
                style: TextStyle(fontSize: 12, color: Colors.grey[600]),
              ),
              Text(
                value,
                style: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ],
          ),
        ),
        CupertinoButton(
          padding: EdgeInsets.zero,
          onPressed: onPressed,
          child: Icon(
            icon == CupertinoIcons.phone
                ? CupertinoIcons.phone_fill
                : CupertinoIcons.mail_solid,
            color: Theme.of(context).primaryColor,
          ),
        ),
      ],
    );
  }

  Widget _buildNotesSection(BuildContext context) {
    return Card(
      elevation: 0.5,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Row(
              children: [
                Icon(CupertinoIcons.doc_text, size: 20),
                SizedBox(width: 8),
                Text(
                  'Notes',
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                ),
              ],
            ),
            const SizedBox(height: 12),
            if (client.notes.isNotEmpty)
              Text(client.notes, style: const TextStyle(fontSize: 16))
            else
              const Text(
                'No notes for this client',
                style: TextStyle(
                  fontSize: 16,
                  fontStyle: FontStyle.italic,
                  color: Colors.grey,
                ),
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildBookingHistory(BuildContext context) {
    return Card(
      elevation: 0.5,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'Recent Bookings',
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                ),
                Text(
                  'See All',
                  style: TextStyle(
                    fontSize: 14,
                    color: Colors.blue,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            if (client.totalBookings > 0)
              const Column(
                children: [
                  // Normally, you'd fetch real booking data here
                  // and display it in a list
                  Text(
                    'Booking history would appear here',
                    style: TextStyle(fontSize: 16),
                  ),
                ],
              )
            else
              const Text(
                'No bookings yet',
                style: TextStyle(
                  fontSize: 16,
                  fontStyle: FontStyle.italic,
                  color: Colors.grey,
                ),
              ),
          ],
        ),
      ),
    );
  }

  String _formatDate(DateTime date) {
    final now = DateTime.now();
    final difference = now.difference(date);

    if (difference.inDays < 30) {
      return '${difference.inDays} days';
    } else if (difference.inDays < 365) {
      final months = (difference.inDays / 30).floor();
      return '$months ${months == 1 ? 'month' : 'months'}';
    } else {
      final years = (difference.inDays / 365).floor();
      return '$years ${years == 1 ? 'year' : 'years'}';
    }
  }
}
