import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import '../../core/api_log_model.dart';
import '../../storage/local_storage_service.dart';
import '../../utils/export_helper.dart';
import '../../utils/color_helper.dart';
import '../widgets/log_item_block.dart';
import '../widgets/log_list_tile.dart';
import '../widgets/log_details_panel.dart';
import 'package:intl/intl.dart';

class DayLogsScreen extends StatefulWidget {
  final String dateStr;

  const DayLogsScreen({super.key, required this.dateStr});

  @override
  DayLogsScreenState createState() => DayLogsScreenState();
}

enum LogFilter { all, get, post, put, delete, success, error }

class DayLogsScreenState extends State<DayLogsScreen> {
  List<ApiLogModel> _allLogs = [];
  List<ApiLogModel> _filteredLogs = [];
  List<String> _uniqueGroups = [];

  bool _isLoading = true;
  String _searchQuery = '';
  String? _selectedGroup;
  LogFilter _currentFilter = LogFilter.all;
  ApiLogModel? _selectedLog;

  final TextEditingController _searchController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _loadLogs();
    _searchController.addListener(_onSearchChanged);
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  void _onSearchChanged() {
    if (_searchController.text.contains(' ')) {
      final newText = _searchController.text.replaceAll(' ', '_');
      _searchController.value = _searchController.value.copyWith(
        text: newText,
        selection: TextSelection.collapsed(
          offset: _searchController.selection.end,
        ),
      );
      return;
    }

    setState(() {
      _searchQuery = _searchController.text.toLowerCase();
      _applyFilters();
    });
  }

  Future<void> _loadLogs() async {
    setState(() => _isLoading = true);
    final logs = await LocalStorageService.instance.getLogsByDate(
      widget.dateStr,
    );

    final groups = logs.map((l) => _getGroupName(l.endpoint)).toSet().toList();
    groups.sort();

    setState(() {
      _allLogs = logs;
      _uniqueGroups = groups;
      _applyFilters();
      _isLoading = false;
    });
  }

  /// Strips `aun_*` app-name prefix from endpoint paths.
  /// e.g. `/aun_pets_parent/booking/upcoming/` → `booking/upcoming/`
  /// e.g. `/utilities/configurator/` → `utilities/configurator/`
  String _getDisplayPath(String endpoint) {
    final segments = endpoint.split('/').where((s) => s.isNotEmpty).toList();
    if (segments.isEmpty) return endpoint;
    if (segments.first.startsWith('aun_')) {
      return segments.sublist(1).join('/');
    }
    return segments.join('/');
  }

  /// Gets the top-level group name for filter chips.
  /// e.g. `/aun_pets_parent/booking/upcoming/` → `booking`
  /// e.g. `/utilities/configurator/` → `utilities`
  String _getGroupName(String endpoint) {
    final display = _getDisplayPath(endpoint);
    final segments = display.split('/').where((s) => s.isNotEmpty).toList();
    if (segments.isEmpty) return display;
    return segments.first;
  }

  void _applyFilters() {
    List<ApiLogModel> result = List.from(_allLogs);

    if (_searchQuery.isNotEmpty) {
      result = result.where((log) {
        return log.endpoint.toLowerCase().contains(_searchQuery);
      }).toList();
    }

    if (_selectedGroup != null) {
      result = result
          .where((log) => _getGroupName(log.endpoint) == _selectedGroup)
          .toList();
    }

    switch (_currentFilter) {
      case LogFilter.all:
        break;
      case LogFilter.get:
        result = result.where((l) => l.method.toUpperCase() == 'GET').toList();
        break;
      case LogFilter.post:
        result = result.where((l) => l.method.toUpperCase() == 'POST').toList();
        break;
      case LogFilter.put:
        result = result.where((l) => l.method.toUpperCase() == 'PUT').toList();
        break;
      case LogFilter.delete:
        result = result
            .where((l) => l.method.toUpperCase() == 'DELETE')
            .toList();
        break;
      case LogFilter.success:
        result = result
            .where(
              (l) =>
                  l.statusCode != null &&
                  l.statusCode! >= 200 &&
                  l.statusCode! < 300,
            )
            .toList();
        break;
      case LogFilter.error:
        result = result
            .where((l) => l.statusCode != null && l.statusCode! >= 400)
            .toList();
        break;
    }

    _filteredLogs = result;
    if (_filteredLogs.isEmpty) {
      _selectedLog = null;
    } else if (_selectedLog == null || !_filteredLogs.contains(_selectedLog)) {
      _selectedLog = _filteredLogs.first;
    }
  }

