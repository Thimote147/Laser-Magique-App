import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../models/booking_model.dart';
import '../../viewmodels/booking_view_model.dart';
import 'package:provider/provider.dart';
import '../../../profile/viewmodels/employee_profile_view_model.dart';
import '../../../../shared/widgets/custom_dialog.dart';

// Fonction utilitaire pour vérifier si une réservation est passée
bool _isBookingPast(Booking booking) {
  final now = DateTime.now();
  final bookingDate = booking.dateTimeLocal;
  return bookingDate.isBefore(DateTime(now.year, now.month, now.day));
}

class BookingDetailsWidget extends StatelessWidget {
  final Booking booking;

  const BookingDetailsWidget({super.key, required this.booking});

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (booking.isCancelled)
            Container(
              margin: const EdgeInsets.only(bottom: 12),
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: Colors.red.shade50,
                borderRadius: BorderRadius.circular(4),
                border: Border.all(color: Colors.red.shade200),
              ),
              child: Row(
                children: [
                  Icon(Icons.cancel, color: Colors.red.shade400),
                  const SizedBox(width: 8),
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

          Card(
            child: ListTile(
              leading: const Icon(Icons.calendar_today),
              title: Text(
                DateFormat.yMMMMd('fr_FR').format(booking.dateTimeLocal),
              ),
              subtitle: Text(
                DateFormat.Hm('fr_FR').format(booking.dateTimeLocal),
              ),
            ),
          ),

          Card(
            child: ListTile(
              leading: const Icon(Icons.groups),
              title: Text(
                '${booking.numberOfPersons} personne${booking.numberOfPersons > 1 ? 's' : ''}',
              ),
              subtitle: Text(
                '${booking.numberOfGames} partie${booking.numberOfGames > 1 ? 's' : ''}',
              ),
            ),
          ),
          Card(
            child: ListTile(
              leading: const Icon(Icons.sports_esports),
              title: Text(booking.formula.activity.name),
              subtitle: Text(booking.formula.name),
            ),
          ),

          // Affichage des infos client réservé aux admins
          Consumer<EmployeeProfileViewModel>(
            builder: (context, profileVM, _) {
              if (profileVM.role != UserRole.admin) return SizedBox.shrink();
              if (booking.email == null && booking.phone == null) {
                return SizedBox.shrink();
              }
              return Card(
                child: Column(
                  children: [
                    if (booking.email != null)
                      ListTile(
                        leading: const Icon(Icons.email),
                        title: Text(booking.email!),
                        onTap: () => _sendEmail(context, booking.email!),
                      ),
                    if (booking.phone != null)
                      ListTile(
                        leading: const Icon(Icons.phone),
                        title: Text(booking.phone!),
                        onTap: () => _makePhoneCall(context, booking.phone!),
                      ),
                  ],
                ),
              );
            },
          ),

          const SizedBox(height: 16),

          Row(
            children: [
              Expanded(
                child: ElevatedButton.icon(
                  icon: Icon(
                    booking.isCancelled ? Icons.restore : Icons.cancel,
                    color: booking.isCancelled ? Colors.green : Colors.orange,
                  ),
                  label: Text(
                    booking.isCancelled
                        ? 'Restaurer la réservation'
                        : 'Marquer comme annulée',
                  ),
                  onPressed: _isBookingPast(booking) ? null : () {
                    final viewModel = context.read<BookingViewModel>();
                    viewModel.toggleCancellationStatus(booking.id);
                    showDialog(
                      context: context,
                      builder: (context) => CustomSuccessDialog(
                        title: 'Succès',
                        content: booking.isCancelled
                            ? 'La réservation a été restaurée'
                            : 'La réservation a été marquée comme annulée',
                        autoClose: true,
                        autoCloseDuration: const Duration(seconds: 2),
                      ),
                    );
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor:
                        booking.isCancelled
                            ? Colors.green.shade50
                            : Colors.orange.shade50,
                  ),
                ),
              ),
              const SizedBox(width: 8),
              ElevatedButton.icon(
                icon: const Icon(Icons.delete, color: Colors.red),
                label: const Text('Supprimer'),
                onPressed: _isBookingPast(booking) ? null : () => _confirmDelete(context),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.red.shade50,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Future<void> _makePhoneCall(BuildContext context, String phoneNumber) async {
    final Uri launchUri = Uri.parse('tel:$phoneNumber');
    
    try {
      if (await canLaunchUrl(launchUri)) {
        await launchUrl(launchUri, mode: LaunchMode.externalApplication);
      } else {
        if (context.mounted) {
          showDialog(
            context: context,
            builder: (context) => CustomErrorDialog(
              title: 'Erreur',
              content: 'Impossible d\'ouvrir l\'application téléphone',
            ),
          );
        }
      }
    } catch (e) {
      if (context.mounted) {
        showDialog(
          context: context,
          builder: (context) => CustomErrorDialog(
            title: 'Erreur',
            content: 'Erreur lors de l\'appel: $e',
          ),
        );
      }
    }
  }

  Future<void> _sendEmail(BuildContext context, String email) async {
    final String subject = Uri.encodeComponent('Concernant votre réservation Laser Magique');
    final String body = Uri.encodeComponent('Bonjour ${booking.firstName},\n\n');
    final Uri launchUri = Uri.parse('mailto:$email?subject=$subject&body=$body');
    
    try {
      if (await canLaunchUrl(launchUri)) {
        await launchUrl(launchUri, mode: LaunchMode.externalApplication);
      } else {
        if (context.mounted) {
          showDialog(
            context: context,
            builder: (context) => CustomErrorDialog(
              title: 'Erreur',
              content: 'Impossible d\'ouvrir l\'application email',
            ),
          );
        }
      }
    } catch (e) {
      if (context.mounted) {
        showDialog(
          context: context,
          builder: (context) => CustomErrorDialog(
            title: 'Erreur',
            content: 'Erreur lors de l\'envoi d\'email: $e',
          ),
        );
      }
    }
  }

  void _confirmDelete(BuildContext context) {
    showDialog(
      context: context,
      builder:
          (context) => CustomConfirmDialog(
            title: 'Confirmer la suppression',
            content: 'Êtes-vous sûr de vouloir supprimer définitivement la réservation de ${booking.firstName} ${booking.lastName ?? ""} ?',
            confirmText: 'SUPPRIMER',
            cancelText: 'ANNULER',
            icon: Icons.delete_forever,
            iconColor: Colors.red,
            confirmColor: Colors.red,
            onConfirm: () async {
              final viewModel = context.read<BookingViewModel>();
              viewModel.removeBooking(booking.id);
              Navigator.pop(context); // Ferme le dialogue
              Navigator.pop(context); // Retourne à l'écran précédent
              
              // Afficher le dialog de succès
              await showDialog(
                context: context,
                barrierDismissible: true,
                builder: (context) => CustomSuccessDialog(
                  title: 'Suppression réussie',
                  content: 'La réservation de ${booking.firstName} ${booking.lastName ?? ""} a été supprimée avec succès',
                  autoClose: true,
                  autoCloseDuration: const Duration(seconds: 3),
                ),
              );
            },
            onCancel: () => Navigator.pop(context),
          ),
    );
  }
}
