# frozen_string_literal: true

require "test_helper"

class REPLTest < Minitest::Test
  def setup
    @output = StringIO.new
    @input = StringIO.new
    Smol.output = @output
    Smol.input = @input
    @app = Class.new(Smol::App) do
      banner "test app"
      config.setting :test_setting, default: "value", desc: "a setting"
    end
  end

  def teardown
    Smol.output = $stdout
    Smol.input = $stdin
  end

  def test_displays_banner_on_start
    @input.string = "exit\n"

    Smol::REPL.new(@app, prompt: "test", history: false).run

    assert_includes @output.string, "test app"
  end

  def test_displays_prompt
    @input.string = "exit\n"

    Smol::REPL.new(@app, prompt: "myapp", history: false).run

    assert_includes @output.string, "myapp>"
  end

  def test_exits_on_exit_command
    @input.string = "exit\n"

    Smol::REPL.new(@app, prompt: "test", history: false).run
  end

  def test_exits_on_quit_command
    @input.string = "quit\n"

    Smol::REPL.new(@app, prompt: "test", history: false).run
  end

  def test_exits_on_q_command
    @input.string = "q\n"

    Smol::REPL.new(@app, prompt: "test", history: false).run
  end

  def test_shows_help_on_help_command
    @input.string = "help\nexit\n"

    Smol::REPL.new(@app, prompt: "test", history: false).run

    assert_includes @output.string, "commands:"
  end

  def test_shows_config_on_config_command
    @input.string = "config\nexit\n"

    Smol::REPL.new(@app, prompt: "test", history: false).run

    assert_includes @output.string, "test_setting"
  end

  def test_shows_warning_for_unknown_command
    @input.string = "unknown_cmd\nexit\n"

    Smol::REPL.new(@app, prompt: "test", history: false).run

    assert_includes @output.string, "unknown command"
  end

  def test_accepts_custom_history_file_path
    repl = Smol::REPL.new(@app, prompt: "test", history: false, history_file: "/tmp/custom_history")

    assert_equal "/tmp/custom_history", repl.instance_variable_get(:@history_file)
  end

  def test_uses_default_history_file_when_not_specified
    repl = Smol::REPL.new(@app, prompt: "test", history: false)

    assert_equal File.expand_path("~/.smol_test_history"), repl.instance_variable_get(:@history_file)
  end
end
