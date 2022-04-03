source 'https://rubygems.org'

gemspec

gem 'nokogiri', RUBY_VERSION < '2.1' ? '~> 1.6.0' : '>= 1.7'

if RUBY_VERSION < '2.1'
  gem 'ruby_parser', '< 3.14'
elsif RUBY_VERSION < '2.3'
  gem 'ruby_parser', '< 3.18'
else
  gem 'ruby_parser', '>= 3.18'
end

gem 'sexp_processor', RUBY_VERSION < '2.1' ? '< 4.14.0' : '> 4.14.0'