  void _showIOSFilterSheet(BuildContext context) {
    showCupertinoModalPopup(
      context: context,
      builder: (BuildContext context) => CupertinoActionSheet(
        title: const Text('Filter Logs'),
        actions: <CupertinoActionSheetAction>[
          _buildCupertinoAction('All Methods/Statuses', LogFilter.all),
          _buildCupertinoAction('Success (2xx)', LogFilter.success),
          _buildCupertinoAction('Errors (4xx, 5xx)', LogFilter.error),
          _buildCupertinoAction('GET', LogFilter.get),
          _buildCupertinoAction('POST', LogFilter.post),
          _buildCupertinoAction('PUT', LogFilter.put),
          _buildCupertinoAction('DELETE', LogFilter.delete),
        ],
        cancelButton: CupertinoActionSheetAction(
          isDestructiveAction: true,
          onPressed: () => Navigator.pop(context),
          child: const Text('Cancel'),
        ),
      ),
    );
  }

  CupertinoActionSheetAction _buildCupertinoAction(
    String title,
    LogFilter filter,
  ) {
    return CupertinoActionSheetAction(
      onPressed: () {
        setState(() => _currentFilter = filter);
        _applyFilters();
        Navigator.pop(context);
      },
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Text(title),
          if (_currentFilter == filter) ...[
            const SizedBox(width: 8),
            const Icon(CupertinoIcons.checkmark_alt, size: 18),
          ],
        ],
      ),
    );
  }

  Widget _buildTabletDetailsPanel(bool isIOS) {
    if (_selectedLog == null) {
      return Center(
        child: Text(
          'Select a log to view details',
          style: TextStyle(
            color: isIOS ? CupertinoColors.systemGrey : Colors.grey.shade600,
          ),
        ),
      );
    }

    final format = DateFormat('hh:mm:ss a');
    final timeStr = format.format(
      DateTime.fromMillisecondsSinceEpoch(_selectedLog!.requestTime),
    );
    final statusColor = LogColorHelper.getStatusColor(_selectedLog!.statusCode);

    return Container(
      color: Colors.white,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // Header
          Container(
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(
              color: Colors.white,
              border: Border(
                bottom: BorderSide(
                  color:
                      isIOS ? CupertinoColors.systemGrey5 : Colors.grey.shade200,
                ),
              ),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 8,
                        vertical: 4,
                      ),
                      decoration: BoxDecoration(
                        color: LogColorHelper.getMethodColor(
                          _selectedLog!.method,
                        ).withValues(alpha: 0.1),
                        borderRadius: BorderRadius.circular(6),
                      ),
                      child: Text(
                        _selectedLog!.method,
                        style: TextStyle(
                          color: LogColorHelper.getMethodColor(
                            _selectedLog!.method,
                          ),
                          fontSize: 12,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Text(
                      _selectedLog!.statusCode?.toString() ?? 'PENDING',
                      style: TextStyle(
                        color: statusColor,
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const Spacer(),
                    Text(
                      '$timeStr  •  ${_selectedLog!.durationMs}ms',
                      style: TextStyle(
                        fontSize: 14,
                        color: Colors.grey.shade600,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                Text(
                  _getDisplayPath(
                    _selectedLog!.endpoint.isNotEmpty
                        ? _selectedLog!.endpoint
                        : _selectedLog!.url,
                  ),
                  style: const TextStyle(
                    fontWeight: FontWeight.w600,
                    fontSize: 18,
                    color: Colors.black87,
                  ),
                ),
              ],
            ),
          ),
          // Scrollable details
          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(24),
              child: LogDetailsPanel(log: _selectedLog!, isIOS: isIOS),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildBody(bool isIOS) {
    if (_isLoading) {
      return Center(
        child: isIOS
            ? const CupertinoActivityIndicator()
            : const CircularProgressIndicator(),
      );
    }

    return LayoutBuilder(
      builder: (context, constraints) {
        final isTablet = constraints.maxWidth >= 768;

        final listContent = Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 8, 16, 8),
              child: isIOS
                  ? CupertinoSearchTextField(
                      controller: _searchController,
                      placeholder: 'Search exact endpoints...',
                    )
                  : TextField(
                      controller: _searchController,
                      decoration: InputDecoration(
                        hintText: 'Search exact endpoints...',
                        prefixIcon: const Icon(Icons.search_rounded),
                        suffixIcon: _searchQuery.isNotEmpty
                            ? IconButton(
                                icon: const Icon(Icons.clear_rounded),
                                onPressed: () {
                                  _searchController.clear();
                                  FocusScope.of(context).unfocus();
                                },
                              )
                            : null,
                        filled: true,
                        fillColor: Colors.grey.shade50,
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                          borderSide: BorderSide(color: Colors.grey.shade300),
                        ),
                        enabledBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                          borderSide: BorderSide(color: Colors.grey.shade300),
                        ),
                        contentPadding: const EdgeInsets.symmetric(
                          horizontal: 16,
                          vertical: 12,
                        ),
                      ),
                    ),
            ),

            if (_uniqueGroups.isNotEmpty)
              SizedBox(
                height: 40,
                child: ListView.builder(
                  scrollDirection: Axis.horizontal,
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  itemCount: _uniqueGroups.length,
                  itemBuilder: (context, index) {
                    final group = _uniqueGroups[index];
                    final isSelected = _selectedGroup == group;
                    final activeColor = isIOS
                        ? CupertinoColors.activeBlue
                        : Theme.of(context).primaryColor;

                    return Padding(
                      padding: const EdgeInsets.only(right: 8),
                      child: FilterChip(
                        label: Text(
                          group,
                          style: TextStyle(
                            fontSize: 12,
                            color: isSelected ? Colors.white : Colors.black87,
                            fontWeight: isSelected
                                ? FontWeight.bold
                                : FontWeight.normal,
                          ),
                        ),
                        selected: isSelected,
                        onSelected: (bool selected) {
                          setState(() {
                            _selectedGroup = selected ? group : null;
                            _applyFilters();
                          });
                        },
                        showCheckmark: false,
                        backgroundColor: isIOS
                            ? CupertinoColors.systemGrey6
                            : Colors.grey.shade100,
                        selectedColor: activeColor,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(20),
                          side: BorderSide(
                            color: isSelected
                                ? Colors.transparent
                                : Colors.grey.shade300,
                          ),
                        ),
                      ),
                    );
                  },
                ),
              ),

            if (_allLogs.isNotEmpty)
              Padding(
                padding: const EdgeInsets.symmetric(
                  horizontal: 16.0,
                  vertical: 8.0,
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      'Showing ${_filteredLogs.length} logs',
                      style: TextStyle(
                        color: isIOS
                            ? CupertinoColors.systemGrey
                            : Colors.grey.shade600,
                        fontSize: 13,
                      ),
                    ),
                    if (!isIOS && !isTablet)
                      PopupMenuButton<LogFilter>(
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(
                              Icons.filter_list_rounded,
                              size: 16,
                              color: Theme.of(context).primaryColor,
                            ),
                            const SizedBox(width: 4),
                            Text(
                              'Filter',
                              style: TextStyle(
                                color: Theme.of(context).primaryColor,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ],
                        ),
                        onSelected: (LogFilter result) {
                          setState(() {
                            _currentFilter = result;
                            _applyFilters();
                          });
                        },
                        itemBuilder: (BuildContext context) =>
                            <PopupMenuEntry<LogFilter>>[
                              const PopupMenuItem<LogFilter>(
                                value: LogFilter.all,
                                child: Text('All Methods/Statuses'),
                              ),
                              const PopupMenuItem<LogFilter>(
                                value: LogFilter.success,
                                child: Text('Success (2xx)'),
                              ),
                              const PopupMenuItem<LogFilter>(
                                value: LogFilter.error,
                                child: Text('Errors (4xx, 5xx)'),
                              ),
                              const PopupMenuItem<LogFilter>(
                                value: LogFilter.get,
                                child: Text('GET'),
                              ),
                              const PopupMenuItem<LogFilter>(
                                value: LogFilter.post,
                                child: Text('POST'),
                              ),
                              const PopupMenuItem<LogFilter>(
                                value: LogFilter.put,
                                child: Text('PUT'),
                              ),
                              const PopupMenuItem<LogFilter>(
                                value: LogFilter.delete,
                                child: Text('DELETE'),
                              ),
                            ],
                      ),
                  ],
                ),
              ),
            Expanded(
              child: _filteredLogs.isEmpty
                  ? Center(
                      child: Text(
                        _allLogs.isEmpty
                            ? 'No logs found.'
                            : 'No logs match filter.',
                        style: TextStyle(
                          color: isIOS
                              ? CupertinoColors.systemGrey
                              : Colors.grey.shade600,
                        ),
                      ),
                    )
                  : ListView.builder(
                      padding: const EdgeInsets.only(bottom: 24),
                      itemCount: _filteredLogs.length,
                      itemBuilder: (context, index) {
                        final log = _filteredLogs[index];
                        final displayEndpoint = _getDisplayPath(
                          log.endpoint.isNotEmpty ? log.endpoint : log.url,
                        );

                        if (isTablet) {
                          return LogListTile(
                            log: log,
                            isSelected: _selectedLog?.id == log.id,
                            isIOS: isIOS,
                            displayEndpoint: displayEndpoint,
                            onTap: () {
                              setState(() {
                                _selectedLog = log;
                              });
                            },
                          );
                        }

                        return LogItemBlock(
                          log: log,
                          isIOS: isIOS,
                          displayEndpoint: displayEndpoint,
                        );
                      },
                    ),
            ),
          ],
        );

        if (isTablet) {
          return Row(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // Left Panel (30%)
              Expanded(
                flex: 3,
                child: Container(
                  decoration: BoxDecoration(
                    color:
                        isIOS ? CupertinoColors.systemGroupedBackground : Colors.grey.shade50,
                    border: Border(
                      right: BorderSide(
                        color:
                            isIOS ? CupertinoColors.systemGrey5 : Colors.grey.shade300,
                        width: 1,
                      ),
                    ),
                  ),
                  child: listContent,
                ),
              ),
              // Right Panel (70%)
              Expanded(
                flex: 7,
                child: _buildTabletDetailsPanel(isIOS),
              ),
            ],
          );
        }

        return listContent;
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final isIOS =
        Theme.of(context).platform == TargetPlatform.iOS ||
        Theme.of(context).platform == TargetPlatform.macOS;

    if (isIOS) {
      return CupertinoPageScaffold(
        backgroundColor: CupertinoColors.white,
        navigationBar: CupertinoNavigationBar(
          backgroundColor: CupertinoColors.white,
          border: null,
          middle: Text(widget.dateStr),
          trailing: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              CupertinoButton(
                padding: EdgeInsets.zero,
                child: const Icon(CupertinoIcons.line_horizontal_3_decrease),
                onPressed: () => _showIOSFilterSheet(context),
              ),
              CupertinoButton(
                padding: EdgeInsets.zero,
                child: const Icon(CupertinoIcons.share),
                onPressed: () => ExportHelper.exportAndShareLogs(
                  _filteredLogs,
                  widget.dateStr,
                ),
              ),
            ],
          ),
        ),
        child: SafeArea(
          child: Material(
            type: MaterialType.transparency,
            child: _buildBody(true),
          ),
        ),
      );
    }

    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        title: Text(
          widget.dateStr,
          style: const TextStyle(
            color: Colors.black,
            fontWeight: FontWeight.w600,
          ),
        ),
        backgroundColor: Colors.white,
        elevation: 0,
        scrolledUnderElevation: 0,
        iconTheme: const IconThemeData(color: Colors.black),
        actions: [
          IconButton(
            icon: const Icon(Icons.share_rounded),
            tooltip: 'Export Day Logs',
            onPressed: () =>
                ExportHelper.exportAndShareLogs(_filteredLogs, widget.dateStr),
          ),
        ],
      ),
      body: _buildBody(false),
    );
  }
}
