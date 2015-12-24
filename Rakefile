require 'fileutils'

MRUBY_VERSION="1.2.0"

file :mruby do
  #sh "git clone --depth=1 https://github.com/mruby/mruby"
  sh "curl -L --fail --retry 3 --retry-delay 1 https://github.com/mruby/mruby/archive/#{MRUBY_VERSION}.tar.gz -s -o - | tar zxf -"
  FileUtils.mv("mruby-#{MRUBY_VERSION}", "mruby")
end

APP_NAME=ENV["APP_NAME"] || "mruby-cli"
APP_ROOT=ENV["APP_ROOT"] || Dir.pwd
# avoid redefining constants in mruby Rakefile
mruby_root=File.expand_path(ENV["MRUBY_ROOT"] || "#{APP_ROOT}/mruby")
mruby_config=File.expand_path(ENV["MRUBY_CONFIG"] || "build_config.rb")
ENV['MRUBY_ROOT'] = mruby_root
ENV['MRUBY_CONFIG'] = mruby_config
Rake::Task[:mruby].invoke unless Dir.exist?(mruby_root)
Dir.chdir(mruby_root)
load "#{mruby_root}/Rakefile"

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
  require_relative 'mrblib/mruby-cli/version'

  # since we're in the mruby/
  release_dir  = "releases/v#{MRubyCLI::Version::VERSION}"
  release_path = Dir.pwd + "/../#{release_dir}"
  app_name     = "mruby-cli-#{MRubyCLI::Version::VERSION}"
  FileUtils.mkdir_p(release_path)

  Dir.mktmpdir do |tmp_dir|
    Dir.chdir(tmp_dir) do
      MRuby.each_target do |target|
        next if name == "host"

        arch = name
        bin  = "#{build_dir}/bin/#{exefile(APP_NAME)}"
        FileUtils.mkdir_p(name)
        FileUtils.cp(bin, name)

        Dir.chdir(arch) do
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
  desc "show help"
  task :version do
    require_relative 'mrblib/mruby-cli/version'
    puts "mruby-cli #{MRubyCLI::Version::VERSION}"
  end

  def clone_mruby_cli_bins
    Dir.chdir(APP_ROOT) do
      `git clone git@github.com:toch/mruby-cli-bins.git`
      return "#{APP_ROOT}/mruby-cli-bins" if $?.success?
    end
    nil
  end

  def detect_current_branch
    return nil unless ENV.key? 'TRAVIS'
    return ENV['TRAVIS_BRANCH'] if ENV['TRAVIS_PULL_REQUEST'] == "false"
    nil
  end

  SUPPORTED_TARGET = {
    "linux" => "x86_64-pc-linux-gnu",
    "osx" => "x86_64-apple-darwin14",
    "win" => "x86_64-w64-mingw32"
  }

  def push_mruby_cli_bins(dir, branch)
    Dir.chdir(dir) do
      `git checkout -B #{branch}`
      SUPPORTED_TARGET.each do |target, dir|
        bin_dir = "#{APP_ROOT}/mruby/build/#{dir}/bin"
        bin_file = "mruby-cli"
        bin_file << ".exe" if target == "win"
        `cp #{bin_dir}/#{bin_file} #{dir}/bin/`
        `git add #{dir}/bin/#{bin_file}`
      end
      `git commit -m "Travis Build #{ENV['TRAVIS_BUILD_NUMBER']} on branch #{branch}"`
      `git push origin #{branch}`
    end
  end

  desc "prepare the bins and send them to mruby-cli-bins"
  task :send_bins_for_test do
    mruby_cli_bins_dir = clone_mruby_cli_bins
    abort "[send bins for test] impossible to clone mruby-cli-bins" unless mruby_cli_bins_dir
    current_branch = detect_current_branch
    abort "[send bins for test] impossible to detect current branch" unless current_branch
    push_mruby_cli_bins(mruby_cli_bins_dir, current_branch)
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

namespace :package do
  require 'fileutils'
  require 'tmpdir'
  require_relative "#{MRUBY_ROOT}/../mrblib/mruby-cli/version"

  version = MRubyCLI::Version::VERSION
  release_dir = "releases/v#{version}"
  package_dir = "packages/v#{version}"
  release_path = Dir.pwd + "/../#{release_dir}"
  package_path = Dir.pwd + "/../#{package_dir}"
  FileUtils.mkdir_p(package_path)

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
  task :deb => [:release] do
    abort("fpm is not installed. Please check your docker install.") unless check_fpm_installed?

    ["x86_64", "i686"].each do |arch|
      release_tar_file = "mruby-cli-#{version}-#{arch}-pc-linux-gnu.tgz"
      arch_name = (arch == "x86_64" ? "amd64" : arch)
      log(package_dir, version, "mruby-cli_#{version}_#{arch_name}.deb")
      `fpm -s tar -t deb -a #{arch} -n mruby-cli -v #{version} --prefix /usr/bin -p #{package_path} #{release_path}/#{release_tar_file}`
    end
  end

  desc "create rpm package"
  task :rpm => [:release] do
    abort("fpm is not installed. Please check your docker install.") unless check_fpm_installed?

    ["x86_64", "i686"].each do |arch|
      release_tar_file = "mruby-cli-#{version}-#{arch}-pc-linux-gnu.tgz"
      log(package_dir, version, "mruby-cli-#{version}-1.#{arch}.rpm")
      `fpm -s tar -t rpm -a #{arch} -n mruby-cli -v #{version} --prefix /usr/bin -p #{package_path} #{release_path}/#{release_tar_file}`
    end
  end

  desc "create msi package"
  task :msi => [:release] do
    abort("msitools is not installed.  Please check your docker install.") unless check_msi_installed?
    ["x86_64", "i686"].each do |arch|
      log(package_dir, version, "mruby-cli-#{version}-#{arch}.msi")
      release_tar_file = "mruby-cli-#{version}-#{arch}-w64-mingw32.tgz"
      Dir.mktmpdir do |dest_dir|
        Dir.chdir dest_dir
        `tar -zxf #{release_path}/#{release_tar_file}`
        File.write("mruby-cli-#{version}-#{arch}.wxs", wxs_content(version, arch))
        `wixl -v mruby-cli-#{version}-#{arch}.wxs && mv mruby-cli-#{version}-#{arch}.msi #{package_path}`
      end
    end
  end

  desc "create dmg package"
  task :dmg => [:release] do
    abort("dmg tools are not installed.  Please check your docker install.") unless check_dmg_installed?
    ["x86_64", "i386"].each do |arch|
      log(package_dir, version, "mruby-cli-#{version}-#{arch}.dmg")
      release_tar_file = "mruby-cli-#{version}-#{arch}-apple-darwin14.tgz"
      Dir.mktmpdir do |dest_dir|
        Dir.chdir dest_dir
        `tar -zxf #{release_path}/#{release_tar_file}`
        FileUtils.chmod 0755, "mruby-cli"
        FileUtils.mkdir_p "mruby-cli.app/Contents/MacOs"
        FileUtils.mv "mruby-cli", "mruby-cli.app/Contents/MacOs"
        File.write("mruby-cli.app/Contents/Info.plist", info_plist_content(version, arch))
        File.write("add-mruby-cli-to-my-path.sh", osx_setup_bash_path_script)
        FileUtils.chmod 0755, "add-mruby-cli-to-my-path.sh"
        `genisoimage -V mruby-cli -D -r -apple -no-pad -o #{package_path}/mruby-cli-#{version}-#{arch}.dmg #{dest_dir}`
      end
    end
  end

end

desc "create all packages"
task :package => ["package:deb", "package:rpm", "package:msi", "package:dmg"]

