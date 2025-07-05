import 'dart:typed_data';
import 'package:flutter/services.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart';
import 'package:intl/intl.dart';
import '../models/daily_statistics_model.dart';
import '../models/cash_movement_model.dart';
import '../viewmodels/statistics_view_model.dart';
import '../../../shared/services/pdf_header_service.dart';

class PdfExportService {
  Future<Uint8List> generateStatisticsReport({
    required DailyStatistics statistics,
    required PeriodType periodType,
    required DateTime startDate,
    required DateTime endDate,
    List<DailyStatistics> periodStatistics = const [],
    List<CashMovement> cashMovements = const [],
  }) async {
    final pdf = pw.Document();

    // Chargement de la police
    final font = await PdfGoogleFonts.openSansRegular();
    final fontBold = await PdfGoogleFonts.openSansBold();

    final periodText = _getPeriodText(periodType, startDate, endDate);

    // Calcul de l'écart de caisse
    final double theoreticalCashAmount =
        statistics.fondCaisseOuverture + statistics.totalCash;
    final double actualCashAmount =
        statistics.fondCaisseFermeture + statistics.montantCoffre;
    final double cashDiscrepancy = actualCashAmount - theoreticalCashAmount;

    // Génération du header
    final header = await PdfHeaderService.buildStandardHeader(
      title: 'Rapport de Statistiques',
      font: font,
      fontBold: fontBold,
    );

    // Génération du PDF
    pdf.addPage(
      pw.MultiPage(
        pageFormat: PdfPageFormat.a4,
        margin: const pw.EdgeInsets.all(32),
        build: (pw.Context context) {
          return [
            header,
            PdfHeaderService.buildPeriodInfoBox(
              periodText: periodText,
              font: font,
              fontBold: fontBold,
            ),
            pw.SizedBox(height: 20),

            // Résumé des méthodes de paiement
            pw.Header(
              level: 1,
              text: 'Méthodes de paiement',
              textStyle: pw.TextStyle(font: fontBold, fontSize: 18),
            ),
            _buildPaymentMethodsTable(statistics, font, fontBold),
            pw.SizedBox(height: 10),

            // Résumé des catégories
            pw.Header(
              level: 1,
              text: 'Ventes par catégorie',
              textStyle: pw.TextStyle(font: fontBold, fontSize: 18),
            ),
            _buildCategoriesTable(statistics, font, fontBold),
            pw.SizedBox(height: 10),

            // Section adaptée selon le type de période
            if (periodType == PeriodType.day) ...[
              // Résumé de caisse (uniquement pour la vue journalière)
              pw.Header(
                level: 1,
                text: 'Résumé de caisse',
                textStyle: pw.TextStyle(font: fontBold, fontSize: 18),
              ),
              _buildSummaryTable(statistics, font, fontBold),
              pw.SizedBox(height: 15),

              // Contrôle de caisse (uniquement pour la vue journalière)
              _buildCashControlSection(statistics, cashDiscrepancy, theoreticalCashAmount, actualCashAmount, font, fontBold),
            ] else ...[
              // Résumé financier pour les vues de période
              pw.Header(
                level: 1,
                text: 'Résumé financier de la période',
                textStyle: pw.TextStyle(font: fontBold, fontSize: 18),
              ),
              _buildPeriodFinancialSummary(periodStatistics, font, fontBold),
              pw.SizedBox(height: 15),
            ],

            // Section spécifique selon le type de période
            ..._buildPeriodSpecificContent(periodType, statistics, periodStatistics, cashMovements, font, fontBold),

            pw.SizedBox(height: 20),
            PdfHeaderService.buildStandardFooter(
              font: font,
              additionalText: 'Laser Magique - Rapport généré le ${DateFormat('dd/MM/yyyy à HH:mm').format(DateTime.now())}',
            ),
          ];
        },
      ),
    );

    return pdf.save();
  }

  pw.Widget _buildPaymentMethodsTable(
    DailyStatistics statistics,
    pw.Font font,
    pw.Font fontBold,
  ) {
    return pw.Table(
      border: pw.TableBorder.all(color: PdfColors.grey400),
      children: [
        pw.TableRow(
          decoration: const pw.BoxDecoration(color: PdfColors.grey200),
          children: [
            pw.Padding(
              padding: const pw.EdgeInsets.all(8),
              child: pw.Text(
                'Méthode de paiement',
                style: pw.TextStyle(font: fontBold),
              ),
            ),
            pw.Padding(
              padding: const pw.EdgeInsets.all(8),
              child: pw.Text(
                'Montant',
                style: pw.TextStyle(font: fontBold),
                textAlign: pw.TextAlign.right,
              ),
            ),
          ],
        ),
        pw.TableRow(
          children: [
            pw.Padding(
              padding: const pw.EdgeInsets.all(8),
              child: pw.Text('Bancontact', style: pw.TextStyle(font: font)),
            ),
            pw.Padding(
              padding: const pw.EdgeInsets.all(8),
              child: pw.Text(
                '${statistics.totalBancontact.toStringAsFixed(2).replaceAll('.', ',')} €',
                style: pw.TextStyle(font: font),
                textAlign: pw.TextAlign.right,
              ),
            ),
          ],
        ),
        pw.TableRow(
          children: [
            pw.Padding(
              padding: const pw.EdgeInsets.all(8),
              child: pw.Text('Espèces', style: pw.TextStyle(font: font)),
            ),
            pw.Padding(
              padding: const pw.EdgeInsets.all(8),
              child: pw.Text(
                '${statistics.totalCash.toStringAsFixed(2).replaceAll('.', ',')} €',
                style: pw.TextStyle(font: font),
                textAlign: pw.TextAlign.right,
              ),
            ),
          ],
        ),
        pw.TableRow(
          children: [
            pw.Padding(
              padding: const pw.EdgeInsets.all(8),
              child: pw.Text('Virement', style: pw.TextStyle(font: font)),
            ),
            pw.Padding(
              padding: const pw.EdgeInsets.all(8),
              child: pw.Text(
                '${statistics.totalVirement.toStringAsFixed(2).replaceAll('.', ',')} €',
                style: pw.TextStyle(font: font),
                textAlign: pw.TextAlign.right,
              ),
            ),
          ],
        ),
        pw.TableRow(
          decoration: const pw.BoxDecoration(color: PdfColors.grey200),
          children: [
            pw.Padding(
              padding: const pw.EdgeInsets.all(8),
              child: pw.Text('TOTAL', style: pw.TextStyle(font: fontBold)),
            ),
            pw.Padding(
              padding: const pw.EdgeInsets.all(8),
              child: pw.Text(
                '${statistics.total.toStringAsFixed(2).replaceAll('.', ',')} €',
                style: pw.TextStyle(font: fontBold),
                textAlign: pw.TextAlign.right,
              ),
            ),
          ],
        ),
      ],
    );
  }

