Pod::Spec.new do |s|
  s.name             = "AEPCore"
  s.version          = "3.7.1"
  s.summary          = "Core library for Adobe Experience Platform Mobile SDK. Written and maintained by Adobe."
  s.description      = <<-DESC
                        The core library provides the foundation for the Adobe Experience Platform SDK.  Having the core library installed is a pre-requisite for any other Adobe Experience Platform SDK extension to work.
                        DESC
  s.homepage         = "https://github.com/adobe/aepsdk-test"
  s.license          = 'Apache V2'
  s.author           = "Adobe Experience Platform SDK Team"
  s.source           = { :git => "https://github.com/adobe/aepsdk-test", :tag => s.version.to_s }

  s.platform = :ios, :watchos, :tvos
  s.platforms = { :ios => "10.0", :watchos => "3.0", :tvos => "10.0" }
  
  s.ios.deployment_target = '10.0'
  s.tvos.deployment_target = '10.0'
  s.watchos.deployment_target = '3.0'
  
  

  s.swift_version = '5.1'

  s.pod_target_xcconfig = { 'BUILD_LIBRARY_FOR_DISTRIBUTION' => 'YES' }

  s.dependency 'AEPRulesEngine', '>= 1.1.0'
  s.dependency 'AEPServices', '>= 3.7.1'

  s.source_files          = 'AEPCore/Sources/**/*.swift'
end
