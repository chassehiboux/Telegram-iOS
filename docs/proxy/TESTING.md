# Testing and Build Evidence

## Baseline

- Local host: Windows; no local Xcode build is claimed.
- Required upstream versions: Telegram 12.9.2, Xcode 26.2, Bazel 8.4.2, macOS 26 (`versions.json`).
- Upstream guidance supports only the full `Telegram/Telegram` application build through `build-system/Make/Make.py`.
- Default `Tests/AllTests` is currently documented as broken; focused `Make.py test --target` runs are required.
- Source inspection confirmed `Tests/AllTests` contains a dangling `//submodules/TgVoipWebrtc:TgCallsTests` label.
- Existing real test labels are `//submodules/TextFormat:TextFormatTests` and the manual `//Telegram:iOSAppUITestSuite`; no MtProtoKit/proxy/network test target exists.
- `Make.py test` forces `debug_sim_arm64`, build number 10000, and a single target. New parser tests need an explicit simulator runner available in Xcode 26.2 and public fake/placeholder signing configuration.
- Device IPA and SideStore installation: not yet verified.

## Baseline build-path findings

- Public route: import `build-system/fake-codesigning/certs`, then run `Make.py build` with `--codesigningInformationPath=build-system/fake-codesigning` and `--configuration=release_arm64`.
- `release_arm64` selects device `arm64`; `Make.py --outputBuildArtifactsPath` deterministically copies `bazel-bin/Telegram/Telegram.ipa`.
- CI must use Apple Silicon `macos-26`. The pinned Bazel SHA in `versions.json` matches the darwin-arm64 release; an Intel runner would reject its downloaded Bazel binary.
- Root `CLAUDE.md` commands using private `fastlanematch`, `TELEGRAM_CODESIGNING_GIT_PASSWORD`, and optional private keys are explicitly excluded.
- Checked-in fake profiles are coupled to team `C67CF9S4VU` and bundle `ph.telegra.Telegraph`, expire 2026-10-30, and produce a fake-signed rather than unsigned IPA.
- Bazel initially uses the profile-bound upstream identifiers. The final workflow then rewrites app/extension plist references to `com.chassehiboux.TelegramProxy`, removes invalidated placeholder signatures and provisioning profiles, and repackages for SideStore re-signing. The workflow verifies the normalized root bundle ID before upload.
- `.github/workflows/build-sidestore-ipa.yml` is prepared but has not run. No device IPA or SideStore compatibility is claimed.
- The target repository is a public GitHub fork, so the standard `macos-26` runner is free according to current GitHub billing documentation. No larger runner is configured.
- Actions secret-name inspection found neither `TELEGRAM_API_ID` nor `TELEGRAM_API_HASH`; this is the current external blocker to dispatching a meaningful baseline build.
- The registered `.github/workflows/build.yml` has a manual source-validation job on feature refs. It uses explicit nonfunctional placeholders, runs `//submodules/MtProtoKit:MtProtoKitProxyTests`, compiles the complete release-arm64 app, and deliberately does not upload the resulting nonfunctional IPA. Its legacy release job is restricted to push events.

## Evidence template

- Base commit:
- Fork commit:
- macOS runner:
- Xcode:
- Build command:
- Tests:
- CI run URL/ID:
- IPA path:
- IPA SHA-256:
- Verified modes:
- Unverified scenarios:
- SideStore real-device result:
