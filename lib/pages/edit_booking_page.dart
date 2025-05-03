import 'package:flutter/material.dart';
import 'package:flutter/cupertino.dart';
import 'package:intl/intl.dart';
import '../models/booking_details.dart';
import '../main.dart'; // For Supabase instance

class EditBookingPage extends StatefulWidget {
  final BookingDetails bookingDetails;

  const EditBookingPage({Key? key, required this.bookingDetails})
    : super(key: key);

  @override
  EditBookingPageState createState() => EditBookingPageState();
}

class EditBookingPageState extends State<EditBookingPage> {
  bool _isLoading = false;
  bool _hasChanges = false;
  bool _loadingActivities = true;

  // Form key for validation
  final _formKey = GlobalKey<FormState>();

  // Controllers for editing text fields
  late TextEditingController _firstnameController;
  late TextEditingController _lastnameController;
  late TextEditingController _emailController;
  late TextEditingController _phoneController;
  late TextEditingController _notesController;
  late TextEditingController _totalController;
  late TextEditingController _depositController;
  late TextEditingController _cardPaymentController;
  late TextEditingController _cashPaymentController;

  // Activity-related fields
  late DateTime _selectedDate;
  late TimeOfDay _selectedTime;
  late int _numberOfPeople;
  late int _numberOfGames;
  late bool _isCancelled;

  // Activity pricing ID
  String? _selectedActivityId;
  List<dynamic> _availableActivities = [];

  @override
  void initState() {
    super.initState();

    // Initialize controllers with current values
    _firstnameController = TextEditingController(
      text: widget.bookingDetails.booking.firstname,
    );
    _lastnameController = TextEditingController(
      text: widget.bookingDetails.booking.lastname ?? '',
    );
    _emailController = TextEditingController(
      text: widget.bookingDetails.booking.email,
    );
    _phoneController = TextEditingController(
      text: widget.bookingDetails.booking.phoneNumber,
    );
    _notesController = TextEditingController(
      text: widget.bookingDetails.booking.notes,
    );

    // Initialize payment controllers
    _totalController = TextEditingController(
      text: widget.bookingDetails.booking.total.toString(),
    );
    _depositController = TextEditingController(
      text: widget.bookingDetails.booking.deposit.toString(),
    );
    _cardPaymentController = TextEditingController(
      text: (widget.bookingDetails.booking.cardPayment ?? 0).toString(),
    );
    _cashPaymentController = TextEditingController(
      text: (widget.bookingDetails.booking.cashPayment ?? 0).toString(),
    );

    // Initialize other fields
    _selectedDate = widget.bookingDetails.booking.date;
    _selectedTime = TimeOfDay(
      hour: widget.bookingDetails.booking.date.hour,
      minute: widget.bookingDetails.booking.date.minute,
    );
    _numberOfPeople = widget.bookingDetails.booking.nbrPers;
    _numberOfGames = widget.bookingDetails.booking.nbrParties;
    _isCancelled = widget.bookingDetails.booking.isCancelled;
    _selectedActivityId = widget.bookingDetails.pricing.id;

    // Load available activities
    _fetchActivities();

    // Add listeners to detect changes
    _addChangeListeners();
  }

  Future<void> _fetchActivities() async {
    setState(() {
      _loadingActivities = true;
    });

    try {
      final response = await supabase.rpc('get_activities');

      setState(() {
        _availableActivities = response as List;
        _loadingActivities = false;
      });
    } catch (e) {
      print('Error fetching activities: $e');
      setState(() {
        _loadingActivities = false;
      });
    }
  }

  void _addChangeListeners() {
    void markAsChanged() {
      if (mounted) {
        setState(() {
          _hasChanges = true;
        });
      }
    }

    _firstnameController.addListener(markAsChanged);
    _lastnameController.addListener(markAsChanged);
    _emailController.addListener(markAsChanged);
    _phoneController.addListener(markAsChanged);
    _notesController.addListener(markAsChanged);
    _totalController.addListener(markAsChanged);
    _depositController.addListener(markAsChanged);
    _cardPaymentController.addListener(markAsChanged);
    _cashPaymentController.addListener(markAsChanged);
  }

