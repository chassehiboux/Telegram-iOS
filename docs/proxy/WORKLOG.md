# Worklog

## 2026-08-12 — Bootstrap and Phase 1 start

- Read root `CLAUDE.md`, `README.md`, `versions.json`, and `.xcodebuildmcp/config.yaml` before functional/build edits.
- Confirmed a clean initial worktree on `master`, fork remote `origin`, and official `upstream`.
- Created feature branch `codex/http-https-proxy`.
- Added project instructions, project-scoped Codex agent configuration, repository skill, documentation skeleton, task backlog, and ignored `artifacts/` output directory.
- Initialized recursive pinned submodules. Two fork-relative URLs resolved to nonexistent `chassehiboux/tgcalls` and `chassehiboux/rlottie`; changed only those entries to accessible canonical `TelegramMessenger` repositories and successfully checked out the exact pinned commits.
- Verified installed `git`, `gh`, `rg`, and Python. GitHub CLI is authenticated as `chassehiboux` with repository/workflow scopes.
- Used three read-only investigations for proxy flow, build/signing flow, and guidance/test discovery.
- Confirmed root `CLAUDE.md` is the only applicable guidance for MtProtoKit/build work; `.xcodebuildmcp/config.yaml` covers simulator/debugging/UI automation only.
- Confirmed no MtProtoKit proxy tests exist. Recorded the focused Bazel XCTest pattern and `Make.py test` limitations; the broken aggregate suite will not be used.
- Mapped settings/persistence/MtProtoKit transport and selected `MTTcpConnection` as the source-backed candidate HTTP insertion point. Recorded open decisions and an existing credential-logging defect.
- Confirmed the public fake-signed `release_arm64` build path and its coupling to upstream team/bundle identifiers. The fake profiles expire 2026-10-30.
- Added a manual `macos-26` Apple-Silicon workflow that injects Telegram API credentials from Actions secrets, uses Xcode 26.2, builds device arm64, validates IPA structure/Mach-O platform, hashes, and uploads `TelegramProxy.ipa`.
- Confirmed the GitHub repository is a public fork. Official GitHub documentation states standard hosted runners are free for public repositories; `macos-26` is a standard Apple Silicon label, so no billable larger runner is needed.
- Actions secret-name inspection found no `TELEGRAM_API_ID` or `TELEGRAM_API_HASH`. The workflow is not dispatched because valid user-owned Telegram API credentials are required.
- No build, device IPA, proxy functionality, or SideStore installation has been claimed.

## 2026-08-12 — Public-channel UI task queued before final IPA

- Added a post-Phase-9 task requested by the user: remove the bottom `Mute` / `Unmute` action from public channels and expose the same state-aware action under `Public Info -> More`.
- Corrected sequencing after user clarification: this UI change is Phase 9 and must be completed before Phase 10 final regression and IPA build, so the delivered IPA contains both feature sets.
- The Phase 2 baseline IPA remains an early CI/build-path proof only and is not the final deliverable.

## 2026-08-12 — Phase 3 architecture investigation

- Ran independent read-only investigations for settings/storage/sharing, MtProtoKit transport/TLS, and Bazel testability.
- Selected a single persisted HTTP model case with explicit TLS flag and new `_t = 2`; preserved existing tags 0/1 and the legacy top-level SOCKS fallback.
- Chose distinct HTTP/HTTPS editor modes, strict host/port validation, SOCKS-only calls, masked credentials, and fork-specific internal share schemes.
- Identified every exhaustive Swift connection-type switch and the status-probe path that must be updated.
- Confirmed the minimal focused Objective-C XCTest target shape and iPhone 17 / iOS 26.2 runner for Xcode 26.2.
- Corrected the documented direct readiness nuance: MTProto writes may be submitted to the backend once async connect starts, while the backend queues until actual connection and the open callback reports transport readiness.
- Selected one-byte exact reads for the initial CONNECT handshake to avoid over-read/deadlock with the current interface; the parser will still return trailing bytes for tests and future chunk reads.
- Selected pre-connect TLS configuration on `MTTcpConnectionInterface` for both GCDAsyncSocket and Network.framework, with the original proxy hostname for SNI/hostname validation and default platform trust intact.
- Implemented the Phase 4 model/UI/storage/link layer and ran an independent read-only proxy review.
- Fixed review findings: shared URL port validation, monotonic editor stable IDs, transport credential/secret log redaction, and SOCKS-only filtering at `PresentationCallManager`.
- HTTP/HTTPS transport remains unimplemented at this checkpoint; no functional proxy claim is made.

## 2026-08-12 — HTTP CONNECT implementation

- Added a bounded incremental CONNECT response parser with a 16 KiB limit, strict CRLF/header validation, all-2xx success handling, a distinct 407 result, and trailing-byte preservation.
- Added safe IPv4, bracketed IPv6, and hostname authority generation. Invalid, non-ASCII, zero-port, control-character, and header-injection inputs are rejected.
- Added optional RFC 7617 Basic proxy authentication without credential logging; ambiguous usernames containing a colon are rejected.
- Routed explicit HTTP proxy connections through the proxy endpoint, delayed all MTProto readiness and writes until CONNECT succeeds, and added a separate 12-second handshake timeout with close/reconnect cleanup.
- Added a focused `//submodules/MtProtoKit:MtProtoKitProxyTests` XCTest target covering success, per-byte fragmentation, all 2xx, 407/403, malformed and oversized responses, auth, address forms, input validation, and trailing data.
- An independent proxy review found no remaining blocking HTTP CONNECT defects after fixes. Transport-level callback/timeout/reconnect tests and macOS execution remain outstanding.
- No HTTP runtime or build success is claimed until the focused macOS test and application build complete.
