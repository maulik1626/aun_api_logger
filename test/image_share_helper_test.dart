import 'dart:io';
import 'dart:typed_data';
import 'dart:ui' as ui;

import 'package:aun_api_logger/src/utils/image_share_helper.dart';
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

  group('Image share', () {
    setUp(() {
      final dir = Directory.systemTemp.createTempSync('aun_img_test_');
      PathProviderPlatform.instance = _FakePathProvider(dir.path);
    });

    test('writes PNG bytes to a temp file with a descriptive name', () async {
      final imageBytes = await _buildTestPngBytes();

      final file = await ImageShareHelper.writeSharePngFile(
        pngBytes: imageBytes,
        method: 'POST',
        displayEndpoint: '/v1/auth',
        requestTime: 1_711_200_000_000,
      );
      final bytes = await file.readAsBytes();
      expect(bytes.length, greaterThan(100));
      expect(bytes, imageBytes);
      expect(file.path.endsWith('.png'), isTrue);
      expect(file.path.contains('POST'), isTrue);
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
