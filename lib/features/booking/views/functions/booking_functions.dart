import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../models/booking_model.dart';
import '../../viewmodels/booking_view_model.dart';
import '../../../../shared/widgets/custom_dialog.dart';

class BookingFunctions {
  static void Function(Booking) createBookingSaveCallback(
    BuildContext context,
  ) {
    return (updatedBooking) async {
      final bookingViewModel = context.read<BookingViewModel>();
      try {
        await bookingViewModel.addBooking(
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
        if (context.mounted) {
          Navigator.of(context).pop();
          await showDialog(
            context: context,
            barrierDismissible: true,
            builder:
                (context) => CustomSuccessDialog(
                  title: 'Réservation créée',
                  content: updatedBooking.deposit > 0
                      ? 'Réservation créée avec succès avec un acompte de ${updatedBooking.deposit.toStringAsFixed(2)}€'
                      : 'Réservation créée avec succès',
                  autoClose: true,
                  autoCloseDuration: const Duration(seconds: 3),
                ),
          );
        }
      } catch (e) {
        if (context.mounted) {
          await showDialog(
            context: context,
            builder: (context) => CustomErrorDialog(
              title: 'Erreur de création',
            content: 'Erreur lors de la création de la réservation : ${e is Exception ? e.toString() : 'Erreur inconnue'}',
          ),
        );
        }
      }
    };
  }

  static void Function(Booking) createBookingUpdateCallback(
    BuildContext context,
    Booking? originalBooking,
  ) {
    return (updatedBooking) async {
      final bookingViewModel = context.read<BookingViewModel>();
      try {
        if (originalBooking != null) {
          await bookingViewModel.updateBooking(updatedBooking);
        } else {
          await bookingViewModel.addBooking(
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
        if (context.mounted) {
          Navigator.of(context).pop();
          await showDialog(
            context: context,
            barrierDismissible: true,
            builder:
                (context) => CustomSuccessDialog(
                  title: 'Réservation créée',
                  content: updatedBooking.deposit > 0
                      ? 'Réservation créée avec succès avec un acompte de ${updatedBooking.deposit.toStringAsFixed(2)}€'
                      : 'Réservation créée avec succès',
                  autoClose: true,
                  autoCloseDuration: const Duration(seconds: 3),
                ),
          );
        }
      } catch (e) {
        if (context.mounted) {
          await showDialog(
            context: context,
            builder: (context) => CustomErrorDialog(
              title: 'Erreur de sauvegarde',
              content: 'Erreur lors de la sauvegarde de la réservation : ${e is Exception ? e.toString() : 'Erreur inconnue'}',
            ),
        );
        }
      }
    };
  }
}


