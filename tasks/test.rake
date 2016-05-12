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

