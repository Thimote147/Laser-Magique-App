import 'package:flutter/services.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:intl/intl.dart';

class PdfHeaderService {
  static const String _companyName = 'Laser Magique';
  static const String _companyAddress = 'Drève de l\'infante 27b, 1410 Waterloo, Belgique';
  static const String _iconPath = 'assets/images/icon.jpeg';
  
  static pw.MemoryImage? _cachedLogo;
  
  static Future<pw.MemoryImage?> _loadLogo() async {
    if (_cachedLogo != null) return _cachedLogo;
    
    try {
      final ByteData data = await rootBundle.load(_iconPath);
      final Uint8List bytes = data.buffer.asUint8List();
      _cachedLogo = pw.MemoryImage(bytes);
      return _cachedLogo;
    } catch (e) {
      return null;
    }
  }
  
  static Future<pw.Widget> buildStandardHeader({
    required String title,
    required pw.Font font,
    required pw.Font fontBold,
    String? subtitle,
    bool showLogo = true,
    bool showDate = true,
  }) async {
    final logo = showLogo ? await _loadLogo() : null;
    
    return pw.Container(
      padding: const pw.EdgeInsets.only(bottom: 20),
      child: pw.Column(
        crossAxisAlignment: pw.CrossAxisAlignment.start,
        children: [
          pw.Row(
            mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
            crossAxisAlignment: pw.CrossAxisAlignment.start,
            children: [
              pw.Expanded(
                child: pw.Row(
                  children: [
                    if (logo != null) ...[
                      pw.Image(
                        logo,
                        width: 50,
                        height: 50,
                        fit: pw.BoxFit.contain,
                      ),
                      pw.SizedBox(width: 16),
                    ],
                    pw.Expanded(
                      child: pw.Column(
                        crossAxisAlignment: pw.CrossAxisAlignment.start,
                        children: [
                          pw.Text(
                            _companyName,
                            style: pw.TextStyle(
                              font: fontBold,
                              fontSize: 20,
                              color: PdfColors.black,
                            ),
                          ),
                          pw.SizedBox(height: 4),
                          pw.Text(
                            _companyAddress,
                            style: pw.TextStyle(
                              font: font,
                              fontSize: 10,
                              color: PdfColors.grey700,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
              if (showDate)
                pw.Text(
                  DateFormat('dd/MM/yyyy').format(DateTime.now()),
                  style: pw.TextStyle(
                    font: font,
                    fontSize: 12,
                    color: PdfColors.grey700,
                  ),
                ),
            ],
          ),
          pw.SizedBox(height: 20),
          pw.Divider(color: PdfColors.grey400),
          pw.SizedBox(height: 20),
          pw.Text(
            title,
            style: pw.TextStyle(
              font: fontBold,
              fontSize: 24,
              color: PdfColors.black,
            ),
          ),
          if (subtitle != null) ...[
            pw.SizedBox(height: 8),
            pw.Text(
              subtitle,
              style: pw.TextStyle(
                font: font,
                fontSize: 16,
                color: PdfColors.grey700,
              ),
            ),
          ],
        ],
      ),
    );
  }
  
  static pw.Widget buildStandardFooter({
    required pw.Font font,
    String? additionalText,
  }) {
    return pw.Container(
      padding: const pw.EdgeInsets.only(top: 20),
      child: pw.Column(
        children: [
          pw.Divider(color: PdfColors.grey400),
          pw.SizedBox(height: 10),
          pw.Text(
            additionalText ?? 
            '$_companyName - Document généré le ${DateFormat('dd/MM/yyyy à HH:mm').format(DateTime.now())}',
            style: pw.TextStyle(
              font: font,
              fontSize: 10,
              color: PdfColors.grey700,
            ),
            textAlign: pw.TextAlign.center,
          ),
        ],
      ),
    );
  }
  
  static pw.Widget buildPeriodInfoBox({
    required String periodText,
    required pw.Font font,
    required pw.Font fontBold,
  }) {
    return pw.Container(
      padding: const pw.EdgeInsets.all(16),
      decoration: pw.BoxDecoration(
        color: PdfColors.grey100,
        borderRadius: pw.BorderRadius.circular(8),
        border: pw.Border.all(color: PdfColors.grey300),
      ),
      child: pw.Row(
        children: [
          pw.Container(
            width: 4,
            height: 40,
            decoration: pw.BoxDecoration(
              color: PdfColors.blue,
              borderRadius: pw.BorderRadius.circular(2),
            ),
          ),
          pw.SizedBox(width: 12),
          pw.Column(
            crossAxisAlignment: pw.CrossAxisAlignment.start,
            children: [
              pw.Text(
                'Période',
                style: pw.TextStyle(
                  font: font,
                  fontSize: 12,
                  color: PdfColors.grey700,
                ),
              ),
              pw.SizedBox(height: 4),
              pw.Text(
                periodText,
                style: pw.TextStyle(
                  font: fontBold,
                  fontSize: 16,
                  color: PdfColors.black,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}