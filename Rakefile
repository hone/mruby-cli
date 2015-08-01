file :mruby do
  sh "git clone --depth=1 https://github.com/mruby/mruby"
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
task :compile => [:mruby, :all] do
  %W(#{MRUBY_ROOT}/build/host/bin/#{APP_NAME} #{MRUBY_ROOT}/build/i686-pc-linux-gnu/#{APP_NAME}").each do |bin|
    sh "strip --strip-unneeded #{bin}" if File.exist?(bin)
  end
end

namespace :test do
  desc "run mruby & unit tests"
  # only build mtest for host
  task :mtest => [:compile] + MRuby.targets.values.map {|t| t.build_mrbtest_lib_only? ? nil : t.exefile("#{t.build_dir}/test/mrbtest") }.compact do
    # in order to get mruby/test/t/synatx.rb __FILE__ to pass,
    # we need to make sure the tests are built relative from MRUBY_ROOT
    load "#{MRUBY_ROOT}/test/mrbtest.rake"
    MRuby.each_target do |target|
      # only run unit tests here
      target.enable_bintest = false
      run_test unless build_mrbtest_lib_only?
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
        run_bintest if bintest_enabled?
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
task :release do
  require 'tmpdir'
  require 'fileutils'
  require_relative 'mrblib/version'

  # since we're in the mruby/
  release_dir  = "releases/v#{MRubyCLI::Version::VERSION}"
  release_path = Dir.pwd + "/../#{release_dir}"
  app_name     = "mruby-cli-#{MRubyCLI::Version::VERSION}"
  FileUtils.mkdir_p(release_path)

  Dir.mktmpdir do |tmp_dir|
    Dir.chdir(tmp_dir) do
      MRuby.each_target do |target|
        arch = name
        bin  = "#{build_dir}/bin/#{exefile(APP_NAME)}"
        FileUtils.mkdir_p(name)
        FileUtils.cp(bin, name)
        if name == "host"
          arch = "x86_64-pc-linux-gnu"
          FileUtils.mv("host", arch)
        end

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
