## 2.2.1 - 2026-04-20

### Changed

- **Searchable Response Body — toolbar polish**: Redesigned the `SearchableJsonCodeBlock` toolbar for a more intuitive, production-grade UX:
  - **Left**: A compact "Search" pill that expands inline to the full search bar with match counter, up/down nav arrows, and a close button.
  - **Right**: Copy and Wrap icons are now always visible and pinned to the right, separated by a subtle vertical divider.
  - Toolbar sits on a distinct grey `50` surface with a bottom border, visually separating it from the code content.
  - Active Wrap icon turns blue to indicate the current state.
  - Match counter badge uses pill-shaped corners for a polished look.
  - Floating SnackBar style for the copy confirmation.

### Dependencies

```yaml
dependencies:
  aun_api_logger:
    git:
      url: https://github.com/maulik1626/aun_api_logger.git
      ref: v2.2.1
```

## 2.2.0 - 2026-04-20

### Added

- **Searchable Response Body**: The "Response Body" block now features a dedicated in-block search bar with:
  - Live search with 200ms debounce for smooth UX on large payloads.
  - Yellow highlight for all occurrences, orange highlight for the active match.
  - Match counter badge showing `X of Y` results.
  - Up (∧) and Down (∨) navigation arrows that smoothly scroll to each match.
  - Virtualized `ListView.builder` rendering with fixed `itemExtent` for O(1) scroll-to-match on huge payloads (≥ 100 lines).
  - Graceful degradation to a standard scrollable column for small responses.
- **New widget**: `SearchableJsonCodeBlock` in `lib/src/ui/widgets/searchable_json_code_block.dart`.

### Dependencies

```yaml
dependencies:
  aun_api_logger:
    git:
      url: https://github.com/maulik1626/aun_api_logger.git
      ref: v2.2.0
```

## 2.1.0 - 2026-04-20

### Added

- **Tablet Split-Panel UI**: `DayLogsScreen` now features an adaptive layout. On devices with a screen width of 768px or wider (e.g. iPads), the UI transforms into a 30:70 split-panel.
  - The left panel displays a scrollable, compact list of logs.
  - Tapping a log instantly displays its full details (headers, bodies, and syntax highlighting) in the right panel.

### Changed

- Extracted `LogDetailsPanel` and `LogListTile` widgets for better reusability and cleaner code structure.

### Dependencies

```yaml
dependencies:
  aun_api_logger:
    git:
      url: https://github.com/maulik1626/aun_api_logger.git
      ref: v2.1.0
```

## 2.0.1 - 2026-04-20
### Fixed

- **JSON String Formatting**: Fixed an issue where the new HTTP interceptors stored minified JSON responses as single-line strings. The `tryEncodeJson` helper now actively attempts to decode string payloads and re-encodes them with proper indentation before storage.

### Dependencies

```yaml
dependencies:
  aun_api_logger:
    git:
      url: https://github.com/maulik1626/aun_api_logger.git
      ref: v2.0.1
```

## 2.0.0 - 2026-04-20

### Added

- **`package:http` support**: New `ApiLoggerHttpClient` — a drop-in `BaseClient` adapter that logs every request/response via `send()` interception. Supports `http.get`, `http.post`, `http.MultipartRequest`, and all other `BaseClient` methods.
- **`dart:io HttpClient` support**: New `ApiLoggerIoHttpClient` — a full `HttpClient` wrapper that intercepts `openUrl` and `request.close()` to log the complete request → response lifecycle. All `HttpClient` properties and convenience methods are delegated.
- **Shared encode helper**: Extracted `tryEncodeJson()` into `lib/src/utils/encode_helper.dart` for reuse across all interceptors.

### Changed

- **BREAKING**: `dio` is no longer a direct dependency. Dio users must add `dio` to their own `pubspec.yaml` and import the interceptor directly:
  ```dart
  import 'package:aun_api_logger/src/interceptors/api_logger_interceptor.dart';
  ```