  @override
  void dispose() {
    _firstnameController.dispose();
    _lastnameController.dispose();
    _emailController.dispose();
    _phoneController.dispose();
    _notesController.dispose();
    _totalController.dispose();
    _depositController.dispose();
    _cardPaymentController.dispose();
    _cashPaymentController.dispose();
    super.dispose();
  }

  Future<void> _saveBooking() async {
    if (!_formKey.currentState!.validate()) {
      return;
    }

    setState(() {
      _isLoading = true;
    });

    try {
      // Combine date and time
      final DateTime dateTime = DateTime(
        _selectedDate.year,
        _selectedDate.month,
        _selectedDate.day,
        _selectedTime.hour,
        _selectedTime.minute,
      );

      // Parse numeric values from text fields
      double total = double.tryParse(_totalController.text) ?? 0.0;
      double deposit = double.tryParse(_depositController.text) ?? 0.0;
      double cardPayment = double.tryParse(_cardPaymentController.text) ?? 0.0;
      double cashPayment = double.tryParse(_cashPaymentController.text) ?? 0.0;

      // Calculate remaining amount
      double amount = total - deposit - cardPayment - cashPayment;

      // Use the update_booking RPC function with all parameters
      await supabase.rpc(
        'update_booking',
        params: {
          'p_activity_booking_id': widget.bookingDetails.activityBookingId,
          'p_booking_id': widget.bookingDetails.booking.bookingId,
          'p_date': dateTime.toIso8601String(),
          'p_email': _emailController.text,
          'p_phone': _phoneController.text,
          'p_total': total,
          'p_amount': amount,
          'p_comment': _notesController.text,
          'p_deposit': deposit,
          'p_lastname':
              _lastnameController.text.isEmpty
                  ? null
                  : _lastnameController.text,
          'p_nbr_pers': _numberOfPeople,
          'p_firstname': _firstnameController.text,
          'p_nbr_parties': _numberOfGames,
          'p_card_payment': cardPayment,
          'p_cash_payment': cashPayment,
          'p_is_cancelled': _isCancelled,
          'p_activity_pricing_id': _selectedActivityId,
        },
      );

      setState(() {
        _isLoading = false;
        _hasChanges = false;
      });

      if (!context.mounted) return;

      // Show success message and navigate back
      _showCupertinoToast('Réservation mise à jour avec succès');

      // Return to the details page with success indicator
      Navigator.pop(context, true);
    } catch (e) {
      print('Error updating booking: $e');
      setState(() {
        _isLoading = false;
      });

      if (!context.mounted) return;

      // Show error message
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
      if (overlayEntry.mounted) {
        overlayEntry.remove();
      }
    });
  }

  Future<void> _selectDate(BuildContext context) async {
    // Check if booking date is in the past
    final DateTime now = DateTime.now();
    final bool isDateInPast = _selectedDate.isBefore(now);

    // If date is in the past, show a message and don't allow modification
    if (isDateInPast) {
      _showCupertinoToast(
        'Impossible de modifier une date passée',
        isError: true,
      );
      return;
    }

    final DateTime? picked = await showCupertinoModalPopup<DateTime>(
      context: context,
      builder: (BuildContext context) {
        // Ensure the date is not before current
        DateTime currentDate = DateTime.now();
        DateTime selectedDate = _selectedDate;

        // Make sure initial date is not before minimum date
        if (selectedDate.isBefore(currentDate)) {
          selectedDate = DateTime(
            currentDate.year,
            currentDate.month,
            currentDate.day,
            selectedDate.hour,
            selectedDate.minute,
          );
        }

        return Container(
          height: 300,
          color: CupertinoColors.systemBackground.resolveFrom(context),
          child: Column(
            children: [
              Container(
                height: 40,
                padding: const EdgeInsets.symmetric(horizontal: 16),
                decoration: const BoxDecoration(
                  color: CupertinoColors.secondarySystemBackground,
                  border: Border(
                    bottom: BorderSide(
                      color: CupertinoColors.separator,
                      width: 0.0,
                    ),
                  ),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    CupertinoButton(
                      padding: EdgeInsets.zero,
                      child: const Text('Annuler'),
                      onPressed: () {
                        Navigator.of(context).pop();
                      },
                    ),
                    CupertinoButton(
                      padding: EdgeInsets.zero,
                      child: const Text('OK'),
                      onPressed: () {
                        Navigator.of(context).pop(selectedDate);
                      },
                    ),
                  ],
                ),
              ),
              Expanded(
                child: CupertinoDatePicker(
                  initialDateTime: selectedDate,
                  minimumDate: currentDate,
                  maximumDate: currentDate.add(const Duration(days: 365)),
                  mode: CupertinoDatePickerMode.date,
                  onDateTimeChanged: (DateTime newDate) {
                    selectedDate = newDate;
                  },
                ),
              ),
            ],
          ),
        );
      },
    );

    if (picked != null && picked != _selectedDate) {
      setState(() {
        _selectedDate = picked;
        _hasChanges = true;
      });
    }
  }

  Future<void> _selectTime(BuildContext context) async {
    // Check if booking is in the past
    final DateTime now = DateTime.now();
    final DateTime bookingDateTime = DateTime(
      _selectedDate.year,
      _selectedDate.month,
      _selectedDate.day,
      _selectedTime.hour,
      _selectedTime.minute,
    );

    // If date/time is in the past, don't allow modification
    if (bookingDateTime.isBefore(now)) {
      _showCupertinoToast(
        'Impossible de modifier une heure passée',
        isError: true,
      );
      return;
    }

    final TimeOfDay? picked = await showCupertinoModalPopup<TimeOfDay>(
      context: context,
      builder: (BuildContext context) {
        // We need to ensure the initial minutes are divisible by the minute interval (15)
        int adjustedMinutes = (_selectedTime.minute ~/ 15) * 15;

        DateTime selectedDateTime = DateTime(
          _selectedDate.year,
          _selectedDate.month,
          _selectedDate.day,
          _selectedTime.hour,
          adjustedMinutes,
        );

        // If selected date is today, ensure time is not in the past
        if (_selectedDate.year == now.year &&
            _selectedDate.month == now.month &&
            _selectedDate.day == now.day) {
          // Round up current time to next 15 min interval
          int currentMinutes = now.minute;
          int roundedMinutes = ((currentMinutes + 14) ~/ 15) * 15;
          DateTime minimumTime = DateTime(
            now.year,
            now.month,
            now.day,
            roundedMinutes == 60 ? now.hour + 1 : now.hour,
            roundedMinutes == 60 ? 0 : roundedMinutes,
          );

          // If selected time is before minimum time, adjust it
          if (selectedDateTime.isBefore(minimumTime)) {
            selectedDateTime = minimumTime;
          }
        }

        return Container(
          height: 300,
          color: CupertinoColors.systemBackground.resolveFrom(context),
          child: Column(
            children: [
              Container(
                height: 40,
                padding: const EdgeInsets.symmetric(horizontal: 16),
                decoration: const BoxDecoration(
                  color: CupertinoColors.secondarySystemBackground,
                  border: Border(
                    bottom: BorderSide(
                      color: CupertinoColors.separator,
                      width: 0.0,
                    ),
                  ),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    CupertinoButton(
                      padding: EdgeInsets.zero,
                      child: const Text('Annuler'),
                      onPressed: () {
                        Navigator.of(context).pop();
                      },
                    ),
                    CupertinoButton(
                      padding: EdgeInsets.zero,
                      child: const Text('OK'),
                      onPressed: () {
                        Navigator.of(context).pop(
                          TimeOfDay(
                            hour: selectedDateTime.hour,
                            minute: selectedDateTime.minute,
                          ),
                        );
                      },
                    ),
                  ],
                ),
              ),
              Expanded(
                child: CupertinoDatePicker(
                  initialDateTime: selectedDateTime,
                  minimumDate:
                      _selectedDate.year == now.year &&
                              _selectedDate.month == now.month &&
                              _selectedDate.day == now.day
                          ? now
                          : null,
                  mode: CupertinoDatePickerMode.time,
                  use24hFormat: true,
                  minuteInterval: 15,
                  onDateTimeChanged: (DateTime newDateTime) {
                    selectedDateTime = newDateTime;
                  },
                ),
              ),
            ],
          ),
        );
      },
    );

    if (picked != null && picked != _selectedTime) {
      setState(() {
        _selectedTime = picked;
        _hasChanges = true;
      });
    }
  }

  void _showUnsavedChangesDialog() {
    showCupertinoDialog(
      context: context,
      builder:
          (context) => CupertinoAlertDialog(
            title: const Text('Modifications non enregistrées'),
            content: const Text(
              'Vous avez des modifications non enregistrées. Voulez-vous quitter sans les enregistrer?',
            ),
            actions: [
              CupertinoDialogAction(
                child: const Text('Continuer à modifier'),
                onPressed: () => Navigator.pop(context),
              ),
              CupertinoDialogAction(
                isDestructiveAction: true,
                onPressed: () {
                  Navigator.pop(context);
                  Navigator.pop(context, false);
                },
                child: const Text('Quitter sans enregistrer'),
              ),
            ],
          ),
    );
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
      // Delete the booking from the database
      await supabase
          .from('bookings')
          .delete()
          .eq('id', widget.bookingDetails.booking.bookingId);

      setState(() {
        _isLoading = false;
      });

      if (!context.mounted) return;

      // Show success message and navigate back
      _showCupertinoToast('Réservation supprimée avec succès');
      Navigator.pop(
        context,
        'deleted',
      ); // Return 'deleted' to indicate deletion
    } catch (e) {
      print('Error deleting booking: $e');
      setState(() {
        _isLoading = false;
      });

      if (!context.mounted) return;

      // Show error message
      _showCupertinoToast('Erreur lors de la suppression: $e', isError: true);
    }
  }

  @override
  Widget build(BuildContext context) {
    return WillPopScope(
      onWillPop: () async {
        if (_hasChanges) {
          _showUnsavedChangesDialog();
          return false;
        }
        return true;
      },
      child: CupertinoPageScaffold(
        backgroundColor: CupertinoColors.systemGroupedBackground,
        navigationBar: CupertinoNavigationBar(
          middle: const Text('Modifier la réservation'),
          backgroundColor: CupertinoColors.systemGroupedBackground,
          border: null,
        ),
        child: SafeArea(
          bottom:
              false, // Don't include bottom safe area since we have a custom bottom bar
          child: Stack(
            children: [
              _isLoading
                  ? const Center(child: CupertinoActivityIndicator())
                  : _buildForm(),

              // Bottom action bar positioned at the bottom
              Positioned(
                left: 0,
                right: 0,
                bottom: 0,
                child: Container(
                  color: CupertinoColors.systemBackground,
                  padding: EdgeInsets.only(
                    bottom: MediaQuery.of(context).padding.bottom,
                    top: 12,
                    left: 16,
                    right: 16,
                  ),
                  child: CupertinoButton(
                    padding: EdgeInsets.zero,
                    color: CupertinoTheme.of(context).primaryColor,
                    child: const Text(
                      'Modifier',
                      style: TextStyle(
                        color: CupertinoColors.white,
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    onPressed: _isLoading ? null : _saveBooking,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildForm() {
    return Form(
      key: _formKey,
      child: ListView(
        padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
        physics: const AlwaysScrollableScrollPhysics(
          parent: BouncingScrollPhysics(),
        ),
        children: [
          _buildCustomerInfoSection(),
          const SizedBox(height: 16),
          _buildTimeSection(),
          const SizedBox(height: 16),
          _buildActivityInfoSection(),
          const SizedBox(height: 16),
          _buildPaymentSection(),
          const SizedBox(height: 16),
          _buildNotesSection(),
          // Add extra padding at the bottom for better scrolling experience
          const SizedBox(height: 80),
        ],
      ),
    );
  }

  // New payment section for editing payment details
  Widget _buildPaymentSection() {
    return _buildSection(
      title: 'Informations de paiement',
      icon: CupertinoIcons.money_euro_circle,
      children: [
        // Total amount
        _buildNumberField(
          controller: _totalController,
          label: 'Total',
          icon: CupertinoIcons.money_euro,
          suffix: '€',
          validator: (value) {
            if (value == null || value.isEmpty) {
              return 'Veuillez entrer un montant total';
            }
            try {
              double.parse(value);
              return null;
            } catch (e) {
              return 'Veuillez entrer un montant valide';
            }
          },
        ),
        const SizedBox(height: 12),

        // Deposit amount
        _buildNumberField(
          controller: _depositController,
          label: 'Acompte',
          icon: CupertinoIcons.money_euro_circle,
          suffix: '€',
        ),
        const SizedBox(height: 12),

        // Amount to pay (calculated field, disabled)
        _buildInfoRow(
          icon: CupertinoIcons.money_euro,
          label: 'Restant à payer',
          value: _calculateRemainingAmount(),
          showChevron: false,
        ),
        const SizedBox(height: 12),

        // Card payment
        _buildNumberField(
          controller: _cardPaymentController,
          label: 'Paiement par carte',
          icon: CupertinoIcons.creditcard,
          suffix: '€',
        ),
        const SizedBox(height: 12),

        // Cash payment
        _buildNumberField(
          controller: _cashPaymentController,
          label: 'Paiement en espèces',
          icon: CupertinoIcons.money_euro_circle,
          suffix: '€',
        ),
      ],
    );
  }

  // Helper method to calculate the remaining amount to pay
  String _calculateRemainingAmount() {
    double total = double.tryParse(_totalController.text) ?? 0;
    double deposit = double.tryParse(_depositController.text) ?? 0;
    double cardPayment = double.tryParse(_cardPaymentController.text) ?? 0;
    double cashPayment = double.tryParse(_cashPaymentController.text) ?? 0;

    double remaining = total - deposit - cardPayment - cashPayment;
    return '${remaining.toStringAsFixed(2)} €';
  }

  // Number field with currency formatting
  Widget _buildNumberField({
    required TextEditingController controller,
    required String label,
    required IconData icon,
    String? suffix,
    String? Function(String?)? validator,
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
          keyboardType: const TextInputType.numberWithOptions(decimal: true),
          placeholder: '0.00',
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
          prefix: Padding(
            padding: const EdgeInsets.only(left: 8),
            child: Icon(icon, color: CupertinoColors.systemGrey, size: 16),
          ),
          suffix:
              suffix != null
                  ? Padding(
                    padding: const EdgeInsets.only(right: 8),
                    child: Text(
                      suffix,
                      style: const TextStyle(
                        color: CupertinoColors.systemGrey,
                        fontSize: 16,
                      ),
                    ),
                  )
                  : null,
          decoration: BoxDecoration(
            color: CupertinoColors.systemGrey6,
            borderRadius: BorderRadius.circular(8),
            border: Border.all(color: CupertinoColors.systemGrey5, width: 0.5),
          ),
          onChanged: (value) {
            // Re-render to update the calculated remaining amount
            setState(() {});
          },
        ),
        if (validator != null)
          ValueListenableBuilder<TextEditingValue>(
            valueListenable: controller,
            builder: (context, value, _) {
              final error = validator(value.text);
              return error != null
                  ? Padding(
                    padding: const EdgeInsets.only(top: 4, left: 4),
                    child: Text(
                      error,
                      style: const TextStyle(
                        color: CupertinoColors.systemRed,
                        fontSize: 12,
                      ),
                    ),
                  )
                  : const SizedBox.shrink();
            },
          ),
      ],
    );
  }

  Widget _buildCustomerInfoSection() {
    return _buildSection(
      title: 'Informations client',
      icon: CupertinoIcons.person_fill,
      children: [
        // Prénom
        _buildTextField(
          controller: _firstnameController,
          label: 'Prénom',
          icon: CupertinoIcons.person_fill,
          validator: (value) {
            if (value == null || value.isEmpty) {
              return 'Veuillez entrer un prénom';
            }
            return null;
          },
        ),
        const SizedBox(height: 12),

        // Nom (optional, no validator)
        _buildTextField(
          controller: _lastnameController,
          label: 'Nom (optionnel)',
          icon: CupertinoIcons.person_2_fill,
        ),
        const SizedBox(height: 12),

        // Email
        _buildTextField(
          controller: _emailController,
          label: 'Email',
          icon: CupertinoIcons.mail_solid,
          keyboardType: TextInputType.emailAddress,
        ),
        const SizedBox(height: 12),

        // Téléphone
        _buildTextField(
          controller: _phoneController,
          label: 'Téléphone',
          icon: CupertinoIcons.phone_fill,
          keyboardType: TextInputType.phone,
        ),
      ],
    );
  }

  Widget _buildTimeSection() {
    // Formatage de la date et de l'heure pour l'affichage
    final dateFormatter = DateFormat('EEEE d MMMM yyyy', 'fr_FR');
    final timeFormatter = DateFormat('HH:mm');

    return _buildSection(
      title: 'Date et heure',
      icon: CupertinoIcons.calendar,
      children: [
        // Date
        GestureDetector(
          onTap: () => _selectDate(context),
          child: _buildInfoRow(
            icon: CupertinoIcons.calendar,
            label: 'Date',
            value: dateFormatter.format(_selectedDate),
            showChevron: true,
          ),
        ),
        const SizedBox(height: 12),

        // Heure
        GestureDetector(
          onTap: () => _selectTime(context),
          child: _buildInfoRow(
            icon: CupertinoIcons.clock,
            label: 'Heure',
            value: timeFormatter.format(
              DateTime(
                _selectedDate.year,
                _selectedDate.month,
                _selectedDate.day,
                _selectedTime.hour,
                _selectedTime.minute,
              ),
            ),
            showChevron: true,
          ),
        ),
      ],
    );
  }

  Widget _buildActivityInfoSection() {
    return _buildSection(
      title: 'Détails de l\'activité',
      icon: CupertinoIcons.game_controller_solid,
      children: [
        // Activity selection
        GestureDetector(
          onTap: () => _showActivityPicker(),
          child: _buildInfoRow(
            icon: CupertinoIcons.tag_fill,
            label: 'Activité',
            value:
                _loadingActivities
                    ? 'Chargement...'
                    : _getSelectedActivityName(),
            showChevron: true,
          ),
        ),
        const SizedBox(height: 12),

        // Type de pricing
        _buildInfoRow(
          icon: CupertinoIcons.money_euro_circle,
          label: 'Type',
          value:
              _loadingActivities ? 'Chargement...' : _getSelectedPricingType(),
          showChevron: false,
        ),
        const SizedBox(height: 12),

        // Nombre de personnes
        _buildCustomCounterRow(
          icon: CupertinoIcons.person_2_fill,
          label: 'Nombre de personnes',
          value: _numberOfPeople,
          onIncrement: () {
            if (_numberOfPeople < _getMaxPlayers()) {
              setState(() {
                _numberOfPeople++;
                _hasChanges = true;
              });
            }
          },
          onDecrement: () {
            if (_numberOfPeople > _getMinPlayers()) {
              setState(() {
                _numberOfPeople--;
                _hasChanges = true;
              });
            }
          },
          minValue: _getMinPlayers(),
          maxValue: _getMaxPlayers(),
        ),
        const SizedBox(height: 12),

        // Nombre de parties
        _buildCustomCounterRow(
          icon: CupertinoIcons.gamecontroller_fill,
          label: 'Nombre de parties',
          value: _numberOfGames,
          onIncrement: () {
            setState(() {
              _numberOfGames++;
              _hasChanges = true;
            });
          },
          onDecrement: () {
            if (_numberOfGames > 1) {
              setState(() {
                _numberOfGames--;
                _hasChanges = true;
              });
            }
          },
          minValue: 1,
          maxValue: 10,
        ),
        const SizedBox(height: 12),

        // Durée
        _buildInfoRow(
          icon: CupertinoIcons.clock_fill,
          label: 'Durée',
          value:
              _loadingActivities
                  ? 'Chargement...'
                  : '${_getActivityDuration()} minutes',
          showChevron: false,
        ),
      ],
    );
  }

  // Helper methods for activity info
  String _getSelectedActivityName() {
    if (_selectedActivityId == null || _availableActivities.isEmpty) {
      return widget.bookingDetails.activity.name;
    }

    for (var activity in _availableActivities) {
      if (activity['pricing_id'] == _selectedActivityId) {
        return activity['activity_name'] ?? 'Activité non trouvée';
      }
    }

    return widget.bookingDetails.activity.name;
  }

  String _getSelectedPricingType() {
    if (_selectedActivityId == null || _availableActivities.isEmpty) {
      return widget.bookingDetails.pricing.type;
    }

    for (var activity in _availableActivities) {
      if (activity['pricing_id'] == _selectedActivityId) {
        return activity['type'] ?? 'Type non trouvé';
      }
    }

    return widget.bookingDetails.pricing.type;
  }

  int _getMinPlayers() {
    if (_selectedActivityId == null || _availableActivities.isEmpty) {
      return widget.bookingDetails.pricing.minPlayer;
    }

    for (var activity in _availableActivities) {
      if (activity['pricing_id'] == _selectedActivityId) {
        return activity['min_player'] ??
            widget.bookingDetails.pricing.minPlayer;
      }
    }

    return widget.bookingDetails.pricing.minPlayer;
  }

  int _getMaxPlayers() {
    if (_selectedActivityId == null || _availableActivities.isEmpty) {
      return widget.bookingDetails.pricing.maxPlayer;
    }

    for (var activity in _availableActivities) {
      if (activity['pricing_id'] == _selectedActivityId) {
        return activity['max_player'] ??
            widget.bookingDetails.pricing.maxPlayer;
      }
    }

    return widget.bookingDetails.pricing.maxPlayer;
  }

  int _getActivityDuration() {
    if (_selectedActivityId == null || _availableActivities.isEmpty) {
      return widget.bookingDetails.pricing.duration;
    }

    for (var activity in _availableActivities) {
      if (activity['pricing_id'] == _selectedActivityId) {
        return activity['duration'] ?? widget.bookingDetails.pricing.duration;
      }
    }

    return widget.bookingDetails.pricing.duration;
  }

  void _showActivityPicker() {
    if (_loadingActivities) {
      _showCupertinoToast('Chargement des activités...', isError: false);
      return;
    }

    if (_availableActivities.isEmpty) {
      _showCupertinoToast('Aucune activité disponible', isError: true);
      return;
    }

    showCupertinoModalPopup<void>(
      context: context,
      builder: (BuildContext context) {
        // Find the initially selected activity index
        int initialIndex = 0;
        for (int i = 0; i < _availableActivities.length; i++) {
          if (_availableActivities[i]['pricing_id'] == _selectedActivityId) {
            initialIndex = i;
            break;
          }
        }

        return Container(
          height: 300,
          padding: const EdgeInsets.only(top: 6.0),
          margin: EdgeInsets.only(
            bottom: MediaQuery.of(context).viewInsets.bottom,
          ),
          color: CupertinoColors.systemBackground,
          child: Column(
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  CupertinoButton(
                    child: const Text('Annuler'),
                    onPressed: () => Navigator.pop(context),
                  ),
                  CupertinoButton(
                    child: const Text('Confirmer'),
                    onPressed: () {
                      if (_availableActivities.isNotEmpty) {
                        setState(() {
                          _selectedActivityId =
                              _availableActivities[initialIndex]['pricing_id'];
                          _hasChanges = true;

                          // Update number of people if necessary
                          int minPlayers = _getMinPlayers();
                          int maxPlayers = _getMaxPlayers();

                          if (_numberOfPeople < minPlayers) {
                            _numberOfPeople = minPlayers;
                          } else if (_numberOfPeople > maxPlayers) {
                            _numberOfPeople = maxPlayers;
                          }
                        });
                      }
                      Navigator.pop(context);
                    },
                  ),
                ],
              ),
              Expanded(
                child: CupertinoPicker(
                  scrollController: FixedExtentScrollController(
                    initialItem: initialIndex,
                  ),
                  itemExtent: 40,
                  onSelectedItemChanged: (int index) {
                    initialIndex = index;
                  },
                  children:
                      _availableActivities
                          .map(
                            (activity) => Center(
                              child: Text(
                                '${activity['name'] ?? 'Erreur'} (${activity['type'] ?? 'erreur'})',
                                style: const TextStyle(fontSize: 16),
                              ),
                            ),
                          )
                          .toList(),
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildNotesSection() {
    return _buildSection(
      title: 'Notes',
      icon: CupertinoIcons.text_bubble,
      children: [
        CupertinoTextField(
          controller: _notesController,
          placeholder: 'Notes supplémentaires (optionnel)',
          maxLines: 4,
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: CupertinoColors.systemGrey6,
            borderRadius: BorderRadius.circular(8),
            border: Border.all(color: CupertinoColors.systemGrey5, width: 0.5),
          ),
        ),
      ],
    );
  }

  Widget _buildSection({
    required String title,
    required IconData icon,
    required List<Widget> children,
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
              ],
            ),
            const Padding(
              padding: EdgeInsets.symmetric(vertical: 12.0),
              child: Divider(height: 1),
            ),
            ...children,
          ],
        ),
      ),
    );
  }

  Widget _buildTextField({
    required TextEditingController controller,
    required String label,
    required IconData icon,
    TextInputType keyboardType = TextInputType.text,
    String? Function(String?)? validator,
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
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
          prefix: Padding(
            padding: const EdgeInsets.only(left: 8),
            child: Icon(icon, color: CupertinoColors.systemGrey, size: 16),
          ),
          decoration: BoxDecoration(
            color: CupertinoColors.systemGrey6,
            borderRadius: BorderRadius.circular(8),
            border: Border.all(color: CupertinoColors.systemGrey5, width: 0.5),
          ),
        ),
        if (validator != null)
          ValueListenableBuilder<TextEditingValue>(
            valueListenable: controller,
            builder: (context, value, _) {
              final error = validator(value.text);
              return error != null
                  ? Padding(
                    padding: const EdgeInsets.only(top: 4, left: 4),
                    child: Text(
                      error,
                      style: const TextStyle(
                        color: CupertinoColors.systemRed,
                        fontSize: 12,
                      ),
                    ),
                  )
                  : const SizedBox.shrink();
            },
          ),
      ],
    );
  }

  Widget _buildInfoRow({
    required IconData icon,
    required String label,
    required String value,
    required bool showChevron,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 10),
      decoration: BoxDecoration(
        color: CupertinoColors.systemGrey6,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: CupertinoColors.systemGrey4, width: 0.5),
      ),
      child: Row(
        children: [
          Icon(icon, color: CupertinoTheme.of(context).primaryColor, size: 18),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  style: const TextStyle(
                    fontSize: 13,
                    color: CupertinoColors.systemGrey,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  value,
                  style: const TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ],
            ),
          ),
          if (showChevron)
            const Icon(
              CupertinoIcons.chevron_right,
              color: CupertinoColors.systemGrey3,
              size: 18,
            ),
        ],
      ),
    );
  }

  Widget _buildCustomCounterRow({
    required IconData icon,
    required String label,
    required int value,
    required VoidCallback onIncrement,
    required VoidCallback onDecrement,
    required int minValue,
    required int maxValue,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 10),
      decoration: BoxDecoration(
        color: CupertinoColors.systemGrey6,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: CupertinoColors.systemGrey4, width: 0.5),
      ),
      child: Row(
        children: [
          Icon(icon, color: CupertinoTheme.of(context).primaryColor, size: 18),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  style: const TextStyle(
                    fontSize: 13,
                    color: CupertinoColors.systemGrey,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  '$value',
                  style: const TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ],
            ),
          ),
          Row(
            children: [
              CupertinoButton(
                padding: EdgeInsets.zero,
                onPressed: value > minValue ? onDecrement : null,
                child: Container(
                  padding: const EdgeInsets.all(6),
                  decoration: BoxDecoration(
                    color:
                        value > minValue
                            ? CupertinoTheme.of(context).primaryColor
                            : CupertinoColors.systemGrey4,
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(
                    CupertinoIcons.minus,
                    color: CupertinoColors.white,
                    size: 14,
                  ),
                ),
              ),
              const SizedBox(width: 8),
              Text(
                '$value',
                style: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                ),
              ),
              const SizedBox(width: 8),
              CupertinoButton(
                padding: EdgeInsets.zero,
                onPressed: value < maxValue ? onIncrement : null,
                child: Container(
                  padding: const EdgeInsets.all(6),
                  decoration: BoxDecoration(
                    color:
                        value < maxValue
                            ? CupertinoTheme.of(context).primaryColor
                            : CupertinoColors.systemGrey4,
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(
                    CupertinoIcons.plus,
                    color: CupertinoColors.white,
                    size: 14,
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
