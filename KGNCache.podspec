Pod::Spec.new do |spec|
  spec.name = 'KGNCache'
  spec.version = '0.1.2'
  spec.authors = {'David Keegan' => 'me@davidkeegan.com'}
  spec.homepage = 'https://github.com/kgn/KGNCache'
  spec.summary = 'KGNCache is a collection of helpful UIColor extensions.'  
  spec.source = {:git => 'https://github.com/kgn/KGNCache.git', :tag => "v#{spec.version}"}
  spec.license = { :type => 'MIT', :file => 'LICENSE' }

  spec.platform = :ios, '8.0'
  spec.requires_arc = true
  spec.frameworks = 'Foundation'
  spec.source_files = 'Source/Cache.swift'
  spec.dependency 'CryptoSwift', '~> 0.1'
end
