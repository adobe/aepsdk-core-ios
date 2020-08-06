Pod::Spec.new do |s|
  s.name             = "AEPSignal"
  s.version          = "0.0.1"
  s.summary          = "AEPSignal"
  s.description      = <<-DESC
AEPLifecycle
                        DESC
  s.homepage         = "https://github.com/adobe/aepsdk-core-ios"
  s.license          = 'Apache V2'
  s.author       = "Adobe Experience Platform SDK Team"
  s.source           = { :git => "https://github.com/adobe/aepsdk-core-ios", :tag => s.version.to_s }

  s.ios.deployment_target = '10.0'

  s.source_files = 'AEPSignal/Sources/**/*.{swift,h,m}'

  s.swift_version = '5.0'
  s.pod_target_xcconfig = { 'BUILD_LIBRARY_FOR_DISTRIBUTION' => 'YES' }

  s.dependency 'AEPCore'
end
