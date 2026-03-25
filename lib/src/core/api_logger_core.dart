import '../storage/local_storage_service.dart';

class AunApiLogger {
  static final AunApiLogger instance = AunApiLogger._internal();

  AunApiLogger._internal();

  /// Call this to initialize the database
  Future<void> initialize() async {
    await LocalStorageService.instance.database;
  }
}
