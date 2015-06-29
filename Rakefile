APP_ROOT=ENV["APP_ROOT"] || Dir.pwd
MRUBY_ROOT=ENV["MRUBY_ROOT"] || "#{APP_ROOT}/mruby"
MRUBY_CONFIG=File.expand_path(ENV["MRUBY_CONFIG"] || "build_config.rb")
INSTALL_PREFIX=ENV["INSTALL_PREFIX"] || "#{APP_ROOT}/build"
MRUBY_VERSION=ENV["MRUBY_VERSION"] || "1.1.0"

desc "Setup Docker for building things locally"
task :setup => ["Dockerfile", "docker-compose.yml"] do
  sh "docker-compose build"
end

file :mruby do
  sh "git clone https://github.com/mruby/mruby"
end

desc "compile binary"
task :compile => :mruby do
  sh "cd #{MRUBY_ROOT} && MRUBY_CONFIG=#{MRUBY_CONFIG} rake all"
end

namespace :test do
  desc "run mruby & unit tests"
  task :mtest => :compile do
    sh "cd #{MRUBY_ROOT} && MRUBY_CONFIG=#{MRUBY_CONFIG} rake all test"
  end

  desc "run integration tests"
  task :bintest => :compile do
    sh "cd #{MRUBY_ROOT} && ruby #{MRUBY_ROOT}/test/bintest.rb #{APP_ROOT}"
  end
end

desc "run all tests"
task :test => ["test:mtest", "test:bintest"]

desc "cleanup"
task :clean do
  sh "cd #{MRUBY_ROOT} && rake deep_clean"
end

task :default => :test
