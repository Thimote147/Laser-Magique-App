import 'package:flutter/material.dart';
import 'package:flutter/cupertino.dart';
import 'package:intl/intl.dart';
import '../models/booking_details.dart';
import '../main.dart'; // Pour accéder à l'instance Supabase
import 'edit_booking_page.dart'; // Import the new edit page

class BookingDetailsPage extends StatefulWidget {
  final String bookingId;

  const BookingDetailsPage({super.key, required this.bookingId});

  @override
  BookingDetailsPageState createState() => BookingDetailsPageState();
}

class BookingDetailsPageState extends State<BookingDetailsPage> {
  bool _isLoading = true;
  final bool _dataChanged = false;
  BookingDetails? _bookingDetails;

  // Controllers for editing text fields
  final TextEditingController _firstnameController = TextEditingController();
  final TextEditingController _lastnameController = TextEditingController();
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _phoneController = TextEditingController();
  final TextEditingController _notesController = TextEditingController();

  // Editing state variables
  final bool _isEditingCustomerInfo = false;

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
        setState(() {
          _isLoading = false;
        });
      }
    } catch (e) {
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
        backgroundColor: themeService.getBackgroundColor(),
        navigationBar: CupertinoNavigationBar(
          middle: const Text('Détails de la réservation'),
          backgroundColor: themeService.getBackgroundColor(),
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
    final backgroundColor = themeService.getCardColor();
    final borderColor = themeService.getSeparatorColor();

    // Define border radius constant to ensure consistency
    const double buttonBorderRadius = 8.0;

    // Define more prominent colors for the cancel button
    final cancelButtonColor =
        isCancelled
            ? CupertinoColors.activeBlue.withOpacity(0.8)
            : themeService.darkMode
            ? CupertinoColors.systemGrey5.darkColor
            : CupertinoColors
                .systemGrey6; // Lighter background for better contrast

    // Define a more visible border color for the cancel button
    final cancelBorderColor =
        isCancelled
            ? CupertinoColors.activeBlue
            : CupertinoColors.systemRed.withOpacity(
              0.6,
            ); // More visible red tint for border

    // Define more prominent text color for the cancel button
    final cancelTextColor =
        isCancelled
            ? CupertinoColors.white
            : CupertinoColors.systemRed; // Red text for better visibility

    return Container(
      decoration: BoxDecoration(
        color: backgroundColor,
        boxShadow: [
          BoxShadow(
            color: borderColor,
            blurRadius: 10,
            offset: const Offset(0, -2),
          ),
        ],
        border: Border(top: BorderSide(color: borderColor, width: 0.5)),
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
            child: Container(
              decoration: BoxDecoration(
                border: Border.all(
                  color: cancelBorderColor, // More visible border
                  width: 1.5, // Slightly thicker border for visibility
                ),
                borderRadius: BorderRadius.circular(buttonBorderRadius),
              ),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(
                  buttonBorderRadius - 1,
                ), // Slightly smaller to fit inside container
                child: CupertinoButton(
                  padding: EdgeInsets.zero,
                  borderRadius: BorderRadius.circular(
                    buttonBorderRadius - 1,
                  ), // Match the clip radius
                  color: cancelButtonColor,
                  child: Text(
                    isCancelled ? 'Remettre' : 'Annuler',
                    style: TextStyle(
                      color: cancelTextColor, // More visible text
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
            ),
          ),
          const SizedBox(width: 12),

          // Delete Button
          Expanded(
            flex:
                isCancelled
                    ? 2
                    : 1, // Take more space when in cancelled state (modify button is hidden)
            child: Container(
              decoration: BoxDecoration(
                border: Border.all(
                  color: CupertinoColors.destructiveRed,
                  width: 1.0,
                ),
                borderRadius: BorderRadius.circular(buttonBorderRadius),
              ),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(buttonBorderRadius - 1),
                child: CupertinoButton(
                  padding: EdgeInsets.zero,
                  borderRadius: BorderRadius.circular(buttonBorderRadius - 1),
                  color: CupertinoColors.destructiveRed,
                  onPressed: _showDeleteConfirmation,
                  child: const Text(
                    'Supprimer',
                    style: TextStyle(
                      color: CupertinoColors.white,
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ),
            ),
          ),

          // Only show Modify Button when booking is not cancelled
          if (!isCancelled) ...[
            const SizedBox(width: 12),
            Expanded(
              child: Container(
                decoration: BoxDecoration(
                  border: Border.all(
                    color: CupertinoTheme.of(context).primaryColor,
                    width: 1.0,
                  ),
                  borderRadius: BorderRadius.circular(buttonBorderRadius),
                ),
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(buttonBorderRadius - 1),
                  child: CupertinoButton(
                    padding: EdgeInsets.zero,
                    borderRadius: BorderRadius.circular(buttonBorderRadius - 1),
                    color: CupertinoTheme.of(context).primaryColor,
                    child: const Text(
                      'Modifier',
                      style: TextStyle(
                        color: CupertinoColors.white,
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    onPressed: () {
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
              ),
            ),
          ],
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
    final cardColor = themeService.getCardColor();
    final textColor = themeService.getTextColor();
    final separatorColor = themeService.getSeparatorColor();
    final primaryColor = CupertinoTheme.of(context).primaryColor;

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(
        horizontal: 16,
        vertical: 12,
      ), // Reduced vertical padding
      decoration: BoxDecoration(
        color: cardColor,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: separatorColor,
            blurRadius: 10,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          // Activity name with slightly smaller font
          Text(
            _bookingDetails!.activity.name,
            style: TextStyle(
              fontSize: 20, // Reduced from 22
              fontWeight: FontWeight.bold,
              color: primaryColor,
            ),
            textAlign: TextAlign.center,
          ),

          // Cancellation indicator if booking is cancelled
          if (isCancelled) ...[
            const SizedBox(height: 8), // Reduced spacing
            Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(
                vertical: 6,
                horizontal: 12,
              ), // Reduced padding
              decoration: BoxDecoration(
                color: CupertinoColors.destructiveRed.withOpacity(0.1),
                borderRadius: BorderRadius.circular(8),
                border: Border.all(
                  color: CupertinoColors.destructiveRed.withOpacity(0.3),
                ),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                mainAxisSize:
                    MainAxisSize.min, // Added to make container tighter
                children: [
                  const Icon(
                    CupertinoIcons.xmark_circle_fill,
                    color: CupertinoColors.destructiveRed,
                    size: 16, // Reduced size
                  ),
                  const SizedBox(width: 6), // Reduced spacing
                  const Text(
                    'Réservation annulée',
                    style: TextStyle(
                      color: CupertinoColors.destructiveRed,
                      fontWeight: FontWeight.w600,
                      fontSize: 13, // Reduced size
                    ),
                  ),
                ],
              ),
            ),
          ],

          const SizedBox(height: 10), // Reduced spacing
          // Date and Time info in a more compact layout
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              // Date
              Container(
                padding: const EdgeInsets.all(6), // Reduced padding
                decoration: BoxDecoration(
                  color: primaryColor.withOpacity(0.1),
                  shape: BoxShape.circle,
                ),
                child: Icon(
                  CupertinoIcons.calendar,
                  color: primaryColor,
                  size: 16, // Reduced size
                ),
              ),
              const SizedBox(width: 6), // Reduced spacing
              Text(
                date,
                style: TextStyle(
                  fontSize: 14, // Reduced size
                  fontWeight: FontWeight.w500,
                  color: textColor,
                ),
              ),
              const SizedBox(width: 16), // Space between date and time
              // Time
              Container(
                padding: const EdgeInsets.all(6), // Reduced padding
                decoration: BoxDecoration(
                  color: primaryColor.withOpacity(0.1),
                  shape: BoxShape.circle,
                ),
                child: Icon(
                  CupertinoIcons.clock,
                  color: primaryColor,
                  size: 16, // Reduced size
                ),
              ),
              const SizedBox(width: 6), // Reduced spacing
              Text(
                '$startTime - $endTime',
                style: TextStyle(
                  fontSize: 14, // Reduced size
                  fontWeight: FontWeight.w500,
                  color: textColor,
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
    final cardColor = themeService.getCardColor();
    final textColor = themeService.getTextColor();
    final separatorColor = themeService.getSeparatorColor();
    final primaryColor = CupertinoTheme.of(context).primaryColor;

    return Container(
      decoration: BoxDecoration(
        color: cardColor,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: separatorColor,
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
                    color: primaryColor.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(6),
                  ),
                  child: Icon(icon, color: primaryColor, size: 16),
                ),
                const SizedBox(width: 8),
                Text(
                  title,
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                    color: textColor,
                  ),
                ),
                const Spacer(),
                if (trailing != null) trailing,
              ],
            ),
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 12.0),
              child: Divider(height: 1, color: separatorColor),
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
                _formatDuration(
                  _bookingDetails!.pricing.duration *
                      _bookingDetails!.booking.nbrParties,
                ),
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

  // Helper method to format duration in hours and minutes or just minutes
  String _formatDuration(int minutes) {
    if (minutes >= 60) {
      int hours = minutes ~/ 60;
      int remainingMinutes = minutes % 60;

      if (remainingMinutes == 0) {
        return hours == 1 ? '1 heure' : '$hours heures';
      } else {
        String hourText = hours == 1 ? '1 heure' : '$hours heures';
        String minuteText =
            remainingMinutes == 1 ? '1 minute' : '$remainingMinutes minutes';
        return '$hourText $minuteText';
      }
    } else {
      return minutes == 1 ? '1 minute' : '$minutes minutes';
    }
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
        // Prix et acompte (switched positions)
        Row(
          children: [
            Expanded(
              child: _buildInfoItem(
                CupertinoIcons.arrow_down_circle,
                'Acompte',
                deposit > 0 ? currencyFormat.format(deposit) : '0.00 €',
                isHighlighted: deposit > 0,
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

        // Restant à payer (moved from above)
        _buildInfoItem(
          CupertinoIcons.money_euro,
          'Restant à payer',
          currencyFormat.format(amount),
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
    final textColor = themeService.getTextColor();
    final secondaryTextColor = themeService.getSecondaryTextColor();
    final primaryColor = CupertinoTheme.of(context).primaryColor;

    final backgroundColor =
        isPaid
            ? primaryColor.withOpacity(0.1)
            : themeService.darkMode
            ? CupertinoColors.systemGrey6.darkColor
            : CupertinoColors.systemGrey6;

    final borderColor =
        isPaid
            ? primaryColor.withOpacity(0.3)
            : themeService.getSeparatorColor();

    return Container(
      padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 12),
      decoration: BoxDecoration(
        color: backgroundColor,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: borderColor, width: 0.5),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
            style: TextStyle(fontSize: 13, color: secondaryTextColor),
          ),
          const SizedBox(height: 4),
          Row(
            children: [
              Icon(
                icon,
                color: isPaid ? primaryColor : secondaryTextColor,
                size: 18,
              ),
              const SizedBox(width: 6),
              Expanded(
                child: Text(
                  value,
                  style: TextStyle(
                    fontSize: 15,
                    fontWeight: isPaid ? FontWeight.w600 : FontWeight.w500,
                    color: isPaid ? primaryColor : textColor,
                  ),
                ),
              ),
              if (isPaid)
                Icon(
                  CupertinoIcons.checkmark_circle_fill,
                  color: primaryColor,
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
    final textColor = themeService.getTextColor();
    final secondaryTextColor = themeService.getSecondaryTextColor();

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
                  style: TextStyle(fontSize: 14, color: secondaryTextColor),
                ),
                const SizedBox(height: 2),
                Text(
                  value,
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w500,
                    color: textColor,
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
    final textColor = themeService.getTextColor();
    final secondaryTextColor = themeService.getSecondaryTextColor();
    final backgroundColor =
        themeService.darkMode
            ? CupertinoColors.systemGrey6.darkColor
            : CupertinoColors.systemGrey6;
    final borderColor = themeService.getSeparatorColor();

    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 10),
        decoration: BoxDecoration(
          color: backgroundColor,
          borderRadius: BorderRadius.circular(8),
          border: Border.all(color: borderColor, width: 0.5),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              label,
              style: TextStyle(fontSize: 12, color: secondaryTextColor),
            ),
            const SizedBox(height: 2),
            Row(
              children: [
                Icon(
                  icon,
                  color:
                      isHighlighted
                          ? CupertinoTheme.of(context).primaryColor
                          : secondaryTextColor,
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
                              : textColor,
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
    // Vous pourriez utiliser le package url_launcher ici
  }

  void _launchPhone(String phoneNumber) {
    // Implémenter la logique pour lancer l'application téléphone
    // Vous pourriez utiliser le package url_launcher ici
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
      await supabase.rpc(
        'delete_booking',
        params: {'p_activity_booking_id': _bookingDetails!.activityBookingId},
      );

      setState(() {
        _isLoading = false;
      });

      if (!context.mounted) return;
      _showCupertinoToast('Réservation supprimée avec succès');
      Navigator.pop(context, {'status': 'deleted', 'refreshCalendar': true});
    } catch (e) {
      setState(() {
        _isLoading = false;
      });

      if (!context.mounted) return;
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
      Navigator.pop(context, {'status': 'cancelled', 'refreshCalendar': true});
    } catch (e) {
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
      await _fetchBookingDetails();
    } catch (e) {
      setState(() {
        _isLoading = false;
      });

      if (!context.mounted) return;
      _showCupertinoToast('Erreur lors de la réactivation: $e', isError: true);
    }
  }
}
