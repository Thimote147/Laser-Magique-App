import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import '../../models/booking_model.dart';
import '../../viewmodels/booking_view_model.dart';
import '../utils/cancelled_text_style.dart';

class BookingListItem extends StatelessWidget {
  final Booking booking;
  final VoidCallback onTap;
  final VoidCallback onMoreTap;

  const BookingListItem({
    super.key,
    required this.booking,
    required this.onTap,
    required this.onMoreTap,
  });

  @override
  Widget build(BuildContext context) {
    // Nous utilisons _getActivityColorWithBrightness directement maintenant

    return Container(
      margin: const EdgeInsets.symmetric(vertical: 4),
      decoration: BoxDecoration(
        border: Border(
          left: BorderSide(
            color:
                booking.isCancelled
                    ? (Theme.of(context).brightness == Brightness.dark
                        ? Colors.red.shade400
                        : Colors.red.shade600)
                    : booking.remainingBalance <= 0
                    ? (Theme.of(context).brightness == Brightness.dark
                        ? Colors.green.shade400
                        : Colors.green.shade600)
                    : _getActivityColorWithBrightness(
                      booking.formula.name,
                      Theme.of(context).brightness,
                    ),
            width: booking.isCancelled || booking.remainingBalance <= 0 ? 4 : 3,
          ),
          bottom: BorderSide(
            color:
                Theme.of(context).brightness == Brightness.dark
                    ? Colors.grey.shade800
                    : Colors.grey.shade200,
            width: 1,
          ),
        ),
        color:
            booking.isCancelled
                ? (Theme.of(context).brightness == Brightness.dark
                    ? Colors.red.shade900.withOpacity(0.3)
                    : Colors.red.shade50.withOpacity(0.5))
                : booking.remainingBalance <= 0
                ? (Theme.of(context).brightness == Brightness.dark
                    ? Colors.green.shade900.withOpacity(0.3)
                    : Colors.green.shade50.withOpacity(0.5))
                : Theme.of(context).brightness == Brightness.dark
                ? Colors.grey.shade900.withOpacity(0.3)
                : null,
        boxShadow:
            booking.isCancelled
                ? [
                  BoxShadow(
                    color: (Theme.of(context).brightness == Brightness.dark
                            ? Colors.red.shade700
                            : Colors.red)
                        .withOpacity(0.15),
                    blurRadius: 3,
                    spreadRadius: 1,
                  ),
                ]
                : booking.remainingBalance <= 0
                ? [
                  BoxShadow(
                    color: (Theme.of(context).brightness == Brightness.dark
                            ? Colors.green.shade700
                            : Colors.green)
                        .withOpacity(0.15),
                    blurRadius: 3,
                    spreadRadius: 1,
                  ),
                ]
                : null,
      ),
      child: Dismissible(
        key: Key(booking.id),
        background: Container(
          color: Colors.red,
          alignment: Alignment.centerLeft,
          padding: const EdgeInsets.symmetric(horizontal: 20),
          child: const Icon(Icons.delete_forever, color: Colors.white),
        ),
        secondaryBackground: Container(
          color:
              booking.isCancelled ? Colors.green.shade100 : Colors.red.shade100,
          alignment: Alignment.centerRight,
          padding: const EdgeInsets.symmetric(horizontal: 20),
          child: Icon(
            booking.isCancelled ? Icons.restore : Icons.cancel,
            color: booking.isCancelled ? Colors.green : Colors.red,
          ),
        ),
        confirmDismiss: (direction) async {
          if (direction == DismissDirection.endToStart) {
            // Confirmer l'annulation ou la restauration
            final viewModel = Provider.of<BookingViewModel>(
              context,
              listen: false,
            );

            final String title =
                booking.isCancelled
                    ? 'Confirmer la restauration'
                    : 'Confirmer l\'annulation';
            final String content =
                booking.isCancelled
                    ? 'Voulez-vous vraiment restaurer la réservation de ${booking.firstName} ${booking.lastName ?? ""} ?'
                    : 'Voulez-vous vraiment marquer la réservation de ${booking.firstName} ${booking.lastName ?? ""} comme annulée ?';
            final String confirmText =
                booking.isCancelled ? 'RESTAURER' : 'ANNULER';
            final Color confirmColor =
                booking.isCancelled ? Colors.green : Colors.orange;

            final result = await showDialog<bool>(
              context: context,
              builder: (BuildContext context) {
                return AlertDialog(
                  title: Text(title),
                  content: Text(content),
                  actions: [
                    TextButton(
                      onPressed: () => Navigator.of(context).pop(false),
                      child: const Text('RETOUR'),
                    ),
                    TextButton(
                      onPressed: () => Navigator.of(context).pop(true),
                      style: TextButton.styleFrom(
                        foregroundColor: confirmColor,
                      ),
                      child: Text(confirmText),
                    ),
                  ],
                );
              },
            );

            if (result == true) {
              viewModel.toggleCancellationStatus(booking.id);
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
            }
            return false; // Ne pas supprimer l'élément
          } else if (direction == DismissDirection.startToEnd) {
            // Confirmer la suppression
            final viewModel = Provider.of<BookingViewModel>(
              context,
              listen: false,
            );
            final result = await showDialog<bool>(
              context: context,
              builder: (BuildContext context) {
                return AlertDialog(
                  title: const Text('Confirmer la suppression'),
                  content: Text(
                    'Êtes-vous sûr de vouloir supprimer définitivement la réservation de ${booking.firstName} ${booking.lastName ?? ""} ?',
                  ),
                  actions: [
                    TextButton(
                      onPressed: () => Navigator.of(context).pop(false),
                      child: const Text('ANNULER'),
                    ),
                    TextButton(
                      onPressed: () => Navigator.of(context).pop(true),
                      style: TextButton.styleFrom(foregroundColor: Colors.red),
                      child: const Text('SUPPRIMER'),
                    ),
                  ],
                );
              },
            );

            if (result == true) {
              viewModel.removeBooking(booking.id);
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text('Réservation supprimée définitivement'),
                  duration: Duration(seconds: 2),
                ),
              );
              return true; // Permettre la suppression de l'élément de la liste
            }
            return false; // Ne pas supprimer si l'utilisateur annule
          }
          return false; // Par défaut, ne pas supprimer
        },
        direction: DismissDirection.horizontal, // Permettre les deux directions
        child: Material(
          color:
              Theme.of(context).brightness == Brightness.dark
                  ? (booking.isCancelled
                      ? Colors.red.shade900.withOpacity(0.3)
                      : booking.remainingBalance <= 0
                      ? Colors.green.shade900.withOpacity(0.3)
                      : Colors.transparent)
                  : (booking.isCancelled
                      ? Colors.red.shade50.withOpacity(0.5)
                      : booking.remainingBalance <= 0
                      ? Colors.green.shade50.withOpacity(0.5)
                      : Colors.transparent),
          child: InkWell(
            onTap: onTap,
            splashColor:
                booking.isCancelled
                    ? (Theme.of(context).brightness == Brightness.dark
                        ? Colors.red.shade700
                        : Colors.red.shade100)
                    : booking.remainingBalance <= 0
                    ? (Theme.of(context).brightness == Brightness.dark
                        ? Colors.green.shade700
                        : Colors.green.shade100)
                    : Theme.of(context).splashColor,
            highlightColor:
                booking.isCancelled
                    ? (Theme.of(context).brightness == Brightness.dark
                        ? Colors.red.shade800.withOpacity(0.3)
                        : Colors.red.shade200.withOpacity(0.3))
                    : booking.remainingBalance <= 0
                    ? (Theme.of(context).brightness == Brightness.dark
                        ? Colors.green.shade800.withOpacity(0.3)
                        : Colors.green.shade200.withOpacity(0.3))
                    : Theme.of(context).highlightColor,
            child: Stack(
              children: [
                Padding(
                  padding: const EdgeInsets.fromLTRB(8, 6, 4, 6),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.center,
                    children: [
                      // Heure et infos
                      SizedBox(
                        width: 42,
                        child: Text(
                          DateFormat.Hm('fr_FR').format(booking.dateTime),
                          style: CancelledTextStyle.apply(
                            TextStyle(
                              color:
                                  Theme.of(context).brightness ==
                                          Brightness.dark
                                      ? Theme.of(
                                        context,
                                      ).colorScheme.secondary.withOpacity(0.9)
                                      : Theme.of(context).colorScheme.secondary,
                              fontWeight: FontWeight.w600,
                              fontSize: 14,
                            ),
                            booking.isCancelled,
                          ),
                        ),
                      ),
                      const SizedBox(width: 8),
                      // Contenu principal
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            // Nom et prénom avec indication d'annulation
                            Row(
                              children: [
                                Expanded(
                                  child: Text(
                                    '${booking.firstName} ${booking.lastName ?? ""}',
                                    style:
                                        booking.isCancelled
                                            ? TextStyle(
                                              fontWeight: FontWeight.bold,
                                              fontSize: 14,
                                              color:
                                                  Theme.of(
                                                            context,
                                                          ).brightness ==
                                                          Brightness.dark
                                                      ? Colors.grey.shade400
                                                      : Colors.grey.shade700,
                                              decoration:
                                                  TextDecoration.lineThrough,
                                              decorationColor:
                                                  Theme.of(
                                                            context,
                                                          ).brightness ==
                                                          Brightness.dark
                                                      ? Colors.red.shade300
                                                      : Colors.red.shade400,
                                              decorationThickness: 2.0,
                                            )
                                            : TextStyle(
                                              fontWeight: FontWeight.bold,
                                              fontSize: 14,
                                              color:
                                                  Theme.of(
                                                            context,
                                                          ).brightness ==
                                                          Brightness.dark
                                                      ? Colors.white
                                                      : Colors.black,
                                            ),
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                ),
                                if (booking.isCancelled)
                                  Container(
                                    margin: const EdgeInsets.only(left: 4),
                                    padding: const EdgeInsets.symmetric(
                                      horizontal: 6,
                                      vertical: 2,
                                    ),
                                    decoration: BoxDecoration(
                                      color:
                                          Theme.of(context).brightness ==
                                                  Brightness.dark
                                              ? Colors.red.shade400
                                              : Colors.red.shade600,
                                      borderRadius: BorderRadius.circular(4),
                                      boxShadow: [
                                        BoxShadow(
                                          color:
                                              Theme.of(context).brightness ==
                                                      Brightness.dark
                                                  ? Colors.red.shade700
                                                      .withOpacity(0.4)
                                                  : Colors.red.shade200
                                                      .withOpacity(0.4),
                                          blurRadius: 2,
                                          offset: const Offset(0, 1),
                                        ),
                                      ],
                                    ),
                                    child: Row(
                                      mainAxisSize: MainAxisSize.min,
                                      children: [
                                        const Icon(
                                          Icons.cancel_outlined,
                                          size: 12,
                                          color: Colors.white,
                                        ),
                                        const SizedBox(width: 2),
                                        const Text(
                                          'ANNULÉE',
                                          style: TextStyle(
                                            color: Colors.white,
                                            fontSize: 11,
                                            fontWeight: FontWeight.bold,
                                            letterSpacing: 0.5,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                if (!booking.isCancelled &&
                                    booking.remainingBalance <= 0)
                                  Container(
                                    margin: const EdgeInsets.only(left: 4),
                                    padding: const EdgeInsets.symmetric(
                                      horizontal: 6,
                                      vertical: 2,
                                    ),
                                    decoration: BoxDecoration(
                                      color:
                                          Theme.of(context).brightness ==
                                                  Brightness.dark
                                              ? Colors.green.shade400
                                              : Colors.green.shade600,
                                      borderRadius: BorderRadius.circular(4),
                                      boxShadow: [
                                        BoxShadow(
                                          color:
                                              Theme.of(context).brightness ==
                                                      Brightness.dark
                                                  ? Colors.green.shade700
                                                      .withOpacity(0.4)
                                                  : Colors.green.shade200
                                                      .withOpacity(0.4),
                                          blurRadius: 2,
                                          offset: const Offset(0, 1),
                                        ),
                                      ],
                                    ),
                                    child: Row(
                                      mainAxisSize: MainAxisSize.min,
                                      children: [
                                        const Icon(
                                          Icons.check_circle_outline,
                                          size: 12,
                                          color: Colors.white,
                                        ),
                                        const SizedBox(width: 2),
                                        const Text(
                                          'PAYÉE',
                                          style: TextStyle(
                                            color: Colors.white,
                                            fontSize: 11,
                                            fontWeight: FontWeight.bold,
                                            letterSpacing: 0.5,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                              ],
                            ),
                            const SizedBox(height: 2),
                            // Activité et détails combinés sur une ligne
                            Row(
                              children: [
                                Flexible(
                                  child: Text(
                                    '${booking.formula.activity.name} - ${booking.formula.name}',
                                    style: CancelledTextStyle.apply(
                                      TextStyle(
                                        color:
                                            booking.isCancelled
                                                ? (Theme.of(
                                                          context,
                                                        ).brightness ==
                                                        Brightness.dark
                                                    ? Colors.grey.shade400
                                                    : Colors.grey.shade600)
                                                : _getActivityColorWithBrightness(
                                                  booking.formula.name,
                                                  Theme.of(context).brightness,
                                                ),
                                        fontWeight: FontWeight.w500,
                                        fontSize: 12,
                                      ),
                                      booking.isCancelled,
                                    ),
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                ),
                                const Text(
                                  ' • ',
                                  style: TextStyle(
                                    fontSize: 12,
                                    fontWeight: FontWeight.w400,
                                  ),
                                ),
                                Text(
                                  '${booking.numberOfPersons} personne${booking.numberOfPersons > 1 ? 's' : ''} - ${booking.numberOfGames} partie${booking.numberOfGames > 1 ? 's' : ''}',
                                  style: CancelledTextStyle.apply(
                                    TextStyle(
                                      fontSize: 12,
                                      color:
                                          booking.isCancelled
                                              ? (Theme.of(context).brightness ==
                                                      Brightness.dark
                                                  ? Colors.grey.shade400
                                                  : Colors.grey.shade600)
                                              : (Theme.of(context).brightness ==
                                                      Brightness.dark
                                                  ? Colors.grey.shade300
                                                  : null),
                                    ),
                                    booking.isCancelled,
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
                      // Menu contextuel
                      IconButton(
                        icon: const Icon(Icons.more_vert, size: 16),
                        onPressed: onMoreTap,
                        padding: EdgeInsets.zero,
                        visualDensity: VisualDensity.compact,
                        constraints: const BoxConstraints(),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  // Fonction pour obtenir une couleur basée sur le type d'activité
  Color _getActivityColor(String activityName) {
    switch (activityName.toLowerCase()) {
      case 'laser game':
        return Colors.red.shade700;
      case 'arcade':
        return Colors.blue.shade700;
      case 'réalité virtuelle':
        return Colors.green.shade700;
      default:
        return Colors.purple.shade700;
    }
  }

  Color _getActivityColorWithBrightness(
    String activityName,
    Brightness brightness,
  ) {
    if (brightness == Brightness.dark) {
      // Couleurs plus claires pour le mode sombre pour un meilleur contraste
      switch (activityName.toLowerCase()) {
        case 'laser game':
          return Colors.red.shade400;
        case 'arcade':
          return Colors.blue.shade400;
        case 'réalité virtuelle':
          return Colors.green.shade400;
        default:
          return Colors.purple.shade400;
      }
    } else {
      // Couleurs standards pour le mode clair
      return _getActivityColor(activityName);
    }
  }
}
