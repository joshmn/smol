# frozen_string_literal: true

require "test_helper"

class InputTest < Minitest::Test
  def setup
    @output = StringIO.new
    @input = StringIO.new
    Smol.output = @output
    Smol.input = @input
  end

  def teardown
    Smol.output = $stdout
    Smol.input = $stdin
  end

  def test_confirm_returns_true_when_user_answers_yes
    @input.string = "y\n"

    assert Smol::Input.confirm("continue?")
  end

  def test_confirm_returns_false_when_user_answers_no
    @input.string = "n\n"

    refute Smol::Input.confirm("continue?")
  end

  def test_confirm_returns_default_true_when_empty
    @input.string = "\n"

    assert Smol::Input.confirm("continue?", default: true)
  end

  def test_confirm_returns_default_false_when_empty
    @input.string = "\n"

    refute Smol::Input.confirm("continue?", default: false)
  end

  def test_confirm_displays_the_question
    @input.string = "y\n"
    Smol::Input.confirm("are you sure?")

    assert_includes @output.string, "are you sure?"
  end

  def test_ask_returns_user_input
    @input.string = "hello\n"

    assert_equal "hello", Smol::Input.ask("name?")
  end

  def test_ask_returns_default_when_empty
    @input.string = "\n"

    assert_equal "world", Smol::Input.ask("name?", default: "world")
  end

  def test_ask_displays_the_question
    @input.string = "test\n"
    Smol::Input.ask("what is your name?")

    assert_includes @output.string, "what is your name?"
  end

  def test_choose_returns_selected_choice
    @input.string = "2\n"

    assert_equal "b", Smol::Input.choose("pick:", %w[a b c])
  end

  def test_choose_returns_default_choice_when_empty
    @input.string = "\n"

    assert_equal "a", Smol::Input.choose("pick:", %w[a b c], default: 1)
  end

  def test_choose_displays_first_choice
    @input.string = "1\n"
    Smol::Input.choose("pick:", %w[first second third])

    assert_includes @output.string, "first"
  end

  def test_choose_displays_second_choice
    @input.string = "1\n"
    Smol::Input.choose("pick:", %w[first second third])

    assert_includes @output.string, "second"
  end

  def test_choose_displays_third_choice
    @input.string = "1\n"
    Smol::Input.choose("pick:", %w[first second third])

    assert_includes @output.string, "third"
  end
end
