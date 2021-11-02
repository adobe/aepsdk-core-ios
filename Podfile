# Uncomment the next line to define a global platform for your project
platform :ios, '10.0'

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
  pod 'AEPRulesEngine', :git => 'https://github.com/sbenedicadb/aepsdk-rulesengine-ios.git', :branch => 'dev-v1.1.0'
end

def tests_main
  project 'TestApps/AEPCoreTestApp.xcodeproj'
  pod 'AEPRulesEngine'
end

def tests_dev
  project 'TestApps/AEPCoreTestApp.xcodeproj'
  pod 'AEPRulesEngine', :git => 'https://github.com/sbenedicadb/aepsdk-rulesengine-ios.git', :branch => 'dev-v1.1.0'
end

target 'AEPCore' do
  core_dev
end

target 'AEPCoreTests' do
  core_dev
end

target 'AEPSignalTests' do
  core_dev
end

target 'AEPLifecycleTests' do
  core_dev
end

target 'AEPIdentityTests' do
  core_dev
end

target 'AEPIntegrationTests' do
  core_dev
end

# TestApps project dependencies

target 'TestApp_Swift' do
  tests_dev
end

target 'TestApp_Objc' do
  tests_dev
end

target 'E2E_Swift' do
  tests_dev
end

target 'PerformanceApp' do
  tests_dev
end
