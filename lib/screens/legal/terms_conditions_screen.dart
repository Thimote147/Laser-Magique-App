import 'package:flutter/material.dart';
import 'package:flutter/cupertino.dart';
import '../../main.dart';

class TermsConditionsScreen extends StatelessWidget {
  const TermsConditionsScreen({super.key});

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
          'Conditions d\'Utilisation',
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
                      CupertinoIcons.doc_text,
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
                          'En vigueur au ${DateTime.now().day}/${DateTime.now().month}/${DateTime.now().year}',
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
                    title: 'ARTICLE 1 : Objet',
                    content:
                        'Les présentes Conditions Générales d\'Utilisation (ci-après les "CGU") ont pour objet de définir les modalités de mise à disposition de l\'application mobile Laser Magique (ci-après l\'"Application") et les conditions d\'utilisation du Service par l\'Utilisateur.\n\n'
                        'L\'Application Laser Magique permet la gestion des réservations, la planification des sessions, la gestion des joueurs et l\'analyse des performances pour l\'établissement du Laser-Magique.\n\n'
                        'Toute utilisation de l\'Application est subordonnée à l\'acceptation préalable et au respect intégral des présentes CGU.',
                    textColor: textColor,
                    backgroundColor: backgroundColor,
                    cardColor: cardColor,
                    separatorColor: separatorColor,
                    accentColor: accentColor,
                    icon: CupertinoIcons.doc_text,
                    isFirstItem: true,
                  ),
                  _buildAccordionSection(
                    title: 'ARTICLE 2 : Mentions légales',
                    content:
                        'L\'Application Laser Magique est éditée par Thimote Fetu, développeur fullstack indépendant, résidant en Belgique. L\'Application a été développée à des fins de gestion interne pour l\'établissement Laser-Magique.',
                    textColor: textColor,
                    backgroundColor: backgroundColor,
                    cardColor: cardColor,
                    separatorColor: separatorColor,
                    accentColor: accentColor,
                    icon: CupertinoIcons.info_circle,
                  ),
                  _buildAccordionSection(
                    title: 'ARTICLE 3 : Accès à l\'Application',
                    content:
                        'L\'Application Laser Magique est actuellement en phase de test interne et n\'est pas disponible publiquement. L\'accès à l\'Application est limité et n\'est possible que via les liens privés de distribution (.apk pour Android et .ipa pour iOS) fournis par l\'Éditeur aux utilisateurs autorisés.\n\n'
                        'L\'accès aux services de l\'Application nécessite que l\'Utilisateur s\'inscrive en remplissant le formulaire prévu à cet effet. L\'Utilisateur s\'engage à fournir des informations exactes et à les mettre à jour régulièrement.\n\n'
                        'L\'accès à l\'Application nécessite une connexion Internet. Les frais de connexion sont à la charge de l\'Utilisateur.',
                    textColor: textColor,
                    backgroundColor: backgroundColor,
                    cardColor: cardColor,
                    separatorColor: separatorColor,
                    accentColor: accentColor,
                    icon: CupertinoIcons.link,
                  ),
                  _buildAccordionSection(
                    title: 'ARTICLE 4 : Compte utilisateur',
                    content:
                        'Pour utiliser l\'Application, l\'Utilisateur doit créer un compte en fournissant les informations marquées comme obligatoires.\n\n'
                        'L\'Utilisateur s\'engage à protéger ses identifiants de connexion et à informer immédiatement l\'Éditeur de toute utilisation frauduleuse dont il aurait connaissance.\n\n'
                        'L\'Utilisateur est seul responsable de l\'utilisation de son compte et de toute action effectuée avec ses identifiants.',
                    textColor: textColor,
                    backgroundColor: backgroundColor,
                    cardColor: cardColor,
                    separatorColor: separatorColor,
                    accentColor: accentColor,
                    icon: CupertinoIcons.person_crop_circle,
                  ),
                  _buildAccordionSection(
                    title: 'ARTICLE 5 : Services',
                    content:
                        'L\'Application propose les services suivants :\n\n'
                        '• Gestion des réservations\n'
                        '• Planification des horaires de travail\n'
                        '• Gestion des clients et des groupes\n'
                        '• Suivi des statistiques et des performances\n'
                        '• Gestion du stock et des équipements\n\n'
                        'Ces services peuvent évoluer, être étendus ou modifiés à tout moment.',
                    textColor: textColor,
                    backgroundColor: backgroundColor,
                    cardColor: cardColor,
                    separatorColor: separatorColor,
                    accentColor: accentColor,
                    icon: CupertinoIcons.cube_box,
                  ),
                  _buildAccordionSection(
                    title: 'ARTICLE 6 : Responsabilités',
                    content:
                        'L\'Éditeur met en œuvre tous les moyens à sa disposition pour assurer un accès de qualité à l\'Application, mais n\'est tenu à aucune obligation de résultat.\n\n'
                        'L\'Éditeur ne peut être tenu responsable des problèmes ou défaillances techniques liés aux réseaux de communication.\n\n'
                        'L\'Utilisateur est responsable de la sécurité de son terminal et de sa connexion Internet.',
                    textColor: textColor,
                    backgroundColor: backgroundColor,
                    cardColor: cardColor,
                    separatorColor: separatorColor,
                    accentColor: accentColor,
                    icon: CupertinoIcons.exclamationmark_shield,
                  ),
                  _buildAccordionSection(
                    title: 'ARTICLE 7 : Propriété intellectuelle',
                    content:
                        'L\'ensemble des éléments constituant l\'Application (textes, graphismes, logiciels, images, sons, plans, logos, marques, etc.) est la propriété exclusive de l\'Éditeur ou fait l\'objet d\'une autorisation d\'utilisation.\n\n'
                        'Conformément au Livre XI du Code de droit économique belge, notamment les articles XI.163 à XI.293 relatifs au droit d\'auteur et aux droits voisins, toute reproduction, diffusion, vente, distribution ou exploitation commerciale de l\'Application, en tout ou partie, sans l\'autorisation expresse et préalable de l\'Éditeur est interdite et constituerait une contrefaçon pouvant entraîner des sanctions civiles et/ou pénales.\n\n'
                        'Cette protection s\'applique également aux bases de données contenues dans l\'Application qui sont protégées par les dispositions sur le droit sui generis des producteurs de bases de données.',
                    textColor: textColor,
                    backgroundColor: backgroundColor,
                    cardColor: cardColor,
                    separatorColor: separatorColor,
                    accentColor: accentColor,
                    icon: CupertinoIcons.doc_richtext,
                  ),
                  _buildAccordionSection(
                    title: 'ARTICLE 8 : Données personnelles',
                    content:
                        'Les informations recueillies dans l\'Application font l\'objet d\'un traitement informatique destiné à la gestion des réservations et des clients. L\'Éditeur s\'engage à respecter la confidentialité des données personnelles communiquées par l\'Utilisateur et à les traiter conformément au Règlement Général sur la Protection des Données (RGPD) et à la législation belge applicable.\n\n'
                        'Pour plus d\'informations sur la gestion des données personnelles, veuillez consulter notre Politique de Confidentialité.',
                    textColor: textColor,
                    backgroundColor: backgroundColor,
                    cardColor: cardColor,
                    separatorColor: separatorColor,
                    accentColor: accentColor,
                    icon: CupertinoIcons.lock_shield,
                  ),
                  _buildAccordionSection(
                    title: 'ARTICLE 9 : Modification des CGU',
                    content:
                        'L\'Éditeur se réserve le droit de modifier à tout moment les présentes CGU. L\'Utilisateur sera informé de ces modifications par tout moyen que l\'Éditeur jugera approprié. Si l\'Utilisateur n\'accepte pas les CGU modifiées, il devra cesser d\'utiliser l\'Application.',
                    textColor: textColor,
                    backgroundColor: backgroundColor,
                    cardColor: cardColor,
                    separatorColor: separatorColor,
                    accentColor: accentColor,
                    icon: CupertinoIcons.arrow_2_circlepath,
                  ),
                  _buildAccordionSection(
                    title: 'ARTICLE 10 : Résiliation',
                    content:
                        'L\'Éditeur peut résilier le droit d\'accès de l\'Utilisateur à tout ou partie de l\'Application, à tout moment et sans préavis, en cas de violation des présentes CGU.',
                    textColor: textColor,
                    backgroundColor: backgroundColor,
                    cardColor: cardColor,
                    separatorColor: separatorColor,
                    accentColor: accentColor,
                    icon: CupertinoIcons.xmark_circle,
                  ),
                  _buildAccordionSection(
                    title: 'ARTICLE 11 : Droit applicable',
                    content:
                        'Les présentes CGU sont soumises au droit belge. En cas de litige, les tribunaux belges seront compétents.\n\n'
                        'Pour toute question relative à l\'application des présentes CGU, vous pouvez contacter l\'Éditeur à l\'adresse suivante : contact@lasermagique.com',
                    textColor: textColor,
                    backgroundColor: backgroundColor,
                    cardColor: cardColor,
                    separatorColor: separatorColor,
                    accentColor: accentColor,
                    icon: CupertinoIcons.building_2_fill,
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
                                'En utilisant cette application, vous acceptez ces conditions.',
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
                          'Dernière mise à jour : ${DateTime.now().day} mai 2025',
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
    bool isFirstItem = false,
    bool isLastItem = false,
    IconData? icon,
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
        // Wrap ExpansionTile with Material widget to provide Material ancestor
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
