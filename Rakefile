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

Rake::Task[:mruby].invoke unless Dir.exist?(mruby_root)
cd mruby_root
load "#{mruby_root}/Rakefile"

load File.join(File.expand_path(File.dirname(__FILE__)), "mrbgem.rake")

current_gem = MRuby::Gem.current
app_version = MRuby::Gem.current.version
APP_VERSION = (app_version.nil? || app_version.empty?) ? "unknown" : app_version

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
    MRuby.each_target do |target|
      clean_env(%w(MRUBY_ROOT MRUBY_CONFIG)) do
        run_bintest if target.bintest_enabled?
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

  # since we're in the mruby/
  release_dir  = "releases/v#{APP_VERSION}"
  release_path = Dir.pwd + "/../#{release_dir}"
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
          puts "Writing #{release_dir}/#{arch_release}.tgz"
          `tar czf #{release_path}/#{arch_release}.tgz *`
        end
      end

      puts "Writing #{release_dir}/#{app_name}.tgz"
      `tar czf #{release_path}/#{app_name}.tgz *`
    end
  end
end

namespace :local do
  desc "show version"
  task :version do
    puts "#{APP_NAME} #{APP_VERSION}"
  end
end

def is_in_a_docker_container?
  `grep -q docker /proc/self/cgroup`
  $?.success?
end

Rake.application.tasks.each do |task|
  next if ENV["MRUBY_CLI_LOCAL"]
  unless task.name.start_with?("local:")
    # Inspired by rake-hooks
    # https://github.com/guillermo/rake-hooks
    old_task = Rake.application.instance_variable_get('@tasks').delete(task.name)
    desc old_task.full_comment
    task old_task.name => old_task.prerequisites do
      abort("Not running in docker, you should type \"docker-compose run <task>\".") \
        unless is_in_a_docker_container?
      old_task.invoke
    end
  end
end

file "../tasks/package.rake"

import "../tasks/package.rake"
