# Implementation Notes

No proxy feature code has been changed yet.

## Phase 4 planned behavior

- Users can choose SOCKS5, MTProto, HTTP, or HTTPS in the proxy editor.
- HTTP and HTTPS store host, port, and optional username/password; edit/reopen restores the selected mode.
- Existing SOCKS5/MTProto serialized values and UI behavior remain unchanged.
- HTTP/HTTPS do not expose `Use for calls` initially.
- HTTP/HTTPS share only through fork-specific internal/QR schemes until a compatible public link schema exists.
- Host is trimmed and port must be within `1...65535` before Save/Share becomes available.
- Passwords are masked in preview and credentials are redacted from logs/descriptions.

## Planned model

Use `ProxyServerConnection.http(username:password:tls:)`, encoded as `_t = 2` with an explicit `tls` field. Existing tags 0 and 1 remain immutable. The MtProtoKit settings object must become explicitly mode-aware rather than inferring type only from the presence of `secret`.

## Test target

Add `//submodules/MtProtoKit:MtProtoKitProxyTests` as an Objective-C `ios_unit_test` with explicit iPhone 17 / iOS 26.2 runner. Invoke only with `Make.py test --target` and public fake signing configuration. Prefer a small private parser `objc_library` if it avoids exposing implementation details without duplicate compilation; otherwise use the smallest test-visible header supported by the existing build.

## Phase 4 implementation status

Implemented the persisted HTTP case (`_t = 2`, explicit TLS flag), distinct editor modes, edit/reopen restoration, strict URL/editor host and port validation, explicit MtProtoKit connection type, SOCKS-only call filtering, fork-specific QR/internal links, settings labels, and password/log redaction. HTTP/HTTPS transport is not connected yet, so this phase is intentionally not marked validated or shippable.
