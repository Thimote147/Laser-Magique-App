import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../models/booking_model.dart';
import '../../viewmodels/activity_formula_view_model.dart';
import '../../viewmodels/booking_edit_viewmodel.dart';
import '../../viewmodels/booking_view_model.dart';
import '../widgets/booking_form_widget.dart';

class BookingEditScreen extends StatelessWidget {
  final Booking? booking;

  const BookingEditScreen({super.key, this.booking});

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider(
      create:
          (context) => BookingEditViewModel(
            booking: booking,
            onSave: (updatedBooking) {
              final bookingViewModel = context.read<BookingViewModel>();
              if (booking != null) {
                bookingViewModel.updateBooking(updatedBooking);
              } else {
                bookingViewModel.addBooking(
                  firstName: updatedBooking.firstName,
                  lastName: updatedBooking.lastName,
                  dateTime: updatedBooking.dateTime,
                  numberOfPersons: updatedBooking.numberOfPersons,
                  numberOfGames: updatedBooking.numberOfGames,
                  email: updatedBooking.email,
                  phone: updatedBooking.phone,
                  formula: updatedBooking.formula,
                  deposit: updatedBooking.deposit,
                  paymentMethod: updatedBooking.paymentMethod,
                );
              }
              Navigator.of(context).pop();

              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text(
                    updatedBooking.deposit > 0
                        ? 'Réservation créée avec un acompte de ${updatedBooking.deposit.toStringAsFixed(2)}€'
                        : 'Réservation créée avec succès',
                  ),
                ),
              );
            },
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
