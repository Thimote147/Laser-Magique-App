/// Calcule le prix total selon la formule :
/// (prix × nbr_partie) arrondi à l'unité supérieure × nbr joueurs
double calculateTotalPrice(double price, int games, int persons) {
  return (price * games).ceilToDouble() * persons;
}