- **BREAKING**: The barrel export (`aun_api_logger.dart`) no longer exports `ApiLoggerInterceptor` (Dio). It now exports `ApiLoggerHttpClient` and `ApiLoggerIoHttpClient` by default.
- Added `http: ^1.3.0` as a dependency.

### Dependencies

```yaml
dependencies:
  aun_api_logger:
    git:
      url: https://github.com/maulik1626/aun_api_logger.git
      ref: v2.0.0
```

## 1.9.6 - 2026-03-29

### Changed

- **Share as PNG image**: Swipe → Share now shares the log card screenshot as a **PNG file** directly. The intermediate PDF wrapper and the **`pdf`** package dependency have been removed.
- **Removed**: `PdfShareHelper`, `PdfJsonSyntax` (PDF-only JSON highlighting), and related tests.

### Dependencies

```yaml
dependencies:
  aun_api_logger:
    git:
      url: https://github.com/maulik1626/aun_api_logger.git
      ref: v1.9.6
```

## 1.9.5 - 2026-03-29

### Fixed

- **Shared PDF content clipped / overflowing**: The share screenshot no longer adds an outer grey padding container. The card is now captured at exactly the on-screen card width (`screen width - 32`) using a tight `BoxConstraints` and `ClipRect`, preventing any content overflow from leaking into the image.
- **Long text soft-wrap in share card**: `RichText` in the share-only code block now sets `overflow: TextOverflow.clip` so content that cannot wrap at word boundaries (e.g. long URLs) is clipped at the card boundary instead of escaping it.

### Dependencies

```yaml
dependencies:
  aun_api_logger:
    git:
      url: https://github.com/maulik1626/aun_api_logger.git
      ref: v1.9.5
```

## 1.9.4 - 2026-03-29

### Fixed

- **Shared PDF zoomed in**: The PDF page was a fixed 420 pt wide regardless of the device screen width, making the screenshot content appear larger than it does on screen. The page dimensions are now derived from the screenshot image size divided by the capture pixel ratio, so the PDF content renders at exactly the same physical size as the on-screen card.

### Dependencies

```yaml
dependencies:
  aun_api_logger:
    git:
      url: https://github.com/maulik1626/aun_api_logger.git
      ref: v1.9.4
```

## 1.9.3 - 2026-03-29

### Changed

- **Screenshot PDF capture width**: Share exports now capture the expanded log card at the **normal on-screen card width** (viewport minus horizontal margin), not a widened offscreen width. Content remains **soft-wrapped** and **full-length** in a single-page image-based PDF.

### Added

- **`.cursorrules`**: Documented that any **commit request** must follow release prep: bump `pubspec.yaml`, update `CHANGELOG.md` and `README.md`, then commit (per `PRODUCTION_GUIDELINES.md`).

### Dependencies

```yaml
dependencies:
  aun_api_logger:
    git:
      url: https://github.com/maulik1626/aun_api_logger.git
      ref: v1.9.3
```

## 1.9.2 - 2026-03-29

### Fixed

- **Broken shared PDF layout**: Replaced direct `pdf/widgets` reconstruction of the log card with a **widened offscreen screenshot** of a dedicated expanded share card, then wrapped that image into a **single-page PDF**. This avoids the glyph corruption / collapsed rendering seen in large response bodies.
- **Large log sharing readability**: The share-only card now **pretty-prints JSON** and uses a wider capture width before conversion to PDF, so long request / response payloads stay visually consistent with the app card without PDF pagination.
- **Regression coverage**: Added tests for the image-to-PDF helper and for the widened share card rendering with both small and large payloads.

### Dependencies

```yaml
dependencies:
  aun_api_logger:
    git:
      url: https://github.com/maulik1626/aun_api_logger.git
      ref: v1.9.2
```

## 1.9.1 - 2026-03-29

### Fixed

