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
  // ── Number of lines to enable virtualisation ─────────────────────────────
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
        newMatches.add(
          _SearchMatch(lineIndex: i, start: idx, end: idx + query.length),
        );
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

  void _clearSearch() {
    _searchController.clear();
    setState(() {
      _query = '';
      _matches = [];
      _activeIndex = -1;
      _searchVisible = false;
    });
  }

  void _onCopy() {
    HapticFeedback.lightImpact();
    Clipboard.setData(ClipboardData(text: widget.content));
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: const Text('Response body copied'),
        duration: const Duration(seconds: 2),
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
        margin: const EdgeInsets.fromLTRB(16, 0, 16, 16),
      ),
    );
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
          style: const TextStyle(
            color: _numberColor,
            fontWeight: FontWeight.w600,
          ),
        ));
      } else if (m.group(5) != null) {
        spans.add(TextSpan(
          text: m.group(5),
          style: const TextStyle(
            color: _boolNullColor,
            fontWeight: FontWeight.bold,
          ),
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

  List<InlineSpan> _buildHighlightedLine(int lineIndex) {
    final line = _lines[lineIndex];
    if (_query.isEmpty || line.isEmpty) {
      return _syntaxHighlight(line);
    }

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

    final result = <InlineSpan>[];
    int cursor = 0;

    for (final (start, end, isActive) in lineMatchRanges) {
      if (cursor < start) {
        result.addAll(_syntaxHighlight(line.substring(cursor, start)));
      }
      result.add(TextSpan(
        text: line.substring(start, end),
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

  // ── Toolbar ───────────────────────────────────────────────────────────────
  //
  // Layout (always):
  //   [ SEARCH AREA — Expanded ]  │  [ COPY ]  [ WRAP ]
  //
  // Search area states
  //   Collapsed → compact pill showing search icon + label
  //   Expanded  → text field + counter badge + ↑↓ nav + ✕

  Widget _buildToolbar() {
    return Row(
      children: [
        // ── Left: search area (takes all remaining space) ──────────────────
        Expanded(
          child: AnimatedSwitcher(
            duration: const Duration(milliseconds: 200),
            transitionBuilder: (child, animation) => FadeTransition(
              opacity: animation,
              child: child,
            ),
            child: _searchVisible
                ? _buildSearchExpandedRow()
                : _buildSearchCollapsedButton(),
          ),
        ),
        // ── Separator ─────────────────────────────────────────────────────
        _divider(),
        // ── Right: persistent copy + wrap ─────────────────────────────────
        _iconButton(
          icon: widget.isIOS
              ? CupertinoIcons.doc_on_doc
              : Icons.copy_rounded,
          tooltip: 'Copy to clipboard',
          onTap: _onCopy,
        ),
        _iconButton(
          icon: _softWrap
              ? (widget.isIOS
                  ? CupertinoIcons.arrow_right_arrow_left
                  : Icons.wrap_text_rounded)
              : (widget.isIOS
                  ? CupertinoIcons.text_alignleft
                  : Icons.short_text_rounded),
          tooltip: _softWrap ? 'Unwrap lines' : 'Wrap lines',
          active: _softWrap,
          onTap: () {
            HapticFeedback.selectionClick();
            setState(() => _softWrap = !_softWrap);
          },
        ),
      ],
    );
  }

  /// Collapsed: small rounded pill — "🔍 Search"
  Widget _buildSearchCollapsedButton() {
    return Align(
      key: const ValueKey('collapsed'),
      alignment: Alignment.centerLeft,
      child: GestureDetector(
        onTap: () {
          HapticFeedback.lightImpact();
          setState(() => _searchVisible = true);
        },
        child: Container(
          height: 28,
          padding: const EdgeInsets.symmetric(horizontal: 10),
          decoration: BoxDecoration(
            color: Colors.grey.shade100,
            borderRadius: BorderRadius.circular(20),
            border: Border.all(color: Colors.grey.shade200),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                widget.isIOS ? CupertinoIcons.search : Icons.search_rounded,
                size: 13,
                color: Colors.grey.shade500,
              ),
              const SizedBox(width: 5),
              Text(
                'Search',
                style: TextStyle(
                  fontSize: 12,
                  color: Colors.grey.shade500,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  /// Expanded: text field + counter + up/down + close
  Widget _buildSearchExpandedRow() {
    final hasQuery = _query.isNotEmpty;
    final hasMatches = _matches.isNotEmpty;

    return Row(
      key: const ValueKey('expanded'),
      children: [
        // ── Text field ─────────────────────────────────────────────────────
        Expanded(
          child: Container(
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(8),
              border: Border.all(
                color: hasQuery && !hasMatches
                    ? Colors.red.shade300
                    : Colors.blue.shade200,
                width: 1.2,
              ),
              boxShadow: [
                BoxShadow(
                  color: Colors.blue.shade50,
                  blurRadius: 4,
                  offset: const Offset(0, 1),
                ),
              ],
            ),
            child: TextField(
              controller: _searchController,
              autofocus: true,
              onChanged: _onSearchChanged,
              textAlignVertical: TextAlignVertical.center,
              style: const TextStyle(
                fontSize: 12,
                color: Color(0xFF212121),
              ),
              decoration: InputDecoration(
                hintText: 'Find in response…',
                hintStyle: TextStyle(
                  fontSize: 12,
                  color: Colors.grey.shade400,
                ),
                contentPadding: const EdgeInsets.symmetric(
                  horizontal: 8,
                  vertical: 7,
                ),
                isDense: true,
                border: InputBorder.none,
                prefixIconConstraints: const BoxConstraints(
                  minWidth: 28,
                  minHeight: 28,
                ),
                prefixIcon: Icon(
                  Icons.search_rounded,
                  size: 14,
                  color: Colors.blue.shade300,
                ),
              ),
            ),
          ),
        ),
        const SizedBox(width: 6),
        // ── Match counter badge ────────────────────────────────────────────
        if (hasQuery) _matchBadge(hasMatches),
        if (hasQuery) const SizedBox(width: 4),
        // ── Nav: prev ─────────────────────────────────────────────────────
        _navButton(
          icon: widget.isIOS
              ? CupertinoIcons.chevron_up
              : Icons.keyboard_arrow_up_rounded,
          enabled: hasMatches,
          onTap: _navigatePrev,
        ),
        // ── Nav: next ─────────────────────────────────────────────────────
        _navButton(
          icon: widget.isIOS
              ? CupertinoIcons.chevron_down
              : Icons.keyboard_arrow_down_rounded,
          enabled: hasMatches,
          onTap: _navigateNext,
        ),
        // ── Close ─────────────────────────────────────────────────────────
        _iconButton(
          icon: widget.isIOS ? CupertinoIcons.xmark : Icons.close_rounded,
          tooltip: 'Close search',
          onTap: _clearSearch,
        ),
      ],
    );
  }

  Widget _matchBadge(bool hasMatches) {
    final label = hasMatches
        ? '${_activeIndex + 1} / ${_matches.length}'
        : 'No results';
    return AnimatedContainer(
      duration: const Duration(milliseconds: 150),
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color: hasMatches
            ? const Color(0xFFFFF3E0)
            : const Color(0xFFFFEBEE),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: hasMatches
              ? const Color(0xFFFFCC80)
              : const Color(0xFFEF9A9A),
        ),
      ),
      child: Text(
        label,
        style: TextStyle(
          fontSize: 11,
          fontWeight: FontWeight.w700,
          color: hasMatches ? Colors.orange.shade800 : Colors.red.shade400,
          letterSpacing: 0.2,
        ),
      ),
    );
  }

  Widget _divider() {
    return Container(
      width: 1,
      height: 18,
      margin: const EdgeInsets.symmetric(horizontal: 6),
      color: Colors.grey.shade200,
    );
  }

  Widget _iconButton({
    required IconData icon,
    required VoidCallback onTap,
    String? tooltip,
    bool active = false,
  }) {
    return Tooltip(
      message: tooltip ?? '',
      waitDuration: const Duration(milliseconds: 500),
      child: GestureDetector(
        onTap: onTap,
        behavior: HitTestBehavior.opaque,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 6),
          child: Icon(
            icon,
            size: 17,
            color: active ? Colors.blue.shade600 : Colors.grey.shade500,
          ),
        ),
      ),
    );
  }

  Widget _navButton({
    required IconData icon,
    required bool enabled,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: enabled ? onTap : null,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 150),
        width: 26,
        height: 26,
        margin: const EdgeInsets.symmetric(horizontal: 2),
        decoration: BoxDecoration(
          color: enabled ? Colors.grey.shade100 : Colors.transparent,
          borderRadius: BorderRadius.circular(6),
          border: enabled ? Border.all(color: Colors.grey.shade200) : null,
        ),
        child: Center(
          child: Icon(
            icon,
            size: 16,
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
              overflow: TextOverflow.visible,
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
      height: isVirtualised
          ? 400
          : (_lines.length * _lineHeight).clamp(60.0, 400.0),
      child: SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        child: SizedBox(
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
          // ── Toolbar (distinct surface) ────────────────────────────────────
          Container(
            padding: const EdgeInsets.fromLTRB(10, 6, 8, 6),
            decoration: BoxDecoration(
              color: Colors.grey.shade50,
              borderRadius: const BorderRadius.vertical(
                top: Radius.circular(8),
              ),
              border: Border(
                bottom: BorderSide(color: Colors.grey.shade200),
              ),
            ),
            child: _buildToolbar(),
          ),
          // ── Content ───────────────────────────────────────────────────────
          _buildContent(),
        ],
      ),
    );
  }
}
