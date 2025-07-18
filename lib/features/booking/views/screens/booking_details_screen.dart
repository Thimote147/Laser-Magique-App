import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../../inventory/viewmodels/stock_view_model.dart';
import '../../../../shared/user_provider.dart';
import '../../../../shared/widgets/dialogs.dart';
import '../../models/booking_model.dart';
import '../../viewmodels/booking_view_model.dart';
import '../widgets/booking_consumption_widget.dart';
import '../widgets/booking_payment_widget.dart';
import 'booking_edit_screen.dart';
import '../widgets/game_sessions_modal.dart';

// Fonction utilitaire pour vérifier si une réservation est passée
bool _isBookingPast(Booking booking) {
  final now = DateTime.now();
  final bookingDate = booking.dateTimeLocal;
  return bookingDate.isBefore(DateTime(now.year, now.month, now.day));
}

class BookingDetailsScreen extends StatefulWidget {
  final Booking booking;

  const BookingDetailsScreen({super.key, required this.booking});

  @override
  State<BookingDetailsScreen> createState() => _BookingDetailsScreenState();
}

class _BookingDetailsScreenState extends State<BookingDetailsScreen> {
  late Booking _currentBooking;

  @override
  void initState() {
    super.initState();
    _currentBooking = widget.booking;
    _refreshBooking();
  }

