# frozen_string_literal: true

require "test_helper"

class OutputTest < Minitest::Test
  def setup
    @output = StringIO.new
    Smol.output = @output
  end

  def teardown
    Smol.output = $stdout
    Smol.verbose = false
    Smol.debug = false
  end

  def test_banner_outputs_red_text
    Smol::Output.banner("test")

    assert_includes @output.string, "\e[31mtest\e[0m"
  end

  def test_header_outputs_bold_text
    Smol::Output.header("test")

    assert_includes @output.string, "\e[1mtest\e[0m"
  end

  def test_desc_outputs_dim_text
    Smol::Output.desc("test")

    assert_includes @output.string, "\e[2mtest\e[0m"
  end

  def test_nl_outputs_newline
    Smol::Output.nl

    assert_equal "\n", @output.string
  end

  def test_info_outputs_plain_text
    Smol::Output.info("test")

    assert_equal "test\n", @output.string
  end

  def test_success_outputs_green_text
    Smol::Output.success("test")

    assert_includes @output.string, "\e[32m"
  end

  def test_success_outputs_bold_text
    Smol::Output.success("test")

    assert_includes @output.string, "\e[1m"
  end

  def test_failure_outputs_red_text
    Smol::Output.failure("test")

    assert_includes @output.string, "\e[31m"
  end

  def test_failure_outputs_bold_text
    Smol::Output.failure("test")

    assert_includes @output.string, "\e[1m"
  end

  def test_warning_outputs_yellow_text
    Smol::Output.warning("test")

    assert_includes @output.string, "\e[33mtest\e[0m"
  end

  def test_hint_outputs_dim_text
    Smol::Output.hint("test")

    assert_includes @output.string, "\e[2mtest\e[0m"
  end

  def test_label_outputs_yellow_text
    Smol::Output.label("test")

    assert_includes @output.string, "\e[33mtest\e[0m"
  end

  def test_verbose_does_not_output_when_off
    Smol.verbose = false
    Smol::Output.verbose("test")

    assert_empty @output.string
  end

  def test_verbose_outputs_when_on
    Smol.verbose = true
    Smol::Output.verbose("test")

    assert_includes @output.string, "test"
  end

  def test_debug_does_not_output_when_off
    Smol.debug = false
    Smol::Output.debug("test")

    assert_empty @output.string
  end

  def test_debug_outputs_with_prefix_when_on
    Smol.debug = true
    Smol::Output.debug("test")

    assert_includes @output.string, "[debug]"
  end

  def test_table_outputs_first_cell
    Smol::Output.table([%w[a b], %w[c d]])

    assert_includes @output.string, "a"
  end

  def test_table_outputs_last_cell
    Smol::Output.table([%w[a b], %w[c d]])

    assert_includes @output.string, "d"
  end

  def test_table_outputs_header_row
    Smol::Output.table([%w[1 2]], headers: %w[col1 col2])

    assert_includes @output.string, "col1"
  end

  def test_table_outputs_separator
    Smol::Output.table([%w[1 2]], headers: %w[col1 col2])

    assert_includes @output.string, "-"
  end

  def test_table_does_nothing_for_empty_rows
    Smol::Output.table([])

    assert_empty @output.string
  end

  def test_check_result_passed_includes_pass_status
    result = Smol::CheckResult.new(passed: true, message: "all good")
    Smol::Output.check_result("test check", result)

    assert_includes @output.string, "pass"
  end

  def test_check_result_passed_includes_check_name
    result = Smol::CheckResult.new(passed: true, message: "all good")
    Smol::Output.check_result("test check", result)

    assert_includes @output.string, "test check"
  end

  def test_check_result_passed_includes_message
    result = Smol::CheckResult.new(passed: true, message: "all good")
    Smol::Output.check_result("test check", result)

    assert_includes @output.string, "all good"
  end

  def test_check_result_failed_includes_fail_status
    result = Smol::CheckResult.new(passed: false, message: "broke")
    Smol::Output.check_result("test check", result)

    assert_includes @output.string, "fail"
  end

  def test_check_result_failed_includes_check_name
    result = Smol::CheckResult.new(passed: false, message: "broke")
    Smol::Output.check_result("test check", result)

    assert_includes @output.string, "test check"
  end

  def test_check_result_failed_includes_message
    result = Smol::CheckResult.new(passed: false, message: "broke")
    Smol::Output.check_result("test check", result)

    assert_includes @output.string, "broke"
  end
end
