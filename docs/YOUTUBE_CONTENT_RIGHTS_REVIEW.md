# YouTube Content Rights Review

This document records the factual findings of how ContextForge accesses and retrieves YouTube data, for the purpose of answering Apple's App Store Connect "Content Rights" question. It contains technical facts only; it contains no legal conclusions and no ownership/rights claims.

---

## 1. What ContextForge Retrieves

ContextForge retrieves the following data from YouTube for a video identified by a user-supplied YouTube URL:

- **Video title** — mapped into the domain `Video.title` and used as the transcript block name in generated output.
- **Channel name** — mapped into the domain `Video.channelName`.
- **Publication date** — mapped into the domain `Video.publishedAt` (from the video's upload/publish date).
- **Video duration** — mapped into the provider DTO `YoutubeVideoMetadata.duration` (not part of the core App Store question, but retrieved).
- **Canonical video URL** — normalized to `https://www.youtube.com/watch?v=VIDEO_ID`.
- **Video description** — retrieved into the provider DTO `YoutubeVideoMetadata.description` (optional/nullable).
- **Transcript (captions)** — the full caption text of a selected caption track, delivered as timestamped segments. The transcript text is joined and, in the app's output builder, embedded verbatim into the final generated output block.

The generated output combines the user's prompt, the "Inspiration" entries (`YYYY-MM-DD -> URL` per video), and the full transcript text, then copies that block to the clipboard for the user to paste into an external LLM. What the user subsequently does with the retrieved content is outside the scope of this review.

## 2. How the Data Is Retrieved

The retrieval mechanism is a **third-party Dart library** (`youtube_explode_dart`) that **scrapes YouTube's public watch page and calls YouTube's internal (`youtubei`) endpoints**. It does **not** use the official YouTube Data API v3 with an application-owned API key.

The technical flow:

1. **URL parsing (local, no network)** — `YouTubeUrlParser` (`lib/services/youtube_url_parser.dart`) validates the user-entered URL (supports `www.youtube.com`, `youtube.com`, `m.youtube.com`, and `youtu.be`), extracts the 11-character canonical video ID, and normalizes the URL to `https://www.youtube.com/watch?v=VIDEO_ID`.
2. **Metadata retrieval (network)** — `VideoService.fetchVideoMetadata` (`lib/services/video_service.dart`) calls `YoutubeExplodeProvider.getVideoMetadata` (`lib/providers/youtube_explode_provider.dart`), which calls `youtube_explode_dart`'s `yt.videos.get(videoId)`. Inside the library this GETs the YouTube watch page:
   - `https://www.youtube.com/watch?v=VIDEO_ID&bpctr=9999999999&has_verified=1&hl=en`
   - The title, author (channel), upload/publish date, duration, and description are parsed out of the watch page HTML/`ytInitialPlayerResponse` data.
3. **Transcript track discovery (network)** — `TranscriptService.getAvailableTranscripts` (`lib/services/transcript_service.dart`) → `YoutubeExplodeProvider.getAvailableTranscripts` → `yt.videos.closedCaptions.getManifest(videoId)`. Inside the library this POSTs to the internal Android player endpoint:
   - `https://www.youtube.com/youtubei/v1/player?prettyPrint=false`
   - using hardcoded public client identifiers/key embedded in the library.
4. **Transcript download (network)** — `TranscriptService.downloadTranscript` → `YoutubeExplodeProvider.downloadTranscript` → `yt.videos.closedCaptions.get(trackInfo)`. Inside the library this GETs the caption track `baseUrl` (returned by the above endpoint, typically on `youtube.com/api/timedtext`) with `fmt=srv3`, parses the returned XML into caption segments, and maps them into the app's `YoutubeTranscript` DTO.

All networking is isolated inside `YoutubeExplodeProvider` (`lib/providers/youtube_explode_provider.dart`), which wraps the library and maps its types into provider-local DTOs.

## 3. Relevant Dependencies

From `pubspec.yaml` (direct) and `pubspec.lock` (versions):

| Package | Version | Type | Role |
|---------|---------|------|------|
| `youtube_explode_dart` | `^3.1.0` (locked `3.1.0`) | direct main | Scraping-based YouTube client: metadata + captions |
| `http` | `1.6.0` | transitive | HTTP client used by `youtube_explode_dart`'s `YoutubeHttpClient` |
| `html` | `0.15.6` | transitive | HTML parsing of the watch page (used by the library) |
| `xml` | `6.6.1` | transitive | XML parsing of caption tracks (used by the library) |
| `http_parser` | `4.1.2` | transitive | HTTP utilities (used by the library) |

Other transitive packages pulled in by `youtube_explode_dart` (per `docs/DEPENDENCIES.md`): `archive`, `crypto`, `csslib`, `ffi`, `freezed_annotation`, `json_annotation`, `logging`, `petitparser`, `posix`, `simple_sparse_list`, `typed_data`, `unicode`, `web`.

Note: ContextForge does **not** declare or use the official Google/YouTube API client (`googleapis`, `youtube`), and does **not** own a YouTube Data API v3 key used for this feature.

## 4. External Services / Domains

The following external domains/endpoints are contacted by the application's YouTube functionality (via the `youtube_explode_dart` library):

- `https://www.youtube.com/watch?v=...` — watch page scraping for metadata (title, channel, dates, description, duration).
- `https://www.youtube.com/youtubei/v1/player?prettyPrint=false` — internal player/caption manifest endpoint (POST with library-embedded public client identifiers).
- Caption track `baseUrl` returned by the above (domain `youtube.com`, path typically `/api/timedtext`, requested with `fmt=srv3`) — actual transcript text download.

These calls are initiated by the library's HTTP client at app runtime when the user enters a YouTube URL and selects/generates a transcript. (Hardcoded public keys are embedded in the library source, e.g. `AIzaSyB-63vPrdThhKuerbB2N_l7Kwwcxj6yUAc` and `AIzaSyAO_FJ2SlqU8Q4STEHLGCilw_Y9_11qcW8`, pointing at YouTube's internal services — not an app-owned API key for the official YouTube Data API.)

