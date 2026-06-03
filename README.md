# Loomit Offerwall iOS SDK

iOS distribution repository for the Loomit Offerwall SDK. Sources are compiled locally on the publisher's machine, ensuring compatibility with any Xcode/Swift version.

## Requirements

- iOS 14.0+
- Xcode 13+ (any Swift version)
- CocoaPods 1.10+

## Installation

Add to your `Podfile`:

```ruby
pod 'LoomitOfferwall'           # Core + Debug
pod 'LoomitOfferwall/Tapjoy'    # Tapjoy adapter (optional)
pod 'LoomitOfferwall/MyChips'   # MyChips adapter (optional)
```

Then run:
```bash
pod install
```

## Unity Integration

See the full Unity integration guide included in the Loomit Unity SDK distribution package.
