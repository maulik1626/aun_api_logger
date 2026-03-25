import 'package:flutter/material.dart';
import '../../storage/local_storage_service.dart';
import '../../utils/export_helper.dart';
import 'day_logs_screen.dart';

class LogDatesScreen extends StatefulWidget {
  const LogDatesScreen({Key? key}) : super(key: key);

  @override
  LogDatesScreenState createState() => LogDatesScreenState();
}

class LogDatesScreenState extends State<LogDatesScreen> {
  List<String> _dates = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadDates();
  }

  Future<void> _loadDates() async {
    setState(() => _isLoading = true);
    final dates = await LocalStorageService.instance.getLogDates();
    setState(() {
      _dates = dates;
      _isLoading = false;
    });
  }

  Future<void> _clearAll() async {
    await LocalStorageService.instance.deleteAllLogs();
    _loadDates();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('API Logs'),
        actions: [
          IconButton(
            icon: const Icon(Icons.download),
            tooltip: 'Export All History',
            onPressed: () => ExportHelper.exportAllLogs(),
          ),
          IconButton(
            icon: const Icon(Icons.delete_forever),
            tooltip: 'Clear All',
            onPressed: () {
              showDialog(
                context: context,
                builder: (c) => AlertDialog(
                  title: const Text('Clear All'),
                  content: const Text(
                    'Are you sure you want to delete all logs?',
                  ),
                  actions: [
                    TextButton(
                      onPressed: () => Navigator.pop(c),
                      child: const Text('Cancel'),
                    ),
                    TextButton(
                      onPressed: () {
                        Navigator.pop(c);
                        _clearAll();
                      },
                      child: const Text(
                        'Clear',
                        style: TextStyle(
                          color: Colors.red,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ],
                ),
              );
            },
          ),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _dates.isEmpty
          ? const Center(child: Text('No local API logs found.'))
          : ListView.builder(
              itemCount: _dates.length,
              itemBuilder: (context, index) {
                final date = _dates[index];
                return ListTile(
                  title: Text(
                    date,
                    style: const TextStyle(fontWeight: FontWeight.bold),
                  ),
                  trailing: const Icon(Icons.chevron_right),
                  onTap: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) => DayLogsScreen(dateStr: date),
                      ),
                    ).then((_) => _loadDates());
                  },
                );
              },
            ),
    );
  }
}
