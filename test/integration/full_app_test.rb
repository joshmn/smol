# frozen_string_literal: true

require "test_helper"

class FullAppIntegrationTest < Minitest::Test
  def setup
    @output = StringIO.new
    @input = StringIO.new
    Smol.output = @output
    Smol.input = @input

    build_sample_app
  end

  def teardown
    Smol.output = $stdout
    Smol.input = $stdin
    Object.send(:remove_const, :IntegrationTestApp) if defined?(IntegrationTestApp)
  end

  def test_registers_hello_command
    assert_includes IntegrationTestApp::App.commands, IntegrationTestApp::Commands::Hello
  end

  def test_registers_preflight_command
    assert_includes IntegrationTestApp::App.commands, IntegrationTestApp::Commands::Preflight
  end

  def test_registers_always_pass_check
    assert_includes IntegrationTestApp::App.checks, IntegrationTestApp::Checks::AlwaysPass
  end

  def test_registers_always_fail_check
    assert_includes IntegrationTestApp::App.checks, IntegrationTestApp::Checks::AlwaysFail
  end

  def test_runs_command_with_args
    cmd = IntegrationTestApp::Commands::Hello.new
    cmd.call("world")

    assert_includes @output.string, "hello, world!"
  end

  def test_displays_title_when_set
    cmd = IntegrationTestApp::Commands::Hello.new
    cmd.call("test")

    assert_includes @output.string, "hello command"
  end

  def test_displays_explain_when_set
    cmd = IntegrationTestApp::Commands::Hello.new
    cmd.call("test")

    assert_includes @output.string, "says hello to someone"
  end

  def test_passing_check_returns_passed
    result = IntegrationTestApp::Checks::AlwaysPass.new.call

    assert result.passed?
  end

  def test_passing_check_includes_message
    result = IntegrationTestApp::Checks::AlwaysPass.new.call

    assert_equal "everything is fine", result.message
  end

  def test_failing_check_returns_failed
    result = IntegrationTestApp::Checks::AlwaysFail.new.call

    assert result.failed?
  end

  def test_failing_check_includes_message
    result = IntegrationTestApp::Checks::AlwaysFail.new.call

    assert_equal "something is wrong", result.message
  end

  def test_run_checks_shows_pass_status
    IntegrationTestApp::Commands::Preflight.new.call

    assert_includes @output.string, "pass"
  end

  def test_run_checks_shows_summary
    IntegrationTestApp::Commands::Preflight.new.call

    assert_includes @output.string, "all checks passed"
  end

  def test_finds_command_by_name
    assert_equal IntegrationTestApp::Commands::Hello, IntegrationTestApp::App.find_command("hello")
  end

  def test_finds_command_by_hi_alias
    assert_equal IntegrationTestApp::Commands::Hello, IntegrationTestApp::App.find_command("hi")
  end

  def test_finds_command_by_h_alias
    assert_equal IntegrationTestApp::Commands::Hello, IntegrationTestApp::App.find_command("h")
  end

  def test_commands_can_access_app_config
    show_config = Class.new(Smol::Command) do
      def call
        info "db: #{config[:database]}"
      end
    end
    show_config.define_singleton_method(:name) { "IntegrationTestApp::Commands::ShowConfig" }

    cmd = show_config.new
    cmd.call

    assert_includes @output.string, "db: mydb"
  end

  def test_config_set_updates_value
    Smol::CLI.new(IntegrationTestApp::App, prompt: "sample").run(["config:set", "database", "newdb"])

    assert_equal "newdb", IntegrationTestApp::App.config[:database]
  end

  def test_config_set_outputs_confirmation
    Smol::CLI.new(IntegrationTestApp::App, prompt: "sample").run(["config:set", "database", "newdb"])

    assert_includes @output.string, "database = newdb"
  end

  def test_command_dsl_methods_work
    cmd = IntegrationTestApp::Commands::Hello

    assert_equal "hello command", cmd.title
    assert_equal "says hello to someone", cmd.explain
    assert_equal [:hi, :h], cmd.aliases
    assert_equal [:name], cmd.args
    assert_equal "greet someone", cmd.desc
  end

  def test_command_matches_by_name
    assert IntegrationTestApp::Commands::Hello.matches?("hello")
  end

  def test_command_matches_by_alias
    assert IntegrationTestApp::Commands::Hello.matches?("hi")
    assert IntegrationTestApp::Commands::Hello.matches?("h")
  end

  def test_command_usage_includes_args
    assert_equal "hello <name>", IntegrationTestApp::Commands::Hello.usage
  end

  private

  def build_sample_app
    # Create module first
    Object.const_set(:IntegrationTestApp, Module.new)

    # Define App - this sets up IntegrationTestApp.register_command and register_check
    IntegrationTestApp.const_set(:App, Class.new(Smol::App) do
      banner "sample app v1"
      config.setting :database, default: "mydb", desc: "database name"
      config.setting :timeout, default: 30, type: :integer, desc: "timeout in seconds"
    end)

    # Define checks module and classes - should auto-register to IntegrationTestApp::App
    IntegrationTestApp.const_set(:Checks, Module.new)

    IntegrationTestApp::Checks.const_set(:AlwaysPass, Class.new(Smol::Check) do
      def call
        pass "everything is fine"
      end
    end)

    IntegrationTestApp::Checks.const_set(:AlwaysFail, Class.new(Smol::Check) do
      def call
        fail "something is wrong"
      end
    end)

    # Define commands module and classes - should auto-register to IntegrationTestApp::App
    IntegrationTestApp.const_set(:Commands, Module.new)

    IntegrationTestApp::Commands.const_set(:Hello, Class.new(Smol::Command) do
      title "hello command"
      explain "says hello to someone"
      aliases :hi, :h
      args :name
      desc "greet someone"

      def call(name)
        info "hello, #{name}!"
      end
    end)

    IntegrationTestApp::Commands.const_set(:Preflight, Class.new(Smol::Command) do
      title "preflight checks"
      desc "run all checks"

      def call
        all_passed = run_checks(IntegrationTestApp::Checks::AlwaysPass)
        checks_passed?(all_passed)
      end
    end)

    # Manual registration required because const_set assigns the class name AFTER
    # Class.new evaluates, so the inherited hook can't find the app to register to.
    # Auto-registration works with normal class definitions (class Foo < Smol::Command).
    IntegrationTestApp::App.register_command(IntegrationTestApp::Commands::Hello)
    IntegrationTestApp::App.register_command(IntegrationTestApp::Commands::Preflight)
    IntegrationTestApp::App.register_check(IntegrationTestApp::Checks::AlwaysPass)
    IntegrationTestApp::App.register_check(IntegrationTestApp::Checks::AlwaysFail)
  end
end
