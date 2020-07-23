Pod::Spec.new do |s|
  s.name             = "AEPServices"
  s.version          = "0.0.1"
  s.summary          = "AEPServices"
  s.description      = <<-DESC
AEPServices
                        DESC
  s.homepage         = "https://github.com/adobe/aepsdk-core-ios"
  s.license          = 'Apache V2'
  s.author       = "Adobe Experience Platform SDK Team"
  s.source           = { :git => "https://github.com/adobe/aepsdk-core-ios", :tag => s.version.to_s }

  s.requires_arc          = true

  s.ios.deployment_target = '10.0'

  s.source_files          = 'AEPServices/Sources/**/*.swift'

  s.pod_target_xcconfig = { 'BUILD_LIBRARY_FOR_DISTRIBUTION' => 'YES' }
  s.swift_version = '5.0'
end
