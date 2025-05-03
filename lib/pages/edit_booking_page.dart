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

  // Form key for validation
  final _formKey = GlobalKey<FormState>();

  // Controllers for editing text fields
  late TextEditingController _firstnameController;
  late TextEditingController _lastnameController;
  late TextEditingController _emailController;
  late TextEditingController _phoneController;
  late TextEditingController _notesController;

  // Activity-related fields
  late DateTime _selectedDate;
  late TimeOfDay _selectedTime;
  late int _numberOfPeople;
  late int _numberOfGames;

  @override
  void initState() {
    super.initState();

    // Initialize controllers with current values
    _firstnameController = TextEditingController(
      text: widget.bookingDetails.booking.firstname,
    );
    _lastnameController = TextEditingController(
      text: widget.bookingDetails.booking.lastname,
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

    // Initialize other fields
    _selectedDate = widget.bookingDetails.booking.date;
    _selectedTime = TimeOfDay(
      hour: widget.bookingDetails.booking.date.hour,
      minute: widget.bookingDetails.booking.date.minute,
    );
    _numberOfPeople = widget.bookingDetails.booking.nbrPers;
    _numberOfGames = widget.bookingDetails.booking.nbrParties;

    // Add listeners to detect changes
    _addChangeListeners();
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

      // Update the booking record in the database
      await supabase
          .from('bookings')
          .update({
            'firstname': _firstnameController.text,
            'lastname': _lastnameController.text,
            'email': _emailController.text,
            'phone_number': _phoneController.text,
            'notes': _notesController.text,
            'date': dateTime.toIso8601String(),
            'nbr_pers': _numberOfPeople,
            'nbr_parties': _numberOfGames,
          })
          .eq('id', widget.bookingDetails.booking.bookingId);

      setState(() {
        _isLoading = false;
        _hasChanges = false;
      });

      if (!context.mounted) return;

      // Show success message and navigate back
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Réservation mise à jour avec succès'),
          backgroundColor: Colors.green,
        ),
      );

      Navigator.pop(context, true); // Return true to indicate success
    } catch (e) {
      print('Error updating booking: $e');
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

  Future<void> _selectDate(BuildContext context) async {
    final DateTime? picked = await showCupertinoModalPopup<DateTime>(
      context: context,
      builder: (BuildContext context) {
        DateTime selectedDate = _selectedDate;

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
                  initialDateTime: _selectedDate,
                  minimumDate: DateTime.now(),
                  maximumDate: DateTime.now().add(const Duration(days: 365)),
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
    final TimeOfDay? picked = await showCupertinoModalPopup<TimeOfDay>(
      context: context,
      builder: (BuildContext context) {
        DateTime selectedDateTime = DateTime(
          _selectedDate.year,
          _selectedDate.month,
          _selectedDate.day,
          _selectedTime.hour,
          _selectedTime.minute,
        );

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
          backgroundColor: CupertinoColors.systemBackground,
          border: null,
          trailing: CupertinoButton(
            padding: EdgeInsets.zero,
            onPressed: _isLoading ? null : _saveBooking,
            child:
                _isLoading
                    ? const CupertinoActivityIndicator()
                    : const Text('Enregistrer'),
          ),
        ),
        child: SafeArea(
          child:
              _isLoading
                  ? const Center(child: CupertinoActivityIndicator())
                  : _buildForm(),
        ),
      ),
    );
  }

  Widget _buildForm() {
    return Form(
      key: _formKey,
      child: ListView(
        padding: const EdgeInsets.all(16.0),
        children: [
          _buildCustomerInfoSection(),
          const SizedBox(height: 20),
          _buildTimeSection(),
          const SizedBox(height: 20),
          _buildActivityInfoSection(),
          const SizedBox(height: 20),
          _buildNotesSection(),
        ],
      ),
    );
  }

  Widget _buildCustomerInfoSection() {
    return Card(
      elevation: 0,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      color: CupertinoTheme.of(context).barBackgroundColor,
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Informations client',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 16),

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

            // Nom
            _buildTextField(
              controller: _lastnameController,
              label: 'Nom',
              icon: CupertinoIcons.person_fill,
              validator: (value) {
                if (value == null || value.isEmpty) {
                  return 'Veuillez entrer un nom';
                }
                return null;
              },
            ),
            const SizedBox(height: 12),

            // Email
            _buildTextField(
              controller: _emailController,
              label: 'Email',
              icon: CupertinoIcons.mail_solid,
              keyboardType: TextInputType.emailAddress,
              validator: (value) {
                if (value == null || value.isEmpty) {
                  return 'Veuillez entrer une adresse email';
                }
                if (!RegExp(
                  r'^[\w-\.]+@([\w-]+\.)+[\w-]{2,4}$',
                ).hasMatch(value)) {
                  return 'Veuillez entrer une adresse email valide';
                }
                return null;
              },
            ),
            const SizedBox(height: 12),

            // Téléphone
            _buildTextField(
              controller: _phoneController,
              label: 'Téléphone',
              icon: CupertinoIcons.phone_fill,
              keyboardType: TextInputType.phone,
              validator: (value) {
                if (value == null || value.isEmpty) {
                  return 'Veuillez entrer un numéro de téléphone';
                }
                return null;
              },
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTimeSection() {
    // Formatage de la date et de l'heure pour l'affichage
    final dateFormatter = DateFormat('dd/MM/yyyy');
    final timeFormatter = DateFormat('HH:mm');

    return Card(
      elevation: 0,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      color: CupertinoTheme.of(context).barBackgroundColor,
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Date et heure',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 16),

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
        ),
      ),
    );
  }

  Widget _buildActivityInfoSection() {
    return Card(
      elevation: 0,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      color: CupertinoTheme.of(context).barBackgroundColor,
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Détails de l\'activité',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 16),

            // Type d'activité (non modifiable)
            _buildInfoRow(
              icon: CupertinoIcons.tag_fill,
              label: 'Activité',
              value: widget.bookingDetails.activity.name,
              showChevron: false,
            ),
            const SizedBox(height: 12),

            // Type de pricing (non modifiable)
            _buildInfoRow(
              icon: CupertinoIcons.money_dollar_circle_fill,
              label: 'Type',
              value: widget.bookingDetails.pricing.type,
              showChevron: false,
            ),
            const SizedBox(height: 12),

            // Nombre de personnes
            _buildCustomCounterRow(
              icon: CupertinoIcons.person_2_fill,
              label: 'Nombre de personnes',
              value: _numberOfPeople,
              onIncrement: () {
                if (_numberOfPeople < widget.bookingDetails.pricing.maxPlayer) {
                  setState(() {
                    _numberOfPeople++;
                    _hasChanges = true;
                  });
                }
              },
              onDecrement: () {
                if (_numberOfPeople > widget.bookingDetails.pricing.minPlayer) {
                  setState(() {
                    _numberOfPeople--;
                    _hasChanges = true;
                  });
                }
              },
              minValue: widget.bookingDetails.pricing.minPlayer,
              maxValue: widget.bookingDetails.pricing.maxPlayer,
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

            // Durée (non modifiable)
            _buildInfoRow(
              icon: CupertinoIcons.clock_fill,
              label: 'Durée',
              value: '${widget.bookingDetails.pricing.duration} minutes',
              showChevron: false,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildNotesSection() {
    return Card(
      elevation: 0,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      color: CupertinoTheme.of(context).barBackgroundColor,
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Notes',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 16),
            CupertinoTextField(
              controller: _notesController,
              placeholder: 'Notes supplémentaires (optionnel)',
              maxLines: 4,
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: CupertinoColors.systemGrey6,
                borderRadius: BorderRadius.circular(8),
              ),
            ),
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
              const SizedBox(height: 4),
              CupertinoTextField(
                controller: controller,
                keyboardType: keyboardType,
                placeholder: label,
                padding: const EdgeInsets.symmetric(
                  horizontal: 12,
                  vertical: 12,
                ),
                decoration: BoxDecoration(
                  color: CupertinoColors.systemGrey6,
                  borderRadius: BorderRadius.circular(8),
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
          ),
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
    return Row(
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
        if (showChevron)
          const Icon(
            CupertinoIcons.chevron_right,
            color: CupertinoColors.systemGrey3,
            size: 18,
          ),
      ],
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
    return Row(
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
                '$value',
                style: const TextStyle(
                  fontSize: 16,
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
    );
  }
}
