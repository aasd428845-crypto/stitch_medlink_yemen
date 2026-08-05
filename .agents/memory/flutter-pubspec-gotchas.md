---
name: Flutter/Dart pubspec and build-cache gotchas
description: intl version pinning by flutter_localizations, freezed @JsonKey analyzer override, and a stale-build-cache compile failure signature.
---

- `flutter_localizations` pins an exact `intl` version per Flutter SDK release — pubspec must match exactly or `pub get` fails.
- `freezed` + `@JsonKey` on constructor params triggers harmless `invalid_annotation_target` warnings; suppress via `analysis_options.yaml`'s `analyzer.errors.invalid_annotation_target: ignore` plus a `build.yaml` with `json_serializable.explicit_to_json: true`.
- **Stale build cache compile failure**: if `flutter run -d web-server` fails with errors like `'Matrix4' isn't a type`, `Method not found: 'DateSymbols'`, or `Unsupported invalid type InvalidType` deep in `flutter`/`flutter_localizations`/`vector_math` package files (not the app's own code), this is a corrupted/stale `.dart_tool`/`build` cache, not a real dependency conflict.
  **Why:** happens after long-idle workspaces resume or after unrelated dependency edits; the DDC/frontend_server cache gets out of sync with the resolved package versions.
  **How to apply:** run `flutter clean && rm -rf .dart_tool build && flutter pub get`, then restart the workflow. Do not try to fix it by pinning/downgrading packages — the versions are usually fine.
</content>
