import 'package:flutter/material.dart';
import 'package:flutter/cupertino.dart';
import 'package:intl/intl.dart';
import '../main.dart'; // Pour le client supabase
import '../utils/app_strings.dart';

class BookingDetailsScreen extends StatefulWidget {
  final String bookingId;

  const BookingDetailsScreen({Key? key, required this.bookingId})
    : super(key: key);

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
      // Récupération des détails de la réservation depuis Supabase
      final response =
          await supabase
              .from('bookings')
              .select()
              .eq('id', widget.bookingId)
              .single();

      setState(() {
        _booking = BookingModel.fromJson(response);
        _isLoading = false;
      });
    } catch (e) {
      print('Erreur lors de la récupération des détails: $e');
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

      // Actualiser les détails de la réservation
      await _fetchBookingDetails();

      if (!context.mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('${AppStrings.statusUpdated} $status'),
          backgroundColor: Colors.green,
        ),
      );
    } catch (e) {
      if (!context.mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('${AppStrings.errorOccurred}: $e'),
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
      await supabase.from('bookings').delete().eq('id', widget.bookingId);

      if (!context.mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(AppStrings.bookingDeleted),
          backgroundColor: Colors.green,
        ),
      );

      if (!context.mounted) return;
      Navigator.pop(
        context,
        true,
      ); // Retourne true pour indiquer la suppression
    } catch (e) {
      if (!context.mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('${AppStrings.deleteError} $e'),
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
      builder:
          (context) => CupertinoAlertDialog(
            title: Text(AppStrings.delete),
            content: Text(AppStrings.deleteConfirmation),
            actions: [
              CupertinoDialogAction(
                child: Text(AppStrings.cancel),
                onPressed: () => Navigator.pop(context),
              ),
              CupertinoDialogAction(
                isDestructiveAction: true,
                onPressed: () {
                  Navigator.pop(context);
                  _deleteBooking();
                },
                child: Text(AppStrings.delete),
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
      builder:
          (BuildContext context) => CupertinoActionSheet(
            title: Text(AppStrings.updateStatus),
            message: Text(AppStrings.chooseNewStatus),
            actions: <CupertinoActionSheetAction>[
              CupertinoActionSheetAction(
                onPressed: () {
                  Navigator.pop(context);
                  _updateBookingStatus('confirmed');
                },
                child: Text(AppStrings.confirmed),
              ),
              CupertinoActionSheetAction(
                onPressed: () {
                  Navigator.pop(context);
                  _updateBookingStatus('completed');
                },
                child: Text(AppStrings.completed),
              ),
              CupertinoActionSheetAction(
                onPressed: () {
                  Navigator.pop(context);
                  _updateBookingStatus('cancelled');
                },
                isDestructiveAction: true,
                child: Text(AppStrings.cancelled),
              ),
            ],
            cancelButton: CupertinoActionSheetAction(
              child: Text(AppStrings.close),
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
    return CupertinoPageScaffold(
      backgroundColor: CupertinoColors.systemGroupedBackground,
      navigationBar: CupertinoNavigationBar(
        middle: Text(AppStrings.bookingDetails),
        backgroundColor: CupertinoColors.systemGroupedBackground,
        border: null,
      ),
      child:
          _isLoading
              ? const Center(child: CupertinoActivityIndicator())
              : _booking == null
              ? Center(child: Text(AppStrings.errorOccurred))
              : SafeArea(
                child: CustomScrollView(
                  physics: const AlwaysScrollableScrollPhysics(
                    parent: BouncingScrollPhysics(),
                  ),
                  slivers: [
                    SliverToBoxAdapter(
                      child: Padding(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 16.0,
                          vertical: 8.0,
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            _buildStatusCard(),
                            const SizedBox(height: 16),
                            _buildBookingDetailsCard(),
                            const SizedBox(height: 16),
                            _buildActionsCard(),
                            const SizedBox(height: 30),
                          ],
                        ),
                      ),
                    ),
                  ],
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

    String statusText = '';
    switch (_booking!.status.toLowerCase()) {
      case 'confirmed':
        statusText = AppStrings.confirmed;
        break;
      case 'cancelled':
        statusText = AppStrings.cancelled;
        break;
      case 'completed':
        statusText = AppStrings.completed;
        break;
      default:
        statusText = AppStrings.pending;
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
                Icon(statusIcon, color: statusColor, size: 24),
                const SizedBox(width: 8),
                Text(
                  '${AppStrings.status} ${statusText.toUpperCase()}',
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
                  AppStrings.date,
                  DateFormat('d MMM yyyy', 'fr_FR').format(_booking!.date),
                ),
                _buildInfoItem(
                  CupertinoIcons.clock,
                  AppStrings.time,
                  DateFormat('HH:mm').format(_booking!.date),
                ),
                _buildInfoItem(
                  CupertinoIcons.money_euro,
                  AppStrings.price,
                  '€0.00', // Prix supprimé du modèle, affichage d'une valeur par défaut
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
        Text(title, style: TextStyle(fontSize: 12, color: Colors.grey[600])),
        const SizedBox(height: 4),
        Text(
          value,
          style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
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
            Text(
              AppStrings.customerInfo,
              style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 16),
            _buildDetailItem(AppStrings.firstName, _booking!.firstName),
            const SizedBox(height: 16),
            _buildDetailItem(AppStrings.lastName, _booking!.lastName),
            const SizedBox(height: 16),
            const Divider(height: 1),
            const SizedBox(height: 16),
            Text(
              AppStrings.serviceInfo,
              style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 16),
            _buildDetailItem(AppStrings.service, _booking!.service),
            const SizedBox(height: 16),
            _buildDetailItem(
              AppStrings.duration,
              '${_getDurationFromService(_booking!.service)} ${AppStrings.minutes}',
            ),
            const SizedBox(height: 16),
            _buildDetailItem(
              AppStrings.price,
              '€0.00', // Remplacé la référence à price qui n'existe plus
            ),
          ],
        ),
      ),
    );
  }

  // Fonction simple pour estimer la durée en fonction du nom du service
  int _getDurationFromService(String service) {
    if (service.contains('Petite')) return 30;
    if (service.contains('Moyenne')) return 45;
    if (service.contains('Grande')) return 60;
    return 45; // Durée par défaut
  }

  Widget _buildDetailItem(String label, String value) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SizedBox(
          width: 130,
          child: Text(
            label,
            style: TextStyle(fontSize: 16, color: Colors.grey[600]),
          ),
        ),
        Expanded(
          child: Text(
            value,
            style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w500),
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
            Text(
              AppStrings.actions,
              style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                Expanded(
                  child: CupertinoButton(
                    padding: EdgeInsets.zero,
                    onPressed: () {
                      // Navigation vers l'écran d'édition
                    },
                    child: Container(
                      alignment: Alignment.center,
                      padding: const EdgeInsets.symmetric(vertical: 14),
                      decoration: BoxDecoration(
                        color: Theme.of(context).primaryColor,
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Text(
                        AppStrings.edit,
                        style: const TextStyle(
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
                      child: Text(
                        AppStrings.delete,
                        style: const TextStyle(
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
