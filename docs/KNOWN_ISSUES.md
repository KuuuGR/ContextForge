# Known Issues

## CF-001 — "Could not reach YouTube. Check your connection."

**Status: Resolved**

- **Reported:** Phase 018–020 — both Debug and Release builds failed to retrieve metadata for valid YouTube URLs.
- **Symptoms:** No video title shown; UI displays "Could not reach YouTube. Check your connection."
- **Root cause:** The macOS App Sandbox blocked all outbound HTTPS connections because the `com.apple.security.network.client` entitlement was missing from both `macos/Runner/DebugProfile.entitlements` and `macos/Runner/Release.entitlements`. Runtime trace captured: `SocketException: Connection failed (OS Error: Operation not permitted, errno = 1), address = www.youtube.com, port = 443`.
- **Fix (Phase 022B):** Added `com.apple.security.network.client` to both entitlement files. Existing entitlements preserved.
- **Verification:** `flutter build macos` succeeds; `codesign -d --entitlements` confirms `com.apple.security.network.client` is embedded in the built app.
- **Resolved in:** Version 0.1.10, Phase 022B.

---

_This file will be updated as issues are discovered during development._