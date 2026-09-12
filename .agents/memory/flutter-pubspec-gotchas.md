---
name: Flutter/Dart pubspec and build-cache gotchas
description: intl version pinning by flutter_localizations, freezed @JsonKey analyzer override, and a stale-build-cache compile failure signature.
---

- `flutter_localizations` pins an exact `intl` version per Flutter SDK release — pubspec must match exactly or `pub get` fails.
- `freezed` + `@JsonKey` on constructor params triggers harmless `invalid_annotation_target` warnings; suppress via `analysis_options.yaml`'s `analyzer.errors.invalid_annotation_target: ignore` plus a `build.yaml` with `json_serializable.explicit_to_json: true`.
- **Stale build cache compile failure**: if `flutter run -d web-server` fails with errors like `'Matrix4' isn't a type`, `Method not found: 'DateSymbols'`, or `Unsupported invalid type InvalidType` deep in `flutter`/`flutter_localizations`/`vector_math` package files (not the app's own code), this is a corrupted/stale `.dart_tool`/`build` cache, not a real dependency conflict.
  **Why:** happens after long-idle workspaces resume or after unrelated dependency edits; the DDC/frontend_server cache gets out of sync with the resolved package versions.
  **How to apply:** run `flutter clean && rm -rf .dart_tool build && flutter pub get`, then restart the workflow. Do not try to fix it by pinning/downgrading packages — the versions are usually fine.
- Flutter 3.32's `Switch` no longer accepts `activeThumbColor`; use `thumbColor: WidgetStatePropertyAll(...)` for the active thumb.
  **Why:** the removed parameter blocks the entire Flutter web build, even when the affected settings screen is not open.
  **How to apply:** update legacy `Switch` calls before using a build as validation for unrelated UI fixes.
- If the pub cache is empty and `flutter pub get` fails while formatting generated localizations, seed the missing lint packages (`flutter_lints` and its `lints` dependency) before rerunning `pub get`.
  **Why:** Flutter's localization generation can read the resolved lockfile paths before all cached analysis-option packages have been restored.
  **How to apply:** repair the cache or add the exact locked package versions, then run `flutter clean`, `flutter pub get`, and the normal build checks.
</content>
