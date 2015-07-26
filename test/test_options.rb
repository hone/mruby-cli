module MRubyCLI
  class TestOptions < MTest::Unit::TestCase
    def test_add
      options = Options.new
      options.add(Option.new("setup", "s", true))
      options.add(Option.new("version", "v", false))

      assert_equal %w(setup: version), options.long_opts
      assert_equal "s:v", options.short_opts
    end

    def test_option
      options = Options.new
      options.add(Option.new("setup", "s", true))
      options.add(Option.new("version", "v", false))

      options.parsed_opts = {"setup" => "foo"}
      assert_equal "foo", options.option(:setup)

      options.parsed_opts = {"s" => "foo"}
      assert_equal "foo", options.option(:setup)

      options.parsed_opts = {"version" => ""}
      assert_equal "", options.option(:version)

      options.parsed_opts = {"v" => ""}
      assert_equal "", options.option(:version)

      options.parsed_opts = {"v" => ""}
      assert_equal false, options.option(:setup)

      options.parsed_opts = {"v" => ""}
      assert_equal nil, options.option(:blah)
    end
  end
end

MTest::Unit.new.run
