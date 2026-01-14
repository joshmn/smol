# frozen_string_literal: true

module Smol
  module Coercion
    TRUTHY_VALUES = %w[true 1 yes].freeze

    def coerce_value(raw, type)
      case type
      when :integer
        raw.to_i
      when :boolean
        TRUTHY_VALUES.include?(raw.to_s.downcase)
      else
        raw
      end
    end
  end
end
