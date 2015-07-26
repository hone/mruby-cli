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

desc "compile binary"
task :compile => [:mruby, :all] do
  %W(#{MRUBY_ROOT}/build/host/bin/#{APP_NAME} #{MRUBY_ROOT}/build/i686-pc-linux-gnu/#{APP_NAME}").each do |bin|
    sh "strip --strip-unneeded #{bin}" if File.exist?(bin)
  end
end

namespace :test do
  desc "run mruby & unit tests"
  # only build mtest for host
  task :mtest => [:compile] + MRuby.targets.values.map {|t| t.build_mrbtest_lib_only? ? nil : t.exefile("#{t.build_dir}/test/mrbtest") }.compact do
    # mruby-io tests expect to be in MRUBY_ROOT
    Dir.chdir(MRUBY_ROOT) do
      # in order to get mruby/test/t/synatx.rb __FILE__ to pass,
      # we need to make sure the tests are built relative from MRUBY_ROOT
      load "#{MRUBY_ROOT}/test/mrbtest.rake"
      MRuby.each_target do |target|
        # only run unit tests here
        target.enable_bintest = false
        run_test unless build_mrbtest_lib_only?
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
  sh "cd #{MRUBY_ROOT} && rake deep_clean"
end
