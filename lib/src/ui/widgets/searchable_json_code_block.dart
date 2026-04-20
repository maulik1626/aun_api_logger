import 'dart:async';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

// ─────────────────────────────────────────────────────────────────────────────
// Data model
// ─────────────────────────────────────────────────────────────────────────────

class _SearchMatch {
  final int lineIndex;
  final int start;
  final int end;

  const _SearchMatch({
    required this.lineIndex,
    required this.start,
    required this.end,
  });
}

// ─────────────────────────────────────────────────────────────────────────────
// Widget
// ─────────────────────────────────────────────────────────────────────────────

class SearchableJsonCodeBlock extends StatefulWidget {
  final String content;
  final bool isIOS;

  const SearchableJsonCodeBlock({
    super.key,
    required this.content,
    required this.isIOS,
  });

  @override
  State<SearchableJsonCodeBlock> createState() =>
      _SearchableJsonCodeBlockState();
}

class _SearchableJsonCodeBlockState extends State<SearchableJsonCodeBlock> {
  // ── JSON syntax colours ───────────────────────────────────────────────────
  static const _keyColor = Color(0xFF00897B);
  static const _stringColor = Color(0xFFF57F17);
  static const _numberColor = Color(0xFF7B1FA2);
  static const _boolNullColor = Color(0xFFD32F2F);
  static const _bracketColor = Color(0xFF757575);
  static const _defaultColor = Color(0xFF424242);

  // ── Search highlight colours ──────────────────────────────────────────────
  static const _inactiveHighlight = Color(0xFFFFEE58); // yellow
  static const _activeHighlight = Color(0xFFFF9800); // orange

  // ── Fixed line height for O(1) scroll-to-match ────────────────────────────
  static const double _lineHeight = 20.0;
  // ── Number of lines to show before enabling virtualisation ────────────────
  static const int _virtualisationThreshold = 100;

  late List<String> _lines;
  late ScrollController _scrollController;

  // ── Search state ──────────────────────────────────────────────────────────
  bool _searchVisible = false;
  String _query = '';
  List<_SearchMatch> _matches = [];
  int _activeIndex = -1;
  final TextEditingController _searchController = TextEditingController();
  Timer? _debounce;

  // ── Display state ─────────────────────────────────────────────────────────
  bool _softWrap = false;

  @override
  void initState() {
    super.initState();
    _lines = widget.content.split('\n');
    _scrollController = ScrollController();
  }

  @override
  void didUpdateWidget(SearchableJsonCodeBlock old) {
    super.didUpdateWidget(old);
    if (old.content != widget.content) {
      _lines = widget.content.split('\n');
      _clearSearch();
    }
  }

  @override
  void dispose() {
    _scrollController.dispose();
    _searchController.dispose();
    _debounce?.cancel();
    super.dispose();
  }

  // ── Search logic ──────────────────────────────────────────────────────────

  void _onSearchChanged(String value) {
    _debounce?.cancel();
    _debounce = Timer(const Duration(milliseconds: 200), () {
      _computeMatches(value);
    });
  }

  void _computeMatches(String query) {
    if (query.isEmpty) {
      setState(() {
        _query = '';
        _matches = [];
        _activeIndex = -1;
      });
      return;
    }

    final lower = query.toLowerCase();
    final newMatches = <_SearchMatch>[];

    for (int i = 0; i < _lines.length; i++) {
      final lineLower = _lines[i].toLowerCase();
      int start = 0;
      while (true) {
        final idx = lineLower.indexOf(lower, start);
        if (idx == -1) break;
        newMatches.add(_SearchMatch(lineIndex: i, start: idx, end: idx + query.length));
        start = idx + query.length;
      }
    }

    setState(() {
      _query = query;
      _matches = newMatches;
      _activeIndex = newMatches.isEmpty ? -1 : 0;
    });

    if (newMatches.isNotEmpty) {
      _scrollToActive();
    }
  }

  void _navigatePrev() {
    if (_matches.isEmpty) return;
    HapticFeedback.selectionClick();
    setState(() {
      _activeIndex = (_activeIndex - 1 + _matches.length) % _matches.length;
    });
    _scrollToActive();
  }

  void _navigateNext() {
    if (_matches.isEmpty) return;
    HapticFeedback.selectionClick();
    setState(() {
      _activeIndex = (_activeIndex + 1) % _matches.length;
    });
    _scrollToActive();
  }

