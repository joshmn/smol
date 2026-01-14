# frozen_string_literal: true

module Smol
  module Output
    using Colors
    extend self

    def out
      Smol.output
    end

    def banner(text)
      out.puts text.red
    end

    def header(text)
      out.puts text.bold
    end

    def desc(text)
      out.puts text.dim
    end

    def nl
      out.puts
    end

    def info(text)
      out.puts text
    end

    def success(text)
      out.puts text.green.bold
    end

    def failure(text)
      out.puts text.red.bold
    end

    def warning(text)
      out.puts text.yellow
    end

    def hint(text)
      out.puts text.dim
    end

    def label(text)
      out.puts text.yellow
    end

    def verbose(text)
      return unless Smol.verbose?

      out.puts text.dim
    end

    def debug(text)
      return unless Smol.debug?

      out.puts "[debug] #{text}".dim
    end

    def check_result(name, result)
      status = result.passed? ? "pass".green.bold : "fail".red.bold
      out.puts "#{status}: #{name}"
      out.puts "      #{result.message}"
    end

    def table(rows, headers: nil, indent: 0)
      return if rows.empty?

      all_rows = headers ? [headers] + rows : rows
      col_widths = table_column_widths(all_rows)
      prefix = " " * indent

      if headers
        header_line = table_format_row(headers, col_widths)
        out.puts "#{prefix}#{header_line}".bold
        out.puts "#{prefix}#{"-" * header_line.length}"
      end

      rows.each do |row|
        out.puts "#{prefix}#{table_format_row(row, col_widths)}"
      end
    end

    private

    def table_column_widths(rows)
      return [] if rows.empty?

      num_cols = rows.map(&:size).max
      (0...num_cols).map do |i|
        rows.map { |row| row[i].to_s.length }.max
      end
    end

    def table_format_row(row, widths)
      row.each_with_index.map do |cell, i|
        cell.to_s.ljust(widths[i] || 0)
      end.join("  ")
    end
  end
end
