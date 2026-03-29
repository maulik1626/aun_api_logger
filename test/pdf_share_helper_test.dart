import 'dart:convert' show jsonEncode;
import 'dart:io';
import 'dart:typed_data';
import 'dart:ui' as ui;

import 'package:aun_api_logger/src/core/api_log_model.dart';
import 'package:aun_api_logger/src/ui/widgets/shared_log_capture_card.dart';
import 'package:aun_api_logger/src/utils/pdf_share_helper.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:path_provider_platform_interface/path_provider_platform_interface.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  late PathProviderPlatform savedPathProvider;

  setUpAll(() {
    savedPathProvider = PathProviderPlatform.instance;
  });

  tearDown(() {
    PathProviderPlatform.instance = savedPathProvider;
  });

  group('Screenshot-based PDF share', () {
    setUp(() {
      final dir = Directory.systemTemp.createTempSync('aun_pdf_test_');
      PathProviderPlatform.instance = _FakePathProvider(dir.path);
    });

    test('wraps a PNG screenshot into a single-page PDF', () async {
      final imageBytes = await _buildTestPngBytes();

      final file = await PdfShareHelper.generatePdfFromImageBytes(
        imageBytes: imageBytes,
        method: 'POST',
        displayEndpoint: '/v1/auth',
        requestTime: 1_711_200_000_000,
      );
      final bytes = await file.readAsBytes();
      expect(bytes.length, greaterThan(100));
      expect(String.fromCharCodes(bytes.take(5)), '%PDF-');
    });

    testWidgets('renders the widened share card for a small log', (
      WidgetTester tester,
    ) async {
      final log = ApiLogModel(
        method: 'POST',
        url: 'https://api.example.com/v1/auth',
        endpoint: '/v1/auth',
        statusCode: 200,
        requestHeaders: '{"Content-Type": "application/json"}',
        requestBody: '{"username": "test"}',
        responseHeaders: '{"Server": "nginx"}',
        responseBody: '{"token": "xyz"}',
        requestTime: 1_711_200_000_000,
        durationMs: 154,
      );

      await tester.pumpWidget(
        MaterialApp(
          home: Material(
            child: SingleChildScrollView(
              child: SizedBox(
                width: 860,
                child: SharedLogCaptureCard(
                  log: log,
                  displayEndpoint: '/v1/auth',
                ),
              ),
            ),
          ),
        ),
      );

      expect(find.text('Request Headers'), findsOneWidget);
      expect(find.text('Response Body'), findsOneWidget);
      expect(find.text('/v1/auth'), findsOneWidget);
      expect(tester.takeException(), isNull);
    });

    testWidgets('renders large response bodies in the share card', (
      WidgetTester tester,
    ) async {
      final big = jsonEncode({
        'items': List.generate(
          350,
          (i) => {
            'id': i,
            'doctor_name': 'Doctor $i',
            'slots': List.generate(
              8,
              (j) => {
                'start_time':
                    '2026-02-28T${(j + 8).toString().padLeft(2, '0')}:00:00.000Z',
                'end_time':
                    '2026-02-28T${(j + 9).toString().padLeft(2, '0')}:00:00.000Z',
                'is_available': j.isEven,
              },
            ),
          },
        ),
      });
      expect(big.length, greaterThan(100_000));

      final log = ApiLogModel(
        method: 'GET',
        url: 'https://example.com/api',
        endpoint: '/api',
        statusCode: 200,
        responseBody: big,
        requestTime: 1_711_200_000_000,
        durationMs: 42,
      );

      await tester.pumpWidget(
        MaterialApp(
          home: Material(
            child: SingleChildScrollView(
              child: SizedBox(
                width: 860,
                child: SharedLogCaptureCard(log: log, displayEndpoint: '/api'),
              ),
            ),
          ),
        ),
      );

      expect(find.text('Response Body'), findsOneWidget);
      expect(tester.takeException(), isNull);
    });
  });
}

Future<Uint8List> _buildTestPngBytes() async {
  final recorder = ui.PictureRecorder();
  final canvas = Canvas(recorder);
  const size = Size(120, 160);

  canvas.drawRect(
    Rect.fromLTWH(0, 0, size.width, size.height),
    Paint()..color = const Color(0xFFF5F7FB),
  );
  canvas.drawRect(
    Rect.fromLTWH(12, 12, 96, 136),
    Paint()..color = const Color(0xFF1E88E5),
  );

  final image = await recorder.endRecording().toImage(
    size.width.toInt(),
    size.height.toInt(),
  );
  try {
    final bytes = await image.toByteData(format: ui.ImageByteFormat.png);
    return bytes!.buffer.asUint8List();
  } finally {
    image.dispose();
  }
}

/// [path_provider] uses the platform channel; unit tests need a fake temp path.
final class _FakePathProvider extends PathProviderPlatform {
  _FakePathProvider(this._tempPath);

  final String _tempPath;

  @override
  Future<String?> getTemporaryPath() async => _tempPath;
}
