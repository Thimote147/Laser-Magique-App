import 'dart:typed_data';
import 'package:flutter/services.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart';
import 'package:intl/intl.dart';
import '../models/daily_statistics_model.dart';
import '../viewmodels/statistics_view_model.dart';

class PdfExportService {
  Future<Uint8List> generateStatisticsReport({
    required DailyStatistics statistics,
    required PeriodType periodType,
    required DateTime startDate,
    required DateTime endDate,
    List<DailyStatistics> periodStatistics = const [],
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

    // Génération du PDF
    pdf.addPage(
      pw.MultiPage(
        pageFormat: PdfPageFormat.a4,
        margin: const pw.EdgeInsets.all(32),
        build: (pw.Context context) {
          return [
            pw.Header(
              level: 0,
              child: pw.Row(
                mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                children: [
                  pw.Text(
                    'Rapport de Statistiques',
                    style: pw.TextStyle(font: fontBold, fontSize: 24),
                  ),
                  pw.Text(
                    DateFormat('dd/MM/yyyy').format(DateTime.now()),
                    style: pw.TextStyle(font: font, fontSize: 14),
                  ),
                ],
              ),
            ),
            pw.SizedBox(height: 20),
            pw.Container(
              padding: const pw.EdgeInsets.all(10),
              decoration: pw.BoxDecoration(
                color: PdfColors.grey200,
                borderRadius: pw.BorderRadius.circular(5),
              ),
              child: pw.Column(
                crossAxisAlignment: pw.CrossAxisAlignment.start,
                children: [
                  pw.Text(
                    'Période: $periodText',
                    style: pw.TextStyle(font: fontBold, fontSize: 14),
                  ),
                ],
              ),
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

            // Résumé de caisse
            pw.Header(
              level: 1,
              text: 'Résumé de caisse',
              textStyle: pw.TextStyle(font: fontBold, fontSize: 18),
            ),
            _buildSummaryTable(statistics, font, fontBold),
            pw.SizedBox(height: 15),

            // Contrôle de caisse
            pw.Container(
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
            ),

            // Si c'est une période, affichons les statistiques journalières
            if (periodType != PeriodType.day &&
                periodStatistics.isNotEmpty) ...[
              pw.SizedBox(height: 30),
              pw.Header(
                level: 1,
                text: 'Détail jour par jour',
                textStyle: pw.TextStyle(font: fontBold, fontSize: 18),
              ),
              _buildDailyStatsTable(periodStatistics, font, fontBold),
            ],

            pw.SizedBox(height: 20),
            pw.Footer(
              title: pw.Text(
                'Laser Magique - Rapport généré le ${DateFormat('dd/MM/yyyy à HH:mm').format(DateTime.now())}',
                style: pw.TextStyle(
                  font: font,
                  fontSize: 10,
                  color: PdfColors.grey700,
                ),
                textAlign: pw.TextAlign.center,
              ),
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
            )
            .toList(),
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
}
