import 'package:flutter/material.dart';
import 'package:flutter/cupertino.dart';
import 'package:intl/intl.dart';
import '../models/booking_details.dart';
import '../main.dart'; // Pour accéder à l'instance Supabase
import '../utils/app_strings.dart';
import 'edit_booking_page.dart'; // Import the new edit page

class BookingDetailsPage extends StatefulWidget {
  final String bookingId;

  const BookingDetailsPage({Key? key, required this.bookingId})
    : super(key: key);

  @override
  BookingDetailsPageState createState() => BookingDetailsPageState();
}

class BookingDetailsPageState extends State<BookingDetailsPage> {
  bool _isLoading = true;
  BookingDetails? _bookingDetails;

  // Controllers for editing text fields
  final TextEditingController _firstnameController = TextEditingController();
  final TextEditingController _lastnameController = TextEditingController();
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _phoneController = TextEditingController();
  final TextEditingController _notesController = TextEditingController();

  // Editing state variables
  bool _isEditingCustomerInfo = false;

  @override
  void initState() {
    super.initState();
    _fetchBookingDetails();
  }

  @override
  void dispose() {
    _firstnameController.dispose();
    _lastnameController.dispose();
    _emailController.dispose();
    _phoneController.dispose();
    _notesController.dispose();
    super.dispose();
  }

  // Initialize controllers with current values
  void _initControllers() {
    if (_bookingDetails != null) {
      _firstnameController.text = _bookingDetails!.booking.firstname;
      _lastnameController.text = _bookingDetails!.booking.lastname;
      _emailController.text = _bookingDetails!.booking.email;
      _phoneController.text = _bookingDetails!.booking.phoneNumber;
      _notesController.text = _bookingDetails!.booking.notes;
    }
  }

  Future<void> _fetchBookingDetails() async {
    setState(() {
      _isLoading = true;
    });

    try {
      // Utilisation de la nouvelle fonction SQL via RPC
      final response = await supabase.rpc(
        'get_booking_details',
        params: {'p_activity_booking_id': widget.bookingId},
      );

      // Debug: afficher la réponse
      print('Response from get_booking_details: $response');

      if (response != null && response.isNotEmpty) {
        setState(() {
          _bookingDetails = BookingDetails.fromJson(response[0]);
          _isLoading = false;
        });
      } else {
        print('No booking details found for ID: ${widget.bookingId}');
        setState(() {
          _isLoading = false;
        });
      }
    } catch (e) {
      print('Error fetching booking details: $e');
      setState(() {
        _isLoading = false;
      });
    }
  }

