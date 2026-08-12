# Telegram-iOS Proxy Fork Instructions

## Project objective

Maintain a minimally modified Telegram-iOS fork that preserves direct, SOCKS5, and MTProto-proxy behavior; adds HTTP CONNECT and HTTPS CONNECT proxy modes; builds reproducibly on macOS CI; and produces a SideStore-ready device-arm64 IPA.

## Mandatory upstream context

At the start of every non-trivial task:

1. Read root `CLAUDE.md` and any relevant nested `CLAUDE.md` files.
2. Inspect current source before relying on documentation.
3. Use `versions.json` as the source of truth for Xcode, Bazel, and macOS versions.
4. If upstream behavior conflicts with `docs/proxy/`, resolve it from source and record the resolution.

## Architecture and security constraints

- Preserve direct, SOCKS5, and MTProto-proxy behavior and serialized settings.
- Make HTTP/HTTPS establish a transparent TCP tunnel before existing MTProto payload begins.
- Prefer the smallest maintainable change and low future rebase cost.
- Do not add production third-party dependencies without explicit approval.
- Never disable TLS certificate or hostname validation and never implement trust-all TLS.
- Never log proxy passwords, `Proxy-Authorization`, Telegram API hashes, auth tokens, session keys, Apple credentials, certificates, or private signing material.
- Do not request or store an Apple Account password. SideStore performs final signing.

## HTTP CONNECT checklist

- Accept proxy hostname/IP, port, and optional Basic authentication.
- Format IPv4, hostname, and bracketed IPv6 destination authorities correctly.
- Accept all HTTP 2xx statuses; fail 407 and other non-2xx responses safely.
- Parse fragmented status lines, headers, and split `\r\n\r\n` delimiters incrementally.
- Bound the maximum response-header size.
- Handle timeout, close, retry, and reconnect by recreating handshake state.
- Do not become MTProto-ready or send MTProto bytes before CONNECT succeeds.
- Preserve bytes arriving after `\r\n\r\n` and pass them to the normal MTProto receive path.

## HTTPS CONNECT checklist

Use this sequence: TCP to proxy -> TLS to proxy -> CONNECT inside TLS -> existing MTProto transport.

- Use the proxy hostname for SNI and hostname verification.
- Keep normal platform certificate validation enabled.
- Never fall back automatically to plaintext after TLS failure.
- Recreate TLS and CONNECT state on reconnect.

## Subagent policy

Use read-only subagents for independent exploration, protocol/security review, build analysis, test discovery, and CI log triage when they materially improve accuracy or speed. The main agent owns architecture, final source edits, synthesis, and fixes. Do not let agents concurrently edit overlapping Telegram source files. Run `proxy_reviewer` after important networking changes and `build_reviewer` for relevant CI failures.

## Build rules

- Windows is for editing and orchestration; compile iOS only on macOS.
- Prefer a standard GitHub-hosted macOS runner when no Mac host is available.
- Select the exact Xcode required by `versions.json` and build through Bazel using `Make.py`.
- Respect full-target and test limitations in `CLAUDE.md`.
- Never use Telegram's private codesigning repository. Prefer the public fake/placeholder signing path for SideStore re-signing.
- A simulator artifact is not the deliverable; the IPA main executable must be device arm64.

## Git and completion rules

- Inspect Git freely; never force-push, rewrite published history, change visibility, or create paid resources without approval.
- Work on a dedicated feature branch, do not commit secrets, and inspect the diff before finalizing each phase.
- Update `docs/proxy/TASKS.md` and `docs/proxy/WORKLOG.md` for each task update.
- Mark work complete only with recorded evidence.
