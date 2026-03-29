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

