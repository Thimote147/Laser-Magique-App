import 'package:flutter/material.dart';
import '../widgets/booking_form_widget.dart';

class AddBookingDialog extends StatelessWidget {
  const AddBookingDialog({super.key});

  @override
  Widget build(BuildContext context) {
    return Dialog(
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: BookingFormWidget(
          onSubmit: () => Navigator.of(context).pop(),
        ),
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