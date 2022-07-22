Pod::Spec.new do |s|
  s.name             = "AEPSignal"
  s.version          = "3.7.0"
  s.summary          = "Signal extension for Adobe Experience Platform Mobile SDK. Written and maintained by Adobe."
  s.description      = <<-DESC
                        The AEPSignal extension provides the support for Postback/PII/Open URL actions triggered by Core rules engine.
                        DESC
  s.homepage         = "https://github.com/FrazierMark/aepsdk-test"
  s.license          = 'Apache V2'
  s.author       = "Adobe Experience Platform SDK Team"
  s.source           = { :git => "https://github.com/FrazierMark/aepsdk-test", :tag => s.version.to_s }

  s.platform = :ios, :watchos, :tvos
  s.platforms = { :ios => "10.0", :watchos => "3.0", :tvos => "10.0" }
  
  s.ios.deployment_target = '10.0'
  s.tvos.deployment_target = '10.0'
  s.watchos.deployment_target = '3.0'

  s.source_files          = 'AEPSignal/Sources/**/*.swift'

  s.swift_version = '5.1'
  s.pod_target_xcconfig = { 'BUILD_LIBRARY_FOR_DISTRIBUTION' => 'YES' }

  s.dependency 'AEPCore', '>= 3.7.0'

end