- **PDF clipping / overflow**: Replaced single fixed-height `pw.Page` (whose height estimate often undershot real `RichText` layout) with **`pw.MultiPage`** so content flows across pages naturally.
- **Large PDFs failing**: Very large JSON responses caused `TooManyPagesException` because one enormous `RichText` widget couldn't be split by the layout engine. Sections are now **chunked** into blocks of ≤48 lines, and long single lines (minified JSON) are split at 2 400 chars before chunking.
- **PDF loader dialog**: A "Preparing PDF" loader is now shown while the PDF is being generated (adaptive: `CupertinoAlertDialog` on iOS, `AlertDialog` on Android).

### Dependencies

```yaml
dependencies:
  aun_api_logger:
    git:
      url: https://github.com/maulik1626/aun_api_logger.git
      ref: v1.9.1
```

## 1.9.0 - 2026-03-29

### Added

- **Adaptive share sheet** after swipe → **Share**: **iOS** uses `CupertinoActionSheet`; **Android** uses a Material modal bottom sheet with drag handle. Choose **without auth tokens** (headers redacted in PDF) or **full data** (includes captured tokens), then the system share sheet opens as before.

### Changed

- PDF sharing is initiated only from the **swipe-revealed Share** control (no long-press share menu). Share-related **haptic** feedback on open was removed per product direction.
- Log card **header** uses `GestureDetector` instead of `InkWell`; **card drop shadow** and Material **surface tint** are cleared for a flatter row.
- **Collapse expanded** log rows before generating/sharing the PDF when needed, so the share flow is reliable on smaller viewports.

### Dependencies

```yaml
dependencies:
  aun_api_logger:
    git:
      url: https://github.com/maulik1626/aun_api_logger.git
      ref: v1.9.0
```

## 1.8.1 - 2026-03-29

### Changed

- PDF export uses **Satoshi** (Regular & Bold, `.otf`) as the embedded font family, aligned with Aun apps (e.g. `aun_pets/pets_customer/fonts`). Replaces Noto Sans for shared log PDFs.

### Dependencies

```yaml
dependencies:
  aun_api_logger:
    git:
      url: https://github.com/maulik1626/aun_api_logger.git
      ref: v1.8.1
```

## 1.8.0 - 2026-03-29

### Added

- PDF export embeds bundled font files (initially Noto Sans; superseded by **Satoshi** in 1.8.1) for broad Unicode coverage and to avoid default Helvetica limitations (see `assets/fonts/README.txt`).

### Changed

- Shared log PDF is a **single continuous page** whose height is estimated from the log content (expanded-card style layout). **No A4 format, no MultiPage pagination.**
- JSON blocks in the PDF use **syntax highlighting** (keys, strings, numbers, booleans, punctuation) aligned with the in-app `JsonCodeBlock` colors.

### Fixed

- Share reliability: ignores overlapping share actions while a share is already running; failed shares show a **SnackBar**; temporary PDF files are deleted after **30s** (was 10s) so the OS has time to read the file.
- iOS: log row uses **`CupertinoContextMenu(child: card)`** so the **header remains tappable** to expand/collapse details (the interactive card must be the context-menu child).

### Dependencies

```yaml
dependencies:
  aun_api_logger:
    git:
      url: https://github.com/maulik1626/aun_api_logger.git
      ref: v1.8.0
```

## 1.7.2 - 2026-03-29

### Fixed

- Fixed `CupertinoContextMenu` crash caused by negative height constraints (`BoxConstraints has non-normalized height constraints`) when the expanded log card consumed nearly the full viewport, leaving no room for the context-menu action sheet.
- Context-menu preview now uses a dedicated collapsed card snapshot instead of the live (potentially expanded) card, ensuring the preview always fits within the viewport.
- Reserved a fixed 140px for the action sheet + safe-area padding; preview height is hard-capped and clipped to prevent overflow.

### Dependencies

```yaml
dependencies:
  aun_api_logger:
    git:
      url: https://github.com/maulik1626/aun_api_logger.git
      ref: v1.7.2
```

## 1.7.1 - 2026-03-29

### Fixed

- Shared log PDFs no longer use a single extremely tall page; content flows across standard A4 pages, removing large blank areas below the log.
- Long JSON sections in the PDF can span page breaks (`TextOverflow.span`) instead of failing layout.

### Changed

