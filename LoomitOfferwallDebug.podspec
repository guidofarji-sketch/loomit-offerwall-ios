Pod::Spec.new do |s|
  s.name             = 'LoomitOfferwallDebug'
  s.version          = '0.3.0-beta.27'
  s.summary          = 'Loomit Offerwall Debug Suite for iOS'
  s.description      = <<-DESC
    Debug suite for Loomit Offerwall SDK iOS.
  DESC

  s.homepage         = 'https://github.com/guidofarji-sketch/loomit-offerwall-ios'
  s.license          = { :type => 'Proprietary', :text => 'Copyright Loomit. All rights reserved.' }
  s.author           = { 'Loomit' => 'support@loomit.com' }
  s.source           = { :git => 'https://github.com/guidofarji-sketch/loomit-offerwall-ios.git', :tag => s.version.to_s }

  s.ios.deployment_target = '14.0'
  s.swift_version = '5.0'

  s.source_files = 'LoomitOfferwallDebug/Sources/LoomitOfferwallDebug/**/*.swift'

  s.dependency 'LoomitOfferwallCore'

  s.static_framework = true
end
