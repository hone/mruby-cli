module MrubyCli
  class TestOption < MTest::Unit::TestCase
    def test_to_long_opt_true
      option = Option.new("setup", "s", true)

      assert_equal "setup:", option.to_long_opt
    end

    def test_to_short_opt_true
      option = Option.new("setup", "s", true)

      assert_equal "s:", option.to_short_opt
    end

    def test_to_long_opt_false
      option = Option.new("version", "v")

      assert_equal "version", option.to_long_opt
    end

    def test_to_short_opt_false
      option = Option.new("version", "v")

      assert_equal "v", option.to_short_opt
    end
  end
end

MTest::Unit.new.run
