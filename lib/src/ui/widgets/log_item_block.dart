import 'dart:io';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:share_plus/share_plus.dart';
import '../../core/api_log_model.dart';
import '../../utils/color_helper.dart';
import '../../utils/log_helper.dart';
import '../../utils/pdf_share_helper.dart';
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
      end: const Offset(-0.15, 0),
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

  Future<void> _shareLog({bool withAuth = false}) async {
    try {
      // Create a copy of the log data
      ApiLogModel shareLog = ApiLogModel(
        id: widget.log.id,
        method: widget.log.method,
        url: widget.log.url,
        endpoint: widget.log.endpoint,
        statusCode: widget.log.statusCode,
        requestHeaders: widget.log.requestHeaders,
        requestBody: widget.log.requestBody,
        responseHeaders: widget.log.responseHeaders,
        responseBody: widget.log.responseBody,
        requestTime: widget.log.requestTime,
        durationMs: widget.log.durationMs,
      );

      // Strip auth if requested
      if (!withAuth && shareLog.requestHeaders != null) {
        try {
          final headers =
              jsonDecode(shareLog.requestHeaders!) as Map<String, dynamic>;
          final List<String> keysToRemove = [];
          headers.forEach((key, value) {
            final lower = key.toLowerCase();
            if (lower.contains('authorization') ||
                lower.contains('token') ||
                lower.contains('bearer')) {
              keysToRemove.add(key);
            }
          });
          for (var k in keysToRemove) {
            headers[k] = '[Filtered]';
          }
          shareLog.requestHeaders = jsonEncode(headers);
        } catch (_) {}
      }

      // Generate PDF
      final File pdfFile = await PdfShareHelper.generatePdf(
        shareLog,
        widget.displayEndpoint,
      );

      await SharePlus.instance.share(
        ShareParams(files: <XFile>[XFile(pdfFile.path)]),
      );

      Future.delayed(const Duration(seconds: 10), () {
        if (pdfFile.existsSync()) {
          try {
            pdfFile.deleteSync();
          } catch (_) {}
        }
      });
    } catch (_) {}

    if (_isSlid) {
      _toggleSlide();
    }
  }

  /// [CupertinoContextMenu] lays out preview + menu sheet in one viewport.
  /// The delegate subtracts the child's height from the viewport to size the
  /// menu sheet.  An expanded log card can be nearly full-screen, making that
  /// remainder negative.
  ///
  /// Fix: hard-cap the preview height so ≥120 px is always left for the sheet
  /// + safe-area, then scale the card down inside that cap.
  Widget _iosContextMenuPreview(BuildContext menuContext, Widget logCard) {
    final size = MediaQuery.sizeOf(menuContext);
    final padding = MediaQuery.paddingOf(menuContext);
    final availableHeight = size.height - padding.vertical;
    // Reserve space for the context-menu action sheet + breathing room.
    const reservedForSheet = 140.0;
    final maxPreviewHeight = (availableHeight - reservedForSheet).clamp(
      160.0,
      520.0,
    );
    final width = size.width - 40;

    return ConstrainedBox(
      constraints: BoxConstraints(maxWidth: width, maxHeight: maxPreviewHeight),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(12),
        child: SingleChildScrollView(
          physics: const NeverScrollableScrollPhysics(),
          child: SizedBox(width: width, child: logCard),
        ),
      ),
    );
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
          JsonCodeBlock(content: content, isIOS: widget.isIOS),
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

    final statusColor = LogColorHelper.getStatusColor(widget.log.statusCode);

    final card = Material(
      color: Colors.transparent,
      child: Container(
        width: MediaQuery.of(context).size.width - 32,
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
                    onTap: () => _shareLog(withAuth: false),
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
                        splashColor: Colors.transparent,
                        highlightColor: Colors.transparent,
                        hoverColor: Colors.transparent,
                        splashFactory: NoSplash.splashFactory,
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
                                  color: LogColorHelper.getMethodColor(
                                    widget.log.method,
                                  ),
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
                                            color:
                                                LogColorHelper.getMethodColor(
                                                  widget.log.method,
                                                ).withValues(alpha: 0.1),
                                            borderRadius: BorderRadius.circular(
                                              4,
                                            ),
                                          ),
                                          child: Text(
                                            widget.log.method,
                                            style: TextStyle(
                                              color:
                                                  LogColorHelper.getMethodColor(
                                                    widget.log.method,
                                                  ),
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
                              const Divider(
                                height: 1,
                                color: Color(0xFFEEEEEE),
                              ),
                              _buildSection('URL', widget.log.url),
                              _buildSection(
                                'Request Headers',
                                widget.log.requestHeaders,
                              ),
                              _buildSection(
                                'Request Body${LogHelper.getRequestBodyType(widget.log.requestHeaders)}',
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
      ),
    );

    if (widget.isIOS) {
      // Build a *collapsed* snapshot of the card for the context-menu preview
      // so it never exceeds the viewport height.
      final collapsedCard = Material(
        color: Colors.transparent,
        child: Container(
          width: MediaQuery.of(context).size.width - 32,
          margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
          clipBehavior: Clip.antiAlias,
          decoration: BoxDecoration(borderRadius: BorderRadius.circular(12)),
          child: Container(
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: CupertinoColors.systemGrey5),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.03),
                  blurRadius: 8,
                  offset: const Offset(0, 2),
                ),
              ],
            ),
            child: Padding(
              padding: const EdgeInsets.all(12.0),
              child: Row(
                children: [
                  Container(
                    width: 4,
                    height: 48,
                    decoration: BoxDecoration(
                      color: LogColorHelper.getMethodColor(widget.log.method),
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
                                color: LogColorHelper.getMethodColor(
                                  widget.log.method,
                                ).withValues(alpha: 0.1),
                                borderRadius: BorderRadius.circular(4),
                              ),
                              child: Text(
                                widget.log.method,
                                style: TextStyle(
                                  color: LogColorHelper.getMethodColor(
                                    widget.log.method,
                                  ),
                                  fontSize: 10,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ),
                            const SizedBox(width: 8),
                            Text(
                              widget.log.statusCode?.toString() ?? 'PENDING',
                              style: TextStyle(
                                color: LogColorHelper.getStatusColor(
                                  widget.log.statusCode,
                                ),
                                fontSize: 13,
                                fontWeight: FontWeight.bold,
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
                ],
              ),
            ),
          ),
        ),
      );

      return CupertinoContextMenu.builder(
        enableHapticFeedback: true,
        actions: <Widget>[
          CupertinoContextMenuAction(
            onPressed: () {
              Navigator.pop(context);
              _shareLog(withAuth: false);
            },
            trailingIcon: CupertinoIcons.share,
            child: const Text('Share (Without Auth)'),
          ),
          CupertinoContextMenuAction(
            onPressed: () {
              Navigator.pop(context);
              _shareLog(withAuth: true);
            },
            trailingIcon: CupertinoIcons.share_solid,
            child: const Text('Share (Full Data)'),
          ),
        ],
        builder: (BuildContext menuContext, Animation<double> animation) =>
            _iosContextMenuPreview(menuContext, collapsedCard),
      );
    } else {
      return GestureDetector(
        onLongPress: () {
          showModalBottomSheet(
            context: context,
            backgroundColor: Colors.white,
            shape: const RoundedRectangleBorder(
              borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
            ),
            builder: (BuildContext context) {
              return SafeArea(
                child: Padding(
                  padding: const EdgeInsets.symmetric(vertical: 8.0),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: <Widget>[
                      Container(
                        width: 40,
                        height: 4,
                        margin: const EdgeInsets.only(bottom: 16),
                        decoration: BoxDecoration(
                          color: Colors.grey.shade300,
                          borderRadius: BorderRadius.circular(2),
                        ),
                      ),
                      ListTile(
                        leading: Container(
                          padding: const EdgeInsets.all(8),
                          decoration: BoxDecoration(
                            color: Colors.blue.shade50,
                            shape: BoxShape.circle,
                          ),
                          child: Icon(
                            Icons.share_rounded,
                            color: Colors.blue.shade700,
                          ),
                        ),
                        title: const Text(
                          'Share (Without Auth)',
                          style: TextStyle(fontWeight: FontWeight.w600),
                        ),
                        subtitle: const Text(
                          'Removes authorization tokens',
                          style: TextStyle(fontSize: 12),
                        ),
                        onTap: () {
                          Navigator.pop(context);
                          _shareLog(withAuth: false);
                        },
                      ),
                      ListTile(
                        leading: Container(
                          padding: const EdgeInsets.all(8),
                          decoration: BoxDecoration(
                            color: Colors.red.shade50,
                            shape: BoxShape.circle,
                          ),
                          child: Icon(
                            Icons.share_rounded,
                            color: Colors.red.shade700,
                          ),
                        ),
                        title: const Text(
                          'Share (Full Data)',
                          style: TextStyle(fontWeight: FontWeight.w600),
                        ),
                        subtitle: const Text(
                          'Includes all sensitive headers',
                          style: TextStyle(fontSize: 12),
                        ),
                        onTap: () {
                          Navigator.pop(context);
                          _shareLog(withAuth: true);
                        },
                      ),
                    ],
                  ),
                ),
              );
            },
          );
        },
        child: card,
      );
    }
  }
}

