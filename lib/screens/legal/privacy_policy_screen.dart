import 'package:flutter/material.dart';
import 'package:flutter/cupertino.dart';
import '../../main.dart';

class PrivacyPolicyScreen extends StatelessWidget {
  const PrivacyPolicyScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final textColor = themeService.getTextColor();
    final backgroundColor = themeService.getBackgroundColor();
    final cardColor = themeService.getCardColor();
    final separatorColor = themeService.getSeparatorColor();
    final accentColor = CupertinoTheme.of(context).primaryColor;

    return CupertinoPageScaffold(
      backgroundColor: backgroundColor,
      navigationBar: CupertinoNavigationBar(
        backgroundColor: backgroundColor,
        border: null,
        middle: Text(
          'Politique de Confidentialité',
          style: TextStyle(
            color: textColor,
            fontWeight: FontWeight.bold,
            fontSize: 18,
          ),
        ),
      ),
      child: SafeArea(
        bottom: true,
        child: Column(
          children: [
            // Header section
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
              decoration: BoxDecoration(
                color: cardColor,
                boxShadow: [
                  BoxShadow(
                    color: separatorColor,
                    blurRadius: 5,
                    offset: const Offset(0, 2),
                  ),
                ],
              ),
              child: Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(
                      color: accentColor.withOpacity(0.1),
                      shape: BoxShape.circle,
                    ),
                    child: Icon(
                      CupertinoIcons.lock_shield,
                      color: accentColor,
                      size: 26,
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Document légal',
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                            letterSpacing: 0.5,
                            color: textColor,
                          ),
                        ),
                        Text(
                          'En vigueur au 6 mai 2025',
                          style: TextStyle(
                            fontSize: 13,
                            color: themeService.getSecondaryTextColor(),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),

            // Content sections
            Expanded(
              child: ListView(
                physics: const BouncingScrollPhysics(),
                padding: const EdgeInsets.only(bottom: 30),
                children: [
                  _buildAccordionSection(
                    title: 'Préambule',
                    content:
                        'La présente politique de confidentialité a pour but d\'informer les utilisateurs de l\'application Laser Magique de la manière dont leurs informations personnelles sont collectées et traitées.\n\n'
                        'Laser Magique s\'engage à respecter les dispositions du Règlement Général sur la Protection des Données (RGPD) et de la loi Informatique et Libertés.',
                    textColor: textColor,
                    backgroundColor: backgroundColor,
                    cardColor: cardColor,
                    separatorColor: separatorColor,
                    accentColor: accentColor,
                    icon: CupertinoIcons.info_circle,
                    isFirstItem: true,
                  ),
                  _buildAccordionSection(
                    title: '1. Collecte des données personnelles',
                    content:
                        'Nous collectons les types de données suivants :\n\n'
                        '• Données d\'identification : nom, prénom, adresse e-mail, numéro de téléphone\n'
                        '• Données de connexion : identifiants de connexion\n'
                        '• Données d\'utilisation : statistiques d\'utilisation, préférences\n'
                        '• Données de réservation : dates et heures, type d\'activité (Groupe, Anniversaire, Social Deal, Tean Building), nombre de participants, durée de la réservation, nombre de parties, informations sur le client\n\n'
                        'Ces données sont collectées lorsque vous :\n'
                        '• Créez un compte utilisateur\n'
                        '• Utilisez l\'application pour gérer des réservations\n'
                        '• Contactez notre service client\n'
                        '• Configurez vos préférences',
                    textColor: textColor,
                    backgroundColor: backgroundColor,
                    cardColor: cardColor,
                    separatorColor: separatorColor,
                    accentColor: accentColor,
                    icon: CupertinoIcons.person_crop_circle_badge_exclam,
                  ),
                  _buildAccordionSection(
                    title: '2. Finalités du traitement des données',
                    content:
                        'Vos données personnelles sont collectées et traitées pour les finalités suivantes :\n\n'
                        '• Gestion des comptes utilisateurs\n'
                        '• Gestion des réservations et planification des sessions\n'
                        '• Gestion de la relation client\n'
                        '• Amélioration de nos services et de l\'expérience utilisateur\n'
                        '• Établissement de statistiques d\'utilisation\n'
                        '• Respect de nos obligations légales',
                    textColor: textColor,
                    backgroundColor: backgroundColor,
                    cardColor: cardColor,
                    separatorColor: separatorColor,
                    accentColor: accentColor,
                    icon: CupertinoIcons.chart_bar_square,
                  ),
                  _buildAccordionSection(
                    title: '3. Base légale du traitement',
                    content:
                        'Le traitement de vos données personnelles est fondé sur :\n\n'
                        '• Votre consentement pour la création de votre compte et la collecte des données d\'utilisation\n'
                        '• L\'exécution du contrat pour la gestion des réservations\n'
                        '• Notre intérêt légitime pour l\'amélioration de nos services\n'
                        '• Le respect de nos obligations légales',
                    textColor: textColor,
                    backgroundColor: backgroundColor,
                    cardColor: cardColor,
                    separatorColor: separatorColor,
                    accentColor: accentColor,
                    icon: CupertinoIcons.doc_text,
                  ),
                  _buildAccordionSection(
                    title: '4. Destinataires des données',
                    content:
                        'Les données collectées sont destinées :\n\n'
                        '• À notre personnel autorisé\n'
                        '• À nos sous-traitants qui agissent en notre nom (hébergement, maintenance)\n\n'
                        'Nous ne vendons ni ne louons vos données personnelles à des tiers.\n\n'
                        'Nous pouvons être amenés à partager vos informations si la loi nous y oblige ou dans le cadre d\'une procédure judiciaire.',
                    textColor: textColor,
                    backgroundColor: backgroundColor,
                    cardColor: cardColor,
                    separatorColor: separatorColor,
                    accentColor: accentColor,
                    icon: CupertinoIcons.share,
                  ),
                  _buildAccordionSection(
                    title: '5. Durée de conservation',
                    content:
                        'Vos données personnelles sont conservées pour la durée nécessaire à la réalisation des finalités pour lesquelles elles ont été collectées, augmentée de la durée légale de conservation.\n\n'
                        '• Données de compte utilisateur : pendant la durée d\'utilisation du service, puis 3 ans après la dernière connexion\n'
                        '• Données de réservation : 3 ans à compter de la fin de la relation commerciale\n'
                        '• Données de facturation : 10 ans conformément aux obligations légales',
                    textColor: textColor,
                    backgroundColor: backgroundColor,
                    cardColor: cardColor,
                    separatorColor: separatorColor,
                    accentColor: accentColor,
                    icon: CupertinoIcons.timer,
                  ),
                  _buildAccordionSection(
                    title: '6. Sécurité des données',
                    content:
                        'Nous mettons en œuvre des mesures techniques et organisationnelles appropriées pour protéger vos données personnelles contre la destruction, la perte, l\'altération, la divulgation non autorisée ou l\'accès non autorisé.\n\n'
                        'Malgré toutes nos précautions, nous ne pouvons garantir une sécurité absolue des données transmises via Internet.',
                    textColor: textColor,
                    backgroundColor: backgroundColor,
                    cardColor: cardColor,
                    separatorColor: separatorColor,
                    accentColor: accentColor,
                    icon: CupertinoIcons.shield,
                  ),
                  _buildAccordionSection(
                    title: '7. Transferts de données hors UE',
                    content:
                        'Vos données peuvent être transférées vers des pays situés en dehors de l\'Union Européenne, notamment pour des raisons d\'hébergement des données.\n\n'
                        'Dans ce cas, nous nous assurons que ces transferts sont effectués vers des pays offrant un niveau de protection adéquat ou avec des garanties appropriées (clauses contractuelles types de la Commission européenne, etc.).',
                    textColor: textColor,
                    backgroundColor: backgroundColor,
                    cardColor: cardColor,
                    separatorColor: separatorColor,
                    accentColor: accentColor,
                    icon: CupertinoIcons.globe,
                  ),
                  _buildAccordionSection(
                    title: '8. Vos droits',
                    content:
                        'Conformément à la réglementation applicable en matière de protection des données personnelles, vous disposez des droits suivants :\n\n'
                        '• Droit d\'accès à vos données\n'
                        '• Droit de rectification des données inexactes\n'
                        '• Droit à l\'effacement (droit à l\'oubli)\n'
                        '• Droit à la limitation du traitement\n'
                        '• Droit d\'opposition au traitement\n'
                        '• Droit à la portabilité de vos données\n'
                        '• Droit de retirer votre consentement à tout moment\n'
                        '• Droit de définir des directives relatives au sort de vos données après votre décès\n\n'
                        'Pour exercer ces droits, vous pouvez nous contacter à l\'adresse email suivante : privacy@lasermagique.com ou par courrier à l\'adresse : Laser Magique - Service Protection des données, 123 Avenue du Laser, 75000 Paris.\n\n'
                        'Vous disposez également du droit d\'introduire une réclamation auprès de l\'Autorité de protection des données (APD) belge.',
                    textColor: textColor,
                    backgroundColor: backgroundColor,
                    cardColor: cardColor,
                    separatorColor: separatorColor,
                    accentColor: accentColor,
                    icon: CupertinoIcons.person_crop_circle_badge_checkmark,
                  ),
                  _buildAccordionSection(
                    title: '9. Cookies et technologies similaires',
                    content:
                        'L\'application Laser Magique utilise des cookies et technologies similaires pour améliorer votre expérience utilisateur et collecter des informations sur la manière dont vous utilisez l\'application.\n\n'
                        'Vous pouvez gérer vos préférences concernant ces technologies dans les paramètres de l\'application.',
                    textColor: textColor,
                    backgroundColor: backgroundColor,
                    cardColor: cardColor,
                    separatorColor: separatorColor,
                    accentColor: accentColor,
                    icon: CupertinoIcons.floppy_disk,
                  ),
                  _buildAccordionSection(
                    title:
                        '10. Modifications de la politique de confidentialité',
                    content:
                        'Nous nous réservons le droit de modifier la présente politique de confidentialité à tout moment. La nouvelle version sera publiée dans l\'application et, le cas échéant, vous sera notifiée.\n\n'
                        'Nous vous encourageons à consulter régulièrement cette politique pour vous tenir informé de toute modification.',
                    textColor: textColor,
                    backgroundColor: backgroundColor,
                    cardColor: cardColor,
                    separatorColor: separatorColor,
                    accentColor: accentColor,
                    icon: CupertinoIcons.arrow_2_circlepath,
                  ),
                  _buildAccordionSection(
                    title: '11. Contact',
                    content:
                        'Pour toute question concernant cette politique de confidentialité ou vos données personnelles, vous pouvez nous contacter :\n\n'
                        '• Par email : info@laser-magique.com\n'
                        '• Par courrier : Laser Magique - Drève de l\'infante n°27B, 1410 Waterloo, Belgique\n'
                        '• Par téléphone : +32 470 53 72 06\n\n'
                        'Nous nous engageons à répondre à vos demandes dans les meilleurs délais.'
                        'Dernière mise à jour : 6 mai 2025',
                    textColor: textColor,
                    backgroundColor: backgroundColor,
                    cardColor: cardColor,
                    separatorColor: separatorColor,
                    accentColor: accentColor,
                    icon: CupertinoIcons.mail,
                    isLastItem: true,
                  ),

                  // Footer with acceptance info
                  Container(
                    margin: const EdgeInsets.fromLTRB(16, 20, 16, 0),
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: accentColor.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Column(
                      children: [
                        Row(
                          children: [
                            Icon(
                              CupertinoIcons.checkmark_seal_fill,
                              color: accentColor,
                              size: 24,
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Text(
                                'En utilisant cette application, vous acceptez notre politique de confidentialité.',
                                style: TextStyle(
                                  fontWeight: FontWeight.w600,
                                  color: textColor,
                                  fontSize: 15,
                                ),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 8),
                        Text(
                          'Dernière mise à jour : 6 mai 2025',
                          style: TextStyle(
                            color: themeService.getSecondaryTextColor(),
                            fontSize: 13,
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
    );
  }

  Widget _buildAccordionSection({
    required String title,
    required String content,
    required Color textColor,
    required Color backgroundColor,
    required Color cardColor,
    required Color separatorColor,
    required Color accentColor,
    IconData? icon,
    bool isFirstItem = false,
    bool isLastItem = false,
  }) {
    return Theme(
      data: ThemeData(
        dividerColor: Colors.transparent,
        colorScheme: ColorScheme.light(primary: accentColor),
      ),
      child: Container(
        margin: EdgeInsets.only(
          left: 16,
          right: 16,
          top: isFirstItem ? 16 : 8,
          bottom: isLastItem ? 8 : 0,
        ),
        decoration: BoxDecoration(
          color: cardColor,
          borderRadius: BorderRadius.circular(12),
          boxShadow: [
            BoxShadow(
              color: separatorColor,
              blurRadius: 4,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Material(
          color: Colors.transparent,
          child: ExpansionTile(
            initiallyExpanded: true,
            title: Row(
              children: [
                if (icon != null)
                  Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: accentColor.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Icon(icon, size: 22, color: accentColor),
                  ),
                if (icon != null) const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    title,
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      color: textColor,
                      fontSize: 16,
                    ),
                  ),
                ),
              ],
            ),
            iconColor: accentColor,
            collapsedIconColor: accentColor,
            childrenPadding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
            children: [
              Text(
                content,
                style: TextStyle(fontSize: 14.0, color: textColor, height: 1.5),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
