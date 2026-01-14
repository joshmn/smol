# frozen_string_literal: true

require "test_helper"

class ColorsTest < Minitest::Test
  class RefinementTest < Minitest::Test
    using Smol::Colors

    def test_applies_green_color
      assert_equal "\e[32mtest\e[0m", "test".green
    end

    def test_applies_red_color
      assert_equal "\e[31mtest\e[0m", "test".red
    end

    def test_applies_yellow_color
      assert_equal "\e[33mtest\e[0m", "test".yellow
    end

    def test_applies_bold_style
      assert_equal "\e[1mtest\e[0m", "test".bold
    end

    def test_applies_dim_style
      assert_equal "\e[2mtest\e[0m", "test".dim
    end
  end

  def test_does_not_leak_to_unrefined_scope
    refute_respond_to "test", :green
  end
end
