import 'package:flutter/material.dart';

/// Utilitaire pour appliquer un style cohérent aux textes des réservations annulées
class CancelledTextStyle {
  /// Applique le style "annulé" à un TextStyle existant
  static TextStyle apply(TextStyle? baseStyle, bool isCancelled) {
    if (!isCancelled) return baseStyle ?? const TextStyle();

    return (baseStyle ?? const TextStyle()).copyWith(
      decoration: TextDecoration.lineThrough,
      color: Colors.grey.shade600,
      decorationColor: Colors.red.shade300,
      decorationThickness: 2.0,
      decorationStyle: TextDecorationStyle.solid,
    );
  }

  /// Crée un TextStyle avec une opacité réduite pour les éléments annulés
  static TextStyle withOpacity(TextStyle? baseStyle, bool isCancelled) {
    if (!isCancelled) return baseStyle ?? const TextStyle();

    return (baseStyle ?? const TextStyle()).copyWith(
      color: (baseStyle?.color ?? Colors.black).withOpacity(0.5),
      fontStyle: FontStyle.italic,
    );
  }
}
