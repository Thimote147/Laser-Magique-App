import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../profile/viewmodels/employee_profile_view_model.dart';
import '../../viewmodels/settings_view_model.dart';
import 'appearance_screen.dart';
import '../../../../shared/activity_formula_screen.dart';
import '../../../auth/services/auth_service.dart';
import '../../../auth/views/screens/auth_view.dart';
import '../../../equipment/views/screens/equipment_management_screen.dart';
import '../widgets/settings_profile_preview.dart';
import '../../../../shared/widgets/custom_dialog.dart';
import '../widgets/settings_section_header.dart';
import '../widgets/settings_item.dart';
import '../widgets/settings_toggle_item.dart';

class SettingsScreen extends StatelessWidget {
  const SettingsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final profileVM = Provider.of<EmployeeProfileViewModel>(context);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Paramètres'),
        actions: [
          IconButton(
            icon: const Icon(Icons.logout),
            tooltip: 'Se déconnecter',
            onPressed: () async {
              final navigator = Navigator.of(context);
              await Provider.of<AuthService>(context, listen: false).signOut();
              navigator.pushAndRemoveUntil(
                MaterialPageRoute(builder: (_) => const AuthView()),
                (route) => false,
              );
            },
          ),
        ],
      ),
      body: ListView(
        padding: const EdgeInsets.symmetric(horizontal: 16),
        children: [
          const SizedBox(height: 8),
          // Prévisualisation du profil
          const SettingsProfilePreview(),

          const SizedBox(height: 24),
          // Section Application
          const SettingsSectionHeader(
            title: 'Application',
            icon: Icons.settings_rounded,
          ),

          // Notifications
          Consumer<SettingsViewModel>(
            builder: (context, settingsVM, child) => SettingsToggleItem(
              icon: Icons.notifications,
              title: 'Notifications',
              subtitle: 'Activer ou désactiver les notifications',
              value: settingsVM.notificationsEnabled,
              onChanged: (value) {
                settingsVM.toggleNotifications(value);
                showDialog(
                  context: context,
                  builder: (context) => CustomSuccessDialog(
                    title: 'Notifications',
                    content: value
                        ? 'Notifications activées'
                        : 'Notifications désactivées',
                    autoClose: true,
                    autoCloseDuration: Duration(seconds: 1),
                  ),
                );
              },
            ),
          ),

          // Apparence
          Consumer<SettingsViewModel>(
            builder: (context, settingsVM, child) => SettingsItem(
              icon: Icons.color_lens,
              title: 'Apparence',
              subtitle: _getThemeModeSubtitle(settingsVM.themeMode),
              onTap: () {
                Navigator.of(context).push(
                  MaterialPageRoute(
                    builder: (context) => const AppearanceScreen(),
                  ),
                );
              },
            ),
          ),

          // Formules et activités (visible uniquement pour admin)
          if (profileVM.role == UserRole.admin)
            SettingsItem(
              icon: Icons.sports_esports,
              title: 'Formules et activités',
              subtitle: 'Gérer les activités et leurs formules',
              onTap: () {
                Navigator.of(context).push(
                  MaterialPageRoute(
                    builder: (context) => const ActivityFormulaScreen(),
                  ),
                );
              },
            ),

          // Gestion du matériel
          SettingsItem(
            icon: Icons.build,
            title: 'Gestion du matériel',
            subtitle: 'Voir et gérer l\'état du matériel',
            onTap: () {
              Navigator.of(context).push(
                MaterialPageRoute(
                  builder: (context) => const EquipmentManagementScreen(),
                ),
              );
            },
          ),

          const SizedBox(height: 24),

          // Section Support
          const SettingsSectionHeader(
            title: 'Support',
            icon: Icons.help_outline_rounded,
          ),

          // Aide
          SettingsItem(
            icon: Icons.help,
            title: 'Aide',
            subtitle: 'Consulter l\'aide et les guides',
            onTap: () {
              showDialog(
                context: context,
                builder: (context) => CustomDialog(
                  title: 'Aide',
                  titleIcon: Icon(Icons.help, color: Colors.blue),
                  content: SingleChildScrollView(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(
                          'Guide d\'utilisation complet',
                          style: Theme.of(context).textTheme.titleMedium?.copyWith(
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        SizedBox(height: 16),
                        
                        ..._buildHelpSections(context),
                        
                        SizedBox(height: 16),
                        Text(
                          'Support technique',
                          style: Theme.of(context).textTheme.titleMedium?.copyWith(
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        SizedBox(height: 8),
                        Text(
                          'Pour toute assistance technique ou question sur l\'utilisation de l\'application, contactez le support. L\'application se synchronise automatiquement avec la base de données en temps réel.',
                          style: Theme.of(context).textTheme.bodyMedium,
                        ),
                      ],
                    ),
                  ),
                  actions: [
                    TextButton(
                      onPressed: () => Navigator.of(context).pop(),
                      child: Text('Fermer'),
                    ),
                  ],
                ),
              );
            },
          ),

          // À propos
          SettingsItem(
            icon: Icons.info,
            title: 'À propos',
            subtitle: 'Informations sur l\'application',
            onTap: () {
              showDialog(
                context: context,
                builder: (context) => CustomDialog(
                  title: 'À propos',
                  titleIcon: Icon(Icons.info, color: Colors.blue),
                  content: SingleChildScrollView(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Center(
                          child: Column(
                            children: [
                              Container(
                                width: 80,
                                height: 80,
                                decoration: BoxDecoration(
                                  gradient: LinearGradient(
                                    colors: [
                                      Theme.of(context).colorScheme.primary,
                                      Theme.of(context).colorScheme.primaryContainer,
                                    ],
                                    begin: Alignment.topLeft,
                                    end: Alignment.bottomRight,
                                  ),
                                  borderRadius: BorderRadius.circular(20),
                                  boxShadow: [
                                    BoxShadow(
                                      color: Theme.of(context).colorScheme.primary.withValues(alpha: 0.3),
                                      blurRadius: 8,
                                      offset: Offset(0, 4),
                                    ),
                                  ],
                                ),
                                child: Icon(
                                  Icons.auto_awesome,
                                  size: 40,
                                  color: Colors.white,
                                ),
                              ),
                              SizedBox(height: 20),
                              Text(
                                'Laser Magique App',
                                style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                                  fontWeight: FontWeight.bold,
                                  color: Theme.of(context).colorScheme.primary,
                                ),
                              ),
                              SizedBox(height: 8),
                              Container(
                                padding: EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                                decoration: BoxDecoration(
                                  color: Theme.of(context).colorScheme.primaryContainer,
                                  borderRadius: BorderRadius.circular(12),
                                ),
                                child: Text(
                                  'Version 0.2.1',
                                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                                    fontWeight: FontWeight.w500,
                                    color: Theme.of(context).colorScheme.primary,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                        SizedBox(height: 32),
                        
                        Text(
                          'À propos de l\'application',
                          style: Theme.of(context).textTheme.titleMedium?.copyWith(
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        SizedBox(height: 12),
                        Text(
                          'Laser Magique App est une solution complète de gestion dédiée aux centres de loisirs et de divertissement. Conçue spécifiquement pour optimiser la gestion quotidienne des activités, cette application moderne offre une interface intuitive et des fonctionnalités avancées pour une expérience utilisateur exceptionnelle.',
                          style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                            height: 1.5,
                          ),
                        ),
                        SizedBox(height: 20),
                        
                        Text(
                          'Fonctionnalités principales',
                          style: Theme.of(context).textTheme.titleMedium?.copyWith(
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        SizedBox(height: 12),
                        _buildFeatureItem(context, Icons.event_available, 'Gestion complète des réservations avec calendrier interactif'),
                        _buildFeatureItem(context, Icons.inventory_2, 'Système de gestion de stock en temps réel avec alertes'),
                        _buildFeatureItem(context, Icons.analytics, 'Analyses financières et rapports détaillés'),
                        _buildFeatureItem(context, Icons.groups, 'Base de données clients avec détection de doublons'),
                        _buildFeatureItem(context, Icons.sports_esports, 'Gestion des sessions de jeu et consommations'),
                        _buildFeatureItem(context, Icons.build, 'Suivi du matériel et maintenance'),
                        _buildFeatureItem(context, Icons.notifications_active, 'Système de notifications en temps réel'),
                        _buildFeatureItem(context, Icons.admin_panel_settings, 'Gestion multi-utilisateurs avec rôles'),
                        _buildFeatureItem(context, Icons.picture_as_pdf, 'Export PDF des rapports et statistiques'),
                        _buildFeatureItem(context, Icons.sync, 'Synchronisation automatique multi-appareils'),
                        
                        SizedBox(height: 20),
                        
                        Text(
                          'Technologies utilisées',
                          style: Theme.of(context).textTheme.titleMedium?.copyWith(
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        SizedBox(height: 12),
                        _buildTechItem(context, 'Flutter', 'Framework de développement mobile'),
                        _buildTechItem(context, 'Supabase', 'Base de données en temps réel'),
                        _buildTechItem(context, 'Firebase', 'Services de notifications push'),
                        _buildTechItem(context, 'Material Design', 'Interface utilisateur moderne'),
                        
                        SizedBox(height: 20),
                        
                        Text(
                          'Informations système',
                          style: Theme.of(context).textTheme.titleMedium?.copyWith(
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        SizedBox(height: 12),
                        _buildInfoRow(context, 'Plateforme', 'iOS, Android, Web, Desktop'),
                        _buildInfoRow(context, 'Langue', 'Français'),
                        _buildInfoRow(context, 'Environnement', 'Flutter ${_getFlutterVersion()}'),
                        _buildInfoRow(context, 'Base de données', 'PostgreSQL (Supabase)'),
                        _buildInfoRow(context, 'Synchronisation', 'Temps réel'),
                        
                        SizedBox(height: 24),
                        
                        Container(
                          padding: EdgeInsets.all(16),
                          decoration: BoxDecoration(
                            color: Theme.of(context).colorScheme.surfaceContainerHighest,
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(
                              color: Theme.of(context).colorScheme.outline.withValues(alpha: 0.2),
                            ),
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                children: [
                                  Icon(
                                    Icons.security,
                                    size: 20,
                                    color: Theme.of(context).colorScheme.primary,
                                  ),
                                  SizedBox(width: 8),
                                  Text(
                                    'Sécurité et confidentialité',
                                    style: Theme.of(context).textTheme.titleSmall?.copyWith(
                                      fontWeight: FontWeight.w600,
                                    ),
                                  ),
                                ],
                              ),
                              SizedBox(height: 8),
                              Text(
                                'Toutes les données sont chiffrées et stockées de manière sécurisée. L\'application respecte les normes de protection des données personnelles et garantit la confidentialité des informations clients.',
                                style: Theme.of(context).textTheme.bodySmall,
                              ),
                            ],
                          ),
                        ),
                        
                        SizedBox(height: 24),
                        Divider(),
                        SizedBox(height: 16),
                        
                        Center(
                          child: Column(
                            children: [
                              Text(
                                '© ${DateTime.now().year} Laser Magique',
                                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                                  fontWeight: FontWeight.w500,
                                ),
                                textAlign: TextAlign.center,
                              ),
                              SizedBox(height: 4),
                              Text(
                                'Tous droits réservés',
                                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                                  color: Theme.of(context).colorScheme.onSurfaceVariant,
                                ),
                                textAlign: TextAlign.center,
                              ),
                              SizedBox(height: 12),
                              Text(
                                'Développé avec ❤️ pour optimiser votre gestion',
                                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                                  color: Theme.of(context).colorScheme.onSurfaceVariant,
                                  fontStyle: FontStyle.italic,
                                ),
                                textAlign: TextAlign.center,
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                  actions: [
                    TextButton(
                      onPressed: () => Navigator.of(context).pop(),
                      child: Text('Fermer'),
                    ),
                  ],
                ),
              );
            },
          ),

          const SizedBox(height: 32),
        ],
      ),
    );
  }

  String _getThemeModeSubtitle(AppThemeMode mode) {
    switch (mode) {
      case AppThemeMode.light:
        return 'Mode clair';
      case AppThemeMode.dark:
        return 'Mode sombre';
      case AppThemeMode.system:
        return 'Adapté au système';
    }
  }

  Widget _buildFeatureItem(BuildContext context, IconData icon, String text) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        children: [
          Icon(
            icon,
            size: 20,
            color: Theme.of(context).colorScheme.primary,
          ),
          SizedBox(width: 12),
          Expanded(
            child: Text(
              text,
              style: Theme.of(context).textTheme.bodyMedium,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTechItem(BuildContext context, String title, String description) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 8,
            height: 8,
            margin: EdgeInsets.only(top: 6),
            decoration: BoxDecoration(
              color: Theme.of(context).colorScheme.primary,
              shape: BoxShape.circle,
            ),
          ),
          SizedBox(width: 12),
          Expanded(
            child: RichText(
              text: TextSpan(
                style: Theme.of(context).textTheme.bodyMedium,
                children: [
                  TextSpan(
                    text: '$title: ',
                    style: TextStyle(fontWeight: FontWeight.w500),
                  ),
                  TextSpan(
                    text: description,
                    style: TextStyle(
                      color: Theme.of(context).colorScheme.onSurfaceVariant,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildInfoRow(BuildContext context, String label, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 100,
            child: Text(
              label,
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                fontWeight: FontWeight.w500,
                color: Theme.of(context).colorScheme.onSurfaceVariant,
              ),
            ),
          ),
          SizedBox(width: 16),
          Expanded(
            child: Text(
              value,
              style: Theme.of(context).textTheme.bodySmall,
            ),
          ),
        ],
      ),
    );
  }

  String _getFlutterVersion() {
    return '3.7+';
  }

  List<Widget> _buildHelpSections(BuildContext context) {
    final helpData = _getHelpData();
    return helpData.map((section) => _buildHelpSectionFromData(context, section)).toList();
  }

  Widget _buildHelpSectionFromData(BuildContext context, HelpSection section) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            '${section.icon} ${section.title}',
            style: Theme.of(context).textTheme.bodyLarge?.copyWith(
              fontWeight: FontWeight.w500,
            ),
          ),
          SizedBox(height: 8),
          ...section.subsections.map((subsection) => 
            _buildHelpSubsection(context, subsection)
          ).toList(),
        ],
      ),
    );
  }

  Widget _buildHelpSubsection(BuildContext context, HelpSubsection subsection) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (subsection.subtitle != null) ...[
            Text(
              subsection.subtitle!,
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                fontWeight: FontWeight.w500,
                color: Theme.of(context).colorScheme.primary,
              ),
            ),
            SizedBox(height: 4),
          ],
          ...subsection.points.map((point) => 
            Padding(
              padding: const EdgeInsets.only(left: 8, bottom: 2),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('• ', style: Theme.of(context).textTheme.bodyMedium),
                  Expanded(
                    child: Text(
                      point,
                      style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                        color: Theme.of(context).colorScheme.onSurfaceVariant,
                      ),
                    ),
                  ),
                ],
              ),
            )
          ).toList(),
        ],
      ),
    );
  }

  List<HelpSection> _getHelpData() {
    return [
      HelpSection(
        icon: '🏠',
        title: 'Navigation principale',
        subsections: [
          HelpSubsection(
            points: [
              'Réservations (Accueil) - Calendrier et gestion des réservations',
              'Statistiques - Analyses financières et rapports', 
              'Stock - Gestion de l\'inventaire',
              'Paramètres - Configuration de l\'application',
            ],
          ),
        ],
      ),
      HelpSection(
        icon: '📅',
        title: 'Gestion des réservations',
        subsections: [
          HelpSubsection(
            subtitle: 'CRÉER UNE RÉSERVATION',
            points: [
              'Appuyez sur le bouton "+" flottant',
              'Saisissez les informations client (détection automatique des doublons)',
              'Sélectionnez la date et l\'heure',
              'Choisissez la formule et le nombre de participants',
              'Gérez l\'acompte et le moyen de paiement',
            ],
          ),
          HelpSubsection(
            subtitle: 'CALENDRIER',
            points: [
              'Vue par jour/mois des réservations',
              'Cliquez sur une réservation pour voir les détails',
              'Statuts : Active, Annulée',
            ],
          ),
          HelpSubsection(
            subtitle: 'GESTION DES RÉSERVATIONS',
            points: [
              'Modification des réservations existantes',
              'Annulation à tout moment',
              'Ajoutez des consommations en temps réel',
              'Le stock se met à jour automatiquement',
              'Finalisez le paiement pour clôturer',
            ],
          ),
        ],
      ),
      HelpSection(
        icon: '📦',
        title: 'Gestion du stock',
        subsections: [
          HelpSubsection(
            subtitle: 'ORGANISATION',
            points: [
              'Stock organisé par catégories : Boissons, Nourriture, Autres',
              'Articles inactifs visibles séparément',
            ],
          ),
          HelpSubsection(
            subtitle: 'FONCTIONS',
            points: [
              'Ajout/modification d\'articles avec nom, quantité, prix, seuil d\'alerte',
              'Mise à jour rapide des quantités directement dans la liste',
              'Recherche par nom d\'article',
              'Activation/désactivation d\'articles',
            ],
          ),
          HelpSubsection(
            subtitle: 'ALERTES',
            points: [
              'Notifications automatiques quand le stock atteint le seuil minimum',
              'Badge rouge sur l\'onglet Stock si alertes en cours',
            ],
          ),
          HelpSubsection(
            subtitle: 'CONSOMMATIONS',
            points: [
              'Décrément automatique lors des sessions de jeu',
              'Historique des mouvements de stock',
            ],
          ),
        ],
      ),
      HelpSection(
        icon: '📊',
        title: 'Statistiques et rapports',
        subsections: [
          HelpSubsection(
            subtitle: 'VUES DISPONIBLES',
            points: [
              'Vue jour : Statistiques quotidiennes détaillées',
              'Vue période : Analyses sur plusieurs jours/semaines',
            ],
          ),
          HelpSubsection(
            subtitle: 'DONNÉES FINANCIÈRES',
            points: [
              'Répartition par méthodes de paiement (espèces, carte, virement)',
              'Analyse par catégories de revenus',
              'Résumé de caisse avec totaux automatiques',
              'Suivi des acomptes et soldes',
            ],
          ),
          HelpSubsection(
            subtitle: 'FONCTIONS ADMIN',
            points: [
              'Export PDF des rapports',
              'Saisie manuelle de données',
              'Graphiques de tendances',
              'Mouvements de caisse avec justificatifs',
            ],
          ),
        ],
      ),
      HelpSection(
        icon: '🎮',
        title: 'Activités et formules (Admin)',
        subsections: [
          HelpSubsection(
            subtitle: 'GESTION DES SERVICES',
            points: [
              'Création d\'activités (types de jeux)',
              'Configuration de formules avec prix, durée, participants',
              'Paramètres min/max participants',
              'Types spéciaux (standard vs Social Deal)',
              'Articles inclus automatiquement dans les formules',
            ],
          ),
          HelpSubsection(
            subtitle: 'ACCÈS',
            points: [
              'Menu Paramètres > "Formules et activités"',
              'Visible uniquement pour les administrateurs',
            ],
          ),
        ],
      ),
      HelpSection(
        icon: '🔧',
        title: 'Gestion du matériel',
        subsections: [
          HelpSubsection(
            subtitle: 'SUIVI D\'ÉQUIPEMENT',
            points: [
              'Liste du matériel avec statut (fonctionnel/en panne)',
              'Descriptions et historique de maintenance',
              'Notifications en cas de problème',
              'Suivi des réparations',
            ],
          ),
          HelpSubsection(
            subtitle: 'ACCÈS',
            points: [
              'Menu Paramètres > "Gestion du matériel"',
            ],
          ),
        ],
      ),
      HelpSection(
        icon: '🔔',
        title: 'Système de notifications',
        subsections: [
          HelpSubsection(
            subtitle: 'TYPES DE NOTIFICATIONS',
            points: [
              'Nouvelles réservations et annulations',
              'Alertes de stock bas',
              'Mises à jour de consommation',
              'Paiements reçus',
              'Mises à jour système',
            ],
          ),
          HelpSubsection(
            subtitle: 'ACCÈS',
            points: [
              'Icône cloche sur l\'écran d\'accueil',
              'Badge avec nombre de notifications non lues',
              'Notifications push sur l\'appareil',
            ],
          ),
        ],
      ),
      HelpSection(
        icon: '👥',
        title: 'Gestion des clients',
        subsections: [
          HelpSubsection(
            subtitle: 'BASE DE DONNÉES',
            points: [
              'Informations complètes : nom, prénom, email, téléphone',
              'Détection automatique des doublons lors de la création',
              'Historique complet des réservations par client',
              'Recherche rapide par nom/email',
            ],
          ),
          HelpSubsection(
            subtitle: 'RECHERCHE',
            points: [
              'Icône de recherche sur l\'écran d\'accueil',
              'Recherche instantanée dans la base clients',
            ],
          ),
        ],
      ),
      HelpSection(
        icon: '👤',
        title: 'Rôles utilisateur',
        subsections: [
          HelpSubsection(
            subtitle: 'UTILISATEUR STANDARD',
            points: [
              'Gestion des réservations et sessions',
              'Consultation du stock et mise à jour des quantités',
              'Accès aux statistiques de base',
              'Gestion de son profil',
            ],
          ),
          HelpSubsection(
            subtitle: 'ADMINISTRATEUR',
            points: [
              'Toutes les fonctions utilisateur +',
              'Gestion des formules et activités',
              'Export PDF des rapports',
              'Saisie manuelle de données',
              'Configuration avancée du système',
            ],
          ),
        ],
      ),
      HelpSection(
        icon: '⚙️',
        title: 'Paramètres',
        subsections: [
          HelpSubsection(
            subtitle: 'APPARENCE',
            points: [
              'Choix du thème : clair, sombre, ou adapté au système',
              'Personnalisation de l\'interface',
            ],
          ),
          HelpSubsection(
            subtitle: 'NOTIFICATIONS',
            points: [
              'Activation/désactivation des notifications push',
              'Configuration des alertes',
            ],
          ),
          HelpSubsection(
            subtitle: 'COMPTE',
            points: [
              'Gestion du profil utilisateur',
              'Déconnexion sécurisée',
            ],
          ),
        ],
      ),
      HelpSection(
        icon: '🔄',
        title: 'Workflows typiques',
        subsections: [
          HelpSubsection(
            subtitle: 'NOUVELLE RÉSERVATION',
            points: [
              'Sélectionnez une date dans le calendrier',
              'Cliquez sur "+" pour créer une réservation',
              'Saisissez/sélectionnez le client',
              'Configurez la formule et les participants',
              'Gérez l\'acompte si nécessaire',
              'Validez → notification automatique',
            ],
          ),
          HelpSubsection(
            subtitle: 'SESSION DE JEU',
            points: [
              'Ouvrez la réservation du jour',
              'Démarrez la session de jeu',
              'Ajoutez les consommations en temps réel',
              'Le total se calcule automatiquement',
              'Finalisez le paiement pour clôturer',
            ],
          ),
          HelpSubsection(
            subtitle: 'GESTION STOCK',
            points: [
              'Consultez le stock par catégorie',
              'Mettez à jour les quantités directement',
              'Ajoutez de nouveaux articles via "+"',
              'Surveillez les alertes de stock bas',
            ],
          ),
        ],
      ),
    ];
  }
}

class HelpSection {
  final String icon;
  final String title;
  final List<HelpSubsection> subsections;

  HelpSection({
    required this.icon,
    required this.title,
    required this.subsections,
  });
}

class HelpSubsection {
  final String? subtitle;
  final List<String> points;

  HelpSubsection({
    this.subtitle,
    required this.points,
  });
}
