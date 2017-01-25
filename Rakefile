require "bundler/gem_tasks"
require "rake/clean"
require "rake/testtask"

task :default => :test

CLEAN.replace %w(pkg doc coverage .yardoc)

Rake::TestTask.new do |t|
  t.libs << 'lib' << 'test'
  if RUBY_PLATFORM == 'java'
    t.test_files = FileList["test/**/*_test.rb"]
  else
    t.test_files = FileList["test/**/*_test.rb"].exclude(/jruby/)
  end
  t.verbose = true
end

task :set_coverage_env do
  ENV["COVERAGE"] = "true"
end

desc "Run Simplecov"
task :coverage => [:set_coverage_env, :test]
