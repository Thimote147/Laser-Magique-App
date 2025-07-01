import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../models/booking_model.dart';
import '../../viewmodels/booking_view_model.dart';

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
        Navigator.of(context).pop();
        await showDialog(
          context: context,
          barrierDismissible: true,
          builder:
              (context) => SuccessDialog(
                message:
                    updatedBooking.deposit > 0
                        ? 'Réservation créée avec un acompte de ${updatedBooking.deposit.toStringAsFixed(2)}€'
                        : 'Réservation créée avec succès',
              ),
        );
      } catch (e) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              'Erreur lors de la création de la réservation : ${e is Exception ? e.toString() : 'Erreur inconnue'}',
            ),
            backgroundColor: Colors.red,
          ),
        );
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
        Navigator.of(context).pop();
        await showDialog(
          context: context,
          barrierDismissible: true,
          builder:
              (context) => SuccessDialog(
                message:
                    updatedBooking.deposit > 0
                        ? 'Réservation créée avec un acompte de ${updatedBooking.deposit.toStringAsFixed(2)}€'
                        : 'Réservation créée avec succès',
              ),
        );
      } catch (e) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              'Erreur lors de la sauvegarde de la réservation : ${e is Exception ? e.toString() : 'Erreur inconnue'}',
            ),
            backgroundColor: Colors.red,
          ),
        );
      }
    };
  }
}

class SuccessDialog extends StatefulWidget {
  final String message;
  const SuccessDialog({Key? key, required this.message}) : super(key: key);

  @override
  State<SuccessDialog> createState() => _SuccessDialogState();
}

class _SuccessDialogState extends State<SuccessDialog>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _scaleAnim;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1100),
    );
    _scaleAnim = CurvedAnimation(parent: _controller, curve: Curves.elasticOut);
    _controller.forward();
    Future.delayed(const Duration(milliseconds: 2600), () {
      if (mounted) Navigator.of(context).pop();
    });
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      backgroundColor: Colors.transparent,
      elevation: 0,
      child: Center(
        child: ScaleTransition(
          scale: _scaleAnim,
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 28),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(20),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.08),
                  blurRadius: 16,
                  offset: const Offset(0, 8),
                ),
              ],
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  decoration: BoxDecoration(
                    color: Colors.green.shade100,
                    shape: BoxShape.circle,
                  ),
                  padding: const EdgeInsets.all(16),
                  child: Icon(
                    Icons.check_circle_rounded,
                    color: Colors.green.shade600,
                    size: 48,
                  ),
                ),
                const SizedBox(height: 18),
                Text(
                  widget.message,
                  textAlign: TextAlign.center,
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    color: Colors.green.shade800,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
