import 'package:flutter/material.dart';
import 'package:flutter/cupertino.dart';
import 'package:intl/intl.dart';
import '../main.dart'; // For supabase client

class BookingDetailsScreen extends StatefulWidget {
  final int bookingId;

  const BookingDetailsScreen({
    Key? key,
    required this.bookingId,
  }) : super(key: key);

  @override
  BookingDetailsScreenState createState() => BookingDetailsScreenState();
}

class BookingDetailsScreenState extends State<BookingDetailsScreen> {
  bool _isLoading = true;
  BookingModel? _booking;
  bool _isActionSheetVisible = false;

  @override
  void initState() {
    super.initState();
    _fetchBookingDetails();
  }

  Future<void> _fetchBookingDetails() async {
    setState(() {
      _isLoading = true;
    });

    try {
      // Fetch booking details from Supabase
      final response = await supabase
          .from('bookings')
          .select()
          .eq('id', widget.bookingId)
          .single();

      setState(() {
        _booking = BookingModel.fromJson(response);
        _isLoading = false;
      });
    } catch (e) {
      print('Error fetching booking details: $e');
      setState(() {
        _isLoading = false;
      });
    }
  }

  Future<void> _updateBookingStatus(String status) async {
    setState(() {
      _isLoading = true;
    });

    try {
      await supabase
          .from('bookings')
          .update({'status': status})
          .eq('id', widget.bookingId);

      // Refresh booking details
      await _fetchBookingDetails();

      if (!context.mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Booking status updated to $status'),
          backgroundColor: Colors.green,
        ),
      );
    } catch (e) {
      if (!context.mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Failed to update status: $e'),
          backgroundColor: Colors.red,
        ),
      );
      setState(() {
        _isLoading = false;
      });
    }
  }

  Future<void> _deleteBooking() async {
    setState(() {
      _isLoading = true;
    });

    try {
      await supabase
          .from('bookings')
          .delete()
          .eq('id', widget.bookingId);

      if (!context.mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Booking deleted successfully'),
          backgroundColor: Colors.green,
        ),
      );

      if (!context.mounted) return;
      Navigator.pop(context, true); // Return true to indicate deletion
    } catch (e) {
      if (!context.mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Failed to delete booking: $e'),
          backgroundColor: Colors.red,
        ),
      );
      setState(() {
        _isLoading = false;
      });
    }
  }

  void _showDeleteConfirmation() {
    showCupertinoDialog(
      context: context,
      builder: (context) => CupertinoAlertDialog(
        title: const Text('Delete Booking'),
        content: const Text(
          'Are you sure you want to delete this booking? This action cannot be undone.',
        ),
        actions: [
          CupertinoDialogAction(
            child: const Text('Cancel'),
            onPressed: () => Navigator.pop(context),
          ),
          CupertinoDialogAction(
            isDestructiveAction: true,
            onPressed: () {
              Navigator.pop(context);
              _deleteBooking();
            },
            child: const Text('Delete'),
          ),
        ],
      ),
    );
  }

  void _showStatusActionSheet() {
    setState(() {
      _isActionSheetVisible = true;
    });

    showCupertinoModalPopup<void>(
      context: context,
      builder: (BuildContext context) => CupertinoActionSheet(
        title: const Text('Update Status'),
        message: const Text('Choose a new status for this booking'),
        actions: <CupertinoActionSheetAction>[
          CupertinoActionSheetAction(
            onPressed: () {
              Navigator.pop(context);
              _updateBookingStatus('confirmed');
            },
            child: const Text('Confirmed'),
          ),
          CupertinoActionSheetAction(
            onPressed: () {
              Navigator.pop(context);
              _updateBookingStatus('completed');
            },
            child: const Text('Completed'),
          ),
          CupertinoActionSheetAction(
            onPressed: () {
              Navigator.pop(context);
              _updateBookingStatus('cancelled');
            },
            isDestructiveAction: true,
            child: const Text('Cancelled'),
          ),
        ],
        cancelButton: CupertinoActionSheetAction(
          child: const Text('Close'),
          onPressed: () {
            Navigator.pop(context);
          },
        ),
      ),
    ).then((_) {
      setState(() {
        _isActionSheetVisible = false;
      });
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Booking Details'),
        centerTitle: true,
        actions: [
          if (_booking != null && !_isActionSheetVisible)
            IconButton(
              icon: const Icon(CupertinoIcons.ellipsis_circle),
              onPressed: _showStatusActionSheet,
            ),
        ],
      ),
      body: _isLoading
          ? const Center(child: CupertinoActivityIndicator())
          : _booking == null
              ? const Center(child: Text('Booking not found'))
              : SingleChildScrollView(
                  child: Padding(
                    padding: const EdgeInsets.all(16.0),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        _buildStatusCard(),
                        const SizedBox(height: 24),
                        _buildBookingDetailsCard(),
                        const SizedBox(height: 24),
                        _buildActionsCard(),
                      ],
                    ),
                  ),
                ),
    );
  }

  Widget _buildStatusCard() {
    Color statusColor;
    IconData statusIcon;

    switch (_booking!.status.toLowerCase()) {
      case 'confirmed':
        statusColor = Colors.green;
        statusIcon = CupertinoIcons.check_mark_circled_solid;
        break;
      case 'cancelled':
        statusColor = Colors.red;
        statusIcon = CupertinoIcons.xmark_circle_fill;
        break;
      case 'completed':
        statusColor = Colors.blue;
        statusIcon = CupertinoIcons.checkmark_seal_fill;
        break;
      default:
        statusColor = Colors.orange;
        statusIcon = CupertinoIcons.clock_fill;
    }

    return Card(
      elevation: 0.5,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(
                  statusIcon,
                  color: statusColor,
                  size: 24,
                ),
                const SizedBox(width: 8),
                Text(
                  'Status: ${_booking!.status.toUpperCase()}',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: statusColor,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            const Divider(height: 1),
            const SizedBox(height: 12),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                _buildInfoItem(
                  CupertinoIcons.calendar,
                  'Date',
                  DateFormat('MMM d, yyyy').format(_booking!.date),
                ),
                _buildInfoItem(
                  CupertinoIcons.clock,
                  'Time',
                  DateFormat('h:mm a').format(_booking!.date),
                ),
                _buildInfoItem(
                  CupertinoIcons.money_dollar,
                  'Price',
                  '€${_booking!.price.toStringAsFixed(2)}',
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildInfoItem(IconData icon, String title, String value) {
    return Column(
      children: [
        Icon(icon, size: 28, color: Colors.grey),
        const SizedBox(height: 8),
        Text(
          title,
          style: TextStyle(
            fontSize: 12,
            color: Colors.grey[600],
          ),
        ),
        const SizedBox(height: 4),
        Text(
          value,
          style: const TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.w600,
          ),
        ),
      ],
    );
  }

  Widget _buildBookingDetailsCard() {
    return Card(
      elevation: 0.5,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Customer Information',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 16),
            _buildDetailItem('Customer Name', _booking!.customerName),
            const SizedBox(height: 16),
            const Divider(height: 1),
            const SizedBox(height: 16),
            const Text(
              'Service Information',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 16),
            _buildDetailItem('Service', _booking!.service),
            const SizedBox(height: 16),
            _buildDetailItem(
                'Duration', '${_getDurationFromService(_booking!.service)} minutes'),
            const SizedBox(height: 16),
            _buildDetailItem('Price', '€${_booking!.price.toStringAsFixed(2)}'),
          ],
        ),
      ),
    );
  }

  // Simple function to estimate duration based on service name
  int _getDurationFromService(String service) {
    if (service.contains('Small')) return 30;
    if (service.contains('Medium')) return 45;
    if (service.contains('Large')) return 60;
    return 45; // Default duration
  }

  Widget _buildDetailItem(String label, String value) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SizedBox(
          width: 130,
          child: Text(
            label,
            style: TextStyle(
              fontSize: 16,
              color: Colors.grey[600],
            ),
          ),
        ),
        Expanded(
          child: Text(
            value,
            style: const TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w500,
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildActionsCard() {
    return Card(
      elevation: 0.5,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Actions',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                Expanded(
                  child: CupertinoButton(
                    padding: EdgeInsets.zero,
                    onPressed: () {
                      // Navigate to edit screen
                    },
                    child: Container(
                      alignment: Alignment.center,
                      padding: const EdgeInsets.symmetric(vertical: 14),
                      decoration: BoxDecoration(
                        color: Theme.of(context).primaryColor,
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: const Text(
                        'Edit',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: CupertinoButton(
                    padding: EdgeInsets.zero,
                    onPressed: _showDeleteConfirmation,
                    child: Container(
                      alignment: Alignment.center,
                      padding: const EdgeInsets.symmetric(vertical: 14),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(color: Colors.red),
                      ),
                      child: const Text(
                        'Delete',
                        style: TextStyle(
                          color: Colors.red,
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}