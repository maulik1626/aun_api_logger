import 'package:flutter/material.dart';
import '../../core/api_log_model.dart';
import '../../utils/log_helper.dart';
import 'log_item_block.dart'; // For JsonCodeBlock

class LogDetailsPanel extends StatelessWidget {
  final ApiLogModel log;
  final bool isIOS;

  const LogDetailsPanel({super.key, required this.log, required this.isIOS});

  Widget _buildSection(String title, String? content) {
    if (content == null || content.isEmpty) return const SizedBox.shrink();
    return Padding(
      padding: const EdgeInsets.only(top: 12.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(
            title,
            style: const TextStyle(
              fontWeight: FontWeight.bold,
              fontSize: 14,
              color: Colors.black87,
            ),
          ),
          const SizedBox(height: 6),
          JsonCodeBlock(content: content, isIOS: isIOS),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        _buildSection('URL', log.url),
        _buildSection('Request Headers', log.requestHeaders),
        _buildSection(
          'Request Body${LogHelper.getRequestBodyType(log.requestHeaders)}',
          log.requestBody,
        ),
        _buildSection('Response Headers', log.responseHeaders),
        _buildSection('Response Body', log.responseBody),
      ],
    );
  }
}
