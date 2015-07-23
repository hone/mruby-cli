module MrubyCli
  class Setup
    def initialize(name)
      @name = name
    end

    def run
      Dir.mkdir(@name) unless Dir.exist?(@name)
      Dir.chdir(@name) do
        write_file("mrbgem.rake", mrbgem_rake)
        write_file("build_config.rb", build_config_rb)
        Dir.mkdir("tools") unless Dir.exist?("tools")
        Dir.mkdir("tools/#{@name}") unless Dir.exist?("tools/#{@name}")
        write_file("tools/#{@name}/#{@name}.c", tools)
        Dir.mkdir("mrblib") unless Dir.exist?("mrblib")
        write_file("mrblib/#{@name}.rb", mrblib)
        write_file("Rakefile", rakefile)
        write_file("Dockerfile", dockerfile)
        write_file("docker-compose.yml", docker_compose_yml)
        Dir.mkdir("bintest") unless Dir.exist?("bintest")
        write_file("bintest/#{@name}.rb", bintest)
      end
    end

    private
    def write_file(file, contents)
      File.open(file, 'w') {|file| file.puts contents }
    end

    def bintest
      <<BINTEST
require 'open3'
require 'tmpdir'

BIN_PATH = File.join(File.dirname(__FILE__), "../mruby/bin/#{@name}")

assert('setup') do
  Dir.mktmpdir do |tmp_dir|
    Dir.chdir(tmp_dir) do
      output, status = Open3.capture2("\#{BIN_PATH}")

      assert_true status.success?, "Process did not exit cleanly"
      assert_include output, "Hello World"
    end
  end
end
BINTEST
    end

    def mrbgem_rake
      <<MRBGEM_RAKE
MRuby::Gem::Specification.new('#{@name}') do |spec|
  spec.license = 'MIT'
  spec.author  = 'MRuby Developer'
  spec.summary = '#{@name}'
  spec.bins    = ['#{@name}']

  spec.add_dependency 'mruby-print', :core => 'mruby-print'
end
MRBGEM_RAKE
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

MRuby::CrossBuild.new('x86_64-w64-mingw32') do |conf|
  toolchain :gcc

  [conf.cc, conf.linker].each do |cc|
    cc.command = 'x86_64-w64-mingw32-gcc'
  end
  conf.cxx.command      = 'x86_64-w64-mingw32-cpp'
  conf.archiver.command = 'x86_64-w64-mingw32-gcc-ar'
  conf.exts.executable  = ".exe"

  conf.build_target     = 'x86_64-pc-linux-gnu'
  conf.host_target      = 'x86_64-w64-mingw32'

  gem_config(conf)
end
BUILD_CONFIG_RB
    end

    def tools
      <<TOOLS
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
  puts "Hello World"
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
APP_ROOT=ENV["APP_ROOT"] || Dir.pwd
MRUBY_ROOT=ENV["MRUBY_ROOT"] || "\#{APP_ROOT}/mruby"
MRUBY_CONFIG=File.expand_path(ENV["MRUBY_CONFIG"] || "build_config.rb")
INSTALL_PREFIX=ENV["INSTALL_PREFIX"] || "\#{APP_ROOT}/build"
MRUBY_VERSION=ENV["MRUBY_VERSION"] || "1.1.0"

file :mruby do
  sh "git clone https://github.com/mruby/mruby"
end

desc "compile binary"
task :compile => :mruby do
  sh "cd \#{MRUBY_ROOT} && MRUBY_CONFIG=\#{MRUBY_CONFIG} rake all"
end

namespace :test do
  desc "run mruby & unit tests"
  task :mtest => :compile do
    sh "cd \#{MRUBY_ROOT} && MRUBY_CONFIG=\#{MRUBY_CONFIG} rake all test"
  end

  desc "run integration tests"
  task :bintest => :compile do
    sh "cd \#{MRUBY_ROOT} && ruby \#{MRUBY_ROOT}/test/bintest.rb \#{APP_ROOT}"
  end
end

desc "run all tests"
task :test => ["test:mtest", "test:bintest"]

desc "cleanup"
task :clean do
  sh "cd \#{MRUBY_ROOT} && rake deep_clean"
end

task :default => :test
RAKEFILE
    end
  end
end