  void _scrollToActive() {
    if (_activeIndex < 0 || _activeIndex >= _matches.length) return;
    if (!_scrollController.hasClients) return;

    // Only apply fixed-height jump when not in wrap mode (wrap mode has variable heights)
    if (!_softWrap && _lines.length >= _virtualisationThreshold) {
      final targetLine = _matches[_activeIndex].lineIndex;
      final targetOffset = (targetLine * _lineHeight).clamp(
        0.0,
        _scrollController.position.maxScrollExtent,
      );
      _scrollController.animateTo(
        targetOffset,
        duration: const Duration(milliseconds: 280),
        curve: Curves.easeInOut,
      );
    }
    // For short content / wrap mode, rely on the same offset estimation:
    else {
      final targetLine = _matches[_activeIndex].lineIndex;
      final estimatedOffset = (targetLine * _lineHeight).clamp(
        0.0,
        _scrollController.position.maxScrollExtent,
      );
      _scrollController.animateTo(
        estimatedOffset,
        duration: const Duration(milliseconds: 280),
        curve: Curves.easeInOut,
      );
    }
  }

  void _clearSearch() {
    _searchController.clear();
    setState(() {
      _query = '';
      _matches = [];
      _activeIndex = -1;
      _searchVisible = false;
    });
  }

  // ── Syntax highlighting ───────────────────────────────────────────────────

  static final _jsonRegex = RegExp(
    r'("(?:[^"\\]|\\.)*")\s*(:)|("(?:[^"\\]|\\.)*")|([-+]?\d+\.?\d*(?:[eE][+-]?\d+)?)|(\btrue\b|\bfalse\b|\bnull\b)|([\[\]{}:,])',
  );

  List<TextSpan> _syntaxHighlight(String line) {
    final spans = <TextSpan>[];
    int lastEnd = 0;

    for (final m in _jsonRegex.allMatches(line)) {
      if (m.start > lastEnd) {
        spans.add(TextSpan(
          text: line.substring(lastEnd, m.start),
          style: const TextStyle(color: _defaultColor),
        ));
      }

      if (m.group(1) != null) {
        spans.add(TextSpan(
          text: m.group(1),
          style: const TextStyle(color: _keyColor, fontWeight: FontWeight.w600),
        ));
        spans.add(TextSpan(
          text: m.group(2),
          style: const TextStyle(color: _bracketColor),
        ));
      } else if (m.group(3) != null) {
        spans.add(TextSpan(
          text: m.group(3),
          style: const TextStyle(color: _stringColor),
        ));
      } else if (m.group(4) != null) {
        spans.add(TextSpan(
          text: m.group(4),
          style: const TextStyle(color: _numberColor, fontWeight: FontWeight.w600),
        ));
      } else if (m.group(5) != null) {
        spans.add(TextSpan(
          text: m.group(5),
          style: const TextStyle(color: _boolNullColor, fontWeight: FontWeight.bold),
        ));
      } else if (m.group(6) != null) {
        spans.add(TextSpan(
          text: m.group(6),
          style: const TextStyle(color: _bracketColor),
        ));
      }

      lastEnd = m.end;
    }

    if (lastEnd < line.length) {
      spans.add(TextSpan(
        text: line.substring(lastEnd),
        style: const TextStyle(color: _defaultColor),
      ));
    }

    return spans;
  }

  /// Builds a line's TextSpan list overlaid with search highlights.
  /// Strategy: flatten existing spans into char segments, then inject
  /// background colours for match ranges.
  List<InlineSpan> _buildHighlightedLine(int lineIndex) {
    final line = _lines[lineIndex];
    if (_query.isEmpty || line.isEmpty) {
      return _syntaxHighlight(line);
    }

    // Collect match ranges on this line + which are "active"
    final lineMatchRanges = <(int start, int end, bool active)>[];
    for (int mi = 0; mi < _matches.length; mi++) {
      final m = _matches[mi];
      if (m.lineIndex == lineIndex) {
        lineMatchRanges.add((m.start, m.end, mi == _activeIndex));
      }
    }

    if (lineMatchRanges.isEmpty) {
      return _syntaxHighlight(line);
    }

    // Build result by splitting the line at match boundaries
    final result = <InlineSpan>[];
    int cursor = 0;

    // Merge sort is unnecessary: matches on same line are already ordered
    for (final (start, end, isActive) in lineMatchRanges) {
      if (cursor < start) {
        result.addAll(_syntaxHighlight(line.substring(cursor, start)));
      }
      final matchText = line.substring(start, end);
      result.add(TextSpan(
        text: matchText,
        style: TextStyle(
          color: Colors.black,
          backgroundColor: isActive ? _activeHighlight : _inactiveHighlight,
          fontWeight: FontWeight.bold,
          fontFamily: 'monospace',
          fontSize: 12,
        ),
      ));
      cursor = end;
    }

    if (cursor < line.length) {
      result.addAll(_syntaxHighlight(line.substring(cursor)));
    }

    return result;
  }

