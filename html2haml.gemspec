# -*- encoding: utf-8 -*-
require File.expand_path('../lib/html2haml/version', __FILE__)

Gem::Specification.new do |gem|
  gem.authors       = ["Norman Clarke"]
  gem.email         = ["norman@njclarke.com"]
  gem.description   = %q{Converts HTML into Haml}
  gem.summary       = %q{Converts HTML into Haml}
  gem.homepage      = "http://haml.info"

  gem.files         = `git ls-files`.split($\)
  gem.executables   = gem.files.grep(%r{^bin/}).map{ |f| File.basename(f) }
  gem.test_files    = gem.files.grep(%r{^(test|spec|features)/})
  gem.name          = "html2haml"
  gem.require_paths = ["lib"]
  gem.version       = Html2haml::VERSION

  gem.add_dependency 'hpricot'
  gem.add_dependency 'haml'
  gem.add_development_dependency 'erubis'
  gem.add_development_dependency 'ruby_parser'
  gem.add_development_dependency 'simplecov'
  gem.add_development_dependency 'rake'
  gem.add_development_dependency 'minitest'
end
