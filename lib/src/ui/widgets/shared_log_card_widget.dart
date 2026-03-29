import 'dart:convert';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../../core/api_log_model.dart';
import '../../utils/color_helper.dart';

import '../../utils/log_helper.dart';

class StaticJsonCodeBlock extends StatelessWidget {
  final String content;

  const StaticJsonCodeBlock({super.key, required this.content});

  static const _keyColor = Color(0xFF00897B); // teal
  static const _stringColor = Color(0xFFF57F17); // amber
  static const _numberColor = Color(0xFF7B1FA2); // purple
  static const _boolNullColor = Color(0xFFD32F2F); // red
  static const _bracketColor = Color(0xFF757575); // grey
  static const _defaultColor = Color(0xFF424242);

  List<TextSpan> _highlightJson(String text) {
    final spans = <TextSpan>[];
    final regex = RegExp(
      r'("(?:[^"\\]|\\.)*")\s*(:)|("(?:[^"\\]|\\.)*")|([-+]?\d+\.?\d*(?:[eE][+-]?\d+)?)|(\btrue\b|\bfalse\b|\bnull\b)|([\[\]{}:,])',
    );

    int lastEnd = 0;
    for (final match in regex.allMatches(text)) {
      if (match.start > lastEnd) {
        spans.add(
          TextSpan(
            text: text.substring(lastEnd, match.start),
            style: const TextStyle(color: _defaultColor),
          ),
        );
      }

      if (match.group(1) != null) {
        // Key
        spans.add(
          TextSpan(
            text: match.group(1),
            style: const TextStyle(
              color: _keyColor,
              fontWeight: FontWeight.w600,
            ),
          ),
        );
        spans.add(
          TextSpan(
            text: match.group(2),
            style: const TextStyle(color: _bracketColor),
          ),
        );
      } else if (match.group(3) != null) {
        // String value
        spans.add(
          TextSpan(
            text: match.group(3),
            style: const TextStyle(color: _stringColor),
          ),
        );
      } else if (match.group(4) != null) {
        // Number
        spans.add(
          TextSpan(
            text: match.group(4),
            style: const TextStyle(
              color: _numberColor,
              fontWeight: FontWeight.w600,
            ),
          ),
        );
      } else if (match.group(5) != null) {
        // Boolean / null
        spans.add(
          TextSpan(
            text: match.group(5),
            style: const TextStyle(
              color: _boolNullColor,
              fontWeight: FontWeight.bold,
            ),
          ),
        );
      } else if (match.group(6) != null) {
        // Brackets, commas, colons
        spans.add(
          TextSpan(
            text: match.group(6),
            style: const TextStyle(color: _bracketColor),
          ),
        );
      }

      lastEnd = match.end;
    }

    if (lastEnd < text.length) {
      spans.add(
        TextSpan(
          text: text.substring(lastEnd),
          style: const TextStyle(color: _defaultColor),
        ),
      );
    }

    return spans;
  }

  @override
  Widget build(BuildContext context) {
    final highlighted = _highlightJson(content);
    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        color: const Color(0xFFFAFAFA),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: Colors.grey.shade200),
      ),
      padding: const EdgeInsets.all(12),
      child: SelectableText.rich(
        TextSpan(
          children: highlighted,
          style: const TextStyle(
            fontFamily: 'monospace',
            fontSize: 12,
            height: 1.3,
          ),
        ),
      ),
    );
  }
}

class SharedLogCardWidget extends StatelessWidget {
  final ApiLogModel log;
  final String displayEndpoint;

  const SharedLogCardWidget({
    super.key,
    required this.log,
    required this.displayEndpoint,
  });

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
          StaticJsonCodeBlock(content: content),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    // Standard Material wrapper to construct theme correctly for Screenshot
    return Material(
      color: Colors.transparent,
      child: Container(
        margin: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: Colors.grey.shade300, width: 2),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min, // Wrap content safely
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Padding(
              padding: const EdgeInsets.all(16.0),
              child: Row(
                children: [
                  Container(
                    width: 4,
                    height: 48,
                    decoration: BoxDecoration(
                      color: LogColorHelper.getStatusColor(log.statusCode),
                      borderRadius: BorderRadius.circular(2),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 6,
                                vertical: 2,
                              ),
                              decoration: BoxDecoration(
                                color: LogColorHelper.getMethodColor(log.method)
                                    .withValues(alpha: 0.1),
                                borderRadius: BorderRadius.circular(4),
                              ),
                              child: Text(
                                log.method,
                                style: TextStyle(
                                  color: LogColorHelper.getMethodColor(
                                      log.method),
                                  fontSize: 10,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ),
                            const SizedBox(width: 8),
                            Text(
                              log.statusCode?.toString() ?? 'PENDING',
                              style: TextStyle(
                                color: LogColorHelper.getStatusColor(
                                    log.statusCode),
                                fontSize: 13,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            const Spacer(),
                            Text(
                              DateFormat('hh:mm:ss a').format(
                                DateTime.fromMillisecondsSinceEpoch(
                                  log.requestTime,
                                ),
                              ),
                              style: TextStyle(
                                fontSize: 11,
                                color: Colors.grey.shade600,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 6),
                        Text(
                          displayEndpoint,
                          style: const TextStyle(
                            fontWeight: FontWeight.w600,
                            fontSize: 13,
                            color: Colors.black,
                          ),
                          maxLines: 4,
                        ),
                        const SizedBox(height: 4),
                        Text(
                          '${log.durationMs}ms',
                          style: TextStyle(
                            fontSize: 12,
                            color: Colors.grey.shade600,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            Container(
              color: Colors.white,
              padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  const Divider(height: 1, color: Color(0xFFEEEEEE)),
                  _buildSection('URL', log.url),
                  _buildSection('Request Headers', log.requestHeaders),
                  _buildSection(
                    'Request Body${LogHelper.getRequestBodyType(log.requestHeaders)}',
                    log.requestBody,
                  ),
                  _buildSection('Response Headers', log.responseHeaders),
                  _buildSection('Response Body', log.responseBody),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
