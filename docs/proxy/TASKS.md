# Telegram HTTP/HTTPS Proxy Backlog

Statuses: `TODO`, `IN PROGRESS`, `BLOCKED`, `DONE`. Completed build/test items must include evidence such as a CI run ID or artifact hash.

## Phase 1 — Repository and environment baseline (`DONE`)

- [x] Read root `CLAUDE.md`, `README.md`, `versions.json`, and `.xcodebuildmcp/config.yaml`.
- [x] Verify remotes and establish feature branch `codex/http-https-proxy`.
- [x] Verify recursive submodules after replacing two inaccessible fork-relative URLs with canonical upstream URLs.
- [x] Inspect current proxy implementation without edits.
- [x] Inspect public fake-codesigning/build path.
- [x] Inspect local Windows tools (`git`, `gh`, `rg`, `python`) and GitHub CLI authentication.
- [x] Determine repository visibility: public fork `chassehiboux/Telegram-iOS` of `TelegramMessenger/Telegram-iOS`.
- [x] Establish baseline macOS CI strategy using standard Apple Silicon `macos-26` and Xcode 26.2.

## Phase 2 — Reproducible baseline SideStore-oriented IPA build (`IN PROGRESS`)

- [x] Add manual macOS GitHub Actions workflow.
- [x] Select and assert exact Xcode/macOS/Apple-Silicon requirements from `versions.json`.
- [ ] Generate stable non-secret fork configuration; consume Telegram API credentials only from Actions secrets if required.
- [ ] Configure missing Actions secrets `TELEGRAM_API_ID` and `TELEGRAM_API_HASH` (user action; values must not enter Git or logs).
- [ ] Build a device-arm64 IPA without Telegram private signing infrastructure.
- [x] Add workflow validation for one `Payload/*.app`, main executable arm64, and iOS-not-simulator platform.
- [ ] Upload and download `TelegramProxy.ipa`; record run, command, commit, and SHA-256.

## Phase 3 — Proxy architecture mapping (`TODO`)

- [ ] Trace settings UI, model, persistence, URL sharing, and MtProtoKit conversion.
- [ ] Trace `MTSocksProxySettings`, transport, connection interfaces, SOCKS5/MTProto handshakes, readiness, buffering, reconnect, timeout, and TLS facilities.
- [ ] Identify test targets and the minimal HTTP insertion point.
- [ ] Document HTTP lifecycle and compare HTTPS designs in `ARCHITECTURE.md`.

## Phase 4 — Data model, persistence, and UI (`TODO`)

- [ ] Add unambiguous HTTP and HTTPS modes with host, port, and optional credentials.
- [ ] Preserve old Codable identifiers and all SOCKS5/MTProto UI behavior.
- [ ] Verify create/edit/save/reopen behavior and add serialization tests where practical.
- [ ] Run macOS tests/build and backward-compatibility review.

## Phase 5 — HTTP CONNECT implementation (`TODO`)

- [ ] Add bounded incremental parser/state machine, Basic auth, status handling, IPv4/IPv6 authorities, lifecycle reset, and leftover-byte forwarding.
- [ ] Test one-chunk and fragmented 2xx, split delimiter, 407/403, malformed/oversized headers, auth redaction, authorities, and trailing tunnel bytes.
- [ ] Run proxy review and macOS tests/build; fix confirmed issues.

## Phase 6 — HTTP adversarial regression review (`TODO`)

- [ ] Review fragmentation, oversized input, close/timeout/retry, duplicate callbacks, stale state, and credential leaks.
- [ ] Verify direct, SOCKS5, MTProto proxy, saved switching, multi-DC, and media-preferred transports.
- [ ] Review CI coverage and rerun focused validation.

## Phase 7 — HTTPS CONNECT design (`TODO`)

- [ ] Compare TLS in `MTTcpConnection`, connection-interface extension, and wrapper/decorator designs.
- [ ] Confirm SNI, trust and hostname validation, reconnect, backend compatibility, testability, and rebase cost.
- [ ] Document the selected design before editing.

## Phase 8 — HTTPS CONNECT implementation (`TODO`)

- [ ] Add TLS-to-proxy, CONNECT inside TLS, normal validation, no downgrade, fresh reconnect, and parser reuse.
- [ ] Test success/failure, hostname/certificate failure where possible, 407/200, and reconnect.
- [ ] Run proxy review and CI; fix confirmed issues.

## Phase 9 — Final regression and IPA release (`TODO`)

- [ ] Validate direct, SOCKS5, MTProto, HTTP, and HTTPS modes plus proxy UI/persistence compatibility.
- [ ] Produce final device-arm64 `artifacts/TelegramProxy.ipa`.
- [ ] Record SHA-256, final run/build evidence, limitations, and SideStore installation status.
