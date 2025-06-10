import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../../models/booking_model.dart';
import '../../viewmodels/booking_view_model.dart';
import 'package:provider/provider.dart';

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
              title: Text(DateFormat.yMMMMd('fr_FR').format(booking.dateTime)),
              subtitle: Text(DateFormat.Hm('fr_FR').format(booking.dateTime)),
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

          if (booking.email != null || booking.phone != null)
            Card(
              child: Column(
                children: [
                  if (booking.email != null)
                    ListTile(
                      leading: const Icon(Icons.email),
                      title: Text(booking.email!),
                      onTap: () {
                        // TODO: Implémenter l'envoi d'email
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(content: Text('Email à ${booking.email}')),
                        );
                      },
                    ),
                  if (booking.phone != null)
                    ListTile(
                      leading: const Icon(Icons.phone),
                      title: Text(booking.phone!),
                      onTap: () {
                        // TODO: Implémenter l'appel téléphonique
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(content: Text('Appel à ${booking.phone}')),
                        );
                      },
                    ),
                ],
              ),
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
                  onPressed: () {
                    final viewModel = context.read<BookingViewModel>();
                    viewModel.toggleCancellationStatus(booking.id);
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Text(
                          booking.isCancelled
                              ? 'La réservation a été restaurée'
                              : 'La réservation a été marquée comme annulée',
                        ),
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
                onPressed: () => _confirmDelete(context),
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

  void _confirmDelete(BuildContext context) {
    showDialog(
      context: context,
      builder:
          (context) => AlertDialog(
            title: const Text('Confirmer la suppression'),
            content: Text(
              'Êtes-vous sûr de vouloir supprimer la réservation de ${booking.firstName} ${booking.lastName ?? ""} ?',
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context),
                child: const Text('Annuler'),
              ),
              TextButton(
                onPressed: () {
                  final viewModel = context.read<BookingViewModel>();
                  viewModel.removeBooking(booking.id);
                  Navigator.pop(context); // Ferme le dialogue
                  Navigator.pop(context); // Retourne à l'écran précédent
                },
                child: const Text(
                  'Supprimer',
                  style: TextStyle(color: Colors.red),
                ),
              ),
            ],
          ),
    );
  }
}
