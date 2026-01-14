# frozen_string_literal: true

require "test_helper"

class CommandTest < Minitest::Test
  def test_command_name_derives_from_class_name
    klass = Class.new(Smol::Command)
    stub_name(klass, "TestModule::RunTests")

    assert_equal "run_tests", klass.command_name
  end

  def test_command_name_accepts_explicit_name
    klass = Class.new(Smol::Command) do
      command_name "custom:name"
    end

    assert_equal "custom:name", klass.command_name
  end

  def test_title_stores_and_returns_title
    klass = Class.new(Smol::Command) do
      title "my title"
    end

    assert_equal "my title", klass.title
  end

  def test_explain_stores_and_returns_explanation
    klass = Class.new(Smol::Command) do
      explain "does the thing"
    end

    assert_equal "does the thing", klass.explain
  end

  def test_aliases_stores_and_returns_aliases
    klass = Class.new(Smol::Command) do
      aliases :r, :run
    end

    assert_equal [:r, :run], klass.aliases
  end

  def test_aliases_returns_empty_array_by_default
    klass = Class.new(Smol::Command)

    assert_equal [], klass.aliases
  end

  def test_args_stores_and_returns_args
    klass = Class.new(Smol::Command) do
      args :name, :value
    end

    assert_equal [:name, :value], klass.args
  end

  def test_args_returns_empty_array_by_default
    klass = Class.new(Smol::Command)

    assert_equal [], klass.args
  end

  def test_desc_stores_and_returns_description
    klass = Class.new(Smol::Command) do
      desc "short description"
    end

    assert_equal "short description", klass.desc
  end

  def test_desc_returns_empty_string_by_default
    klass = Class.new(Smol::Command)

    assert_equal "", klass.desc
  end

  def test_group_stores_and_returns_group
    klass = Class.new(Smol::Command) do
      group "admin"
    end

    assert_equal "admin", klass.group
  end

  def test_group_returns_nil_by_default
    klass = Class.new(Smol::Command)

    assert_nil klass.group
  end

  def test_matches_command_name
    klass = Class.new(Smol::Command)
    stub_name(klass, "TestModule::Deploy")

    assert klass.matches?("deploy")
  end

  def test_matches_aliases
    klass = Class.new(Smol::Command) do
      aliases :d, :dep
    end
    stub_name(klass, "TestModule::Deploy")

    assert klass.matches?("d")
    assert klass.matches?("dep")
  end

  def test_does_not_match_unrelated_input
    klass = Class.new(Smol::Command)
    stub_name(klass, "TestModule::Deploy")

    refute klass.matches?("other")
  end

  def test_usage_includes_command_name
    klass = Class.new(Smol::Command)
    stub_name(klass, "TestModule::Deploy")

    assert_equal "deploy", klass.usage
  end

  def test_usage_includes_args_in_angle_brackets
    klass = Class.new(Smol::Command) do
      args :env, :version
    end
    stub_name(klass, "TestModule::Deploy")

    assert_equal "deploy <env> <version>", klass.usage
  end

  private

  def stub_name(klass, name)
    klass.define_singleton_method(:name) { name }
  end
end

class CommandRescueFromTest < Minitest::Test
  def setup
    @output = StringIO.new
    Smol.output = @output
  end

  def teardown
    Smol.output = $stdout
  end

  def test_block_handler_does_not_raise
    klass = Class.new(Smol::Command) do
      rescue_from ArgumentError do |e|
        failure "caught: #{e.message}"
      end

      def call
        raise ArgumentError, "bad arg"
      end
    end

    klass.new.call
  end

  def test_block_handler_executes_handler
    klass = Class.new(Smol::Command) do
      rescue_from ArgumentError do |e|
        failure "caught: #{e.message}"
      end

      def call
        raise ArgumentError, "bad arg"
      end
    end

    klass.new.call

    assert_includes @output.string, "caught: bad arg"
  end

  def test_method_handler_does_not_raise
    klass = Class.new(Smol::Command) do
      rescue_from RuntimeError, with: :handle_error

      def call
        raise RuntimeError, "oops"
      end

      def handle_error(e)
        failure "handled: #{e.message}"
      end
    end

    klass.new.call
  end

  def test_method_handler_executes_handler
    klass = Class.new(Smol::Command) do
      rescue_from RuntimeError, with: :handle_error

      def call
        raise RuntimeError, "oops"
      end

      def handle_error(e)
        failure "handled: #{e.message}"
      end
    end

    klass.new.call

    assert_includes @output.string, "handled: oops"
  end

  def test_re_raises_unhandled_exceptions
    klass = Class.new(Smol::Command) do
      rescue_from ArgumentError do
        failure "caught"
      end

      def call
        raise RuntimeError, "not caught"
      end
    end

    assert_raises(RuntimeError) { klass.new.call }
  end
