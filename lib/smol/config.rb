# frozen_string_literal: true

module Smol
  class Config
    include Coercion

    def initialize
      @settings = {}
      @values = {}
    end

    def setting(key, default:, type: :string, desc: nil)
      @settings[key] = { default: default, type: type, desc: desc }
    end

    def [](key)
      return @values[key] if @values.key?(key)

      setting = @settings[key]
      raise ArgumentError, "unknown config key: #{key}" unless setting

      env_key = key.to_s.upcase
      raw = ENV.fetch(env_key, setting[:default].to_s)

      @values[key] = coerce_value(raw, setting[:type])
    end

    def set(key, value)
      raise ArgumentError, "unknown config key: #{key}" unless @settings.key?(key)

      @values[key] = coerce_value(value.to_s, @settings[key][:type])
    end

    def settings
      @settings.dup
    end

    def to_h
      @settings.keys.each_with_object({}) { |k, h| h[k] = self[k] }
    end

    def each(&block)
      return enum_for(:each) unless block

      @settings.each_key { |k| yield k, self[k], @settings[k] }
    end
  end
end
