import 'package:flutter/material.dart';
import '../../models/booking_model.dart';

/// Widget pour afficher des marqueurs de réservation dans un calendrier
/// en distinguant les réservations annulées
class BookingCalendarMarker extends StatelessWidget {
  final Booking booking;
  final double size;

  const BookingCalendarMarker({
    super.key,
    required this.booking,
    this.size = 8.0,
  });

  @override
  Widget build(BuildContext context) {
    Color
    markerColor; // Déterminer la couleur en fonction de l'activité et du statut d'annulation
    if (booking.isCancelled) {
      markerColor = Colors.red.shade600;
    } else {
      final activityName = booking.formula.activity.name.toLowerCase();
      if (activityName.contains('laser')) {
        markerColor = Colors.red;
      } else if (activityName.contains('virtual')) {
        markerColor = Colors.blue;
      } else if (activityName.contains('arcade')) {
        markerColor = Colors.purple;
      } else {
        markerColor = Colors.indigo;
      }
    }
    return Container(
      width: size,
      height: size,
      margin: const EdgeInsets.symmetric(horizontal: 0.5),
      decoration: BoxDecoration(
        shape: booking.isCancelled ? BoxShape.rectangle : BoxShape.circle,
        color: markerColor,
        border:
            booking.isCancelled
                ? Border.all(color: Colors.white, width: 1)
                : null,
        borderRadius: booking.isCancelled ? BorderRadius.circular(2) : null,
        boxShadow:
            booking.isCancelled
                ? [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.2),
                    blurRadius: 1,
                    spreadRadius: 0,
                    offset: const Offset(0, 1),
                  ),
                ]
                : null,
      ),
    );
  }
}
