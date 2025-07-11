import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import '../../models/booking_model.dart';
import '../../viewmodels/booking_view_model.dart';
import '../../../inventory/viewmodels/stock_view_model.dart';
import '../../../../shared/widgets/dialogs.dart';

// Fonction utilitaire pour vérifier si une réservation est passée
bool _isBookingPast(Booking booking) {
  final now = DateTime.now();
  final bookingDate = booking.dateTimeLocal;
  return bookingDate.isBefore(DateTime(now.year, now.month, now.day));
}

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
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Consumer<StockViewModel>(
      builder: (context, stockVM, child) {
        // Calculer le montant restant en temps réel pour la bordure
        final currentConsumptionsTotal = stockVM.getConsumptionTotal(
          booking.id,
        );
        final realTotalPrice = booking.formulaPrice + currentConsumptionsTotal;
        final realRemainingBalance = realTotalPrice - booking.totalPaid;

        return Card(
          margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
          elevation: 0,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
            side: BorderSide(
              color:
                  booking.isCancelled
                      ? Theme.of(
                        context,
                      ).colorScheme.error.withAlpha((255 * 0.3).round())
                      : realRemainingBalance <= 0
                      ? Theme.of(
                        context,
                      ).colorScheme.primary.withAlpha((255 * 0.3).round())
                      : Theme.of(context).colorScheme.outlineVariant.withAlpha(
                        (255 * 0.3).round(),
                      ),
            ),
          ),
          child: Dismissible(
            key: Key(booking.id),
            background: Container(
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(12),
                color: Theme.of(context).colorScheme.error,
              ),
              alignment: Alignment.centerLeft,
              padding: const EdgeInsets.symmetric(horizontal: 20),
              child: const Icon(Icons.delete_forever, color: Colors.white),
            ),
            secondaryBackground: Container(
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(12),
                color:
                    booking.isCancelled
                        ? Colors.green
                        : const Color(
                          0xFFE57373,
                        ), // Rouge plus intense mais toujours plus doux que le rouge vif
              ),
              alignment: Alignment.centerRight,
              padding: const EdgeInsets.symmetric(horizontal: 20),
              child: Icon(
                booking.isCancelled ? Icons.restore : Icons.cancel,
                color: Colors.white,
              ),
            ),
            confirmDismiss: _isBookingPast(booking) ? null : (direction) async {
              final navigator = Navigator.of(context);
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
                    return CustomConfirmDialog(
                      title: title,
                      content: content,
                      confirmText: confirmText,
                      cancelText: 'RETOUR',
                      icon: booking.isCancelled ? Icons.restore : Icons.cancel,
                      iconColor: confirmColor,
                      confirmColor: confirmColor,
                      onConfirm: () => navigator.pop(true),
                      onCancel: () => navigator.pop(false),
                    );
                  },
                );

                if (result == true) {
                  viewModel.toggleCancellationStatus(booking.id);
                  if (context.mounted) {
                    await showDialog(
                      context: context,
                      builder: (context) => CustomSuccessDialog(
                        title: booking.isCancelled ? 'Réservation restaurée' : 'Réservation annulée',
                        content: booking.isCancelled
                            ? 'La réservation a été restaurée avec succès'
                            : 'La réservation a été marquée comme annulée',
                        autoClose: true,
                        autoCloseDuration: const Duration(seconds: 2),
                      ),
                    );
                  }
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
                    return CustomConfirmDialog(
                      title: 'Confirmer la suppression',
                      content: 'Êtes-vous sûr de vouloir supprimer définitivement la réservation de ${booking.firstName} ${booking.lastName ?? ""} ?',
                      confirmText: 'SUPPRIMER',
                      cancelText: 'ANNULER',
                      icon: Icons.delete_forever,
                      iconColor: Colors.red,
                      confirmColor: Colors.red,
                      onConfirm: () => navigator.pop(true),
                      onCancel: () => navigator.pop(false),
                    );
                  },
                );

                if (result == true) {
                  viewModel.removeBooking(booking.id);
                  
                  // Afficher le dialog de succès au lieu du SnackBar
                  if (context.mounted) {
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
                  }
                  
                  return true; // Permettre la suppression de l'élément de la liste
                }
                return false; // Ne pas supprimer si l'utilisateur annule
              }
              return false; // Par défaut, ne pas supprimer
            },
            direction:
                DismissDirection.horizontal, // Permettre les deux directions
            child: Material(
              color:
                  booking.isCancelled
                      ? Theme.of(context).colorScheme.errorContainer.withAlpha(
                        (255 * (isDark ? 0.2 : 0.1)).round(),
                      )
                      : realRemainingBalance <= 0
                      ? Theme.of(context).colorScheme.primaryContainer
                          .withAlpha((255 * (isDark ? 0.2 : 0.1)).round())
                      : Colors.transparent,
              borderRadius: BorderRadius.circular(12),
              child: InkWell(
                onTap: onTap,
                borderRadius: BorderRadius.circular(12),
                child: Padding(
                  padding: const EdgeInsets.all(12),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      // Première ligne : Nom et heure
                      Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Expanded(
                            child: Text(
                              '${booking.firstName} ${booking.lastName ?? ""}',
                              style: Theme.of(
                                context,
                              ).textTheme.titleMedium?.copyWith(
                                fontWeight: FontWeight.w500,
                                color:
                                    booking.isCancelled
                                        ? Theme.of(context).colorScheme.outline
                                        : null,
                                decoration:
                                    booking.isCancelled
                                        ? TextDecoration.lineThrough
                                        : null,
                                decorationColor:
                                    Theme.of(context).colorScheme.error,
                              ),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 8,
                              vertical: 4,
                            ),
                            decoration: BoxDecoration(
                              color: Theme.of(context)
                                  .colorScheme
                                  .surfaceContainerHighest
                                  .withAlpha((255 * 0.3).round()),
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: Text(
                              DateFormat.Hm(
                                'fr_FR',
                              ).format(booking.dateTimeLocal),
                              style: TextStyle(
                                color: Theme.of(context).colorScheme.primary,
                                fontWeight: FontWeight.w500,
                                fontSize: 14,
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 8),
                      // Deuxième ligne : Activité et statut
                      Row(
                        children: [
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  '${booking.formula.activity.name} - ${booking.formula.name}',
                                  style: Theme.of(
                                    context,
                                  ).textTheme.bodyMedium?.copyWith(
                                    color: Theme.of(
                                      context,
                                    ).colorScheme.primary.withAlpha(
                                      (255 * (booking.isCancelled ? 0.6 : 1))
                                          .round(),
                                    ),
                                    fontWeight: FontWeight.w500,
                                  ),
                                ),
                                const SizedBox(height: 4),
                                Text(
                                  '${booking.numberOfPersons} personne${booking.numberOfPersons > 1 ? 's' : ''} • ${booking.numberOfGames} partie${booking.numberOfGames > 1 ? 's' : ''}',
                                  style: Theme.of(
                                    context,
                                  ).textTheme.bodySmall?.copyWith(
                                    color:
                                        Theme.of(
                                          context,
                                        ).colorScheme.onSurfaceVariant,
                                  ),
                                ),
                              ],
                            ),
                          ),
                          Consumer<StockViewModel>(
                            builder: (context, stockVM, child) {
                              // Calculer le montant restant en temps réel
                              final currentConsumptionsTotal = stockVM
                                  .getConsumptionTotal(booking.id);
                              final realTotalPrice =
                                  booking.formulaPrice +
                                  currentConsumptionsTotal;
                              final realRemainingBalance =
                                  realTotalPrice - booking.totalPaid;

                              return Column(
                                crossAxisAlignment: CrossAxisAlignment.end,
                                children: [
                                  if (realRemainingBalance > 0 &&
                                      !booking.isCancelled)
                                    Container(
                                      padding: const EdgeInsets.symmetric(
                                        horizontal: 8,
                                        vertical: 2,
                                      ),
                                      decoration: BoxDecoration(
                                        color:
                                            Theme.of(
                                              context,
                                            ).colorScheme.secondaryContainer,
                                        borderRadius: BorderRadius.circular(4),
                                      ),
                                      child: Text(
                                        'Reste ${realRemainingBalance.toStringAsFixed(2)}€',
                                        style: TextStyle(
                                          color:
                                              Theme.of(context)
                                                  .colorScheme
                                                  .onSecondaryContainer,
                                          fontSize: 12,
                                          fontWeight: FontWeight.w500,
                                        ),
                                      ),
                                    ),
                                  if (booking.isCancelled ||
                                      realRemainingBalance <= 0)
                                    Container(
                                      padding: const EdgeInsets.symmetric(
                                        horizontal: 6,
                                        vertical: 2,
                                      ),
                                      decoration: BoxDecoration(
                                        color:
                                            booking.isCancelled
                                                ? Theme.of(
                                                  context,
                                                ).colorScheme.error
                                                : Theme.of(
                                                  context,
                                                ).colorScheme.primary,
                                        borderRadius: BorderRadius.circular(4),
                                      ),
                                      child: Text(
                                        booking.isCancelled
                                            ? 'ANNULÉE'
                                            : 'PAYÉE',
                                        style: TextStyle(
                                          color:
                                              booking.isCancelled
                                                  ? Theme.of(
                                                    context,
                                                  ).colorScheme.onError
                                                  : Theme.of(
                                                    context,
                                                  ).colorScheme.onPrimary,
                                          fontSize: 10,
                                          fontWeight: FontWeight.w600,
                                          letterSpacing: 0.5,
                                        ),
                                      ),
                                    ),
                                ],
                              );
                            },
                          ),
                          const SizedBox(width: 8),
                          // Menu popup seulement pour les réservations non passées
                          if (!_isBookingPast(booking))
                            IconButton(
                              icon: Icon(
                                Icons.more_vert,
                                size: 20,
                                color:
                                    Theme.of(
                                      context,
                                    ).colorScheme.onSurfaceVariant,
                              ),
                              onPressed: onMoreTap,
                              visualDensity: VisualDensity.compact,
                              style: IconButton.styleFrom(
                                padding: EdgeInsets.zero,
                              ),
                            ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        );
      },
    );
  }
}
