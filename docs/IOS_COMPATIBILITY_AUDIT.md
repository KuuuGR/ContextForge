# ContextForge — iOS Compatibility Build Audit

**Audit type:** Build / compatibility baseline (no implementation changes)
**Date:** 2026-09-23
**Branch:** `release/macos-1.1.0` (HEAD `028ea65`, "Release 1.1.0 (build 3)")
**Scope:** Determine whether the current ContextForge source (working on macOS) can
compile for iOS as-is, and catalogue any blockers. No fixes were implemented.

---

## 1. Current result

**`BUILDS WITH ENVIRONMENT LIMITATION`**

The current source **compiles for iOS** without any application-code changes.
Both an iOS Simulator build and an unsigned iOS device build completed
successfully (exit code `0`).

The limitation is environmental only: a **signed, installable device/TestFlight
build and an on-device runtime test were not performed**. The device build was
intentionally produced with `--no-codesign`, so code signing / provisioning and
actual deployment were not validated. This is **not** a source-code
incompatibility.

> Note: The only source-level "gap" the build surfaced was that the Flutter
> toolchain auto-migrated the iOS deployment target from `13.0` to `15.0`
> (see §3). That migration is a project-configuration upgrade performed by
> Flutter itself and was reverted after the audit to preserve the baseline.

---

## 2. Build evidence

### Environment

| Item | Value |
| --- | --- |
| Flutter | `3.47.1` (stable, revision `6655482ec0`, 2026-08-19) |
| Dart | `3.13.1` |
| DevTools | `2.60.0` |
| Flutter root | `/Users/admin/Developer/flutter` |
| Xcode | `26.5` (build `17F42`) |
| Xcode developer dir | `/Applications/Xcode.app/Contents/Developer` |
| iOS SDK | `iOS 26.5` (`iphoneos26.5`) |
| iOS Simulator SDK | `Simulator - iOS 26.5` (`iphonesimulator26.5`) |
| CocoaPods / Podfile | **none** — the iOS project uses **Swift Package Manager** (`XCLocalSwiftPackageReference` → `Flutter/ephemeral/Packages/FlutterGeneratedPluginSwiftPackage`) |

### Commands executed

```sh
flutter pub get
flutter build ios --simulator --debug
flutter build ios --debug --no-codesign
flutter analyze
```

### Results

| Command | Result | Key output |
| --- | --- | --- |
| `flutter pub get` | Success (exit `0`) | `Got dependencies!` |
| `flutter build ios --simulator --debug` | **Success (exit `0`)** | `Xcode build done. 238,0s` · `✓ Built build/ios/iphonesimulator/Runner.app` |
| `flutter build ios --debug --no-codesign` | **Success (exit `0`)** | `Xcode build done. 219,7s` · `✓ Built build/ios/iphoneos/Runner.app` |
| `flutter analyze` | No errors | `3 issues found` (2 `info`, 1 `warning`) |

Analyzer issues (pre-existing, non-blocking, also present on macOS):

- `info` `prefer_function_declarations_over_variables` — `lib/widgets/destination_selector.dart:77`
- `info` `prefer_function_declarations_over_variables` — `lib/widgets/destination_selector.dart:139`
- `warning` `unused_element_parameter` (`size`) — `lib/widgets/prompt_selector.dart:208`

### Non-fatal tool output observed during the build

```
Updating minimum iOS deployment target to 15.0.
Upgrading project.pbxproj
Upgrading AppFrameworkInfo.plist
Upgrading analysis_options.yaml to exclude build and platform directories.
Warning: Building for device with codesigning disabled. You will have to manually
         codesign before deploying to device.
```

`Flutter`/Xcode performed these project migrations automatically. They are
**machine-generated configuration upgrades**, not application source changes.

---

## 3. Classification of every observed build event

