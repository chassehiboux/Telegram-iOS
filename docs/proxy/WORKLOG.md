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
- The workflow has not been pushed or dispatched. macOS Actions may incur billable usage and requires user approval first.
- No build, device IPA, proxy functionality, or SideStore installation has been claimed.
