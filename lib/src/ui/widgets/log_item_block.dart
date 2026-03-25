import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:share_plus/share_plus.dart';
import '../../core/api_log_model.dart';
import 'package:intl/intl.dart';
import 'dart:convert';

class LogItemBlock extends StatefulWidget {
  final ApiLogModel log;
  final bool isIOS;
  final String displayEndpoint;

  const LogItemBlock({
    super.key,
    required this.log,
    required this.isIOS,
    required this.displayEndpoint,
  });

  @override
  State<LogItemBlock> createState() => _LogItemBlockState();
}

class _LogItemBlockState extends State<LogItemBlock>
    with SingleTickerProviderStateMixin {
  bool _isExpanded = false;
  late AnimationController _slideController;
  late Animation<Offset> _slideAnimation;
  bool _isSlid = false;

  @override
  void initState() {
    super.initState();
    _slideController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 250),
    );
    _slideAnimation = Tween<Offset>(
      begin: Offset.zero,
      end: const Offset(-0.3, 0),
    ).animate(CurvedAnimation(parent: _slideController, curve: Curves.easeOut));
  }

  @override
  void dispose() {
    _slideController.dispose();
    super.dispose();
  }

  void _toggleSlide() {
    if (_isSlid) {
      _slideController.reverse();
    } else {
      _slideController.forward();
    }
    _isSlid = !_isSlid;
  }

  void _copyToClipboard(BuildContext context) {
    final content = const JsonEncoder.withIndent(
      '  ',
    ).convert(widget.log.toMap());
    Clipboard.setData(ClipboardData(text: content));
    _slideController.reverse();
    _isSlid = false;
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Copied to clipboard'),
        duration: Duration(seconds: 2),
      ),
    );
  }

  void _shareLog() {
    final content = const JsonEncoder.withIndent(
      '  ',
    ).convert(widget.log.toMap());
    // ignore: deprecated_member_use
    Share.share(content);
    _slideController.reverse();
    _isSlid = false;
  }

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
          Text(
            title,
            style: const TextStyle(
              fontWeight: FontWeight.bold,
              fontSize: 14,
              color: Colors.black87,
            ),
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
      clipBehavior: Clip.antiAlias,
      decoration: BoxDecoration(borderRadius: BorderRadius.circular(12)),
      child: Stack(
        children: [
          // Background action buttons revealed on swipe
          Positioned.fill(
            child: Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                GestureDetector(
                  onTap: () => _copyToClipboard(context),
                  child: Container(
                    width: 60,
                    color: widget.isIOS
                        ? CupertinoColors.activeBlue
                        : Colors.blue,
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          widget.isIOS
                              ? CupertinoIcons.doc_on_doc
                              : Icons.copy_rounded,
                          color: Colors.white,
                          size: 22,
                        ),
                        const SizedBox(height: 4),
                        const Text(
                          'Copy',
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 11,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                GestureDetector(
                  onTap: _shareLog,
                  child: Container(
                    width: 60,
                    color: widget.isIOS
                        ? CupertinoColors.activeGreen
                        : Colors.green,
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          widget.isIOS
                              ? CupertinoIcons.share
                              : Icons.share_rounded,
                          color: Colors.white,
                          size: 22,
                        ),
                        const SizedBox(height: 4),
                        const Text(
                          'Share',
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 11,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
          // Foreground card that slides
          SlideTransition(
            position: _slideAnimation,
            child: GestureDetector(
              onHorizontalDragEnd: (details) {
                if (details.primaryVelocity != null &&
                    details.primaryVelocity! < -200) {
                  if (!_isSlid) {
                    _toggleSlide();
                  }
                } else if (details.primaryVelocity != null &&
                    details.primaryVelocity! > 200) {
                  if (_isSlid) {
                    _toggleSlide();
                  }
                }
              },
              child: Container(
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
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    InkWell(
                      onTap: () {
                        if (_isSlid) {
                          _toggleSlide();
                          return;
                        }
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
                                          color: statusColor.withValues(
                                            alpha: 0.1,
                                          ),
                                          borderRadius: BorderRadius.circular(
                                            4,
                                          ),
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
                                        widget.log.statusCode?.toString() ??
                                            'PENDING',
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
                                    widget.displayEndpoint,
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
                            _buildSection(
                              'Request Headers',
                              widget.log.requestHeaders,
                            ),
                            _buildSection(
                              'Request Body',
                              widget.log.requestBody,
                            ),
                            _buildSection(
                              'Response Headers',
                              widget.log.responseHeaders,
                            ),
                            _buildSection(
                              'Response Body',
                              widget.log.responseBody,
                            ),
                          ],
                        ),
                      ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