## 5. Evidence From the Code

For every important conclusion, the supporting file/class/function:

| Conclusion | File | Class / Function | Description |
|-----------|------|------------------|-------------|
| URL parsing/normalization is local | `lib/services/youtube_url_parser.dart` | `YouTubeUrlParser.extractVideoId` / `normalizeUrl` | Validates supported YouTube URL formats and extracts the 11-char video ID; normalizes to `https://www.youtube.com/watch?v=...`. |
| Video metadata title/user upload/publish date | `lib/providers/youtube_explode_provider.dart` | `YoutubeExplodeProvider._mapVideo` | Maps `video.title`, `video.author`, `video.uploadDate ?? video.publishDate`, `video.duration`, `video.url`, `video.description` into `YoutubeVideoMetadata`. |
| Metadata network call | `lib/providers/youtube_explode_provider.dart` | `YoutubeExplodeProvider._defaultFetch` | `yt.videos.get(videoId)` → library `VideoClient.get` → `WatchPage.get` (scrapes watch page). |
| Transcript discovery | `lib/providers/youtube_explode_provider.dart` | `_defaultFetchManifest` | `yt.videos.closedCaptions.getManifest(videoId)` → library `ClosedCaptionClient.getManifest` (POSTs to `youtubei/v1/player`). |
| Transcript download | `lib/providers/youtube_explode_provider.dart` | `_defaultFetchCaptionTrack` | `yt.videos.closedCaptions.get(trackInfo)` → library GETs caption track `baseUrl` with `fmt=srv3` and parses XML. |
| Orchestration | `lib/services/video_service.dart` | `VideoService.fetchVideoMetadata` | Validates URL, calls provider, maps DTO to domain `Video`. |
| Orchestration | `lib/services/transcript_service.dart` | `TranscriptService.getAvailableTranscripts` / `downloadTranscript` | Discovers and downloads transcripts through the provider abstraction. |
| Provider abstraction (interface only) | `lib/providers/youtube_provider.dart` | `YoutubeProvider` | Abstract contract: metadata, transcript list, transcript download. |
| App wiring uses the scrape provider | `lib/app/app.dart` | `ContextForgeApp.build` | Instantiates `VideoService(... provider: YoutubeExplodeProvider())`. |
| Retrieved fields persisted in domain model | `lib/models/video.dart` | `Video` | Stores `title`, `channelName`, `publishedAt` (plus URL, transcript flags). |
| Transcript text embedded in final output | `lib/services/output_builder_service.dart` | `OutputBuilderService.build` / `_titleForVideo` | Uses retrieved title as transcript block name; writes full transcript text verbatim into the copied output block. |
| Library scrapes watch page for metadata | `youtube_explode_dart-3.1.0` (pub cache) | `src/videos/video_client.dart` `_getVideoFromWatchPage`; `src/reverse_engineering/pages/watch_page.dart` `WatchPage.get` | GETs `https://www.youtube.com/watch?v=...`, parses player response for title/author/date/description. |
| Library uses internal youtubei endpoint for captions | `youtube_explode_dart-3.1.0` (pub cache) | `src/videos/closed_captions/closed_caption_client.dart` `getManifest`/`_getCaptionTracksFromApi`; `src/videos/youtube_api_client.dart` | POSTs to `https://www.youtube.com/youtubei/v1/player?prettyPrint=false`, reads `baseUrl`/`languageCode`; track download uses the `baseUrl` with `fmt=srv3`. |
| Library's HTTP stack | `youtube_explode_dart-3.1.0` (pub cache) | `src/reverse_engineering/youtube_http_client.dart` | Wraps `package:http` client; default browser-like user-agent headers. |

