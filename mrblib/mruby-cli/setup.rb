module MRubyCLI
  class Setup
    def initialize(name, output)
      @name   = name
      @output = output
    end

    def run
      Dir.mkdir(@name) unless Dir.exist?(@name)
      Dir.chdir(@name) do
        write_file(".gitignore", gitignore)
        write_file("mrbgem.rake", mrbgem_rake)
        write_file("build_config.rb", build_config_rb)
        write_file("Rakefile", rakefile)
        write_file("Dockerfile", dockerfile)
        write_file("docker-compose.yml", docker_compose_yml)

        create_dir_p("tools/#{@name}")
        write_file("tools/#{@name}/#{@name}.c", tools)

        create_dir("mrblib")
        write_file("mrblib/#{@name}.rb", mrblib)

        create_dir("mrblib/#{@name}")
        write_file("mrblib/#{@name}/version.rb", version)

        create_dir("bintest")
        write_file("bintest/#{@name}.rb", bintest)

        create_dir("test")
        write_file("test/test_#{@name}.rb", test)
      end
    end

    private
    def create_dir_p(dir)
      dir.split("/").inject("") do |parent, base|
        new_dir =
          if parent == ""
            base
          else
            "#{parent}/#{base}"
          end

        create_dir(new_dir)

        new_dir
      end
    end

    def create_dir(dir)
      if Dir.exist?(dir)
        @output.puts "  skip    #{dir}"
      else
        @output.puts "  create  #{dir}/"
        Dir.mkdir(dir)
      end
    end

    def write_file(file, contents)
      @output.puts "  create  #{file}"
      File.open(file, 'w') {|file| file.puts contents }
    end

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
  output, status = Open3.capture2(BIN_PATH, "version")

  assert_true status.success?, "Process did not exit cleanly"
  assert_include output, "v0.0.1"
end
BINTEST
    end

    def mrbgem_rake
      <<MRBGEM_RAKE
require_relative 'mrblib/#{@name}/version'

spec = MRuby::Gem::Specification.new('#{@name}') do |spec|
  spec.bins    = ['#{@name}']
  spec.add_dependency 'mruby-print', :core => 'mruby-print'
  spec.add_dependency 'mruby-mtest', :mgem => 'mruby-mtest'
end

spec.license = 'MIT'
spec.author  = 'MRuby Developer'
spec.summary = '#{@name}'
spec.version = #{Util.camelize(@name)}::VERSION
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

  conf.exts do |exts|
    exts.object = '.obj'
    exts.executable = '.exe'
    exts.library = '.lib'
  end

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

  conf.exts do |exts|
    exts.object = '.obj'
    exts.executable = '.exe'
    exts.library = '.lib'
  end

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
  if argv[1] == "version"
    puts "v\#{#{Util.camelize(@name)}::VERSION}"
  else
    puts "Hello World"
  end
end
TOOLS
    end

    def version
      <<VERSION
module #{Util.camelize(@name)}
  VERSION = "0.0.1"
end
VERSION
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
  entrypoint:
    - rake
    - compile
test:
  <<: *defaults
  entrypoint:
    - rake
    - test
bintest:
  <<: *defaults
  entrypoint:
    - rake
    - test:bintest
mtest:
  <<: *defaults
  entrypoint:
    - rake
    - test:mtest
clean:
  <<: *defaults
  entrypoint:
    - rake
    - clean
shell:
  <<: *defaults
  entrypoint:
    - bash
release:
  <<: *defaults
  entrypoint:
    - rake
    - release
DOCKER_COMPOSE_YML
    end

    def rakefile
      <<RAKEFILE
require 'fileutils'

$verbose = Rake.verbose == Rake::FileUtilsExt::DEFAULT ? false : Rake.verbose

MRUBY_VERSION="1.2.0"

file :mruby do
  #sh "git clone --depth=1 https://github.com/mruby/mruby"
  sh "curl -L --fail --retry 3 --retry-delay 1 https://github.com/mruby/mruby/archive/\#{MRUBY_VERSION}.tar.gz -s -o - | tar zxf -"
  FileUtils.mv("mruby-\#{MRUBY_VERSION}", "mruby")
end

APP_NAME=ENV["APP_NAME"] || "#{@name}"
APP_ROOT=ENV["APP_ROOT"] || Dir.pwd
# avoid redefining constants in mruby Rakefile
mruby_root=File.expand_path(ENV["MRUBY_ROOT"] || "\#{APP_ROOT}/mruby")
mruby_config=File.expand_path(ENV["MRUBY_CONFIG"] || "build_config.rb")
ENV['MRUBY_ROOT'] = mruby_root
ENV['MRUBY_CONFIG'] = mruby_config
Rake::Task[:mruby].invoke unless Dir.exist?(mruby_root)
load "\#{mruby_root}/Rakefile"

load File.join(File.expand_path(File.dirname(__FILE__)), "mrbgem.rake")

current_gem = MRuby::Gem.current
app_version = MRuby::Gem.current.version
APP_VERSION = (app_version.nil? || app_version.empty?) ? "unknown" : app_version

desc "compile binary"
task :compile => [:all] do
  Dir.chdir(mruby_root) do
    MRuby.each_target do |target|
      `\#{target.cc.command} --version`
      abort("Command \#{target.cc.command} for \#{target.name} is missing.") unless $?.success?
    end
    %W(\#{mruby_root}/build/x86_64-pc-linux-gnu/bin/\#{APP_NAME} \#{mruby_root}/build/i686-pc-linux-gnu/\#{APP_NAME}).each do |bin|
      sh "strip --strip-unneeded \#{bin}" if File.exist?(bin)
    end
  end
end

namespace :test do
  desc "run mruby & unit tests"
  # only build mtest for host
  task :mtest => :compile do
    Dir.chdir(mruby_root) do
      # in order to get mruby/test/t/synatx.rb __FILE__ to pass,
      # we need to make sure the tests are built relative from mruby_root
      MRuby.each_target do |target|
        # only run unit tests here
        target.enable_bintest = false
        run_test if target.test_enabled?
      end
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
    Dir.chdir(mruby_root) do
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
task :test => ["test:mtest", "test:bintest"]

desc "cleanup"
task :clean do
  Dir.chdir(mruby_root) do
    sh "rake deep_clean"
  end
end

desc "generate a release tarball"
task :release => :compile do
  require 'tmpdir'

  Dir.chdir(mruby_root) do
    # since we're in the mruby/
    release_dir  = "releases/v\#{APP_VERSION}"
    release_path = Dir.pwd + "/../\#{release_dir}"
    app_name     = "\#{APP_NAME}-\#{APP_VERSION}"
    FileUtils.mkdir_p(release_path)

    Dir.mktmpdir do |tmp_dir|
      Dir.chdir(tmp_dir) do
        MRuby.each_target do |target|
          next if name == "host"

          arch = name
          bin  = "\#{build_dir}/bin/\#{exefile(APP_NAME)}"
          FileUtils.mkdir_p(name)
          FileUtils.cp(bin, name)

          Dir.chdir(arch) do
            arch_release = "\#{app_name}-\#{arch}"
            puts "Writing \#{release_dir}/\#{arch_release}.tgz"
            `tar czf \#{release_path}/\#{arch_release}.tgz *`
          end
        end

        puts "Writing \#{release_dir}/\#{app_name}.tgz"
        `tar czf \#{release_path}/\#{app_name}.tgz *`
      end
    end
  end
end

namespace :local do
  desc "show version"
  task :version do
    puts "\#{APP_NAME} \#{APP_VERSION}"
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
