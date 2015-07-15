require 'rake/testtask'

dir = File.dirname(__FILE__)

task :default => :test

Rake::TestTask.new do |t|
  t.libs << "test"
  t.test_files = Dir.glob("#{dir}/test/*_test.rb")
  t.warning = true
  t.verbose = true
  t.ruby_opts = ["--dev"] if defined?(JRUBY_VERSION)
end

namespace :test do
  task :isolated do
    Dir.glob("#{dir}/test/*_test.rb").all? do |file|
      sh(Gem.ruby, '-w', "-I#{dir}/lib", "-I#{dir}/test", file)
    end or raise "Failures"
  end
end