  @override
  void didUpdateWidget(BookingDetailsScreen oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.booking.id != widget.booking.id) {
      _currentBooking = widget.booking;
      _refreshBooking();
    }
  }

  Future<void> _refreshBooking() async {
    try {
      if (!mounted) return;
      final bookingViewModel = Provider.of<BookingViewModel>(
        context,
        listen: false,
      );

      // Invalider le cache des consommations APRÈS le build pour éviter les erreurs
      // en utilisant Future.microtask pour s'assurer que c'est exécuté après le build
      Future.microtask(() {
        if (mounted) {
          final stockViewModel = Provider.of<StockViewModel>(
            context,
            listen: false,
          );
          stockViewModel.invalidateConsumptionsCacheForBooking(
            widget.booking.id,
          );
        }
      });

      final updatedBooking = await bookingViewModel.getBookingDetails(
        widget.booking.id,
      );
      if (mounted) {
        setState(() {
          _currentBooking = updatedBooking;
        });
      }
    } catch (e) {
      // Silent error handling
    }
  }

  Future<void> _makePhoneCall(String phoneNumber) async {
    final Uri launchUri = Uri.parse('tel:$phoneNumber');

    try {
      if (await canLaunchUrl(launchUri)) {
        await launchUrl(launchUri, mode: LaunchMode.externalApplication);
      } else {
        if (mounted) {
          await showDialog(
            context: context,
            builder: (context) => CustomErrorDialog(
              title: 'Erreur d\'appel',
              content: 'Impossible d\'ouvrir l\'application téléphone',
            ),
          );
        }
      }
    } catch (e) {
      if (mounted) {
        await showDialog(
          context: context,
          builder: (context) => CustomErrorDialog(
            title: 'Erreur d\'appel',
            content: 'Erreur lors de l\'appel: $e',
          ),
        );
      }
    }
  }

  Future<void> _sendEmail(String email) async {
    final String subject = Uri.encodeComponent(
      'Concernant votre réservation Laser Magique',
    );
    final String body = Uri.encodeComponent(
      'Bonjour ${_currentBooking.firstName},\n\n',
    );
    final Uri launchUri = Uri.parse(
      'mailto:$email?subject=$subject&body=$body',
    );

    try {
      if (await canLaunchUrl(launchUri)) {
        await launchUrl(launchUri, mode: LaunchMode.externalApplication);
      } else {
        if (mounted) {
          await showDialog(
            context: context,
            builder: (context) => CustomErrorDialog(
              title: 'Erreur d\'email',
              content: 'Impossible d\'ouvrir l\'application email',
            ),
          );
        }
      }
    } catch (e) {
      if (mounted) {
        await showDialog(
          context: context,
          builder: (context) => CustomErrorDialog(
            title: 'Erreur d\'email',
            content: 'Erreur lors de l\'envoi d\'email: $e',
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<UserProvider>(
      builder: (context, userProvider, child) {
        final isAdmin = userProvider.isAdmin;

        return Scaffold(
          appBar: AppBar(
            title: Text(
              '${_currentBooking.firstName} ${_currentBooking.lastName ?? ""}',
            ),
            actions: [
              // Bouton Modifier dans la barre d'actions (seulement si pas passé)
              if (!_isBookingPast(_currentBooking))
                IconButton(
                  icon: Icon(
                    Icons.edit,
                    color: Theme.of(context).colorScheme.primary,
                  ),
                  tooltip: 'Modifier la réservation',
                  onPressed: () {
                    Navigator.of(context)
                        .push(
                          MaterialPageRoute(
                            builder:
                                (context) =>
                                    BookingEditScreen(booking: _currentBooking),
                          ),
                        )
                        .then((_) => _refreshBooking());
                  },
                ),
              PopupMenuButton<String>(
                icon: Icon(
                  Icons.more_vert,
                  color: Theme.of(context).colorScheme.onSurface,
                ),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
                elevation: 4,
                itemBuilder:
                    (context) {
                      final isBookingPast = _isBookingPast(_currentBooking);
                      return [
                      // Options de contact (toujours disponibles si admin)
                      if (isAdmin) ...[
                        if (_currentBooking.email != null)
                          PopupMenuItem<String>(
                            value: 'email',
                            child: Row(
                              children: [
                                Icon(
                                  Icons.email,
                                  size: 20,
                                  color: Colors.green,
                                ),
                                const SizedBox(width: 12),
                                Text(
                                  'Envoyer un email',
                                  style: Theme.of(context).textTheme.bodyMedium,
                                ),
                              ],
                            ),
                          ),
                        if (_currentBooking.phone != null)
                          PopupMenuItem<String>(
                            value: 'call',
                            child: Row(
                              children: [
                                Icon(
                                  Icons.phone,
                                  size: 20,
                                  color: Colors.green,
                                ),
                                const SizedBox(width: 12),
                                Text(
                                  'Appeler',
                                  style: Theme.of(context).textTheme.bodyMedium,
                                ),
                              ],
                            ),
                          ),
                        if ((_currentBooking.email != null ||
                            _currentBooking.phone != null) && !isBookingPast)
                          const PopupMenuDivider(),
                      ],

                      // Option d'annulation/restauration (tous les utilisateurs, sauf passées)
                      if (!isBookingPast)
                        PopupMenuItem<String>(
                        value: 'toggle_cancel',
                        child: Row(
                          children: [
                            Icon(
                              _currentBooking.isCancelled
                                  ? Icons.restore
                                  : Icons.cancel,
                              size: 20,
                              color:
                                  _currentBooking.isCancelled
                                      ? Colors.green
                                      : Colors.orange,
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Text(
                                _currentBooking.isCancelled
                                    ? 'Restaurer la réservation'
                                    : 'Marquer comme annulée',
                                style: Theme.of(
                                  context,
                                ).textTheme.bodyMedium?.copyWith(
                                  color:
                                      _currentBooking.isCancelled
                                          ? Colors.green
                                          : Colors.orange,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),

                      // Option de suppression (admin uniquement, sauf passées)
                      if (isAdmin && !isBookingPast) ...[
                        const PopupMenuDivider(),
                        PopupMenuItem<String>(
                          value: 'delete',
                          child: Row(
                            children: [
                              Icon(Icons.delete, size: 20, color: Colors.red),
                              const SizedBox(width: 12),
                              Text(
                                'Supprimer la réservation',
                                style: Theme.of(context).textTheme.bodyMedium
                                    ?.copyWith(color: Colors.red),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ];
                    },
                onSelected: (String value) async {
                  switch (value) {
                    case 'email':
                      if (_currentBooking.email != null) {
                        await _sendEmail(_currentBooking.email!);
                      }
                      break;
                    case 'call':
                      if (_currentBooking.phone != null) {
                        await _makePhoneCall(_currentBooking.phone!);
                      }
                      break;
                    case 'toggle_cancel':
                      await Provider.of<BookingViewModel>(
                        context,
                        listen: false,
                      ).toggleCancellationStatus(_currentBooking.id);
                      await _refreshBooking();
                      if (context.mounted) {
                        await showDialog(
                          context: context,
                          builder: (context) => CustomSuccessDialog(
                            title: _currentBooking.isCancelled ? 'Réservation restaurée' : 'Réservation annulée',
                            content: _currentBooking.isCancelled
                                ? 'La réservation a été restaurée avec succès'
                                : 'La réservation a été marquée comme annulée',
                            autoClose: true,
                            autoCloseDuration: const Duration(seconds: 2),
                          ),
                        );
                      }
                      break;
                    case 'delete':
                      final navigator = Navigator.of(context);
                      final bookingViewModel = Provider.of<BookingViewModel>(
                        context,
                        listen: false,
                      );

                      await Future.delayed(const Duration(milliseconds: 100));
                      if (!context.mounted) return;

                      final confirmed = await showDialog<bool>(
                        context: context,
                        builder: (dialogContext) => CustomConfirmDialog(
                          title: 'Confirmer la suppression',
                          content: 'Êtes-vous sûr de vouloir supprimer définitivement la réservation de ${_currentBooking.firstName} ${_currentBooking.lastName ?? ""} ?',
                          confirmText: 'Supprimer',
                          cancelText: 'Annuler',
                          icon: Icons.warning_rounded,
                          iconColor: Theme.of(context).colorScheme.error,
                          confirmColor: Theme.of(context).colorScheme.error,
                          onConfirm: () => Navigator.of(dialogContext).pop(true),
                          onCancel: () => Navigator.of(dialogContext).pop(false),
                        ),
                      );

                      if (!mounted) return;
                      if (confirmed == true) {
                        bookingViewModel.removeBooking(_currentBooking.id);
                        navigator.pop();
                        
                        // Afficher le dialog de succès
                        if (mounted) {
                          await showDialog(
                            context: context,
                            barrierDismissible: true,
                            builder: (context) => CustomSuccessDialog(
                              title: 'Suppression réussie',
                              content: 'La réservation de ${_currentBooking.firstName} ${_currentBooking.lastName ?? ""} a été supprimée avec succès',
                              autoClose: true,
                              autoCloseDuration: const Duration(seconds: 3),
                            ),
                          );
                        }
                      }
                      break;
                  }
                },
              ),
            ],
          ),
          body: RefreshIndicator(
            onRefresh: _refreshBooking,
            child: SingleChildScrollView(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                if (_currentBooking.isCancelled)
                  Container(
                    margin: const EdgeInsets.only(bottom: 12),
                    padding: const EdgeInsets.symmetric(
                      horizontal: 12,
                      vertical: 8,
                    ),
                    decoration: BoxDecoration(
                      color: Theme.of(context).colorScheme.errorContainer,
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Row(
                      children: [
                        Icon(
                          Icons.cancel,
                          size: 18,
                          color: Theme.of(context).colorScheme.error,
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            'Réservation annulée',
                            style: TextStyle(
                              fontWeight: FontWeight.bold,
                              color: Theme.of(context).colorScheme.error,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),

                // Section Client (affiché seulement si admin)
                if (isAdmin) ...[
                  Padding(
                    padding: const EdgeInsets.only(left: 4, bottom: 8),
                    child: Row(
                      children: [
                        Icon(
                          Icons.person_rounded,
                          size: 20,
                          color: Theme.of(context).colorScheme.primary,
                        ),
                        const SizedBox(width: 8),
                        Text(
                          'Informations client',
                          style: Theme.of(
                            context,
                          ).textTheme.titleMedium?.copyWith(
                            color: Theme.of(context).colorScheme.onSurface,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ],
                    ),
                  ),
                  Card(
                    elevation: 0,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                      side: BorderSide(
                        color: Theme.of(
                          context,
                        ).colorScheme.outline.withValues(alpha: 0.2),
                      ),
                    ),
                    child: Container(
                      width: double.infinity,
                      padding: const EdgeInsets.all(12),
                      child: Column(
                        children: [
                          if (_currentBooking.email != null)
                            Container(
                              width: double.infinity,
                              decoration: BoxDecoration(
                                color: Theme.of(context)
                                    .colorScheme
                                    .surfaceContainerHighest
                                    .withValues(alpha: 0.3),
                                borderRadius: BorderRadius.circular(8),
                              ),
                              padding: const EdgeInsets.symmetric(
                                horizontal: 16,
                                vertical: 12,
                              ),
                              child: Row(
                                children: [
                                  Icon(
                                    Icons.email_rounded,
                                    size: 20,
                                    color:
                                        Theme.of(context).colorScheme.primary,
                                  ),
                                  const SizedBox(width: 12),
                                  Expanded(
                                    child: Column(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.start,
                                      children: [
                                        Text(
                                          'Email',
                                          style: Theme.of(
                                            context,
                                          ).textTheme.bodySmall?.copyWith(
                                            color:
                                                Theme.of(
                                                  context,
                                                ).colorScheme.onSurfaceVariant,
                                          ),
                                        ),
                                        const SizedBox(height: 4),
                                        Text(
                                          _currentBooking.email ?? '',
                                          style: Theme.of(
                                            context,
                                          ).textTheme.titleMedium?.copyWith(
                                            fontWeight: FontWeight.w500,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          if (_currentBooking.email != null &&
                              _currentBooking.phone != null)
                            const SizedBox(height: 8),
                          if (_currentBooking.phone != null)
                            Container(
                              width: double.infinity,
                              decoration: BoxDecoration(
                                color: Theme.of(context)
                                    .colorScheme
                                    .surfaceContainerHighest
                                    .withValues(alpha: 0.3),
                                borderRadius: BorderRadius.circular(8),
                              ),
                              padding: const EdgeInsets.symmetric(
                                horizontal: 16,
                                vertical: 12,
                              ),
                              child: Row(
                                children: [
                                  Icon(
                                    Icons.phone_rounded,
                                    size: 20,
                                    color:
                                        Theme.of(context).colorScheme.primary,
                                  ),
                                  const SizedBox(width: 12),
                                  Expanded(
                                    child: Column(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.start,
                                      children: [
                                        Text(
                                          'Téléphone',
                                          style: Theme.of(
                                            context,
                                          ).textTheme.bodySmall?.copyWith(
                                            color:
                                                Theme.of(
                                                  context,
                                                ).colorScheme.onSurfaceVariant,
                                          ),
                                        ),
                                        const SizedBox(height: 4),
                                        Text(
                                          _currentBooking.phone ?? '',
                                          style: Theme.of(
                                            context,
                                          ).textTheme.titleMedium?.copyWith(
                                            fontWeight: FontWeight.w500,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                ],
                              ),
                            ),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),
                ],

                // Section Activité
                Padding(
                  padding: const EdgeInsets.only(left: 4, bottom: 8),
                  child: Row(
                    children: [
                      Icon(
                        Icons.sports_esports_rounded,
                        size: 20,
                        color: Theme.of(context).colorScheme.primary,
                      ),
                      const SizedBox(width: 8),
                      Text(
                        'Détails de l\'activité',
                        style: Theme.of(
                          context,
                        ).textTheme.titleMedium?.copyWith(
                          color: Theme.of(context).colorScheme.onSurface,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                  ),
                ),
                Card(
                  elevation: 0,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                    side: BorderSide(
                      color: Theme.of(
                        context,
                      ).colorScheme.outline.withValues(alpha: 0.2),
                    ),
                  ),
                  child: Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(12),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Container(
                          width: double.infinity,
                          decoration: BoxDecoration(
                            color: Theme.of(context)
                                .colorScheme
                                .surfaceContainerHighest
                                .withValues(alpha: 0.3),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          padding: const EdgeInsets.symmetric(
                            horizontal: 16,
                            vertical: 12,
                          ),
                          child: Row(
                            children: [
                              Expanded(
                                flex: 2,
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      'Formule',
                                      style: Theme.of(
                                        context,
                                      ).textTheme.bodySmall?.copyWith(
                                        color:
                                            Theme.of(
                                              context,
                                            ).colorScheme.onSurfaceVariant,
                                      ),
                                    ),
                                    const SizedBox(height: 4),
                                    Text(
                                      _currentBooking.formula.name,
                                      style: Theme.of(
                                        context,
                                      ).textTheme.titleMedium?.copyWith(
                                        fontWeight: FontWeight.w500,
                                      ),
                                    ),
                                    Text(
                                      _currentBooking.formula.activity.name,
                                      style: Theme.of(
                                        context,
                                      ).textTheme.bodyMedium?.copyWith(
                                        color:
                                            Theme.of(
                                              context,
                                            ).colorScheme.onSurfaceVariant,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                              SizedBox(
                                height: 48,
                                child: VerticalDivider(
                                  width: 32,
                                  color: Theme.of(
                                    context,
                                  ).colorScheme.outline.withValues(alpha: 0.2),
                                ),
                              ),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    Text(
                                      'Personnes',
                                      style: Theme.of(
                                        context,
                                      ).textTheme.bodySmall?.copyWith(
                                        color:
                                            Theme.of(
                                              context,
                                            ).colorScheme.onSurfaceVariant,
                                      ),
                                    ),
                                    const SizedBox(height: 4),
                                    Text(
                                      '${_currentBooking.numberOfPersons}',
                                      style: Theme.of(
                                        context,
                                      ).textTheme.titleMedium?.copyWith(
                                        fontWeight: FontWeight.w500,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                              SizedBox(
                                height: 48,
                                child: VerticalDivider(
                                  width: 32,
                                  color: Theme.of(
                                    context,
                                  ).colorScheme.outline.withValues(alpha: 0.2),
                                ),
                              ),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    Text(
                                      'Parties',
                                      style: Theme.of(
                                        context,
                                      ).textTheme.bodySmall?.copyWith(
                                        color:
                                            Theme.of(
                                              context,
                                            ).colorScheme.onSurfaceVariant,
                                      ),
                                    ),
                                    const SizedBox(height: 4),
                                    Text(
                                      '${_currentBooking.numberOfGames}',
                                      style: Theme.of(
                                        context,
                                      ).textTheme.titleMedium?.copyWith(
                                        fontWeight: FontWeight.w500,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ),
                        ),
                        // Bouton Gérer les parties (si plus d'une partie et formule groupe)
                        if (_currentBooking.numberOfGames > 1 && 
                            _currentBooking.formula.name.toLowerCase().contains('groupe')) ...[
                          const SizedBox(height: 12),
                          SizedBox(
                            width: double.infinity,
                            child: OutlinedButton.icon(
                              onPressed: _isBookingPast(_currentBooking) ? null : () {
                                showModalBottomSheet(
                                  context: context,
                                  isScrollControlled: true,
                                  backgroundColor: Colors.transparent,
                                  isDismissible: true, // Permet de fermer en cliquant à l'extérieur
                                  enableDrag: true, // Permet de fermer en glissant vers le bas
                                  builder: (context) => GameSessionsModal(
                                    booking: _currentBooking,
                                    onSessionsUpdated: _refreshBooking,
                                  ),
                                );
                              },
                              icon: Icon(
                                Icons.sports_esports,
                                size: 20,
                                color: Theme.of(context).colorScheme.primary,
                              ),
                              label: Text(
                                'Gérer les parties individuelles',
                                style: TextStyle(
                                  color: Theme.of(context).colorScheme.primary,
                                ),
                              ),
                              style: OutlinedButton.styleFrom(
                                side: BorderSide(
                                  color: Theme.of(context).colorScheme.primary,
                                ),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(8),
                                ),
                                padding: const EdgeInsets.symmetric(vertical: 12),
                              ),
                            ),
                          ),
                        ],
                      ],
                    ),
                  ),
                ),

                const SizedBox(height: 16),

                // Section Date et Heure
                Padding(
                  padding: const EdgeInsets.only(left: 4, bottom: 8),
                  child: Row(
                    children: [
                      Icon(
                        Icons.calendar_today_rounded,
                        size: 20,
                        color: Theme.of(context).colorScheme.primary,
                      ),
                      const SizedBox(width: 8),
                      Text(
                        'Date et heure',
                        style: Theme.of(
                          context,
                        ).textTheme.titleMedium?.copyWith(
                          color: Theme.of(context).colorScheme.onSurface,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                  ),
                ),
                Card(
                  elevation: 0,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                    side: BorderSide(
                      color: Theme.of(
                        context,
                      ).colorScheme.outline.withValues(alpha: 0.2),
                    ),
                  ),
                  child: Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(12),
                    child: Container(
                      width: double.infinity,
                      decoration: BoxDecoration(
                        color: Theme.of(context)
                            .colorScheme
                            .surfaceContainerHighest
                            .withValues(alpha: 0.3),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      padding: const EdgeInsets.symmetric(
                        horizontal: 16,
                        vertical: 12,
                      ),
                      child: Row(
                        children: [
                          Expanded(
                            child: Row(
                              children: [
                                Icon(
                                  Icons.calendar_month_rounded,
                                  size: 20,
                                  color: Theme.of(context).colorScheme.primary,
                                ),
                                const SizedBox(width: 12),
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        'Date',
                                        style: Theme.of(
                                          context,
                                        ).textTheme.bodySmall?.copyWith(
                                          color:
                                              Theme.of(
                                                context,
                                              ).colorScheme.onSurfaceVariant,
                                        ),
                                      ),
                                      const SizedBox(height: 4),
                                      Text(
                                        DateFormat.yMMMMd(
                                          'fr_FR',
                                        ).format(_currentBooking.dateTimeLocal),
                                        style: Theme.of(
                                          context,
                                        ).textTheme.titleMedium?.copyWith(
                                          fontWeight: FontWeight.w500,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ],
                            ),
                          ),
                          SizedBox(
                            height: 48,
                            child: VerticalDivider(
                              width: 32,
                              color: Theme.of(
                                context,
                              ).colorScheme.outline.withValues(alpha: 0.2),
                            ),
                          ),
                          Expanded(
                            child: Row(
                              children: [
                                Icon(
                                  Icons.access_time_rounded,
                                  size: 20,
                                  color: Theme.of(context).colorScheme.primary,
                                ),
                                const SizedBox(width: 12),
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        'Heure',
                                        style: Theme.of(
                                          context,
                                        ).textTheme.bodySmall?.copyWith(
                                          color:
                                              Theme.of(
                                                context,
                                              ).colorScheme.onSurfaceVariant,
                                        ),
                                      ),
                                      const SizedBox(height: 4),
                                      Text(
                                        DateFormat.Hm(
                                          'fr_FR',
                                        ).format(_currentBooking.dateTimeLocal),
                                        style: Theme.of(
                                          context,
                                        ).textTheme.titleMedium?.copyWith(
                                          fontWeight: FontWeight.w500,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),

                const SizedBox(height: 16),

                // Section Paiements
                Padding(
                  padding: const EdgeInsets.only(left: 4, bottom: 8),
                  child: Row(
                    children: [
                      Icon(
                        Icons.payments_rounded,
                        size: 20,
                        color: Theme.of(context).colorScheme.primary,
                      ),
                      const SizedBox(width: 8),
                      Text(
                        'Paiements',
                        style: Theme.of(
                          context,
                        ).textTheme.titleMedium?.copyWith(
                          color: Theme.of(context).colorScheme.onSurface,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                  ),
                ),
                Card(
                  elevation: 0,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                    side: BorderSide(
                      color: Theme.of(
                        context,
                      ).colorScheme.outline.withValues(alpha: 0.2),
                    ),
                  ),
                  child: Padding(
                    padding: const EdgeInsets.all(12),
                    child: BookingPaymentWidget(booking: _currentBooking),
                  ),
                ),

                const SizedBox(height: 16),

                // Section Consommations
                Padding(
                  padding: const EdgeInsets.only(left: 4, bottom: 8),
                  child: Row(
                    children: [
                      Icon(
                        Icons.local_bar_rounded,
                        size: 20,
                        color: Theme.of(context).colorScheme.primary,
                      ),
                      const SizedBox(width: 8),
                      Text(
                        'Consommations',
                        style: Theme.of(
                          context,
                        ).textTheme.titleMedium?.copyWith(
                          color: Theme.of(context).colorScheme.onSurface,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                  ),
                ),
                Card(
                  elevation: 0,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                    side: BorderSide(
                      color: Theme.of(
                        context,
                      ).colorScheme.outline.withValues(alpha: 0.2),
                    ),
                  ),
                  child: Padding(
                    padding: const EdgeInsets.all(12),
                    child: BookingConsumptionWidget(
                      booking: _currentBooking,
                      onBookingUpdated: _refreshBooking,
                    ),
                  ),
                ),
              ],
            ),
            ),
          ),
        );
      },
    );
  }
}
