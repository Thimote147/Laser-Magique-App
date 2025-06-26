import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../models/booking_model.dart';
import '../../viewmodels/booking_view_model.dart';

class BookingFunctions {
  static void Function(Booking) createBookingSaveCallback(BuildContext context) {
    return (updatedBooking) {
      final bookingViewModel = context.read<BookingViewModel>();
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
    };
  }

  static void Function(Booking) createBookingUpdateCallback(
    BuildContext context,
    Booking? originalBooking,
  ) {
    return (updatedBooking) {
      final bookingViewModel = context.read<BookingViewModel>();
      if (originalBooking != null) {
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
    };
  }
}