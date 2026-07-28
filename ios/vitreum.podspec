Pod::Spec.new do |s|
  s.name             = 'vitreum'
  s.version          = '0.1.0'
  s.summary          = 'Adaptive native and simulated glass surfaces for Flutter.'
  s.description      = 'Public Apple Liquid Glass APIs where validated, with a Flutter fallback.'
  s.homepage         = 'https://github.com/example/vitreum'
  s.license          = { :file => '../LICENSE' }
  s.author           = { 'Vitreum contributors' => 'maintainers@example.invalid' }
  s.source           = { :path => '.' }
  s.source_files     = 'vitreum/Sources/vitreum/**/*'
  s.dependency 'Flutter'
  s.platform = :ios, '13.0'
  s.swift_version = '5.0'
end
