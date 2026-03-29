import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';

import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:path_provider/path_provider.dart';
import 'package:intl/intl.dart';

import '../core/api_log_model.dart';

class PdfShareHelper {
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

  /// Generates a PDF file from the given log and returns the File.
  static Future<File> generatePdf(ApiLogModel log, String displayEndpoint) async {
    final methodColor = getMethodPdfColor(log.method);
    final statusColor = getStatusPdfColor(log.statusCode);

    final timeStr = DateFormat('hh-mm-ss_a').format(
      DateTime.fromMillisecondsSinceEpoch(log.requestTime),
    );
    final displayTime = DateFormat('hh:mm:ss a').format(
      DateTime.fromMillisecondsSinceEpoch(log.requestTime),
    );

    // Build sanitized filename
    final endpointSlug = displayEndpoint
        .replaceAll(RegExp(r'[^a-zA-Z0-9_\-]'), '_')
        .replaceAll(RegExp(r'_+'), '_')
        .replaceAll(RegExp(r'^_|_$'), '');
    final fileName = '${log.method}_${endpointSlug}_$timeStr.pdf';

    // Build PDF content widgets
    final List<pw.Widget> content = [];

    // --- Header section ---
    content.add(
      pw.Row(
        crossAxisAlignment: pw.CrossAxisAlignment.start,
        children: [
          // Left color bar
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
                    // Method badge
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
                    // Status code
                    pw.Text(
                      log.statusCode?.toString() ?? 'PENDING',
                      style: pw.TextStyle(
                        color: statusColor,
                        fontSize: 14,
                        fontWeight: pw.FontWeight.bold,
                      ),
                    ),
                    pw.Spacer(),
                    // Timestamp
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
                // Endpoint
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
                // Duration
                pw.Text(
                  '${log.durationMs}ms',
                  style: pw.TextStyle(
                    fontSize: 11,
                    color: PdfColors.grey600,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );

    content.add(pw.SizedBox(height: 12));
    content.add(pw.Divider(color: PdfColors.grey300, thickness: 0.5));

    // --- URL ---
    _addSection(content, 'URL', log.url);

    // --- Request Headers ---
    _addSection(content, 'Request Headers', _prettyJson(log.requestHeaders));

    // --- Request Body ---
    final bodyType = _getRequestBodyType(log.requestHeaders);
    _addSection(
      content,
      'Request Body$bodyType',
      _prettyJson(log.requestBody),
    );

    // --- Response Headers ---
    _addSection(content, 'Response Headers', _prettyJson(log.responseHeaders));

    // --- Response Body ---
    _addSection(content, 'Response Body', _prettyJson(log.responseBody));

    // Calculate approximate content height
    // We use a very tall page so there's no page break
    const a4Width = 595.28; // A4 width in points
    const margin = 40.0;

    final pdf = pw.Document();

    pdf.addPage(
      pw.Page(
        pageFormat: const PdfPageFormat(
          a4Width,
          50000, // Very tall single page — no page breaks
          marginAll: margin,
        ),
        build: (pw.Context context) {
          return pw.Container(
            decoration: pw.BoxDecoration(
              color: PdfColors.white,
              borderRadius: pw.BorderRadius.circular(8),
              border: pw.Border.all(color: PdfColors.grey300, width: 1.5),
            ),
            padding: const pw.EdgeInsets.all(20),
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

  static void _addSection(List<pw.Widget> content, String title, String? text) {
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
          style: const pw.TextStyle(
            fontSize: 10,
            lineSpacing: 2,
          ),
          softWrap: true,
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
      String contentType = '';
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