  pw.Widget _buildCategoriesTable(
    DailyStatistics statistics,
    pw.Font font,
    pw.Font fontBold,
  ) {
    return pw.Table(
      border: pw.TableBorder.all(color: PdfColors.grey400),
      children: [
        pw.TableRow(
          decoration: const pw.BoxDecoration(color: PdfColors.grey200),
          children: [
            pw.Padding(
              padding: const pw.EdgeInsets.all(8),
              child: pw.Text('Catégorie', style: pw.TextStyle(font: fontBold)),
            ),
            pw.Padding(
              padding: const pw.EdgeInsets.all(8),
              child: pw.Text(
                'Montant',
                style: pw.TextStyle(font: fontBold),
                textAlign: pw.TextAlign.right,
              ),
            ),
          ],
        ),
        pw.TableRow(
          children: [
            pw.Padding(
              padding: const pw.EdgeInsets.all(8),
              child: pw.Text('Boissons', style: pw.TextStyle(font: font)),
            ),
            pw.Padding(
              padding: const pw.EdgeInsets.all(8),
              child: pw.Text(
                '${statistics.totalBoissons.toStringAsFixed(2).replaceAll('.', ',')} €',
                style: pw.TextStyle(font: font),
                textAlign: pw.TextAlign.right,
              ),
            ),
          ],
        ),
        pw.TableRow(
          children: [
            pw.Padding(
              padding: const pw.EdgeInsets.all(8),
              child: pw.Text('Nourritures', style: pw.TextStyle(font: font)),
            ),
            pw.Padding(
              padding: const pw.EdgeInsets.all(8),
              child: pw.Text(
                '${statistics.totalNourritures.toStringAsFixed(2).replaceAll('.', ',')} €',
                style: pw.TextStyle(font: font),
                textAlign: pw.TextAlign.right,
              ),
            ),
          ],
        ),
        pw.TableRow(
          decoration: const pw.BoxDecoration(color: PdfColors.grey200),
          children: [
            pw.Padding(
              padding: const pw.EdgeInsets.all(8),
              child: pw.Text('TOTAL', style: pw.TextStyle(font: fontBold)),
            ),
            pw.Padding(
              padding: const pw.EdgeInsets.all(8),
              child: pw.Text(
                '${statistics.totalParCategorie.toStringAsFixed(2).replaceAll('.', ',')} €',
                style: pw.TextStyle(font: fontBold),
                textAlign: pw.TextAlign.right,
              ),
            ),
          ],
        ),
      ],
    );
  }

  pw.Widget _buildSummaryTable(
    DailyStatistics statistics,
    pw.Font font,
    pw.Font fontBold,
  ) {
    return pw.Table(
      border: pw.TableBorder.all(color: PdfColors.grey400),
      children: [
        pw.TableRow(
          decoration: const pw.BoxDecoration(color: PdfColors.grey200),
          children: [
            pw.Padding(
              padding: const pw.EdgeInsets.all(8),
              child: pw.Text('Élément', style: pw.TextStyle(font: fontBold)),
            ),
            pw.Padding(
              padding: const pw.EdgeInsets.all(8),
              child: pw.Text(
                'Montant',
                style: pw.TextStyle(font: fontBold),
                textAlign: pw.TextAlign.right,
              ),
            ),
          ],
        ),
        pw.TableRow(
          children: [
            pw.Padding(
              padding: const pw.EdgeInsets.all(8),
              child: pw.Text('Fond ouverture', style: pw.TextStyle(font: font)),
            ),
            pw.Padding(
              padding: const pw.EdgeInsets.all(8),
              child: pw.Text(
                '${statistics.fondCaisseOuverture.toStringAsFixed(2).replaceAll('.', ',')} €',
                style: pw.TextStyle(font: font),
                textAlign: pw.TextAlign.right,
              ),
            ),
          ],
        ),
        pw.TableRow(
          children: [
            pw.Padding(
              padding: const pw.EdgeInsets.all(8),
              child: pw.Text('Fond fermeture', style: pw.TextStyle(font: font)),
            ),
            pw.Padding(
              padding: const pw.EdgeInsets.all(8),
              child: pw.Text(
                '${statistics.fondCaisseFermeture.toStringAsFixed(2).replaceAll('.', ',')} €',
                style: pw.TextStyle(font: font),
                textAlign: pw.TextAlign.right,
              ),
            ),
          ],
        ),
        pw.TableRow(
          children: [
            pw.Padding(
              padding: const pw.EdgeInsets.all(8),
              child: pw.Text(
                'Montant au coffre',
                style: pw.TextStyle(font: font),
              ),
            ),
            pw.Padding(
              padding: const pw.EdgeInsets.all(8),
              child: pw.Text(
                '${statistics.montantCoffre.toStringAsFixed(2).replaceAll('.', ',')} €',
                style: pw.TextStyle(font: font),
                textAlign: pw.TextAlign.right,
              ),
            ),
          ],
        ),
      ],
    );
  }

