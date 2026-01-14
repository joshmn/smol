# frozen_string_literal: true

require "test_helper"

class CheckTest < Minitest::Test
  def test_check_name_derives_from_class_name
    klass = Class.new(Smol::Check)
    stub_name(klass, "TestModule::DiskSpaceCheck")

    assert_equal "disk space check", klass.check_name
  end

  def test_check_name_handles_camel_case
    klass = Class.new(Smol::Check)
    stub_name(klass, "TestModule::HTTPConnection")

    assert_equal "http connection", klass.check_name
  end

  def test_pass_returns_passed_check_result
    check = Smol::Check.new
    result = check.pass("all good")

    assert result.passed?
  end

  def test_pass_includes_message
    check = Smol::Check.new
    result = check.pass("all good")

    assert_equal "all good", result.message
  end

  def test_fail_returns_failed_check_result
    check = Smol::Check.new
    result = check.fail("something broke")

    assert result.failed?
  end

  def test_fail_includes_message
    check = Smol::Check.new
    result = check.fail("something broke")

    assert_equal "something broke", result.message
  end

  private

  def stub_name(klass, name)
    klass.define_singleton_method(:name) { name }
  end
end
