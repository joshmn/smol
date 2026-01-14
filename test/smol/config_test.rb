# frozen_string_literal: true

require "test_helper"

class ConfigTest < Minitest::Test
  def test_setting_registers_with_default_value
    config = Smol::Config.new
    config.setting :foo, default: "bar"

    assert_equal "bar", config[:foo]
  end

  def test_setting_registers_with_description
    config = Smol::Config.new
    config.setting :foo, default: "bar", desc: "the foo setting"

    assert_equal "the foo setting", config.settings[:foo][:desc]
  end

  def test_returns_default_value_when_env_not_set
    config = Smol::Config.new
    config.setting :test_key, default: "default_value"

    assert_equal "default_value", config[:test_key]
  end

  def test_returns_env_value_when_set
    ENV["TEST_KEY"] = "env_value"
    config = Smol::Config.new
    config.setting :test_key, default: "default_value"

    assert_equal "env_value", config[:test_key]
  ensure
    ENV.delete("TEST_KEY")
  end

  def test_raises_for_unknown_key
    config = Smol::Config.new

    error = assert_raises(ArgumentError) { config[:unknown] }
    assert_match(/unknown config key/, error.message)
  end

  def test_caches_the_value
    config = Smol::Config.new
    config.setting :cached, default: "first"

    config[:cached]
    config.instance_variable_get(:@settings)[:cached][:default] = "changed"

    assert_equal "first", config[:cached]
  end

  def test_coerces_to_integer
    config = Smol::Config.new
    config.setting :port, default: "3000", type: :integer

    assert_equal 3000, config[:port]
  end

  def test_coerces_to_boolean_true
    config = Smol::Config.new
    config.setting :enabled, default: "true", type: :boolean

    assert_equal true, config[:enabled]
  end

  def test_coerces_to_boolean_false
    config = Smol::Config.new
    config.setting :enabled, default: "false", type: :boolean

    assert_equal false, config[:enabled]
  end

  def test_accepts_1_as_boolean_true
    config = Smol::Config.new
    config.setting :enabled, default: "1", type: :boolean

    assert_equal true, config[:enabled]
  end

  def test_accepts_yes_as_boolean_true
    config = Smol::Config.new
    config.setting :enabled, default: "yes", type: :boolean

    assert_equal true, config[:enabled]
  end

  def test_set_overrides_cached_value
    config = Smol::Config.new
    config.setting :foo, default: "bar"
    config[:foo]

    config.set(:foo, "baz")

    assert_equal "baz", config[:foo]
  end

  def test_set_coerces_the_type
    config = Smol::Config.new
    config.setting :port, default: 3000, type: :integer

    config.set(:port, "8080")

    assert_equal 8080, config[:port]
  end

  def test_set_raises_for_unknown_key
    config = Smol::Config.new

    assert_raises(ArgumentError) { config.set(:unknown, "value") }
  end

  def test_to_h_returns_hash_of_all_settings
    config = Smol::Config.new
    config.setting :one, default: "1"
    config.setting :two, default: "2"

    assert_equal({ one: "1", two: "2" }, config.to_h)
  end

  def test_each_yields_key_value_and_setting_info
    config = Smol::Config.new
    config.setting :foo, default: "bar", desc: "description"

    yielded = []
    config.each { |k, v, s| yielded << [k, v, s] }

    assert_equal 1, yielded.size
    assert_equal :foo, yielded.first[0]
    assert_equal "bar", yielded.first[1]
    assert_equal "description", yielded.first[2][:desc]
  end

  def test_each_returns_enumerator_when_no_block_given
    config = Smol::Config.new

    assert_kind_of Enumerator, config.each
  end
end
