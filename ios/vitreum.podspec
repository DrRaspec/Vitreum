Pod::Spec.new do |s|
  s.name             = 'vitreum'
  s.version          = '0.2.0'
  s.summary          = 'Adaptive native and simulated glass surfaces for Flutter.'
  s.description      = 'Public Apple Liquid Glass APIs where validated, with a Flutter fallback.'
  s.homepage         = 'https://github.com/DrRaspec/Vitreum'
  s.license          = { :file => '../LICENSE' }
  s.author           = 'Vitreum contributors'
  s.source           = { :path => '.' }
  s.source_files     = 'vitreum/Sources/vitreum/**/*'
  s.dependency 'Flutter'
  s.platform = :ios, '13.0'
  s.swift_version = '5.0'
end
