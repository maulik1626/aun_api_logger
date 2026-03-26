# Production Guidelines

This document outlines the strict industry standards that govern the `aun_api_logger` package development, versioning, and continuous maintenance. Any contributions to this package, whether directly by internal developers or via GitHub Pull Requests, must adhere to these policies.

---

## 1. Versioning System (Strict SemVer)

We strictly follow [Semantic Versioning 2.0.0](https://semver.org/).
Every release must bump the version number located in `pubspec.yaml` using the format `MAJOR.MINOR.PATCH`:

- **MAJOR (`x.0.0`)**: Breaks backward compatibility (e.g., completely renaming the exported interceptor class, changing how local SQLite databases are structured requiring breaking migrations).
- **MINOR (`0.x.0`)**: Adds functionality in a backward-compatible manner (e.g., adding a new filtering bar to `DayLogsScreen`).
- **PATCH (`0.0.x`)**: Backward-compatible bug fixes (e.g., fixing a UI overflow issue, correcting a typo, repairing SQLite timezone edge cases).

## 2. Changelog Maintenance

Every version bump **MUST** be accompanied by an update in `CHANGELOG.md`. 
The format is strictly:

```markdown
## [Version] - YYYY-MM-DD
### Added
- Feature description.
### Changed
- Details about refactored/changed logic.
### Fixed
- Description of the resolved bug.
### Dependencies
```yaml
dependencies:
  aun_api_logger:
    git:
      url: https://github.com/maulik1626/aun_api_logger.git
      ref: <version-git-tag>
```
```

Every version entry **MUST** include a `### Dependencies` section with a dedicated yaml code block containing the exact git `url` and pinned `ref` (version git tag) for that version. The `ref` must be the actual pushed version git tag that contains that version's code changes. The `README.md` dependency block must always reflect the latest version's ref.

**Workflow**: After committing and pushing a version bump, immediately update `CHANGELOG.md` and `README.md` with the pushed version git tag, then commit and push the ref update.

**Never** publish a change without detailing it in the CHANGELOG.

## 3. Git Workflow & Conventional Commits

All commit messages **MUST** follow [Conventional Commits](https://www.conventionalcommits.org/en/v1.0.0/):

- `feat(ui): add new search bar to logs screen`
- `fix(interceptor): correctly catch network timeouts`
- `docs(readme): add troubleshooting section`
- `test(core): add coverage for ApiLogModel parsing`
- `chore(deps): bump dio version to 5.4.0`

### Branching Strategy
- `main`: The stable branch representing production. Ensure `pubspec.yaml` reflects the currently published package.
- `develop`: The active integration branch.
- Feature branches (`feat/name-of-feature`, `fix/name-of-bug`).

## 4. Code Quality & Formatting

Before opening a Pull Request locally:
1. Ensure the code is formatted using `dart format .`
2. No warnings or errors must be present from `flutter analyze`. Fix **all** `info` rules whenever possible to maintain a pristine codebase.
3. No print statements allowed (`print` or `debugPrint`) inside package code. Any internal logs should use Dart's `dart:developer` log if absolutely necessary, but since this is a logger itself, use standard `assert()` or quietly handle failures as is currently designed.

## 5. Automated Testing (TDD Encouraged)

Any new feature **MUST** be accompanied by tests under the `test/` directory.
- Use Unit Tests for Core logic (`api_log_model_test.dart`, Utility files).
- The package requires a **test coverage of > 80%** for critical data paths.
- Avoid introducing flaky tests. Test databases in SQLite using standard mocked data where native sqflite extensions fail on host machines without mocking.

## 6. PR Review Checklist

- [ ] Code has been linted and formatted (`flutter analyze`, `dart format .`).
- [ ] Tests completely cover the new edge-cases (`flutter test`).
- [ ] `pub.dev` score logic stays at maximum: ensuring correct `README.md`, `CHANGELOG.md`, and all public APIs have Dart Docs `///`.
- [ ] The version has been incremented according to SemVer.
