import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../models/booking_model.dart';
import '../../../../shared/viewmodels/activity_formula_view_model.dart';
import '../../viewmodels/booking_edit_viewmodel.dart';
import '../widgets/booking_form_widget.dart';
import '../functions/booking_functions.dart';

class BookingEditScreen extends StatelessWidget {
  final Booking? booking;

  const BookingEditScreen({super.key, this.booking});

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider(
      create: (context) => BookingEditViewModel(
        booking: booking,
        onSave: BookingFunctions.createBookingUpdateCallback(context, booking),
      ),
      child: Consumer2<BookingEditViewModel, ActivityFormulaViewModel>(
        builder: (context, viewModel, formulaViewModel, child) {
          return Scaffold(
            appBar: AppBar(
              title: Text(
                booking != null
                    ? 'Modifier la réservation'
                    : 'Nouvelle réservation',
              ),
              actions: [
                TextButton.icon(
                  onPressed: () {
                    final error = viewModel.validate();
                    if (error != null) {
                      ScaffoldMessenger.of(
                        context,
                      ).showSnackBar(SnackBar(content: Text(error)));
                      return;
                    }
                    viewModel.save();
                  },
                  icon: const Icon(Icons.check),
                  label: const Text('Ajouter'),
                ),
              ],
            ),
            body: BookingFormWidget(booking: booking),
          );
        },
      ),
    );
  }
}
