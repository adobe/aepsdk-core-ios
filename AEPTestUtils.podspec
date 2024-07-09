Pod::Spec.new do |s|
    s.name             = "AEPTestUtils"
    s.version          = "5.0.3"
    s.summary          = "Adobe Experience Platform test utilities for Adobe Experience Platform Mobile SDK. Written and maintained by Adobe."
  
    s.description      = <<-DESC
                         The Adobe Experience Platform test utilities enable easier testing of Adobe Experience Platform Mobile SDKs.
                         DESC
  
    s.homepage         = "https://github.com/adobe/aepsdk-core-ios"
    s.license          = 'Apache V2'
    s.author           = "Adobe Experience Platform SDK Team"
    s.source           = { :git => "https://github.com/adobe/aepsdk-core-ios", :tag => s.version.to_s }
    
    s.ios.deployment_target = '12.0'
    s.tvos.deployment_target = '12.0'
  
    s.swift_version = '5.1'
  
    s.pod_target_xcconfig = { 
        'BUILD_LIBRARY_FOR_DISTRIBUTION' => 'YES',
        'ENABLE_TESTING_SEARCH_PATHS' => 'YES',
        'ENABLED_TESTABILITY' => 'YES' # Allows AEPTestUtils to use @testable import
    }
  
    s.frameworks   = 'XCTest'
  
    s.source_files = [
        'AEPServices/Mocks/PublicTestUtils/**/*.swift',
        'AEPCore/Mocks/PublicTestUtils/**/*.swift'
    ]
    
    s.dependency 'AEPCore', '>= 5.2.0', '< 6.0.0'
    s.dependency 'AEPServices', '>= 5.2.0', '< 6.0.0'
  end
  