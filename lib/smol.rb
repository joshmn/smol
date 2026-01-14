# frozen_string_literal: true

require "logger"
require "readline"

require "smol/version"
require "smol/colors"
require "smol/coercion"
require "smol/app_lookup"
require "smol/check_result"
require "smol/output"
require "smol/input"
require "smol/config"
require "smol/config_display"
require "smol/check"
require "smol/command"
require "smol/app"
require "smol/repl"
require "smol/cli"

module Smol
  class Error < StandardError; end

  class << self
    attr_writer :output, :input, :logger, :verbose, :quiet

    def output
      @output ||= $stdout
    end

    def input
      @input ||= $stdin
    end

    def logger
      @logger ||= Logger.new($stderr, level: Logger::WARN)
    end

    def verbose?
      @verbose || ENV["VERBOSE"] == "1" || ENV["VERBOSE"] == "true"
    end

    def quiet?
      @quiet || ENV["QUIET"] == "1" || ENV["QUIET"] == "true"
    end

    def debug?
      @debug || ENV["DEBUG"] == "1" || ENV["DEBUG"] == "true"
    end

    def debug=(value)
      @debug = value
    end
  end
end
