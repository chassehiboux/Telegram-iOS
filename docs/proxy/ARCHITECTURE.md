# Proxy Architecture

Status: Phase 1 source map complete; detailed Phase 3 design remains open.

## Settings and persistence

- `submodules/SettingsUI/Sources/Data and Storage/DataAndStorageSettingsController.swift` opens proxy settings.
- `ProxyListSettingsController.swift` reads `SharedDataKeys.proxySettings` and toggles enabled/active servers, add, edit, delete, sharing, and QR flows.
- `ProxyServerSettingsController.swift` currently exposes only SOCKS5 and MTProto modes and persists through `updateProxySettingsInteractively`.
- `submodules/TelegramCore/Sources/SyncCore/SyncCore_ProxySettings.swift` owns `ProxyServerConnection` persistence. Existing tags are `_t = 0` for SOCKS5 and `_t = 1` for MTProto; they are immutable compatibility contracts. A legacy top-level SOCKS username/password fallback must remain decodable.
- `ProxySettings` is stored under stable shared-data key `Int32(4)`.
- Deep links flow through `UrlHandling.swift`, `OpenResolvedUrl.swift`, and `ProxyServerPreviewScreen`. Every exhaustive connection-type switch must be audited before adding cases.

## Bridge into MtProtoKit

`submodules/TelegramCore/Sources/Settings/ProxySettings.swift` currently maps both application proxy cases into `MTSocksProxySettings`: SOCKS has credentials and no secret; MTProto has a secret. Startup and live environment updates occur in `Network.swift` and `Account.swift`; MtProtoKit resets connections when proxy settings change.

Proxy status checks use the same bridge and create an `MTTcpConnection` through `ProxyServersStatuses.swift` and `MTProxyConnectivity.m`, so a shared transport-layer implementation also covers status probes.

## Transport lifecycles

`MTProto.m` creates `MTTcpTransport`; `MTTcpTransport.m` creates fresh `MTTcpConnection` instances and reports connection lifecycle changes.

- Direct: resolve destination -> successfully start the asynchronous connect -> mark `_readyToSendData` and submit queued MTProto writes to the backend. The backend may queue writes until its connect callback; transport-open notification still comes from `connectionInterfaceDidConnect`.
- SOCKS5: connect proxy -> method negotiation -> optional RFC 1929 authentication -> SOCKS CONNECT to Telegram destination -> parse reply -> mark ready -> drain queued MTProto -> start framed reads.
- MTProto proxy: connect to proxy and apply secret-controlled obfuscated framing. Type-2 fake TLS is Telegram camouflage, not certificate-validated TLS and cannot implement HTTPS CONNECT.
- HTTP proposal: TCP to proxy -> incremental HTTP CONNECT -> mark ready -> existing MTProto framing.
- HTTPS required flow: TCP to proxy -> certificate/hostname-validated TLS to proxy -> CONNECT inside TLS -> mark ready -> existing MTProto framing.

## Minimal insertion point

`submodules/MtProtoKit/Sources/MTTcpConnection.m` is the smallest shared HTTP insertion point because it already owns proxy selection, handshake state, `_readyToSendData`, queued sends, receive startup, timeout, close, and reconnect behavior for normal and proxy-status connections.

The current `MTTcpConnectionInterface` exposes connect, write, exact-length read, and disconnect. Backends are the embedded GCDAsyncSocket adapter in `MTTcpConnection.m` and `NetworkFrameworkTcpConnectionInterface.swift`. GCDAsyncSocket has TLS capability but the interface does not expose it; the Network.framework backend currently creates `NWParameters(tls: nil, tcp: ...)`. HTTPS design must cover both without trust bypass.

### HTTP receive strategy

The interface's exact-length contract makes a large CONNECT header read unsafe: a short successful response would wait for tunnel bytes that the client must not send before success. The minimal safe implementation reads one byte at a time into a bounded incremental parser until `\r\n\r\n`. Exact reads cannot over-read, so the first tunnel byte stays in the backend for the normal MTProto read. The parser will nevertheless accept arbitrary chunks and return any trailing suffix for deterministic tests and future chunk-read support.

