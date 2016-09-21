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

  def log(dir, version, package)
    puts "Writing packages #{dir}/#{version}/#{package}"
  end

  desc "create deb package"
  task :deb => [package_path, :release] do
    abort("fpm is not installed. Please check your docker install.") unless check_fpm_installed?

    ["x86_64", "i686"].each do |arch|
      release_tar_file = "mruby-cli-#{APP_VERSION}-#{arch}-pc-linux-gnu.tgz"
      arch_name = (arch == "x86_64" ? "amd64" : arch)
      log(package_path, APP_VERSION, "mruby-cli_#{APP_VERSION}_#{arch_name}.deb")
      `fpm -s tar -t deb -a #{arch} -n mruby-cli -v #{APP_VERSION} --prefix /usr/bin -p #{package_path} #{release_path}/#{release_tar_file}`
    end
  end

  desc "create rpm package"
  task :rpm => [package_path, :release] do
    abort("fpm is not installed. Please check your docker install.") unless check_fpm_installed?

    ["x86_64", "i686"].each do |arch|
      release_tar_file = "mruby-cli-#{APP_VERSION}-#{arch}-pc-linux-gnu.tgz"
      log(package_path, APP_VERSION, "mruby-cli-#{APP_VERSION}-1.#{arch}.rpm")
      `fpm -s tar -t rpm -a #{arch} -n mruby-cli -v #{APP_VERSION} --prefix /usr/bin -p #{package_path} #{release_path}/#{release_tar_file}`
    end
  end

  desc "create msi package"
  task :msi => [package_path, :release] do
    abort("msitools is not installed.  Please check your docker install.") unless check_msi_installed?
    ["x86_64", "i686"].each do |arch|
      log(package_path, APP_VERSION, "mruby-cli-#{APP_VERSION}-#{arch}.msi")
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
      log(package_path, APP_VERSION, "mruby-cli-#{APP_VERSION}-#{arch}.dmg")
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

