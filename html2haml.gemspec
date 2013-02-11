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

  gem.add_dependency 'hpricot', '~> 0.8.6'
  gem.add_dependency 'erubis', '~> 2.7.0'
  gem.add_dependency 'ruby_parser', '~> 3.1.1'
  gem.add_dependency 'haml', '>= 4.0.0.rc.1'
  gem.add_development_dependency 'simplecov', '~> 0.7.1'
  gem.add_development_dependency 'minitest', '~> 4.4.0'
  gem.add_development_dependency 'rake'
end
