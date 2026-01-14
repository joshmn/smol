# frozen_string_literal: true

require "test_helper"

class CLITest < Minitest::Test
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

  def test_falls_back_to_repl_with_no_args
    @input.string = "exit\n"

    Smol::CLI.new(@app, prompt: "test", history: false).run([])

    assert_includes @output.string, "test app"
  end

  def test_shows_usage_on_help
    exit_status = nil
    begin
      Smol::CLI.new(@app, prompt: "test").run(["help"])
    rescue SystemExit => e
      exit_status = e.status
    end

    assert_equal 1, exit_status
    assert_includes @output.string, "usage:"
  end

  def test_shows_config_on_config_command
    Smol::CLI.new(@app, prompt: "test").run(["config"])

    assert_includes @output.string, "test_setting"
  end

  def test_exits_with_status_1_for_unknown_command
    exit_status = nil
    begin
      Smol::CLI.new(@app, prompt: "test").run(["unknown"])
    rescue SystemExit => e
      exit_status = e.status
    end

    assert_equal 1, exit_status
  end

  def test_dispatches_to_registered_command
    cmd_class = Class.new(Smol::Command) do
      def call
        info "command ran"
      end
    end
    cmd_class.define_singleton_method(:matches?) { |input| input == "mycmd" }
    cmd_class.define_singleton_method(:args) { [] }
    cmd_class.define_singleton_method(:title) { nil }
    @app.register_command(cmd_class)

    Smol::CLI.new(@app, prompt: "test").run(["mycmd"])

    assert_includes @output.string, "command ran"
  end

  def test_exits_0_when_command_returns_true
    cmd_class = Class.new(Smol::Command) do
      def call
        true
      end
    end
    cmd_class.define_singleton_method(:matches?) { |input| input == "mycmd" }
    cmd_class.define_singleton_method(:args) { [] }
    cmd_class.define_singleton_method(:title) { nil }
    @app.register_command(cmd_class)

    exit_status = nil
    begin
      Smol::CLI.new(@app, prompt: "test").run(["mycmd"])
    rescue SystemExit => e
      exit_status = e.status
    end

    assert_equal 0, exit_status
  end

  def test_exits_1_when_command_returns_false
    cmd_class = Class.new(Smol::Command) do
      def call
        false
      end
    end
    cmd_class.define_singleton_method(:matches?) { |input| input == "mycmd" }
    cmd_class.define_singleton_method(:args) { [] }
    cmd_class.define_singleton_method(:title) { nil }
    @app.register_command(cmd_class)

    exit_status = nil
    begin
      Smol::CLI.new(@app, prompt: "test").run(["mycmd"])
    rescue SystemExit => e
      exit_status = e.status
    end

    assert_equal 1, exit_status
  end
end
