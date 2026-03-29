import 'dart:io';
import 'dart:typed_data';
import 'dart:ui' as ui;

import 'package:intl/intl.dart';
import 'package:path_provider/path_provider.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;

class PdfShareHelper {
  /// Wraps the already-rendered share screenshot into a single-page PDF.
  ///
  /// [pixelRatio] must match the value used when capturing the screenshot so
  /// that the PDF page dimensions map 1-to-1 to the original logical-pixel
  /// size of the widget, preventing the content from appearing zoomed.
  static Future<File> generatePdfFromImageBytes({
    required Uint8List imageBytes,
    required String method,
    required String displayEndpoint,
    required int requestTime,
    double pixelRatio = 1.0,
  }) async {
    final timeStr = DateFormat(
      'hh-mm-ss_a',
    ).format(DateTime.fromMillisecondsSinceEpoch(requestTime));
    final endpointSlug = displayEndpoint
        .replaceAll(RegExp(r'[^a-zA-Z0-9_\-]'), '_')
        .replaceAll(RegExp(r'_+'), '_')
        .replaceAll(RegExp(r'^_|_$'), '');
    final fileName = '${method}_${endpointSlug}_$timeStr.pdf';

    final imageSize = await _decodeImageSize(imageBytes);
    // Divide by pixelRatio to recover logical pixel dimensions — these become
    // the PDF page dimensions in points so the content is not zoomed vs screen.
    final pageWidth = (imageSize.width / pixelRatio).clamp(280.0, 2000.0);
    final pageHeight = (imageSize.height / pixelRatio).clamp(320.0, 20000.0);

    final pdf = pw.Document();
    final image = pw.MemoryImage(imageBytes);
    pdf.addPage(
      pw.Page(
        margin: pw.EdgeInsets.zero,
        pageFormat: PdfPageFormat(pageWidth, pageHeight),
        build: (pw.Context context) {
          return pw.SizedBox.expand(
            child: pw.Image(image, fit: pw.BoxFit.fill),
          );
        },
      ),
    );

    final pdfBytes = await pdf.save();
    final directory = await getTemporaryDirectory();
    final file = File('${directory.path}/$fileName');
    await file.writeAsBytes(pdfBytes);
    return file;
  }

  static Future<ui.Size> _decodeImageSize(Uint8List bytes) async {
    final codec = await ui.instantiateImageCodec(bytes);
    try {
      final frame = await codec.getNextFrame();
      final image = frame.image;
      try {
        return ui.Size(image.width.toDouble(), image.height.toDouble());
      } finally {
        image.dispose();
      }
    } finally {
      codec.dispose();
    }
  }
}
