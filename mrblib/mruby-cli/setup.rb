module MRubyCLI
  class Setup
    def initialize(name, output)
      @name   = name
      @output = output
    end

    def run
      Dir.mkdir(@name) unless Dir.exist?(@name)
      Dir.chdir(@name) do
        Util::write_file(".gitignore", gitignore)
        Util::write_file("mrbgem.rake", mrbgem_rake)
        Util::write_file("build_config.rb", build_config_rb)
        Util::write_file("Rakefile", rakefile)
        Util::write_file("Dockerfile", dockerfile)
        Util::write_file("docker-compose.yml", docker_compose_yml)

        Util::create_dir_p("tools/#{@name}")
        Util::write_file("tools/#{@name}/#{@name}.c", tools)

        Util::create_dir("mrblib")
        Util::write_file("mrblib/#{@name}.rb", mrblib)

        Util::create_dir("bintest")
        Util::write_file("bintest/#{@name}.rb", bintest)

        Util::create_dir("test")
        Util::write_file("test/test_#{@name}.rb", test)

        Util::create_dir("mrblib/#{@name}")
        generate = Generate.new(@name, @output)
        generate.run(:cli)
        generate.run(:help)
        generate.run(:version)
        generate.run(:options)
      end
    end

    private

    def test
      <<TEST
class Test#{Util.camelize(@name)} < MTest::Unit::TestCase
  def test_main
    assert_nil __main__([])
  end
end

MTest::Unit.new.run
TEST
    end

    def bintest
      <<BINTEST
require 'open3'

BIN_PATH = File.join(File.dirname(__FILE__), "../mruby/bin/#{@name}")

assert('hello') do
  output, status = Open3.capture2(BIN_PATH)

  assert_true status.success?, "Process did not exit cleanly"
  assert_include output, "Hello World"
end

assert('version') do
  output, status = Open3.capture2(BIN_PATH, "--version")

  assert_true status.success?, "Process did not exit cleanly"
  assert_include output, "#{@name} version 0.0.1"
end
BINTEST
    end

    def mrbgem_rake
      <<MRBGEM_RAKE
require_relative 'mrblib/#{@name}/version'

MRuby::Gem::Specification.new('#{@name}') do |spec|
  spec.license = 'MIT'
  spec.author  = 'MRuby Developer'
  spec.summary = '#{@name}'
  spec.bins    = ['#{@name}']
  spec.version = #{Util.camelize(@name)}::Version::VERSION

  spec.add_dependency 'mruby-print', :core => 'mruby-print'
  spec.add_dependency 'mruby-mtest', :mgem => 'mruby-mtest'
  spec.add_dependency 'mruby-getopts', :mgem => 'mruby-getopts'
end
MRBGEM_RAKE
    end

    def gitignore
      <<IGNORE
mruby/
IGNORE
    end

    def build_config_rb
      <<BUILD_CONFIG_RB
def gem_config(conf)
  #conf.gembox 'default'

  # be sure to include this gem (the cli app)
  conf.gem File.expand_path(File.dirname(__FILE__))
end

MRuby::Build.new do |conf|
  toolchain :clang

  conf.enable_bintest
  conf.enable_debug
  conf.enable_test

  gem_config(conf)
end

MRuby::Build.new('x86_64-pc-linux-gnu') do |conf|
  toolchain :gcc

  gem_config(conf)
end

MRuby::CrossBuild.new('i686-pc-linux-gnu') do |conf|
  toolchain :gcc

  [conf.cc, conf.cxx, conf.linker].each do |cc|
    cc.flags << "-m32"
  end

  gem_config(conf)
end

MRuby::CrossBuild.new('x86_64-apple-darwin14') do |conf|
  toolchain :clang

  [conf.cc, conf.linker].each do |cc|
    cc.command = 'x86_64-apple-darwin14-clang'
  end
  conf.cxx.command      = 'x86_64-apple-darwin14-clang++'
  conf.archiver.command = 'x86_64-apple-darwin14-ar'

  conf.build_target     = 'x86_64-pc-linux-gnu'
  conf.host_target      = 'x86_64-apple-darwin14'

  gem_config(conf)
end

MRuby::CrossBuild.new('i386-apple-darwin14') do |conf|
  toolchain :clang

  [conf.cc, conf.linker].each do |cc|
    cc.command = 'i386-apple-darwin14-clang'
  end
  conf.cxx.command      = 'i386-apple-darwin14-clang++'
  conf.archiver.command = 'i386-apple-darwin14-ar'

  conf.build_target     = 'i386-pc-linux-gnu'
  conf.host_target      = 'i386-apple-darwin14'

  gem_config(conf)
end

