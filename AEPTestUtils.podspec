Pod::Spec.new do |s|
    s.name             = "AEPTestUtils"
    s.version          = "5.0.1"
    s.summary          = "Adobe Experience Platform test utilities for Adobe Experience Platform Mobile SDK. Written and maintained by Adobe."
  
    s.description      = <<-DESC
                         The Adobe Experience Platform test utilities enable easier testing of Adobe Experience Platform Mobile SDKs.
                         DESC
  
    s.homepage         = "https://github.com/adobe/aepsdk-testutils-ios.git"
    s.license          = { :type => "Apache License, Version 2.0", :file => "LICENSE" }
    s.author           = "Adobe Experience Platform SDK Team"
    s.source           = { :git => "https://github.com/adobe/aepsdk-testutils-ios.git", :tag => s.version.to_s }
    
    s.ios.deployment_target = '12.0'
    s.tvos.deployment_target = '12.0'
  
    s.swift_version = '5.1'
  
    s.pod_target_xcconfig = { 'BUILD_LIBRARY_FOR_DISTRIBUTION' => 'YES' }
  
    s.frameworks   = 'XCTest'
  
    s.default_subspec = 'CoreDependent'
  
    s.subspec 'ServicesDependent' do |sd|
      sd.source_files = 'AEPServices/Mocks/AEPTestUtils/**/*.swift'
      sd.dependency 'AEPServices', '>= 5.2.0'
    end
  
    s.subspec 'CoreDependent' do |cd|
      cd.source_files = 'AEPCore/Mocks/AEPTestUtils/**/*.swift'
      cd.dependency 'AEPCore', '>= 5.2.0'
      cd.dependency 'AEPServices', '>= 5.2.0'
    end
  end
  