class DailyStatistics {
  final DateTime date;
  final double fondCaisseOuverture;
  final double fondCaisseFermeture;
  final double totalBancontact;
  final double totalCash;
  final double totalVirement;
  final double totalBoissons;
  final double totalNourritures;
  final double montantCoffre;
  final List<CategoryTotal> categorieDetails;
  final List<PaymentMethodTotal> methodesPaiementDetails;

  const DailyStatistics({
    required this.date,
    required this.fondCaisseOuverture,
    required this.fondCaisseFermeture,
    required this.totalBancontact,
    required this.totalCash,
    required this.totalVirement,
    required this.totalBoissons,
    required this.totalNourritures,
    required this.montantCoffre,
    required this.categorieDetails,
    required this.methodesPaiementDetails,
  });

  double get totalRecettes => totalBancontact + totalCash + totalVirement;
  double get totalParCategorie => totalBoissons + totalNourritures;
  
  double get soldeFinal {
    return fondCaisseFermeture - fondCaisseOuverture;
  }

  DailyStatistics copyWith({
    DateTime? date,
    double? fondCaisseOuverture,
    double? fondCaisseFermeture,
    double? totalBancontact,
    double? totalCash,
    double? totalVirement,
    double? totalBoissons,
    double? totalNourritures,
    double? montantCoffre,
    List<CategoryTotal>? categorieDetails,
    List<PaymentMethodTotal>? methodesPaiementDetails,
  }) {
    return DailyStatistics(
      date: date ?? this.date,
      fondCaisseOuverture: fondCaisseOuverture ?? this.fondCaisseOuverture,
      fondCaisseFermeture: fondCaisseFermeture ?? this.fondCaisseFermeture,
      totalBancontact: totalBancontact ?? this.totalBancontact,
      totalCash: totalCash ?? this.totalCash,
      totalVirement: totalVirement ?? this.totalVirement,
      totalBoissons: totalBoissons ?? this.totalBoissons,
      totalNourritures: totalNourritures ?? this.totalNourritures,
      montantCoffre: montantCoffre ?? this.montantCoffre,
      categorieDetails: categorieDetails ?? this.categorieDetails,
      methodesPaiementDetails: methodesPaiementDetails ?? this.methodesPaiementDetails,
    );
  }
}

class CategoryTotal {
  final String category;
  final String categoryDisplayName;
  final double total;
  final int itemCount;

  const CategoryTotal({
    required this.category,
    required this.categoryDisplayName,
    required this.total,
    required this.itemCount,
  });
}

class PaymentMethodTotal {
  final String method;
  final String methodDisplayName;
  final double total;
  final int transactionCount;

  const PaymentMethodTotal({
    required this.method,
    required this.methodDisplayName,
    required this.total,
    required this.transactionCount,
  });
}