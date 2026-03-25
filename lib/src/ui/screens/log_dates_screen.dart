import 'package:flutter/material.dart';
import '../../storage/local_storage_service.dart';
import '../../utils/export_helper.dart';
import 'day_logs_screen.dart';

class LogDatesScreen extends StatefulWidget {
  const LogDatesScreen({super.key});

  @override
  LogDatesScreenState createState() => LogDatesScreenState();
}

enum DateSortOrder { newestFirst, oldestFirst }

class LogDatesScreenState extends State<LogDatesScreen> {
  List<String> _allDates = [];
  List<String> _filteredDates = [];
  bool _isLoading = true;
  String _searchQuery = '';
  DateSortOrder _sortOrder = DateSortOrder.newestFirst;

  final TextEditingController _searchController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _loadDates();
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

  Future<void> _loadDates() async {
    setState(() => _isLoading = true);
    final dates = await LocalStorageService.instance.getLogDates();
    setState(() {
      _allDates = dates;
      _applyFilters();
      _isLoading = false;
    });
  }

  void _applyFilters() {
    List<String> result = List.from(_allDates);

    if (_searchQuery.isNotEmpty) {
      result = result
          .where((date) => date.toLowerCase().contains(_searchQuery))
          .toList();
    }

    if (_sortOrder == DateSortOrder.newestFirst) {
      result.sort((a, b) => b.compareTo(a));
    } else {
      result.sort((a, b) => a.compareTo(b));
    }

    _filteredDates = result;
  }

  Future<void> _clearAll() async {
    await LocalStorageService.instance.deleteAllLogs();
    _loadDates();
  }

  void _showClearAllDialog() {
    showDialog(
      context: context,
      builder: (c) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Text('Clear All Logs'),
        content: const Text(
          'Are you sure you want to delete all stored API logs? This action cannot be undone.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(c),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.red,
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(8),
              ),
            ),
            onPressed: () {
              Navigator.pop(c);
              _clearAll();
            },
            child: const Text('Clear All'),
          ),
        ],
      ),
    );
  }

  Widget _buildDateCard(BuildContext context, String date) {
    final theme = Theme.of(context);
    return Card(
      elevation: 0,
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: BorderSide(
          color: theme.colorScheme.outline.withValues(alpha: 0.2),
          width: 1,
        ),
      ),
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: () {
          Navigator.push(
            context,
            MaterialPageRoute(builder: (_) => DayLogsScreen(dateStr: date)),
          ).then((_) => _loadDates());
        },
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: theme.colorScheme.primary.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(
                  Icons.calendar_today_rounded,
                  color: theme.colorScheme.primary,
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      date,
                      style: theme.textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      'Tap to view API logs',
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: theme.colorScheme.onSurface.withValues(
                          alpha: 0.6,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              Icon(
                Icons.chevron_right_rounded,
                color: theme.colorScheme.onSurface.withValues(alpha: 0.4),
              ),
            ],
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      backgroundColor: theme.colorScheme.surface,
      appBar: AppBar(
        title: const Text(
          'API Logs',
          style: TextStyle(fontWeight: FontWeight.w600),
        ),
        centerTitle: true,
        elevation: 0,
        backgroundColor: Colors.transparent,
        scrolledUnderElevation: 0,
        actions: [
          IconButton(
            icon: const Icon(Icons.download_rounded),
            tooltip: 'Export All History',
            onPressed: () => ExportHelper.exportAllLogs(),
          ),
          PopupMenuButton<DateSortOrder>(
            icon: const Icon(Icons.filter_list_rounded),
            tooltip: 'Filter/Sort',
            onSelected: (DateSortOrder result) {
              setState(() {
                _sortOrder = result;
                _applyFilters();
              });
            },
            itemBuilder: (BuildContext context) =>
                <PopupMenuEntry<DateSortOrder>>[
                  const PopupMenuItem<DateSortOrder>(
                    value: DateSortOrder.newestFirst,
                    child: Text('Newest First'),
                  ),
                  const PopupMenuItem<DateSortOrder>(
                    value: DateSortOrder.oldestFirst,
                    child: Text('Oldest First'),
                  ),
                ],
          ),
          IconButton(
            icon: const Icon(
              Icons.delete_sweep_rounded,
              color: Colors.redAccent,
            ),
            tooltip: 'Clear All',
            onPressed: _showClearAllDialog,
          ),
          const SizedBox(width: 8),
        ],
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 8, 16, 16),
            child: TextField(
              controller: _searchController,
              decoration: InputDecoration(
                hintText: 'Search date (e.g., 2026-03-25)...',
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
                fillColor: theme.colorScheme.onSurface.withValues(alpha: 0.04),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(30),
                  borderSide: BorderSide.none,
                ),
                contentPadding: const EdgeInsets.symmetric(
                  horizontal: 20,
                  vertical: 14,
                ),
              ),
            ),
          ),
          Expanded(
            child: _isLoading
                ? const Center(child: CircularProgressIndicator())
                : _filteredDates.isEmpty
                ? Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          Icons.search_off_rounded,
                          size: 64,
                          color: theme.colorScheme.onSurface.withValues(
                            alpha: 0.3,
                          ),
                        ),
                        const SizedBox(height: 16),
                        Text(
                          _allDates.isEmpty
                              ? 'No API logs found.'
                              : 'No dates match your search.',
                          style: theme.textTheme.titleMedium?.copyWith(
                            color: theme.colorScheme.onSurface.withValues(
                              alpha: 0.6,
                            ),
                          ),
                        ),
                      ],
                    ),
                  )
                : LayoutBuilder(
                    builder: (context, constraints) {
                      if (constraints.maxWidth >= 600) {
                        return GridView.builder(
                          padding: const EdgeInsets.only(bottom: 24),
                          gridDelegate:
                              SliverGridDelegateWithFixedCrossAxisCount(
                                crossAxisCount: constraints.maxWidth > 900
                                    ? 3
                                    : 2,
                                childAspectRatio: 3,
                                crossAxisSpacing: 0,
                                mainAxisSpacing: 0,
                              ),
                          itemCount: _filteredDates.length,
                          itemBuilder: (context, index) {
                            return _buildDateCard(
                              context,
                              _filteredDates[index],
                            );
                          },
                        );
                      } else {
                        return ListView.builder(
                          padding: const EdgeInsets.only(bottom: 24),
                          itemCount: _filteredDates.length,
                          itemBuilder: (context, index) {
                            return _buildDateCard(
                              context,
                              _filteredDates[index],
                            );
                          },
                        );
                      }
                    },
                  ),
          ),
        ],
      ),
    );
  }
}
