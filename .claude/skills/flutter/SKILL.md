---
name: flutter
description: Flutter/Dart workflow using the Dart MCP tools and real checks. USE FOR: Flutter/Dart analyzer errors, widget, layout or runtime errors, adding packages, Flutter tests. DO NOT USE FOR: non-Dart code, generic debugging (use debug), or choosing a state-management library.
---

<!-- why: #1 #13 guessing Flutter APIs, layout fixes and package choices from memory produces code that does not analyze, overflows, or pulls in dead dependencies; the connected Dart MCP server and the analyzer give ground truth. Model-invocable on purpose (unlike the /base:* flow skills); pairs with the tdd and debug skills. -->

# Flutter / Dart

1. **Ask the tools, do not guess.** Use the Dart MCP server: `analyze_files` for errors, `get_runtime_errors` for crashes of the running app, `hot_reload` (or `hot_restart` after state/`main` changes) after edits, `widget_inspector` for the live widget tree, `pub` to add or upgrade packages, `pub_dev_search` to find packages, `read_package_uris` / `rip_grep_packages` to read a dependency's real API. These need the app launched through the Dart MCP server (DTD connected); otherwise fall back to `flutter run` plus CLI `dart analyze`. If `analyze_files` returns nothing, register the project folder with `roots` and retry; if it is still empty, run CLI `dart analyze <dir>` and report both results (a lab run saw the MCP return empty while the CLI found an error and a warning). Format with the CLI, only the files you changed: `dart format <files>`.
2. **Follow the project.** Keep its existing state management, routing and folder layout. Do not introduce or argue for a different one.
3. **Layout errors** (overflow, unbounded height/width, "RenderBox was not laid out"): inspect the tree with `widget_inspector` and find which parent gives which constraints. Fix with `Expanded`/`Flexible`, a bounded `SizedBox`/`ConstrainedBox`, or a scrollable (`ListView`, `SingleChildScrollView`). Never patch with magic pixel sizes.
4. **Tests.** Widget tests: `WidgetTester`, finders (`find.text`, `find.byKey`, `find.byType`), `pump` for one frame, `pumpAndSettle` for animations. Integration tests for full user flows on a device or emulator. Golden tests only for visually stable UI; they break on fonts and platform changes.
5. **Config and secrets.** Pass environment values with `--dart-define-from-file=<file>` and read them via `String.fromEnvironment`. Gitignore the define file. Define values are compiled into the app and extractable, so they are not secret storage: real secrets stay on a backend. Never put keys or tokens in source.
6. **Widget hygiene.** Use `const` constructors and widgets wherever possible. Dispose every controller, focus node, stream subscription and animation controller in `dispose()`.
7. **Adding a dependency.** First check its pub.dev page: license, recent maintenance, support for the project's Dart/Flutter SDK constraint, popularity. Add it through `pub` (not by hand-typing a guessed version) so the version is resolved (apps record it in `pubspec.lock`).
8. **Before saying "done":** run `dart analyze` (or `flutter analyze`) and the tests (`flutter test` for Flutter packages, `dart test` for pure Dart); report the real output. Never silence the analyzer or skip, weaken or delete a test to get green.
