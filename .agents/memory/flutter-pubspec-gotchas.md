---
name: Flutter/Dart pubspec gotchas
description: Two recurring pubspec/analyzer issues when scaffolding a fresh Flutter app with localization and freezed models.
---

1. **intl version pin.** `flutter_localizations` (from the Flutter SDK) pins an exact `intl` version (e.g. `0.20.2` on Flutter 3.32). If `pubspec.yaml` declares an older `intl` constraint (e.g. `^0.19.0`), `flutter pub get` fails version solving. Fix: match whatever version `flutter pub get`'s error message names, don't guess.

2. **freezed + `@JsonKey` on constructor params.** Using `@JsonKey(name: '...')` directly on a `@freezed` class's constructor parameters (the common pattern for snake_case DB column mapping) triggers `invalid_annotation_target` warnings from the analyzer — this is a known/expected freezed limitation, not a real bug. Suppress it project-wide via `analysis_options.yaml`:
   ```yaml
   analyzer:
     errors:
       invalid_annotation_target: ignore
   ```
   Also add a `build.yaml` with `json_serializable: options: explicit_to_json: true` if models nest other `@freezed`/`@JsonSerializable` types.

**Why:** both cost a full debug cycle if hit blind; keeping this here means matching pubspec/analyzer setup on the next Flutter scaffold is instant instead of trial-and-error.
