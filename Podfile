# Uncomment the next line to define a global platform for your project
platform :ios, '10.0'

# Comment the next line if you don't want to use dynamic frameworks
use_frameworks!

workspace 'AEPCore'
project 'AEPCore.xcodeproj'

def rules_main
  pod 'AEPRulesEngine'
end

def rules_dev
  pod 'AEPRulesEngine', :git => 'https://github.com/sbenedicadb/aepsdk-rulesengine-ios.git', :branch => 'dev-v1.0.2'
end

target 'AEPCore' do
  rules_dev
end

target 'AEPCoreTests' do
  rules_dev
end

target 'AEPSignalTests' do
  rules_dev
end

target 'AEPLifecycleTests' do
  rules_dev
end

target 'AEPIdentityTests' do
  rules_dev
end

target 'AEPIntegrationTests' do
  rules_dev
end
