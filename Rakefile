require "rake/clean"
require "rake/testtask"
require "rubygems/package_task"

task :default => :test

CLEAN.replace %w(pkg doc coverage .yardoc)

Rake::TestTask.new do |t|
  t.libs << 'lib' << 'test'
  t.test_files = Dir["test/**/*_test.rb"]
  t.verbose = true
end

task :set_coverage_env do
  ENV["COVERAGE"] = "true"
end

desc "Run Simplecov (only works on 1.9)"
task :coverage => [:set_coverage_env, :test]

gemspec = File.expand_path("../html2haml.gemspec", __FILE__)
if File.exist? gemspec
  Gem::PackageTask.new(eval(File.read(gemspec))) { |pkg| }
end