  pw.Widget _buildDailyStatsTable(
    List<DailyStatistics> statistics,
    pw.Font font,
    pw.Font fontBold,
  ) {
    return pw.Table(
      border: pw.TableBorder.all(color: PdfColors.grey400),
      children: [
        pw.TableRow(
          decoration: const pw.BoxDecoration(color: PdfColors.grey200),
          children: [
            pw.Padding(
              padding: const pw.EdgeInsets.all(8),
              child: pw.Text('Date', style: pw.TextStyle(font: fontBold)),
            ),
            pw.Padding(
              padding: const pw.EdgeInsets.all(8),
              child: pw.Text(
                'Bancontact',
                style: pw.TextStyle(font: fontBold),
                textAlign: pw.TextAlign.right,
              ),
            ),
            pw.Padding(
              padding: const pw.EdgeInsets.all(8),
              child: pw.Text(
                'Espèces',
                style: pw.TextStyle(font: fontBold),
                textAlign: pw.TextAlign.right,
              ),
            ),
            pw.Padding(
              padding: const pw.EdgeInsets.all(8),
              child: pw.Text(
                'Virement',
                style: pw.TextStyle(font: fontBold),
                textAlign: pw.TextAlign.right,
              ),
            ),
            pw.Padding(
              padding: const pw.EdgeInsets.all(8),
              child: pw.Text(
                'Total',
                style: pw.TextStyle(font: fontBold),
                textAlign: pw.TextAlign.right,
              ),
            ),
          ],
        ),
        ...statistics
            .map(
              (stat) => pw.TableRow(
                children: [
                  pw.Padding(
                    padding: const pw.EdgeInsets.all(8),
                    child: pw.Text(
                      DateFormat('dd/MM/yyyy').format(stat.date),
                      style: pw.TextStyle(font: font),
                    ),
                  ),
                  pw.Padding(
                    padding: const pw.EdgeInsets.all(8),
                    child: pw.Text(
                      '${stat.totalBancontact.toStringAsFixed(2).replaceAll('.', ',')} €',
                      style: pw.TextStyle(font: font),
                      textAlign: pw.TextAlign.right,
                    ),
                  ),
                  pw.Padding(
                    padding: const pw.EdgeInsets.all(8),
                    child: pw.Text(
                      '${stat.totalCash.toStringAsFixed(2).replaceAll('.', ',')} €',
                      style: pw.TextStyle(font: font),
                      textAlign: pw.TextAlign.right,
                    ),
                  ),
                  pw.Padding(
                    padding: const pw.EdgeInsets.all(8),
                    child: pw.Text(
                      '${stat.totalVirement.toStringAsFixed(2).replaceAll('.', ',')} €',
                      style: pw.TextStyle(font: font),
                      textAlign: pw.TextAlign.right,
                    ),
                  ),
                  pw.Padding(
                    padding: const pw.EdgeInsets.all(8),
                    child: pw.Text(
                      '${stat.total.toStringAsFixed(2).replaceAll('.', ',')} €',
                      style: pw.TextStyle(font: font),
                      textAlign: pw.TextAlign.right,
                    ),
                  ),
                ],
              ),
            ),
      ],
    );
  }

  String _getPeriodText(
    PeriodType periodType,
    DateTime startDate,
    DateTime endDate,
  ) {
    final dateFormat = DateFormat('dd/MM/yyyy');
    switch (periodType) {
      case PeriodType.day:
        return 'Journée du ${dateFormat.format(startDate)}';
      case PeriodType.week:
        return 'Semaine du ${dateFormat.format(startDate)} au ${dateFormat.format(endDate)}';
      case PeriodType.month:
        return 'Mois de ${DateFormat('MMMM yyyy', 'fr_FR').format(startDate)}';
      case PeriodType.year:
        return 'Année ${startDate.year}';
    }
  }

  Future<void> printPdf(Uint8List pdfBytes) async {
    await Printing.layoutPdf(
      onLayout: (PdfPageFormat format) async => pdfBytes,
    );
  }

  Future<void> sharePdf(Uint8List pdfBytes, String fileName) async {
    await Printing.sharePdf(bytes: pdfBytes, filename: fileName);
  }

