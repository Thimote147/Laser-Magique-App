/// Calcule le prix total selon la formule :
/// (prix_unitaire × nbr_parties) arrondi au dixième supérieur × nbr_joueurs
double calculateTotalPrice(double price, int games, int persons) {
  // Calculer le prix pour une personne et l'arrondir au dixième supérieur
  double pricePerPersonAllGames = price * games;
  // Arrondir au dixième supérieur : multiplier par 10, arrondir à l'entier supérieur, diviser par 10
  double roundedPricePerPerson = (pricePerPersonAllGames * 10).ceilToDouble() / 10;
  
  // Multiplier par le nombre de joueurs
  return roundedPricePerPerson * persons;
}
