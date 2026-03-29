import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../../core/api_log_model.dart';
import '../../utils/color_helper.dart';
import '../../utils/log_helper.dart';

class SharedLogCaptureCard extends StatelessWidget {
  const SharedLogCaptureCard({
    super.key,
    required this.log,
    required this.displayEndpoint,
  });

  final ApiLogModel log;
  final String displayEndpoint;

  @override
  Widget build(BuildContext context) {
    final timeStr = DateFormat(
      'hh:mm:ss a',
    ).format(DateTime.fromMillisecondsSinceEpoch(log.requestTime));
    final statusColor = LogColorHelper.getStatusColor(log.statusCode);
    final methodColor = LogColorHelper.getMethodColor(log.method);

    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.grey.shade200),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        mainAxisSize: MainAxisSize.min,
        children: [
          Padding(
            padding: const EdgeInsets.all(16),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  width: 4,
                  height: 48,
                  decoration: BoxDecoration(
                    color: methodColor,
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
                              horizontal: 8,
                              vertical: 3,
                            ),
                            decoration: BoxDecoration(
                              color: methodColor.withValues(alpha: 0.1),
                              borderRadius: BorderRadius.circular(4),
                            ),
                            child: Text(
                              log.method,
                              style: TextStyle(
                                color: methodColor,
                                fontSize: 11,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                          const SizedBox(width: 10),
                          Text(
                            log.statusCode?.toString() ?? 'PENDING',
                            style: TextStyle(
                              color: statusColor,
                              fontSize: 14,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          const Spacer(),
                          Text(
                            timeStr,
                            style: TextStyle(
                              fontSize: 11,
                              color: Colors.grey.shade500,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 8),
                      Text(
                        displayEndpoint,
                        style: const TextStyle(
                          fontWeight: FontWeight.w600,
                          fontSize: 14,
                          color: Colors.black,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        '${log.durationMs}ms',
                        style: TextStyle(
                          fontSize: 12,
                          color: Colors.grey.shade500,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          const Divider(height: 1, color: Color(0xFFEEEEEE)),
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              mainAxisSize: MainAxisSize.min,
              children: [
                _ShareSection(title: 'URL', content: log.url, isJson: false),
                _ShareSection(
                  title: 'Request Headers',
                  content: log.requestHeaders,
                ),
                _ShareSection(
                  title:
                      'Request Body${LogHelper.getRequestBodyType(log.requestHeaders)}',
                  content: log.requestBody,
                ),
                _ShareSection(
                  title: 'Response Headers',
                  content: log.responseHeaders,
                ),
                _ShareSection(
                  title: 'Response Body',
                  content: log.responseBody,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _ShareSection extends StatelessWidget {
  const _ShareSection({
    required this.title,
    required this.content,
    this.isJson = true,
  });

  final String title;
  final String? content;
  final bool isJson;

  @override
  Widget build(BuildContext context) {
    if (content == null || content!.isEmpty) {
      return const SizedBox.shrink();
    }

    final formatted = isJson ? _prettyJson(content!) : content!;

    return Padding(
      padding: const EdgeInsets.only(top: 12),
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
          _ShareCodeBlock(content: formatted),
        ],
      ),
    );
  }

  static String _prettyJson(String raw) {
    try {
      final decoded = jsonDecode(raw);
      return const JsonEncoder.withIndent('  ').convert(decoded);
    } catch (_) {
      return raw;
    }
  }
}

class _ShareCodeBlock extends StatelessWidget {
  const _ShareCodeBlock({required this.content});

  final String content;

  static const _keyColor = Color(0xFF00897B);
  static const _stringColor = Color(0xFFF57F17);
  static const _numberColor = Color(0xFF7B1FA2);
  static const _boolNullColor = Color(0xFFD32F2F);
  static const _bracketColor = Color(0xFF757575);
  static const _defaultColor = Color(0xFF424242);

  List<TextSpan> _highlightJson(String text) {
    final spans = <TextSpan>[];
    final regex = RegExp(
      r'("(?:[^"\\]|\\.)*")\s*(:)|("(?:[^"\\]|\\.)*")|([-+]?\d+\.?\d*(?:[eE][+-]?\d+)?)|(\btrue\b|\bfalse\b|\bnull\b)|([\[\]{}:,])',
    );

    var lastEnd = 0;
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
        spans.add(
          TextSpan(
            text: match.group(3),
            style: const TextStyle(color: _stringColor),
          ),
        );
      } else if (match.group(4) != null) {
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
    return Container(
      decoration: BoxDecoration(
        color: const Color(0xFFFAFAFA),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: Colors.grey.shade200),
      ),
      padding: const EdgeInsets.all(12),
      child: RichText(
        text: TextSpan(
          children: _highlightJson(content),
          style: const TextStyle(
            fontFamily: 'monospace',
            fontSize: 12,
            height: 1.45,
          ),
        ),
        softWrap: true,
      ),
    );
  }
}
