MRuby::Gem::Specification.new('mruby-plato-gnss') do |spec|
  spec.license = 'MIT'
  spec.authors = 'Hiroshi Mimaki'
  spec.description = 'Plato::GNSS module'

  spec.add_dependency('mruby-hash-ext', :core => 'mruby-hash-ext')
  spec.add_dependency('mruby-string-ext', :core => 'mruby-string-ext')
  spec.add_dependency('mruby-struct', :core => 'mruby-struct')
  spec.add_dependency('mruby-math', :core => 'mruby-math')
  spec.add_test_dependency('mruby-metaprog', :core => 'mruby-metaprog')
end
