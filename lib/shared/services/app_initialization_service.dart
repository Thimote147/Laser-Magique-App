import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../features/inventory/inventory.dart';

/// Service responsable de l'initialisation des données au démarrage de l'application
class AppInitializationService {
  /// Initialise toutes les données requises au démarrage
  static Future<void> initialize(BuildContext context) async {
    // Préchargement du stock
    await _preloadStock(context);
  }

  /// Précharge les données de stock au démarrage
  static Future<void> _preloadStock(BuildContext context) async {
    try {
      final stockViewModel = Provider.of<StockViewModel>(
        context,
        listen: false,
      );
      // S'assurer que le stock est chargé
      if (!stockViewModel.isInitialized) {
        await stockViewModel.initialize();
      }
    } catch (e) {
      debugPrint('Erreur lors du préchargement du stock: $e');
      // Ne pas bloquer le démarrage de l'application en cas d'erreur
    }
  }
}
