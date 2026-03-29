import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';

import 'package:flutter/services.dart' show rootBundle;
import 'package:intl/intl.dart';
import 'package:path_provider/path_provider.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;

import '../core/api_log_model.dart';
import 'pdf_json_syntax.dart';

class PdfShareHelper {
  static const double _pageWidthPt = 420;
  static const double _marginPt = 20;
  static const double _cardPaddingPt = 20;
  static const double _codeFontSize = 9;
  static const double _lineHeightPt = 11;

  static PdfColor getMethodPdfColor(String? method) {
    if (method == null) return PdfColors.grey;
    switch (method.toUpperCase()) {
      case 'GET':
        return PdfColors.blue;
      case 'POST':
        return PdfColors.green;
      case 'PUT':
      case 'PATCH':
        return PdfColors.orange;
      case 'DELETE':
        return PdfColors.red;
      default:
        return PdfColors.grey;
    }
  }

  static PdfColor getStatusPdfColor(int? statusCode) {
    if (statusCode == null) return PdfColors.grey;
    if (statusCode >= 200 && statusCode < 300) return PdfColors.green;
    if (statusCode >= 300 && statusCode < 400) return PdfColors.blue;
    if (statusCode >= 400 && statusCode < 500) return PdfColors.orange;
    return PdfColors.red;
  }

  static Future<pw.ThemeData> _loadTheme() async {
    try {
      final regular = await rootBundle.load(
        'packages/aun_api_logger/assets/fonts/NotoSans-Regular.ttf',
      );
      final bold = await rootBundle.load(
        'packages/aun_api_logger/assets/fonts/NotoSans-Bold.ttf',
      );
      return pw.ThemeData.withFont(
        base: pw.Font.ttf(regular),
        bold: pw.Font.ttf(bold),
      );
    } catch (_) {
      return pw.ThemeData.base();
    }
  }

