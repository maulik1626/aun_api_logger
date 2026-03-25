import 'package:flutter/material.dart';
import '../../core/api_log_model.dart';
import 'copy_share_buttons.dart';
import 'package:intl/intl.dart';

class LogItemBlock extends StatelessWidget {
  final ApiLogModel log;

  const LogItemBlock({Key? key, required this.log}) : super(key: key);

  Color _getStatusColor(int? statusCode) {
    if (statusCode == null) return Colors.grey;
    if (statusCode >= 200 && statusCode < 300) return Colors.green;
    if (statusCode >= 300 && statusCode < 400) return Colors.blue;
    if (statusCode >= 400 && statusCode < 500) return Colors.orange;
    return Colors.red;
  }

  @override
  Widget build(BuildContext context) {
    final format = DateFormat('hh:mm:ss a');
    final timeStr = format.format(
      DateTime.fromMillisecondsSinceEpoch(log.requestTime),
    );

    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      elevation: 2,
      child: ExpansionTile(
        title: Text(
          '[${log.method}] ${log.endpoint}',
          style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13),
          maxLines: 2,
          overflow: TextOverflow.ellipsis,
        ),
        subtitle: Padding(
          padding: const EdgeInsets.only(top: 4.0),
          child: Row(
            children: [
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                decoration: BoxDecoration(
                  color: _getStatusColor(log.statusCode),
                  borderRadius: BorderRadius.circular(4),
                ),
                child: Text(
                  log.statusCode?.toString() ?? 'PENDING',
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 12,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
              const SizedBox(width: 8),
              Text(
                '$timeStr • ${log.durationMs}ms',
                style: const TextStyle(fontSize: 12),
              ),
            ],
          ),
        ),
        children: [
          _buildSection('URL', log.url),
          _buildSection('Request Headers', log.requestHeaders),
          _buildSection('Request Body', log.requestBody),
          _buildSection('Response Headers', log.responseHeaders),
          _buildSection('Response Body', log.responseBody),
        ],
      ),
    );
  }

  Widget _buildSection(String title, String? content) {
    if (content == null || content.isEmpty) return const SizedBox.shrink();
    return Padding(
      padding: const EdgeInsets.all(8.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(title, style: const TextStyle(fontWeight: FontWeight.bold)),
              CopyShareButtons(contentToCopy: content, shareText: content),
            ],
          ),
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: Colors.grey.withOpacity(0.1),
              borderRadius: BorderRadius.circular(4),
            ),
            child: SelectableText(
              content,
              style: const TextStyle(fontFamily: 'monospace', fontSize: 12),
            ),
          ),
        ],
      ),
    );
  }
}
