# Changelog

All notable changes to the LoomitOfferwall iOS SDK will be documented in this file.

The format is based on [Keep a Changelog](https://keepachangelog.com/en/1.1.0/),
and this project adheres to [Semantic Versioning](https://semver.org/spec/v2.0.0.html).

## [0.3.0-beta.6] - 2025-06-04

### Added
- `@objc` wrapper class `LoomitOfferwallBridgeWrapper` inside `LoomitOfferwallCore` for Unity iOS bridge integration.
  - Exposes all SDK methods as synchronous Objective-C selectors.
  - Wraps async `OfferwallSdk` actor calls via `NSInvocation` dispatch.
  - Implements `OfferwallListener` to forward callbacks to Unity via `UnitySendMessage`.
  - Includes duplicate-init guard (`isSdkInitialized`) to prevent double SDK initialization.

### Changed
- Switched Unity iOS bridge architecture to industry-standard CocoaPods pattern:
  - SDK pod declared **only** in `Unity-iPhone` host target (not `UnityFramework`).
  - UnityFramework compiles a pure Objective-C bridge that resolves the wrapper at runtime via `NSClassFromString`.
  - Eliminates duplicate SDK instances and duplicate events (`show`, `snapshot`).
- Expanded `swift_versions` to include `5.9` and `6.0`.
- Added `BUILD_LIBRARY_FOR_DISTRIBUTION = YES` for binary stability.

### Removed
- Removed legacy `@_cdecl` Swift bridge approach in favor of `@objc` wrapper class.

## [0.3.0-beta.5] - 2025-06-02

### Added
- Initial CocoaPods distribution with static framework linkage.
- Tapjoy and MyChips adapter support.
- Debug panel (`LoomitOfferwallDebug`) for diagnostics.
- `LoomitApiKey` Info.plist injection support.

### Fixed
- Removed stale xcframework references in Unity post-process build.

---

## Release Notes

### Versioning Strategy
- **Beta tags** (`0.x.x-beta.N`) are pre-release snapshots for publisher integration testing.
- **Stable tags** (`0.x.x`) are production-ready releases.
- All tags are immutable. If a critical fix is needed, a new tag is issued.