  /// One continuous page sized to fit the expanded-log layout (no A4 / no pagination).
  static Future<File> generatePdf(
    ApiLogModel log,
    String displayEndpoint,
  ) async {
    final theme = await _loadTheme();
    final methodColor = getMethodPdfColor(log.method);
    final statusColor = getStatusPdfColor(log.statusCode);

    final timeStr = DateFormat(
      'hh-mm-ss_a',
    ).format(DateTime.fromMillisecondsSinceEpoch(log.requestTime));
    final displayTime = DateFormat(
      'hh:mm:ss a',
    ).format(DateTime.fromMillisecondsSinceEpoch(log.requestTime));

    final endpointSlug = displayEndpoint
        .replaceAll(RegExp(r'[^a-zA-Z0-9_\-]'), '_')
        .replaceAll(RegExp(r'_+'), '_')
        .replaceAll(RegExp(r'^_|_$'), '');
    final fileName = '${log.method}_${endpointSlug}_$timeStr.pdf';

    final innerWidth = _pageWidthPt - (_marginPt * 2) - (_cardPaddingPt * 2);

    final content = <pw.Widget>[];

    content.add(
      pw.Row(
        crossAxisAlignment: pw.CrossAxisAlignment.start,
        children: [
          pw.Container(
            width: 5,
            height: 50,
            decoration: pw.BoxDecoration(
              color: methodColor,
              borderRadius: pw.BorderRadius.circular(2),
            ),
          ),
          pw.SizedBox(width: 12),
          pw.Expanded(
            child: pw.Column(
              crossAxisAlignment: pw.CrossAxisAlignment.start,
              children: [
                pw.Row(
                  children: [
                    pw.Container(
                      padding: const pw.EdgeInsets.symmetric(
                        horizontal: 8,
                        vertical: 3,
                      ),
                      decoration: pw.BoxDecoration(
                        color: methodColor.flatten().shade(0.9),
                        borderRadius: pw.BorderRadius.circular(4),
                      ),
                      child: pw.Text(
                        log.method,
                        style: pw.TextStyle(
                          color: methodColor,
                          fontSize: 11,
                          fontWeight: pw.FontWeight.bold,
                        ),
                      ),
                    ),
                    pw.SizedBox(width: 10),
                    pw.Text(
                      log.statusCode?.toString() ?? 'PENDING',
                      style: pw.TextStyle(
                        color: statusColor,
                        fontSize: 14,
                        fontWeight: pw.FontWeight.bold,
                      ),
                    ),
                    pw.Spacer(),
                    pw.Text(
                      displayTime,
                      style: pw.TextStyle(
                        fontSize: 10,
                        color: PdfColors.grey600,
                      ),
                    ),
                  ],
                ),
                pw.SizedBox(height: 6),
                pw.Text(
                  displayEndpoint,
                  style: pw.TextStyle(
                    fontWeight: pw.FontWeight.bold,
                    fontSize: 13,
                    color: PdfColors.black,
                  ),
                  softWrap: true,
                ),
                pw.SizedBox(height: 4),
                pw.Text(
                  '${log.durationMs}ms',
                  style: pw.TextStyle(fontSize: 11, color: PdfColors.grey600),
                ),
              ],
            ),
          ),
        ],
      ),
    );

    content.add(pw.SizedBox(height: 12));
    content.add(pw.Divider(color: PdfColors.grey300, thickness: 0.5));

    _addPlainSection(content, theme, 'URL', log.url);
    _addJsonSection(
      content,
      theme,
      'Request Headers',
      _prettyJson(log.requestHeaders),
    );
    final bodyType = _getRequestBodyType(log.requestHeaders);
    _addJsonSection(
      content,
      theme,
      'Request Body$bodyType',
      _prettyJson(log.requestBody),
    );
    _addJsonSection(
      content,
      theme,
      'Response Headers',
      _prettyJson(log.responseHeaders),
    );
    _addJsonSection(
      content,
      theme,
      'Response Body',
      _prettyJson(log.responseBody),
    );

    final pageHeight = _estimatePageHeight(
      log: log,
      displayEndpoint: displayEndpoint,
      innerWidth: innerWidth,
    );

    final pdf = pw.Document(theme: theme);

    pdf.addPage(
      pw.Page(
        pageFormat: PdfPageFormat(
          _pageWidthPt,
          pageHeight,
          marginAll: _marginPt,
        ),
        build: (pw.Context context) {
          return pw.Container(
            decoration: pw.BoxDecoration(
              color: PdfColors.white,
              borderRadius: pw.BorderRadius.circular(8),
              border: pw.Border.all(color: PdfColors.grey300, width: 1.5),
            ),
            padding: const pw.EdgeInsets.all(_cardPaddingPt),
            child: pw.Column(
              crossAxisAlignment: pw.CrossAxisAlignment.stretch,
              mainAxisSize: pw.MainAxisSize.min,
              children: content,
            ),
          );
        },
      ),
    );

    final Uint8List pdfBytes = await pdf.save();

    final directory = await getTemporaryDirectory();
    final file = File('${directory.path}/$fileName');
    await file.writeAsBytes(pdfBytes);

    return file;
  }

  static double _estimatePageHeight({
    required ApiLogModel log,
    required String displayEndpoint,
    required double innerWidth,
  }) {
    const headerBlock = 130.0;
    const divider = 14.0;
    const cardPad = _cardPaddingPt * 2;
    const sectionTitle = 34.0;
    const sectionBoxPad = 24.0;
    const approxChar = 5.0;

    double h = cardPad + headerBlock + divider;

    void addSection(String? raw, {required bool json}) {
      if (raw == null || raw.isEmpty) return;
      final text = json ? (_prettyJson(raw) ?? raw) : raw;
      h += 12 + sectionTitle;
      final lines = _estimateWrappedLines(text, innerWidth, approxChar);
      h += lines * _lineHeightPt + sectionBoxPad;
    }

    addSection(log.url, json: false);
    addSection(log.requestHeaders, json: true);
    addSection(log.requestBody, json: true);
    addSection(log.responseHeaders, json: true);
    addSection(log.responseBody, json: true);

    final marginV = _marginPt * 2;
    return (h * 1.15 + marginV).clamp(320, 200000);
  }

