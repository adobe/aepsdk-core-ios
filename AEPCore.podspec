Pod::Spec.new do |s|
  s.name             = "AEPCore"
  s.version          = "4.2.0"
  s.summary          = "Core library for Adobe Experience Platform Mobile SDK. Written and maintained by Adobe."
  s.description      = <<-DESC
                        The core library provides the foundation for the Adobe Experience Platform SDK.  Having the core library installed is a pre-requisite for any other Adobe Experience Platform SDK extension to work.
                        DESC
  s.homepage         = "https://github.com/adobe/aepsdk-core-ios"
  s.license          = 'Apache V2'
  s.author           = "Adobe Experience Platform SDK Team"
  s.source           = { :git => "https://github.com/adobe/aepsdk-core-ios", :tag => s.version.to_s }

  s.ios.deployment_target = '11.0'
  s.tvos.deployment_target = '11.0'

  s.swift_version = '5.1'

  s.pod_target_xcconfig = { 'BUILD_LIBRARY_FOR_DISTRIBUTION' => 'YES' }

  s.dependency 'AEPRulesEngine', '>= 4.0.0'
  s.dependency 'AEPServices', '>= 4.2.0'


  s.source_files          = 'AEPCore/Sources/**/*.swift'
  s.resource_bundles        = { 'AEPCore_Resources' => ['AEPCore/Sources/PrivacyInfo.xcprivacy'] }


end
