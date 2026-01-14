# frozen_string_literal: true

require "test_helper"

class AppTest < Minitest::Test
  def test_banner_stores_and_returns_banner
    klass = Class.new(Smol::App) do
      banner "welcome"
    end

    assert_equal "welcome", klass.banner
  end

  def test_banner_returns_empty_string_by_default
    klass = Class.new(Smol::App)

    assert_equal "", klass.banner
  end

  def test_config_returns_config_instance
    klass = Class.new(Smol::App)

    assert_kind_of Smol::Config, klass.config
  end

  def test_config_returns_same_instance_on_subsequent_calls
    klass = Class.new(Smol::App)

    assert_same klass.config, klass.config
  end

  def test_commands_returns_empty_array_by_default
    klass = Class.new(Smol::App)

    assert_equal [], klass.commands
  end

  def test_checks_returns_empty_array_by_default
    klass = Class.new(Smol::App)

    assert_equal [], klass.checks
  end

  def test_find_command_finds_by_name
    app = Class.new(Smol::App)
    cmd = Class.new(Smol::Command)
    cmd.define_singleton_method(:matches?) { |input| input == "test" }
    app.register_command(cmd)

    assert_equal cmd, app.find_command("test")
  end

  def test_find_command_returns_nil_when_not_found
    app = Class.new(Smol::App)

    assert_nil app.find_command("missing")
  end

  def test_each_subclass_has_its_own_command_registry
    app1 = Class.new(Smol::App)
    app2 = Class.new(Smol::App)
    cmd = Class.new(Smol::Command)

    app1.register_command(cmd)

    assert_includes app1.commands, cmd
    refute_includes app2.commands, cmd
  end

  def test_each_subclass_has_its_own_check_registry
    app1 = Class.new(Smol::App)
    app2 = Class.new(Smol::App)
    check = Class.new(Smol::Check)

    app1.register_check(check)

    assert_includes app1.checks, check
    refute_includes app2.checks, check
  end

  def test_mount_registers_sub_app
    main_app = Class.new(Smol::App)
    sub_app = Class.new(Smol::App)

    main_app.mount(sub_app, as: "admin")

    assert_equal sub_app, main_app.mounts["admin"]
  end

  def test_find_mount_returns_mounted_app
    main_app = Class.new(Smol::App)
    sub_app = Class.new(Smol::App)
    main_app.mount(sub_app, as: "admin")

    assert_equal sub_app, main_app.find_mount("admin")
  end

  def test_find_mount_returns_nil_for_unknown
    main_app = Class.new(Smol::App)

    assert_nil main_app.find_mount("unknown")
  end

  def test_find_command_delegates_to_mounted_app
    main_app = Class.new(Smol::App)
    sub_app = Class.new(Smol::App)
    cmd = Class.new(Smol::Command)
    cmd.define_singleton_method(:matches?) { |input| input == "users" }

    sub_app.register_command(cmd)
    main_app.mount(sub_app, as: "admin")

    assert_equal cmd, main_app.find_command("admin:users")
  end

  def test_find_command_returns_nil_for_unknown_mounted_command
    main_app = Class.new(Smol::App)
    sub_app = Class.new(Smol::App)
    main_app.mount(sub_app, as: "admin")

    assert_nil main_app.find_command("admin:unknown")
  end

  def test_mounts_returns_empty_hash_by_default
    app = Class.new(Smol::App)

    assert_equal({}, app.mounts)
  end
end
