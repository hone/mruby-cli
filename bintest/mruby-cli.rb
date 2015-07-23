require 'open3'
require 'tmpdir'

BIN_PATH = File.join(File.dirname(__FILE__), "../mruby/bin/mruby-cli")

assert('setup') do
  Dir.mktmpdir do |tmp_dir|
    Dir.chdir(tmp_dir) do
      app_name = "new_cli"
      output, status = Open3.capture2("#{BIN_PATH}", "--setup", app_name)

      assert_true status.success?, "Process did not exit cleanly"
      assert_true Dir.exist?(app_name)
      Dir.chdir(app_name) do
        (%w(mrbgem.rake build_config.rb Rakefile Dockerfile docker-compose.yml) + ["tools/#{app_name}/#{app_name}.c", "mrblib/#{app_name}.rb", "bintest/#{app_name}.rb"]).each do |file|
          assert_true(File.exist?(file), "Could not find #{file}")
        end
      end
    end
  end
end

assert('setup can compile and run the generated app') do
  Dir.mktmpdir do |tmp_dir|
    Dir.chdir(tmp_dir) do
      app_name = "hello_world"
      Open3.capture2("#{BIN_PATH}", "--setup", app_name)

      Dir.chdir(app_name) do
        output, status = Open3.capture2("rake compile")
        assert_true status.success?, "Process did not exit cleanly"
        
        output, status = Open3.capture2("mruby/bin/#{app_name}")
        assert_true status.success?, "Process did not exit cleanly"
        assert_include output, "Hello World"

        output, status = Open3.capture2("rake test:bintest")
        assert_true status.success?, "Process did not exit cleanly"
      end
    end
  end
end

assert('version') do
  require_relative '../mrblib/version'
  output, status = Open3.capture2("#{BIN_PATH}", "--version")
  assert_true status.success?, "Process did not exit cleanly"
  assert_include output, "mruby-cli version #{MrubyCli::Version::VERSION}"
end