| Event | Classification | Source-blocking? |
| --- | --- | --- |
| `flutter pub get` — 20 packages had newer incompatible versions | Dependency (informational only) | No |
| Deployment target auto-upgrade `13.0` → `15.0` in `ios/Runner.xcodeproj/project.pbxproj` | **Missing iOS configuration** (Flutter-required minimum), auto-migrated | No |
| `analysis_options.yaml` analyzer `exclude` auto-added | Tooling side-effect | No |
| `--no-codesign` warning | **Code signing / environment** | No |
| `flutter analyze` 3 info/warning items | Dart lint (pre-existing) | No |
| **No Dart/Flutter compilation errors** | — | — |
| **No iOS Swift/ObjC compile errors** | — | — |

There were **zero** Dart compilation failures, **zero** iOS source
incompatibilities, and **zero** plugin/dependency incompatibilities in the
attempted builds.

---

## 4. Compatibility findings

Only areas relevant to the current implementation are listed. "iOS status"
reflects what was verified from code and/or the build.

| Area | Current implementation | iOS status | Evidence | Required future work |
| --- | --- | --- | --- | --- |
| UI / layout | Single `HomePage` with a frozen desktop layout plus a compact reflow branch (`lib/presentation/responsive.dart`, 600 px breakpoint) added in commit `b02324c` ("iOS-01 — Responsive iPhone layout for TestFlight"). | **Compiles.** Compact layout already implemented. | `isCompactWidth` / `isCompact` used in `home_page.dart`, `transcript_status_indicator.dart`; no desktop-only widgets (no `MenuBar`, `MenuAnchor`, `MouseRegion`, `SystemMouseCursors` in `lib/`). | Runtime visual QA on real devices/orientations. |
| Window / view-controller | Desktop windowing lives in `macos/Runner/MainFlutterWindow.swift` (`NSWindow`, `FlutterViewController`). iOS uses standard `ios/Runner/AppDelegate.swift` + `SceneDelegate.swift` (`FlutterSceneDelegate`). | **Compiles.** Native UI is fully per-platform. | Device build succeeded compiling `AppDelegate.swift`/`SceneDelegate.swift`. | None for compile; iOS scene lifecycle already wired. |
| Keyboard shortcuts / command bar | `Shortcuts`/`Actions` with `SingleActivator` (`⌘↩`, `⌘R`, `⌘⌫`, `⌘⇧S`, `⌘V`, `Esc`) in `home_page.dart`; `CommandBar` widget is pure Flutter geometry. | **Compiles.** Shortcuts are inert without a hardware keyboard but do not block the build. | `home_page.dart:1005-1070`; `lib/widgets/command_bar.dart` (Material-only). | Decide iOS interaction model; no compile work. |
| Clipboard | `Clipboard.getData/setData` (Flutter services) for Smart Paste, field paste and copy output. | **Compiles.** Flutter Clipboard is cross-platform. | `home_page.dart:558, 784`; `didChangeAppLifecycleState` refresh. | iOS pasteboard privacy UX (optional). |
| Transcript handling | Pure-Dart via `youtube_explode_dart` behind `YoutubeProvider`; discovery/selection/download/clean in `transcript_service.dart` + providers. No native code, no `dart:io` file downloads. | **Compiles.** | Build succeeded with `youtube_explode_dart 3.1.0`; `lib/services/transcript_service.dart`, `lib/providers/youtube_explode_provider.dart`. | None for compile. |
| YouTube / networking | `http`-based scraping through `youtube_explode_provider.dart`. | **Compiles.** Uses standard sockets/HTTP. | iOS device `Runner.app` built; no network entitlement is required on iOS (unlike macOS App Sandbox). | Verify ATS/runtime behavior on device (unknown, not tested). |
| Persistence — prompts, history, intro, destinations, review state | `dart:io` JSON files. Default directory resolves to `${HOME}/Library/Application Support/context_forge` **only on macOS**; on any other platform it falls back to `Directory.current.path`. | **Compiles.** | `json_prompt_storage.dart`, `json_video_history_storage.dart`, `first_launch_intro_store.dart`, `destination_store.dart`, `review_store.dart` — each uses `if (Platform.isMacOS) { ... } return Directory.current.path;`. | On iOS `Directory.current` is not a durable, guaranteed-writable data location and `path_provider` is **not** a dependency. Persistence is likely non-durable on iOS. **Runtime/behavioral work, not a compile blocker.** |
| File access — import prompts | `openFile` via `file_selector`. | **Compiles; runtime-supported.** `FileSelectorIOS` overrides `openFile`/`openFiles`. | Build registered `file_selector_ios 0.5.3+5` (`GeneratedPluginRegistrant.m`); `FileSelectorIOS` source overrides `openFile`/`openFiles`. | None for import. |
| File access — export (Markdown, prompts) | `getSaveLocation` via `file_selector`, then `File(path).writeAsString`. | **Compiles but NOT implemented on iOS at runtime.** `file_selector_ios` does **not** override `getSaveLocation`/`getSavePath`/`getDirectoryPath`, so the platform-interface base method throws `UnimplementedError` at call time. | `lib/services/markdown_export_service.dart:38`; `lib/services/prompt_transfer_service.dart:82`; `file_selector_ios-0.5.3+5/lib/file_selector_ios.dart` (only `openFile`/`openFiles`); base `getSaveLocation` in `file_selector_platform_interface`. | Replace iOS export with a share sheet / `UIDocumentPicker`-based save or a documents-dir write. **Runtime functional gap, not a compile failure** (both callers wrap in try/catch and show an error snackbar). |
| StoreKit / App Review | Dart `MethodChannel('contextforge/review')` (`app_review_service.dart`). Native handler exists for **both** platforms: macOS `MainFlutterWindow.swift` (`AppStore.requestReview(in:)`, macOS 13+) and iOS `AppDelegate.swift` (`AppStore.requestReview(in:)` guarded by `#available(iOS 16.0, *)`). | **Compiles; iOS handler present.** | `ios/Runner/AppDelegate.swift:21-51`; `lib/services/app_review_service.dart`. | On iOS < 16 the request is a graceful no-op. No purchase/IAP code exists. Verify prompt behavior on device (unknown). |
| Plugins / dependencies | `url_launcher ^6.3.0`, `youtube_explode_dart ^3.1.0`, `file_selector ^1.1.0`, `cupertino_icons`, `flutter_localizations`. | **Compiles.** iOS federated plugins: `url_launcher_ios 6.4.1`, `file_selector_ios 0.5.3+5`. | `.flutter-plugins-dependencies` (ios section); `ios/Runner/GeneratedPluginRegistrant.m`. | `url_launcher` uses `LaunchMode.externalApplication` (fine on iOS). |
| Permissions | No iOS entitlements file; no camera/mic/photos use. `Info.plist` has no special usage descriptions. | **Compiles.** | `ios/Runner/Info.plist`; no `ios/Runner/*.entitlements`. | None unless a future feature needs a usage string. |
| iOS project config | Bundle id `com.etaosin.contextForge`, team `8TC5J5KMXE`, Swift 5.0, `INFOPLIST`/storyboards intact, SPM-based. | **Builds** after Flutter auto-migrates `IPHONEOS_DEPLOYMENT_TARGET` to `15.0`. | `ios/Runner.xcodeproj/project.pbxproj`; build log `Updating minimum iOS deployment target to 15.0`. | Commit the deployment-target bump (or otherwise raise it) so a clean build does not rely on an auto-migration. |

