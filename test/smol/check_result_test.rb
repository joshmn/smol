# frozen_string_literal: true

require "test_helper"

class CheckResultTest < Minitest::Test
  def test_passed_returns_true_when_passed_is_true
    result = Smol::CheckResult.new(passed: true, message: "ok")

    assert result.passed?
  end

  def test_passed_returns_false_when_passed_is_false
    result = Smol::CheckResult.new(passed: false, message: "failed")

    refute result.passed?
  end

  def test_failed_returns_false_when_passed_is_true
    result = Smol::CheckResult.new(passed: true, message: "ok")

    refute result.failed?
  end

  def test_failed_returns_true_when_passed_is_false
    result = Smol::CheckResult.new(passed: false, message: "failed")

    assert result.failed?
  end

  def test_to_s_formats_passed_result
    result = Smol::CheckResult.new(passed: true, message: "all good")

    assert_equal "passed: all good", result.to_s
  end

  def test_to_s_formats_failed_result
    result = Smol::CheckResult.new(passed: false, message: "something broke")

    assert_equal "failed: something broke", result.to_s
  end
end
