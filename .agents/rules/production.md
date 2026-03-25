# aun_api_logger Project Rules

You are an AI assistant working on the `aun_api_logger` Flutter package. You must strictly adhere to the following rules based on the `PRODUCTION_GUIDELINES.md`:

1. **Versioning**: Strictly use Semantic Versioning (SemVer 2.0.0) in `pubspec.yaml` (MAJOR.MINOR.PATCH).
2. **Changelog**: Every version bump MUST be accompanied by an update in `CHANGELOG.md` under the strict format `## [Version] - YYYY-MM-DD`.
3. **Commits**: All Git commits MUST use Conventional Commits (e.g., `feat(ui): ...`, `fix(core): ...`).
4. **Code Quality**:
   - The code must be formatted using `dart format .`.
   - `flutter analyze` MUST return 0 warnings/errors. Fix all `info` rules.
   - Absolutely NO `print` or `debugPrint` statements.
5. **Testing**: New features require tests (`>80%` coverage).

Always check `PRODUCTION_GUIDELINES.md` if you are unsure about the release process.