class JsonCodeBlock extends StatefulWidget {
  final String content;
  final bool isIOS;

  const JsonCodeBlock({super.key, required this.content, required this.isIOS});

  @override
  State<JsonCodeBlock> createState() => _JsonCodeBlockState();
}

class _JsonCodeBlockState extends State<JsonCodeBlock> {
  bool _softWrap = false;

  // JSON syntax colors
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
    final highlighted = _highlightJson(widget.content);

    return Container(
      decoration: BoxDecoration(
        color: const Color(0xFFFAFAFA),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: Colors.grey.shade200),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Align(
            alignment: Alignment.topRight,
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                GestureDetector(
                  onTap: () {
                    HapticFeedback.lightImpact();
                    Clipboard.setData(ClipboardData(text: widget.content));
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                        content: Text('Copied to clipboard'),
                        duration: Duration(seconds: 2),
                      ),
                    );
                  },
                  child: Padding(
                    padding: const EdgeInsets.all(8.0),
                    child: Icon(
                      widget.isIOS
                          ? CupertinoIcons.doc_on_doc
                          : Icons.copy_rounded,
                      size: 18,
                      color: Colors.grey.shade600,
                    ),
                  ),
                ),
                GestureDetector(
                  onTap: () {
                    HapticFeedback.selectionClick();
                    setState(() => _softWrap = !_softWrap);
                  },
                  child: Padding(
                    padding: const EdgeInsets.all(8.0),
                    child: Icon(
                      _softWrap
                          ? (widget.isIOS
                                ? CupertinoIcons.arrow_right_arrow_left
                                : Icons.wrap_text_rounded)
                          : (widget.isIOS
                                ? CupertinoIcons.text_alignleft
                                : Icons.short_text_rounded),
                      size: 18,
                      color: Colors.grey.shade600,
                    ),
                  ),
                ),
              ],
            ),
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(12, 0, 12, 12),
            child: _softWrap
                ? SelectableText.rich(
                    TextSpan(
                      children: highlighted,
                      style: const TextStyle(
                        fontFamily: 'monospace',
                        fontSize: 12,
                      ),
                    ),
                  )
                : SingleChildScrollView(
                    scrollDirection: Axis.horizontal,
                    child: SelectableText.rich(
                      TextSpan(
                        children: highlighted,
                        style: const TextStyle(
                          fontFamily: 'monospace',
                          fontSize: 12,
                        ),
                      ),
                    ),
                  ),
          ),
        ],
      ),
    );
  }
}
