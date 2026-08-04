---
name: Flutter has no artifact type
description: Why a Flutter project in this workspace can't be previewed like other artifacts, and how the user actually views it.
---

The `artifacts` skill's supported `artifactType` list does not include Flutter/Dart (only `expo`, `design-system`, `openscad`, `react-vite`, `slides`, `video-js`). There is no way to register a Flutter project as an artifact.

**Consequence:** a Flutter app must be run via a plain `configureWorkflow` call (e.g. `flutter run -d web-server --web-port=<port> --web-hostname=0.0.0.0`, `outputType: "webview"`) instead of `createArtifact`. Per Replit's own docs, only registered artifacts can be shared/previewed via the standard Preview pane/URL — a non-artifact workflow will not show up in the artifact preview dropdown or work with the `Screenshot` tool's `appPreview` source (it errors "Artifact not found").

**How to apply:** when a user wants a Flutter mobile app built in this workspace, set expectations up front that it will run as a background dev-server workflow they view through the Workflows pane's own webview tab, not the normal artifact preview switcher. Verify the server is actually serving with `curl -s -o /dev/null -w "%{http_code}" http://localhost:<port>/` from the shell rather than relying on the Screenshot tool.
