import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../viewmodels/employee_profile_view_model.dart';
import 'edit_profile_screen.dart';

class ProfileScreen extends StatelessWidget {
  const ProfileScreen({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Consumer<EmployeeProfileViewModel>(
      builder: (context, profileVM, child) {
        return Scaffold(
          appBar: AppBar(title: Text('Profil')),
          body: SingleChildScrollView(
            child: Padding(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _buildStatsCard(profileVM, context),
                  const SizedBox(height: 20),
                  _buildPersonalInfo(profileVM, context),
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  // Carte des statistiques de travail
  Widget _buildStatsCard(
    EmployeeProfileViewModel profileVM,
    BuildContext context,
  ) {
    final colorScheme = Theme.of(context).colorScheme;
    final totalHours = profileVM.workDays.fold(
      0.0,
      (sum, day) => sum + day.hours,
    );
    final currentMonthEarnings = profileVM.getCurrentMonthEarnings();

    return Card(
      elevation: 5,
      shadowColor: colorScheme.primary.withOpacity(0.3),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Padding(
        padding: const EdgeInsets.all(20.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(Icons.insights, color: colorScheme.primary),
                const SizedBox(width: 8),
                const Text(
                  'Statistiques de travail',
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                ),
              ],
            ),
            const SizedBox(height: 16),
            Container(
              padding: const EdgeInsets.symmetric(vertical: 10),
              decoration: BoxDecoration(
                color: colorScheme.surface,
                borderRadius: BorderRadius.circular(12),
              ),
              child: Row(
                children: [
                  _buildStatItem(
                    context: context,
                    icon: Icons.euro,
                    value: '${profileVM.hourlyRate.toStringAsFixed(2)}€',
                    label: 'Taux horaire',
                  ),
                  Container(
                    height: 50,
                    width: 1,
                    color: Colors.grey.withOpacity(0.3),
                  ),
                  _buildStatItem(
                    context: context,
                    icon: Icons.access_time,
                    value: _formatHoursToHourMinutes(totalHours),
                    label: 'Total heures',
                  ),
                  Container(
                    height: 50,
                    width: 1,
                    color: Colors.grey.withOpacity(0.3),
                  ),
                  _buildStatItem(
                    context: context,
                    icon: Icons.payments,
                    value: '${currentMonthEarnings.toStringAsFixed(2)}€',
                    label: 'Ce mois',
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  // Widget pour un élément de statistique
  Widget _buildStatItem({
    required BuildContext context,
    required IconData icon,
    required String value,
    required String label,
  }) {
    final colorScheme = Theme.of(context).colorScheme;

    return Expanded(
      child: Column(
        children: [
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: colorScheme.primary.withOpacity(0.1),
              shape: BoxShape.circle,
              boxShadow: [
                BoxShadow(
                  color: colorScheme.primary.withOpacity(0.1),
                  blurRadius: 5,
                  offset: const Offset(0, 2),
                ),
              ],
            ),
            child: Icon(icon, color: colorScheme.primary, size: 24),
          ),
          const SizedBox(height: 10),
          Text(
            value,
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: colorScheme.primary,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            label,
            style: TextStyle(
              fontSize: 13,
              color: Colors.grey[700],
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }

  // Informations personnelles (email, téléphone, taux horaire)
  Widget _buildPersonalInfo(
    EmployeeProfileViewModel profileVM,
    BuildContext context,
  ) {
    final colorScheme = Theme.of(context).colorScheme;

    return Card(
      elevation: 5,
      shadowColor: colorScheme.primary.withOpacity(0.3),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Padding(
        padding: const EdgeInsets.all(15.0), // Réduit de 20 à 15
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(Icons.person, color: colorScheme.primary),
                const SizedBox(width: 8),
                const Text(
                  'Informations personnelles',
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                ),
              ],
            ),
            const SizedBox(height: 10), // Réduit de 16 à 10
            _buildProfileItem(
              icon: Icons.person,
              title: 'Prénom',
              subtitle: profileVM.firstName,
              context: context,
            ),
            const Divider(height: 1), // Hauteur minimale
            _buildProfileItem(
              icon: Icons.person_outline,
              title: 'Nom',
              subtitle: profileVM.lastName,
              context: context,
            ),
            const Divider(height: 1), // Hauteur minimale
            _buildProfileItem(
              icon: Icons.email,
              title: 'Email',
              subtitle: profileVM.email,
              context: context,
            ),
            const Divider(height: 1), // Hauteur minimale
            _buildProfileItem(
              icon: Icons.phone,
              title: 'Téléphone',
              subtitle: profileVM.phone,
              context: context,
            ),
            const SizedBox(height: 16), // Réduit de 24 à 16
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: () {
                  // Ouvrir l'écran de modification du profil
                  Navigator.of(context).push(
                    MaterialPageRoute(
                      builder: (context) => const EditProfileScreen(),
                    ),
                  );
                },
                style: ButtonStyle(
                  backgroundColor: MaterialStateProperty.resolveWith<Color>((
                    Set<MaterialState> states,
                  ) {
                    if (states.contains(MaterialState.pressed)) {
                      return colorScheme.primary.withOpacity(0.8);
                    }
                    return colorScheme.primary;
                  }),
                  foregroundColor: MaterialStateProperty.all<Color>(
                    Colors.white,
                  ),
                  padding: MaterialStateProperty.all<EdgeInsetsGeometry>(
                    const EdgeInsets.symmetric(
                      vertical: 12,
                    ), // Réduit de 16 à 12
                  ),
                  shape: MaterialStateProperty.all<RoundedRectangleBorder>(
                    RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(30),
                    ),
                  ),
                  elevation: MaterialStateProperty.all<double>(4),
                  shadowColor: MaterialStateProperty.all<Color>(
                    colorScheme.primary.withOpacity(0.4),
                  ),
                ),
                child: const Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(Icons.edit),
                    SizedBox(width: 8),
                    Text(
                      'Modifier les informations',
                      style: TextStyle(
                        fontSize: 14, // Réduit de 16 à 14
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  // Élément de profil (utilisé pour les informations personnelles)
  Widget _buildProfileItem({
    required IconData icon,
    required String title,
    required String subtitle,
    required BuildContext context,
  }) {
    final colorScheme = Theme.of(context).colorScheme;
    return ListTile(
      leading: Container(
        padding: const EdgeInsets.all(8), // Réduit de 10 à 8
        decoration: BoxDecoration(
          color: colorScheme.primary.withOpacity(0.1),
          borderRadius: BorderRadius.circular(10), // Réduit de 12 à 10
        ),
        child: Icon(
          icon,
          color: colorScheme.primary,
          size: 20,
        ), // Réduit de 22 à 20
      ),
      title: Text(
        title,
        style: const TextStyle(
          fontWeight: FontWeight.bold,
          fontSize: 15,
        ), // Réduit de 16 à 15
      ),
      subtitle: Text(
        subtitle,
        style: TextStyle(
          color: Colors.grey[800],
          fontSize: 14,
        ), // Réduit de 15 à 14
      ),
      contentPadding: EdgeInsets.zero,
      minVerticalPadding: 12, // Réduit de 16 à 12
      dense:
          true, // Ajoute cette propriété pour rendre le ListTile plus compact
    );
  }

  // Convertir les heures décimales en format heures et minutes (Xh30)
  String _formatHoursToHourMinutes(double hours) {
    int fullHours = hours.floor();
    int minutes = ((hours - fullHours) * 60).round();

    if (minutes == 0) {
      return '${fullHours}h';
    } else {
      return '${fullHours}h${minutes}';
    }
  }
}