- Log PDF sharing uses `SharePlus.instance.share(ShareParams(files: ...))` with files only—no companion share-sheet text.
- iOS: `CupertinoContextMenu.builder` avoids the grey long-press decoy shadow; expand/collapse `InkWell` uses no Material splash or highlight.
- Removed redundant `material.dart` import from `color_helper.dart` (analyzer cleanliness).

### Dependencies

```yaml
dependencies:
  aun_api_logger:
    git:
      url: https://github.com/maulik1626/aun_api_logger.git
      ref: v1.7.1
```

## 1.7.0 - 2026-03-30

### Changed

- **BREAKING**: Replaced screenshot-based image sharing with PDF generation for API log sharing.
- Shared PDFs are A4 width, single continuous page (no page breaks), with full soft-wrapped content.
- PDF files are named descriptively: `{METHOD}_{endpoint}_{hh-mm-ss_AM/PM}.pdf`.
- Color-coded HTTP method badge and status code in the PDF.
- Removed `screenshot` dependency; added `pdf` dependency.

### Dependencies

```yaml
dependencies:
  aun_api_logger:
    git:
      url: https://github.com/maulik1626/aun_api_logger.git
      ref: v1.7.0
```

## 1.6.3 - 2026-03-30

### Fixed

- Resolved `No MediaQuery widget ancestor found` error by using `Text.rich` instead of `SelectableText.rich` in the screenshot widget.
- Resolved `RenderFlex overflowed by X pixels` error by limiting extreme JSON capture text to 2500 characters within images and wrapping the capture content in `SingleChildScrollView`.

## 1.6.2 - 2026-03-30

### Fixed

- Fixed a syntax error introduced during the Material ancestor fix.

## 1.6.1 - 2026-03-30

### Fixed

- Resolved `No Material widget found` exception thrown by `InkWell` during `CupertinoContextMenu` transitions.
- Prevented infinite width layout errors on shared card preview by providing strict constraints.

### Added

- Feature: Updated UI to color-code the left sidebar indicator according to HTTP request type instead of status code.

## 1.6.0 - 2026-03-29

### Added

- Feature: Implemented adaptive long-press share interactions on log cards.
  - iOS devices now use `CupertinoContextMenu` native interactions.
  - Android devices use an elegant `ModalBottomSheet`.
- Feature: Share logic extracts and strips sensitive Auth headers dynamically, offering "Share (Without Auth)" and "Share (Full Data)" actions.
- Feature: Added `screenshot` dependency to capture the exact expanded UI of logs off-screen for beautiful sharing formatting.
- Feature: Method badges now color-code logically reflecting Postman colors (`GET`=Blue, `POST`=Green, `PUT`=Orange, `DELETE`=Red).
- Feature: Response status text changes color exactly reflecting their status group (`200`s=Green, `400`s=Orange, `500`s=Red).

### Changed

- Reconstructed image share output to use a dedicated isolated renderer widget `SharedLogCardWidget` ensuring screenshot safety independent from local UI adjustments.
- Offloaded core parsing behaviors (`getStatusColor`, `getMethodColor`, `getRequestBodyType`) into `utils/` for globally synced usages across `SharedLogCardWidget` and main screens.

### Dependencies

```yaml
dependencies:
  aun_api_logger:
    git:
      url: https://github.com/maulik1626/aun_api_logger.git
      ref: v1.6.0
```

## 1.5.2 - 2026-03-25

### Added

- Feature: Added haptic feedback on JSON code block copy tap and wrap/unwrap toggle tap in log card details.

### Changed

- Standardized changelog format from this release onward to include a dedicated dependency reference block.

### Dependencies

```yaml
dependencies:
  aun_api_logger:
    git:
      url: https://github.com/maulik1626/aun_api_logger.git
      ref: v1.5.2
```

## 1.5.1 - 2026-03-25

### Added

- Feature: Added dynamic data type indicators to the "Request Body" section block header natively identifying payloads as `(FormData)`, `(JSON)`, or `(FormURLEncoded)` based on the content type header.

