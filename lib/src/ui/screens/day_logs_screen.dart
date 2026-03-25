import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import '../../core/api_log_model.dart';
import '../../storage/local_storage_service.dart';
import '../../utils/export_helper.dart';
import '../widgets/log_item_block.dart';

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
  bool _isLoading = true;
  String _searchQuery = '';
  LogFilter _currentFilter = LogFilter.all;

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
    setState(() {
      _allLogs = logs;
      _applyFilters();
      _isLoading = false;
    });
  }

  void _applyFilters() {
    List<ApiLogModel> result = List.from(_allLogs);

    if (_searchQuery.isNotEmpty) {
      result = result.where((log) {
        final urlMatch = log.url.toLowerCase().contains(_searchQuery);
        final endpointMatch = log.endpoint.toLowerCase().contains(_searchQuery);
        return urlMatch || endpointMatch;
      }).toList();
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
  }

  void _showIOSFilterSheet(BuildContext context) {
    showCupertinoModalPopup(
      context: context,
      builder: (BuildContext context) => CupertinoActionSheet(
        title: const Text('Filter Logs'),
        actions: <CupertinoActionSheetAction>[
          _buildCupertinoAction('All Logs', LogFilter.all),
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

  Widget _buildBody(bool isIOS) {
    if (_isLoading) {
      return Center(
        child: isIOS
            ? const CupertinoActivityIndicator()
            : const CircularProgressIndicator(),
      );
    }

    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 8, 16, 16),
          child: isIOS
              ? CupertinoSearchTextField(
                  controller: _searchController,
                  placeholder: 'Search endpoint or URL...',
                )
              : TextField(
                  controller: _searchController,
                  decoration: InputDecoration(
                    hintText: 'Search endpoint or URL...',
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
        if (_allLogs.isNotEmpty)
          Padding(
            padding: const EdgeInsets.symmetric(
              horizontal: 16.0,
              vertical: 4.0,
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
                if (!isIOS)
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
                            child: Text('All Logs'),
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
                    return LogItemBlock(
                      log: _filteredLogs[index],
                      isIOS: isIOS,
                    );
                  },
                ),
        ),
      ],
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
