import 'package:flutter/material.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:intl/intl.dart';
import '../main.dart';
import '../models/activity.dart';

class NewBookingScreen extends StatefulWidget {
  final DateTime? initialDate;

  const NewBookingScreen({super.key, this.initialDate});

  @override
  NewBookingScreenState createState() => NewBookingScreenState();
}

class NewBookingScreenState extends State<NewBookingScreen> {
  final _formKey = GlobalKey<FormState>();

  // Form fields
  final TextEditingController _firstNameController = TextEditingController();
  final TextEditingController _lastNameController = TextEditingController();
  final TextEditingController _phoneController = TextEditingController();
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _depositController = TextEditingController();
  final TextEditingController _totalController = TextEditingController();
  final TextEditingController _commentController = TextEditingController();

  DateTime _selectedDate = DateTime.now();
  TimeOfDay _selectedTime = TimeOfDay.now();

  // These will be updated after activity selection
  int _numberOfPersons = 1; // Default value will be replaced with minPlayer
  int _numberOfParties = 1;

  String? _selectedActivityId;
  double _deposit = 0.0;
  double _total = 0.0;

  // Available activities
  List<Activity> _activities = [];

  bool _isLoading = false;
  bool _isLoadingActivities = true;

  // Scroll controller to manage the form scroll behavior
  final ScrollController _scrollController = ScrollController();

