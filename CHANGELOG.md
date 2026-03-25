## 1.1.0 - 2026-03-25
### Added
- Added a search bar to `LogDatesScreen` to filter log dates directly.
- Added a sorting filter menu to `LogDatesScreen` to switch between 'Newest First' and 'Oldest First'.

### Changed
- Redesigned `LogDatesScreen` to use a modern, device-responsive UI including an adaptive grid layout for tablets and elegant date cards.

## 1.0.0

* Initial release of `aun_api_logger`.
* Added `ApiLoggerInterceptor` for capturing Dio requests and responses locally.
* Added `LocalStorageService` utilizing SQLite (`sqflite`) for isolated on-device persistence.
* Created built-in UI: `LogDatesScreen` and `DayLogsScreen` for fast API inspection.
* Implemented complete Copy to Clipboard and JSON Export sharing mechanisms.
