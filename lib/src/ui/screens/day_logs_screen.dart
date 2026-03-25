import 'package:flutter/material.dart';
import '../../core/api_log_model.dart';
import '../../storage/local_storage_service.dart';
import '../../utils/export_helper.dart';
import '../widgets/log_item_block.dart';

class DayLogsScreen extends StatefulWidget {
  final String dateStr;

  const DayLogsScreen({Key? key, required this.dateStr}) : super(key: key);

  @override
  DayLogsScreenState createState() => DayLogsScreenState();
}

class DayLogsScreenState extends State<DayLogsScreen> {
  List<ApiLogModel> _logs = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadLogs();
  }

  Future<void> _loadLogs() async {
    setState(() => _isLoading = true);
    final logs = await LocalStorageService.instance.getLogsByDate(
      widget.dateStr,
    );
    setState(() {
      _logs = logs;
      _isLoading = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.dateStr),
        actions: [
          IconButton(
            icon: const Icon(Icons.download),
            tooltip: 'Export Day Logs',
            onPressed: () =>
                ExportHelper.exportAndShareLogs(_logs, widget.dateStr),
          ),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _logs.isEmpty
          ? const Center(child: Text('No logs found.'))
          : ListView.builder(
              itemCount: _logs.length,
              itemBuilder: (context, index) {
                return LogItemBlock(log: _logs[index]);
              },
            ),
    );
  }
}
