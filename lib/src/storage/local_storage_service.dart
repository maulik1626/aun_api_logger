import 'package:path/path.dart';
import 'package:sqflite/sqflite.dart';
import '../core/api_log_model.dart';
import 'package:intl/intl.dart';

class LocalStorageService {
  static final LocalStorageService instance = LocalStorageService._init();
  static Database? _database;

  LocalStorageService._init();

  Future<Database> get database async {
    if (_database != null) return _database!;
    _database = await _initDB('aun_api_logger.db');
    return _database!;
  }

  Future<Database> _initDB(String filePath) async {
    final dbPath = await getDatabasesPath();
    final path = join(dbPath, filePath);
    return await openDatabase(path, version: 1, onCreate: _createDB);
  }

  Future _createDB(Database db, int version) async {
    const idType = 'INTEGER PRIMARY KEY AUTOINCREMENT';
    const textType = 'TEXT';
    const intType = 'INTEGER';

    await db.execute('''
CREATE TABLE api_logs (
  id $idType,
  method $textType,
  url $textType,
  endpoint $textType,
  statusCode $intType,
  requestHeaders $textType,
  requestBody $textType,
  responseHeaders $textType,
  responseBody $textType,
  requestTime $intType,
  durationMs $intType
)
''');
  }

  Future<int> insertLog(ApiLogModel log) async {
    final db = await instance.database;
    return await db.insert('api_logs', log.toMap());
  }

  Future<int> updateLog(ApiLogModel log) async {
    final db = await instance.database;
    return await db.update(
      'api_logs',
      log.toMap(),
      where: 'id = ?',
      whereArgs: [log.id],
    );
  }

  /// Returns distinct dates in the format YYYY-MM-DD that have logs
  Future<List<String>> getLogDates() async {
    final db = await instance.database;
    final result = await db.rawQuery(
      'SELECT DISTINCT requestTime FROM api_logs ORDER BY requestTime DESC',
    );

    // Convert epoch to formatted dates to group them
    final Set<String> distinctDates = {};
    for (var row in result) {
      final requestTime = row['requestTime'] as int;
      final date = DateTime.fromMillisecondsSinceEpoch(requestTime);
      final formattedDate = DateFormat('yyyy-MM-dd').format(date);
      distinctDates.add(formattedDate);
    }
    return distinctDates.toList();
  }

  /// Fetches all logs for a specific YYYY-MM-DD date
  Future<List<ApiLogModel>> getLogsByDate(String dateStr) async {
    final db = await instance.database;

    // Parse the start and end of that day
    final dateTimeStr = '$dateStr 00:00:00.000';
    final startOfDay = DateTime.parse(dateTimeStr).millisecondsSinceEpoch;
    final endOfDay = startOfDay + 86400000; // + 1 day in milliseconds

    final result = await db.rawQuery(
      'SELECT * FROM api_logs WHERE requestTime >= ? AND requestTime < ? ORDER BY requestTime DESC',
      [startOfDay, endOfDay],
    );

    return result.map((json) => ApiLogModel.fromMap(json)).toList();
  }

  Future<int> deleteLogsByDate(String dateStr) async {
    final db = await instance.database;
    final dateTimeStr = '$dateStr 00:00:00.000';
    final startOfDay = DateTime.parse(dateTimeStr).millisecondsSinceEpoch;
    final endOfDay = startOfDay + 86400000;

    return await db.delete(
      'api_logs',
      where: 'requestTime >= ? AND requestTime < ?',
      whereArgs: [startOfDay, endOfDay],
    );
  }

  Future<int> deleteAllLogs() async {
    final db = await instance.database;
    return await db.delete('api_logs');
  }

  Future<List<ApiLogModel>> getAllLogs() async {
    final db = await instance.database;
    const orderBy = 'requestTime DESC';
    final result = await db.query('api_logs', orderBy: orderBy);
    return result.map((json) => ApiLogModel.fromMap(json)).toList();
  }
}