## 1.5.0 - 2026-03-25

### Changed

- Replaced static common-prefix stripping with smart dynamic path grouping.
- Endpoints starting with `aun_*` (e.g. `aun_pets_parent`, `aun_pets_doctor`) automatically have the app name prefix stripped.
- FilterChips now show top-level group names (e.g. `booking`, `doctor`, `utilities`, `authentication`) instead of full paths.
- Log card display paths show cleaned endpoints (e.g. `booking/upcoming_bookings/` instead of `aun_pets_parent/booking/upcoming_bookings/`).

## 1.4.1 - 2026-03-25

### Changed

- Swipe-to-reveal on log cards now shows only Share (removed Copy from swipe).
- Added a Copy icon in the top-right of each JSON code block, placed before the wrap/unwrap toggle.

## 1.4.0 - 2026-03-25

### Added

- Feature: JSON syntax highlighting in log data blocks — keys (teal), string values (amber), numbers (purple), booleans/null (red), and brackets (grey).
- Feature: Code blocks default to unwrapped mode with horizontal scrolling.
- Feature: Wrap/unwrap toggle icon in the top-right of each data block.

## 1.3.1 - 2026-03-25

### Changed

- Endpoint paths in FilterChips and log cards now strip the common prefix (e.g. `booking/upcoming_bookings/` instead of `aun_pets_parent/booking/upcoming_bookings/`).
- Replaced inline copy/share buttons on log card headers with native swipe-to-reveal actions (slide left to show Copy and Share).
- Removed per-section copy/share buttons from expanded log details for a cleaner look.

## 1.3.0 - 2026-03-25

### Added

- Feature: Added horizontally sliding `FilterChip` components below the `DayLogsScreen` search bar mapping specifically to all unique paths logged, allowing users distinct "One-Tap Path Filters".
- Enhancement: Searching within `DayLogsScreen` now natively restricts to strictly matching the `endpoint` URI rather than conflating matches with URLs.
- Enhancement: Intercepted typing inside the Search bar; Spaces are now seamlessly replaced dynamically with underscores `_`.

## 1.2.1 - 2026-03-25

### Added

- Feature: Added a global share button to `LogItemBlock` allowing users to share an entire API call immediately.
- Enhancement: Explicitly handle `dio.FormData` in the `ApiLoggerInterceptor`, parsing `fields` and attached `files` seamlessly.

### Fixed

- Fixed bug on iOS causing "yellow lines" (default missing Material UI fallbacks) by wrapping `CupertinoPageScaffold` elements in explicit `Material` widgets.

## 1.2.0 - 2026-03-25

### Added

- Implemented fully Adaptive iOS/Android UI constraints. iOS devices now render using native `CupertinoPageScaffold`, `CupertinoSearchTextField`, and `CupertinoActionSheet`.
- Shifted the search functionality and HTTP log filtering capabilities (GET/POST/status codes) into `DayLogsScreen`.

### Changed

- Refactored all log list items away from `ExpansionTile` and into sleek, clean, custom expandable white containers.
- Enforced unified pure white backgrounds for all package UI elements.
- Removed 'Delete All' actions from the UI entirely to clean up the screen header.
- Switched default Material Icons to adaptive native icons based on the host OS.

## 1.1.0 - 2026-03-25

### Added

- Added a search bar to `LogDatesScreen` to filter log dates directly.
- Added a sorting filter menu to `LogDatesScreen` to switch between 'Newest First' and 'Oldest First'.

### Changed

- Redesigned `LogDatesScreen` to use a modern, device-responsive UI including an adaptive grid layout for tablets and elegant date cards.

## 1.0.0

- Initial release of `aun_api_logger`.
- Added `ApiLoggerInterceptor` for capturing Dio requests and responses locally.
- Added `LocalStorageService` utilizing SQLite (`sqflite`) for isolated on-device persistence.
- Created built-in UI: `LogDatesScreen` and `DayLogsScreen` for fast API inspection.
- Implemented complete Copy to Clipboard and JSON Export sharing mechanisms.

