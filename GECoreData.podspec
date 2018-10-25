Pod::Spec.new do |s|

  s.name = "GECoreData"
  s.version = "0.0.1"
  s.summary = "Core Data related extensions"

  s.description  = <<~END
    Core Data related stuff shared between applications.
  END

  s.homepage = "https://github.com/grigorye/GECoreData"
  s.license = 'MIT'
  s.author = { "Grigory Entin" => "grigory.entin@gmail.com" }

  s.ios.deployment_target = '11.0'
  # s.osx.deployment_target = '10.10'
  # s.watchos.deployment_target = "2.0"
  # s.tvos.deployment_target = "9.0"

  s.source = { :git => "https://github.com/grigorye/GECoreData.git", :tag => "#{s.version}" }
  
  s.swift_version = "4.2"

  s.source_files  = "GECoreData/*.swift"

  s.dependency "GEFoundation", "~> 0.1"
  s.dependency "GETracing", "~> 0.1"

  s.test_spec 'Tests' do |test_spec|
    test_spec.source_files = 'GECoreDataTests/*.swift'
  end  

end
