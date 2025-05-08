import 'package:flutter/material.dart';
import 'package:flutter/cupertino.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import 'package:url_launcher/url_launcher.dart';
import '../models/booking_details.dart';
import '../models/food.dart';
import '../main.dart';
import '../services/booking_service.dart';
import '../services/auth_service.dart';
import 'edit_booking_page.dart';

class BookingDetailsPage extends StatefulWidget {
  final String bookingId;

  const BookingDetailsPage({super.key, required this.bookingId});

  @override
  BookingDetailsPageState createState() => BookingDetailsPageState();
}

class BookingDetailsPageState extends State<BookingDetailsPage> {
  final BookingService _bookingService =
      BookingService.instance; // Add booking service
  bool _isLoading = true;
  bool _dataChanged = false;
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
      // Use booking service to fetch the booking details
      final bookingDetails = await _bookingService.fetchBookingDetails(
        widget.bookingId,
      );

      if (bookingDetails != null) {
        // Fetch and process consumptions using the service
        await _bookingService.fetchAndProcessConsumptions(bookingDetails);

        setState(() {
          _bookingDetails = bookingDetails;
          _isLoading = false;
        });
      } else {
        setState(() {
          _bookingDetails = null;
          _isLoading = false;
        });
      }
    } catch (e) {
      setState(() {
        _bookingDetails = null;
        _isLoading = false;
      });
      if (mounted) {
        _showCupertinoToast('Erreur: $e', isError: true);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return PopScope(
      canPop: false,
      onPopInvokedWithResult: (didPop, result) {
        if (!didPop) {
          // Return with refresh flag to update calendar
          Navigator.pop(context, {'refreshCalendar': _dataChanged || true});
        }
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

    // Check if booking has consumptions
    final bool hasConsumptions =
        _bookingDetails != null && _bookingDetails!.consumptions.isNotEmpty;

    // Define border radius constant to ensure consistency
    const double buttonBorderRadius = 8.0;

    // Define more prominent colors for the cancel button
    final cancelButtonColor =
        isCancelled
            ? CupertinoColors.activeBlue.withOpacity(0.8)
            : hasConsumptions
            ? CupertinoColors
                .systemGrey4 // Disabled color
            : themeService.darkMode
            ? CupertinoColors.systemGrey5.darkColor
            : CupertinoColors
                .systemGrey6; // Lighter background for better contrast

    // Define a more visible border color for the cancel button
    final cancelBorderColor =
        isCancelled
            ? CupertinoColors.activeBlue
            : hasConsumptions
            ? CupertinoColors.systemGrey
            : CupertinoColors.systemRed.withOpacity(
              0.6,
            ); // More visible red tint for border

    // Define more prominent text color for the cancel button
    final cancelTextColor =
        isCancelled
            ? CupertinoColors.white
            : hasConsumptions
            ? CupertinoColors.systemGrey
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
                  onPressed:
                      hasConsumptions && !isCancelled
                          ? () =>
                              _showCantCancelDialog() // Show explanation dialog when has consumptions
                          : () {
                            if (isCancelled) {
                              _showReinstateConfirmation();
                            } else {
                              _showCancelConfirmation();
                            }
                          },
                  child: Text(
                    isCancelled ? 'Remettre' : 'Annuler',
                    style: TextStyle(
                      color: cancelTextColor, // More visible text
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
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
                        if (!mounted) return; // Add mounted check here

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

    // Get cancellation status
    final bool isCancelled = _bookingDetails?.booking.isCancelled ?? false;

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

                // Consumptions section - Only show when not cancelled
                if (!isCancelled) ...[
                  _buildCompactSection(
                    title: 'Consommations',
                    icon: CupertinoIcons.cart_fill,
                    trailing: CupertinoButton(
                      padding: EdgeInsets.zero,
                      onPressed: _showAddConsumptionDialog,
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 12,
                          vertical: 8,
                        ),
                        decoration: BoxDecoration(
                          color: CupertinoColors.systemBlue,
                          borderRadius: BorderRadius.circular(20),
                          boxShadow: [
                            BoxShadow(
                              color: CupertinoTheme.of(
                                context,
                              ).primaryColor.withAlpha((0.3 * 255).round()),
                              blurRadius: 8,
                              offset: const Offset(0, 3),
                            ),
                          ],
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: const [
                            Icon(
                              CupertinoIcons.plus,
                              color: CupertinoColors.white,
                              size: 16,
                            ),
                            SizedBox(width: 4),
                            Text(
                              'Ajouter',
                              style: TextStyle(
                                color: CupertinoColors.white,
                                fontWeight: FontWeight.w600,
                                fontSize: 14,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                    child: _buildConsumptionSection(),
                  ),
                  const SizedBox(height: 16),
                ],

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
                  color: primaryColor.withAlpha((0.1 * 255).round()),
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
                  color: primaryColor.withAlpha((0.1 * 255).round()),
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
                    color: primaryColor.withAlpha((0.1 * 255).round()),
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
    // Get auth service and check user role
    final authService = Provider.of<AuthService>(context, listen: false);
    final isAdmin = authService.userRole == 'admin';

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

          // Contact info rows - Only show if user is admin
          if (isAdmin)
            Row(
              children: [
                // Phone
                Expanded(
                  child: _buildInfoItem(
                    CupertinoIcons.phone_fill,
                    'Téléphone',
                    _bookingDetails!.booking.phoneNumber,
                    onTap:
                        () =>
                            _launchPhone(_bookingDetails!.booking.phoneNumber),
                  ),
                ),
                const SizedBox(width: 16),
                // Email
                Expanded(
                  child: _buildInfoItem(
                    CupertinoIcons.mail_solid,
                    'Email',
                    _bookingDetails!.booking.email,
                    onTap: () => _launchEmail(_bookingDetails!.booking.email),
                  ),
                ),
              ],
            )
          else
            Padding(
              padding: const EdgeInsets.only(top: 4.0),
              child: Text(
                'Les coordonnées sont visibles uniquement par les administrateurs',
                style: TextStyle(
                  fontSize: 14,
                  color: themeService.getSecondaryTextColor(),
                ),
              ),
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

    // Calculate consumption total
    final consumptionsTotal = _bookingDetails!.consumptionsTotal;

    // Calculate activity price correctly using the pricing model
    double activityPrice = _calculateActivityPrice();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Activity price and consumptions
        Row(
          children: [
            Expanded(
              child: _buildInfoItem(
                CupertinoIcons.game_controller,
                'Prix activité',
                currencyFormat.format(activityPrice),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: _buildInfoItem(
                CupertinoIcons.cart_fill,
                'Consommations',
                currencyFormat.format(consumptionsTotal),
                isHighlighted: consumptionsTotal > 0,
              ),
            ),
          ],
        ),

        const SizedBox(height: 12),

        // Deposit and total
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

        // Restant à payer
        _buildInfoItem(
          CupertinoIcons.money_euro,
          'Restant à payer',
          currencyFormat.format(amount),
          isHighlighted: true,
          highlightColor: amount == 0 ? CupertinoColors.activeGreen : null,
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

  // New helper method to calculate activity price correctly based on pricing model
  double _calculateActivityPrice() {
    return _bookingService.calculateActivityPrice(_bookingDetails!);
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
            ? primaryColor.withAlpha((0.1 * 255).round())
            : themeService.darkMode
            ? CupertinoColors.systemGrey6.darkColor
            : CupertinoColors.systemGrey6;

    final borderColor =
        isPaid
            ? primaryColor.withAlpha((0.3 * 255).round())
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
              color: CupertinoTheme.of(
                context,
              ).primaryColor.withAlpha((0.1 * 255).round()),
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
    Color? highlightColor,
  }) {
    final textColor = themeService.getTextColor();
    final secondaryTextColor = themeService.getSecondaryTextColor();
    final backgroundColor =
        themeService.darkMode
            ? CupertinoColors.systemGrey6.darkColor
            : CupertinoColors.systemGrey6;
    final borderColor = themeService.getSeparatorColor();

    // Use provided highlight color or default to primary color
    final Color activeColor =
        highlightColor ?? CupertinoTheme.of(context).primaryColor;

    // If amount is 0 and we're highlighting with green, change the background color as well
    final bool isGreenZeroAmount =
        isHighlighted && highlightColor == CupertinoColors.activeGreen;

    final Color containerBgColor =
        isGreenZeroAmount
            ? CupertinoColors.activeGreen.withOpacity(0.1)
            : backgroundColor;

    final Color containerBorderColor =
        isGreenZeroAmount
            ? CupertinoColors.activeGreen.withOpacity(0.3)
            : borderColor;

    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 10),
        decoration: BoxDecoration(
          color: containerBgColor,
          borderRadius: BorderRadius.circular(8),
          border: Border.all(color: containerBorderColor, width: 0.5),
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
                  color: isHighlighted ? activeColor : secondaryTextColor,
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
                      color: isHighlighted ? activeColor : textColor,
                    ),
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
                if (isGreenZeroAmount)
                  Icon(
                    CupertinoIcons.checkmark_circle_fill,
                    color: CupertinoColors.activeGreen,
                    size: 16,
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

  void _launchEmail(String email) async {
    // Show confirmation dialog before launching email
    showCupertinoDialog(
      context: context,
      builder:
          (BuildContext context) => CupertinoAlertDialog(
            title: const Text('Envoyer un email'),
            content: Text('Voulez-vous envoyer un email à $email ?'),
            actions: [
              CupertinoDialogAction(
                child: const Text('Annuler'),
                onPressed: () {
                  Navigator.pop(context);
                },
              ),
              CupertinoDialogAction(
                isDefaultAction: true,
                onPressed: () async {
                  Navigator.pop(context);

                  // Launch email client after confirmation
                  final Uri emailUri = Uri(scheme: 'mailto', path: email);
                  if (await canLaunchUrl(emailUri)) {
                    await launchUrl(emailUri);
                  } else {
                    _showCupertinoToast(
                      'Impossible d\'ouvrir l\'application de messagerie',
                      isError: true,
                    );
                  }
                },
                child: const Text('Envoyer'),
              ),
            ],
          ),
    );
  }

  void _launchPhone(String phoneNumber) async {
    // Show confirmation dialog before launching phone call
    showCupertinoDialog(
      context: context,
      builder:
          (BuildContext context) => CupertinoAlertDialog(
            title: const Text('Appeler'),
            content: Text('Voulez-vous appeler $phoneNumber ?'),
            actions: [
              CupertinoDialogAction(
                child: const Text('Annuler'),
                onPressed: () {
                  Navigator.pop(context);
                },
              ),
              CupertinoDialogAction(
                isDefaultAction: true,
                onPressed: () async {
                  Navigator.pop(context);

                  // Launch phone dialer after confirmation
                  final Uri phoneUri = Uri(scheme: 'tel', path: phoneNumber);
                  if (await canLaunchUrl(phoneUri)) {
                    await launchUrl(phoneUri);
                  } else {
                    _showCupertinoToast(
                      'Impossible d\'ouvrir l\'application de téléphone',
                      isError: true,
                    );
                  }
                },
                child: const Text('Appeler'),
              ),
            ],
          ),
    );
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
      // Use booking service to delete the booking
      await _bookingService.deleteBooking(_bookingDetails!.activityBookingId);

      // Check if widget is still mounted before updating state
      if (!mounted) return;

      setState(() {
        _isLoading = false;
      });

      _showCupertinoToast('Réservation supprimée avec succès');
      Navigator.pop(context, {'status': 'deleted', 'refreshCalendar': true});
    } catch (e) {
      // Check if widget is still mounted before updating state
      if (!mounted) return;

      setState(() {
        _isLoading = false;
      });

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
      // Use booking service to cancel the booking
      await _bookingService.cancelBooking(_bookingDetails!.booking.bookingId);

      if (!mounted) return;

      setState(() {
        _isLoading = false;
      });

      _showCupertinoToast('Réservation annulée avec succès');
      Navigator.pop(context, {'status': 'cancelled', 'refreshCalendar': true});
    } catch (e) {
      if (!mounted) return;

      setState(() {
        _isLoading = false;
      });

      _showCupertinoToast('Erreur lors de l\'annulation: $e', isError: true);
    }
  }

  Future<void> _showReinstateConfirmation() async {
    return showCupertinoDialog<void>(
      context: context,
      builder:
          (BuildContext context) => CupertinoAlertDialog(
            title: const Text('Confirmer la réactivation'),
            content: const Text(
              'Voulez-vous vraiment réactiver cette réservation?',
            ),
            actions: <CupertinoDialogAction>[
              CupertinoDialogAction(
                child: const Text('Retour'),
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
                child: const Text('Confirmer'),
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
      // Use booking service to reinstate the booking
      await _bookingService.reinstateBooking(
        _bookingDetails!.booking.bookingId,
      );

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

  // New method to build the consumption section
  Widget _buildConsumptionSection() {
    final currencyFormat = NumberFormat.currency(
      locale: 'fr_FR',
      symbol: '€',
      decimalDigits: 2,
    );

    if (_bookingDetails!.consumptions.isEmpty) {
      return Container(
        padding: const EdgeInsets.symmetric(vertical: 20),
        alignment: Alignment.center,
        child: Text(
          'Aucune consommation',
          style: TextStyle(color: themeService.getSecondaryTextColor()),
        ),
      );
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Column headers
        Padding(
          padding: const EdgeInsets.only(bottom: 8.0),
          child: Row(
            children: [
              Expanded(
                flex: 5,
                child: Text(
                  'Produit',
                  style: TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                    color: themeService.getSecondaryTextColor(),
                  ),
                ),
              ),
              Expanded(
                flex: 2,
                child: Text(
                  'Qté',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                    color: themeService.getSecondaryTextColor(),
                  ),
                ),
              ),
              Expanded(
                flex: 3,
                child: Text(
                  'Total',
                  textAlign: TextAlign.right,
                  style: TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                    color: themeService.getSecondaryTextColor(),
                  ),
                ),
              ),
              const SizedBox(width: 40), // Space for delete button
            ],
          ),
        ),

        const Divider(height: 1),

        // List of consumption items
        ...List.generate(_bookingDetails!.consumptions.length, (index) {
          final item = _bookingDetails!.consumptions[index];
          return Padding(
            padding: const EdgeInsets.symmetric(vertical: 12.0),
            child: Row(
              children: [
                // Item name and price
                Expanded(
                  flex: 5,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        item.name,
                        style: const TextStyle(
                          fontWeight: FontWeight.w500,
                          fontSize: 15,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        '${currencyFormat.format(item.price)} / unité',
                        style: TextStyle(
                          fontSize: 12,
                          color: themeService.getSecondaryTextColor(),
                        ),
                      ),
                    ],
                  ),
                ),

                // Quantity with +/- controls
                Expanded(
                  flex: 2,
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      // Decrease quantity button
                      GestureDetector(
                        onTap: () {
                          _updateConsumptionQuantity(
                            item.id,
                            item.quantity - 1,
                          );
                        },
                        child: Container(
                          padding: const EdgeInsets.all(5), // Reduced padding
                          decoration: BoxDecoration(
                            color: themeService.getSeparatorColor().withAlpha(
                              (0.2 * 255).round(),
                            ),
                            borderRadius: BorderRadius.circular(6),
                          ),
                          child: const Icon(
                            CupertinoIcons.minus,
                            size: 14,
                            color: CupertinoColors.systemGrey,
                          ),
                        ),
                      ),

                      // Quantity display - Decreased horizontal padding
                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 4),
                        child: Text(
                          '${item.quantity}',
                          style: const TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 15,
                          ),
                        ),
                      ),

                      // Increase quantity button
                      GestureDetector(
                        onTap: () {
                          _updateConsumptionQuantity(
                            item.id,
                            item.quantity + 1,
                          );
                        },
                        child: Container(
                          padding: const EdgeInsets.all(5), // Reduced padding
                          decoration: BoxDecoration(
                            color: CupertinoTheme.of(
                              context,
                            ).primaryColor.withAlpha((0.2 * 255).round()),
                            borderRadius: BorderRadius.circular(6),
                          ),
                          child: Icon(
                            CupertinoIcons.plus,
                            size: 14,
                            color: CupertinoTheme.of(context).primaryColor,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),

                // Total price
                Expanded(
                  flex: 3,
                  child: Text(
                    currencyFormat.format(item.price * item.quantity),
                    style: const TextStyle(
                      fontWeight: FontWeight.w600,
                      fontSize: 15,
                    ),
                    textAlign: TextAlign.right,
                  ),
                ),

                // Delete button
                CupertinoButton(
                  padding: const EdgeInsets.only(left: 8),
                  minSize: 24,
                  child: const Icon(
                    CupertinoIcons.delete,
                    size: 18,
                    color: CupertinoColors.systemRed,
                  ),
                  onPressed: () => _removeConsumption(item.id),
                ),
              ],
            ),
          );
        }),

        // Total
        const Divider(),
        Padding(
          padding: const EdgeInsets.only(top: 12.0),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text(
                'Total',
                style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
              ),
              Text(
                currencyFormat.format(_bookingDetails!.consumptionsTotal),
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 16,
                  color: CupertinoTheme.of(context).primaryColor,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  // Method to update the quantity of a consumption item
  void _updateConsumptionQuantity(String itemId, int newQuantity) async {
    final FoodItem? item = _bookingDetails!.getConsumptionById(itemId);
    if (item == null) return;

    // Check if we're decreasing to zero or negative
    if (newQuantity <= 0) {
      // If the new quantity is zero or negative, remove the item completely
      double activityPrice = _bookingDetails!.activityPrice;

      // Update UI immediately to show the item is removed
      setState(() {
        // Remove the item from the list
        _bookingDetails!.consumptions.removeWhere((i) => i.id == itemId);

        // Calculate new consumption total from all remaining items
        double newConsumptionsTotal = 0;
        for (var consumption in _bookingDetails!.consumptions) {
          newConsumptionsTotal += consumption.price * consumption.quantity;
        }

        // Create updated booking with new totals
        final updatedBooking = BookingInfo(
          bookingId: _bookingDetails!.booking.bookingId,
          firstname: _bookingDetails!.booking.firstname,
          lastname: _bookingDetails!.booking.lastname,
          date: _bookingDetails!.booking.date,
          nbrPers: _bookingDetails!.booking.nbrPers,
          nbrParties: _bookingDetails!.booking.nbrParties,
          email: _bookingDetails!.booking.email,
          phoneNumber: _bookingDetails!.booking.phoneNumber,
          notes: _bookingDetails!.booking.notes,
          total:
              activityPrice +
              newConsumptionsTotal, // Key formula: activityPrice + consumptionsTotal
          amount:
              (activityPrice + newConsumptionsTotal) -
              (_bookingDetails!.booking.deposit +
                  (_bookingDetails!.booking.cardPayment ?? 0) +
                  (_bookingDetails!.booking.cashPayment ?? 0)),
          deposit: _bookingDetails!.booking.deposit,
          isCancelled: _bookingDetails!.booking.isCancelled,
          cardPayment: _bookingDetails!.booking.cardPayment,
          cashPayment: _bookingDetails!.booking.cashPayment,
        );

        // Update booking details with new data
        _bookingDetails = BookingDetails(
          activityBookingId: _bookingDetails!.activityBookingId,
          booking: updatedBooking,
          activity: _bookingDetails!.activity,
          pricing: _bookingDetails!.pricing,
          createdAt: _bookingDetails!.createdAt,
          updatedAt: _bookingDetails!.updatedAt,
          consumptions: _bookingDetails!.consumptions,
          activityPrice: activityPrice,
        );
      });

      // Now remove the item in the database
      try {
        await _bookingService.removeConsumption(
          _bookingDetails!.booking.bookingId,
          itemId,
        );

        // Calculate consumption total from current items
        double newConsumptionsTotal = 0;
        for (var consumption in _bookingDetails!.consumptions) {
          newConsumptionsTotal += consumption.price * consumption.quantity;
        }

        // Update booking total in database
        await _bookingService.updateBookingTotalInDatabase(
          _bookingDetails!.booking.bookingId,
          activityPrice,
          newConsumptionsTotal,
          _bookingDetails!.booking.deposit,
          _bookingDetails!.booking.cardPayment,
          _bookingDetails!.booking.cashPayment,
        );

        _dataChanged = true;

        if (mounted) {
          _showCupertinoToast('Article supprimé');
        }
      } catch (e) {
        if (mounted) {
          _showCupertinoToast(
            'Erreur lors de la suppression: $e',
            isError: true,
          );
          await _fetchBookingDetails(); // Refresh to get correct state
        }
      }
      return;
    }

    // Store the quantity change info
    bool isIncreasing = newQuantity > item.quantity;
    int oldQuantity = item.quantity;
    double activityPrice = _bookingDetails!.activityPrice;

    // Update the UI immediately with a full recalculation
    setState(() {
      final index = _bookingDetails!.consumptions.indexWhere(
        (i) => i.id == itemId,
      );
      if (index != -1) {
        // Create a new FoodItem with updated quantity
        final updatedItem = _bookingDetails!.consumptions[index].copyWith(
          quantity: newQuantity,
        );
        // Replace the item in the list
        _bookingDetails!.consumptions[index] = updatedItem;

        // Calculate the true consumption total from all items
        double newConsumptionsTotal = 0;
        for (var consumption in _bookingDetails!.consumptions) {
          newConsumptionsTotal += consumption.price * consumption.quantity;
        }

        // Update the booking object with new totals
        final updatedBooking = BookingInfo(
          bookingId: _bookingDetails!.booking.bookingId,
          firstname: _bookingDetails!.booking.firstname,
          lastname: _bookingDetails!.booking.lastname,
          date: _bookingDetails!.booking.date,
          nbrPers: _bookingDetails!.booking.nbrPers,
          nbrParties: _bookingDetails!.booking.nbrParties,
          email: _bookingDetails!.booking.email,
          phoneNumber: _bookingDetails!.booking.phoneNumber,
          notes: _bookingDetails!.booking.notes,
          total: activityPrice + newConsumptionsTotal,
          amount:
              (activityPrice + newConsumptionsTotal) -
              (_bookingDetails!.booking.deposit +
                  (_bookingDetails!.booking.cardPayment ?? 0) +
                  (_bookingDetails!.booking.cashPayment ?? 0)),
          deposit: _bookingDetails!.booking.deposit,
          isCancelled: _bookingDetails!.booking.isCancelled,
          cardPayment: _bookingDetails!.booking.cardPayment,
          cashPayment: _bookingDetails!.booking.cashPayment,
        );

        // Update the booking details with new booking info
        _bookingDetails = BookingDetails(
          activityBookingId: _bookingDetails!.activityBookingId,
          booking: updatedBooking,
          activity: _bookingDetails!.activity,
          pricing: _bookingDetails!.pricing,
          createdAt: _bookingDetails!.createdAt,
          updatedAt: _bookingDetails!.updatedAt,
          consumptions: _bookingDetails!.consumptions,
          activityPrice: activityPrice,
        );
      }
    });

    // Then perform the server update in the background
    try {
      if (isIncreasing) {
        // Increasing quantity - use BookingService
        await _bookingService.updateConsumptionQuantity(
          _bookingDetails!.booking.bookingId,
          itemId,
          oldQuantity + 1,
        );
      } else {
        // Decreasing quantity - use BookingService
        await _bookingService.decreaseConsumptionQuantity(
          _bookingDetails!.booking.bookingId,
          itemId,
        );
      }

      // Calculate consumption total from current items
      double newConsumptionsTotal = 0;
      for (var consumption in _bookingDetails!.consumptions) {
        newConsumptionsTotal += consumption.price * consumption.quantity;
      }

      // Update booking total in database
      await _bookingService.updateBookingTotalInDatabase(
        _bookingDetails!.booking.bookingId,
        activityPrice,
        newConsumptionsTotal,
        _bookingDetails!.booking.deposit,
        _bookingDetails!.booking.cardPayment,
        _bookingDetails!.booking.cashPayment,
      );

      // Mark data as changed
      _dataChanged = true;

      // Show a toast confirmation if needed
      if (mounted) {
        _showCupertinoToast('Quantité mise à jour avec succès');
      }
    } catch (e) {
      // If there was an error, show error message and refresh to get correct state
      if (mounted) {
        _showCupertinoToast('Erreur lors de la mise à jour: $e', isError: true);
        // Only refresh in case of an error to ensure data consistency
        await _fetchBookingDetails();
      }
    }
  }

  // Method to only refresh consumption data without rebuilding the entire UI
  Future<void> _refreshConsumptionsOnly() async {
    try {
      // Fetch only consumptions using the get_conso function
      final consumptionsResponse = await supabase.rpc(
        'get_conso',
        params: {'actual_booking_id': _bookingDetails!.booking.bookingId},
      );

      // Convert consumption items and update the existing booking details
      if (consumptionsResponse != null && mounted) {
        final consumptionsList =
            (consumptionsResponse as List)
                .map(
                  (item) => FoodItem(
                    id: item['food_id'],
                    name: item['name'],
                    price:
                        _parseDouble(item['price']) /
                        _parseInt(item['quantity']), // Get unit price
                    quantity: _parseInt(item['quantity']),
                  ),
                )
                .toList();

        // Update state with new consumption data
        setState(() {
          _bookingDetails!.consumptions.clear();
          _bookingDetails!.consumptions.addAll(consumptionsList);
        });
      }
    } catch (e) {
      // Silently handle error as this is a background refresh
      debugPrint('Error refreshing consumptions: $e');
    }
  }

  // Method to remove a consumption item
  void _removeConsumption(String itemId) {
    showCupertinoDialog(
      context: context,
      builder:
          (context) => CupertinoAlertDialog(
            title: const Text('Supprimer cet article'),
            content: const Text(
              'Voulez-vous vraiment supprimer cet article des consommations ?',
            ),
            actions: [
              CupertinoDialogAction(
                child: const Text('Annuler'),
                onPressed: () {
                  Navigator.pop(context);
                },
              ),
              CupertinoDialogAction(
                isDestructiveAction: true,
                onPressed: () async {
                  Navigator.pop(context);

                  // Get the item to be removed before removing it from the list
                  final item = _bookingDetails!.getConsumptionById(itemId);
                  if (item == null) return;

                  // Calculate the price to subtract from totals
                  double itemTotalPrice = item.price * item.quantity;
                  double activityPrice = _bookingDetails!.activityPrice;
                  double currentConsumptionsTotal =
                      _bookingDetails!.consumptionsTotal;
                  double newConsumptionsTotal =
                      currentConsumptionsTotal - itemTotalPrice;

                  // Update UI immediately for better user experience
                  setState(() {
                    // Remove the item from the list
                    _bookingDetails!.consumptions.removeWhere(
                      (i) => i.id == itemId,
                    );

                    // Update booking with new totals
                    final updatedBooking = BookingInfo(
                      bookingId: _bookingDetails!.booking.bookingId,
                      firstname: _bookingDetails!.booking.firstname,
                      lastname: _bookingDetails!.booking.lastname,
                      date: _bookingDetails!.booking.date,
                      nbrPers: _bookingDetails!.booking.nbrPers,
                      nbrParties: _bookingDetails!.booking.nbrParties,
                      email: _bookingDetails!.booking.email,
                      phoneNumber: _bookingDetails!.booking.phoneNumber,
                      notes: _bookingDetails!.booking.notes,
                      total: activityPrice + newConsumptionsTotal,
                      amount:
                          (activityPrice + newConsumptionsTotal) -
                          (_bookingDetails!.booking.deposit +
                              (_bookingDetails!.booking.cardPayment ?? 0) +
                              (_bookingDetails!.booking.cashPayment ?? 0)),
                      deposit: _bookingDetails!.booking.deposit,
                      isCancelled: _bookingDetails!.booking.isCancelled,
                      cardPayment: _bookingDetails!.booking.cardPayment,
                      cashPayment: _bookingDetails!.booking.cashPayment,
                    );

                    // Update the booking details object
                    _bookingDetails = BookingDetails(
                      activityBookingId: _bookingDetails!.activityBookingId,
                      booking: updatedBooking,
                      activity: _bookingDetails!.activity,
                      pricing: _bookingDetails!.pricing,
                      createdAt: _bookingDetails!.createdAt,
                      updatedAt: _bookingDetails!.updatedAt,
                      consumptions: _bookingDetails!.consumptions,
                      activityPrice: activityPrice,
                    );
                  });

                  try {
                    // Now update the database
                    await _bookingService.removeConsumption(
                      _bookingDetails!.booking.bookingId,
                      itemId,
                    );

                    // Update the booking total in the database
                    await _bookingService.updateBookingTotalInDatabase(
                      _bookingDetails!.booking.bookingId,
                      activityPrice,
                      newConsumptionsTotal,
                      _bookingDetails!.booking.deposit,
                      _bookingDetails!.booking.cardPayment,
                      _bookingDetails!.booking.cashPayment,
                    );

                    _dataChanged = true;

                    if (mounted) {
                      _showCupertinoToast('Article supprimé avec succès');
                    }
                  } catch (e) {
                    if (mounted) {
                      _showCupertinoToast(
                        'Erreur lors de la suppression: $e',
                        isError: true,
                      );

                      // In case of error, refresh to get the correct state
                      await _fetchBookingDetails();
                    }
                  }
                },
                child: const Text('Supprimer'),
              ),
            ],
          ),
    );
  }

  // Method to show the dialog to add new consumption items
  void _showAddConsumptionDialog() {
    showCupertinoModalPopup(
      context: context,
      builder: (context) => _buildAddConsumptionModal(),
    );
  }

  // Build the modal to add new consumption items
  Widget _buildAddConsumptionModal() {
    // Add a search term state variable
    String searchTerm = '';

    return StatefulBuilder(
      builder: (context, setState) {
        return Container(
          height: MediaQuery.of(context).size.height * 0.7,
          padding: const EdgeInsets.only(top: 12),
          decoration: BoxDecoration(
            color: themeService.getBackgroundColor(),
            borderRadius: const BorderRadius.only(
              topLeft: Radius.circular(16),
              topRight: Radius.circular(16),
            ),
          ),
          child: Column(
            children: [
              // Header
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16.0),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    CupertinoButton(
                      padding: EdgeInsets.zero,
                      onPressed: () => Navigator.pop(context),
                      child: const Text('Annuler'),
                    ),
                    const Text(
                      'Ajouter une consommation',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    CupertinoButton(
                      padding: EdgeInsets.zero,
                      onPressed: () => Navigator.pop(context),
                      child: const Text('OK'),
                    ),
                  ],
                ),
              ),

              // Divider
              Container(
                height: 1,
                color: themeService.getSeparatorColor(),
                margin: const EdgeInsets.symmetric(vertical: 8),
              ),

              // Search field - Updated to update searchTerm
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16.0),
                child: CupertinoSearchTextField(
                  placeholder: 'Rechercher un produit',
                  onChanged: (value) {
                    // Update search term and rebuild widget with setState
                    setState(() {
                      searchTerm = value.toLowerCase();
                    });
                  },
                ),
              ),

              // List of food items - now passing searchTerm
              Expanded(child: _buildFoodItemsList(setState, searchTerm)),
            ],
          ),
        );
      },
    );
  }

  // Method to build the list of food items - Updated to include search filtering
  Widget _buildFoodItemsList(StateSetter modalSetState, String searchTerm) {
    return FutureBuilder<List<FoodItem>>(
      future: _fetchFoodItems(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CupertinoActivityIndicator());
        } else if (snapshot.hasError) {
          return Center(
            child: Text(
              'Erreur lors du chargement: ${snapshot.error}',
              style: const TextStyle(color: CupertinoColors.systemRed),
            ),
          );
        } else if (!snapshot.hasData || snapshot.data!.isEmpty) {
          return const Center(child: Text('Aucun produit disponible'));
        }

        // Filter food items based on search term
        final allFoodItems = snapshot.data!;
        final foodItems =
            searchTerm.isEmpty
                ? allFoodItems
                : allFoodItems
                    .where(
                      (item) => item.name.toLowerCase().contains(searchTerm),
                    )
                    .toList();

        // Show a message when no search results are found
        if (foodItems.isEmpty) {
          return Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(
                  CupertinoIcons.search,
                  size: 64,
                  color: CupertinoColors.systemGrey.withOpacity(0.5),
                ),
                const SizedBox(height: 16),
                const Text(
                  'Aucun produit trouvé',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w500,
                    color: CupertinoColors.systemGrey,
                  ),
                ),
              ],
            ),
          );
        }

        final currencyFormat = NumberFormat.currency(
          locale: 'fr_FR',
          symbol: '€',
          decimalDigits: 2,
        );

        // Removing any potential padding that might create space
        return ListView.builder(
          padding: EdgeInsets.zero, // Remove any default padding
          itemCount: foodItems.length,
          itemBuilder: (context, index) {
            final item = foodItems[index];
            // Track if request is in progress to prevent multiple calls
            final isLoading = ValueNotifier<bool>(false);

            return Column(
              children: [
                if (index > 0)
                  Divider(height: 1, color: themeService.getSeparatorColor()),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 12,
                  ),
                  child: Row(
                    children: [
                      // Item name and price
                      Expanded(
                        flex: 3,
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              item.name,
                              style: const TextStyle(
                                fontSize: 17,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              currencyFormat.format(item.price),
                              style: TextStyle(
                                fontSize: 14,
                                color: themeService.getSecondaryTextColor(),
                              ),
                            ),
                          ],
                        ),
                      ),

                      // Add button
                      ValueListenableBuilder<bool>(
                        valueListenable: isLoading,
                        builder: (context, loading, _) {
                          return CupertinoButton(
                            padding: EdgeInsets.zero,
                            onPressed:
                                loading
                                    ? null
                                    : () async {
                                      isLoading.value = true;
                                      await _addConsumption(
                                        item.copyWith(quantity: 1),
                                      );
                                      isLoading.value = false;
                                    },
                            child: Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 20,
                                vertical: 10,
                              ),
                              decoration: BoxDecoration(
                                color:
                                    loading
                                        ? CupertinoColors.systemGrey
                                        : CupertinoTheme.of(
                                          context,
                                        ).primaryColor,
                                borderRadius: BorderRadius.circular(8),
                              ),
                              child: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  if (loading)
                                    const CupertinoActivityIndicator(
                                      radius: 8,
                                      color: CupertinoColors.white,
                                    )
                                  else
                                    const Icon(
                                      CupertinoIcons.plus,
                                      size: 16,
                                      color: CupertinoColors.white,
                                    ),
                                  const SizedBox(width: 6),
                                  Text(
                                    loading ? 'Ajout...' : 'Ajouter',
                                    style: const TextStyle(
                                      color: CupertinoColors.white,
                                      fontWeight: FontWeight.w500,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          );
                        },
                      ),
                    ],
                  ),
                ),
              ],
            );
          },
        );
      },
    );
  }

  // Method to fetch food items using the BookingService
  Future<List<FoodItem>> _fetchFoodItems() async {
    try {
      return await _bookingService.getFoodItems();
    } catch (e) {
      throw 'Erreur lors du chargement des produits: $e';
    }
  }

  // Method to add a consumption to the booking
  Future<void> _addConsumption(FoodItem item) async {
    try {
      // Use the BookingService to add the consumption
      await _bookingService.addConsumption(
        _bookingDetails!.booking.bookingId,
        item,
      );

      // Calculate activity price correctly
      double activityPrice =
          _bookingDetails!.activityPrice > 0
              ? _bookingDetails!.activityPrice
              : _bookingService.calculateActivityPrice(_bookingDetails!);

      // Update the consumptions list to get the current state
      await _refreshConsumptionsOnly();

      // Calculate the true consumption total from the items we have
      double newConsumptionsTotal = 0;
      for (var consumption in _bookingDetails!.consumptions) {
        newConsumptionsTotal += consumption.price * consumption.quantity;
      }

      // Calculate correct total as activityPrice + consumptionsTotal
      double newTotal = activityPrice + newConsumptionsTotal;
      double newAmount =
          newTotal -
          (_bookingDetails!.booking.deposit +
              (_bookingDetails!.booking.cardPayment ?? 0) +
              (_bookingDetails!.booking.cashPayment ?? 0));

      // Update the booking total in database with the correct values
      await _bookingService.updateBookingTotalInDatabase(
        _bookingDetails!.booking.bookingId,
        activityPrice,
        newConsumptionsTotal,
        _bookingDetails!.booking.deposit,
        _bookingDetails!.booking.cardPayment,
        _bookingDetails!.booking.cashPayment,
      );

      // Mark data as changed
      _dataChanged = true;

      // Update the UI with the correct totals
      setState(() {
        final updatedBooking = BookingInfo(
          bookingId: _bookingDetails!.booking.bookingId,
          firstname: _bookingDetails!.booking.firstname,
          lastname: _bookingDetails!.booking.lastname,
          date: _bookingDetails!.booking.date,
          nbrPers: _bookingDetails!.booking.nbrPers,
          nbrParties: _bookingDetails!.booking.nbrParties,
          email: _bookingDetails!.booking.email,
          phoneNumber: _bookingDetails!.booking.phoneNumber,
          notes: _bookingDetails!.booking.notes,
          total: newTotal,
          amount: newAmount,
          deposit: _bookingDetails!.booking.deposit,
          isCancelled: _bookingDetails!.booking.isCancelled,
          cardPayment: _bookingDetails!.booking.cardPayment,
          cashPayment: _bookingDetails!.booking.cashPayment,
        );

        // Update the booking details object
        _bookingDetails = BookingDetails(
          activityBookingId: _bookingDetails!.activityBookingId,
          booking: updatedBooking,
          activity: _bookingDetails!.activity,
          pricing: _bookingDetails!.pricing,
          createdAt: _bookingDetails!.createdAt,
          updatedAt: _bookingDetails!.updatedAt,
          consumptions: _bookingDetails!.consumptions,
          activityPrice: activityPrice,
        );
      });

      // Show success toast
      if (mounted) {
        _showCupertinoToast('Consommation ajoutée');
      }
    } catch (e) {
      // In case of error, refresh to restore correct state
      await _fetchBookingDetails();
      if (mounted) {
        _showCupertinoToast('Erreur lors de l\'ajout: $e', isError: true);
      }
    }
  }

  // Helper methods for parsing values
  double _parseDouble(dynamic value) {
    if (value == null) return 0.0;
    if (value is double) return value;
    if (value is int) return value.toDouble();
    if (value is String) return double.tryParse(value) ?? 0.0;
    return 0.0;
  }

  int _parseInt(dynamic value) {
    if (value == null) return 0;
    if (value is int) return value;
    if (value is String) return int.tryParse(value) ?? 0;
    if (value is double) return value.toInt();
    return 0;
  }

  // Method to show dialog explaining why bookings with consumptions cannot be cancelled
  Future<void> _showCantCancelDialog() async {
    return showCupertinoDialog<void>(
      context: context,
      builder:
          (BuildContext context) => CupertinoAlertDialog(
            title: const Text('Action impossible'),
            content: const Text(
              'Impossible d\'annuler une réservation qui contient des consommations. Veuillez supprimer toutes les consommations avant d\'annuler la réservation.',
            ),
            actions: <CupertinoDialogAction>[
              CupertinoDialogAction(
                isDefaultAction: true,
                onPressed: () {
                  Navigator.pop(context);
                },
                child: const Text('Compris'),
              ),
            ],
          ),
    );
  }
}
