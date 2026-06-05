# Loomit Offerwall iOS SDK

[![Version](https://img.shields.io/badge/version-0.3.0--beta.6-blue)](https://github.com/guidofarji-sketch/loomit-offerwall-ios/releases)
[![Platform](https://img.shields.io/badge/platform-iOS%2014.0%2B-lightgrey)](https://developer.apple.com/ios/)
[![Swift](https://img.shields.io/badge/swift-5.0%20%7C%205.9%20%7C%206.0-orange)](https://swift.org)
[![License](https://img.shields.io/badge/license-Proprietary-red)](LICENSE)

Unified offerwall monetization layer for iOS with multi-provider adapters, remote configuration, A/B testing, and server-side provider selection.

## Why Source-Based Distribution?

Unlike precompiled xcframeworks that break with every new Swift/Xcode release, **this pod compiles sources locally on the publisher's machine**. This guarantees:

- **Zero Swift version mismatch errors** — no "module compiled with Swift X cannot be imported by Swift Y"
- **Full symbol visibility** — debuggers and crash reporters see actual source lines
- **Architecture flexibility** — simulator, device, and new Apple Silicon variants work out of the box

## Requirements

- iOS 14.0+
- Xcode 14+ (Swift 5.0 / 5.9 / 6.0 compatible)
- CocoaPods 1.12+

## Installation

Add to your `Podfile`:

```ruby
platform :ios, '14.0'
use_frameworks! :linkage => :static

pod 'LoomitOfferwall', :git => 'https://github.com/guidofarji-sketch/loomit-offerwall-ios.git', :tag => '0.3.0-beta.7'
```

Then run:
```bash
pod install
```

> **Note:** `use_frameworks! :linkage => :static` is required for TapjoySDK compatibility and to prevent duplicate symbol issues when the pod is referenced by multiple targets.

## Configuration

### 1. API Key (Required)

Add your Loomit API Key to `Info.plist`:

```xml
<key>LoomitApiKey</key>
<string>YOUR_LOOMIT_API_KEY</string>
```

### 2. Initialize the SDK

```swift
import LoomitOfferwallCore

let sdk = OfferwallSdk.shared
await sdk.setLoomitApiKey("YOUR_LOOMIT_API_KEY")
await sdk.setClientId("your-client-id")
await sdk.setPublisherUserId("user-123")

// Register adapters
await sdk.registerAdapter(TapjoyAdapter())
await sdk.registerAdapter(MyChipsAdapter())

// Fetch remote configuration
_ = try? await sdk.fetchConfig()

// Show offerwall
if let viewController = UIApplication.shared.keyWindow?.rootViewController {
    await sdk.show(from: viewController)
}
```

### 3. Set up the Listener

```swift
class MyListener: OfferwallListener {
    func offerwallDidInitialize() {
        print("Offerwall ready")
    }
    
    func offerwall(didShow providerKey: String, adSpace: String?) {
        print("Showing: \(providerKey)")
    }
    
    func offerwall(didEarnRewardAmount amount: Int, currency: String, providerKey: String) {
        print("Reward: \(amount) \(currency) from \(providerKey)")
    }
}

await sdk.setListener(MyListener())
```

## Unity Integration

This repository includes an `@objc` wrapper class (`LoomitOfferwallBridgeWrapper`) specifically designed for Unity iOS bridging. The Unity bridge uses dynamic Objective-C runtime dispatch so the SDK pod can be linked **only in the main app target**, avoiding duplicate instances.

See the full Unity integration guide in the Loomit Unity SDK distribution package.

## Architecture

```
┌─────────────────┐     ┌──────────────────┐     ┌─────────────────────┐
│   Publisher App │────▶│ @objc Wrapper    │────▶│  OfferwallSdk Actor │
│   (Swift/ObjC)  │     │ (this pod)       │     │  (Swift concurrency)│
└─────────────────┘     └──────────────────┘     └─────────────────────┘
                              │
                              ▼
                       ┌──────────────────┐
                       │ OfferwallListener│
                       │ (callbacks)      │
                       └──────────────────┘
```

## Supported Providers

| Provider | Adapter | Status |
|----------|---------|--------|
| Tapjoy | `TapjoyAdapter` | Production Ready |
| MyChips | `MyChipsAdapter` | Production Ready |

## License

This software is proprietary and confidential. See [LICENSE](LICENSE) for details.

For licensing inquiries, contact support@loomit.com.