## 6. Existing Project Documentation

- `docs/YOUTUBE_PROVIDER_REVIEW.md` — explicitly states the library "is a scraping-based client (no official YouTube API key)" and that "The library is a scraping client that reads metadata and transcripts from YouTube pages."
- `docs/DEPENDENCIES.md` — explicitly states `youtube_explode_dart` "Retrieves YouTube video metadata (title, channel, upload date, duration, description) **without requiring an API key**" and "scrapes public watch-page metadata."
- `README.md` — describes the app as a "Local macOS tool for gathering inspiration sources, YouTube transcripts and generating structured AI-ready research packages."
- `lib/providers/youtube_provider.dart` — comments note providers "encapsulate external integrations" and mention "(e.g., based on scraping or a future API client)."
- `LICENSE` — project is GNU GPL v3 (this is ContextForge's own source license; it does not address YouTube content rights).
- No third-party notices, Terms of Service statements, YouTube-branding guidelines, or content-licensing/attribution notices were found in the project.

## 7. Unknowns / Things That Cannot Be Determined

- The project contains **no explicit license, agreement, or authorization from YouTube/Google** for scraping its pages/internal endpoints or reusing video titles, channel names, dates, or transcripts.
- Whether the use of `youtube_explode_dart`'s scraping approach complies with YouTube's Terms of Service / Google's policies **cannot be determined from the project code alone**.
- Whether the user's act of supplying a URL grants ContextForge any rights to the content **cannot be determined from the code/project**. The project stores no evidence of such a grant or provenance.
- The exact caption-track `baseUrl` domain seen at runtime for a specific video is determined by YouTube's responses; the code only shows the mechanism (`youtubei/v1/player` returning `baseUrl`, typically `youtube.com/api/timedtext`).
- Whether YouTube currently blocks, rate-limits, or prevents such scraping **cannot be established from the code** (the library's error handling references possible 429/rate-limit responses, but actual behavior varies and is not part of the project).
- No analysis was performed on whether any retrieved content is Creative Commons or otherwise licensed; the app makes no such determination.
- The review covered the code and bundled docs in `/Users/admin/Developer/ContextForge`; any external legal agreements, developer accounts, or policies held by the app owner outside the repository are out of scope.

## 8. App Store Connect Content Rights — Technical Facts

The following are the technical facts relevant to deciding how to answer Apple's "Does your app contain, show, or access third-party content?" question. **No Yes/No recommendation is made here; this section lists facts only.**

- ContextForge **does access third-party content**: it retrieves video metadata (title, channel name, publication date, and other fields) and the full video transcript (caption text) for YouTube videos identified by user-supplied URLs.
- The retrieval mechanism is a **third-party library** (`youtube_explode_dart`, v3.1.0) that **scrapes YouTube's public watch page** and calls YouTube's **internal `youtubei` endpoints**, with hardcoded public client identifiers for metadata and transcripts.
- ContextForge does **not** demonstrate use of the official YouTube Data API v3 with its own API key; no API key is configured in the app for this feature.
- The app's own source code and documentation describe this as scraping — e.g., "scraping-based client (no official YouTube API key)" (`docs/YOUTUBE_PROVIDER_REVIEW.md`) and "scrapes public watch-page metadata" (`docs/DEPENDENCIES.md`).
- The app's final generated output (copied to the clipboard for the user) includes the retrieved channel/title context and the **full transcript text verbatim** (`lib/services/output_builder_service.dart`).
- The project contains **no explicit documentation, license, or authorization** from YouTube/Google for retrieving or reusing this content, and contains no statement that ContextForge owns the YouTube content or has rights to it.
- External domains contacted for this feature: `www.youtube.com` (watch page scraping; internal `youtubei/v1/player`; caption track download) and, via the library, potential caption track URLs on `youtube.com` (`/api/timedtext`).

---

## Verification Status

- Code inspected: YES
- YouTube retrieval mechanism identified: YES (third-party scraping library `youtube_explode_dart`; watch-page scraping + `youtubei/v1/player` + caption-track download; no app-owned YouTube Data API key)
- All relevant dependencies identified: YES (from `pubspec.yaml` / `pubspec.lock` and `docs/DEPENDENCIES.md`)
- External endpoints identified: YES (`www.youtube.com` watch page; `www.youtube.com/youtubei/v1/player`; caption-track `baseUrl` on `youtube.com/api/timedtext`)
- Remaining uncertainties: (1) Whether scraping behavior complies with YouTube/Google Terms of Service or policies — cannot be determined from the project; (2) whether the user-supplied URL grants any content rights — cannot be determined from the project; (3) exact per-video caption-track URLs at runtime are determined by YouTube responses, not hardcoded in the app; (4) whether YouTube currently blocks/rate-limits such access — cannot be established from the code; (5) no documented authorization/license from YouTube for this content reuse exists in the project.