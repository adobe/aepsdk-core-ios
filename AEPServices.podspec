Pod::Spec.new do |s|
  s.name             = "AEPServices"
  s.version          = "3.5.0.1"
  s.summary          = "Servcies library for Adobe Experience Platform Mobile SDK. Written and maintained by Adobe."
  s.description      = <<-DESC
                        The AEPServices library provides the platform services and utilities for the Adobe Experience Platform SDK.  Having the services library installed is a pre-requisite for any other Adobe Experience Platform SDK extension to work.
                        DESC
  s.homepage         = "https://github.com/adobe/aepsdk-core-ios"
  s.license          = 'Apache V2'
  s.author       = "Adobe Experience Platform SDK Team"
  s.source           = { :git => "https://github.com/adobe/aepsdk-core-ios", :tag => s.version.to_s }

  s.ios.deployment_target = '10.0'
  s.tvos.deployment_target = '10.0'

  s.source_files          = 'AEPServices/Sources/**/*.swift'

  s.pod_target_xcconfig = { 'BUILD_LIBRARY_FOR_DISTRIBUTION' => 'YES' }
  s.swift_version = '5.1'
end