HTTP/HTTPS set `_readyToSendData` and report `tcpConnectionOpened` only after a valid 2xx response. They need a dedicated handshake deadline because existing SOCKS reads use infinite timeouts and the normal response timer starts only after MTProto data is sent. Closing discards the whole `MTTcpConnection`, so parser, deadline, TLS, and CONNECT state are naturally recreated on reconnect.

### HTTPS design decision

Extend `MTTcpConnectionInterface` with TLS configuration supplied before connecting and make its connected callback mean TLS-ready for TLS connections.

- GCDAsyncSocket: start TLS after TCP connects, set `kCFStreamSSLPeerName` to the original proxy hostname, retain normal trust evaluation, and forward connected only from `socketDidSecure`.
- Network.framework: build TLS-enabled `NWParameters`, explicitly set the original proxy hostname/SNI, and retain default trust verification; `.ready` then means TCP plus TLS.
- Preserve the original hostname separately from its resolved IP for SNI and hostname verification.
- Do not implement TLS in a wrapper over opaque reads/writes, downcast backends, reuse MTProxy type-2 camouflage, bypass trust, or downgrade to plaintext.

## Known risks and required decisions

- Exact-length reads make post-header coalesced tunnel bytes a critical design issue. The parser/adapter must preserve every byte after `\r\n\r\n`.
- Existing debug output in `MTTcpConnection.m` logs SOCKS username and password; `MTSocksProxySettings.description` includes password/secret and is incorporated into environment descriptions. Redaction is mandatory before release.
- Current port conversion clamps to `UInt16`; UI validation should reject ports outside 1...65535.
- Telegram calls intentionally use only SOCKS today. HTTP/HTTPS behavior for `useForCalls` requires an explicit compatibility decision.
- HTTP/HTTPS share and deep-link schemas require a backward-compatible product decision.
- HTTPS alternatives to compare in Phase 7: extend `MTTcpConnectionInterface` with TLS upgrade/state callbacks; construct TLS-aware interfaces by mode; or add a dedicated wrapper/decorator. Selection must prove SNI, hostname/trust validation, backend coverage, reconnect safety, and small rebase cost.

## Test requirements

Extract the smallest deterministic CONNECT parser/state helper. Cover fragmented status/header/delimiter input, 2xx/407/other errors, malformed and oversized headers, authority formatting, credential redaction, lifecycle reset, and response-plus-tunnel bytes in one read. Add transport integration coverage where feasible and run focused Bazel tests through `Make.py test --target` on macOS.

There is no nested `submodules/MtProtoKit/CLAUDE.md` and no existing MtProtoKit test target. The current minimal app-side pattern is `//submodules/TextFormat:TextFormatTests`. A new focused target should use an explicit iPhone/iOS runner available with Xcode 26.2 and be invoked as `Make.py test --target //submodules/MtProtoKit:MtProtoKitProxyTests`, never through the broken aggregate suite. Whether the helper needs a small test-support library or test-visible header remains to be proven from Bazel linkage.

## Persistence and sharing decision

- Add one new domain case `http(username: String?, password: String?, tls: Bool)` with immutable `_t = 2` and explicit `tls`; retain `_t = 0` SOCKS5 and `_t = 1` MTProto unchanged.
- Present distinct HTTP and HTTPS modes in UI while sharing the model case and parser.
- Keep new credentials nested under `connection`; top-level `username` triggers the legacy SOCKS fallback.
- Keep HTTP/HTTPS excluded from `useForCalls` until the VoIP path explicitly supports them.
- Never encode HTTP/HTTPS as Telegram `socks` or `proxy` links because older/current clients would misinterpret them. Use fork-specific `tg://http-proxy` and `tg://https-proxy` links for internal/QR sharing; do not claim a `t.me` public schema without one.
- Validate trimmed nonempty host and port `1...65535`; do not rely on `UInt16(clamping:)` or `abs(port)`.
- Mask passwords in previews and redact all proxy descriptions/logs.
