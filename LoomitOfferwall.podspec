Pod::Spec.new do |s|
  s.name             = 'LoomitOfferwall'
  s.version          = '0.3.0-beta.2'
  s.summary          = 'Loomit Offerwall SDK for iOS'
  s.description      = <<-DESC
    Loomit Offerwall SDK provides a unified monetization layer with multi-provider
    offerwall support (Tapjoy, MyChips). Sources are compiled locally so the SDK
    works with any Swift/Xcode version.
  DESC

  s.homepage         = 'https://github.com/guidofarji-sketch/loomit-offerwall-ios'
  s.license          = { :type => 'Proprietary', :text => 'Copyright Loomit. All rights reserved.' }
  s.author           = { 'Loomit' => 'support@loomit.com' }
  s.source           = { :git => 'https://github.com/guidofarji-sketch/loomit-offerwall-ios.git', :tag => s.version.to_s }

  s.ios.deployment_target = '14.0'
  s.swift_versions = ['5.0']

  s.pod_target_xcconfig = {
    'SWIFT_VERSION' => '5.0'
  }

  # ─────────────────────────────────────────────────────────────────────────────
  # Core — AdapterAPI + Core compiled as one pod target.
  # AdapterAPI sources are included here directly so Swift resolves all types
  # without needing a separate 'import LoomitOfferwallAdapterAPI' statement.
  # ─────────────────────────────────────────────────────────────────────────────
  s.subspec 'Core' do |core|
    core.source_files = [
      'Sources/LoomitOfferwallAdapterAPI/**/*.swift',
      'Sources/LoomitOfferwallCore/**/*.swift'
    ]
    core.resource_bundles = {
      'LoomitOfferwallCore' => ['Resources/EmergencyConfig.json']
    }
    core.frameworks = 'Foundation', 'UIKit', 'AdSupport'
  end

  # ─────────────────────────────────────────────────────────────────────────────
  # Debug — optional debug panel (shake to open)
  # ─────────────────────────────────────────────────────────────────────────────
  s.subspec 'Debug' do |debug|
    debug.source_files = 'Sources/LoomitOfferwallDebug/**/*.swift'
    debug.dependency 'LoomitOfferwall/Core'
  end

  # ─────────────────────────────────────────────────────────────────────────────
  # Tapjoy — optional adapter for Tapjoy/Unity Offerwall
  # Requires TapjoySDK ~> 14.0 from CocoaPods trunk (static xcframework)
  # Note: Podfile must use: use_frameworks! :linkage => :static
  # ─────────────────────────────────────────────────────────────────────────────
  s.subspec 'Tapjoy' do |tapjoy|
    tapjoy.source_files = 'Sources/LoomitOfferwallAdapterTapjoy/**/*.swift'
    tapjoy.dependency 'LoomitOfferwall/Core'
    tapjoy.dependency 'TapjoySDK', '~> 14.0'
    tapjoy.pod_target_xcconfig = { 'OTHER_LDFLAGS' => '-ObjC' }
  end

  # ─────────────────────────────────────────────────────────────────────────────
  # MyChips — optional adapter. Uses vendored xcframework (no CocoaPod available)
  # ─────────────────────────────────────────────────────────────────────────────
  s.subspec 'MyChips' do |mychips|
    mychips.source_files       = 'Sources/LoomitOfferwallAdapterMyChips/**/*.swift'
    mychips.dependency 'LoomitOfferwall/Core'
    mychips.vendored_frameworks = 'Frameworks/MyChipsSdk.xcframework'
  end

  # Default: Core + Debug only. Publishers add providers explicitly.
  s.default_subspecs = ['Core', 'Debug']

end