  static int _estimateWrappedLines(
    String text,
    double innerWidth,
    double charW,
  ) {
    final charsPerLine = (innerWidth / charW).floor().clamp(24, 120);
    var total = 0;
    for (final line in text.split('\n')) {
      if (line.isEmpty) {
        total += 1;
      } else {
        total += (line.length / charsPerLine).ceil();
      }
    }
    return total;
  }

  static void _addPlainSection(
    List<pw.Widget> content,
    pw.ThemeData theme,
    String title,
    String? text,
  ) {
    if (text == null || text.isEmpty) return;
    content.add(pw.SizedBox(height: 12));
    content.add(
      pw.Text(
        title,
        style: pw.TextStyle(
          fontWeight: pw.FontWeight.bold,
          fontSize: 13,
          color: PdfColors.black,
        ),
      ),
    );
    content.add(pw.SizedBox(height: 6));
    content.add(
      pw.Container(
        width: double.infinity,
        padding: const pw.EdgeInsets.all(12),
        decoration: pw.BoxDecoration(
          color: const PdfColor(0.98, 0.98, 0.98),
          borderRadius: pw.BorderRadius.circular(6),
          border: pw.Border.all(color: PdfColors.grey200),
        ),
        child: pw.Text(
          text,
          style: theme.defaultTextStyle.copyWith(
            fontSize: _codeFontSize,
            lineSpacing: 2,
          ),
          softWrap: true,
        ),
      ),
    );
  }

  static void _addJsonSection(
    List<pw.Widget> content,
    pw.ThemeData theme,
    String title,
    String? text,
  ) {
    if (text == null || text.isEmpty) return;
    final base = theme.defaultTextStyle.copyWith(
      fontSize: _codeFontSize,
      lineSpacing: 2,
    );

    content.add(pw.SizedBox(height: 12));
    content.add(
      pw.Text(
        title,
        style: pw.TextStyle(
          fontWeight: pw.FontWeight.bold,
          fontSize: 13,
          color: PdfColors.black,
        ),
      ),
    );
    content.add(pw.SizedBox(height: 6));
    content.add(
      pw.Container(
        width: double.infinity,
        padding: const pw.EdgeInsets.all(12),
        decoration: pw.BoxDecoration(
          color: const PdfColor(0.98, 0.98, 0.98),
          borderRadius: pw.BorderRadius.circular(6),
          border: pw.Border.all(color: PdfColors.grey200),
        ),
        child: pw.RichText(
          text: pw.TextSpan(
            style: base,
            children: PdfJsonSyntax.highlight(text, base),
          ),
        ),
      ),
    );
  }

  static String? _prettyJson(String? raw) {
    if (raw == null || raw.isEmpty) return null;
    try {
      final decoded = jsonDecode(raw);
      return const JsonEncoder.withIndent('  ').convert(decoded);
    } catch (_) {
      return raw;
    }
  }

  static String _getRequestBodyType(String? requestHeaders) {
    try {
      if (requestHeaders == null || requestHeaders.isEmpty) return '';
      final headers = jsonDecode(requestHeaders) as Map<String, dynamic>;
      var contentType = '';
      headers.forEach((key, value) {
        if (key.toLowerCase() == 'content-type') {
          contentType = value.toString().toLowerCase();
        }
      });
      if (contentType.contains('multipart/form-data')) return ' (FormData)';
      if (contentType.contains('application/json')) return ' (JSON)';
      if (contentType.contains('application/x-www-form-urlencoded')) {
        return ' (FormURLEncoded)';
      }
    } catch (_) {}
    return '';
  }
}
