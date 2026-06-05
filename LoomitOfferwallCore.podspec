Pod::Spec.new do |s|
  s.name             = 'LoomitOfferwallCore'
  s.version          = '0.3.0-beta.27'
  s.summary          = 'Loomit Offerwall SDK Core for iOS'
  s.description      = <<-DESC
    Loomit Offerwall SDK Core provides the unified monetization layer.
  DESC

  s.homepage         = 'https://github.com/guidofarji-sketch/loomit-offerwall-ios'
  s.license          = { :type => 'Proprietary', :text => 'Copyright Loomit. All rights reserved.' }
  s.author           = { 'Loomit' => 'support@loomit.com' }
  s.source           = { :git => 'https://github.com/guidofarji-sketch/loomit-offerwall-ios.git', :tag => s.version.to_s }

  s.ios.deployment_target = '14.0'
  s.swift_versions = ['5.0', '5.9', '6.0']

  s.static_framework = true

  s.source_files = 'LoomitOfferwall/Sources/LoomitOfferwallCore/**/*.swift'

  s.resource_bundles = {
    'LoomitOfferwallCore' => ['LoomitOfferwall/Resources/**/*']
  }

  s.frameworks = 'Foundation', 'UIKit', 'AdSupport'

  s.pod_target_xcconfig = {
    'BUILD_LIBRARY_FOR_DISTRIBUTION' => 'YES',
    'SWIFT_VERSION' => '5.0',
    'OTHER_LDFLAGS' => '-ObjC'
  }
end
