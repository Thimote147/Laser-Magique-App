import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../viewmodels/booking_view_model.dart';
import '../../models/booking_model.dart';
import 'booking_list_item.dart';
import '../../../../shared/user_provider.dart';
import '../../../../shared/widgets/custom_dialog.dart';

// Fonction utilitaire pour vérifier si une réservation est passée
bool _isBookingPast(Booking booking) {
  final now = DateTime.now();
  final bookingDate = booking.dateTimeLocal;
  return bookingDate.isBefore(DateTime(now.year, now.month, now.day));
}

class BookingListWidget extends StatelessWidget {
  final BookingViewModel viewModel;
  final DateTime selectedDay;

  const BookingListWidget({
    super.key,
    required this.viewModel,
    required this.selectedDay,
  });

  @override
  Widget build(BuildContext context) {
    if (viewModel.isLoading) {
      return const Center(child: CircularProgressIndicator());
    }

    final bookings = viewModel.getBookingsForDay(selectedDay);

    if (bookings.isEmpty) {
      return const Center(
        child: Text(
          'Aucune réservation pour cette journée',
          style: TextStyle(fontSize: 16, fontStyle: FontStyle.italic),
        ),
      );
    }

    return RefreshIndicator(
      onRefresh: () => viewModel.refresh(),
      child: ListView.builder(
        physics: const AlwaysScrollableScrollPhysics(),
        itemCount: bookings.length,
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
        itemBuilder: (context, index) {
          final booking = bookings[index];
          return BookingListItem(
            booking: booking,
            onTap: () {
              _showBookingDetails(context, booking);
            },
            onMoreTap: () {
              _showBookingOptions(context, booking, viewModel);
            },
          );
        },
      ),
    );
  }

  void _showBookingDetails(BuildContext context, Booking booking) {
    showDialog(
      context: context,
      builder:
          (context) => CustomDialog(
            title: '${booking.firstName} ${booking.lastName ?? ""}',
            titleIcon: Icon(Icons.person),
            content: SingleChildScrollView(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  // Indicateur de statut (annulée ou non)
                  if (booking.isCancelled)
                    Container(
                      margin: const EdgeInsets.only(bottom: 12),
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: Theme.of(context).colorScheme.errorContainer.withValues(alpha: 0.3),
                        borderRadius: BorderRadius.circular(4),
                        border: Border.all(color: Theme.of(context).colorScheme.error.withValues(alpha: 0.3)),
                      ),
                      child: Row(
                        children: [
                          Icon(
                            Icons.cancel,
                            color: Theme.of(context).colorScheme.error,
                            size: 18,
                          ),
                          const SizedBox(width: 8),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  'Réservation annulée',
                                  style: TextStyle(
                                    fontWeight: FontWeight.bold,
                                    color: Theme.of(context).colorScheme.error,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                  ListTile(
                    title: const Text('Activité'),
                    subtitle: Text(
                      '${booking.formula.activity.name} - ${booking.formula.name}',
                    ),
                    leading: const Icon(Icons.sports_esports),
                  ),
                  ListTile(
                    title: const Text('Détails'),
                    subtitle: Text(
                      '${booking.numberOfPersons} personne${booking.numberOfPersons > 1 ? 's' : ''}\n'
                      '${booking.numberOfGames} partie${booking.numberOfGames > 1 ? 's' : ''}',
                    ),
                    leading: const Icon(Icons.group),
                  ),
                  if (booking.email != null)
                    ListTile(
                      title: const Text('Contact'),
                      subtitle: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          if (booking.email != null)
                            Text('Email: ${booking.email}'),
                          if (booking.phone != null)
                            Text('Tél: ${booking.phone}'),
                        ],
                      ),
                      leading: const Icon(Icons.contact_mail),
                    ),
                ],
              ),
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context),
                child: const Text('FERMER'),
              ),
            ],
          ),
    );
  }

  void _showBookingOptions(
    BuildContext context,
    Booking booking,
    BookingViewModel viewModel,
  ) {
    final userProvider = Provider.of<UserProvider>(context, listen: false);
    final isAdmin = userProvider.user?.settings?.role == 'admin';
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
      builder: (context) {
        return SafeArea(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              if (!_isBookingPast(booking))
                ListTile(
                  leading: const Icon(Icons.edit, color: Colors.blue),
                  title: const Text('Modifier la réservation'),
                  onTap: () {
                    Navigator.pop(context);
                    _showEditBookingDialog(context, booking, viewModel);
                  },
                ),
              if (!_isBookingPast(booking))
                ListTile(
                  leading: Icon(
                    booking.isCancelled ? Icons.restore : Icons.cancel,
                    color: booking.isCancelled ? Colors.green : Colors.orange,
                  ),
                  title: Text(
                    booking.isCancelled
                        ? 'Restaurer la réservation'
                        : 'Marquer comme annulée',
                    style: TextStyle(
                      color: booking.isCancelled ? Colors.green : Colors.orange,
                    ),
                  ),
                  subtitle: null,
                  onTap: () {
                    Navigator.pop(context);
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
                ),
              if (isAdmin && !_isBookingPast(booking))
                ListTile(
                  leading: const Icon(Icons.delete, color: Colors.red),
                  title: const Text('Supprimer la réservation'),
                  onTap: () {
                    Navigator.pop(context);
                    _confirmDelete(context, booking, viewModel);
                  },
                ),
              if (booking.email != null)
                ListTile(
                  leading: const Icon(Icons.email, color: Colors.green),
                  title: const Text('Envoyer un email'),
                  subtitle: Text(booking.email!),
                  onTap: () {
                    Navigator.pop(context);
                    // Implémenter l'envoi d'email ici
                    showDialog(
                      context: context,
                      builder: (context) => CustomSuccessDialog(
                        title: 'Email',
                        content: 'Email à ${booking.email}',
                        autoClose: true,
                        autoCloseDuration: const Duration(seconds: 2),
                      ),
                    );
                  },
                ),
              if (booking.phone != null)
                ListTile(
                  leading: const Icon(Icons.phone, color: Colors.green),
                  title: const Text('Appeler'),
                  subtitle: Text(booking.phone!),
                  onTap: () async {
                    Navigator.pop(context);
                    // Implémenter l'appel téléphonique ici
                    await showDialog(
                      context: context,
                      builder: (context) => CustomSuccessDialog(
                        title: 'Appel initié',
                        content: 'Appel vers ${booking.phone}',
                        autoClose: true,
                        autoCloseDuration: const Duration(seconds: 2),
                      ),
                    );
                  },
                ),
            ],
          ),
        );
      },
    );
  }

  void _confirmDelete(
    BuildContext context,
    Booking booking,
    BookingViewModel viewModel,
  ) {
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
              viewModel.removeBooking(booking.id);
              Navigator.pop(context);
              
              // Afficher le dialog de succès au lieu du SnackBar
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

  void _showEditBookingDialog(
    BuildContext context,
    Booking booking,
    BookingViewModel viewModel,
  ) {
    // Afficher l'interface de modification de réservation
    // (implémentation existante)
  }
}
