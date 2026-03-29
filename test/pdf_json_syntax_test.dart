import 'package:aun_api_logger/src/utils/pdf_json_syntax.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:pdf/widgets.dart' as pw;

void main() {
  test('highlight emits spans for simple JSON', () {
    const json = '{"a":1,"b":"x"}';
    final base = pw.TextStyle(fontSize: 9);
    final spans = PdfJsonSyntax.highlight(json, base);
    expect(spans, isNotEmpty);
    final joined = spans.map((s) => s.text ?? '').join();
    expect(joined, json);
  });

  test('highlight handles empty object', () {
    const json = '{}';
    final base = pw.TextStyle(fontSize: 9);
    final spans = PdfJsonSyntax.highlight(json, base);
    expect(spans, isNotEmpty);
  });
}
