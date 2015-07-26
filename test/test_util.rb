module MrubyCli
  class TestUtil < MTest::Unit::TestCase
    def test_camelize
      assert_equal "GoodNightMoon", Util.camelize("good_night_moon")
      assert_equal "FooBarBaz", Util.camelize("foo-bar-baz")
    end
  end
end

MTest::Unit.new.run
