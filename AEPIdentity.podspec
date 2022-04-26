Pod::Spec.new do |s|
  s.name             = "AEPIdentity"
  s.version          = "3.5.0.1"
  s.summary          = "Identity extension for Adobe Experience Platform Mobile SDK. Written and maintained by Adobe."
  s.description      = <<-DESC
                        The AEPIdentity extension provides APIs that allow use of the Visitor ID services in the Adobe Experience Cloud SDK.
                        DESC
  s.homepage         = "https://github.com/adobe/aepsdk-core-ios"
  s.license          = 'Apache V2'
  s.author       = "Adobe Experience Platform SDK Team"
  s.source           = { :git => "https://github.com/adobe/aepsdk-core-ios", :tag => s.version.to_s }

  s.ios.deployment_target = '10.0'
  s.tvos.deployment_target = '10.0'

  s.source_files          = 'AEPIdentity/Sources/**/*.swift'

  s.swift_version = '5.1'
  s.pod_target_xcconfig = { 'BUILD_LIBRARY_FOR_DISTRIBUTION' => 'YES' }

  s.dependency 'AEPCore', '>= 3.5.0'

end