  // Section de contrôle de caisse
  pw.Widget _buildCashControlSection(
    DailyStatistics statistics,
    double cashDiscrepancy,
    double theoreticalCashAmount,
    double actualCashAmount,
    pw.Font font,
    pw.Font fontBold,
  ) {
    return pw.Container(
      padding: const pw.EdgeInsets.all(10),
      decoration: pw.BoxDecoration(
        color:
            cashDiscrepancy != 0
                ? (cashDiscrepancy > 0
                    ? PdfColors.green100
                    : PdfColors.red100)
                : PdfColors.grey200,
        borderRadius: pw.BorderRadius.circular(5),
        border: pw.Border.all(
          color:
              cashDiscrepancy != 0
                  ? (cashDiscrepancy > 0
                      ? PdfColors.green800
                      : PdfColors.red800)
                  : PdfColors.grey400,
          width: 0.5,
        ),
      ),
      child: pw.Column(
        crossAxisAlignment: pw.CrossAxisAlignment.start,
        children: [
          pw.Text(
            'Contrôle de caisse',
            style: pw.TextStyle(font: fontBold, fontSize: 14),
          ),
          pw.SizedBox(height: 10),
          pw.Row(
            mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
            children: [
              pw.Text(
                'Solde théorique espèces:',
                style: pw.TextStyle(font: font),
              ),
              pw.Text(
                '${theoreticalCashAmount.toStringAsFixed(2).replaceAll('.', ',')} €',
                style: pw.TextStyle(font: font),
              ),
            ],
          ),
          pw.SizedBox(height: 5),
          pw.Row(
            mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
            children: [
              pw.Text(
                'Solde réel espèces:',
                style: pw.TextStyle(font: font),
              ),
              pw.Text(
                '${actualCashAmount.toStringAsFixed(2).replaceAll('.', ',')} €',
                style: pw.TextStyle(font: font),
              ),
            ],
          ),
          pw.SizedBox(height: 10),
          pw.Row(
            mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
            children: [
              pw.Text(
                'Écart de caisse:',
                style: pw.TextStyle(font: fontBold),
              ),
              pw.Text(
                '${cashDiscrepancy.toStringAsFixed(2).replaceAll('.', ',')} €',
                style: pw.TextStyle(
                  font: fontBold,
                  color:
                      cashDiscrepancy != 0
                          ? (cashDiscrepancy > 0
                              ? PdfColors.green800
                              : PdfColors.red800)
                          : PdfColors.black,
                ),
              ),
            ],
          ),
          if (cashDiscrepancy.abs() > 0.01)
            pw.Padding(
              padding: const pw.EdgeInsets.only(top: 5),
              child: pw.Text(
                cashDiscrepancy > 0
                    ? 'Il y a plus d\'argent en caisse que prévu.'
                    : 'Il manque de l\'argent en caisse.',
                style: pw.TextStyle(
                  font: font,
                  fontStyle: pw.FontStyle.italic,
                  fontSize: 12,
                  color:
                      cashDiscrepancy > 0
                          ? PdfColors.green800
                          : PdfColors.red800,
                ),
              ),
            ),
        ],
      ),
    );
  }

  // Contenu spécifique selon le type de période
  List<pw.Widget> _buildPeriodSpecificContent(
    PeriodType periodType,
    DailyStatistics statistics,
    List<DailyStatistics> periodStatistics,
    List<CashMovement> cashMovements,
    pw.Font font,
    pw.Font fontBold,
  ) {
    switch (periodType) {
      case PeriodType.day:
        return _buildDaySpecificContent(statistics, cashMovements, font, fontBold);
      case PeriodType.week:
      case PeriodType.month:
      case PeriodType.year:
        return _buildPeriodSpecificSections(periodType, periodStatistics, font, fontBold);
    }
  }

  // Contenu spécifique pour la vue journalière
  List<pw.Widget> _buildDaySpecificContent(
    DailyStatistics statistics,
    List<CashMovement> cashMovements,
    pw.Font font,
    pw.Font fontBold,
  ) {
    final widgets = <pw.Widget>[];

    // Section mouvements de caisse si il y en a
    if (cashMovements.isNotEmpty) {
      widgets.addAll([
        pw.SizedBox(height: 20),
        pw.Header(
          level: 1,
          text: 'Mouvements de caisse',
          textStyle: pw.TextStyle(font: fontBold, fontSize: 18),
        ),
        _buildCashMovementsTable(cashMovements, font, fontBold),
      ]);
    }

    // Section détails des catégories si disponible
    if (statistics.categorieDetails.isNotEmpty) {
      widgets.addAll([
        pw.SizedBox(height: 20),
        pw.Header(
          level: 1,
          text: 'Détail des catégories',
          textStyle: pw.TextStyle(font: fontBold, fontSize: 18),
        ),
        _buildDetailedCategoriesTable(statistics.categorieDetails, font, fontBold),
      ]);
    }

    return widgets;
  }

  // Contenu spécifique pour les vues de période
  List<pw.Widget> _buildPeriodSpecificSections(
    PeriodType periodType,
    List<DailyStatistics> periodStatistics,
    pw.Font font,
    pw.Font fontBold,
  ) {
    final widgets = <pw.Widget>[];

    if (periodStatistics.isNotEmpty) {
      // Ajout uniquement de l'analyse des performances (pas de redondance avec le résumé financier)
      widgets.addAll([
        pw.SizedBox(height: 20),
        pw.Header(
          level: 1,
          text: 'Analyse des performances',
          textStyle: pw.TextStyle(font: fontBold, fontSize: 18),
        ),
        _buildPeriodSummary(periodStatistics, font, fontBold),
      ]);

      // Détail jour par jour seulement si la période n'est pas trop longue
      if (periodStatistics.length <= 31) { // Maximum 1 mois
        final activeDays = periodStatistics.where((stat) => stat.total > 0).toList();
        
        // Détail des jours avec ventes
        if (activeDays.isNotEmpty) {
          widgets.addAll([
            pw.SizedBox(height: 20),
            pw.Header(
              level: 1,
              text: 'Détail des jours avec ventes',
              textStyle: pw.TextStyle(font: fontBold, fontSize: 18),
            ),
            _buildDailyStatsTable(activeDays, font, fontBold),
          ]);
        }
        
        // Informations de caisse des jours avec vente
        if (activeDays.isNotEmpty) {
          widgets.addAll([
            pw.SizedBox(height: 20),
            pw.Header(
              level: 1,
              text: 'Gestion de caisse - Jours avec vente',
              textStyle: pw.TextStyle(font: fontBold, fontSize: 18),
            ),
            _buildActiveDaysCashTable(activeDays, font, fontBold),
          ]);
        }
      }
    }

    return widgets;
  }

