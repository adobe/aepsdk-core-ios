Pod::Spec.new do |s|
  s.name             = "AEPCore"
  s.version          = "0.0.1"
  s.summary          = "AEPCore"
  s.description      = <<-DESC
AEPCore
                        DESC
  s.homepage         = "https://github.com/adobe/aepsdk-core-ios"
  s.license          = 'Apache V2'
  s.author       = "Adobe Experience Platform SDK Team"
  s.source           = { :git => "https://github.com/adobe/aepsdk-core-ios", :tag => s.version.to_s }

  s.ios.deployment_target = '10.0'

  s.swift_version = '5.0'
  
  s.pod_target_xcconfig = { 'BUILD_LIBRARY_FOR_DISTRIBUTION' => 'YES' }

  s.pod_target_xcconfig = { 'BUILD_LIBRARY_FOR_DISTRIBUTION' => 'YES', 'SWIFT_OBJC_BRIDGING_HEADER' => 'AEPCore/Sources/AEPCore.h' }

  s.dependency 'SwiftRulesEngine'
  s.dependency 'AEPServices'

  s.source_files          = 'AEPCore/Sources/**/*.swift', 'AEPCore/Sources/**/*.m', 'AEPCore/Sources/**/*.h'


end
