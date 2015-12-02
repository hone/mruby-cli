require 'open3'
require 'tmpdir'

BIN_PATH = File.join(File.dirname(__FILE__), "../mruby/bin/mruby-cli")

assert('setup') do
  Dir.mktmpdir do |tmp_dir|
    Dir.chdir(tmp_dir) do
      app_name = "new_cli"
      output, status = Open3.capture2(BIN_PATH, "setup", app_name)

      assert_true status.success?, "Process did not exit cleanly"
      assert_true Dir.exist?(app_name)
      Dir.chdir(app_name) do
        (%w(.gitignore mrbgem.rake build_config.rb Rakefile Dockerfile docker-compose.yml) + ["tools/#{app_name}/#{app_name}.c", "mrblib/#{app_name}.rb", "bintest/#{app_name}.rb"]).each do |file|
          assert_true(File.exist?(file), "Could not find #{file}")
          assert_include output, " create  #{file}"
        end
      end
    end
  end
end

assert('setup can compile and run the generated app') do
  Dir.mktmpdir do |tmp_dir|
    Dir.chdir(tmp_dir) do
      app_name = "hello_world"
      Open3.capture2(BIN_PATH, "setup", app_name)

      Dir.chdir(app_name) do
        output, status = Open3.capture2("rake compile")
        assert_true status.success?, "`rake compile` did not exit cleanly"

        output, status = Open3.capture2("mruby/bin/#{app_name}")
        assert_true status.success?, "`#{app_name}` did not exit cleanly"
        assert_include output, "Hello World"

        %w(x86_64-pc-linux-gnu i686-pc-linux-gnu).each do |host|
          output, status = Open3.capture2("file mruby/build/x86_64-pc-linux-gnu/bin/#{app_name}")
          assert_include output, ", stripped"
        end

        output, status = Open3.capture2("rake test:bintest")
        assert_true status.success?, "`rake test:bintest` did not exit cleanly"

        output, status = Open3.capture2("rake test:mtest")
        assert_true status.success?, "`rake test:mtest` did not exit cleanly"
        assert_false output.include?("Error:"), "mtest has errors"
        assert_false output.include?("Failure:"), "mtest has failures"
      end
    end
  end
end

assert('version') do
  require_relative '../mrblib/mruby-cli/version'
  output, status = Open3.capture2(BIN_PATH, "--version")
  assert_true status.success?, "Process did not exit cleanly"
  assert_include output, "mruby-cli version #{MRubyCLI::Version::VERSION}"
end

assert('help') do
  output, status = Open3.capture2(BIN_PATH, "--help")
  assert_true status.success?, "Process did not exit cleanly"
  assert_include output, "Create your own cli application."
end