  // ── Toolbar builder ───────────────────────────────────────────────────────

  Widget _buildToolbar() {
    final hasMatches = _matches.isNotEmpty;
    final matchLabel = _query.isEmpty
        ? ''
        : hasMatches
            ? '${_activeIndex + 1} of ${_matches.length}'
            : 'No results';
    final labelColor = hasMatches ? Colors.orange.shade700 : Colors.red.shade400;

    return Row(
      children: [
        // ── Search bar (animates in) ────────────────────────────────────────
        Expanded(
          child: AnimatedSwitcher(
            duration: const Duration(milliseconds: 220),
            child: _searchVisible
                ? _buildSearchBar(matchLabel, labelColor)
                : Row(
                    mainAxisAlignment: MainAxisAlignment.end,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      _toolbarIcon(
                        icon: widget.isIOS
                            ? CupertinoIcons.search
                            : Icons.search_rounded,
                        tooltip: 'Search response',
                        onTap: () {
                          HapticFeedback.lightImpact();
                          setState(() => _searchVisible = true);
                          // Autofocus handled below
                        },
                      ),
                      _toolbarIcon(
                        icon: widget.isIOS
                            ? CupertinoIcons.doc_on_doc
                            : Icons.copy_rounded,
                        tooltip: 'Copy',
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
                      ),
                      _toolbarIcon(
                        icon: _softWrap
                            ? (widget.isIOS
                                ? CupertinoIcons.arrow_right_arrow_left
                                : Icons.wrap_text_rounded)
                            : (widget.isIOS
                                ? CupertinoIcons.text_alignleft
                                : Icons.short_text_rounded),
                        tooltip: _softWrap ? 'Unwrap' : 'Wrap',
                        onTap: () {
                          HapticFeedback.selectionClick();
                          setState(() => _softWrap = !_softWrap);
                        },
                      ),
                    ],
                  ),
          ),
        ),
      ],
    );
  }

  Widget _buildSearchBar(String matchLabel, Color labelColor) {
    return Row(
      children: [
        // ── Text field ─────────────────────────────────────────────────────
        Expanded(
          child: Container(
            height: 34,
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(8),
              border: Border.all(
                color: _query.isNotEmpty && _matches.isEmpty
                    ? Colors.red.shade300
                    : Colors.grey.shade300,
              ),
            ),
            child: TextField(
              controller: _searchController,
              autofocus: true,
              onChanged: _onSearchChanged,
              style: const TextStyle(fontSize: 13),
              decoration: InputDecoration(
                hintText: 'Find in response…',
                hintStyle: TextStyle(fontSize: 12, color: Colors.grey.shade400),
                contentPadding: const EdgeInsets.symmetric(horizontal: 10, vertical: 0),
                isDense: true,
                border: InputBorder.none,
                prefixIconConstraints: const BoxConstraints(minWidth: 32, minHeight: 32),
                prefixIcon: Icon(
                  Icons.search_rounded,
                  size: 16,
                  color: Colors.grey.shade500,
                ),
              ),
            ),
          ),
        ),
        const SizedBox(width: 6),
        // ── Match counter ──────────────────────────────────────────────────
        if (_query.isNotEmpty)
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 3),
            decoration: BoxDecoration(
              color: _matches.isEmpty ? Colors.red.shade50 : Colors.orange.shade50,
              borderRadius: BorderRadius.circular(6),
              border: Border.all(
                color: _matches.isEmpty ? Colors.red.shade200 : Colors.orange.shade200,
              ),
            ),
            child: Text(
              matchLabel,
              style: TextStyle(
                fontSize: 11,
                fontWeight: FontWeight.w600,
                color: labelColor,
              ),
            ),
          ),
        const SizedBox(width: 4),
        // ── Up arrow ───────────────────────────────────────────────────────
        _navButton(
          icon: widget.isIOS ? CupertinoIcons.chevron_up : Icons.keyboard_arrow_up_rounded,
          onTap: _matches.isEmpty ? null : _navigatePrev,
        ),
        // ── Down arrow ─────────────────────────────────────────────────────
        _navButton(
          icon: widget.isIOS ? CupertinoIcons.chevron_down : Icons.keyboard_arrow_down_rounded,
          onTap: _matches.isEmpty ? null : _navigateNext,
        ),
        // ── Close ─────────────────────────────────────────────────────────
        _toolbarIcon(
          icon: widget.isIOS ? CupertinoIcons.xmark : Icons.close_rounded,
          tooltip: 'Close search',
          onTap: _clearSearch,
        ),
      ],
    );
  }

  Widget _toolbarIcon({
    required IconData icon,
    required VoidCallback onTap,
    String? tooltip,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Tooltip(
        message: tooltip ?? '',
        child: Padding(
          padding: const EdgeInsets.all(8.0),
          child: Icon(icon, size: 18, color: Colors.grey.shade600),
        ),
      ),
    );
  }

  Widget _navButton({required IconData icon, required VoidCallback? onTap}) {
    final enabled = onTap != null;
    return GestureDetector(
      onTap: onTap,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 2, vertical: 4),
        child: Container(
          width: 28,
          height: 28,
          decoration: BoxDecoration(
            color: enabled ? Colors.grey.shade100 : Colors.transparent,
            borderRadius: BorderRadius.circular(6),
          ),
          child: Icon(
            icon,
            size: 18,
            color: enabled ? Colors.grey.shade700 : Colors.grey.shade300,
          ),
        ),
      ),
    );
  }

  // ── Content builder ───────────────────────────────────────────────────────

  Widget _buildContent() {
    final isVirtualised = _lines.length >= _virtualisationThreshold;

    Widget listView;

    if (isVirtualised) {
      // Use fixed itemExtent for perfect O(1) scroll-to-index
      listView = ListView.builder(
        controller: _scrollController,
        itemCount: _lines.length,
        itemExtent: _softWrap ? null : _lineHeight,
        shrinkWrap: false,
        padding: const EdgeInsets.fromLTRB(12, 0, 12, 12),
        itemBuilder: (context, index) {
          return SelectionArea(
            child: RichText(
              softWrap: _softWrap,
              overflow: _softWrap ? TextOverflow.visible : TextOverflow.visible,
              text: TextSpan(
                children: _buildHighlightedLine(index),
                style: const TextStyle(
                  fontFamily: 'monospace',
                  fontSize: 12,
                  height: 1.6,
                ),
              ),
            ),
          );
        },
      );
    } else {
      // Short content: render as single scrollable SelectableText
      listView = SingleChildScrollView(
        controller: _scrollController,
        padding: const EdgeInsets.fromLTRB(12, 0, 12, 12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: List.generate(_lines.length, (index) {
            return RichText(
              softWrap: _softWrap,
              text: TextSpan(
                children: _buildHighlightedLine(index),
                style: const TextStyle(
                  fontFamily: 'monospace',
                  fontSize: 12,
                  height: 1.6,
                ),
              ),
            );
          }),
        ),
      );
    }

    if (_softWrap) {
      return SizedBox(
        height: isVirtualised ? 400 : null,
        child: listView,
      );
    }

    return SizedBox(
      height: isVirtualised ? 400 : (_lines.length * _lineHeight).clamp(60, 400),
      child: SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        child: SizedBox(
          // Give enough width to avoid wrapping
          width: 2000,
          child: listView,
        ),
      ),
    );
  }

  // ─────────────────────────────────────────────────────────────────────────
  // Build
  // ─────────────────────────────────────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: const Color(0xFFFAFAFA),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: Colors.grey.shade200),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // ── Toolbar ───────────────────────────────────────────────────────
          Padding(
            padding: const EdgeInsets.fromLTRB(8, 4, 4, 4),
            child: _buildToolbar(),
          ),
          // ── Search bar row (shown when active + wide layout) ──────────────
          // ── Content ───────────────────────────────────────────────────────
          _buildContent(),
        ],
      ),
    );
  }
}
