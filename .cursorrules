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
6. **Dependency Version Pinning & Docs Sync**:
   - App integrations of `aun_api_logger` MUST use a pinned immutable reference (published version, git tag, or commit SHA), never a moving branch reference like `ref: main`.
   - Documentation MUST always include the `pubspec.yaml` dependency code block for `aun_api_logger`.
   - Whenever the dependency reference/version is changed, that README/documentation code block MUST be updated in the same change.
7. **Changelog Dependency Block (Mandatory for Every Version Bump)**:
   - Every `CHANGELOG.md` version entry MUST include a `### Dependencies` section with a dedicated yaml code block showing the exact `aun_api_logger` git `url` and pinned `ref` (commit SHA) for that version.
   - The `ref` in the dependency block MUST be the actual pushed commit SHA that contains that version's code changes.
   - The `README.md` dependency block MUST always show the latest version's commit SHA.
   - **Workflow**: After committing and pushing a version bump, immediately update `CHANGELOG.md` and `README.md` with the pushed commit SHA, then commit and push the ref update.

Always check `PRODUCTION_GUIDELINES.md` if you are unsure about the release process.
