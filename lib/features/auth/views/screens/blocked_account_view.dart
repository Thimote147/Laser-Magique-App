import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:laser_magique_app/features/auth/services/auth_service.dart';
import '../../../profile/models/user_model.dart';
import 'auth_view.dart';

class BlockedAccountView extends StatefulWidget {
  const BlockedAccountView({super.key});

  @override
  State<BlockedAccountView> createState() => _BlockedAccountViewState();
}

class _BlockedAccountViewState extends State<BlockedAccountView> {
  UserModel? currentUser;
  bool isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadCurrentUser();
  }

  Future<void> _loadCurrentUser() async {
    try {
      final authService = AuthService();
      final user = await authService.currentUserWithSettings;
      setState(() {
        currentUser = user;
        isLoading = false;
      });
    } catch (e) {
      setState(() {
        isLoading = false;
      });
    }
  }

  Future<void> _launchPhone(String phoneNumber) async {
    final Uri phoneUri = Uri(scheme: 'tel', path: phoneNumber);
    if (await canLaunchUrl(phoneUri)) {
      await launchUrl(phoneUri);
    } else {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Impossible d\'ouvrir le numéro : $phoneNumber'),
            backgroundColor: Theme.of(context).colorScheme.error,
          ),
        );
      }
    }
  }

  bool get _isUserMember {
    return currentUser?.settings?.role == 'member';
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Scaffold(
      backgroundColor: colorScheme.surface,
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 32),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const SizedBox(height: 60),
                  
                  // Logo avec titre
                  Column(
                    children: [
                      Container(
                        width: 80,
                        height: 80,
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(16),
                          boxShadow: [
                            BoxShadow(
                              color: colorScheme.primary.withAlpha((255 * 0.2).round()),
                              blurRadius: 16,
                              offset: const Offset(0, 6),
                            ),
                          ],
                        ),
                        child: ClipRRect(
                          borderRadius: BorderRadius.circular(16),
                          child: Image.asset(
                            'assets/images/icon.jpeg',
                            width: 80,
                            height: 80,
                            fit: BoxFit.cover,
                          ),
                        ),
                      ),
                      
                      const SizedBox(height: 20),
                      
                      Text(
                        'Laser Magique',
                        style: theme.textTheme.headlineSmall?.copyWith(
                          color: colorScheme.onSurface,
                          fontWeight: FontWeight.w600,
                          letterSpacing: 0.5,
                        ),
                      ),
                    ],
                  ),
                  
                  const SizedBox(height: 48),
                  
                  // Carte d'information de blocage
                  Container(
                    padding: const EdgeInsets.all(24),
                    decoration: BoxDecoration(
                      color: colorScheme.errorContainer.withAlpha((255 * 0.1).round()),
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(
                        color: colorScheme.error.withAlpha((255 * 0.2).round()),
                        width: 1,
                      ),
                    ),
                    child: Column(
                      children: [
                        // Icône de blocage
                        Container(
                          padding: const EdgeInsets.all(16),
                          decoration: BoxDecoration(
                            color: colorScheme.errorContainer.withAlpha((255 * 0.3).round()),
                            shape: BoxShape.circle,
                          ),
                          child: Icon(
                            Icons.block_rounded,
                            size: 32,
                            color: colorScheme.error,
                          ),
                        ),
                        
                        const SizedBox(height: 20),
                        
                        // Titre
                        Text(
                          'Accès suspendu',
                          style: theme.textTheme.titleLarge?.copyWith(
                            color: colorScheme.error,
                            fontWeight: FontWeight.w600,
                          ),
                          textAlign: TextAlign.center,
                        ),
                        
                        const SizedBox(height: 12),
                        
                        // Message principal
                        Text(
                          'Votre compte a été bloqué.',
                          style: theme.textTheme.bodyLarge?.copyWith(
                            color: colorScheme.onSurface,
                          ),
                          textAlign: TextAlign.center,
                        ),
                        
                        const SizedBox(height: 8),
                        
                        // Instructions
                        if (isLoading)
                          const SizedBox.shrink()
                        else
                          Text(
                            _isUserMember 
                              ? 'Pour plus d\'informations et réactiver votre accès, contactez un administrateur ou le support.'
                              : 'Pour plus d\'informations et réactiver votre accès, contactez le support.',
                            style: theme.textTheme.bodyMedium?.copyWith(
                              color: colorScheme.onSurfaceVariant,
                            ),
                            textAlign: TextAlign.center,
                          ),
                      ],
                    ),
                  ),
                  
                  const SizedBox(height: 32),
                  
                  // Boutons d'action
                  if (isLoading)
                    const CircularProgressIndicator()
                  else
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        // Bouton de contact support
                        FilledButton.icon(
                          onPressed: () => _launchPhone('+32492594409'),
                          icon: const Icon(Icons.support_agent_rounded),
                          label: const Text('Contacter le support'),
                          style: FilledButton.styleFrom(
                            backgroundColor: colorScheme.primary,
                            padding: const EdgeInsets.symmetric(vertical: 18),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(16),
                            ),
                            minimumSize: const Size(double.infinity, 56),
                          ),
                        ),
                        
                        const SizedBox(height: 12),
                        
                        // Bouton administrateur (visible seulement pour les membres)
                        if (_isUserMember) ...[
                          FilledButton.icon(
                            onPressed: () => _launchPhone('+32470537206'),
                            icon: const Icon(Icons.admin_panel_settings_rounded),
                            label: const Text('Contacter un administrateur'),
                            style: FilledButton.styleFrom(
                              backgroundColor: colorScheme.secondary,
                              padding: const EdgeInsets.symmetric(vertical: 18),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(16),
                              ),
                              minimumSize: const Size(double.infinity, 56),
                            ),
                          ),
                          const SizedBox(height: 12),
                        ],
                        
                        // Bouton de déconnexion
                        OutlinedButton.icon(
                          onPressed: () async {
                            final authService = AuthService();
                            await authService.signOut();
                            
                            if (context.mounted) {
                              Navigator.of(context).pushAndRemoveUntil(
                                MaterialPageRoute(builder: (context) => const AuthView()),
                                (route) => false,
                              );
                            }
                          },
                          icon: const Icon(Icons.logout_rounded),
                          label: const Text('Retour à la connexion'),
                          style: OutlinedButton.styleFrom(
                            padding: const EdgeInsets.symmetric(vertical: 18),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(16),
                            ),
                            minimumSize: const Size(double.infinity, 56),
                            side: BorderSide(
                              color: colorScheme.outline.withAlpha((255 * 0.5).round()),
                            ),
                          ),
                        ),
                      ],
                    ),
                  
                  const SizedBox(height: 60),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}