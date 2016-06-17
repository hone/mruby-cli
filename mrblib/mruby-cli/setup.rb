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

        create_dir_p("tasks")
        write_file("tasks/package.rake", package_rake)
        write_file("tasks/test.rake", test_rake)

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
release:
  <<: *defaults
  command: rake release
DOCKER_COMPOSE_YML
    end

    def rakefile
      <<-RAKEFILE
MRUBY_VERSION="1.2.0"

APP_NAME = ENV.fetch "APP_NAME", "#{@name}"
APP_ROOT = ENV.fetch "APP_ROOT", Dir.pwd

def expand_and_set(env_name, default)
  unexpanded = ENV.fetch env_name, default

  expanded = File.expand_path unexpanded

  ENV[env_name] = expanded
end

# avoid redefining constants in mruby Rakefile
mruby_root   = expand_and_set "MRUBY_ROOT", "\#{APP_ROOT}/mruby"
mruby_config = expand_and_set "MRUBY_CONFIG", "build_config.rb"

directory mruby_root do
  #sh "git clone --depth=1 https://github.com/mruby/mruby"
  sh "curl -L --fail --retry 3 --retry-delay 1 https://github.com/mruby/mruby/archive/\#{MRUBY_VERSION}.tar.gz -s -o - | tar zxf -"
  mv "mruby-\#{MRUBY_VERSION}", mruby_root
end

task :mruby => mruby_root

mruby_rakefile = "\#{mruby_root}/Rakefile"

file   mruby_rakefile => mruby_root
import mruby_rakefile

test_rakefile = "tasks/test.rake"
file   test_rakefile => mruby_rakefile
import test_rakefile

task :app_version do
  load "mrbgem.rake"

  current_gem = MRuby::Gem.current
  app_version = MRuby::Gem.current.version
  APP_VERSION = (app_version.nil? || app_version.empty?) ? "unknown" : app_version
end

