import 'package:flutter/material.dart';
import 'package:flutter/cupertino.dart';
import 'package:intl/intl.dart';
import '../main.dart'; // For supabase client

class NewBookingScreen extends StatefulWidget {
  const NewBookingScreen({Key? key}) : super(key: key);

  @override
  NewBookingScreenState createState() => NewBookingScreenState();
}

class NewBookingScreenState extends State<NewBookingScreen> {
  final _formKey = GlobalKey<FormState>();

  // Form fields
  String _customerName = '';
  String _service = '';
  DateTime _selectedDate = DateTime.now();
  TimeOfDay _selectedTime = TimeOfDay.now();
  double _price = 0.0;

  // Available services
  final List<Map<String, dynamic>> _services = [
    {'name': 'Laser Hair Removal - Small Area', 'price': 50.0},
    {'name': 'Laser Hair Removal - Medium Area', 'price': 80.0},
    {'name': 'Laser Hair Removal - Large Area', 'price': 120.0},
    {'name': 'Skin Rejuvenation', 'price': 150.0},
    {'name': 'Pigmentation Treatment', 'price': 130.0},
  ];

  bool _isLoading = false;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('New Booking'), centerTitle: true),
      body:
          _isLoading
              ? const Center(child: CupertinoActivityIndicator())
              : SingleChildScrollView(
                child: Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Form(
                    key: _formKey,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        _buildInfoCard(),
                        const SizedBox(height: 20),
                        _buildCustomerNameField(),
                        const SizedBox(height: 20),
                        _buildServiceSelector(),
                        const SizedBox(height: 20),
                        _buildDateTimeSelectors(),
                        const SizedBox(height: 20),
                        _buildPriceField(),
                        const SizedBox(height: 30),
                        _buildSubmitButton(),
                      ],
                    ),
                  ),
                ),
              ),
    );
  }

  Widget _buildInfoCard() {
    return Card(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
      elevation: 0.5,
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Theme.of(context).primaryColor.withOpacity(0.1),
                shape: BoxShape.circle,
              ),
              child: Icon(
                CupertinoIcons.calendar_badge_plus,
                color: Theme.of(context).primaryColor,
                size: 28,
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Create New Booking',
                    style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    'Fill out the form below to create a new appointment',
                    style: TextStyle(color: Colors.grey[600]),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildCustomerNameField() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Customer Name',
          style: TextStyle(fontWeight: FontWeight.w600, fontSize: 16),
        ),
        const SizedBox(height: 8),
        CupertinoTextField(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          placeholder: 'Enter customer name',
          decoration: BoxDecoration(
            color: CupertinoColors.systemGrey6,
            borderRadius: BorderRadius.circular(8),
          ),
          onChanged: (value) {
            setState(() {
              _customerName = value;
            });
          },
        ),
      ],
    );
  }

  Widget _buildServiceSelector() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Service',
          style: TextStyle(fontWeight: FontWeight.w600, fontSize: 16),
        ),
        const SizedBox(height: 8),
        Card(
          margin: EdgeInsets.zero,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
          elevation: 0,
          color: CupertinoColors.systemGrey6,
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 12),
            child: DropdownButtonHideUnderline(
              child: DropdownButton<String>(
                isExpanded: true,
                hint: const Text('Select a service'),
                value: _service.isEmpty ? null : _service,
                icon: const Icon(CupertinoIcons.chevron_down),
                elevation: 0,
                style: const TextStyle(color: CupertinoColors.black),
                onChanged: (String? value) {
                  if (value != null) {
                    setState(() {
                      _service = value;
                      // Auto-fill price based on selected service
                      for (var service in _services) {
                        if (service['name'] == value) {
                          _price = service['price'];
                          break;
                        }
                      }
                    });
                  }
                },
                items:
                    _services
                        .map(
                          (service) => DropdownMenuItem<String>(
                            value: service['name'],
                            child: Text(service['name']),
                          ),
                        )
                        .toList(),
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildDateTimeSelectors() {
    return Row(
      children: [
        // Date Selector
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'Date',
                style: TextStyle(fontWeight: FontWeight.w600, fontSize: 16),
              ),
              const SizedBox(height: 8),
              GestureDetector(
                onTap: () => _showDatePicker(),
                child: Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 12,
                  ),
                  decoration: BoxDecoration(
                    color: CupertinoColors.systemGrey6,
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        DateFormat('MMM d, yyyy').format(_selectedDate),
                        style: const TextStyle(fontSize: 16),
                      ),
                      const Icon(
                        CupertinoIcons.calendar,
                        color: CupertinoColors.systemGrey,
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
        const SizedBox(width: 16),
        // Time Selector
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'Time',
                style: TextStyle(fontWeight: FontWeight.w600, fontSize: 16),
              ),
              const SizedBox(height: 8),
              GestureDetector(
                onTap: () => _showTimePicker(),
                child: Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 12,
                  ),
                  decoration: BoxDecoration(
                    color: CupertinoColors.systemGrey6,
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        _selectedTime.format(context),
                        style: const TextStyle(fontSize: 16),
                      ),
                      const Icon(
                        CupertinoIcons.clock,
                        color: CupertinoColors.systemGrey,
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Future<void> _showDatePicker() async {
    final DateTime? pickedDate = await showCupertinoModalPopup<DateTime>(
      context: context,
      builder: (BuildContext context) {
        return Container(
          height: 216,
          padding: const EdgeInsets.only(top: 6.0),
          margin: EdgeInsets.only(
            bottom: MediaQuery.of(context).viewInsets.bottom,
          ),
          color: CupertinoColors.systemBackground.resolveFrom(context),
          child: SafeArea(
            top: false,
            child: CupertinoDatePicker(
              initialDateTime: _selectedDate,
              mode: CupertinoDatePickerMode.date,
              use24hFormat: false,
              minimumDate: DateTime.now(),
              maximumDate: DateTime.now().add(const Duration(days: 365)),
              onDateTimeChanged: (DateTime newDateTime) {
                setState(() {
                  _selectedDate = newDateTime;
                });
              },
            ),
          ),
        );
      },
    );

    if (pickedDate != null) {
      setState(() {
        _selectedDate = pickedDate;
      });
    }
  }

  Future<void> _showTimePicker() async {
    await showCupertinoModalPopup<void>(
      context: context,
      builder: (BuildContext context) {
        return Container(
          height: 216,
          padding: const EdgeInsets.only(top: 6.0),
          margin: EdgeInsets.only(
            bottom: MediaQuery.of(context).viewInsets.bottom,
          ),
          color: CupertinoColors.systemBackground.resolveFrom(context),
          child: SafeArea(
            top: false,
            child: CupertinoDatePicker(
              initialDateTime: DateTime(
                _selectedDate.year,
                _selectedDate.month,
                _selectedDate.day,
                _selectedTime.hour,
                _selectedTime.minute,
              ),
              mode: CupertinoDatePickerMode.time,
              use24hFormat: false,
              onDateTimeChanged: (DateTime newDateTime) {
                setState(() {
                  _selectedTime = TimeOfDay(
                    hour: newDateTime.hour,
                    minute: newDateTime.minute,
                  );
                });
              },
            ),
          ),
        );
      },
    );
  }

  Widget _buildPriceField() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Price (€)',
          style: TextStyle(fontWeight: FontWeight.w600, fontSize: 16),
        ),
        const SizedBox(height: 8),
        CupertinoTextField(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          placeholder: '0.00',
          decoration: BoxDecoration(
            color: CupertinoColors.systemGrey6,
            borderRadius: BorderRadius.circular(8),
          ),
          keyboardType: const TextInputType.numberWithOptions(decimal: true),
          controller: TextEditingController(
            text: _price > 0 ? _price.toString() : '',
          ),
          onChanged: (value) {
            setState(() {
              _price = double.tryParse(value) ?? 0.0;
            });
          },
        ),
      ],
    );
  }

  Widget _buildSubmitButton() {
    return SizedBox(
      width: double.infinity,
      child: CupertinoButton(
        color: Theme.of(context).primaryColor,
        borderRadius: BorderRadius.circular(8),
        padding: const EdgeInsets.symmetric(vertical: 14),
        onPressed: _isFormValid() ? _submitForm : null,
        child: const Text(
          'Create Booking',
          style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
        ),
      ),
    );
  }

  bool _isFormValid() {
    return _customerName.isNotEmpty && _service.isNotEmpty && _price > 0;
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
      // Insert booking into Supabase
      final response =
          await supabase.from('bookings').insert({
            'customer_name': _customerName,
            'service': _service,
            'date': bookingDateTime.toIso8601String(),
            'price': _price,
            'status': 'confirmed',
          }).select();

      if (response != null) {
        if (!context.mounted) return;

        // Show success message
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Booking created successfully!'),
            backgroundColor: Colors.green,
          ),
        );

        // Navigate back
        if (!context.mounted) return;
        Navigator.pop(context, true); // Return true to indicate success
      }
    } catch (e) {
      if (!context.mounted) return;

      // Show error message
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error creating booking: $e'),
          backgroundColor: Colors.red,
        ),
      );
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }
}
