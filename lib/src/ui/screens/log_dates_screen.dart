import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import '../../storage/local_storage_service.dart';
import '../../utils/export_helper.dart';
import 'day_logs_screen.dart';

class LogDatesScreen extends StatefulWidget {
  const LogDatesScreen({super.key});

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
    dates.sort((a, b) => b.compareTo(a)); // Always newest first
    setState(() {
      _dates = dates;
      _isLoading = false;
    });
  }

  Widget _buildDateCard(BuildContext context, String date, bool isIOS) {
    if (isIOS) {
      return CupertinoButton(
        padding: EdgeInsets.zero,
        onPressed: () {
          Navigator.push(
            context,
            CupertinoPageRoute(builder: (_) => DayLogsScreen(dateStr: date)),
          ).then((_) => _loadDates());
        },
        child: Container(
          margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
          padding: const EdgeInsets.all(16.0),
          decoration: BoxDecoration(
            color: CupertinoColors.white,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: CupertinoColors.systemGrey5, width: 1),
            boxShadow: [
              BoxShadow(
                color: CupertinoColors.black.withValues(alpha: 0.02),
                blurRadius: 8,
                offset: const Offset(0, 2),
              ),
            ],
          ),
          child: Row(
            children: [
              Icon(
                CupertinoIcons.calendar,
                color: CupertinoTheme.of(context).primaryColor,
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Text(
                  date,
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                    color: CupertinoColors.black,
                  ),
                ),
              ),
              const Icon(
                CupertinoIcons.chevron_right,
                color: CupertinoColors.systemGrey3,
              ),
            ],
          ),
        ),
      );
    }

    return Card(
      elevation: 0,
      color: Colors.white,
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: BorderSide(color: Colors.grey.shade200),
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
              Icon(
                Icons.calendar_today_rounded,
                color: Theme.of(context).primaryColor,
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Text(
                  date,
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                    color: Colors.black,
                  ),
                ),
              ),
              Icon(Icons.chevron_right_rounded, color: Colors.grey.shade400),
            ],
          ),
        ),
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

    if (_dates.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              isIOS ? CupertinoIcons.tray : Icons.inbox_rounded,
              size: 64,
              color: isIOS ? CupertinoColors.systemGrey : Colors.grey.shade400,
            ),
            const SizedBox(height: 16),
            Text(
              'No API logs found.',
              style: TextStyle(
                fontSize: 16,
                color: isIOS
                    ? CupertinoColors.systemGrey
                    : Colors.grey.shade600,
              ),
            ),
          ],
        ),
      );
    }

    return LayoutBuilder(
      builder: (context, constraints) {
        if (constraints.maxWidth >= 600) {
          return GridView.builder(
            padding: const EdgeInsets.symmetric(vertical: 16),
            gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: constraints.maxWidth > 900 ? 3 : 2,
              childAspectRatio: 3,
            ),
            itemCount: _dates.length,
            itemBuilder: (context, index) =>
                _buildDateCard(context, _dates[index], isIOS),
          );
        } else {
          return ListView.builder(
            padding: const EdgeInsets.symmetric(vertical: 16),
            itemCount: _dates.length,
            itemBuilder: (context, index) =>
                _buildDateCard(context, _dates[index], isIOS),
          );
        }
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
          middle: const Text('API Logs'),
          trailing: CupertinoButton(
            padding: EdgeInsets.zero,
            child: const Icon(CupertinoIcons.arrow_down_doc),
            onPressed: () => ExportHelper.exportAllLogs(),
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
        title: const Text(
          'API Logs',
          style: TextStyle(color: Colors.black, fontWeight: FontWeight.w600),
        ),
        backgroundColor: Colors.white,
        elevation: 0,
        scrolledUnderElevation: 0,
        iconTheme: const IconThemeData(color: Colors.black),
        actions: [
          IconButton(
            icon: const Icon(Icons.download_rounded),
            tooltip: 'Export All History',
            onPressed: () => ExportHelper.exportAllLogs(),
          ),
          const SizedBox(width: 8),
        ],
      ),
      body: _buildBody(false),
    );
  }
}