---

## 5. Architecture blockers — summary

Checked against the areas called out in the audit request:

- **Transcript downloading** — pure Dart (`youtube_explode_dart`), no filesystem writes, no native code. **No compile blocker.**
- **YouTube integration** — pure Dart HTTP. **No compile blocker.**
- **Clipboard handling** — Flutter `Clipboard` API. **No compile blocker.**
- **File system / storage** — `dart:io` JSON stores. Compiles. macOS-specific path resolution with a non-macOS fallback; durability on iOS is questionable (see §4). **No compile blocker.**
- **Prompt persistence** — same as above.
- **Import / export** — import uses `openFile` (iOS-supported); export uses `getSaveLocation` (**not implemented on iOS**). **Runtime gap, not a compile blocker.**
- **Settings** — no dedicated Settings screen exists; the app has About/Shortcuts/Help dialogs in a footer. Nothing to port.
- **App Review / StoreKit review request** — native handler already present on iOS. **No compile blocker.**
- **Window / view-controller code** — macOS-only by design and confined to `macos/Runner/`; iOS uses `AppDelegate`/`SceneDelegate`. **No compile blocker.**
- **Keyboard shortcuts / command bar** — Flutter-level only. **No compile blocker.**
- **Desktop-specific UI assumptions** — a compact layout branch already exists; no desktop-only Flutter UI APIs found in `lib/`. **No compile blocker.**
- **Path handling** — `Platform.pathSeparator` + `Platform.isMacOS` guards. Compiles.
- **Permissions** — none required for current features on iOS.
- **`dart:io` usage** — only in the five JSON/export services listed above; all compile for iOS.
- **macOS-specific Flutter plugins** — none in `pubspec.yaml`; the only plugins are federated and have iOS implementations.

