import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';

import '../../models/booking_model.dart';
import '../../viewmodels/booking_view_model.dart';
import '../widgets/booking_consumption_widget.dart';
import '../widgets/booking_payment_widget.dart';
import 'booking_edit_screen.dart';

class BookingDetailsScreen extends StatelessWidget {
  final Booking booking;

  const BookingDetailsScreen({super.key, required this.booking});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('${booking.firstName} ${booking.lastName ?? ""}'),
        actions: [
          IconButton(
            icon: const Icon(Icons.edit),
            onPressed: () {
              Navigator.of(context).push(
                MaterialPageRoute(
                  builder: (context) => BookingEditScreen(booking: booking),
                ),
              );
            },
          ),
          PopupMenuButton(
            itemBuilder:
                (context) => [
                  if (booking.email != null)
                    PopupMenuItem(
                      child: ListTile(
                        leading: const Icon(Icons.email, color: Colors.green),
                        title: const Text('Envoyer un email'),
                        contentPadding: EdgeInsets.zero,
                      ),
                      onTap: () {
                        // Implémenter l'envoi d'email ici
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(content: Text('Email à ${booking.email}')),
                        );
                      },
                    ),
                  if (booking.phone != null)
                    PopupMenuItem(
                      child: ListTile(
                        leading: const Icon(Icons.phone, color: Colors.green),
                        title: const Text('Appeler'),
                        contentPadding: EdgeInsets.zero,
                      ),
                      onTap: () {
                        // Implémenter l'appel téléphonique ici
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(content: Text('Appel à ${booking.phone}')),
                        );
                      },
                    ),
                  PopupMenuItem(
                    child: ListTile(
                      leading: Icon(
                        booking.isCancelled ? Icons.restore : Icons.cancel,
                        color:
                            booking.isCancelled ? Colors.green : Colors.orange,
                      ),
                      title: Text(
                        booking.isCancelled
                            ? 'Restaurer la réservation'
                            : 'Marquer comme annulée',
                        style: TextStyle(
                          color:
                              booking.isCancelled
                                  ? Colors.green
                                  : Colors.orange,
                        ),
                      ),
                      contentPadding: EdgeInsets.zero,
                    ),
                    onTap: () {
                      Provider.of<BookingViewModel>(
                        context,
                        listen: false,
                      ).toggleCancellationStatus(booking.id);
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                          content: Text(
                            booking.isCancelled
                                ? 'La réservation a été restaurée'
                                : 'La réservation a été marquée comme annulée',
                          ),
                          duration: const Duration(seconds: 2),
                        ),
                      );
                    },
                  ),
                  PopupMenuItem(
                    child: const ListTile(
                      leading: Icon(Icons.delete, color: Colors.red),
                      title: Text('Supprimer la réservation'),
                      contentPadding: EdgeInsets.zero,
                    ),
                    onTap: () async {
                      // Délai pour permettre au menu de se fermer
                      await Future.delayed(const Duration(milliseconds: 100));
                      if (!context.mounted) return;

                      final confirmed = await showDialog<bool>(
                        context: context,
                        builder:
                            (context) => AlertDialog(
                              title: const Text('Confirmer la suppression'),
                              content: Text(
                                'Êtes-vous sûr de vouloir supprimer définitivement la réservation de ${booking.firstName} ${booking.lastName ?? ""} ?',
                              ),
                              actions: [
                                TextButton(
                                  onPressed:
                                      () => Navigator.of(context).pop(false),
                                  child: const Text('Annuler'),
                                ),
                                TextButton(
                                  onPressed:
                                      () => Navigator.of(context).pop(true),
                                  child: const Text(
                                    'Supprimer',
                                    style: TextStyle(color: Colors.red),
                                  ),
                                ),
                              ],
                            ),
                      );

                      if (confirmed == true && context.mounted) {
                        Provider.of<BookingViewModel>(
                          context,
                          listen: false,
                        ).removeBooking(booking.id);
                        Navigator.of(context).pop();
                      }
                    },
                  ),
                ],
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (booking.isCancelled)
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
            Card(
              child: Column(
                children: [
                  ListTile(
                    leading: const Icon(Icons.calendar_today),
                    title: Text(
                      DateFormat.yMMMMd('fr_FR').format(booking.dateTime),
                    ),
                    subtitle: Text(
                      DateFormat.Hm('fr_FR').format(booking.dateTime),
                    ),
                  ),
                  const Divider(height: 1),
                  ListTile(
                    leading: const Icon(Icons.groups),
                    title: Text(
                      '${booking.numberOfPersons} personne${booking.numberOfPersons > 1 ? 's' : ''}',
                    ),
                    subtitle: Text(
                      '${booking.numberOfGames} partie${booking.numberOfGames > 1 ? 's' : ''}',
                    ),
                  ),
                  const Divider(height: 1),
                  ListTile(
                    leading: const Icon(Icons.sports_esports),
                    title: Text(booking.formula.activity.name),
                    subtitle: Text(booking.formula.name),
                  ),
                ],
              ),
            ),
            if (booking.email != null || booking.phone != null) ...[
              const SizedBox(height: 24),
              const Text(
                'Contact',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 8),
              Card(
                child: Column(
                  children: [
                    if (booking.email != null)
                      ListTile(
                        leading: const Icon(Icons.email),
                        title: const Text('Email'),
                        subtitle: Text(booking.email!),
                      ),
                    if (booking.email != null && booking.phone != null)
                      const Divider(height: 1),
                    if (booking.phone != null)
                      ListTile(
                        leading: const Icon(Icons.phone),
                        title: const Text('Téléphone'),
                        subtitle: Text(booking.phone!),
                      ),
                  ],
                ),
              ),
            ],
            const SizedBox(height: 24),
            BookingPaymentWidget(booking: booking),
            const SizedBox(height: 24),
            BookingConsumptionWidget(booking: booking),
          ],
        ),
      ),
    );
  }
}