end

class CommandBeforeAfterActionTest < Minitest::Test
  def setup
    @output = StringIO.new
    Smol.output = @output
  end

  def teardown
    Smol.output = $stdout
  end

  def test_before_action_runs_before_call
    klass = Class.new(Smol::Command) do
      before_action :setup_stuff

      def call
        info "main"
      end

      def setup_stuff
        info "before"
      end
    end

    klass.new.call

    assert_match(/before.*main/m, @output.string)
  end

  def test_before_action_receives_args
    klass = Class.new(Smol::Command) do
      before_action :check_env

      def call(env)
        info "deploying to #{env}"
      end

      def check_env(env)
        info "checking #{env}"
      end
    end

    klass.new.call("production")

    assert_includes @output.string, "checking production"
  end

  def test_before_action_halts_on_false
    klass = Class.new(Smol::Command) do
      before_action :check_auth

      def call
        info "should not run"
      end

      def check_auth
        info "denied"
        false
      end
    end

    klass.new.call

    assert_includes @output.string, "denied"
    refute_includes @output.string, "should not run"
  end

  def test_after_action_runs_after_call
    klass = Class.new(Smol::Command) do
      after_action :cleanup

      def call
        info "main"
      end

      def cleanup(result:)
        info "after"
      end
    end

    klass.new.call

    assert_match(/main.*after/m, @output.string)
  end

  def test_after_action_receives_result
    klass = Class.new(Smol::Command) do
      after_action :log_result

      def call
        "success"
      end

      def log_result(result:)
        info "result: #{result}"
      end
    end

    klass.new.call

    assert_includes @output.string, "result: success"
  end

  def test_after_action_skipped_when_before_halts
    klass = Class.new(Smol::Command) do
      before_action :halt_early
      after_action :should_not_run

      def call
        info "main"
      end

      def halt_early
        false
      end

      def should_not_run(result:)
        info "after ran"
      end
    end

    klass.new.call

    refute_includes @output.string, "after ran"
  end
end

class CommandOptionsTest < Minitest::Test
  def test_option_registers_option
    klass = Class.new(Smol::Command) do
      option :env, short: :e, default: "development", desc: "environment"
    end

    assert_equal :e, klass.options[:env][:short]
    assert_equal "development", klass.options[:env][:default]
  end

  def test_parse_options_extracts_long_option
    klass = Class.new(Smol::Command) do
      option :env, default: "dev"
    end

    positional, opts = klass.parse_options(["--env=production"])

    assert_equal [], positional
    assert_equal "production", opts[:env]
  end

  def test_parse_options_extracts_short_option
    klass = Class.new(Smol::Command) do
      option :env, short: :e, default: "dev"
    end

    positional, opts = klass.parse_options(["-e", "staging"])

    assert_equal [], positional
    assert_equal "staging", opts[:env]
  end

  def test_parse_options_preserves_positional_args
    klass = Class.new(Smol::Command) do
      option :verbose, short: :v, type: :boolean, default: false
    end

    positional, opts = klass.parse_options(["deploy", "-v", "true", "extra"])

    assert_equal ["deploy", "extra"], positional
    assert_equal true, opts[:verbose]
  end

  def test_parse_options_uses_defaults
    klass = Class.new(Smol::Command) do
      option :env, default: "development"
      option :timeout, default: 30, type: :integer
    end

    _, opts = klass.parse_options([])

    assert_equal "development", opts[:env]
    assert_equal 30, opts[:timeout]
  end

  def test_parse_options_coerces_integer
    klass = Class.new(Smol::Command) do
      option :port, type: :integer, default: 3000
    end

    _, opts = klass.parse_options(["--port=8080"])

    assert_equal 8080, opts[:port]
  end

  def test_parse_options_coerces_boolean
    klass = Class.new(Smol::Command) do
      option :verbose, type: :boolean, default: false
    end

    _, opts = klass.parse_options(["--verbose=true"])

    assert_equal true, opts[:verbose]
  end

  def test_usage_includes_options
    klass = Class.new(Smol::Command) do
      args :name
      option :env, short: :e
    end
    klass.define_singleton_method(:name) { "Test::Deploy" }

    assert_includes klass.usage, "<name>"
    assert_includes klass.usage, "[-e/--env]"
  end

  def test_options_passed_to_call
    output = StringIO.new
    Smol.output = output

    klass = Class.new(Smol::Command) do
      option :env, default: "dev"

      def call(env:)
        info "env: #{env}"
      end
    end

    klass.new.call(env: "production")

    assert_includes output.string, "env: production"
  ensure
    Smol.output = $stdout
  end
end
