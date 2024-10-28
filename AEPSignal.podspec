Pod::Spec.new do |s|
  s.name             = "AEPSignal"
  s.version          = "5.3.1"

  s.summary          = "Signal extension for Adobe Experience Platform Mobile SDK. Written and maintained by Adobe."
  s.description      = <<-DESC
                        The AEPSignal extension provides the support for Postback/PII/Open URL actions triggered by Core rules engine.
                        DESC
  s.homepage         = "https://github.com/adobe/aepsdk-core-ios"
  s.license          = 'Apache V2'
  s.author       = "Adobe Experience Platform SDK Team"
  s.source           = { :git => "https://github.com/adobe/aepsdk-core-ios", :tag => s.version.to_s }

  s.ios.deployment_target = '12.0'
  s.tvos.deployment_target = '12.0'

  s.swift_version = '5.1'
  
  s.source_files          = 'AEPSignal/Sources/**/*.swift'

  s.pod_target_xcconfig = { 'BUILD_LIBRARY_FOR_DISTRIBUTION' => 'YES' }

  s.dependency 'AEPCore', '>= 5.3.1', '< 6.0.0'


end
