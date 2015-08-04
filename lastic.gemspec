#require './lib/time_boots/version'

Gem::Specification.new do |s|
  s.name     = 'lastic'
  s.version  = '0.0.1'
  s.authors  = ['Victor Shepelev']
  s.email    = 'zverok.offline@gmail.com'
  s.homepage = 'https://github.com/zverok/lastic'

  s.summary = 'ElasticSearch DSL, erasing all the complexity'
  s.licenses = ['MIT']

  #s.files = `git ls-files`.split($RS).reject do |file|
  #  file =~ /^(?:
  #  spec\/.*
  #  |Gemfile
  #  |Rakefile
  #  |\.rspec
  #  |\.gitignore
  #  |\.rubocop.yml
  #  |\.travis.yml
  #  )$/x
  #end
  s.require_paths = ["lib"]

  s.add_dependency 'hashie'

  #s.add_development_dependency 'rubocop', '~> 0.30'
  s.add_development_dependency 'rspec', '~> 3'
  s.add_development_dependency 'rspec-its', '~> 1'
  #s.add_development_dependency 'simplecov', '~> 0.9'
end
