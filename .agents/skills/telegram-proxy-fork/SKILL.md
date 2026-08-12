---
name: telegram-proxy-fork
description: Use for Telegram-iOS HTTP CONNECT, HTTPS CONNECT, proxy settings/serialization, MtProtoKit transport changes, proxy tests, macOS CI builds, and SideStore-ready IPA packaging in this repository.
---

# Telegram Proxy Fork Workflow

1. Read `AGENTS.md`, root `CLAUDE.md`, and relevant nested `CLAUDE.md` files in full.
2. Read `docs/proxy/ARCHITECTURE.md`, `IMPLEMENTATION.md`, and `TESTING.md` when present.
3. Re-check current source before trusting documentation.
4. For non-trivial design work, delegate independent read-only investigations to `repo_explorer`, `proxy_reviewer`, and/or `build_reviewer`.
5. Keep the main agent as the only normal source-code writer.
6. Before implementation, identify affected files, user-visible behavior, compatibility risks, and validation.
7. After implementation, inspect the diff, run relevant macOS CI tests/build, request networking or build review as applicable, fix confirmed issues, rerun validation, and update `docs/proxy/*`.

## HTTP CONNECT checklist

- Preserve direct, SOCKS5, MTProto-proxy, and existing serialized behavior.
- Tunnel before MTProto readiness or payload transmission.
- Support proxy hostname/IP, port, optional Basic authentication, IPv4/hostname destinations, and bracketed IPv6 authorities.
- Accept 2xx and safely fail 407, other non-2xx, malformed, closed, and timed-out handshakes.
- Parse fragmented status/header data and a delimiter split across reads.
- Enforce a bounded header size and reset all state on reconnect.
- Deliver bytes after the response header to the existing MTProto receive path.
- Never log credentials or authorization headers.

## HTTPS CONNECT checklist

- Establish TCP to the proxy, then TLS to the proxy, then CONNECT inside TLS, then existing MTProto traffic.
- Set SNI and verify the certificate hostname against the proxy hostname.
- Retain platform trust validation with no trust-all or plaintext downgrade.
- Recreate TLS and CONNECT state after reconnect.
- Reuse the tested HTTP parser where the architecture permits.

## Build and evidence checklist

- Use `versions.json` for Xcode, Bazel, and macOS requirements.
- Build through public `Make.py` and fake/placeholder signing paths, never Telegram private signing infrastructure.
- Validate `Payload/*.app` and a device-arm64 executable, not a simulator build.
- Record tests, CI run ID/URL, commit, configuration, artifact hash, unverified scenarios, and real-device SideStore status in `docs/proxy/TESTING.md`.
- Keep `docs/proxy/TASKS.md` and `WORKLOG.md` current; never mark success without evidence.