  @override
  void initState() {
    super.initState();

    // Set selected date from initialDate if provided
    if (widget.initialDate != null) {
      _selectedDate = widget.initialDate!;
    }

    _fetchActivities();

    // Set default deposit value to 0
    _depositController.text = "0.00";

    // Default total to 0.00 to ensure the text field isn't empty
    _totalController.text = "0.00";

    // Listen for changes to update total
    _depositController.addListener(_updateTotalFromDeposit);

    // Add listener for firstName to trigger UI refresh for button state
    _firstNameController.addListener(() {
      setState(() {
        // This empty setState will trigger UI rebuild to update button state
      });
    });

    // Add a post-frame callback to update the price after the first build
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_selectedActivityId != null) {
        // Make sure the price gets calculated and updated immediately
        _updateTotalPrice();
      }
    });
  }

  @override
  void dispose() {
    _firstNameController.dispose();
    _lastNameController.dispose();
    _phoneController.dispose();
    _emailController.dispose();
    _depositController.dispose();
    _totalController.dispose();
    _commentController.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  void _updateTotalFromDeposit() {
    if (_depositController.text.isNotEmpty) {
      try {
        final depositValue = double.parse(_depositController.text);
        setState(() {
          _deposit = depositValue;
        });
      } catch (e) {
        // Invalid number format
      }
    }
  }

  Future<void> _fetchActivities() async {
    setState(() {
      _isLoadingActivities = true;
    });

    try {
      // Using the get_activities RPC function
      final response = await supabase.rpc('get_activities');

      final activities =
          (response as List)
              .map((activity) => Activity.fromJson(activity))
              .toList();

      setState(() {
        _activities = activities;
        _isLoadingActivities = false;

        // Select the first activity by default if available
        if (activities.isNotEmpty && _selectedActivityId == null) {
          _selectedActivityId = activities.first.id;

          // Set number of persons to minimum player count
          final activity = activities.first;
          _numberOfPersons = activity.minPlayer > 0 ? activity.minPlayer : 1;

          // Set appropriate number of parties based on activity type
          _setPartiesForActivity(activity);

          _updateTotalPrice();
        }
      });
    } catch (e) {
      debugPrint('Error fetching activities: $e');
      setState(() {
        _isLoadingActivities = false;
        // Provide some default options in case of error
        _activities = [
          Activity(
            id: 'a58f16b4-3f80-4c4b-83e9-741d43ccea4c',
            name: 'Standard Game',
            type: 'standard',
            firstPrice: 200.00,
            secondPrice: 250.00,
            thirdPrice: 300.00,
            minPlayer: 2,
            maxPlayer: 10,
            duration: 60,
          ),
        ];

        if (_selectedActivityId == null && _activities.isNotEmpty) {
          _selectedActivityId = _activities.first.id;

          // Set number of persons to minimum player count
          final activity = _activities.first;
          _numberOfPersons = activity.minPlayer > 0 ? activity.minPlayer : 1;

          // Set appropriate number of parties based on activity type
          _setPartiesForActivity(activity);

          _updateTotalPrice();
        }
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final backgroundColor = themeService.getBackgroundColor();

    return CupertinoPageScaffold(
      backgroundColor: backgroundColor,
      navigationBar: CupertinoNavigationBar(
        middle: Text(
          'Nouvelle réservation',
          style: TextStyle(color: themeService.getTextColor()),
        ),
        backgroundColor: backgroundColor,
        previousPageTitle: 'Retour',
        trailing: CupertinoButton(
          padding: EdgeInsets.zero,
          onPressed: _isFormValid() ? _submitForm : null,
          child:
              _isLoading
                  ? const CupertinoActivityIndicator()
                  : Text(
                    'Créer',
                    style: TextStyle(
                      color:
                          _isFormValid()
                              ? CupertinoTheme.of(context).primaryColor
                              : CupertinoColors.systemGrey4,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
        ),
      ),
      child:
          _isLoadingActivities
              ? const Center(child: CupertinoActivityIndicator())
              : SafeArea(
                bottom: true,
                child: Form(
                  key: _formKey,
                  child: CustomScrollView(
                    controller: _scrollController,
                    physics: const AlwaysScrollableScrollPhysics(),
                    slivers: [
                      SliverToBoxAdapter(
                        child: Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 16.0),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const SizedBox(height: 16),
                              // Client information section
                              _buildCompactSection(
                                title: 'Client',
                                icon: CupertinoIcons.person_fill,
                                child: _buildClientInformation(),
                              ),

                              const SizedBox(height: 16),

                              // Activity section
                              _buildCompactSection(
                                title: 'Activité',
                                icon: CupertinoIcons.game_controller_solid,
                                child: _buildActivityInformation(),
                              ),

                              const SizedBox(height: 16),

                              // Date and time section
                              _buildCompactSection(
                                title: 'Date et heure',
                                icon: CupertinoIcons.calendar,
                                child: _buildDateTimeInformation(),
                              ),

                              const SizedBox(height: 16),

                              // Payment section
                              _buildCompactSection(
                                title: 'Paiement',
                                icon: CupertinoIcons.money_euro_circle,
                                child: _buildPaymentInformation(),
                              ),

                              const SizedBox(height: 16),

                              // Comment section
                              _buildCompactSection(
                                title: 'Commentaire',
                                icon: CupertinoIcons.text_bubble,
                                child: _buildCommentField(),
                              ),

                              const SizedBox(height: 24),
                            ],
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
    );
  }

  // Helper method to build the compact section with title and content
  Widget _buildCompactSection({
    required String title,
    required IconData icon,
    required Widget child,
  }) {
    final cardColor = themeService.getCardColor();
    final separatorColor = themeService.getSeparatorColor();

    return Card(
      color: cardColor,
      elevation: 0,
      margin: EdgeInsets.zero,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: BorderSide(color: separatorColor, width: 0.5),
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
                    ).primaryColor.withAlpha((0.1 * 255).round()),
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
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                    color: themeService.getTextColor(),
                  ),
                ),
              ],
            ),
            Divider(height: 24, color: separatorColor),
            child,
          ],
        ),
      ),
    );
  }

  // Client information section
  Widget _buildClientInformation() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            // First Name
            Expanded(
              child: _buildTextFieldWithLabel(
                label: 'Prénom*',
                controller: _firstNameController,
                placeholder: 'Prénom',
                keyboardType: TextInputType.name,
              ),
            ),
            const SizedBox(width: 12),
            // Last Name
            Expanded(
              child: _buildTextFieldWithLabel(
                label: 'Nom',
                controller: _lastNameController,
                placeholder: 'Nom',
                keyboardType: TextInputType.name,
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),
        Row(
          children: [
            // Phone
            Expanded(
              child: _buildTextFieldWithLabel(
                label: 'Téléphone',
                controller: _phoneController,
                placeholder: 'Téléphone',
                keyboardType: TextInputType.phone,
                icon: CupertinoIcons.phone,
              ),
            ),
            const SizedBox(width: 12),
            // Email
            Expanded(
              child: _buildTextFieldWithLabel(
                label: 'Email',
                controller: _emailController,
                placeholder: 'Email',
                keyboardType: TextInputType.emailAddress,
                icon: CupertinoIcons.mail,
              ),
            ),
          ],
        ),
      ],
    );
  }

  // Activity information section
  Widget _buildActivityInformation() {
    final textColor = themeService.getTextColor();
    final backgroundColor =
        themeService.darkMode
            ? CupertinoColors.systemGrey6.darkColor
            : CupertinoColors.systemGrey6;
    final separatorColor = themeService.getSeparatorColor();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Activity selection
        _buildLabelWithText(
          label: 'Sélectionnez une activité*',
          child: GestureDetector(
            onTap: () => _showActivityPicker(),
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
              decoration: BoxDecoration(
                color: backgroundColor,
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: separatorColor, width: 0.5),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Expanded(
                    child: Text(
                      _getSelectedActivityName(),
                      style: TextStyle(fontSize: 15, color: textColor),
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                  Icon(
                    CupertinoIcons.chevron_down,
                    color: CupertinoColors.systemGrey,
                    size: 14,
                  ),
                ],
              ),
            ),
          ),
        ),
        if (_selectedActivityId != null) ...[
          const SizedBox(height: 4),
          Padding(
            padding: const EdgeInsets.only(left: 4.0),
            child: Text(
              _getActivityDetails(),
              style: const TextStyle(
                fontSize: 12,
                color: CupertinoColors.systemGrey,
              ),
            ),
          ),
        ],
        const SizedBox(height: 12),

        // Number of people and parties
        Row(
          children: [
            // Number of people
            Expanded(
              child: _buildLabelWithText(
                label: 'Nombre de personnes*',
                child: _buildNumberStepper(
                  value: _numberOfPersons,
                  onChanged: (value) {
                    setState(() {
                      _numberOfPersons = value;

                      // Check if we need to update the number of parties based on the change in persons
                      _adjustNumberOfPartiesForActivity();

                      _updateTotalPrice();
                    });
                  },
                  min: _getMinPlayers(),
                  max: _getMaxPlayers(),
                ),
              ),
            ),
            const SizedBox(width: 12),
            // Number of parties
            Expanded(
              child: _buildLabelWithText(
                label: 'Nombre de parties*',
                child: _buildNumberStepper(
                  value: _numberOfParties,
                  onChanged: (value) {
                    setState(() {
                      _numberOfParties = value;
                      _updateTotalPrice();
                    });
                  },
                  min: _getMinParties(),
                  max: _getMaxParties(),
                ),
              ),
            ),
          ],
        ),
      ],
    );
  }

  // Date and time information section
  Widget _buildDateTimeInformation() {
    final frenchDateFormat = DateFormat('dd MMMM yyyy', 'fr_FR');
    final textColor = themeService.getTextColor();
    final backgroundColor =
        themeService.darkMode
            ? CupertinoColors.systemGrey6.darkColor
            : CupertinoColors.systemGrey6;
    final separatorColor = themeService.getSeparatorColor();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            // Date selector
            Expanded(
              child: _buildLabelWithText(
                label: 'Date*',
                child: GestureDetector(
                  onTap: () => _showDatePicker(context),
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 12,
                      vertical: 10,
                    ),
                    decoration: BoxDecoration(
                      color: backgroundColor,
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(color: separatorColor, width: 0.5),
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          frenchDateFormat.format(_selectedDate),
                          style: TextStyle(fontSize: 15, color: textColor),
                          overflow: TextOverflow.ellipsis,
                        ),
                        Icon(
                          CupertinoIcons.calendar,
                          color: CupertinoTheme.of(context).primaryColor,
                          size: 16,
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
            const SizedBox(width: 12),
            // Time selector
            Expanded(
              child: _buildLabelWithText(
                label: 'Heure*',
                child: GestureDetector(
                  onTap: () => _showTimePicker(context),
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 12,
                      vertical: 10,
                    ),
                    decoration: BoxDecoration(
                      color: backgroundColor,
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(color: separatorColor, width: 0.5),
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          '${_selectedTime.hour.toString().padLeft(2, '0')}:${_selectedTime.minute.toString().padLeft(2, '0')}',
                          style: TextStyle(fontSize: 15, color: textColor),
                        ),
                        Icon(
                          CupertinoIcons.clock,
                          color: CupertinoTheme.of(context).primaryColor,
                          size: 16,
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),

        // Show estimated end time when activity is selected
        if (_selectedActivityId != null) ...[
          const SizedBox(height: 12),
          Row(
            children: [
              Icon(
                CupertinoIcons.clock_fill,
                color: CupertinoColors.systemGrey,
                size: 14,
              ),
              const SizedBox(width: 6),
              Text(
                'Fin estimée: ${_calculateEstimatedEndTime()}',
                style: TextStyle(
                  fontSize: 13,
                  color: CupertinoColors.systemGrey,
                ),
              ),
            ],
          ),
        ],
      ],
    );
  }

  // Payment information section
  Widget _buildPaymentInformation() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Pricing information when activity is selected
        if (_selectedActivityId != null) ...[
          // Price information
          Row(
            children: [
              Expanded(
                child: _buildInfoItem(
                  label: 'Prix unitaire',
                  value: _getUnitPrice().toStringAsFixed(2),
                  icon: CupertinoIcons.money_euro,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _buildInfoItem(
                  label: 'Prix total',
                  value: _getTotalPrice().toStringAsFixed(2),
                  icon: CupertinoIcons.money_euro_circle,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
        ],

        // Deposit and total fields (inverted)
        Row(
          children: [
            // Deposit amount (now first)
            Expanded(
              child: _buildTextFieldWithLabel(
                label: 'Acompte versé',
                controller: _depositController,
                placeholder: '0.00',
                keyboardType: const TextInputType.numberWithOptions(
                  decimal: true,
                ),
                suffix: '€',
                onChanged: (value) {
                  try {
                    setState(() {
                      _deposit = double.tryParse(value) ?? 0.0;
                    });
                  } catch (_) {}
                },
              ),
            ),
            const SizedBox(width: 12),
            // Total amount (now second)
            Expanded(
              child: _buildTextFieldWithLabel(
                label: 'Montant total*',
                controller: _totalController,
                placeholder: '0.00',
                keyboardType: const TextInputType.numberWithOptions(
                  decimal: true,
                ),
                suffix: '€',
                onChanged: (value) {
                  try {
                    setState(() {
                      _total = double.tryParse(value) ?? 0.0;
                    });
                  } catch (_) {}
                },
              ),
            ),
          ],
        ),
      ],
    );
  }

  // Comment field
  Widget _buildCommentField() {
    return _buildTextFieldWithLabel(
      label: 'Commentaire (optionnel)',
      controller: _commentController,
      placeholder: 'Ajouter un commentaire...',
      keyboardType: TextInputType.multiline,
      isMultiline: true,
    );
  }

  // Helper method to build an info item
  Widget _buildInfoItem({
    required String label,
    required String value,
    required IconData icon,
  }) {
    final textColor = themeService.getTextColor();
    final backgroundColor =
        themeService.darkMode
            ? CupertinoColors.systemGrey6.darkColor
            : CupertinoColors.systemGrey6;
    final separatorColor = themeService.getSeparatorColor();

    return Container(
      padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 10),
      decoration: BoxDecoration(
        color: backgroundColor,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: separatorColor, width: 0.5),
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
                color: CupertinoTheme.of(context).primaryColor,
                size: 16,
              ),
              const SizedBox(width: 6),
              Text(
                value,
                style: TextStyle(
                  fontSize: 15,
                  fontWeight: FontWeight.w500,
                  color: textColor,
                ),
              ),
              Text(
                " €",
                style: TextStyle(
                  fontSize: 15,
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

  // Helper method to build a text field with label
  Widget _buildTextFieldWithLabel({
    required String label,
    required TextEditingController controller,
    required String placeholder,
    TextInputType? keyboardType,
    IconData? icon,
    String? prefix,
    String? suffix,
    bool isMultiline = false,
    Function(String)? onChanged,
  }) {
    final textColor = themeService.getTextColor();

    return _buildLabelWithText(
      label: label,
      child: CupertinoTextField(
        controller: controller,
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
        placeholder: placeholder,
        placeholderStyle: TextStyle(color: CupertinoColors.systemGrey),
        style: TextStyle(color: textColor),
        prefix:
            prefix != null
                ? Padding(
                  padding: const EdgeInsets.only(left: 8),
                  child: Text(
                    prefix,
                    style: TextStyle(
                      color: textColor,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                )
                : icon != null
                ? Padding(
                  padding: const EdgeInsets.only(left: 8),
                  child: Icon(
                    icon,
                    color: CupertinoColors.systemGrey,
                    size: 16,
                  ),
                )
                : null,
        suffix:
            suffix != null
                ? Padding(
                  padding: const EdgeInsets.only(right: 8),
                  child: Text(
                    suffix,
                    style: TextStyle(
                      color: textColor,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                )
                : null,
        keyboardType: keyboardType,
        decoration: BoxDecoration(
          color:
              themeService.darkMode
                  ? CupertinoColors.systemGrey6.darkColor
                  : CupertinoColors.systemGrey6,
          borderRadius: BorderRadius.circular(8),
          border: Border.all(
            color: themeService.getSeparatorColor(),
            width: 0.5,
          ),
        ),
        maxLines: isMultiline ? 3 : 1,
        minLines: isMultiline ? 3 : 1,
        onChanged: onChanged,
      ),
    );
  }

  // Helper method to build a label with a widget
  Widget _buildLabelWithText({required String label, required Widget child}) {
    final secondaryTextColor = themeService.getSecondaryTextColor();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.only(left: 4, bottom: 4),
          child: Text(
            label,
            style: TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.w500,
              color: secondaryTextColor,
            ),
          ),
        ),
        child,
      ],
    );
  }

  // Helper method to build a number stepper
  Widget _buildNumberStepper({
    required int value,
    required Function(int) onChanged,
    int min = 1,
    int max = 20,
  }) {
    final textColor = themeService.getTextColor();
    final backgroundColor =
        themeService.darkMode
            ? CupertinoColors.systemGrey6.darkColor
            : CupertinoColors.systemGrey6;
    final separatorColor = themeService.getSeparatorColor();

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: backgroundColor,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: separatorColor, width: 0.5),
      ),
      child: Row(
        children: [
          CupertinoButton(
            padding: EdgeInsets.zero,
            onPressed: value > min ? () => onChanged(value - 1) : null,
            child: Container(
              padding: const EdgeInsets.all(4),
              decoration: BoxDecoration(
                color:
                    value > min
                        ? CupertinoTheme.of(
                          context,
                        ).primaryColor.withAlpha((0.1 * 255).round())
                        : themeService.darkMode
                        ? CupertinoColors.systemGrey5.darkColor
                        : CupertinoColors.systemGrey5,
                shape: BoxShape.circle,
              ),
              child: Icon(
                CupertinoIcons.minus,
                color:
                    value > min
                        ? CupertinoTheme.of(context).primaryColor
                        : CupertinoColors.systemGrey3,
                size: 14,
              ),
            ),
          ),
          Expanded(
            child: Center(
              child: Text(
                value.toString(),
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w500,
                  color: textColor,
                ),
              ),
            ),
          ),
          CupertinoButton(
            padding: EdgeInsets.zero,
            onPressed: value < max ? () => onChanged(value + 1) : null,
            child: Container(
              padding: const EdgeInsets.all(4),
              decoration: BoxDecoration(
                color:
                    value < max
                        ? CupertinoTheme.of(
                          context,
                        ).primaryColor.withAlpha((0.1 * 255).round())
                        : themeService.darkMode
                        ? CupertinoColors.systemGrey5.darkColor
                        : CupertinoColors.systemGrey5,
                shape: BoxShape.circle,
              ),
              child: Icon(
                CupertinoIcons.plus,
                color:
                    value < max
                        ? CupertinoTheme.of(context).primaryColor
                        : CupertinoColors.systemGrey3,
                size: 14,
              ),
            ),
          ),
        ],
      ),
    );
  }

  // Calculate the estimated end time based on activity duration and number of parties
  String _calculateEstimatedEndTime() {
    final activity = _getSelectedActivity();
    if (activity == null) return '--:--';

    final totalDurationMinutes = activity.duration * _numberOfParties;
    final endTime = DateTime(
      _selectedDate.year,
      _selectedDate.month,
      _selectedDate.day,
      _selectedTime.hour,
      _selectedTime.minute,
    ).add(Duration(minutes: totalDurationMinutes));

    return '${endTime.hour.toString().padLeft(2, '0')}:${endTime.minute.toString().padLeft(2, '0')}';
  }

  // Get the unit price for the current activity and number of people
  double _getUnitPrice() {
    final activity = _getSelectedActivity();
    if (activity == null) return 0.0;

    if (_numberOfParties == 1 && activity.firstPrice > 0) {
      return activity.firstPrice;
    } else if (_numberOfParties == 2 && activity.secondPrice > 0) {
      return activity.secondPrice;
    } else if (_numberOfParties == 3 && activity.thirdPrice > 0) {
      return activity.thirdPrice;
    } else if (_numberOfParties > 3) {
      // For more than 3 parties, use thirdPrice as base and add additional parties

      // Base price is thirdPrice for the first 3 parties
      double basePrice = activity.thirdPrice;

      // For additional parties, calculate based on available prices
      double additionalPartyPrice = 0.0;

      // Use the first available price for additional parties, prioritizing firstPrice
      if (activity.firstPrice > 0) {
        additionalPartyPrice = activity.firstPrice;
      } else if (activity.secondPrice > 0) {
        additionalPartyPrice =
            activity.secondPrice /
            2; // Divide by 2 since secondPrice is for 2 parties
      } else if (activity.thirdPrice > 0) {
        additionalPartyPrice =
            activity.thirdPrice /
            3; // Divide by 3 since thirdPrice is for 3 parties
      }

      // Calculate the total price per person
      return basePrice + (additionalPartyPrice * (_numberOfParties - 3));
    } else {
      return 0.0;
    }
  }

  // Get the selected activity object
  Activity? _getSelectedActivity() {
    if (_selectedActivityId == null) return null;

    return _activities.firstWhere(
      (a) => a.id == _selectedActivityId,
      orElse:
          () => Activity(
            id: '',
            name: '',
            type: '',
            firstPrice: 0,
            secondPrice: 0,
            thirdPrice: 0,
            minPlayer: 0,
            maxPlayer: 0,
            duration: 0,
          ),
    );
  }

  // Get minimum allowed players for the selected activity
  int _getMinPlayers() {
    final activity = _getSelectedActivity();
    if (activity == null) return 1;

    return activity.minPlayer > 0 ? activity.minPlayer : 1;
  }

  // Get maximum allowed players for the selected activity
  int _getMaxPlayers() {
    final activity = _getSelectedActivity();
    if (activity == null) return 20;

    return activity.maxPlayer > 0 ? activity.maxPlayer : 20;
  }

  // Get minimum allowed parties for the current activity
  int _getMinParties() {
    final activity = _getSelectedActivity();
    if (activity == null) return 1;

    // If firstPrice is available, minimum is 1 party
    if (activity.firstPrice > 0) {
      return 1;
    }
    // If secondPrice is available but not firstPrice, minimum is 2 parties
    else if (activity.secondPrice > 0) {
      return 2;
    }
    // If only thirdPrice is available, minimum is 3 parties
    else if (activity.thirdPrice > 0) {
      return 3;
    }

    return 1; // Default fallback
  }

  int _getMaxParties() {
    final activity = _getSelectedActivity();

    if (activity == null) return 1;

    if (activity.type.toLowerCase() == 'social deal' ||
        activity.type.toLowerCase() == 'anniversaire') {
      return 3;
    }

    return 5;
  }

  // Existing methods
  String _getSelectedActivityName() {
    if (_selectedActivityId == null || _activities.isEmpty) {
      return 'Sélectionnez une activité';
    }

    final activity = _activities.firstWhere(
      (a) => a.id == _selectedActivityId,
      orElse:
          () => Activity(
            id: '',
            name: 'Activité non trouvée',
            type: '',
            firstPrice: 0,
            secondPrice: 0,
            thirdPrice: 0,
            minPlayer: 0,
            maxPlayer: 0,
            duration: 0,
          ),
    );

    return '${activity.name} (${activity.type})';
  }

  String _getActivityDetails() {
    if (_selectedActivityId == null) return '';

    final activity = _activities.firstWhere(
      (a) => a.id == _selectedActivityId,
      orElse:
          () => Activity(
            id: '',
            name: '',
            type: '',
            firstPrice: 0,
            secondPrice: 0,
            thirdPrice: 0,
            minPlayer: 0,
            maxPlayer: 0,
            duration: 0,
          ),
    );

    // Get the first available price and corresponding number of parties
    String priceText;
    int durationMultiplier = 1; // Default multiplier for duration (1 party)

    if (activity.firstPrice > 0) {
      priceText = '${activity.firstPrice.toStringAsFixed(2)}€';
      durationMultiplier = 1; // firstPrice is for 1 party
    } else if (activity.secondPrice > 0) {
      priceText = '${activity.secondPrice.toStringAsFixed(2)}€';
      durationMultiplier = 2; // secondPrice is for 2 parties
    } else if (activity.thirdPrice > 0) {
      priceText = '${activity.thirdPrice.toStringAsFixed(2)}€';
      durationMultiplier = 3; // thirdPrice is for 3 parties
    } else {
      priceText = '0.00€';
      durationMultiplier = 1;
    }

    // Calculate total duration based on the price's corresponding parties
    int totalDurationMinutes = activity.duration * durationMultiplier;

    // Format duration to display in hours if more than 59 minutes
    String durationText;
    if (totalDurationMinutes >= 60) {
      int hours = totalDurationMinutes ~/ 60;
      int minutes = totalDurationMinutes % 60;

      if (minutes == 0) {
        // If it's a full hour with no minutes
        durationText = '${hours}h';
      } else {
        // If it has both hours and minutes
        durationText = '${hours}h ${minutes}min';
      }
    } else {
      durationText = '$totalDurationMinutes min';
    }

    return '${activity.minPlayer}-${activity.maxPlayer} pers. - $durationText - $priceText';
  }

  // Activity picker modal
  void _showActivityPicker() {
    final backgroundColor = themeService.getCardColor();
    final textColor = themeService.getTextColor();
    final separatorColor = themeService.getSeparatorColor();

    int selectedIndex = 0;
    if (_selectedActivityId != null) {
      final index = _activities.indexWhere((a) => a.id == _selectedActivityId);
      if (index >= 0) {
        selectedIndex = index;
      }
    }

    showCupertinoModalPopup<void>(
      context: context,
      builder: (BuildContext context) {
        return Container(
          height: 300,
          padding: const EdgeInsets.only(top: 6.0),
          margin: EdgeInsets.only(
            bottom: MediaQuery.of(context).viewInsets.bottom,
          ),
          color: backgroundColor,
          child: Column(
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  CupertinoButton(
                    child: Text(
                      'Annuler',
                      style: TextStyle(
                        color: CupertinoTheme.of(context).primaryColor,
                      ),
                    ),
                    onPressed: () => Navigator.pop(context),
                  ),
                  CupertinoButton(
                    child: Text(
                      'Confirmer',
                      style: TextStyle(
                        color: CupertinoTheme.of(context).primaryColor,
                      ),
                    ),
                    onPressed: () {
                      if (_activities.isNotEmpty) {
                        final newActivity = _activities[selectedIndex];
                        final bool activityChanged =
                            _selectedActivityId != newActivity.id;

                        setState(() {
                          _selectedActivityId = newActivity.id;

                          if (activityChanged) {
                            // Always set _numberOfPersons to exactly match minPlayer when activity changes
                            _numberOfPersons =
                                newActivity.minPlayer > 0
                                    ? newActivity.minPlayer
                                    : 1;

                            // Reset and set appropriate number of parties for this activity type
                            _setPartiesForActivity(newActivity);
                          }

                          _updateTotalPrice();
                        });
                      }
                      Navigator.pop(context);
                    },
                  ),
                ],
              ),
              Divider(height: 0, color: separatorColor),
              Expanded(
                child: Theme(
                  data: Theme.of(context).copyWith(
                    textTheme: Theme.of(context).textTheme.copyWith(
                      bodyMedium: TextStyle(color: textColor),
                    ),
                  ),
                  child: CupertinoPicker(
                    scrollController: FixedExtentScrollController(
                      initialItem: selectedIndex,
                    ),
                    itemExtent: 40,
                    onSelectedItemChanged: (int index) {
                      selectedIndex = index;
                    },
                    children:
                        _activities
                            .map(
                              (activity) => Center(
                                child: Text(
                                  '${activity.name} (${activity.type})',
                                  style: TextStyle(color: textColor),
                                ),
                              ),
                            )
                            .toList(),
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  void _updateTotalPrice() {
    if (_selectedActivityId != null) {
      // Find selected activity
      final selectedActivity = _activities.firstWhere(
        (activity) => activity.id == _selectedActivityId,
        orElse:
            () => Activity(
              id: '',
              name: '',
              type: '',
              firstPrice: 0,
              secondPrice: 0,
              thirdPrice: 0,
              minPlayer: 0,
              maxPlayer: 0,
              duration: 0,
            ),
      );

      setState(() {
        // Update number of persons to the minimum player count of the activity
        if (_numberOfPersons < selectedActivity.minPlayer) {
          _numberOfPersons =
              selectedActivity.minPlayer > 0 ? selectedActivity.minPlayer : 1;
        }

        // If firstPrice and secondPrice are null/zero, enforce minimum 3 parties
        // This is typical for "anniversaire" activities where only thirdPrice is used
        if (selectedActivity.firstPrice <= 0 &&
            selectedActivity.secondPrice <= 0 &&
            selectedActivity.thirdPrice > 0) {
          if (_numberOfParties < 3) {
            _numberOfParties = 3;
          }
        }

        // Use _getTotalPrice to calculate properly for all activity types
        final calculatedTotal = _getTotalPrice();

        // Update total value and controller
        _total = calculatedTotal;
        _totalController.text = _total.toStringAsFixed(2);

        // Automatically set deposit equal to total ONLY for Social Deal activities
        if (selectedActivity.type.toLowerCase() == 'social deal') {
          _deposit = calculatedTotal;
          _depositController.text = calculatedTotal.toStringAsFixed(2);
        }
      });
    }
  }

  // Helper method to adjust number of parties based on activity requirements
  void _adjustNumberOfPartiesForActivity() {
    if (_selectedActivityId != null) {
      final activity = _getSelectedActivity();
      if (activity != null) {
        // Check if this activity has special pricing requirements (first and second price null)
        if (activity.firstPrice <= 0 &&
            activity.secondPrice <= 0 &&
            activity.thirdPrice > 0) {
          // For activities like "anniversaire" where only thirdPrice is used
          if (_numberOfParties < 3) {
            setState(() {
              _numberOfParties = 3;
            });
          }
        }
      }
    }
  }

  // Helper method to set the appropriate number of parties based on activity type
  void _setPartiesForActivity(Activity activity) {
    final bool isSocialDeal = activity.type.toLowerCase() == 'social deal';

    // First check the available price tiers and determine the minimum parties
    if (activity.firstPrice > 0) {
      // If firstPrice is available, set to 1 party
      _numberOfParties = 1;
    } else if (activity.firstPrice <= 0 && activity.secondPrice > 0) {
      // If only secondPrice is available (no firstPrice), set to 2 parties
      _numberOfParties = 2;
    } else if (activity.firstPrice <= 0 &&
        activity.secondPrice <= 0 &&
        activity.thirdPrice > 0) {
      // If only thirdPrice is available (no firstPrice, no secondPrice), set to 3 parties
      _numberOfParties = 3;
    } else {
      // Fallback case if no pricing is defined (shouldn't happen, but just in case)
      _numberOfParties = 1;
    }

    // Special handling for Social Deal activities - always set deposit equal to total
    if (isSocialDeal) {
      // For Social Deal activities, first calculate the total, then set deposit equal to it
      Future.microtask(() {
        // Calculate total first
        final calculatedTotal = _getTotalPrice();
        setState(() {
          _total = calculatedTotal;
          _totalController.text = calculatedTotal.toStringAsFixed(2);
          // Set deposit equal to total for Social Deal activities
          _deposit = calculatedTotal;
          _depositController.text = calculatedTotal.toStringAsFixed(2);
        });
      });
    } else if (!isSocialDeal) {
      setState(() {
        _deposit = 0.0;
        _depositController.text = "0.00";
      });
    }
  }

  void _showDatePicker(BuildContext context) {
    final backgroundColor = themeService.getCardColor();
    final textColor = themeService.getTextColor();
    final separatorColor = themeService.getSeparatorColor();

    // Use a custom widget to display month names in French
    showCupertinoModalPopup<void>(
      context: context,
      builder:
          (BuildContext context) => Container(
            height: 280,
            padding: const EdgeInsets.only(top: 6.0),
            margin: EdgeInsets.only(
              bottom: MediaQuery.of(context).viewInsets.bottom,
            ),
            color: backgroundColor,
            child: Column(
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    CupertinoButton(
                      child: Text(
                        'Annuler',
                        style: TextStyle(
                          color: CupertinoTheme.of(context).primaryColor,
                        ),
                      ),
                      onPressed: () => Navigator.pop(context),
                    ),
                    CupertinoButton(
                      child: Text(
                        'Confirmer',
                        style: TextStyle(
                          color: CupertinoTheme.of(context).primaryColor,
                        ),
                      ),
                      onPressed: () => Navigator.pop(context),
                    ),
                  ],
                ),
                Divider(height: 0, color: separatorColor),
                Expanded(
                  child: Localizations.override(
                    context: context,
                    locale: const Locale('fr', 'FR'),
                    delegates: const [
                      DefaultCupertinoLocalizations.delegate,
                      DefaultMaterialLocalizations.delegate,
                      DefaultWidgetsLocalizations.delegate,
                      GlobalCupertinoLocalizations.delegate,
                      GlobalMaterialLocalizations.delegate,
                      GlobalWidgetsLocalizations.delegate,
                    ],
                    child: Builder(
                      builder: (BuildContext context) {
                        return Theme(
                          data: Theme.of(context).copyWith(
                            textTheme: Theme.of(context).textTheme.copyWith(
                              bodyMedium: TextStyle(color: textColor),
                            ),
                          ),
                          child: CupertinoDatePicker(
                            initialDateTime: _selectedDate,
                            mode: CupertinoDatePickerMode.date,
                            dateOrder: DatePickerDateOrder.dmy,
                            use24hFormat: true,
                            onDateTimeChanged: (DateTime newDateTime) {
                              setState(() {
                                _selectedDate = DateTime(
                                  newDateTime.year,
                                  newDateTime.month,
                                  newDateTime.day,
                                  _selectedTime.hour,
                                  _selectedTime.minute,
                                );
                              });
                            },
                          ),
                        );
                      },
                    ),
                  ),
                ),
              ],
            ),
          ),
    );
  }

  void _showTimePicker(BuildContext context) {
    final backgroundColor = themeService.getCardColor();
    final textColor = themeService.getTextColor();
    final separatorColor = themeService.getSeparatorColor();

    // Adjust initial minute to be divisible by minuteInterval (15)
    final minuteInterval = 15;
    final initialMinute =
        (_selectedTime.minute ~/ minuteInterval) * minuteInterval;

    final initialDateTime = DateTime(
      _selectedDate.year,
      _selectedDate.month,
      _selectedDate.day,
      _selectedTime.hour,
      initialMinute, // Use adjusted minute value
    );

    showCupertinoModalPopup<void>(
      context: context,
      builder:
          (BuildContext context) => Container(
            height: 280,
            padding: const EdgeInsets.only(top: 6.0),
            margin: EdgeInsets.only(
              bottom: MediaQuery.of(context).viewInsets.bottom,
            ),
            color: backgroundColor,
            child: Column(
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    CupertinoButton(
                      child: Text(
                        'Annuler',
                        style: TextStyle(
                          color: CupertinoTheme.of(context).primaryColor,
                        ),
                      ),
                      onPressed: () => Navigator.pop(context),
                    ),
                    CupertinoButton(
                      child: Text(
                        'Confirmer',
                        style: TextStyle(
                          color: CupertinoTheme.of(context).primaryColor,
                        ),
                      ),
                      onPressed: () => Navigator.pop(context),
                    ),
                  ],
                ),
                Divider(height: 0, color: separatorColor),
                Expanded(
                  child: Localizations.override(
                    context: context,
                    locale: const Locale('fr', 'FR'),
                    delegates: const [
                      DefaultCupertinoLocalizations.delegate,
                      DefaultMaterialLocalizations.delegate,
                      DefaultWidgetsLocalizations.delegate,
                      GlobalCupertinoLocalizations.delegate,
                      GlobalMaterialLocalizations.delegate,
                      GlobalWidgetsLocalizations.delegate,
                    ],
                    child: Builder(
                      builder: (BuildContext context) {
                        return Theme(
                          data: Theme.of(context).copyWith(
                            textTheme: Theme.of(context).textTheme.copyWith(
                              bodyMedium: TextStyle(color: textColor),
                            ),
                          ),
                          child: CupertinoDatePicker(
                            initialDateTime: initialDateTime,
                            mode: CupertinoDatePickerMode.time,
                            use24hFormat: true,
                            minuteInterval: minuteInterval,
                            onDateTimeChanged: (DateTime newDateTime) {
                              setState(() {
                                _selectedTime = TimeOfDay(
                                  hour: newDateTime.hour,
                                  minute: newDateTime.minute,
                                );
                                _selectedDate = DateTime(
                                  _selectedDate.year,
                                  _selectedDate.month,
                                  _selectedDate.day,
                                  newDateTime.hour,
                                  newDateTime.minute,
                                );
                              });
                            },
                          ),
                        );
                      },
                    ),
                  ),
                ),
              ],
            ),
          ),
    );
  }

  bool _isFormValid() {
    // Check if all required fields are filled
    bool hasFirstName = _firstNameController.text.isNotEmpty;
    bool hasActivity = _selectedActivityId != null;
    bool hasTotal =
        _totalController.text.isNotEmpty &&
        double.tryParse(_totalController.text) != null &&
        double.tryParse(_totalController.text)! > 0;

    // The form is valid if first name, activity, and a valid total are provided
    return hasFirstName && hasActivity && hasTotal;
  }

  Future<void> _submitForm() async {
    if (!_isFormValid()) return;

    setState(() {
      _isLoading = true;
    });

    // Combine date and time
    final bookingDateTime = DateTime(
      _selectedDate.year,
      _selectedDate.month,
      _selectedDate.day,
      _selectedTime.hour,
      _selectedTime.minute,
    );

    try {
      // Call the insert_booking function using Supabase RPC
      await supabase.rpc(
        'insert_booking',
        params: {
          'firstname': _firstNameController.text,
          'lastname': _lastNameController.text,
          'phone': _phoneController.text,
          'email': _emailController.text,
          'deposit': _deposit,
          'date': bookingDateTime.toIso8601String(),
          'nbr_pers': _numberOfPersons,
          'activity_pricing_id': _selectedActivityId,
          'nbr_parties': _numberOfParties,
          'total': _total,
          'comment': _commentController.text,
        },
      );

      // Check if the widget is still in the tree after the async operation
      if (!mounted) return;

      // Return to previous screen with success indicator
      Navigator.pop(context, true);
    } catch (e) {
      debugPrint('Error creating booking: $e');

      // Check if the widget is still in the tree after the async operation
      if (!mounted) return;
    } finally {
      // This is safe even after an async gap as we're just updating our own state
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  // Get total price for the current activity, parties, and people
  double _getTotalPrice() {
    final activity = _getSelectedActivity();
    if (activity == null) return 0.0;

    double pricePerPerson = 0.0;

    // For birthday activities (firstPrice and secondPrice are null/0)
    if (activity.firstPrice <= 0 &&
        activity.secondPrice <= 0 &&
        activity.thirdPrice > 0) {
      // For birthday packages, always use thirdPrice (as it's the only available price)
      // and it represents the package price for 3 parties
      pricePerPerson = activity.thirdPrice;

      // If more than 3 parties, add additional parties at thirdPrice/3 per party
      if (_numberOfParties > 3) {
        double additionalPartiesPrice =
            (activity.thirdPrice / 3) * (_numberOfParties - 3);
        pricePerPerson += additionalPartiesPrice;
      }
    } else {
      // For regular activities with multiple price tiers
      if (_numberOfParties == 1 && activity.firstPrice > 0) {
        // 1 party - use firstPrice
        pricePerPerson = activity.firstPrice;
      } else if (_numberOfParties == 2 && activity.secondPrice > 0) {
        // 2 parties - use secondPrice
        pricePerPerson = activity.secondPrice;
      } else if (_numberOfParties == 3 && activity.thirdPrice > 0) {
        // 3 parties - use thirdPrice
        pricePerPerson = activity.thirdPrice;
      } else if (_numberOfParties > 3) {
        // More than 3 parties
        // Use thirdPrice for first 3 parties
        pricePerPerson = activity.thirdPrice;

        // For additional parties, determine which price to use for each additional party
        double additionalPartyPrice;
        if (activity.firstPrice > 0) {
          additionalPartyPrice = activity.firstPrice;
        } else if (activity.secondPrice > 0) {
          additionalPartyPrice = activity.secondPrice;
        } else {
          additionalPartyPrice =
              activity.thirdPrice / 3; // Fallback to thirdPrice/3
        }

        // Add cost for additional parties
        pricePerPerson += additionalPartyPrice * (_numberOfParties - 3);
      } else {
        // Fallback using the regular pricing from getPriceForParty
        // This handles edge cases like 0 parties or when prices are missing
        pricePerPerson =
            activity.getPriceForParty(_numberOfPersons) * _numberOfParties;
        return pricePerPerson; // Return early since we already multiplied by number of parties
      }
    }

    // Multiply by the number of persons to get the total price
    return pricePerPerson * _numberOfPersons;
  }
}
