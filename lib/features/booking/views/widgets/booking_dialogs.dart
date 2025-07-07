import 'package:flutter/material.dart';
import '../../../../shared/widgets/custom_dialog.dart';
import '../widgets/booking_form_widget.dart';

class AddBookingDialog extends StatelessWidget {
  const AddBookingDialog({super.key});

  @override
  Widget build(BuildContext context) {
    return CustomDialog(
      title: 'Nouvelle réservation',
      titleIcon: Icon(Icons.add_circle_outline),
      content: BookingFormWidget(
        onSubmit: () => Navigator.of(context).pop(),
      ),
    );
  }

  static void show(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => const AddBookingDialog(),
    );
  }
}