MRuby::CrossBuild.new('x86_64-w64-mingw32') do |conf|
  toolchain :gcc

  [conf.cc, conf.linker].each do |cc|
    cc.command = 'x86_64-w64-mingw32-gcc'
  end
  conf.cxx.command      = 'x86_64-w64-mingw32-g++'
  conf.archiver.command = 'x86_64-w64-mingw32-gcc-ar'
  conf.exts.executable  = ".exe"

  conf.build_target     = 'x86_64-pc-linux-gnu'
  conf.host_target      = 'x86_64-w64-mingw32'

  gem_config(conf)
end

MRuby::CrossBuild.new('i686-w64-mingw32') do |conf|
  toolchain :gcc

  [conf.cc, conf.linker].each do |cc|
    cc.command = 'i686-w64-mingw32-gcc'
  end
  conf.cxx.command      = 'i686-w64-mingw32-g++'
  conf.archiver.command = 'i686-w64-mingw32-gcc-ar'
  conf.exts.executable  = ".exe"

  conf.build_target     = 'i686-pc-linux-gnu'
  conf.host_target      = 'i686-w64-mingw32'

  gem_config(conf)
end
BUILD_CONFIG_RB
    end

    def tools
      <<TOOLS
// This file is generated by mruby-cli. Do not touch.
#include <stdlib.h>
#include <stdio.h>

/* Include the mruby header */
#include <mruby.h>
#include <mruby/array.h>

int main(int argc, char *argv[])
{
  mrb_state *mrb = mrb_open();
  mrb_value ARGV = mrb_ary_new_capa(mrb, argc);
  int i;
  int return_value;

  for (i = 0; i < argc; i++) {
    mrb_ary_push(mrb, ARGV, mrb_str_new_cstr(mrb, argv[i]));
  }
  mrb_define_global_const(mrb, "ARGV", ARGV);

  // call __main__(ARGV)
  mrb_funcall(mrb, mrb_top_self(mrb), "__main__", 1, ARGV);

  return_value = EXIT_SUCCESS;

  if (mrb->exc) {
    mrb_print_error(mrb);
    return_value = EXIT_FAILURE;
  }
  mrb_close(mrb);

  return return_value;
}
TOOLS
    end

    def mrblib
      <<TOOLS
def __main__(argv)
  #{Util::camelize(@name)}::CLI.new(argv).run
end
TOOLS
    end

    def dockerfile
      <<DOCKERFILE
FROM hone/mruby-cli
DOCKERFILE
    end

    def docker_compose_yml
      <<DOCKER_COMPOSE_YML
compile: &defaults
  build: .
  volumes:
    - .:/home/mruby/code:rw
  command: rake compile
test:
  <<: *defaults
  command: rake test
bintest:
  <<: *defaults
  command: rake test:bintest
mtest:
  <<: *defaults
  command: rake test:mtest
clean:
  <<: *defaults
  command: rake clean
shell:
  <<: *defaults
  command: bash
DOCKER_COMPOSE_YML
    end

    def rakefile
      <<RAKEFILE
require 'fileutils'

MRUBY_VERSION="1.2.0"

file :mruby do
  #sh "git clone --depth=1 https://github.com/mruby/mruby"
  sh "curl -L --fail --retry 3 --retry-delay 1 https://github.com/mruby/mruby/archive/#{MRUBY_VERSION}.tar.gz -s -o - | tar zxf -"
  FileUtils.mv("mruby-#{MRUBY_VERSION}", "mruby")
end

APP_NAME=ENV["APP_NAME"] || "#{@name}"
APP_ROOT=ENV["APP_ROOT"] || Dir.pwd
# avoid redefining constants in mruby Rakefile
mruby_root=File.expand_path(ENV["MRUBY_ROOT"] || "\#{APP_ROOT}/mruby")
mruby_config=File.expand_path(ENV["MRUBY_CONFIG"] || "build_config.rb")
ENV['MRUBY_ROOT'] = mruby_root
ENV['MRUBY_CONFIG'] = mruby_config
Rake::Task[:mruby].invoke unless Dir.exist?(mruby_root)
Dir.chdir(mruby_root)
load "\#{mruby_root}/Rakefile"

desc "compile binary"
task :compile => [:all] do

  MRuby.each_target do |target|
    `\#{target.cc.command} --version`
    abort("Command \#{target.cc.command} for \#{target.name} is missing.") unless $?.success?
  end
  %W(\#{mruby_root}/build/x86_64-pc-linux-gnu/bin/\#{APP_NAME} \#{mruby_root}/build/i686-pc-linux-gnu/\#{APP_NAME}").each do |bin|
    sh "strip --strip-unneeded \#{bin}" if File.exist?(bin)
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
task :test => ["test:mtest", "test:bintest"]

desc "cleanup"
task :clean do
  sh "rake deep_clean"
end

namespace :local do
  desc "show help"
  task :version do
    require_relative 'mrblib/mruby-cli/version'
    puts "mruby-cli \#{MRubyCLI::Version::VERSION}"
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
      abort("Not running in docker, you should type \\"docker-compose run <task>\\".") \
        unless is_in_a_docker_container?
      old_task.invoke
    end
  end
end
RAKEFILE
    end
  end
end
