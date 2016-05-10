MRUBY_VERSION="1.2.0"

APP_NAME = ENV.fetch "APP_NAME", "mruby-cli"
APP_ROOT = ENV.fetch "APP_ROOT", Dir.pwd

def expand_and_set(env_name, default)
  unexpanded = ENV.fetch env_name, default

  expanded = File.expand_path unexpanded

  ENV[env_name] = expanded
end

# avoid redefining constants in mruby Rakefile
mruby_root   = expand_and_set "MRUBY_ROOT", "#{APP_ROOT}/mruby"
mruby_config = expand_and_set "MRUBY_CONFIG", "build_config.rb"

directory mruby_root do
  #sh "git clone --depth=1 https://github.com/mruby/mruby"
  sh "curl -L --fail --retry 3 --retry-delay 1 https://github.com/mruby/mruby/archive/#{MRUBY_VERSION}.tar.gz -s -o - | tar zxf -"
  mv "mruby-#{MRUBY_VERSION}", mruby_root
end

task :mruby => mruby_root

mruby_rakefile = "#{mruby_root}/Rakefile"
file mruby_rakefile => mruby_root

import mruby_rakefile

task :app_version do
  load "mrbgem.rake"

  current_gem = MRuby::Gem.current
  app_version = MRuby::Gem.current.version
  APP_VERSION = (app_version.nil? || app_version.empty?) ? "unknown" : app_version
end

desc "compile all the binaries"
task :compile => [:all] do
  MRuby.each_target do |target|
    `#{target.cc.command} --version`
    abort("Command #{target.cc.command} for #{target.name} is missing.") unless $?.success?
  end
  %W(#{mruby_root}/build/x86_64-pc-linux-gnu/bin/#{APP_NAME} #{mruby_root}/build/i686-pc-linux-gnu/#{APP_NAME}").each do |bin|
    sh "strip --strip-unneeded #{bin}" if File.exist?(bin)
  end
end

namespace :test do
  desc "run mruby & unit tests"
  # only build mtest for host
  task :mtest => :compile do
    # in order to get mruby/test/t/synatx.rb __FILE__ to pass,
    # we need to make sure the tests are built relative from mruby_root
    MRuby.each_target do |target|
      # only run unit tests here
      target.enable_bintest = false
      run_test if target.test_enabled?
    end
  end

  def clean_env(envs)
    old_env = {}
    envs.each do |key|
      old_env[key] = ENV[key]
      ENV[key] = nil
    end
    yield
    envs.each do |key|
      ENV[key] = old_env[key]
    end
  end

  desc "run integration tests"
  task :bintest => :compile do
    cd mruby_root do
      MRuby.each_target do |target|
        clean_env(%w(MRUBY_ROOT MRUBY_CONFIG)) do
          run_bintest if target.bintest_enabled?
        end
      end
    end
  end
end

desc "run all tests"
Rake::Task['test'].clear
task :test => ['test:bintest', 'test:mtest']

desc "cleanup"
task :clean do
  sh "rake deep_clean"
end

desc "generate a release tarball"
task :release => :compile do
  require 'tmpdir'

  release_path = File.expand_path "releases/v#{APP_VERSION}"
  app_name     = "#{APP_NAME}-#{APP_VERSION}"
  mkdir_p release_path

  Dir.mktmpdir do |tmp_dir|
    cd tmp_dir do
      MRuby.each_target do |target|
        next if name == "host"

        arch = name
        bin  = "#{build_dir}/bin/#{exefile(APP_NAME)}"
        mkdir_p name
        cp bin, name

        cd arch do
          arch_release = "#{app_name}-#{arch}"
          puts "Writing #{release_path}/#{arch_release}.tgz"
          `tar czf #{release_path}/#{arch_release}.tgz *`
        end
      end

      puts "Writing #{release_path}/#{app_name}.tgz"
      `tar czf #{release_path}/#{app_name}.tgz *`
    end
  end
end

def is_in_a_docker_container?
  `grep -q docker /proc/self/cgroup`
  $?.success?
end

namespace :local do
  desc "show version"
  task :version do
    puts "#{APP_NAME} #{APP_VERSION}"
  end

  task :ensure_in_docker do
    unless is_in_a_docker_container? then
      abort "Not running in docker, you should type \"docker-compose run <task>\"."
    end
  end
end

Rake.application.tasks.each do |task|
  next if task.name.start_with?("local:")
  next if Rake::FileTask === task

  task task.name => "local:ensure_in_docker"
end unless ENV["MRUBY_CLI_LOCAL"]

file "tasks/package.rake" => :app_version

import "tasks/package.rake"

