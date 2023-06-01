# Uncomment the next line to define a global platform for your project
platform :ios, '11.0'

# Comment the next line if you don't want to use dynamic frameworks
use_frameworks!

workspace 'AEPCore'

pod 'SwiftLint', '0.44.0'

def core_main
  project 'AEPCore.xcodeproj'
  pod 'AEPRulesEngine'
end

def core_dev
  project 'AEPCore.xcodeproj'
  pod 'AEPRulesEngine', :git => 'https://github.com/adobe/aepsdk-rulesengine-ios.git', :branch => 'main'
end

def tests_main
  project 'TestApps/AEPCoreTestApp.xcodeproj'
  pod 'AEPRulesEngine'
end

def tests_dev
  project 'TestApps/AEPCoreTestApp.xcodeproj'
  pod 'AEPRulesEngine', :git => 'https://github.com/adobe/aepsdk-rulesengine-ios.git', :branch => 'main'
end

target 'AEPCore' do
  core_main
end

target 'AEPCoreTests' do
  core_main
end

target 'AEPSignalTests' do
  core_main
end

target 'AEPLifecycleTests' do
  core_main
end

target 'AEPIdentityTests' do
  core_main
end

target 'AEPIntegrationTests' do
  core_main
end

# TestApps project dependencies

target 'TestApp_Swift' do
  tests_main
end

target 'TestApp_Objc' do
  tests_main
end

target 'E2E_Swift' do
  tests_main
end

target 'PerformanceApp' do
  tests_main
end

target 'TestAppExtension' do
  tests_main
end

target 'TestApp_Swift (tvOS)' do
  tests_main
end

target 'TestApp_Objc (tvOS)' do
  tests_main
end

post_install do |pi|
  pi.pods_project.targets.each do |t|
    t.build_configurations.each do |bc|
        bc.build_settings['TVOS_DEPLOYMENT_TARGET'] = '11.0'
        bc.build_settings['SUPPORTED_PLATFORMS'] = 'iphoneos iphonesimulator appletvos appletvsimulator'
        bc.build_settings['TARGETED_DEVICE_FAMILY'] = "1,2,3"
    end
  end
end