desc "compile all the binaries"
task :compile => [:all] do
  %W(\#{mruby_root}/build/x86_64-pc-linux-gnu/bin/\#{APP_NAME}
     \#{mruby_root}/build/i686-pc-linux-gnu/\#{APP_NAME}").each do |bin|
    puts "impl strip \#{bin}"
    next unless File.exist? bin

    sh "strip --strip-unneeded \#{bin}"
  end
end

desc "cleanup"
task :clean do
  sh "rake deep_clean"
end

desc "generate a release tarball"
task :release => :compile do
  require 'tmpdir'

  release_path = File.expand_path "releases/v\#{APP_VERSION}"
  app_name     = "\#{APP_NAME}-\#{APP_VERSION}"
  mkdir_p release_path

  Dir.mktmpdir do |tmp_dir|
    cd tmp_dir do
      MRuby.each_target do |target|
        next if name == "host"

        arch = name
        bin  = "\#{build_dir}/bin/\#{exefile(APP_NAME)}"
        mkdir_p name
        cp bin, name

        cd arch do
          arch_release = "\#{app_name}-\#{arch}"
          puts "Writing \#{release_path}/\#{arch_release}.tgz"
          `tar czf \#{release_path}/\#{arch_release}.tgz *`
        end
      end

      puts "Writing \#{release_path}/\#{app_name}.tgz"
      `tar czf \#{release_path}/\#{app_name}.tgz *`
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
    puts "\#{APP_NAME} \#{APP_VERSION}"
  end

  task :ensure_in_docker do
    unless is_in_a_docker_container? then
      abort 'Not running in docker, you should type "docker-compose run <task>".'
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
      RAKEFILE
    end

   def package_rake
     <<-'RAKEFILE'
require 'tmpdir'

desc "create all packages"
task :package => ["package:deb", "package:rpm", "package:msi", "package:dmg"]

namespace :package do
  release_path = File.expand_path "releases/v#{APP_VERSION}"
  package_path = File.expand_path "packages/v#{APP_VERSION}"

  directory package_path

  def check_fpm_installed?
    `gem list -i fpm`.chomp == "true"
  end

  def check_msi_installed?
    `wixl --version`
    $?.success?
  end

  def check_dmg_installed?
    `genisoimage --version`
    $?.success?
  end

  def wxs_content(version, arch)
    arch_wxs = case arch
      when "x86_64"
        {
          string: "64-bit",
          program_files_folder: "ProgramFiles64Folder",
          define: "<?define Win64 = \"yes\"?>"
        }
      else
        {
          string: "32-bit",
          program_files_folder: "ProgramFilesFolder",
          define: "<?define Win64 = \"no\"?>"
        }
    end

    <<-EOF
<?xml version='1.0' encoding='utf-8'?>
<Wix xmlns='http://schemas.microsoft.com/wix/2006/wi'>

  #{arch_wxs[:define]}

  <Product
    Name='mruby-cli #{arch_wxs[:string]}'
    Id='F43E56B6-5FF2-450C-B7B7-0B12BF066ABD'
    Version='#{version}'
    Language='1033'
    Manufacturer='mruby-cli'
    UpgradeCode='12268671-59a0-42d3-b1f2-79e52b5657a6'
  >

    <Package InstallerVersion="200" Compressed="yes" Comments="comments" InstallScope="perMachine"/>

    <Media Id="1" Cabinet="cabinet.cab" EmbedCab="yes"/>

    <Directory Id='TARGETDIR' Name='SourceDir'>
      <Directory Id='#{arch_wxs[:program_files_folder]}' Name='PFiles'>
        <Directory Id='INSTALLDIR' Name='mruby-cli'>
          <Component Id='MainExecutable' Guid='3DCA4C4D-205C-4FA4-8BB1-C0BF41CA5EFA'>
            <File Id='mruby-cliEXE' Name='mruby-cli.exe' DiskId='1' Source='mruby-cli.exe' KeyPath='yes'/>
          </Component>
        </Directory>
      </Directory>
    </Directory>

    <Feature Id='Complete' Level='1'>
      <ComponentRef Id='MainExecutable' />
    </Feature>
  </Product>
</Wix>
    EOF
  end

  def info_plist_content(version, arch)
    <<-EOF
<?xml version="1.0" encoding="UTF-8"?>
<!DOCTYPE plist PUBLIC "-//Apple Computer//DTD PLIST 1.0//EN" "http://www.apple.com/DTDs/PropertyList-1.0.dtd">
<plist version="1.0">
<dict>
  <key>CFBundleExecutable</key>
  <string>mruby-cli</string>
  <key>CFBundleGetInfoString</key>
  <string>mruby-cli #{version} #{arch}</string>
  <key>CFBundleName</key>
  <string>mruby-cli</string>
  <key>CFBundleIdentifier</key>
  <string>mruby-cli</string>
  <key>CFBundlePackageType</key>
  <string>APPL</string>
  <key>CFBundleShortVersionString</key>
  <string>#{version}</string>
  <key>CFBundleSignature</key>
  <string>mrbc</string>
  <key>CFBundleInfoDictionaryVersion</key>
  <string>6.0</string>
</dict>
</plist>
    EOF
  end

  def osx_setup_bash_path_script
    <<-EOF
#!/bin/bash
echo "export PATH=$PATH:/Applications/mruby-cli.app/Contents/MacOs" >> $HOME/.bash_profile
source $HOME/.bash_profile
    EOF
  end

  def log(package_dir, version, package)
    puts "Writing packages #{package_dir}/#{version}/#{package}"
  end

  desc "create deb package"
  task :deb => [package_path, :release] do
    abort("fpm is not installed. Please check your docker install.") unless check_fpm_installed?

    ["x86_64", "i686"].each do |arch|
      release_tar_file = "mruby-cli-#{APP_VERSION}-#{arch}-pc-linux-gnu.tgz"
      arch_name = (arch == "x86_64" ? "amd64" : arch)
      log(package_dir, APP_VERSION, "mruby-cli_#{APP_VERSION}_#{arch_name}.deb")
      `fpm -s tar -t deb -a #{arch} -n mruby-cli -v #{APP_VERSION} --prefix /usr/bin -p #{package_path} #{release_path}/#{release_tar_file}`
    end
  end

  desc "create rpm package"
  task :rpm => [package_path, :release] do
    abort("fpm is not installed. Please check your docker install.") unless check_fpm_installed?

    ["x86_64", "i686"].each do |arch|
      release_tar_file = "mruby-cli-#{APP_VERSION}-#{arch}-pc-linux-gnu.tgz"
      log(package_dir, APP_VERSION, "mruby-cli-#{APP_VERSION}-1.#{arch}.rpm")
      `fpm -s tar -t rpm -a #{arch} -n mruby-cli -v #{APP_VERSION} --prefix /usr/bin -p #{package_path} #{release_path}/#{release_tar_file}`
    end
  end

  desc "create msi package"
  task :msi => [package_path, :release] do
    abort("msitools is not installed.  Please check your docker install.") unless check_msi_installed?
    ["x86_64", "i686"].each do |arch|
      log(package_dir, APP_VERSION, "mruby-cli-#{APP_VERSION}-#{arch}.msi")
      release_tar_file = "mruby-cli-#{APP_VERSION}-#{arch}-w64-mingw32.tgz"
      Dir.mktmpdir do |dest_dir|
        cd dest_dir
        `tar -zxf #{release_path}/#{release_tar_file}`
        File.write("mruby-cli-#{APP_VERSION}-#{arch}.wxs", wxs_content(APP_VERSION, arch))
        `wixl -v mruby-cli-#{APP_VERSION}-#{arch}.wxs && mv mruby-cli-#{APP_VERSION}-#{arch}.msi #{package_path}`
      end
    end
  end

  desc "create dmg package"
  task :dmg => [package_path, :release] do
    abort("dmg tools are not installed.  Please check your docker install.") unless check_dmg_installed?
    ["x86_64", "i386"].each do |arch|
      log(package_dir, APP_VERSION, "mruby-cli-#{APP_VERSION}-#{arch}.dmg")
      release_tar_file = "mruby-cli-#{APP_VERSION}-#{arch}-apple-darwin14.tgz"
      Dir.mktmpdir do |dest_dir|
        cd dest_dir
        `tar -zxf #{release_path}/#{release_tar_file}`
        chmod 0755, "mruby-cli"
        mkdir_p "mruby-cli.app/Contents/MacOs"
        mv "mruby-cli", "mruby-cli.app/Contents/MacOs"
        File.write("mruby-cli.app/Contents/Info.plist", info_plist_content(APP_VERSION, arch))
        File.write("add-mruby-cli-to-my-path.sh", osx_setup_bash_path_script)
        chmod 0755, "add-mruby-cli-to-my-path.sh"
        `genisoimage -V mruby-cli -D -r -apple -no-pad -o #{package_path}/mruby-cli-#{APP_VERSION}-#{arch}.dmg #{dest_dir}`
      end
    end
  end
end
     RAKEFILE
   end

   def test_rake
     <<-'RAKEFILE'
# Remove default test task actions from MRuby's Rakefile
Rake::Task['test'].clear

namespace :test do
  desc "run mruby & unit tests"
  # only build mtest for host
  task :mtest => :compile do
    # in order to get mruby/test/t/synatx.rb __FILE__ to pass,
    # we need to make sure the tests are built relative from MRUBY_ROOT
    cd MRUBY_ROOT do
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
    cd MRUBY_ROOT do
      MRuby.each_target do |target|
        clean_env(%w(MRUBY_ROOT MRUBY_CONFIG)) do
          run_bintest if target.bintest_enabled?
        end
      end
    end
  end
end

desc "run all tests"
task :test => ['test:bintest', 'test:mtest']
     RAKEFILE
   end
  end
end
