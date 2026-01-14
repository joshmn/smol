# frozen_string_literal: true

module Smol
  CheckResult = Struct.new(:passed, :message, keyword_init: true) do
    def passed?
      passed
    end

    def failed?
      !passed
    end

    def to_s
      status = passed? ? "passed" : "failed"
      "#{status}: #{message}"
    end
  end
end
