import 'package:flutter/material.dart';
import '../../core/api_log_model.dart';
import '../../utils/log_helper.dart';
import 'log_item_block.dart'; // For JsonCodeBlock
import 'searchable_json_code_block.dart';

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

  Widget _buildResponseBodySection(String? content) {
    if (content == null || content.isEmpty) return const SizedBox.shrink();
    return Padding(
      padding: const EdgeInsets.only(top: 12.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          const Text(
            'Response Body',
            style: TextStyle(
              fontWeight: FontWeight.bold,
              fontSize: 14,
              color: Colors.black87,
            ),
          ),
          const SizedBox(height: 6),
          SearchableJsonCodeBlock(content: content, isIOS: isIOS),
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
        _buildResponseBodySection(log.responseBody),
      ],
    );
  }
}
