import 'dart:convert';
import 'dart:io';

import 'package:aun_api_logger/src/core/api_log_model.dart';
import 'package:aun_api_logger/src/utils/pdf_share_helper.dart';
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

  group('PdfShareHelper.generatePdf', () {
    setUp(() {
      final dir = Directory.systemTemp.createTempSync('aun_pdf_test_');
      PathProviderPlatform.instance = _FakePathProvider(dir.path);
    });
    test('produces valid PDF bytes for a small log', () async {
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

      final file = await PdfShareHelper.generatePdf(log, '/v1/auth');
      final bytes = await file.readAsBytes();
      expect(bytes.length, greaterThan(100));
      expect(String.fromCharCodes(bytes.take(5)), '%PDF-');
    });

    test('completes for a large JSON response without throwing', () async {
      final big = jsonEncode({
        'items': List.generate(2000, (i) => {'id': i, 'data': 'x' * 200}),
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

      final file = await PdfShareHelper.generatePdf(log, '/api');
      final bytes = await file.readAsBytes();
      expect(bytes.length, greaterThan(1000));
      expect(String.fromCharCodes(bytes.take(5)), '%PDF-');
    });

    test(
      'completes for long single-line non-JSON body (minified path)',
      () async {
        final longLine = 'x' * 120_000;
        final log = ApiLogModel(
          method: 'GET',
          url: 'https://example.com/api',
          endpoint: '/api',
          statusCode: 500,
          responseBody: longLine,
          requestTime: 1_711_200_000_000,
          durationMs: 3,
        );

        final file = await PdfShareHelper.generatePdf(log, '/api');
        final bytes = await file.readAsBytes();
        expect(bytes.length, greaterThan(500));
        expect(String.fromCharCodes(bytes.take(5)), '%PDF-');
      },
    );
  });
}

/// [path_provider] uses the platform channel; unit tests need a fake temp path.
final class _FakePathProvider extends PathProviderPlatform {
  _FakePathProvider(this._tempPath);

  final String _tempPath;

  @override
  Future<String?> getTemporaryPath() async => _tempPath;
}