  Future<void> _cancelBooking() async {
    // Vous pourriez implémenter la logique d'annulation ici
    // Par exemple, mettre à jour un champ status dans la base de données
    setState(() {
      _isLoading = true;
    });

    try {
      // À adapter selon votre logique métier
      await supabase
          .from('booking_activities')
          .update({'status': 'cancelled'})
          .eq('activity_booking_id', widget.bookingId);

      if (!context.mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Réservation annulée avec succès'),
          backgroundColor: Colors.green,
        ),
      );

      // Rafraîchir les détails
      await _fetchBookingDetails();
    } catch (e) {
      if (!context.mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Erreur lors de l\'annulation: $e'),
          backgroundColor: Colors.red,
        ),
      );
      setState(() {
        _isLoading = false;
      });
    }
  }

  void _showCancelConfirmation() {
    showCupertinoDialog(
      context: context,
      builder:
          (context) => CupertinoAlertDialog(
            title: const Text('Confirmer l\'annulation'),
            content: const Text(
              'Êtes-vous sûr de vouloir annuler cette réservation?',
            ),
            actions: [
              CupertinoDialogAction(
                child: const Text('Non'),
                onPressed: () => Navigator.pop(context),
              ),
              CupertinoDialogAction(
                isDestructiveAction: true,
                onPressed: () {
                  Navigator.pop(context);
                  _cancelBooking();
                },
                child: const Text('Oui, annuler'),
              ),
            ],
          ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return CupertinoPageScaffold(
      backgroundColor: CupertinoColors.systemGroupedBackground,
      navigationBar: CupertinoNavigationBar(
        middle: const Text('Détails de la réservation'),
        backgroundColor: CupertinoColors.systemGroupedBackground,
        border: null,
      ),
      child:
          _isLoading
              ? const Center(child: CupertinoActivityIndicator())
              : _bookingDetails == null
              ? const Center(child: Text('Aucun détail trouvé'))
              : SafeArea(child: _buildDetailsContent()),
    );
  }

  Widget _buildDetailsContent() {
    // Formater la date pour l'affichage
    final dateFormatter = DateFormat('EEEE d MMMM yyyy', 'fr_FR');
    final timeFormatter = DateFormat('HH:mm');

    final formattedDate = dateFormatter.format(_bookingDetails!.booking.date);
    final formattedTime = timeFormatter.format(_bookingDetails!.booking.date);

    // Calculer l'heure de fin
    final endTime = _bookingDetails!.booking.date.add(
      Duration(minutes: _bookingDetails!.pricing.duration),
    );
    final formattedEndTime = timeFormatter.format(endTime);

    return ListView(
      padding: const EdgeInsets.all(16.0),
      children: [
        // En-tête avec les informations principales
        _buildHeaderCard(formattedDate, formattedTime, formattedEndTime),

        const SizedBox(height: 16),

        // Informations client
        _buildClientInfoSection(),

        const SizedBox(height: 16),

        // Informations activité
        _buildActivityInfoSection(),

        const SizedBox(height: 16),

        // Tarification
        _buildPricingSection(),

        const SizedBox(height: 24),

        // Boutons d'action
        _buildActionButtons(),
      ],
    );
  }

  Widget _buildHeaderCard(String date, String startTime, String endTime) {
    return Card(
      elevation: 0,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      color: CupertinoTheme.of(context).primaryColor.withOpacity(0.1),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(
                  CupertinoIcons.calendar,
                  color: CupertinoTheme.of(context).primaryColor,
                  size: 22,
                ),
                const SizedBox(width: 8),
                Text(
                  date,
                  style: const TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(
                  CupertinoIcons.clock,
                  color: CupertinoTheme.of(context).primaryColor,
                  size: 18,
                ),
                const SizedBox(width: 6),
                Text(
                  '$startTime - $endTime',
                  style: const TextStyle(fontSize: 16),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Text(
              _bookingDetails!.activity.name,
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
                color: CupertinoTheme.of(context).primaryColor,
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildClientInfoSection() {
    return Card(
      elevation: 0,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text(
                  'Informations client',
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                ),
                CupertinoButton(
                  padding: EdgeInsets.zero,
                  child: Icon(
                    _isEditingCustomerInfo
                        ? CupertinoIcons.checkmark_circle
                        : CupertinoIcons.pencil,
                    color: CupertinoTheme.of(context).primaryColor,
                  ),
                  onPressed: () {
                    if (_isEditingCustomerInfo) {
                      _saveCustomerInfo();
                    } else {
                      _startEditingCustomerInfo();
                    }
                  },
                ),
              ],
            ),
            const SizedBox(height: 12),

            // Prénom
            _isEditingCustomerInfo
                ? _buildEditableField(
                  CupertinoIcons.person_fill,
                  'Prénom',
                  _firstnameController,
                )
                : _buildInfoRow(
                  CupertinoIcons.person_fill,
                  'Prénom',
                  _bookingDetails!.booking.formattedFirstname,
                ),
            const Divider(height: 24),

            // Nom
            _isEditingCustomerInfo
                ? _buildEditableField(
                  CupertinoIcons.person_fill,
                  'Nom',
                  _lastnameController,
                )
                : _buildInfoRow(
                  CupertinoIcons.person_fill,
                  'Nom',
                  _bookingDetails!.booking.formattedLastname,
                ),
            const Divider(height: 24),

            // Email
            _isEditingCustomerInfo
                ? _buildEditableField(
                  CupertinoIcons.mail_solid,
                  'Email',
                  _emailController,
                  keyboardType: TextInputType.emailAddress,
                )
                : _buildInfoRow(
                  CupertinoIcons.mail_solid,
                  'Email',
                  _bookingDetails!.booking.email,
                  onTap: () => _launchEmail(_bookingDetails!.booking.email),
                ),
            const Divider(height: 24),

            // Téléphone
            _isEditingCustomerInfo
                ? _buildEditableField(
                  CupertinoIcons.phone_fill,
                  'Téléphone',
                  _phoneController,
                  keyboardType: TextInputType.phone,
                )
                : _buildInfoRow(
                  CupertinoIcons.phone_fill,
                  'Téléphone',
                  _bookingDetails!.booking.phoneNumber,
                  onTap:
                      () => _launchPhone(_bookingDetails!.booking.phoneNumber),
                ),

            // Notes
            if (_isEditingCustomerInfo ||
                _bookingDetails!.booking.notes.isNotEmpty) ...[
              const Divider(height: 24),
              _isEditingCustomerInfo
                  ? _buildEditableField(
                    CupertinoIcons.doc_text,
                    'Notes',
                    _notesController,
                    maxLines: 3,
                  )
                  : _buildInfoRow(
                    CupertinoIcons.doc_text,
                    'Notes',
                    _bookingDetails!.booking.notes,
                  ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildActivityInfoSection() {
    return Card(
      elevation: 0,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Informations activité',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 12),
            _buildInfoRow(
              CupertinoIcons.tag_fill,
              'Type',
              _bookingDetails!.pricing.type,
            ),
            const Divider(height: 24),
            _buildInfoRow(
              CupertinoIcons.person_2_fill,
              'Nombre de personnes',
              '${_bookingDetails!.booking.nbrPers} personnes',
            ),
            const Divider(height: 24),
            _buildInfoRow(
              CupertinoIcons.clock_fill,
              'Durée',
              '${_bookingDetails!.pricing.duration} minutes',
            ),
            const Divider(height: 24),
            _buildInfoRow(
              CupertinoIcons.gamecontroller_fill,
              'Nombre de parties',
              '${_bookingDetails!.booking.nbrParties} parties',
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildPricingSection() {
    // Calculer le prix actuel en fonction du nombre de personnes
    final currentPrice = _bookingDetails!.pricing.getPriceForPlayers(
      _bookingDetails!.booking.nbrPers,
    );

    return Card(
      elevation: 0,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Tarification',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 12),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text(
                  'Prix par personne:',
                  style: TextStyle(fontSize: 16),
                ),
                Text(
                  '€${currentPrice.toStringAsFixed(2)}',
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text('Total:', style: TextStyle(fontSize: 18)),
                Text(
                  '€${(currentPrice * _bookingDetails!.booking.nbrPers).toStringAsFixed(2)}',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: CupertinoTheme.of(context).primaryColor,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildActionButtons() {
    return Row(
      children: [
        Expanded(
          child: CupertinoButton(
            padding: const EdgeInsets.symmetric(vertical: 14),
            color: CupertinoTheme.of(context).primaryColor,
            child: const Text('Modifier'),
            onPressed: () {
              // Navigation vers l'écran de modification
            },
          ),
        ),
        const SizedBox(width: 12),
        CupertinoButton(
          padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 20),
          color: CupertinoColors.systemRed,
          child: const Text('Annuler'),
          onPressed: _showCancelConfirmation,
        ),
      ],
    );
  }

  Widget _buildInfoRow(
    IconData icon,
    String label,
    String value, {
    VoidCallback? onTap,
  }) {
    return InkWell(
      onTap: onTap,
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: CupertinoTheme.of(context).primaryColor.withOpacity(0.1),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Icon(
              icon,
              color: CupertinoTheme.of(context).primaryColor,
              size: 20,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  style: const TextStyle(
                    fontSize: 14,
                    color: CupertinoColors.systemGrey,
                  ),
                ),
                const SizedBox(height: 2),
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
          if (onTap != null)
            Icon(
              CupertinoIcons.chevron_right,
              color: CupertinoColors.systemGrey3,
              size: 18,
            ),
        ],
      ),
    );
  }

  void _showActionMenu() {
    showCupertinoModalPopup<void>(
      context: context,
      builder:
          (BuildContext context) => CupertinoActionSheet(
            title: const Text('Actions'),
            message: const Text('Choisissez une action pour cette réservation'),
            actions: <CupertinoActionSheetAction>[
              CupertinoActionSheetAction(
                onPressed: () {
                  Navigator.pop(context);
                  // Logique pour modifier
                },
                child: const Text('Modifier la réservation'),
              ),
              CupertinoActionSheetAction(
                onPressed: () {
                  Navigator.pop(context);
                  _showCancelConfirmation();
                },
                isDestructiveAction: true,
                child: const Text('Annuler la réservation'),
              ),
            ],
            cancelButton: CupertinoActionSheetAction(
              child: const Text('Fermer'),
              onPressed: () {
                Navigator.pop(context);
              },
            ),
          ),
    );
  }

  void _launchEmail(String email) {
    // Implémenter la logique pour lancer l'application mail
    print('Launching email: $email');
    // Vous pourriez utiliser le package url_launcher ici
  }

  void _launchPhone(String phoneNumber) {
    // Implémenter la logique pour lancer l'application téléphone
    print('Launching phone: $phoneNumber');
    // Vous pourriez utiliser le package url_launcher ici
  }

  void _startEditingCustomerInfo() {
    setState(() {
      _isEditingCustomerInfo = true;
      _initControllers();
    });
  }

  Future<void> _saveCustomerInfo() async {
    setState(() {
      _isLoading = true;
    });

    try {
      // Ensure we're updating the public.bookings table in the database
      await supabase
          .from('bookings') // This references the public.bookings table
          .update({
            'firstname': _firstnameController.text,
            'lastname': _lastnameController.text,
            'email': _emailController.text,
            'phone_number': _phoneController.text,
            'notes': _notesController.text,
          })
          .eq('id', _bookingDetails!.booking.bookingId);

      // Refresh booking details to show the updated information
      await _fetchBookingDetails();

      // Exit editing mode
      setState(() {
        _isEditingCustomerInfo = false;
        _isLoading = false;
      });

      if (!context.mounted) return;

      // Show success message
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Informations client mises à jour avec succès'),
          backgroundColor: Colors.green,
        ),
      );
    } catch (e) {
      print('Error updating customer info: $e');
      setState(() {
        _isLoading = false;
      });

      if (!context.mounted) return;

      // Show error message
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Erreur lors de la mise à jour: $e'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  Widget _buildEditableField(
    IconData icon,
    String label,
    TextEditingController controller, {
    TextInputType keyboardType = TextInputType.text,
    int maxLines = 1,
  }) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: CupertinoTheme.of(context).primaryColor.withOpacity(0.1),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Icon(
            icon,
            color: CupertinoTheme.of(context).primaryColor,
            size: 20,
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                label,
                style: const TextStyle(
                  fontSize: 14,
                  color: CupertinoColors.systemGrey,
                ),
              ),
              const SizedBox(height: 2),
              CupertinoTextField(
                controller: controller,
                keyboardType: keyboardType,
                maxLines: maxLines,
                decoration: BoxDecoration(
                  color: CupertinoColors.systemGrey6,
                  borderRadius: BorderRadius.circular(8),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}