  // Table des mouvements de caisse
  pw.Widget _buildCashMovementsTable(
    List<CashMovement> movements,
    pw.Font font,
    pw.Font fontBold,
  ) {
    return pw.Table(
      border: pw.TableBorder.all(color: PdfColors.grey400),
      children: [
        // En-tête
        pw.TableRow(
          decoration: const pw.BoxDecoration(color: PdfColors.grey200),
          children: [
            pw.Padding(
              padding: const pw.EdgeInsets.all(8),
              child: pw.Text('Heure', style: pw.TextStyle(font: fontBold)),
            ),
            pw.Padding(
              padding: const pw.EdgeInsets.all(8),
              child: pw.Text('Type', style: pw.TextStyle(font: fontBold)),
            ),
            pw.Padding(
              padding: const pw.EdgeInsets.all(8),
              child: pw.Text('Montant', style: pw.TextStyle(font: fontBold), textAlign: pw.TextAlign.right),
            ),
            pw.Padding(
              padding: const pw.EdgeInsets.all(8),
              child: pw.Text('Justification', style: pw.TextStyle(font: fontBold)),
            ),
          ],
        ),
        // Données
        ...movements.map((movement) => pw.TableRow(
          children: [
            pw.Padding(
              padding: const pw.EdgeInsets.all(8),
              child: pw.Text(
                DateFormat('HH:mm').format(movement.date),
                style: pw.TextStyle(font: font),
              ),
            ),
            pw.Padding(
              padding: const pw.EdgeInsets.all(8),
              child: pw.Text(
                movement.type == CashMovementType.entry ? 'Entrée' : 'Sortie',
                style: pw.TextStyle(
                  font: font,
                  color: movement.type == CashMovementType.entry ? PdfColors.green800 : PdfColors.red800,
                ),
              ),
            ),
            pw.Padding(
              padding: const pw.EdgeInsets.all(8),
              child: pw.Text(
                '${movement.type == CashMovementType.entry ? '+' : '-'}${movement.amount.toStringAsFixed(2).replaceAll('.', ',')} €',
                style: pw.TextStyle(
                  font: font,
                  color: movement.type == CashMovementType.entry ? PdfColors.green800 : PdfColors.red800,
                ),
                textAlign: pw.TextAlign.right,
              ),
            ),
            pw.Padding(
              padding: const pw.EdgeInsets.all(8),
              child: pw.Text(
                movement.justification,
                style: pw.TextStyle(font: font),
              ),
            ),
          ],
        )),
        // Total
        if (movements.isNotEmpty) pw.TableRow(
          decoration: const pw.BoxDecoration(color: PdfColors.grey200),
          children: [
            pw.Padding(
              padding: const pw.EdgeInsets.all(8),
              child: pw.Text('TOTAL', style: pw.TextStyle(font: fontBold)),
            ),
            pw.Padding(
              padding: const pw.EdgeInsets.all(8),
              child: pw.Text(''),
            ),
            pw.Padding(
              padding: const pw.EdgeInsets.all(8),
              child: pw.Text(
                '${_calculateTotalCashMovements(movements).toStringAsFixed(2).replaceAll('.', ',')} €',
                style: pw.TextStyle(font: fontBold),
                textAlign: pw.TextAlign.right,
              ),
            ),
            pw.Padding(
              padding: const pw.EdgeInsets.all(8),
              child: pw.Text(''),
            ),
          ],
        ),
      ],
    );
  }

  // Table détaillée des catégories
  pw.Widget _buildDetailedCategoriesTable(
    List<CategoryTotal> categories,
    pw.Font font,
    pw.Font fontBold,
  ) {
    return pw.Table(
      border: pw.TableBorder.all(color: PdfColors.grey400),
      children: [
        // En-tête
        pw.TableRow(
          decoration: const pw.BoxDecoration(color: PdfColors.grey200),
          children: [
            pw.Padding(
              padding: const pw.EdgeInsets.all(8),
              child: pw.Text('Catégorie', style: pw.TextStyle(font: fontBold)),
            ),
            pw.Padding(
              padding: const pw.EdgeInsets.all(8),
              child: pw.Text('Nombre d\'articles', style: pw.TextStyle(font: fontBold), textAlign: pw.TextAlign.center),
            ),
            pw.Padding(
              padding: const pw.EdgeInsets.all(8),
              child: pw.Text('Montant', style: pw.TextStyle(font: fontBold), textAlign: pw.TextAlign.right),
            ),
          ],
        ),
        // Données
        ...categories.map((category) => pw.TableRow(
          children: [
            pw.Padding(
              padding: const pw.EdgeInsets.all(8),
              child: pw.Text(category.categoryDisplayName, style: pw.TextStyle(font: font)),
            ),
            pw.Padding(
              padding: const pw.EdgeInsets.all(8),
              child: pw.Text('${category.itemCount}', style: pw.TextStyle(font: font), textAlign: pw.TextAlign.center),
            ),
            pw.Padding(
              padding: const pw.EdgeInsets.all(8),
              child: pw.Text(
                '${category.total.toStringAsFixed(2).replaceAll('.', ',')} €',
                style: pw.TextStyle(font: font),
                textAlign: pw.TextAlign.right,
              ),
            ),
          ],
        )),
      ],
    );
  }

