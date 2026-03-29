import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;

/// JSON syntax highlighting for [pw.RichText], aligned with [JsonCodeBlock] colors.
class PdfJsonSyntax {
  static final PdfColor keyColor = PdfColor.fromInt(0xFF00897B);
  static final PdfColor stringColor = PdfColor.fromInt(0xFFF57F17);
  static final PdfColor numberColor = PdfColor.fromInt(0xFF7B1FA2);
  static final PdfColor boolNullColor = PdfColor.fromInt(0xFFD32F2F);
  static final PdfColor bracketColor = PdfColor.fromInt(0xFF757575);
  static final PdfColor defaultColor = PdfColor.fromInt(0xFF424242);

  static final RegExp _token = RegExp(
    r'("(?:[^"\\]|\\.)*")\s*(:)|("(?:[^"\\]|\\.)*")|([-+]?\d+\.?\d*(?:[eE][+-]?\d+)?)|(\btrue\b|\bfalse\b|\bnull\b)|([\[\]{}:,])',
  );

  /// Builds flat [pw.TextSpan] children for JSON or JSON-like text.
  static List<pw.TextSpan> highlight(String text, pw.TextStyle baseStyle) {
    final spans = <pw.TextSpan>[];
    int lastEnd = 0;
    for (final match in _token.allMatches(text)) {
      if (match.start > lastEnd) {
        spans.add(
          pw.TextSpan(
            text: text.substring(lastEnd, match.start),
            style: baseStyle.copyWith(color: defaultColor),
          ),
        );
      }

      if (match.group(1) != null) {
        spans.add(
          pw.TextSpan(
            text: match.group(1),
            style: baseStyle.copyWith(
              color: keyColor,
              fontWeight: pw.FontWeight.bold,
            ),
          ),
        );
        spans.add(
          pw.TextSpan(
            text: match.group(2),
            style: baseStyle.copyWith(color: bracketColor),
          ),
        );
      } else if (match.group(3) != null) {
        spans.add(
          pw.TextSpan(
            text: match.group(3),
            style: baseStyle.copyWith(color: stringColor),
          ),
        );
      } else if (match.group(4) != null) {
        spans.add(
          pw.TextSpan(
            text: match.group(4),
            style: baseStyle.copyWith(
              color: numberColor,
              fontWeight: pw.FontWeight.bold,
            ),
          ),
        );
      } else if (match.group(5) != null) {
        spans.add(
          pw.TextSpan(
            text: match.group(5),
            style: baseStyle.copyWith(
              color: boolNullColor,
              fontWeight: pw.FontWeight.bold,
            ),
          ),
        );
      } else if (match.group(6) != null) {
        spans.add(
          pw.TextSpan(
            text: match.group(6),
            style: baseStyle.copyWith(color: bracketColor),
          ),
        );
      }

      lastEnd = match.end;
    }

    if (lastEnd < text.length) {
      spans.add(
        pw.TextSpan(
          text: text.substring(lastEnd),
          style: baseStyle.copyWith(color: defaultColor),
        ),
      );
    }

    return spans;
  }
}
