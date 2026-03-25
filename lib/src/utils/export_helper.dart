import 'dart:convert';
import 'dart:io';
import 'package:path_provider/path_provider.dart';
import 'package:share_plus/share_plus.dart';
import '../core/api_log_model.dart';
import '../storage/local_storage_service.dart';

class ExportHelper {
  /// Exports all logs of a day to a JSON file and opens the share dialog.
  static Future<void> exportAndShareLogs(
    List<ApiLogModel> logs,
    String dateStr,
  ) async {
    if (logs.isEmpty) return;

    final List<Map<String, dynamic>> jsonList = logs
        .map((l) => l.toMap())
        .toList();
    final String jsonString = const JsonEncoder.withIndent(
      '  ',
    ).convert(jsonList);

    final directory = await getTemporaryDirectory();
    final File file = File('${directory.path}/api_logs_$dateStr.json');
    await file.writeAsString(jsonString);

    // In mobile, sharing a file allows the user to 'Save to Files' or send it
    await Share.shareXFiles([XFile(file.path)], text: 'API Logs for $dateStr');
  }

  /// Exports the entire database
  static Future<void> exportAllLogs() async {
    final logs = await LocalStorageService.instance.getAllLogs();
    await exportAndShareLogs(logs, 'all_history');
  }
}