  // Résumé de période (uniquement pour informations complémentaires)
  pw.Widget _buildPeriodSummary(
    List<DailyStatistics> periodStats,
    pw.Font font,
    pw.Font fontBold,
  ) {
    // Filtrer les jours avec des ventes (éviter les jours à 0€)
    final activeDays = periodStats.where((stat) => stat.total > 0).toList();
    
    if (activeDays.isEmpty) {
      return pw.Text('Aucune vente durant cette période', style: pw.TextStyle(font: font));
    }

    final maxDay = activeDays.reduce((a, b) => a.total > b.total ? a : b);
    final minDay = activeDays.reduce((a, b) => a.total < b.total ? a : b);

    return pw.Table(
      border: pw.TableBorder.all(color: PdfColors.grey400),
      children: [
        pw.TableRow(
          decoration: const pw.BoxDecoration(color: PdfColors.grey200),
          children: [
            pw.Padding(
              padding: const pw.EdgeInsets.all(8),
              child: pw.Text('Analyse des performances', style: pw.TextStyle(font: fontBold)),
            ),
            pw.Padding(
              padding: const pw.EdgeInsets.all(8),
              child: pw.Text('Valeur', style: pw.TextStyle(font: fontBold), textAlign: pw.TextAlign.right),
            ),
          ],
        ),
        pw.TableRow(
          children: [
            pw.Padding(
              padding: const pw.EdgeInsets.all(8),
              child: pw.Text('Jours d\'activité', style: pw.TextStyle(font: font)),
            ),
            pw.Padding(
              padding: const pw.EdgeInsets.all(8),
              child: pw.Text('${activeDays.length} / ${periodStats.length}', style: pw.TextStyle(font: font), textAlign: pw.TextAlign.right),
            ),
          ],
        ),
        pw.TableRow(
          children: [
            pw.Padding(
              padding: const pw.EdgeInsets.all(8),
              child: pw.Text('Meilleure performance', style: pw.TextStyle(font: font)),
            ),
            pw.Padding(
              padding: const pw.EdgeInsets.all(8),
              child: pw.Text(
                '${DateFormat('dd/MM/yyyy').format(maxDay.date)} (${maxDay.total.toStringAsFixed(2).replaceAll('.', ',')} €)',
                style: pw.TextStyle(font: font),
                textAlign: pw.TextAlign.right,
              ),
            ),
          ],
        ),
        if (activeDays.length > 1) // N'afficher que s'il y a plusieurs jours actifs
          pw.TableRow(
            children: [
              pw.Padding(
                padding: const pw.EdgeInsets.all(8),
                child: pw.Text('Plus faible performance', style: pw.TextStyle(font: font)),
              ),
              pw.Padding(
                padding: const pw.EdgeInsets.all(8),
                child: pw.Text(
                  '${DateFormat('dd/MM/yyyy').format(minDay.date)} (${minDay.total.toStringAsFixed(2).replaceAll('.', ',')} €)',
                  style: pw.TextStyle(font: font),
                  textAlign: pw.TextAlign.right,
                ),
              ),
            ],
          ),
      ],
    );
  }

  // Calculer le total des mouvements de caisse
  double _calculateTotalCashMovements(List<CashMovement> movements) {
    return movements.fold(0.0, (total, movement) {
      return total + (movement.type == CashMovementType.entry ? movement.amount : -movement.amount);
    });
  }

  // Table des informations de caisse pour les jours sans vente
  pw.Widget _buildInactiveDaysCashTable(
    List<DailyStatistics> inactiveDays,
    pw.Font font,
    pw.Font fontBold,
  ) {
    return pw.Table(
      border: pw.TableBorder.all(color: PdfColors.grey400),
      columnWidths: {
        0: const pw.FlexColumnWidth(1.5),
        1: const pw.FlexColumnWidth(1),
        2: const pw.FlexColumnWidth(1),
        3: const pw.FlexColumnWidth(1),
        4: const pw.FlexColumnWidth(1),
      },
      children: [
        // En-tête
        pw.TableRow(
          decoration: const pw.BoxDecoration(color: PdfColors.grey200),
          children: [
            pw.Padding(
              padding: const pw.EdgeInsets.all(6),
              child: pw.Text('Date', style: pw.TextStyle(font: fontBold, fontSize: 10)),
            ),
            pw.Padding(
              padding: const pw.EdgeInsets.all(6),
              child: pw.Text('Fond ouv.', style: pw.TextStyle(font: fontBold, fontSize: 10), textAlign: pw.TextAlign.center),
            ),
            pw.Padding(
              padding: const pw.EdgeInsets.all(6),
              child: pw.Text('Fond ferm.', style: pw.TextStyle(font: fontBold, fontSize: 10), textAlign: pw.TextAlign.center),
            ),
            pw.Padding(
              padding: const pw.EdgeInsets.all(6),
              child: pw.Text('Coffre', style: pw.TextStyle(font: fontBold, fontSize: 10), textAlign: pw.TextAlign.center),
            ),
            pw.Padding(
              padding: const pw.EdgeInsets.all(6),
              child: pw.Text('Écart', style: pw.TextStyle(font: fontBold, fontSize: 10), textAlign: pw.TextAlign.center),
            ),
          ],
        ),
        // Données des jours inactifs
        ...inactiveDays.map((stat) {
          final double theoreticalCash = stat.fondCaisseOuverture + stat.totalCash; // Toujours 0 pour les jours inactifs
          final double actualCash = stat.fondCaisseFermeture + stat.montantCoffre;
          final double discrepancy = actualCash - theoreticalCash;
          
          return pw.TableRow(
            children: [
              pw.Padding(
                padding: const pw.EdgeInsets.all(6),
                child: pw.Text(
                  DateFormat('dd/MM/yyyy').format(stat.date),
                  style: pw.TextStyle(font: font, fontSize: 9),
                ),
              ),
              pw.Padding(
                padding: const pw.EdgeInsets.all(6),
                child: pw.Text(
                  '${stat.fondCaisseOuverture.toStringAsFixed(0).replaceAll('.', ',')}€',
                  style: pw.TextStyle(font: font, fontSize: 9),
                  textAlign: pw.TextAlign.center,
                ),
              ),
              pw.Padding(
                padding: const pw.EdgeInsets.all(6),
                child: pw.Text(
                  '${stat.fondCaisseFermeture.toStringAsFixed(0).replaceAll('.', ',')}€',
                  style: pw.TextStyle(font: font, fontSize: 9),
                  textAlign: pw.TextAlign.center,
                ),
              ),
              pw.Padding(
                padding: const pw.EdgeInsets.all(6),
                child: pw.Text(
                  '${stat.montantCoffre.toStringAsFixed(0).replaceAll('.', ',')}€',
                  style: pw.TextStyle(font: font, fontSize: 9),
                  textAlign: pw.TextAlign.center,
                ),
              ),
              pw.Padding(
                padding: const pw.EdgeInsets.all(6),
                child: pw.Text(
                  '${discrepancy >= 0 ? '+' : ''}${discrepancy.toStringAsFixed(2).replaceAll('.', ',')}€',
                  style: pw.TextStyle(
                    font: font,
                    fontSize: 9,
                    color: discrepancy == 0 
                        ? PdfColors.black 
                        : (discrepancy > 0 ? PdfColors.green800 : PdfColors.red800),
                  ),
                  textAlign: pw.TextAlign.center,
                ),
              ),
            ],
          );
        }),
      ],
    );
  }

