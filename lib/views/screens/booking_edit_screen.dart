import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../models/booking_model.dart';
import '../../viewmodels/activity_formula_view_model.dart';
import '../../viewmodels/booking_edit_viewmodel.dart';
import '../../viewmodels/booking_view_model.dart';
import '../widgets/booking_form/contact_fields.dart';
import '../widgets/booking_form/date_time_selectors.dart';
import '../widgets/booking_form/deposit_section.dart';
import '../widgets/booking_form/formula_section.dart';

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
            body: SingleChildScrollView(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  if (booking?.isCancelled ?? false)
                    Container(
                      margin: const EdgeInsets.only(bottom: 16),
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: Colors.red.shade50,
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(color: Colors.red.shade200),
                      ),
                      child: Row(
                        children: [
                          Icon(Icons.cancel, color: Colors.red.shade400),
                          const SizedBox(width: 12),
                          const Expanded(
                            child: Text(
                              'Réservation annulée',
                              style: TextStyle(
                                fontWeight: FontWeight.bold,
                                color: Colors.red,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ContactFields(
                    firstName: viewModel.firstName,
                    lastName: viewModel.lastName,
                    email: viewModel.email,
                    phone: viewModel.phone,
                    onFirstNameChanged: viewModel.setFirstName,
                    onLastNameChanged: viewModel.setLastName,
                    onEmailChanged: viewModel.setEmail,
                    onPhoneChanged: viewModel.setPhone,
                  ),
                  const SizedBox(height: 16),
                  DateTimeSelectors(
                    selectedDate: viewModel.selectedDate,
                    selectedTime: viewModel.selectedTime,
                    onDateChanged: viewModel.setDate,
                    onTimeChanged: viewModel.setTime,
                  ),
                  const SizedBox(height: 16),
                  FormulaSection(
                    selectedFormula: viewModel.selectedFormula,
                    formulas: formulaViewModel.formulas,
                    onFormulaChanged: viewModel.setFormula,
                    numberOfPersons: viewModel.numberOfPersons,
                    numberOfGames: viewModel.numberOfGames,
                    onPersonsChanged: viewModel.setNumberOfPersons,
                    onGamesChanged: viewModel.setNumberOfGames,
                  ),
                  if (booking == null) ...[
                    const SizedBox(height: 16),
                    DepositSection(
                      selectedFormula: viewModel.selectedFormula,
                      numberOfPersons: viewModel.numberOfPersons,
                      numberOfGames: viewModel.numberOfGames,
                      depositAmount: viewModel.depositAmount,
                      paymentMethod: viewModel.paymentMethod,
                      onDepositChanged: viewModel.setDepositAmount,
                      onPaymentMethodChanged: viewModel.setPaymentMethod,
                    ),
                  ],
                ],
              ),
            ),
          );
        },
      ),
    );
  }
}
