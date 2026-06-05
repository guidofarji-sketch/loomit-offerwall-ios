Pod::Spec.new do |s|
  s.name             = 'LoomitOfferwallAdapterAPI'
  s.version          = '0.3.0-beta.27'
  s.summary          = 'Loomit Offerwall Adapter API for iOS'
  s.description      = <<-DESC
    Adapter API interface for Loomit Offerwall SDK iOS.
  DESC

  s.homepage         = 'https://github.com/guidofarji-sketch/loomit-offerwall-ios'
  s.license          = { :type => 'Proprietary', :text => 'Copyright Loomit. All rights reserved.' }
  s.author           = { 'Loomit' => 'support@loomit.com' }
  s.source           = { :git => 'https://github.com/guidofarji-sketch/loomit-offerwall-ios.git', :tag => s.version.to_s }

  s.ios.deployment_target = '14.0'
  s.swift_version = '5.0'

  s.source_files = 'LoomitOfferwallAdapterAPI/Sources/LoomitOfferwallAdapterAPI/**/*.swift'

  s.static_framework = true
  s.module_name = 'LoomitOfferwallAdapterAPI'
end
