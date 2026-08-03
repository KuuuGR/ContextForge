# ROOT_CAUSE — "Could not reach YouTube. Check your connection."

## Summary

The application's macOS app sandbox **does not include the outbound network client entitlement**, so all HTTPS connections to YouTube are blocked by the macOS sandbox with `EPERM` (Operation not permitted). Every YouTube request therefore fails with `SocketException: Connection failed (OS Error: Operation not permitted, errno = 1)`.

The previous diagnostics (Phase 018) were misleading because they executed the pipeline **outside the app sandbox** (in the `flutter test` harness), where outbound network is permitted. The real application runs **inside the sandbox**, so the same code path fails at the socket layer.

---

## Root Cause

Missing entitlement: `com.apple.security.network.client`

The macOS App Sandbox denies all outbound network access **by default**. An application must explicitly request the outbound network entitlement:

```xml
<key>com.apple.security.network.client</key>
<true/>
```

Neither of the application's entitlement files declares it:

| File | Current content | Missing |
|------|-----------------|---------|
| `macos/Runner/DebugProfile.entitlements` | `app-sandbox`, `cs.allow-jit`, `network.server` | ✅ `com.apple.security.network.client` **absent** |
| `macos/Runner/Release.entitlements` | `app-sandbox` only | ✅ `com.apple.security.network.client` **absent** |

---

## Exact Failure Chain (UI → Exception)

1. **Exact UI widget:** `lib/widgets/video_input_card.dart` — `VideoInputCard` `onSubmitted` callback.
2. **Exact controller:** `lib/viewmodels/video_card_controller.dart` — `VideoCardController.loadMetadata()` line 44.
3. **Exact service:** `lib/services/video_service.dart` — `VideoService.fetchVideoMetadata()` line 71.
4. **Exact provider:** `lib/providers/youtube_explode_provider.dart` — `YoutubeExplodeProvider.getVideoMetadata()` **line 77**:
   ```dart
   final video = await _fetchVideo(_youtube, videoId);
   ```
   This line calls `yt.videos.get(videoId)`, which opens the outbound socket.
5. **Exact exception (concrete line in dependency):** `youtube_explode_dart` → `IOClient.send` (`package:http/src/io_client.dart:227`) throws:
   > `ClientException with SocketException: Connection failed (OS Error: Operation not permitted, errno = 1), address = www.youtube.com, port = 443, uri=https://www.youtube.com/watch?v=1ZXZvTyeNzc&bpctr=9999999999&has_verified=1&hl=en`

6. **Exception mapping chain:**
   - `YoutubeExplodeProvider.getVideoMetadata` catches the generic socket error and wraps it into `YoutubeNetworkException('Failed to fetch metadata for video ...', cause: socketError)` — `lib/providers/youtube_explode_provider.dart` catch-all.
   - `VideoCardController.loadMetadata` catches `YoutubeNetworkException` and replaces it with the generic UI message **"Could not reach YouTube. Check your connection."** — `lib/viewmodels/video_card_controller.dart:60`.

---

## Runtime Trace (actual execution, captured from `flutter run -d macos`)

```
[TRACE][1] VideoInputCard.onSubmitted ("https://www.youtube.com/watch?v=1ZXZvTyeNzc")
[TRACE][2] VideoCardController.loadMetadata called
[TRACE][3] VideoService.fetchVideoMetadata entered
[TRACE][4] URL validation (YouTubeUrlParser.extractVideoId)
[TRACE][5] Parsed video ID: "1ZXZvTyeNzc"
[TRACE][6] YoutubeExplodeProvider.getVideoMetadata called
[TRACE][7] YoutubeExplodeProvider.getVideoMetadata calling yt.videos.get (network)   ← LAST STEP
[YoutubeExplodeProvider] Metadata failed: type=_ClientSocketException, message=ClientException with SocketException:
    Connection failed (OS Error: Operation not permitted, errno = 1), address = www.youtube.com, port = 443
[TRACE][BOUNDARY] Metadata fetch failed: type=YoutubeNetworkException ...
```

**LAST printed step = `[7]` (the network call).** This is the exact failure boundary.

---

## Why Previous Diagnostics Were Misleading

Phase 018 validated the pipeline with a smoke check run through `flutter test`. A `flutter test` process executes **outside the macOS App Sandbox**, so outbound HTTPS was permitted and the full pipeline (metadata → discovery → selection → download) completed successfully. This appeared to prove the pipeline was healthy; in reality it only proved the pipeline is healthy when not restricted by the sandbox.

The real application binary is launched by the sandboxed `context_forge.app`, inheriting the entitlements in `DebugProfile.entitlements` / `Release.entitlements`. Inside the sandbox, the missing `com.apple.security.network.client` entitlement denies the socket with `errno = 1` (EPERM). This is exactly what the user reproduced in both Debug and Release builds.

---

## Proposed Fix (not implemented in this phase)

Add the outbound network client entitlement to **both**:

```xml
<!-- macos/Runner/DebugProfile.entitlements -->
<key>com.apple.security.network.client</key>
<true/>

<!-- macos/Runner/Release.entitlements -->
<key>com.apple.security.network.client</key>
<true/>
```

This single change grants the app outbound HTTPS access and directly resolves the reported failure.

---

## Files Referenced

- `macos/Runner/DebugProfile.entitlements`
- `macos/Runner/Release.entitlements`
- `lib/providers/youtube_explode_provider.dart` (line 77)
- `lib/services/video_service.dart` (line 71)
- `lib/viewmodels/video_card_controller.dart` (lines 44, 60)
- `lib/widgets/video_input_card.dart` (onSubmitted)