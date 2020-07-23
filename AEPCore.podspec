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

  s.requires_arc          = true

  s.ios.deployment_target = '10.0'

  s.swift_version = '5.0'

  s.dependency 'AEPCore/AEPServices'
  s.dependency 'AEPCore/AEPLifecycle'
  s.dependency 'AEPCore/AEPIdentity'

  s.source_files          = 'AEPCore/Sources/**/*.swift'

  s.subspec 'AEPServices' do |sp|    
    sp.dependency 'AEPServices'
  end


  s.subspec 'AEPLifecycle' do |sp|
    sp.dependency 'AEPLifecycle'

  end

  s.subspec 'AEPIdentity' do |sp|
    sp.dependency 'AEPIdentity'

  end


end