---

## 6. Facts vs. assumptions

**Verified facts (from the actual build):**

- `flutter build ios --simulator --debug` → `✓ Built build/ios/iphonesimulator/Runner.app` (exit `0`).
- `flutter build ios --debug --no-codesign` → `✓ Built build/ios/iphoneos/Runner.app` (exit `0`).
- The Flutter tool auto-upgraded the iOS deployment target `13.0` → `15.0`.
- `flutter analyze` reported no errors (2 info + 1 warning).
- No Swift/Dart compile errors were emitted.

**Verified facts (from reading the source):**

- Native App Review channel is implemented for both macOS and iOS.
- `file_selector_ios` implements `openFile`/`openFiles` but **not** `getSaveLocation`.
- macOS path resolution in the storage services falls back to `Directory.current.path` on non-macOS platforms; `path_provider` is not a dependency.
- The app already contains a compact (phone) layout branch (`responsive.dart`).
- No macOS-only APIs (`AppKit`, `NSWindow`, `NSApplication`, `MenuBar`, etc.) are referenced in `lib/`.

**Environment limitation (not source-related):**

- Code signing / provisioning were disabled for the device build; no physical
  device or TestFlight upload was validated. A complete signed device run
  remains unverified.

**Likely future iOS work (identified from code, requiring implementation tasks):**

- Provide a durable iOS storage location (e.g. via `path_provider`) for the JSON
  stores.
- Replace `getSaveLocation`-based export with an iOS-appropriate save/share flow.
- Runtime QA of clipboard, App Review and networking on real devices.

**Unknowns (require a later implementation/testing task):**

- Actual runtime behavior of the storage fallback on iOS (whether
  `Directory.current` is writable/durable in the app sandbox).
- Whether Apple's review prompt behaves as expected on iOS 16+ at runtime.
- Whether `youtube_explode_dart` scraping is affected by iOS network conditions
  / ATS in practice.

---

## 7. Scope compliance

- No application source files were modified.
- No macOS behavior was changed (`git diff` for `macos/`, `lib/`, `test/` is empty).
- No iOS implementation was added or altered to hide/bypass anything.
- No dependencies were upgraded.
- The only repository addition is this document.
- The Flutter tool's automatic edits to `analysis_options.yaml` and
  `ios/Runner.xcodeproj/project.pbxproj` made during the build were reverted
  after the audit so the repository remains at the audited baseline.

### Files changed by this audit

- `docs/IOS_COMPATIBILITY_AUDIT.md` (new) — the only change.

### Commands used for validation

```sh
git status                            # clean apart from pre-existing untracked files
git diff -- macos/ lib/ test/ ios/    # empty
```