  // Table des informations de caisse pour les jours avec vente
  pw.Widget _buildActiveDaysCashTable(
    List<DailyStatistics> activeDays,
    pw.Font font,
    pw.Font fontBold,
  ) {
    return pw.Table(
      border: pw.TableBorder.all(color: PdfColors.grey400),
      columnWidths: {
        0: const pw.FlexColumnWidth(1.5),
        1: const pw.FlexColumnWidth(1),
        2: const pw.FlexColumnWidth(1),
        3: const pw.FlexColumnWidth(1),
        4: const pw.FlexColumnWidth(1),
        5: const pw.FlexColumnWidth(1),
      },
      children: [
        // En-tête
        pw.TableRow(
          decoration: const pw.BoxDecoration(color: PdfColors.grey200),
          children: [
            pw.Padding(
              padding: const pw.EdgeInsets.all(6),
              child: pw.Text('Date', style: pw.TextStyle(font: fontBold, fontSize: 10)),
            ),
            pw.Padding(
              padding: const pw.EdgeInsets.all(6),
              child: pw.Text('Fond ouv.', style: pw.TextStyle(font: fontBold, fontSize: 10), textAlign: pw.TextAlign.center),
            ),
            pw.Padding(
              padding: const pw.EdgeInsets.all(6),
              child: pw.Text('Fond ferm.', style: pw.TextStyle(font: fontBold, fontSize: 10), textAlign: pw.TextAlign.center),
            ),
            pw.Padding(
              padding: const pw.EdgeInsets.all(6),
              child: pw.Text('Coffre', style: pw.TextStyle(font: fontBold, fontSize: 10), textAlign: pw.TextAlign.center),
            ),
            pw.Padding(
              padding: const pw.EdgeInsets.all(6),
              child: pw.Text('Vente', style: pw.TextStyle(font: fontBold, fontSize: 10), textAlign: pw.TextAlign.center),
            ),
            pw.Padding(
              padding: const pw.EdgeInsets.all(6),
              child: pw.Text('Écart', style: pw.TextStyle(font: fontBold, fontSize: 10), textAlign: pw.TextAlign.center),
            ),
          ],
        ),
        // Données des jours actifs
        ...activeDays.map((stat) {
          final double theoreticalCash = stat.fondCaisseOuverture + stat.totalCash;
          final double actualCash = stat.fondCaisseFermeture + stat.montantCoffre;
          final double discrepancy = actualCash - theoreticalCash;
          
          return pw.TableRow(
            children: [
              pw.Padding(
                padding: const pw.EdgeInsets.all(6),
                child: pw.Text(
                  DateFormat('dd/MM/yyyy').format(stat.date),
                  style: pw.TextStyle(font: font, fontSize: 9),
                ),
              ),
              pw.Padding(
                padding: const pw.EdgeInsets.all(6),
                child: pw.Text(
                  '${stat.fondCaisseOuverture.toStringAsFixed(0).replaceAll('.', ',')}€',
                  style: pw.TextStyle(font: font, fontSize: 9),
                  textAlign: pw.TextAlign.center,
                ),
              ),
              pw.Padding(
                padding: const pw.EdgeInsets.all(6),
                child: pw.Text(
                  '${stat.fondCaisseFermeture.toStringAsFixed(0).replaceAll('.', ',')}€',
                  style: pw.TextStyle(font: font, fontSize: 9),
                  textAlign: pw.TextAlign.center,
                ),
              ),
              pw.Padding(
                padding: const pw.EdgeInsets.all(6),
                child: pw.Text(
                  '${stat.montantCoffre.toStringAsFixed(0).replaceAll('.', ',')}€',
                  style: pw.TextStyle(font: font, fontSize: 9),
                  textAlign: pw.TextAlign.center,
                ),
              ),
              pw.Padding(
                padding: const pw.EdgeInsets.all(6),
                child: pw.Text(
                  '${stat.totalCash.toStringAsFixed(0).replaceAll('.', ',')}€',
                  style: pw.TextStyle(font: font, fontSize: 9),
                  textAlign: pw.TextAlign.center,
                ),
              ),
              pw.Padding(
                padding: const pw.EdgeInsets.all(6),
                child: pw.Text(
                  '${discrepancy >= 0 ? '+' : ''}${discrepancy.toStringAsFixed(2).replaceAll('.', ',')}€',
                  style: pw.TextStyle(
                    font: font,
                    fontSize: 9,
                    color: discrepancy == 0 
                        ? PdfColors.black 
                        : (discrepancy > 0 ? PdfColors.green800 : PdfColors.red800),
                  ),
                  textAlign: pw.TextAlign.center,
                ),
              ),
            ],
          );
        }),
      ],
    );
  }

