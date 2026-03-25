import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import '../../core/api_log_model.dart';
import 'package:intl/intl.dart';
import 'dart:convert';
import 'copy_share_buttons.dart';

class LogItemBlock extends StatefulWidget {
  final ApiLogModel log;
  final bool isIOS;

  const LogItemBlock({super.key, required this.log, required this.isIOS});

  @override
  State<LogItemBlock> createState() => _LogItemBlockState();
}

class _LogItemBlockState extends State<LogItemBlock> {
  bool _isExpanded = false;

  Color _getStatusColor(int? statusCode) {
    if (statusCode == null) {
      return CupertinoColors.systemGrey;
    }
    if (statusCode >= 200 && statusCode < 300) {
      return CupertinoColors.activeGreen;
    }
    if (statusCode >= 300 && statusCode < 400) {
      return CupertinoColors.systemBlue;
    }
    if (statusCode >= 400 && statusCode < 500) {
      return CupertinoColors.systemOrange;
    }
    return CupertinoColors.systemRed;
  }

  Widget _buildSection(String title, String? content) {
    if (content == null || content.isEmpty) return const SizedBox.shrink();
    return Padding(
      padding: const EdgeInsets.only(top: 12.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                title,
                style: const TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 14,
                  color: Colors.black87,
                ),
              ),
              CopyShareButtons(
                contentToCopy: content,
                shareText: content,
                isIOS: widget.isIOS,
              ),
            ],
          ),
          const SizedBox(height: 6),
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: Colors.grey.shade50,
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: Colors.grey.shade200),
            ),
            child: SelectableText(
              content,
              style: TextStyle(
                fontFamily: 'monospace',
                fontSize: 12,
                color: Colors.grey.shade800,
              ),
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final format = DateFormat('hh:mm:ss a');
    final timeStr = format.format(
      DateTime.fromMillisecondsSinceEpoch(widget.log.requestTime),
    );

    final statusColor = _getStatusColor(widget.log.statusCode);

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: widget.isIOS
              ? CupertinoColors.systemGrey5
              : Colors.grey.shade200,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.03),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      clipBehavior: Clip.antiAlias,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          InkWell(
            onTap: () {
              setState(() {
                _isExpanded = !_isExpanded;
              });
            },
            child: Padding(
              padding: const EdgeInsets.all(12.0),
              child: Row(
                children: [
                  Container(
                    width: 4,
                    height: 48,
                    decoration: BoxDecoration(
                      color: statusColor,
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
                                color: statusColor.withValues(alpha: 0.1),
                                borderRadius: BorderRadius.circular(4),
                              ),
                              child: Text(
                                widget.log.method,
                                style: TextStyle(
                                  color: statusColor,
                                  fontSize: 10,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ),
                            const SizedBox(width: 8),
                            Text(
                              widget.log.statusCode?.toString() ?? 'PENDING',
                              style: TextStyle(
                                color: statusColor,
                                fontSize: 13,
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
                        const SizedBox(height: 6),
                        Text(
                          widget.log.endpoint.isNotEmpty
                              ? widget.log.endpoint
                              : widget.log.url,
                          style: const TextStyle(
                            fontWeight: FontWeight.w600,
                            fontSize: 13,
                            color: Colors.black,
                          ),
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                        ),
                        const SizedBox(height: 4),
                        Text(
                          '${widget.log.durationMs}ms',
                          style: TextStyle(
                            fontSize: 12,
                            color: Colors.grey.shade500,
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 8),
                  CopyShareButtons(
                    contentToCopy: const JsonEncoder.withIndent(
                      '  ',
                    ).convert(widget.log.toMap()),
                    shareText: const JsonEncoder.withIndent(
                      '  ',
                    ).convert(widget.log.toMap()),
                    isIOS: widget.isIOS,
                  ),
                  const SizedBox(width: 8),
                  Icon(
                    _isExpanded
                        ? (widget.isIOS
                              ? CupertinoIcons.chevron_up
                              : Icons.expand_less_rounded)
                        : (widget.isIOS
                              ? CupertinoIcons.chevron_down
                              : Icons.expand_more_rounded),
                    color: Colors.grey.shade400,
                    size: 20,
                  ),
                ],
              ),
            ),
          ),
          if (_isExpanded)
            Container(
              color: Colors.white,
              padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  const Divider(height: 1, color: Color(0xFFEEEEEE)),
                  _buildSection('URL', widget.log.url),
                  _buildSection('Request Headers', widget.log.requestHeaders),
                  _buildSection('Request Body', widget.log.requestBody),
                  _buildSection('Response Headers', widget.log.responseHeaders),
                  _buildSection('Response Body', widget.log.responseBody),
                ],
              ),
            ),
        ],
      ),
    );
  }
}
