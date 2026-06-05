Pod::Spec.new do |s|
  s.name             = 'LoomitOfferwall'
  s.version          = '0.3.0-beta.27'
  s.summary          = 'Loomit Offerwall SDK for iOS'
  s.description      = <<-DESC
    Loomit Offerwall SDK provides a unified monetization layer with multi-provider
    offerwall support. Adapters are optional subspecs for modular provider selection.
  DESC

  s.homepage         = 'https://github.com/guidofarji-sketch/loomit-offerwall-ios'
  s.license          = { :type => 'Proprietary', :text => 'Copyright Loomit. All rights reserved.' }
  s.author           = { 'Loomit' => 'support@loomit.com' }
  s.source           = { :git => 'https://github.com/guidofarji-sketch/loomit-offerwall-ios.git', :tag => s.version.to_s }

  s.ios.deployment_target = '14.0'
  s.swift_versions = ['5.0', '5.9', '6.0']

  s.static_framework = true

  # Only Core is installed by default
  s.default_subspec = 'Core'

  # Core SDK (required)
  s.subspec 'Core' do |core|
    core.source_files = 'LoomitOfferwall/Sources/LoomitOfferwallCore/**/*.swift'
    core.resource_bundles = {
      'LoomitOfferwallCore' => ['LoomitOfferwall/Resources/**/*']
    }
    core.frameworks = 'Foundation', 'UIKit', 'AdSupport'
  end

  # Adapter API (required by all adapters)
  s.subspec 'AdapterAPI' do |api|
    api.source_files = 'LoomitOfferwallAdapterAPI/Sources/LoomitOfferwallAdapterAPI/**/*.swift'
    api.dependency 'LoomitOfferwall/Core'
  end

  # MyChips adapter (optional)
  s.subspec 'AdapterMyChips' do |mychips|
    mychips.source_files = 'LoomitOfferwallAdapterMyChips/Sources/LoomitOfferwallAdapterMyChips/**/*.swift'
    mychips.dependency 'LoomitOfferwall/AdapterAPI'
    mychips.vendored_frameworks = 'Frameworks/MyChipsSdk.xcframework'
  end

  # Tapjoy adapter (optional)
  s.subspec 'AdapterTapjoy' do |tapjoy|
    tapjoy.source_files = 'LoomitOfferwallAdapterTapjoy/Sources/LoomitOfferwallAdapterTapjoy/**/*.swift'
    tapjoy.dependency 'LoomitOfferwall/AdapterAPI'
    tapjoy.dependency 'TapjoySDK', '~> 14.7.0'
  end

  # Debug suite (optional)
  s.subspec 'Debug' do |debug|
    debug.source_files = 'LoomitOfferwallDebug/Sources/LoomitOfferwallDebug/**/*.swift'
    debug.dependency 'LoomitOfferwall/Core'
  end

  s.pod_target_xcconfig = {
    'BUILD_LIBRARY_FOR_DISTRIBUTION' => 'YES',
    'SWIFT_VERSION' => '5.0',
    'OTHER_LDFLAGS' => '-ObjC'
  }

end
