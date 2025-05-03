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
  bool _dataChanged = false; // Track if data was changed
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
      _lastnameController.text =
          _bookingDetails!.booking.lastname ?? ''; // Handle nullable lastname
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
      final response = await supabase.rpc(
        'get_booking_details',
        params: {'p_activity_booking_id': widget.bookingId},
      );

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

  @override
  Widget build(BuildContext context) {
    return WillPopScope(
      onWillPop: () async {
        // Return with refresh flag to update calendar
        Navigator.pop(context, {'refreshCalendar': _dataChanged || true});
        return false; // We handle the pop ourselves
      },
      child: CupertinoPageScaffold(
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
                : Stack(
                  children: [
                    // Main content with padding at the bottom for the fixed button
                    SafeArea(
                      bottom:
                          false, // Don't pad the bottom since we have the fixed button
                      child: _buildDetailsContent(),
                    ),

                    // Fixed position button at the bottom
                    Positioned(
                      left: 0,
                      right: 0,
                      bottom: 0,
                      child: _buildFixedActionButton(),
                    ),
                  ],
                ),
      ),
    );
  }

  // Fixed position action button at the bottom
  Widget _buildFixedActionButton() {
    final bool isCancelled = _bookingDetails?.booking.isCancelled ?? false;

    return Container(
      decoration: BoxDecoration(
        color: CupertinoColors.systemBackground,
        boxShadow: [
          BoxShadow(
            color: CupertinoColors.systemGrey5.withOpacity(0.5),
            blurRadius: 10,
            offset: const Offset(0, -2),
          ),
        ],
        border: Border(
          top: BorderSide(
            color: CupertinoColors.systemGrey4.withOpacity(0.4),
            width: 0.5,
          ),
        ),
      ),
      padding: EdgeInsets.only(
        left: 16,
        right: 16,
        top: 12,
        bottom: MediaQuery.of(context).padding.bottom + 12, // Respect safe area
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
        children: [
          // Cancel/Reinstate Button
          Expanded(
            child: CupertinoButton(
              padding: EdgeInsets.zero,
              color:
                  isCancelled
                      ? CupertinoColors.activeBlue.withOpacity(0.8)
                      : CupertinoColors.systemGrey5,
              child: Text(
                isCancelled ? 'Remettre' : 'Annuler',
                style: TextStyle(
                  color:
                      isCancelled
                          ? CupertinoColors.white
                          : CupertinoColors.black,
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                ),
              ),
              onPressed: () {
                if (isCancelled) {
                  _showReinstateConfirmation();
                } else {
                  _showCancelConfirmation();
                }
              },
            ),
          ),
          const SizedBox(width: 12),

          // Delete Button
          Expanded(
            child: CupertinoButton(
              padding: EdgeInsets.zero,
              color: CupertinoColors.destructiveRed,
              child: const Text(
                'Supprimer',
                style: TextStyle(
                  color: CupertinoColors.white,
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                ),
              ),
              onPressed: _showDeleteConfirmation,
            ),
          ),

          const SizedBox(width: 12),

          // Modify Button - Disabled when booking is cancelled
          Expanded(
            child: CupertinoButton(
              padding: EdgeInsets.zero,
              color:
                  isCancelled
                      ? CupertinoColors
                          .systemGrey4 // Gray color for disabled state
                      : CupertinoTheme.of(context).primaryColor,
              child: Text(
                'Modifier',
                style: TextStyle(
                  color: CupertinoColors.white,
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                ),
              ),
              // Disable the button when booking is cancelled by setting onPressed to null
              onPressed:
                  isCancelled
                      ? null
                      : () {
                        Navigator.push(
                          context,
                          CupertinoPageRoute(
                            builder:
                                (context) => EditBookingPage(
                                  bookingDetails: _bookingDetails!,
                                ),
                          ),
                        ).then((result) {
                          if (result == true || result == 'deleted') {
                            if (result == 'deleted') {
                              Navigator.pop(
                                context,
                                {'status': 'deleted', 'refreshCalendar': true},
                              ); // Return to the previous screen if booking was deleted
                            } else {
                              _fetchBookingDetails(); // Refresh if changes were made
                            }
                          }
                        });
                      },
            ),
          ),
        ],
      ),
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
      Duration(
        minutes:
            _bookingDetails!.pricing.duration *
            _bookingDetails!.booking.nbrParties,
      ),
    );
    final formattedEndTime = timeFormatter.format(endTime);

    return CustomScrollView(
      physics: const AlwaysScrollableScrollPhysics(
        parent: BouncingScrollPhysics(),
      ),
      slivers: [
        // Add the pull-to-refresh control
        CupertinoSliverRefreshControl(
          onRefresh: () async {
            // Refresh the booking details
            await _fetchBookingDetails();
            // Show a toast to confirm the refresh
            if (mounted) {
              _showCupertinoToast('Détails mis à jour');
            }
          },
        ),
        SliverToBoxAdapter(
          child: Padding(
            padding: const EdgeInsets.symmetric(
              horizontal: 16.0,
              vertical: 8.0,
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Main info (header card)
                _buildHeaderCard(
                  formattedDate,
                  formattedTime,
                  formattedEndTime,
                ),

                const SizedBox(height: 16),

                // Client info section
                _buildCompactSection(
                  title: 'Informations client',
                  icon: CupertinoIcons.person_fill,
                  child: _buildClientInfoSection(),
                ),

                const SizedBox(height: 16),

                // Activity info
                _buildCompactSection(
                  title: 'Activité',
                  icon: CupertinoIcons.game_controller_solid,
                  child: _buildActivityInfoSection(),
                ),

                const SizedBox(height: 16),

                // Payment section
                _buildCompactSection(
                  title: 'Paiement',
                  icon: CupertinoIcons.money_euro_circle,
                  child: _buildPricingSection(),
                ),

                const SizedBox(height: 16),

                // Notes section if any
                if (_bookingDetails!.booking.notes.isNotEmpty)
                  _buildCompactSection(
                    title: 'Notes',
                    icon: CupertinoIcons.text_bubble,
                    child: _buildNotesSection(),
                  ),

                // Add bottom padding for better scrolling experience with the bottom nav bar
                SizedBox(height: MediaQuery.of(context).padding.bottom + 80),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildHeaderCard(String date, String startTime, String endTime) {
    final bool isCancelled = _bookingDetails?.booking.isCancelled ?? false;

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: CupertinoColors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: CupertinoColors.systemGrey5.withOpacity(0.5),
            blurRadius: 10,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          // Activity name with larger font
          Text(
            _bookingDetails!.activity.name,
            style: TextStyle(
              fontSize: 22,
              fontWeight: FontWeight.bold,
              color: CupertinoTheme.of(context).primaryColor,
            ),
            textAlign: TextAlign.center,
          ),

          // Cancellation indicator if booking is cancelled
          if (isCancelled) ...[
            const SizedBox(height: 10),
            Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 12),
              decoration: BoxDecoration(
                color: CupertinoColors.destructiveRed.withOpacity(0.1),
                borderRadius: BorderRadius.circular(8),
                border: Border.all(
                  color: CupertinoColors.destructiveRed.withOpacity(0.3),
                ),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(
                    CupertinoIcons.xmark_circle_fill,
                    color: CupertinoColors.destructiveRed,
                    size: 20,
                  ),
                  const SizedBox(width: 8),
                  const Text(
                    'Réservation annulée',
                    style: TextStyle(
                      color: CupertinoColors.destructiveRed,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
              ),
            ),
          ],

          const SizedBox(height: 12),

          // Date row
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: CupertinoTheme.of(
                    context,
                  ).primaryColor.withOpacity(0.1),
                  shape: BoxShape.circle,
                ),
                child: Icon(
                  CupertinoIcons.calendar,
                  color: CupertinoTheme.of(context).primaryColor,
                  size: 20,
                ),
              ),
              const SizedBox(width: 8),
              Text(
                date,
                style: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),

          // Time row
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: CupertinoTheme.of(
                    context,
                  ).primaryColor.withOpacity(0.1),
                  shape: BoxShape.circle,
                ),
                child: Icon(
                  CupertinoIcons.clock,
                  color: CupertinoTheme.of(context).primaryColor,
                  size: 20,
                ),
              ),
              const SizedBox(width: 8),
              Text(
                '$startTime - $endTime',
                style: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildCompactSection({
    required String title,
    required IconData icon,
    required Widget child,
    Widget? trailing,
  }) {
    return Container(
      decoration: BoxDecoration(
        color: CupertinoColors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: CupertinoColors.systemGrey5.withOpacity(0.5),
            blurRadius: 5,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(6),
                  decoration: BoxDecoration(
                    color: CupertinoTheme.of(
                      context,
                    ).primaryColor.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(6),
                  ),
                  child: Icon(
                    icon,
                    color: CupertinoTheme.of(context).primaryColor,
                    size: 16,
                  ),
                ),
                const SizedBox(width: 8),
                Text(
                  title,
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const Spacer(),
                if (trailing != null) trailing,
              ],
            ),
            const Padding(
              padding: EdgeInsets.symmetric(vertical: 12.0),
              child: Divider(height: 1),
            ),
            child,
          ],
        ),
      ),
    );
  }

  Widget _buildClientInfoSection() {
    if (_isEditingCustomerInfo) {
      return Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Prénom & Nom
          Row(
            children: [
              // Prénom
              Expanded(
                child: _buildEditableField(
                  CupertinoIcons.person_fill,
                  'Prénom',
                  _firstnameController,
                ),
              ),
              const SizedBox(width: 12),
              // Nom
              Expanded(
                child: _buildEditableField(
                  CupertinoIcons.person_fill,
                  'Nom',
                  _lastnameController,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),

          // Email & Téléphone
          Row(
            children: [
              // Email
              Expanded(
                child: _buildEditableField(
                  CupertinoIcons.mail_solid,
                  'Email',
                  _emailController,
                  keyboardType: TextInputType.emailAddress,
                ),
              ),
              const SizedBox(width: 12),
              // Téléphone
              Expanded(
                child: _buildEditableField(
                  CupertinoIcons.phone_fill,
                  'Téléphone',
                  _phoneController,
                  keyboardType: TextInputType.phone,
                ),
              ),
            ],
          ),

          // Notes
          const SizedBox(height: 12),
          _buildEditableField(
            CupertinoIcons.doc_text,
            'Notes',
            _notesController,
            maxLines: 3,
          ),
        ],
      );
    } else {
      return Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Client name
          _buildInfoRow(
            CupertinoIcons.person_fill,
            'Client',
            '${_bookingDetails!.booking.formattedFirstname} ${_bookingDetails!.booking.formattedLastname}',
          ),
          const SizedBox(height: 12),

          // Contact info rows
          Row(
            children: [
              // Email
              Expanded(
                child: _buildInfoItem(
                  CupertinoIcons.mail_solid,
                  'Email',
                  _bookingDetails!.booking.email,
                  onTap: () => _launchEmail(_bookingDetails!.booking.email),
                ),
              ),
              const SizedBox(width: 16),
              // Phone
              Expanded(
                child: _buildInfoItem(
                  CupertinoIcons.phone_fill,
                  'Téléphone',
                  _bookingDetails!.booking.phoneNumber,
                  onTap:
                      () => _launchPhone(_bookingDetails!.booking.phoneNumber),
                ),
              ),
            ],
          ),
        ],
      );
    }
  }

  Widget _buildActivityInfoSection() {
    return Column(
      children: [
        // First row: Type and Personnes
        Row(
          children: [
            Expanded(
              child: _buildInfoItem(
                CupertinoIcons.tag_fill,
                'Type',
                _bookingDetails!.pricing.type,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: _buildInfoItem(
                CupertinoIcons.person_2_fill,
                'Personnes',
                '${_bookingDetails!.booking.nbrPers}',
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),

        // Second row: Duration and Parties
        Row(
          children: [
            Expanded(
              child: _buildInfoItem(
                CupertinoIcons.clock_fill,
                'Durée',
                '${_bookingDetails!.pricing.duration} min',
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: _buildInfoItem(
                CupertinoIcons.gamecontroller_fill,
                'Parties',
                '${_bookingDetails!.booking.nbrParties}',
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildPricingSection() {
    // Format currency values
    final currencyFormat = NumberFormat.currency(
      locale: 'fr_FR',
      symbol: '€',
      decimalDigits: 2,
    );

    // Get all the payment values
    final amount = _bookingDetails!.booking.amount;
    final deposit = _bookingDetails!.booking.deposit;
    final total = _bookingDetails!.booking.total;
    final cardPayment = _bookingDetails!.booking.cardPayment;
    final cashPayment = _bookingDetails!.booking.cashPayment;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Prix et acompte
        Row(
          children: [
            Expanded(
              child: _buildInfoItem(
                CupertinoIcons.money_euro,
                'Restant à payer',
                currencyFormat.format(amount),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: _buildInfoItem(
                CupertinoIcons.money_euro_circle,
                'Total',
                currencyFormat.format(total),
                isHighlighted: true,
              ),
            ),
          ],
        ),

        const SizedBox(height: 12),

        // Acompte
        _buildInfoItem(
          CupertinoIcons.arrow_down_circle,
          'Acompte',
          deposit > 0 ? currencyFormat.format(deposit) : 'Aucun acompte',
          isHighlighted: deposit > 0,
        ),

        const SizedBox(height: 16),
        const Text(
          'Méthodes de paiement',
          style: TextStyle(
            fontSize: 15,
            fontWeight: FontWeight.w600,
            color: CupertinoColors.systemGrey,
          ),
        ),
        const SizedBox(height: 8),

        // Paiement CB et espèces
        Row(
          children: [
            Expanded(
              child: _buildPaymentMethodItem(
                CupertinoIcons.creditcard,
                'Carte bancaire',
                cardPayment != null
                    ? currencyFormat.format(cardPayment)
                    : 'Non',
                isPaid: cardPayment != null && cardPayment > 0,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: _buildPaymentMethodItem(
                CupertinoIcons.money_euro_circle,
                'Espèces',
                cashPayment != null
                    ? currencyFormat.format(cashPayment)
                    : 'Non',
                isPaid: cashPayment != null && cashPayment > 0,
              ),
            ),
          ],
        ),
      ],
    );
  }

  // Widget pour afficher une méthode de paiement avec son statut
  Widget _buildPaymentMethodItem(
    IconData icon,
    String label,
    String value, {
    required bool isPaid,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 12),
      decoration: BoxDecoration(
        color:
            isPaid
                ? CupertinoTheme.of(context).primaryColor.withOpacity(0.1)
                : CupertinoColors.systemGrey6,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(
          color:
              isPaid
                  ? CupertinoTheme.of(context).primaryColor.withOpacity(0.3)
                  : CupertinoColors.systemGrey4,
          width: 0.5,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
            style: TextStyle(fontSize: 13, color: CupertinoColors.systemGrey),
          ),
          const SizedBox(height: 4),
          Row(
            children: [
              Icon(
                icon,
                color:
                    isPaid
                        ? CupertinoTheme.of(context).primaryColor
                        : CupertinoColors.systemGrey,
                size: 18,
              ),
              const SizedBox(width: 6),
              Expanded(
                child: Text(
                  value,
                  style: TextStyle(
                    fontSize: 15,
                    fontWeight: isPaid ? FontWeight.w600 : FontWeight.w500,
                    color:
                        isPaid
                            ? CupertinoTheme.of(context).primaryColor
                            : CupertinoColors.black,
                  ),
                ),
              ),
              if (isPaid)
                Icon(
                  CupertinoIcons.checkmark_circle_fill,
                  color: CupertinoTheme.of(context).primaryColor,
                  size: 18,
                ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildNotesSection() {
    return _buildInfoRow(
      CupertinoIcons.doc_text,
      'Notes',
      _bookingDetails!.booking.notes,
    );
  }

  Widget _buildInfoRow(
    IconData icon,
    String label,
    String value, {
    VoidCallback? onTap,
  }) {
    return GestureDetector(
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

  Widget _buildInfoItem(
    IconData icon,
    String label,
    String value, {
    bool isHighlighted = false,
    VoidCallback? onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 10),
        decoration: BoxDecoration(
          color: CupertinoColors.systemGrey6,
          borderRadius: BorderRadius.circular(8),
          border: Border.all(color: CupertinoColors.systemGrey4, width: 0.5),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              label,
              style: TextStyle(fontSize: 12, color: CupertinoColors.systemGrey),
            ),
            const SizedBox(height: 2),
            Row(
              children: [
                Icon(
                  icon,
                  color:
                      isHighlighted
                          ? CupertinoTheme.of(context).primaryColor
                          : CupertinoColors.systemGrey,
                  size: 16,
                ),
                const SizedBox(width: 6),
                Expanded(
                  child: Text(
                    value,
                    style: TextStyle(
                      fontSize: 15,
                      fontWeight:
                          isHighlighted ? FontWeight.w600 : FontWeight.w500,
                      color:
                          isHighlighted
                              ? CupertinoTheme.of(context).primaryColor
                              : CupertinoColors.black,
                    ),
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildEditableField(
    IconData icon,
    String label,
    TextEditingController controller, {
    TextInputType keyboardType = TextInputType.text,
    int maxLines = 1,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.only(left: 4, bottom: 4),
          child: Text(
            label,
            style: const TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.w500,
              color: CupertinoColors.systemGrey,
            ),
          ),
        ),
        CupertinoTextField(
          controller: controller,
          keyboardType: keyboardType,
          placeholder: label,
          maxLines: maxLines,
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
          prefix: Padding(
            padding: const EdgeInsets.only(left: 8),
            child: Icon(icon, color: CupertinoColors.systemGrey, size: 16),
          ),
          decoration: BoxDecoration(
            color: CupertinoColors.systemGrey6,
            borderRadius: BorderRadius.circular(8),
          ),
        ),
      ],
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
      await supabase
          .from('bookings')
          .update({
            'firstname': _firstnameController.text,
            'lastname': _lastnameController.text,
            'email': _emailController.text,
            'phone':
                _phoneController.text, // Changed from 'phone_number' to 'phone'
            'comment':
                _notesController.text, // Changed from 'notes' to 'comment'
          })
          .eq('id', _bookingDetails!.booking.bookingId);

      await _fetchBookingDetails();

      setState(() {
        _isEditingCustomerInfo = false;
        _isLoading = false;
      });

      if (!context.mounted) return;

      // Using a local SnackBar without depending on ScaffoldMessenger
      _showCupertinoToast('Informations client mises à jour avec succès');
    } catch (e) {
      print('Error updating customer info: $e');
      setState(() {
        _isLoading = false;
      });

      if (!context.mounted) return;

      // Using a local SnackBar without depending on ScaffoldMessenger
      _showCupertinoToast('Erreur lors de la mise à jour: $e', isError: true);
    }
  }

  // Custom toast method that works with CupertinoPageScaffold
  void _showCupertinoToast(String message, {bool isError = false}) {
    // Show an overlay notification at the top of the screen
    final overlay = Overlay.of(context);
    final overlayEntry = OverlayEntry(
      builder:
          (context) => Positioned(
            top: 80, // Position below the navigation bar
            left: 16,
            right: 16,
            child: Material(
              // Using Material just for the elevation
              elevation: 4,
              borderRadius: BorderRadius.circular(10),
              color:
                  isError
                      ? CupertinoColors.destructiveRed
                      : CupertinoColors.activeGreen,
              child: Padding(
                padding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 12,
                ),
                child: Row(
                  children: [
                    Icon(
                      isError
                          ? CupertinoIcons.exclamationmark_circle
                          : CupertinoIcons.checkmark_circle,
                      color: CupertinoColors.white,
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Text(
                        message,
                        style: const TextStyle(
                          color: CupertinoColors.white,
                          fontSize: 14,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
    );

    overlay.insert(overlayEntry);

    // Auto-dismiss after 3 seconds
    Future.delayed(const Duration(seconds: 3), () {
      overlayEntry.remove();
    });
  }

  Future<void> _showDeleteConfirmation() async {
    return showCupertinoDialog<void>(
      context: context,
      builder:
          (BuildContext context) => CupertinoAlertDialog(
            title: const Text('Confirmer la suppression'),
            content: const Text(
              'Êtes-vous sûr de vouloir supprimer cette réservation? Cette action ne peut pas être annulée.',
            ),
            actions: <CupertinoDialogAction>[
              CupertinoDialogAction(
                child: const Text('Annuler'),
                onPressed: () {
                  Navigator.pop(context);
                },
              ),
              CupertinoDialogAction(
                isDestructiveAction: true,
                onPressed: () {
                  Navigator.pop(context);
                  _deleteBooking();
                },
                child: const Text('Supprimer'),
              ),
            ],
          ),
    );
  }

  Future<void> _deleteBooking() async {
    setState(() {
      _isLoading = true;
    });

    try {
      // Call the delete_booking RPC function instead of directly deleting the record
      await supabase.rpc(
        'delete_booking',
        params: {'p_activity_booking_id': _bookingDetails!.activityBookingId},
      );

      setState(() {
        _isLoading = false;
      });

      if (!context.mounted) return;

      // Show success message
      _showCupertinoToast('Réservation supprimée avec succès');

      // Pop with 'deleted' result and refresh flag for calendar
      Navigator.pop(context, {
        'status': 'deleted',
        'refreshCalendar': true,
      }); // Return object with deletion status and refresh flag
    } catch (e) {
      print('Error deleting booking: $e');
      setState(() {
        _isLoading = false;
      });

      if (!context.mounted) return;

      // Show error message with the specific server error
      _showCupertinoToast('Erreur lors de la suppression: $e', isError: true);
    }
  }

  Future<void> _showCancelConfirmation() async {
    return showCupertinoDialog<void>(
      context: context,
      builder:
          (BuildContext context) => CupertinoAlertDialog(
            title: const Text('Confirmer l\'annulation'),
            content: const Text(
              'Êtes-vous sûr de vouloir annuler cette réservation? Cette action ne peut pas être annulée.',
            ),
            actions: <CupertinoDialogAction>[
              CupertinoDialogAction(
                child: const Text('Retour'),
                onPressed: () {
                  Navigator.pop(context);
                },
              ),
              CupertinoDialogAction(
                isDestructiveAction: true,
                onPressed: () {
                  Navigator.pop(context);
                  _cancelBooking();
                },
                child: const Text('Confirmer'),
              ),
            ],
          ),
    );
  }

  Future<void> _cancelBooking() async {
    setState(() {
      _isLoading = true;
    });

    try {
      await supabase
          .from('bookings')
          .update({'is_cancelled': true})
          .eq('booking_id', _bookingDetails!.booking.bookingId);

      setState(() {
        _isLoading = false;
      });

      if (!context.mounted) return;

      _showCupertinoToast('Réservation annulée avec succès');

      // Return to calendar with a signal to refresh, similar to delete operation
      Navigator.pop(context, {'status': 'cancelled', 'refreshCalendar': true});
    } catch (e) {
      print('Error cancelling booking: $e');
      setState(() {
        _isLoading = false;
      });

      if (!context.mounted) return;

      _showCupertinoToast('Erreur lors de l\'annulation: $e', isError: true);
    }
  }

  Future<void> _showReinstateConfirmation() async {
    return showCupertinoDialog<void>(
      context: context,
      builder:
          (BuildContext context) => CupertinoAlertDialog(
            title: const Text('Remettre la réservation'),
            content: const Text(
              'Voulez-vous réactiver cette réservation annulée?',
            ),
            actions: <CupertinoDialogAction>[
              CupertinoDialogAction(
                child: const Text('Annuler'),
                onPressed: () {
                  Navigator.pop(context);
                },
              ),
              CupertinoDialogAction(
                isDefaultAction: true,
                onPressed: () {
                  Navigator.pop(context);
                  _reinstateBooking();
                },
                child: const Text('Réactiver'),
              ),
            ],
          ),
    );
  }

  Future<void> _reinstateBooking() async {
    setState(() {
      _isLoading = true;
    });

    try {
      await supabase
          .from('bookings')
          .update({'is_cancelled': false})
          .eq('booking_id', _bookingDetails!.booking.bookingId);

      setState(() {
        _isLoading = false;
      });

      if (!context.mounted) return;

      _showCupertinoToast('Réservation réactivée avec succès');

      // Refresh booking details to show updated status
      await _fetchBookingDetails();

      // Don't navigate back, just stay on the page with updated data
    } catch (e) {
      print('Error reinstating booking: $e');
      setState(() {
        _isLoading = false;
      });

      if (!context.mounted) return;

      _showCupertinoToast('Erreur lors de la réactivation: $e', isError: true);
    }
  }
}