  // Résumé financier pour les vues de période
  pw.Widget _buildPeriodFinancialSummary(
    List<DailyStatistics> periodStats,
    pw.Font font,
    pw.Font fontBold,
  ) {
    if (periodStats.isEmpty) {
      return pw.Text('Aucune donnée disponible', style: pw.TextStyle(font: font));
    }

    // Calculs financiers pour la période
    final totalSales = periodStats.fold(0.0, (sum, stat) => sum + stat.total);
    final totalCash = periodStats.fold(0.0, (sum, stat) => sum + stat.totalCash);
    final totalBancontact = periodStats.fold(0.0, (sum, stat) => sum + stat.totalBancontact);
    final totalVirement = periodStats.fold(0.0, (sum, stat) => sum + stat.totalVirement);
    final totalDays = periodStats.length;
    final averageDaily = totalSales / totalDays;
    
    // Tendance (comparaison première moitié vs seconde moitié)
    final halfPoint = (periodStats.length / 2).floor();
    final firstHalf = periodStats.take(halfPoint);
    final secondHalf = periodStats.skip(halfPoint);
    
    final firstHalfAvg = firstHalf.isEmpty ? 0.0 : 
        firstHalf.fold(0.0, (sum, stat) => sum + stat.total) / firstHalf.length;
    final secondHalfAvg = secondHalf.isEmpty ? 0.0 : 
        secondHalf.fold(0.0, (sum, stat) => sum + stat.total) / secondHalf.length;
    
    final trendPercentage = firstHalfAvg == 0 ? 0.0 : 
        ((secondHalfAvg - firstHalfAvg) / firstHalfAvg) * 100;

    // Répartition des paiements en pourcentages
    final cashPercentage = totalSales == 0 ? 0.0 : (totalCash / totalSales) * 100;
    final bancontactPercentage = totalSales == 0 ? 0.0 : (totalBancontact / totalSales) * 100;
    final virementPercentage = totalSales == 0 ? 0.0 : (totalVirement / totalSales) * 100;

    return pw.Table(
      border: pw.TableBorder.all(color: PdfColors.grey400),
      children: [
        pw.TableRow(
          decoration: const pw.BoxDecoration(color: PdfColors.grey200),
          children: [
            pw.Padding(
              padding: const pw.EdgeInsets.all(8),
              child: pw.Text('Indicateur financier', style: pw.TextStyle(font: fontBold)),
            ),
            pw.Padding(
              padding: const pw.EdgeInsets.all(8),
              child: pw.Text('Valeur', style: pw.TextStyle(font: fontBold), textAlign: pw.TextAlign.right),
            ),
          ],
        ),
        pw.TableRow(
          children: [
            pw.Padding(
              padding: const pw.EdgeInsets.all(8),
              child: pw.Text('Chiffre d\'affaires total', style: pw.TextStyle(font: font)),
            ),
            pw.Padding(
              padding: const pw.EdgeInsets.all(8),
              child: pw.Text(
                '${totalSales.toStringAsFixed(2).replaceAll('.', ',')} €',
                style: pw.TextStyle(font: fontBold),
                textAlign: pw.TextAlign.right,
              ),
            ),
          ],
        ),
        pw.TableRow(
          children: [
            pw.Padding(
              padding: const pw.EdgeInsets.all(8),
              child: pw.Text('Moyenne journalière', style: pw.TextStyle(font: font)),
            ),
            pw.Padding(
              padding: const pw.EdgeInsets.all(8),
              child: pw.Text(
                '${averageDaily.toStringAsFixed(2).replaceAll('.', ',')} €',
                style: pw.TextStyle(font: font),
                textAlign: pw.TextAlign.right,
              ),
            ),
          ],
        ),
        pw.TableRow(
          children: [
            pw.Padding(
              padding: const pw.EdgeInsets.all(8),
              child: pw.Text('Tendance période', style: pw.TextStyle(font: font)),
            ),
            pw.Padding(
              padding: const pw.EdgeInsets.all(8),
              child: pw.Text(
                '${trendPercentage >= 0 ? '+' : ''}${trendPercentage.toStringAsFixed(1).replaceAll('.', ',')}%',
                style: pw.TextStyle(
                  font: font,
                  color: trendPercentage >= 0 ? PdfColors.green800 : PdfColors.red800,
                ),
                textAlign: pw.TextAlign.right,
              ),
            ),
          ],
        ),
        pw.TableRow(
          children: [
            pw.Padding(
              padding: const pw.EdgeInsets.all(8),
              child: pw.Text('Répartition espèces/Bancontact', style: pw.TextStyle(font: font)),
            ),
            pw.Padding(
              padding: const pw.EdgeInsets.all(8),
              child: pw.Text(
                '${cashPercentage.toStringAsFixed(1).replaceAll('.', ',')}% / ${(bancontactPercentage + virementPercentage).toStringAsFixed(1).replaceAll('.', ',')}%',
                style: pw.TextStyle(font: font),
                textAlign: pw.TextAlign.right,
              ),
            ),
          ],
        ),
      ],
    );
  }
}
